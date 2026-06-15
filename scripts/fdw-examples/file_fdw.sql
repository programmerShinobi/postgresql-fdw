-- =============================================================================
-- Example: file_fdw  (read a CSV file as a table)
-- The file must be readable INSIDE the container. Mount it via docker-compose,
-- e.g. add to volumes:  - ./data/sample.csv:/data/sample.csv:ro
-- =============================================================================

CREATE SERVER IF NOT EXISTS file_server
    FOREIGN DATA WRAPPER file_fdw;

-- CREATE FOREIGN TABLE csv_people (
--     id   int,
--     name text,
--     city text
-- ) SERVER file_server
--   OPTIONS (filename '/data/sample.csv', format 'csv', header 'true');

-- SELECT city, count(*) FROM csv_people GROUP BY city ORDER BY 2 DESC;
