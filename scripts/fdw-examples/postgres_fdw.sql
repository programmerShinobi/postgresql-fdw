-- =============================================================================
-- Example: postgres_fdw  (query another PostgreSQL server)
-- These are NOT auto-run — copy/paste and adapt to a real remote server.
-- =============================================================================

-- 1) Define the remote server.
CREATE SERVER IF NOT EXISTS remote_pg
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'remote-postgres.example.com', port '5432', dbname 'remote_db');

-- 2) Map your local user to a remote login.
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER remote_pg
    OPTIONS (user 'remote_user', password 'remote_password');

-- 3a) Import an entire remote schema as foreign tables.
-- IMPORT FOREIGN SCHEMA public
--     FROM SERVER remote_pg INTO public;

-- 3b) ...or declare a single foreign table by hand.
-- CREATE FOREIGN TABLE remote_customers (
--     id    bigint,
--     name  text,
--     email text
-- ) SERVER remote_pg OPTIONS (schema_name 'public', table_name 'customers');

-- 4) Query it like a local table:
-- SELECT * FROM remote_customers LIMIT 10;
