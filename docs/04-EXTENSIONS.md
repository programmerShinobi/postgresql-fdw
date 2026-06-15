# 4. Extensions

Everything below is **already installed and created** in `ahi_db` on first boot
(see `scripts/init/00-extensions.sql`). List them anytime with:

```bash
make extensions      # what's created in the DB
make available       # everything the image *could* offer
```

---

## 4.1 Foreign Data Wrappers (the ⭐ of this repo)

| Extension | Connects to | Notes |
|-----------|-------------|-------|
| `postgres_fdw` | other PostgreSQL servers | built-in contrib |
| `mysql_fdw` | MySQL / MariaDB | compiled from source in the image |
| `tds_fdw` | SQL Server / Sybase | via FreeTDS |
| `file_fdw` | CSV / flat files | file must be readable in the container |
| `dblink` | other PostgreSQL (ad-hoc) | function-style, not table-style |

Copy-paste recipes live in [`scripts/fdw-examples/`](../scripts/fdw-examples/).
Quick taste:

```sql
CREATE SERVER remote_pg FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.0.0.10', port '5432', dbname 'remote_db');
CREATE USER MAPPING FOR CURRENT_USER SERVER remote_pg
    OPTIONS (user 'remote_user', password 'secret');
IMPORT FOREIGN SCHEMA public FROM SERVER remote_pg INTO public;
SELECT * FROM some_remote_table LIMIT 5;
```

## 4.2 AI / search

| Extension | What it gives you | Example |
|-----------|-------------------|---------|
| `vector` (pgvector) | embedding storage + ANN search | `CREATE TABLE items (id int, embedding vector(1536));` then `ORDER BY embedding <=> '[...]' LIMIT 5;` |
| `pg_trgm` | trigram fuzzy text search | `WHERE name % 'jhon'` |
| `unaccent` | accent-insensitive search | `WHERE unaccent(name) ILIKE unaccent('café')` |
| `fuzzystrmatch` | soundex / levenshtein | `levenshtein('foo','for')` |

## 4.3 Scheduling & partitioning

| Extension | Use | Example |
|-----------|-----|---------|
| `pg_cron` | run SQL on a cron schedule, inside the DB | `SELECT cron.schedule('nightly', '0 2 * * *', 'VACUUM ANALYZE');` |
| `pg_partman` | automated time/serial partitioning | manage big tables without manual partition DDL |

> `pg_cron` is bound to `ahi_db` via `cron.database_name`. Jobs run as the
> database owner. List jobs: `SELECT * FROM cron.job;`

## 4.4 Performance & operations

| Extension | Use |
|-----------|-----|
| `pg_stat_statements` | find your slowest/most frequent queries: `SELECT query, calls, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;` |
| `hypopg` | test indexes *hypothetically* before building them |
| `pg_hint_plan` | force planner choices when needed |
| `pg_repack` | remove table/index bloat without long locks |
| `pgaudit` | structured audit logging for compliance |

## 4.5 Data types & utilities (contrib)

`uuid-ossp`, `pgcrypto` (UUIDs, hashing, encryption), `citext` (case-insensitive
text), `hstore`, `ltree` (trees), `cube` + `earthdistance` (geo distance without
PostGIS), `intarray`, `isn`, `tablefunc` (crosstab/pivot), `btree_gin`,
`btree_gist`.

```sql
SELECT gen_random_uuid();                 -- pgcrypto
SELECT uuid_generate_v4();                -- uuid-ossp
SELECT earth_distance(ll_to_earth(-6.2,106.8), ll_to_earth(-7.8,110.4)); -- ~km*1000
```

## 4.6 Adding or removing an extension

1. **apt-packaged?** Add `postgresql-17-<name>` to the `Dockerfile`, rebuild.
2. **needs source build?** Follow the `mysql_fdw` pattern in the `Dockerfile`.
3. **create it** in `scripts/init/00-extensions.sql` (or run `CREATE EXTENSION`
   manually for an already-running DB).
4. If it needs preloading, add it to `shared_preload_libraries` in
   `config/postgresql.conf` and `make restart`.

---

✅ Next: the reasoning behind the resource caps →
[5. Resource Tuning »](05-RESOURCE-TUNING.md)
