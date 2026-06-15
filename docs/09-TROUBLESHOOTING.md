# 9. Troubleshooting

> First two commands for almost any issue:
>
> ```bash
> make logs        # what is Postgres actually saying?
> make ps          # is it healthy / restarting / exited?
> ```

## 9.1 Container won't start / restart loop

| Cause | Diagnosis | Fix |
|-------|-----------|-----|
| Bad `postgresql.conf` edit | `make logs` shows a config error line | fix the line, `make restart` |
| Missing preload lib | log: `could not access file "..."` in `shared_preload_libraries` | ensure the extension is installed in the image; rebuild |
| Port taken | `make up` errors `port is already allocated` | change `POSTGRES_HOST_PORT` in `.env` |
| Corrupt/locked data dir | log mentions lock or PID file | `make down`, then `make up`; last resort `make destroy` (wipes data) |

## 9.2 Extensions are missing

Init scripts in `scripts/init/` **only run on a fresh data volume**. If the
volume already existed, they were skipped.

```bash
# Option A — create them manually on the running DB:
make psql
local_db=# \i /docker-entrypoint-initdb.d/00-extensions.sql

# Option B — start clean (⚠️ deletes all data):
make destroy && make up
```

## 9.3 `mysql_fdw` build failed during `make build`

Usually transient (apt mirror / network). Retry:

```bash
docker compose build --no-cache postgres
```

If it persists, check you can reach `github.com` and `apt.postgresql.org` from
Docker (proxy/DNS). The build clones `EnterpriseDB/mysql_fdw` and needs
`libmariadb-dev`.

## 9.4 `FATAL: sorry, too many clients already`

You hit `max_connections` (50). Causes & fixes:

- App pool too large → cap each app pool at ≤ 10 ([doc 6](06-NESTJS-INTEGRATION.md)).
- Leaked/idle connections → check:
  ```sql
  SELECT count(*), state FROM pg_stat_activity GROUP BY state;
  ```
- Genuinely need more → raise `max_connections` (costs RAM) or add PgBouncer.

## 9.5 High memory / laptop swapping

```bash
make stats          # is Postgres near its 1.5 GiB LIMIT?
docker stats        # which container is the hog? (often Elasticsearch)
free -h             # host headroom
```

If Postgres is the culprit, lower `work_mem`/`shared_buffers` or
`PG_MEM_LIMIT`. More often it's Elasticsearch — cap its JVM heap. See
[doc 5](05-RESOURCE-TUNING.md).

## 9.6 Slow queries

```sql
-- top offenders (needs pg_stat_statements — already installed)
SELECT query, calls, round(mean_exec_time::numeric, 2) AS avg_ms,
       round(total_exec_time::numeric, 2) AS total_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- reset stats to start fresh
SELECT pg_stat_statements_reset();
```

Use `EXPLAIN (ANALYZE, BUFFERS)` on the offender; test indexes safely with
`hypopg` before building them.

## 9.7 pg_cron jobs not running

```sql
SELECT * FROM cron.job;                 -- are they scheduled?
SELECT * FROM cron.job_run_details      -- did they run / fail?
  ORDER BY start_time DESC LIMIT 20;
```

Check `cron.database_name = 'local_db'` in `postgresql.conf` matches your DB, and
that `pg_cron` is in `shared_preload_libraries`.

## 9.8 Can't connect from the host

- Is it healthy? `make health`
- Right port? Host uses **15409**, container uses **5432**.
- Right password? It's whatever was in `.env` **at first init** — changing
  `.env` later does not change an existing user's password. Reset it:
  ```sql
  ALTER USER local_dev WITH PASSWORD 'new-password';
  ```

## 9.9 Reset everything (nuclear)

```bash
make destroy        # stop + delete data volume
make build          # rebuild image
make up             # fresh init, extensions recreated
```

---

✅ Last doc: lock it down →
[10. Security »](10-SECURITY.md)
