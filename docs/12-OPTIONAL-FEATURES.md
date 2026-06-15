# 12. Optional features (opt-in, zero cost when off)

> **Design promise:** a plain `make up` starts **only** the PostgreSQL server.
> Every feature below is gated behind a Docker Compose **profile**, so it
> consumes **no CPU/RAM** until you explicitly enable it. All features are
> present in the repo — anyone who needs one just turns it on.

## 12.1 Feature matrix

| Feature | Profile | Command | Default | Idle cost when ON | Off by default? |
|---------|---------|---------|---------|-------------------|-----------------|
| Core PostgreSQL 17 | — | `make up` | always | (the DB itself) | n/a |
| Manual backup/restore | — | `make backup` / `make restore` | always available | none (runs on demand) | n/a |
| **Scheduled backups** | `backup` | `make up-backup` | OFF | ~ idle, ≤128 MB cap | ✅ |
| **Connection pooler** (PgBouncer) | `pooler` | `make up-pooler` | OFF | ~5–15 MB, ≤96 MB cap | ✅ |
| **Web admin UI** (Adminer) | `ui` | `make up-ui` | OFF | ~10–20 MB, ≤128 MB cap | ✅ |
| **Metrics exporter** | `metrics` | `make up-metrics` | OFF | ~10–20 MB, ≤96 MB cap | ✅ |
| **Import from source** | — | script | always available | none (runs on demand) | n/a |
| Everything at once | all | `make up-all` | OFF | sum of the above | ✅ |

> Each optional service has a hard `mem_limit` + `cpus` cap, so even when ON it
> cannot slow your laptop. Turn any of them off again with `make down` (stops
> the whole stack) and bring back just core with `make up`.

## 12.2 Connection pooler — PgBouncer (`pooler`)

Why: Postgres `max_connections` is only 50 and shared. A pooler lets many app
connections (e.g. NestJS in watch mode) share a few real ones.

```bash
make up-pooler
# App connects to port 6432 instead of 15409:
#   postgresql://local_dev:<password>@127.0.0.1:6432/local_db
```

Tune in `.env`: `PGBOUNCER_POOL_MODE` (transaction|session), `MAX_CLIENT_CONN`,
`DEFAULT_POOL_SIZE`.

## 12.3 Scheduled backups (`backup`)

Why: automated, rotated `pg_dump`s without you remembering to run them.

```bash
make up-backup        # backs up on BACKUP_SCHEDULE into ./backups
```

Tune in `.env`: `BACKUP_SCHEDULE` (`@daily`, `@hourly`, or cron), and retention
`BACKUP_KEEP_DAYS/WEEKS/MONTHS`. Manual backup/restore still works anytime via
`make backup` / `make restore` — see [doc 7](07-BACKUP-RESTORE.md).

## 12.4 Web admin UI — Adminer (`ui`)

Why: a browser GUI for the DB without installing anything on the host. Adminer is
a single lightweight container (far lighter than pgAdmin).

```bash
make up-ui            # open http://localhost:8080
# System: PostgreSQL · Server: postgres · User/DB: from your .env
```

## 12.5 Metrics — postgres-exporter (`metrics`)

Why: expose Postgres metrics for Prometheus/Grafana when you want observability.

```bash
make up-metrics       # metrics at http://localhost:9187/metrics
```

Point a Prometheus scrape at `localhost:9187`. (Prometheus/Grafana themselves are
intentionally **not** bundled — add them in your own monitoring stack if needed.)

## 12.6 Import from an existing source

A fully optional, on-demand workflow (no running service). See
[doc 11 — Import from Source](11-IMPORT-FROM-SOURCE.md).

## 12.7 Heavier extensions (opt-in at build time)

Extensions like **PostGIS** or **TimescaleDB** are deliberately **not** baked in
(they enlarge the image and can be heavy). If you need them, add the package to
the `Dockerfile` (e.g. `postgresql-17-postgis-3`, `timescaledb-2-postgresql-17`),
add to `shared_preload_libraries` if required, rebuild, and `CREATE EXTENSION`.
This keeps the default image fast for everyone who doesn't need them.

## 12.8 Mixing profiles

```bash
docker compose --profile pooler --profile ui up -d     # just these two
make up-all                                             # all optional services
make down                                               # stop everything
make up                                                 # back to core only
```

---

✅ Back to the [README »](../README.md)
