# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-06-15

### Added
- Dockerized **PostgreSQL 17** image with a curated extension set ready to use:
  `postgres_fdw`, `mysql_fdw` (compiled), `tds_fdw`, `file_fdw`, `pgvector`,
  `pg_cron`, `pg_partman`, `pg_stat_statements`, `pgaudit`, `pg_repack`,
  `hypopg`, `pg_hint_plan`, `orafce`, plus the contrib toolbox.
- Laptop-tuned defaults: hard Docker memory/CPU caps + conservative
  `postgresql.conf`, safe to run alongside Elasticsearch/Redis/NestJS.
- `Makefile` workflow (`up`, `down`, `psql`, `backup`, `restore`, `stats`, …).
- Auto-init SQL (extensions, baseline roles) and copy-paste FDW examples.
- **Optional services behind compose profiles** (off by default, hard-capped):
  PgBouncer (`pooler`), scheduled backups (`backup`), Adminer (`ui`),
  postgres-exporter (`metrics`).
- **Import-from-source** workflow with a verified compatibility report and
  cron-job re-creation helper.
- **Secret-management standard**: gitignored `.env`/`.env.source`, broad
  `.gitignore`, and a pre-commit secret guard (`make hooks`).
- Documentation set `docs/01`–`docs/12` (requirements → optional features) and a
  GitHub CI workflow that builds the image and asserts every extension installs.
- Open-source metadata: `CONTRIBUTING`, `CODE_OF_CONDUCT`, `SECURITY`, issue/PR
  templates.

[Unreleased]: https://github.com/programmerShinobi/postgresql-fdw/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/programmerShinobi/postgresql-fdw/releases/tag/v1.0.0
