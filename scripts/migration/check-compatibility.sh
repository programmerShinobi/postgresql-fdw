#!/usr/bin/env bash
# =============================================================================
# check-compatibility.sh
# Connects to a SOURCE PostgreSQL and reports everything that matters for a
# safe import into this repo's target (PG17). Read-only; runs only SELECTs.
#
# Credentials are read from `.env.source` (gitignored). Never hardcode them.
#   cp .env.source.example .env.source   # then fill it in
#   ./scripts/migration/check-compatibility.sh
# =============================================================================
set -euo pipefail

# Load source credentials from the gitignored .env.source (if present).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$ROOT/.env.source" ]; then
  set -a; . "$ROOT/.env.source"; set +a
fi

: "${SRC_HOST:?Set SRC_HOST in .env.source}"
: "${SRC_PORT:?Set SRC_PORT in .env.source}"
: "${SRC_USER:?Set SRC_USER in .env.source}"
: "${SRC_DB:?Set SRC_DB in .env.source}"
: "${SRC_PASSWORD:?Set SRC_PASSWORD in .env.source}"

export PGPASSWORD="$SRC_PASSWORD"
DSN="host=$SRC_HOST port=$SRC_PORT user=$SRC_USER dbname=$SRC_DB connect_timeout=8"
PSQL=(psql "$DSN" -X -q)

# Extensions this repo's image provides (target). Keep in sync with Dockerfile.
PROVIDED="uuid-ossp pgcrypto citext hstore pg_trgm btree_gin btree_gist \
unaccent fuzzystrmatch intarray ltree tablefunc cube earthdistance isn dblink \
pg_stat_statements hypopg pg_hint_plan pgaudit pg_repack vector orafce pg_cron \
pg_partman postgres_fdw file_fdw mysql_fdw tds_fdw plpgsql"

echo "=============================================="
echo " SOURCE COMPATIBILITY REPORT"
echo "=============================================="

echo; echo "## Server version"
"${PSQL[@]}" -tAc "select version();"

echo; echo "## Encoding / collation"
"${PSQL[@]}" -c "select datname, pg_encoding_to_char(encoding) enc, datcollate, datctype \
                 from pg_database where datname = current_database();"

echo; echo "## shared_preload_libraries (cluster-level extensions)"
"${PSQL[@]}" -tAc "show shared_preload_libraries;"

echo; echo "## Extensions in source vs target image"
missing=0
while read -r ext _; do
  [ -z "$ext" ] && continue
  if echo " $PROVIDED " | grep -q " $ext "; then
    printf "  [OK]      %s\n" "$ext"
  else
    printf "  [MISSING] %s  <-- NOT in target image!\n" "$ext"
    missing=1
  fi
done < <("${PSQL[@]}" -tAc "select extname from pg_extension order by 1;")

echo; echo "## Object inventory"
"${PSQL[@]}" -c "select
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
     where c.relkind='r' and n.nspname not like 'pg_%' and n.nspname<>'information_schema') as tables,
  (select count(*) from pg_class where relkind='m') as matviews,
  (select count(*) from pg_class where relkind='f') as foreign_tables,
  (select count(*) from pg_foreign_server) as foreign_servers,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname not like 'pg_%' and n.nspname<>'information_schema') as functions;"

echo; echo "## pg_cron jobs (NOT carried by pg_dump — recreate manually!)"
"${PSQL[@]}" -c "select jobid, schedule, left(command,55) as command, active from cron.job order by jobid;" 2>/dev/null \
  || echo "  (no cron schema / not accessible)"

echo; echo "## Database size"
"${PSQL[@]}" -tAc "select pg_size_pretty(pg_database_size(current_database()));"

echo
if [ "$missing" -eq 0 ]; then
  echo ">>> RESULT: all source extensions are present in the target image. Safe to import."
else
  echo ">>> RESULT: one or more extensions are MISSING in the target image."
  echo "    Add them to the Dockerfile and rebuild before importing."
  exit 1
fi
