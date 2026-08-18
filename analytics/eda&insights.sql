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
WITH median_price_per_sqr_by_region AS(
    
)



