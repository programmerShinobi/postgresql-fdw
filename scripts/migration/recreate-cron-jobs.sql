-- =============================================================================
-- recreate-cron-jobs.sql
-- pg_cron jobs live in the `cron` schema (extension-owned) and are NOT carried
-- over by pg_dump/pg_restore. Re-create them on the TARGET after importing.
--
-- These mirror the 5 jobs found on the source database.
-- They run in the database set by cron.database_name (= local_db).
--
-- Run:  make psql   then   \i /opt/fdw-examples/../migration/recreate-cron-jobs.sql
--   or:  docker compose exec -T postgres psql -U local_dev -d local_db -f -
-- =============================================================================

-- Hourly at :50 — refresh dashboards
SELECT cron.schedule('refresh_mv_b777_300_a',       '50 * * * *',
       'REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_b777_300_a');
SELECT cron.schedule('refresh_mv_hil_followon_open','50 * * * *',
       'REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_hil_followon_open');
SELECT cron.schedule('refresh_mv_hil_elastic',      '50 * * * *',
       'REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_hil_elastic');

-- Hourly at :40
SELECT cron.schedule('refresh_mv_lastflight_details','40 * * * *',
       'REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_lastflight_details');
SELECT cron.schedule('refresh_mv_hydraulic',        '40 * * * *',
       'REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_hydraulic');

-- Verify
SELECT jobid, schedule, command, active FROM cron.job ORDER BY jobid;
