/*
===================================================================
Load Silver Layer: OLX Apartments Listings
===================================================================
Purpose:
    Loads and lightly transforms bronze.olx_apartments_info into
    silver.olx_apartments_info. Currently applies one cleanup rule
    (correcting a known source misspelling in `layout`); extend this
    procedure as further cleaning rules are identified.

Usage:
    CALL silver.load_silver();
===================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP WITH TIME ZONE := NOW();
    end_time TIMESTAMP WITH TIME ZONE;
BEGIN
    RAISE NOTICE 'Truncating Table: silver.olx_apartments_info';
    TRUNCATE TABLE silver.olx_apartments_info;

    RAISE NOTICE '=========================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '=========================';

    -- Explicit column list: dwh_created_date is intentionally omitted
    -- so it falls back to its DEFAULT CURRENT_TIMESTAMP.
    INSERT INTO silver.olx_apartments_info (
        listing_id,
        price_usd,
        price_per_sqr,
        listing_type,
        commission,
        negotiable,
        published_date,
        date_scraped,
        url,
        description,
        housing_type,
        rooms,
        total_area_m2,
        floor,
        total_floors,
        building_type,
        layout,
        build_year,
        age,
        ceiling_height,
        bathroom,
        furnished,
        renovation,
        seller_type,
        region,
        district,
        amenity_air_conditioning,
        amenity_balcony,
        amenity_cable_tv,
        amenity_internet,
        amenity_kitchen,
        amenity_refrigerator,
        amenity_tv,
        amenity_telephone,
        amenity_washing_machine,
        nearby_bus_stop,
        nearby_cafe,
        nearby_clinic,
        nearby_entertainment,
        nearby_green_area,
        nearby_hospital,
        nearby_kindergarten,
        nearby_park,
        nearby_parking,
        nearby_playground,
        nearby_restaurant,
        nearby_school,
        nearby_shops,
        nearby_supermarket,
        near_metro_mentioned
    )
    SELECT
        listing_id,
        price_usd,
        price_per_sqr,
        listing_type,
        commission,
        negotiable,
        published_date,
        date_scraped,
        url,
        description,
        housing_type,
        rooms,
        total_area_m2,
        floor,
        total_floors,
        building_type,
        -- Source data has a known misspelling for this layout value; corrected here.
        CASE
            WHEN layout = 'adjacent_seperated' THEN 'adjacent_separated'
            ELSE layout
        END AS layout,
        build_year,
        age,
        ceiling_height,
        bathroom,
        furnished,
        renovation,
        seller_type,
        region,
        district,
        amenity_air_conditioning,
        amenity_balcony,
        amenity_cable_tv,
        amenity_internet,
        amenity_kitchen,
        amenity_refrigerator,
        amenity_tv,
        amenity_telephone,
        amenity_washing_machine,
        nearby_bus_stop,
        nearby_cafe,
        nearby_clinic,
        nearby_entertainment,
        nearby_green_area,
        nearby_hospital,
        nearby_kindergarten,
        nearby_park,
        nearby_parking,
        nearby_playground,
        nearby_restaurant,
        nearby_school,
        nearby_shops,
        nearby_supermarket,
        near_metro_mentioned
    FROM
        bronze.olx_apartments_info
    WHERE price_usd > 0;

    end_time := NOW();
    RAISE NOTICE 'Load duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error loading silver layer: %', SQLERRM;
        RAISE;
END;
$$;

CALL silver.load_silver();

