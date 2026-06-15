# syntax=docker/dockerfile:1
#
# PostgreSQL 17 — Development image with a curated set of extensions.
# Base: official postgres:17-bookworm (already wired to the PGDG apt repo,
# so `postgresql-17-*` packages install cleanly).
#
# Build args let you pin everything for reproducible builds.
ARG PG_MAJOR=17
FROM postgres:${PG_MAJOR}-bookworm

ARG PG_MAJOR=17
ARG MYSQL_FDW_VERSION=REL-2_9_3

LABEL org.opencontainers.image.title="postgresql-fdw-dev" \
      org.opencontainers.image.description="PostgreSQL 17 with FDW + common extensions, tuned for laptop development" \
      org.opencontainers.image.licenses="MIT"

# ---------------------------------------------------------------------------
# 1) Extensions available as PGDG apt packages (no compilation needed).
#    These cover FDW, vector search, scheduling, partitioning, auditing, etc.
# ---------------------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        postgresql-${PG_MAJOR}-pgvector \
        postgresql-${PG_MAJOR}-cron \
        postgresql-${PG_MAJOR}-partman \
        postgresql-${PG_MAJOR}-tds-fdw \
        postgresql-${PG_MAJOR}-hypopg \
        postgresql-${PG_MAJOR}-repack \
        postgresql-${PG_MAJOR}-pgaudit \
        postgresql-${PG_MAJOR}-orafce \
        postgresql-${PG_MAJOR}-pg-hint-plan \
    ; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2) mysql_fdw — not packaged for PGDG, so compile from source.
#    We keep the small runtime client lib (libmariadb3) and drop heavy
#    build-only tooling afterwards to keep the image lean.
# ---------------------------------------------------------------------------
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        postgresql-server-dev-${PG_MAJOR} \
        libmariadb-dev \
        libmariadb-dev-compat \
    ; \
    git clone --branch "${MYSQL_FDW_VERSION}" --depth 1 \
        https://github.com/EnterpriseDB/mysql_fdw.git /tmp/mysql_fdw; \
    cd /tmp/mysql_fdw; \
    make USE_PGXS=1; \
    make USE_PGXS=1 install; \
    cd /; \
    rm -rf /tmp/mysql_fdw; \
    # keep the runtime MariaDB client lib that mysql_fdw.so links against
    apt-mark manual libmariadb3; \
    apt-get purge -y --auto-remove \
        build-essential \
        git \
        postgresql-server-dev-${PG_MAJOR} \
        libmariadb-dev \
        libmariadb-dev-compat \
    ; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 3) Bundle the tuned configuration into the image as a fallback default.
#    docker-compose still mounts ./config/* so you can edit without rebuilds.
# ---------------------------------------------------------------------------
COPY config/postgresql.conf /etc/postgresql/postgresql.conf

# A simple in-image healthcheck (compose defines its own as well).
HEALTHCHECK --interval=10s --timeout=5s --start-period=40s --retries=5 \
    CMD pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" || exit 1
