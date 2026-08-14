/*
===================================================================
Load Bronze Layer: OLX Apartments Listings
===================================================================
Purpose:
    Loads the cleaned dataset CSV into bronze.olx_apartments_info.
    Uses psql's client-side \copy so the file is read from wherever
    this script is run, rather than requiring the Postgres server
    process itself to have filesystem access to the file.
 
Usage:
    Run from the repository root using psql:
        psql -U <user> -d apartments_dwh_proj -f load_bronze.sql
 
    The path below is relative to the repository root — adjust the
    working directory (not the path) if running from elsewhere.
===================================================================
*/
 
-- Clear existing rows so this script is safe to re-run
TRUNCATE TABLE bronze.olx_apartments_info;
 
\copy bronze.olx_apartments_info FROM './dataset/database.csv' WITH (FORMAT CSV, HEADER);
 