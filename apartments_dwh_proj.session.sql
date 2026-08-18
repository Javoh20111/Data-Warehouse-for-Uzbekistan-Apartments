CREATE TABLE IF NOT EXISTS property_dim (
    property_dim_id SERIAL PRIMARY KEY,
    housing_type TEXT, 
    building_type TEXT, 
    layout TEXT, 
    bathroom TEXT, 
    furnished BOOLEAN, 
    renovation TEXT,
);

CREATE TABLE IF NOT EXISTS location_dim (
    location_dim_id SERIAL PRIMARY KEY,
    region TEXT,
    district TEXT,

    UNIQUE (
        region,
        district
    )
);

CREATE TABLE IF NOT EXISTS listing_fact(
    listing_id TEXT PRIMARY KEY,
    property_dim_id INTEGER NOT NULL,
    location_dim_id INTEGER NOT NULL,

    rooms INTEGER, 
    total_area_m2 FLOAT, 
    floor INTEGER,
    total_floors INTEGER,
    build_year INTEGER, 
    age INTEGER,
    ceiling_height DECIMAL(3,2),

    seller_type TEXT,
    price_usd NUMERIC(12,2) NOT NULL,
    price_per_sqr NUMERIC(10,2),
    listing_type TEXT,
    negotiable BOOLEAN,
    commission BOOLEAN,
    date_scraped DATE,
    description TEXT,
    FOREIGN KEY (property_dim_id) REFERENCES property_dim(property_dim_id),
    FOREIGN KEY (location_dim_id) REFERENCES location_dim(location_dim_id)
);


CREATE TABLE IF NOT EXISTS listing_attributes(
    listing_id TEXT PRIMARY KEY,
    amenity_air_conditioning BOOLEAN,
    amenity_balcony BOOLEAN,
    amenity_cable_tv BOOLEAN,
    amenity_internet BOOLEAN,
    amenity_kitchen BOOLEAN,
    amenity_refrigerator BOOLEAN,
    amenity_tv BOOLEAN,
    amenity_telephone BOOLEAN,
    amenity_washing_machine BOOLEAN,
    nearby_bus_stop BOOLEAN,
    nearby_cafe BOOLEAN,
    nearby_clinic BOOLEAN,
    nearby_entertainment BOOLEAN,
    nearby_green_area BOOLEAN,
    nearby_hospital BOOLEAN,
    nearby_kindergarten BOOLEAN,
    nearby_park BOOLEAN,
    nearby_parking BOOLEAN,
    nearby_playground BOOLEAN,
    near_metro_mentioned BOOLEAN,
    nearby_restaurant BOOLEAN,
    nearby_school BOOLEAN,
    nearby_shops BOOLEAN,
    nearby_supermarket BOOLEAN,
    FOREIGN KEY (listing_id) REFERENCES listing_fact(listing_id)
);
