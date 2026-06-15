-- =============================================================================
-- 00-extensions.sql
-- Runs automatically ONLY on first cluster init (empty data directory),
-- against the database named by POSTGRES_DB (ahi_db).
--
-- Every extension below ships inside the image, so it is "ready to use".
-- =============================================================================

\echo '>>> Creating extensions in database:' :DBNAME

-- ----- Core utilities (PostgreSQL contrib) ----------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";        -- uuid_generate_v4(), etc.
CREATE EXTENSION IF NOT EXISTS pgcrypto;           -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS citext;             -- case-insensitive text
CREATE EXTENSION IF NOT EXISTS hstore;             -- key/value pairs
CREATE EXTENSION IF NOT EXISTS pg_trgm;            -- trigram fuzzy search
CREATE EXTENSION IF NOT EXISTS btree_gin;          -- GIN over scalar types
CREATE EXTENSION IF NOT EXISTS btree_gist;         -- GiST over scalar types
CREATE EXTENSION IF NOT EXISTS unaccent;           -- accent-insensitive search
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;      -- soundex, levenshtein
CREATE EXTENSION IF NOT EXISTS intarray;           -- integer array ops
CREATE EXTENSION IF NOT EXISTS ltree;              -- hierarchical tree labels
CREATE EXTENSION IF NOT EXISTS tablefunc;          -- crosstab / pivot
CREATE EXTENSION IF NOT EXISTS cube;               -- multidimensional cube
CREATE EXTENSION IF NOT EXISTS earthdistance;      -- great-circle distance
CREATE EXTENSION IF NOT EXISTS isn;                -- ISBN/ISSN/EAN13 types
CREATE EXTENSION IF NOT EXISTS dblink;             -- ad-hoc cross-db queries

-- ----- Observability & performance ------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_stat_statements; -- query performance stats
CREATE EXTENSION IF NOT EXISTS hypopg;             -- hypothetical indexes
CREATE EXTENSION IF NOT EXISTS pg_hint_plan;       -- planner hints
CREATE EXTENSION IF NOT EXISTS pgaudit;            -- audit logging
CREATE EXTENSION IF NOT EXISTS pg_repack;          -- bloat removal w/o locks

-- ----- AI / search ----------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;             -- pgvector: embeddings/ANN

-- ----- Compatibility helpers ------------------------------------------------
CREATE EXTENSION IF NOT EXISTS orafce;             -- Oracle-compatible functions

-- ----- Scheduling -----------------------------------------------------------
-- pg_cron lives in the database set by cron.database_name (= ahi_db).
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ----- Partitioning ---------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;

-- ----- Foreign Data Wrappers (the "fdw" in the repo name) -------------------
CREATE EXTENSION IF NOT EXISTS postgres_fdw;       -- -> other PostgreSQL
CREATE EXTENSION IF NOT EXISTS file_fdw;           -- -> CSV / flat files
CREATE EXTENSION IF NOT EXISTS mysql_fdw;          -- -> MySQL / MariaDB
CREATE EXTENSION IF NOT EXISTS tds_fdw;            -- -> SQL Server / Sybase

\echo '>>> Extensions created. Listing:'
SELECT extname AS extension, extversion AS version
FROM pg_extension
ORDER BY extname;
