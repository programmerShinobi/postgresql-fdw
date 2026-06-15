# 11. Import from an existing source database

> Verified against the live source database on 2026-06-15.
> All connection details live in your local `.env.source` (gitignored) — this
> document intentionally contains **no** hosts, IPs, or credentials.

## 11.1 Compatibility verdict — ✅ SAFE

| Aspect | Source | Target (this repo) | Result |
|--------|--------|--------------------|--------|
| PostgreSQL | **15.8** | **17** | ✅ upward migration is supported |
| Encoding | UTF8 | UTF8 | ✅ identical |
| Collation / ctype | en_US.utf8 | en_US.utf8 | ✅ identical (indexes safe) |
| `mysql_fdw` | 1.2 | 1.2 | ✅ present |
| `pg_cron` | 1.6 | 1.6+ | ✅ present |
| `tds_fdw` | 2.0.3 | 2.0.3+ | ✅ present |
| `plpgsql` | 1.0 | builtin | ✅ present |

The target image is a **superset** of everything the source actually uses, so a
dump/restore will not fail on a missing extension. Re-verify any time:

```bash
cp .env.source.example .env.source   # fill in host/port/user/db/password (gitignored)
./scripts/migration/check-compatibility.sh
```

## 11.2 What the source contains (inventory)

- **14 tables**, **11 materialized views**, 1 view, **14 functions**,
  **24 composite/enum types**, 3 sequences.
- **5 foreign servers** (4× `tds_fdw` → internal SQL Server hosts `:1433`,
  1× `mysql_fdw` → an internal MySQL host `:3306`) + **5 user mappings** +
  **12 foreign tables**. (Actual hostnames are internal — not recorded here.)
- **5 `pg_cron` jobs** (hourly `REFRESH MATERIALIZED VIEW CONCURRENTLY`).
- Database size ≈ **1.9 GB**.

## 11.3 Three things that need attention

### (a) Ownership / roles
Objects in the dump are owned by whatever role owned them on the **source**
(call it `<source_role>`). If that role doesn't exist in this target — whose
superuser is **`local_dev`** — pick one:

- **Recommended (frictionless FDW):** create a matching role in the target
  before importing, so owners *and* FDW user mappings restore verbatim:
  ```bash
  docker compose exec -T postgres psql -U local_dev -d local_db \
    -c "CREATE ROLE <source_role> LOGIN SUPERUSER PASSWORD 'pick-a-password';"
  ```
  Then import **without** `--no-owner` (edit the script) to keep ownership.
- **Pure `local_*` (default in our script):** import with
  `--no-owner --no-privileges` → everything ends up owned by `local_dev`. The
  catch: any **FDW user mappings tied to `<source_role>`** won't be used by a
  `local_dev` session. Recreate them for `local_dev` (the import carries the
  remote credentials into the catalog; copy them with):
  ```sql
  -- as the importing user, inspect then recreate per server:
  SELECT srvname FROM pg_foreign_server;
  -- CREATE USER MAPPING FOR local_dev SERVER <server> OPTIONS (username '...', password '...');
  ```

> TL;DR: to **work immediately**, recreate the source owner role in the target.
> For a clean `local_*` world, expect to redo the user mappings.

### (b) `pg_cron` jobs are NOT dumped
`pg_dump` never carries `cron.job` rows. Recreate them after import:
```bash
docker compose exec -T postgres psql -U local_dev -d local_db \
  -f /opt/migration/recreate-cron-jobs.sql
```
(The 5 jobs are pre-written in `scripts/migration/recreate-cron-jobs.sql`.)

### (c) `timescaledb` is preloaded on the source — but unused
The source's `shared_preload_libraries = 'timescaledb, pg_cron'`, yet
`timescaledb` is **not** created as an extension in the source database (no hypertables).
So the import does **not** need it and will not fail. Only if you later intend to
use TimescaleDB features would you add `postgresql-17-timescaledb` to the
`Dockerfile` and preload it.

### (d) Foreign tables hold no local data
`mysql_fdw`/`tds_fdw` foreign tables are *pointers*. The import copies their
**definitions**, not remote rows. For them to return data, the new container
must reach those internal remote servers — same network/VPN as today.

## 11.4 One-shot import

```bash
cp .env.source.example .env.source   # fill in the source connection (gitignored)
make up                              # target must be running
./scripts/migration/import-from-source.sh
```

The script: dumps the source with the **container's PG17 `pg_dump`** (client ≥
server, the safe direction), restores into `local_db`, then recreates the cron
jobs. The dump is saved in `./backups/` so you can re-run the restore offline.

## 11.5 Post-import verification checklist

- [ ] `make extensions` lists mysql_fdw, pg_cron, tds_fdw
- [ ] `\dt` shows the 14 tables; `\dm` shows 11 materialized views
- [ ] `SELECT * FROM cron.job;` shows the 5 jobs
- [ ] `SELECT srvname FROM pg_foreign_server;` shows the 5 servers
- [ ] A foreign-table `SELECT ... LIMIT 1` works (needs remote reachability)
- [ ] Row counts on a couple of key tables match the source
- [ ] `make backup` to capture the freshly imported state

---

✅ Back to the [README »](../README.md)
