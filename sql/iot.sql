CREATE TABLE IES (
    reading_id VARCHAR(20),
    product_id VARCHAR(20),
    batch_id VARCHAR(20),
    plant_id VARCHAR(20),
    production_line VARCHAR(20),
    equipment_id VARCHAR(20),
    reading_timestamp TIMESTAMP,
    temperature_c NUMERIC(10,2),
    humidity_percent NUMERIC(10,2),
    pressure_bar NUMERIC(10,3),
    vibration_mm_s NUMERIC(10,3),
    equipment_status VARCHAR(20)
);

SELECT * FROM IES