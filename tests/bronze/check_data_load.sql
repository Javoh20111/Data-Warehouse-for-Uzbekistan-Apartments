/*
===================================================================
Test: bronze.olx_apartments_info is not empty
===================================================================
Purpose:
    Sanity check that CALL bronze.load_bronze(...) actually loaded
    rows, rather than succeeding silently against an empty/missing
    CSV.
===================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.check_load()
LANGUAGE plpgsql
AS $$
DECLARE 
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count
    FROM bronze.olx_apartments_info;

    IF row_count = 0 THEN 
        RAISE NOTICE 'FAILED: bronze.olx_apartments_info has 0 rows';
    END IF;

    RAISE NOTICE 'PASSED: bronze.olx_apartments_info has % rows',
    row_count;

END;
$$;

CALL bronze.check_load();