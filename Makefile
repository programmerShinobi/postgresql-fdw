# =============================================================================
# Convenience commands. Run `make help` to see everything.
# =============================================================================
SHELL := /bin/bash

# Load .env so targets can reference $(POSTGRES_USER) etc.
ifneq (,$(wildcard ./.env))
include .env
export
endif

DC          := docker compose
SERVICE     := postgres
# Derive from .env (POSTGRES_USER/POSTGRES_DB) so renaming them never breaks
# `make psql` / `backup` / `extensions`. Falls back to the defaults if unset.
DB_USER     ?= $(or $(POSTGRES_USER),local_dev)
DB_NAME     ?= $(or $(POSTGRES_DB),local_db)
TS          := $(shell date +%Y%m%d_%H%M%S)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: init
init: hooks ## First-time setup: copy .env.example -> .env if missing + install hooks
	@test -f .env || (cp .env.example .env && echo "Created .env — EDIT THE PASSWORD before 'make up'")
	@test -f .env && echo ".env present."

.PHONY: hooks
hooks: ## Install the git pre-commit secret guard
	@if [ -d .git ]; then \
		cp scripts/git-hooks/pre-commit .git/hooks/pre-commit && \
		chmod +x .git/hooks/pre-commit && \
		echo "Installed .git/hooks/pre-commit (secret guard)."; \
	else echo "Not a git repo yet — run 'git init' first."; fi

.PHONY: scan-secrets
scan-secrets: ## Dry-run the secret guard against everything currently staged
	@git add -A -n >/dev/null 2>&1; bash scripts/git-hooks/pre-commit && echo "No secrets detected in staged changes."

.PHONY: build
build: ## Build the image (compiles mysql_fdw; first run is slow)
	$(DC) build

.PHONY: up
up: ## Start ONLY core Postgres (optional services stay off)
	$(DC) up -d

# ---- Optional features (compose profiles; off by default) ------------------
.PHONY: up-pooler
up-pooler: ## Start core + PgBouncer connection pooler (port 6432)
	$(DC) --profile pooler up -d

.PHONY: up-backup
up-backup: ## Start core + scheduled backup service
	$(DC) --profile backup up -d

.PHONY: up-ui
up-ui: ## Start core + Adminer web UI (http://localhost:8080)
	$(DC) --profile ui up -d

.PHONY: up-metrics
up-metrics: ## Start core + postgres-exporter (http://localhost:9187/metrics)
	$(DC) --profile metrics up -d

.PHONY: up-all
up-all: ## Start core + ALL optional services
	$(DC) --profile pooler --profile backup --profile ui --profile metrics up -d

.PHONY: down
down: ## Stop containers (keeps data)
	$(DC) down

.PHONY: restart
restart: ## Restart the Postgres service
	$(DC) restart $(SERVICE)

.PHONY: destroy
destroy: ## Stop and DELETE the data volume (irreversible!)
	$(DC) down -v

.PHONY: logs
logs: ## Follow Postgres logs
	$(DC) logs -f $(SERVICE)

.PHONY: ps
ps: ## Show container status
	$(DC) ps

.PHONY: stats
stats: ## Live CPU/RAM usage of the container
	docker stats $$($(DC) ps -q $(SERVICE))

.PHONY: psql
psql: ## Open a psql shell inside the container
	$(DC) exec $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME)

.PHONY: extensions
extensions: ## List installed extensions in the database
	$(DC) exec $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) \
		-c "SELECT extname, extversion FROM pg_extension ORDER BY extname;"

.PHONY: available
available: ## List ALL extensions the image can offer (default_version)
	$(DC) exec $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) \
		-c "SELECT name, default_version, comment FROM pg_available_extensions ORDER BY name;"

.PHONY: health
health: ## Check readiness
	$(DC) exec $(SERVICE) pg_isready -U $(DB_USER) -d $(DB_NAME)

.PHONY: backup
backup: ## Dump the database to ./backups (gzip)
	$(DC) exec -T $(SERVICE) pg_dump -U $(DB_USER) -d $(DB_NAME) -Fc \
		| gzip > backups/$(DB_NAME)_$(TS).dump.gz
	@echo "Wrote backups/$(DB_NAME)_$(TS).dump.gz"

.PHONY: restore
restore: ## Restore from FILE=backups/xxx.dump.gz
	@test -n "$(FILE)" || (echo "Usage: make restore FILE=backups/xxx.dump.gz"; exit 1)
	gunzip -c $(FILE) | $(DC) exec -T $(SERVICE) pg_restore -U $(DB_USER) -d $(DB_NAME) --clean --if-exists
	@echo "Restored from $(FILE)"
