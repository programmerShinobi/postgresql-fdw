# 7. Backup & Restore

> Data in the `local_pgdata` volume survives `make down`, but **not** `make
> destroy`. Take real backups.

> **This feature is optional and on-demand.** Nothing here runs unless you
> invoke it. `make backup`/`make restore` are manual; an *automated* scheduled
> backup is an opt-in service (`make up-backup`, off by default) — see
> [doc 12 — Optional Features](12-OPTIONAL-FEATURES.md).

## 7.1 One-off backup

```bash
make backup
# -> backups/local_db_YYYYMMDD_HHMMSS.dump.gz   (custom-format, gzipped)
```

Under the hood:

```bash
docker compose exec -T postgres \
  pg_dump -U local_dev -d local_db -Fc | gzip > backups/local_db_<ts>.dump.gz
```

Custom format (`-Fc`) is recommended: compressed, and `pg_restore` can do
selective/partial restores from it.

## 7.2 Restore

```bash
make restore FILE=backups/local_db_20260615_140000.dump.gz
```

Under the hood:

```bash
gunzip -c <file> | docker compose exec -T postgres \
  pg_restore -U local_dev -d local_db --clean --if-exists
```

> `--clean --if-exists` drops existing objects first, so you restore onto a
> non-empty DB safely. To restore into a **fresh** DB, `make destroy && make up`
> first, then restore.

## 7.3 Plain SQL dump (portable, human-readable)

```bash
docker compose exec -T postgres pg_dumpall -U local_dev --globals-only \
  > backups/globals.sql            # roles/tablespaces
docker compose exec -T postgres pg_dump -U local_dev -d local_db \
  > backups/local_db.sql             # schema + data as SQL
```

## 7.4 Scheduled backups

**Option A — host cron** (simple):

```cron
# crontab -e  → daily at 02:30
30 2 * * * cd /home/faqih/Documents/projects/me/postgresql-fdw && make backup >> backups/cron.log 2>&1
```

**Option B — in-database with pg_cron** (logical dump still needs the host, but
you can schedule maintenance):

```sql
SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM (ANALYZE)');
SELECT * FROM cron.job;            -- verify
```

## 7.5 Retention / pruning

Old dumps pile up. Prune those older than 14 days:

```bash
find backups -name '*.dump.gz' -mtime +14 -delete
```

## 7.6 Restore checklist

- [ ] Backup file exists and is non-zero (`ls -lh backups/`)
- [ ] Target DB reachable (`make health`)
- [ ] Ran restore; checked row counts in a key table
- [ ] App reconnected successfully

---

✅ Next: take it beyond your laptop →
[8. Deployment »](08-DEPLOYMENT.md)
