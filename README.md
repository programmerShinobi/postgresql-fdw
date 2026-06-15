<div align="center">

# 🐘 PostgreSQL 17 — Dockerized Dev Setup with FDW & Extensions

**A production-shaped, laptop-friendly PostgreSQL development environment.**
Foreign Data Wrappers + vector search + scheduling + partitioning + auditing —
all pre-installed, tuned to coexist peacefully with Elasticsearch, Redis and NestJS.

[![CI](https://github.com/programmerShinobi/postgresql-fdw/actions/workflows/ci.yml/badge.svg)](https://github.com/programmerShinobi/postgresql-fdw/actions/workflows/ci.yml)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## ✨ What you get

- **PostgreSQL 17** on the official Debian image, fully reproducible.
- **15+ extensions ready to use** the moment the container is up — including
  `postgres_fdw`, `mysql_fdw`, `tds_fdw`, `file_fdw`, `pgvector`, `pg_cron`,
  `pg_partman`, `pg_stat_statements`, `pgaudit`, `pg_repack`, `hypopg`,
  `pg_hint_plan`, `orafce`, and the usual `uuid-ossp`/`pgcrypto`/`pg_trgm` toolbox.
- **Laptop-safe by design** — hard Docker memory & CPU caps so Postgres can
  *never* starve your other heavy services.
- **One-command workflow** via `make` (up, down, psql, backup, restore, stats…).
- **Documented end-to-end** — a checklist you can tick off from requirements
  all the way to deployment.

---

## 🚀 Quick start (TL;DR)

```bash
# 1. Configure (edit the password!)
cp .env.example .env

# 2. Build the image (first build compiles mysql_fdw — grab a coffee ☕)
make build

# 3. Start
make up

# 4. Verify extensions are live
make extensions
```

Then connect:

```
postgresql://local_dev:<your-password>@127.0.0.1:15409/local_db
```

> Host port **15409** mirrors the original reference connection string; the
> generic `local_dev` / `local_db` names keep this reusable. Change anything in `.env`.

---

## 📚 Documentation — read in order

Each document is a self-contained checklist. Tick the boxes as you go.

| # | Document | What it covers |
|---|----------|----------------|
| 0 | [**Getting Started**](docs/00-GETTING-STARTED.md) | 👈 **New here? Start with this** — friendly step-by-step walkthrough |
| 1 | [Requirements](docs/01-REQUIREMENTS.md) | Hardware/software prerequisites, your laptop's budget |
| 2 | [Installation](docs/02-INSTALLATION.md) | Step-by-step from clone to running container |
| 3 | [Configuration](docs/03-CONFIGURATION.md) | Every `.env` & `postgresql.conf` knob explained |
| 4 | [Extensions](docs/04-EXTENSIONS.md) | What each extension does + usage snippets |
| 5 | [Resource Tuning](docs/05-RESOURCE-TUNING.md) | Why the limits are what they are; how to rebalance |
| 6 | [NestJS Integration](docs/06-NESTJS-INTEGRATION.md) | Wiring this DB into a NestJS/TypeORM/Prisma app |
| 7 | [Backup & Restore](docs/07-BACKUP-RESTORE.md) | Dump, restore, and scheduled backups |
| 8 | [Deployment](docs/08-DEPLOYMENT.md) | Promoting the same setup toward staging/prod |
| 9 | [Troubleshooting](docs/09-TROUBLESHOOTING.md) | Common errors and fixes |
| 10 | [Security](docs/10-SECURITY.md) | Hardening checklist for dev and beyond |
| 11 | [Import from Source](docs/11-IMPORT-FROM-SOURCE.md) | Safely migrate data from an existing PostgreSQL |
| 12 | [Optional Features](docs/12-OPTIONAL-FEATURES.md) | Opt-in pooler / backups / UI / metrics — zero cost when off |

---

## 🗂️ Repository layout

```
postgresql-fdw/
├── docker-compose.yml          # the stack + hard resource caps
├── Dockerfile                  # PG17 + extensions (compiles mysql_fdw)
├── .env.example                # copy to .env and edit
├── Makefile                    # make up / down / psql / backup ...
├── config/
│   └── postgresql.conf         # laptop-tuned server config
├── scripts/
│   ├── init/                   # auto-run on first boot
│   │   ├── 00-extensions.sql   #   CREATE EXTENSION for everything
│   │   └── 01-roles-and-grants.sql
│   └── fdw-examples/           # copy-paste FDW recipes (not auto-run)
├── backups/                    # pg_dump output lands here
└── docs/                       # the numbered guides above
```

---

## ✅ Master checklist

A bird's-eye view. Detailed steps live in the linked docs.

- [ ] **Requirements** met — Docker Engine + Compose v2, ≥2 GB free RAM budget → [doc 1](docs/01-REQUIREMENTS.md)
- [ ] `.env` created and **password changed** → [doc 2](docs/02-INSTALLATION.md)
- [ ] Image built (`make build`) → [doc 2](docs/02-INSTALLATION.md)
- [ ] Container healthy (`make health`) → [doc 2](docs/02-INSTALLATION.md)
- [ ] Extensions verified (`make extensions`) → [doc 4](docs/04-EXTENSIONS.md)
- [ ] Resource caps reviewed for your machine → [doc 5](docs/05-RESOURCE-TUNING.md)
- [ ] App connected (NestJS) → [doc 6](docs/06-NESTJS-INTEGRATION.md)
- [ ] Backup tested at least once → [doc 7](docs/07-BACKUP-RESTORE.md)
- [ ] Security checklist reviewed → [doc 10](docs/10-SECURITY.md)

---

## 🧩 Optional features (off by default, zero cost when off)

A plain `make up` starts **only** PostgreSQL. Everything else is opt-in via
Docker Compose profiles, each hard-capped so it never slows your laptop:

```bash
make up-pooler    # + PgBouncer connection pooler   (port 6432)
make up-backup    # + scheduled rotated backups
make up-ui        # + Adminer web UI                (http://localhost:8080)
make up-metrics   # + postgres-exporter             (http://localhost:9187)
make up-all       # + everything above
```

Full matrix & tuning: [doc 12 — Optional Features](docs/12-OPTIONAL-FEATURES.md).

## 🧰 Everyday commands

```bash
make up           # start ONLY core Postgres
make down         # stop everything (data kept)
make psql         # open a psql shell
make extensions   # list installed extensions
make stats        # live CPU/RAM of the container
make backup       # one-off dump to ./backups (manual)
make logs         # follow logs
make destroy      # stop AND delete data (careful!)
make help         # everything
```

---

## 👤 Author

**programmerShinobi** · [GitHub](https://github.com/programmerShinobi)

If this project helps you, a ⭐ on the repo is appreciated!

## 📄 License

Copyright © 2026 [programmerShinobi](https://github.com/programmerShinobi).
Released under the [MIT License](LICENSE) — use it freely.
