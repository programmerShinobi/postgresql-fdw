-- =============================================================================
-- Example: mysql_fdw  (query a MySQL / MariaDB server)
-- =============================================================================

CREATE SERVER IF NOT EXISTS remote_mysql
    FOREIGN DATA WRAPPER mysql_fdw
    OPTIONS (host '10.0.0.20', port '3306');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER remote_mysql
    OPTIONS (username 'mysql_user', password 'mysql_password');

-- Declare a foreign table mapping a MySQL table.
-- CREATE FOREIGN TABLE mysql_orders (
--     id     int,
--     total  numeric(12,2),
--     status varchar(32)
-- ) SERVER remote_mysql OPTIONS (dbname 'shop', table_name 'orders');

-- SELECT * FROM mysql_orders WHERE status = 'paid' LIMIT 10;

-- Tip: mysql_fdw supports IMPORT FOREIGN SCHEMA too:
-- IMPORT FOREIGN SCHEMA shop FROM SERVER remote_mysql INTO public;
