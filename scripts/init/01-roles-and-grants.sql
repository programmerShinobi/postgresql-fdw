-- =============================================================================
-- 01-roles-and-grants.sql
-- A minimal, sensible baseline so your app doesn't run everything as superuser.
-- Adjust to taste. Runs once on first init against POSTGRES_DB (ahi_db).
-- =============================================================================

-- An application schema (keep app objects out of `public` if you prefer).
CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION CURRENT_USER;

-- A read-only role you can grant to reporting tools / dashboards.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ahi_readonly') THEN
        CREATE ROLE ahi_readonly NOLOGIN;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public, app TO ahi_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public, app TO ahi_readonly;

-- Make future tables inherit the read-only grant automatically.
ALTER DEFAULT PRIVILEGES IN SCHEMA public, app
    GRANT SELECT ON TABLES TO ahi_readonly;

\echo '>>> Baseline schema "app" and role "ahi_readonly" ready.'
