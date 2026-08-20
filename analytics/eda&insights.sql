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
    "region","listings","median","rank"
    "Tashkent Region","50463",90000,"1"
    "Bukhara Region","2522",45900,"2"
    "Samarkand Region","2279",63000,"3"
    "Navoiy Region","675",38346,"4"
    "Fergana Region","419",29800,"5"
    "Kashkadarya Region","239",35433,"6"
    "Khorezm Region","171",35000,"7"
    "Republic of Karakalpakstan","124",28937,"8"
    "Surxondaryo Region","116",34843,"9"
    "Jizzakh Region","91",31496,"10"
    "Andijan Region","88",35500,"11"
    "Sirdaryo Region","84",31535,"12"
    "Namangan Region","32",37217,"13"
 */

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
/* 
    "district","median_usd_per_sqr"
    "Mirabad",1953.12
    "Yakkasaray",1800
    "Shaykhantakhur",1764.71
    "Mirzo Ulugbek",1545.45
    "Yunusabad",1458.895

 */

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
/* 
    "district","median_usd_per_sqr"
    "Nukus",424.32
    "Fergana",500
    "Karshi",524.095
    "Urgench",526.2449999999999
    "Nurafshan (Toytepa)",535.43
 */



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
/*
    "region","median_usd_per_sqr","price_per_sqr_category","average_price"
    "Tashkent Region",1473.21,"Above Average",649.5611538461538
    "Samarkand Region",1000,"Above Average",649.5611538461538
    "Bukhara Region",690.38,"Above Average",649.5611538461538
    "Navoiy Region",601.19,"Below Average",649.5611538461538
    "Andijan Region",593.59,"Below Average",649.5611538461538
    "Namangan Region",591.0550000000001,"Below Average",649.5611538461538
    "Surxondaryo Region",559.2,"Below Average",649.5611538461538
    "Kashkadarya Region",520,"Below Average",649.5611538461538
    "Jizzakh Region",511.81,"Below Average",649.5611538461538
    "Sirdaryo Region",511.51,"Below Average",649.5611538461538
    "Khorezm Region",501.07,"Below Average",649.5611538461538
    "Fergana Region",486.11,"Below Average",649.5611538461538
    "Republic of Karakalpakstan",405.16999999999996,"Below Average",649.5611538461538
*/


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

/* 
    "region","sales_percentage","rent_percentage"
    "Navoiy Region","74%","26%"
    "Sirdaryo Region","74%","26%"
    "Bukhara Region","72%","28%"
    "Tashkent Region","65%","35%"
    "Jizzakh Region","65%","35%"
    "Surxondaryo Region","60%","40%"
    "Kashkadarya Region","58%","42%"
    "Republic of Karakalpakstan","57%","43%"
    "Samarkand Region","55%","45%"
    "Andijan Region","50%","50%"
    "Fergana Region","48%","52%"
    "Namangan Region","38%","62%"
    "Khorezm Region","38%","62%"

 */


-- Compares median apartment prices by number of rooms and calculates the percentage change from the previous room category.
WITH cte as(
    SELECT
        rooms,
        current,
        LAG(current) OVER(ORDER BY rooms) as pervius
    FROM(
        SELECT
            rooms,
            PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY fl.price_usd) AS current
        FROM gold.fact_listing fl
        LEFT JOIN gold.dim_location dl 
            ON fl.location_dim_id = dl.location_dim_id
        WHERE fl.listing_type = 'Sale' AND dl.region = 'Tashkent Region'
        GROUP BY rooms
        ) AS bp
)

SELECT
    rooms,
    current,
    pervius,
    CONCAT(ROUND(((current - pervius)/pervius * 100)::NUMERIC, 2),'%') AS percentage_increase
FROM cte;

/* 
    "rooms","current","pervius","percentage_increase"
    1,53125,"","%"
    2,77500,53125,"45.88%"
    3,115000,77500,"48.39%"
    4,148000,115000,"28.70%"
    5,185000,148000,"25.00%"
    6,250000,185000,"35.14%"
 */

