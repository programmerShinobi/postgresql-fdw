# 3. Configuration

Two files control everything:

1. **`.env`** — runtime/orchestration (credentials, ports, resource caps).
2. **`config/postgresql.conf`** — the database server's own tuning.

Nothing here requires an image rebuild **except** changing extensions in the
`Dockerfile`. Config changes only need a `make restart`.

---

## 3.1 `.env` reference

| Variable | Default | Purpose |
|----------|---------|---------|
| `COMPOSE_PROJECT_NAME` | `ahi` | Prefix for container/volume/network names |
| `POSTGRES_USER` | `ahi_dev` | Superuser created on first init |
| `POSTGRES_PASSWORD` | — | **Required.** Set a strong value |
| `POSTGRES_DB` | `ahi_db` | Default database created on first init |
| `POSTGRES_HOST_PORT` | `15409` | Host port → container `5432` |
| `TZ` | `Asia/Jakarta` | Container & log timezone |
| `PG_MEM_LIMIT` | `1536M` | **Hard** RAM ceiling for the container |
| `PG_MEMSWAP_LIMIT` | `2048M` | RAM + swap ceiling |
| `PG_CPU_LIMIT` | `2.0` | Max CPU cores |
| `PG_SHM_SIZE` | `256m` | `/dev/shm` size (parallel queries, big sorts) |

> ⚠️ Changing `POSTGRES_USER`/`POSTGRES_DB`/`POSTGRES_PASSWORD` **after** the
> first boot does **not** retroactively change an existing data volume. To apply
> them you must `make destroy` (wipes data) or change them via SQL.

> 🔄 If you rename `POSTGRES_DB`, also update `cron.database_name` and
> `pg_partman_bgw.dbname` in `config/postgresql.conf` so pg_cron/pg_partman
> attach to the right database.

## 3.2 `config/postgresql.conf` — key settings

These are deliberately **conservative** because Postgres shares the laptop.

| Setting | Value | Why |
|---------|-------|-----|
| `shared_buffers` | `256MB` | Small on purpose — we don't own all RAM |
| `effective_cache_size` | `768MB` | Conservative estimate of OS cache share |
| `work_mem` | `16MB` | Per sort/hash; low to bound total under load |
| `maintenance_work_mem` | `128MB` | For VACUUM / index builds |
| `max_connections` | `50` | Ample for dev; use a pooler beyond that |
| `max_parallel_workers_per_gather` | `2` | Don't hog all 8 threads |
| `random_page_cost` | `1.1` | SSD-aware |
| `effective_io_concurrency` | `200` | SSD-aware |
| `wal_compression` | `on` | Less write amplification on SSD |
| `log_min_duration_statement` | `500ms` | Surface slow queries during dev |
| `shared_preload_libraries` | see below | Loads background extensions |

### Preloaded libraries

```
shared_preload_libraries = 'pg_stat_statements,pg_cron,pgaudit,pg_hint_plan,pg_partman_bgw'
```

These **must** be preloaded (they hook into the server at startup). Other
extensions like `pgvector` or the FDWs do not need preloading. If you add a new
preload-requiring extension, edit this line and `make restart`.

## 3.3 How to change settings safely

```bash
# 1. Edit config/postgresql.conf  (it's mounted read-only into the container)
# 2. Apply:
make restart
# 3. Confirm a value:
make psql
ahi_db=# SHOW shared_buffers;
```

Some settings (e.g. `shared_buffers`, `shared_preload_libraries`) require a full
restart — `make restart` covers that. Many others can be reloaded live with
`SELECT pg_reload_conf();`.

## 3.4 Authentication

- Host connections use **`scram-sha-256`** (`POSTGRES_HOST_AUTH_METHOD` +
  `password_encryption`). This is stronger than the legacy `md5`.
- The data directory is created with **`--data-checksums`** to detect silent
  corruption early.

---

✅ Next: understand what you can do with the bundled extensions →
[4. Extensions »](04-EXTENSIONS.md)
