#!/usr/bin/env bash
# =============================================================================
# import-from-source.sh
# Dumps a SOURCE PostgreSQL and restores it into this repo's running target,
# using the TARGET CONTAINER's pg_dump/pg_restore (PostgreSQL 17) so the client
# version always >= the source. The dump file lands in ./backups.
#
# Credentials are read from `.env.source` (gitignored). Never hardcode them.
#   cp .env.source.example .env.source   # then fill it in
#   make up                              # target must be running
#   ./scripts/migration/import-from-source.sh
#
# Notes:
#  * Restores with --no-owner --no-privileges so objects end up owned by the
#    target superuser (local_dev). See doc 11 for the FDW user-mapping caveat.
#  * Re-creates pg_cron jobs afterwards (pg_dump never carries them).
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
[ -f .env.source ] && { set -a; . ./.env.source; set +a; }
[ -f .env ]        && { set -a; . ./.env;        set +a; }

: "${SRC_HOST:?Set SRC_HOST in .env.source}"
: "${SRC_PORT:?Set SRC_PORT in .env.source}"
: "${SRC_USER:?Set SRC_USER in .env.source}"
: "${SRC_DB:?Set SRC_DB in .env.source}"
: "${SRC_PASSWORD:?Set SRC_PASSWORD in .env.source}"

TGT_USER="${POSTGRES_USER:-local_dev}"
TGT_DB="${POSTGRES_DB:-local_db}"
DUMP="/backups/source_$(date +%Y%m%d_%H%M%S).dump"
DC="docker compose"

echo ">>> 1/3  Dumping source via the target container's pg_dump (v17)..."
$DC exec -T -e PGPASSWORD="$SRC_PASSWORD" postgres \
  pg_dump -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$SRC_DB" \
          -Fc --no-owner --no-privileges --verbose -f "$DUMP"

echo ">>> 2/3  Restoring into target ${TGT_DB}..."
$DC exec -T postgres \
  pg_restore --no-owner --no-privileges --clean --if-exists \
             -U "$TGT_USER" -d "$TGT_DB" "$DUMP" || \
  echo "    (pg_restore reported non-fatal warnings — review the output above)"

echo ">>> 3/3  Re-creating pg_cron jobs (not carried by pg_dump)..."
$DC exec -T postgres psql -U "$TGT_USER" -d "$TGT_DB" \
  -f /opt/migration/recreate-cron-jobs.sql 2>/dev/null || \
  echo "    Run manually: docker compose exec -T postgres psql -U $TGT_USER -d $TGT_DB -f /opt/migration/recreate-cron-jobs.sql"

echo
echo ">>> Done. Verify:"
echo "    make extensions"
echo "    docker compose exec -T postgres psql -U $TGT_USER -d $TGT_DB -c '\\dt'"
echo "    docker compose exec -T postgres psql -U $TGT_USER -d $TGT_DB -c 'SELECT * FROM cron.job;'"
