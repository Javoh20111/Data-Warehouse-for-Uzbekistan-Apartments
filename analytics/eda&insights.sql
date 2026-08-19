-- Ranks regions by the number of apartment sale listings and shows the median sale price for each region.

SELECT
    region,
    listings,
    median,
    RANK() OVER(ORDER BY listings DESC) AS rank
FROM (
    SELECT
        dl.region,
        COUNT(*) as listings,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fl.price_usd)::INTEGER AS median
    FROM gold.fact_listing fl
    LEFT JOIN gold.dim_location dl
        ON fl.location_dim_id = dl.location_dim_id
    WHERE fl.listing_type = 'Sale'
    GROUP BY dl.region 
) regional_stats;


/*
Identifies the 5 cheapest and 5 most expensive districts for sale listings 
based on median price per square meter, considering only districts with more than 100 listings.
*/

-- Optimize downstream queries by indexing only 'Sale' listings rather than the entire table
CREATE OR REPLACE INDEX idx_filter_listing_type ON gold.fact_listing (listing_type)
WHERE listing_type = 'Sale';

WITH expensive_districts AS (
    SELECT
        dl.district AS district,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY fl.price_per_sqr) as median_usd_per_sqr
    FROM gold.fact_listing fl
    LEFT JOIN gold.dim_location dl
        ON fl.location_dim_id = dl.location_dim_id
    WHERE fl.listing_type = 'Sale'
    GROUP BY dl.district
    HAVING COUNT(*) > 100 -- Filter out low-volume districts to prevent small sample size bias
)
SELECT
    district,
    median_usd_per_sqr
FROM expensive_districts
ORDER BY median_usd_per_sqr DESC
LIMIT 5;

WITH cheap_districts AS (
    SELECT
        dl.district AS district,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY fl.price_per_sqr) as median_usd_per_sqr
    FROM gold.fact_listing fl
    LEFT JOIN gold.dim_location dl
        ON fl.location_dim_id = dl.location_dim_id
    WHERE fl.listing_type = 'Sale'
    GROUP BY dl.district
    HAVING COUNT(*) > 100 -- Filter out low-volume districts to prevent small sample size bias
)
SELECT
    district,
    median_usd_per_sqr
FROM cheap_districts
ORDER BY median_usd_per_sqr ASC
LIMIT 5;

--



-- Purpose: Calculates the median price per square unit for 'Sale' listings by region and categorizes each region as 'Above Average' or 'Below Average' relative to the overall average across all regions.

SELECT
    region,
    median_usd_per_sqr,
    -- OVER() clause allows comparing each row's median against the global average across all regions
    CASE 
        WHEN median_usd_per_sqr > AVG(median_usd_per_sqr) OVER() THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_per_sqr_category,
    AVG(median_usd_per_sqr) OVER() AS average_price
FROM (
    SELECT
        dl.region AS region,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY fl.price_per_sqr) AS median_usd_per_sqr
    FROM gold.fact_listing fl
    LEFT JOIN gold.dim_location dl
        ON fl.location_dim_id = dl.location_dim_id
    WHERE fl.listing_type = 'Sale'
    GROUP BY dl.region
) AS regional_medians
ORDER BY median_usd_per_sqr DESC;



-- Purpose: Calculates the percentage breakdown of 'Sale' vs. 'Rent' listings for each region relative to total regional inventory.

WITH sale_percentage_per_region AS (
    SELECT
        dl.region AS region,
        COUNT(*) AS sale_count
    FROM gold.fact_listing fl
    LEFT JOIN gold.dim_location dl
        ON fl.location_dim_id = dl.location_dim_id
    WHERE fl.listing_type = 'Sale'
    GROUP BY dl.region
), rent_percentage_per_region AS (
    SELECT
        dl.region AS region,
        COUNT(*) AS rent_count
    FROM gold.fact_listing fl
    LEFT JOIN gold.dim_location dl
        ON fl.location_dim_id = dl.location_dim_id
    WHERE fl.listing_type = 'Rent'
    GROUP BY dl.region
)
SELECT
    COALESCE(sp.region, rp.region) AS region,
    -- Multiply by 1.0 to force float division and COALESCE NULLs for regions missing sales or rentals
    CONCAT(((COALESCE(sp.sale_count, 0) * 1.0 / (COALESCE(sp.sale_count, 0) + COALESCE(rp.rent_count, 0))) * 100)::INTEGER, '%') AS sales_percentage,
    CONCAT(((COALESCE(rp.rent_count, 0) * 1.0 / (COALESCE(sp.sale_count, 0) + COALESCE(rp.rent_count, 0))) * 100)::INTEGER, '%') AS rent_percentage
FROM sale_percentage_per_region sp
-- FULL OUTER JOIN ensures regions with only sales or only rentals are preserved
FULL OUTER JOIN rent_percentage_per_region rp
    ON sp.region = rp.region
ORDER BY sales_percentage DESC;



