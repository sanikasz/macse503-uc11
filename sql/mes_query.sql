CREATE TABLE IF NOT EXISTS staging.stg_mes_batch_production (
    batch_id VARCHAR(20),
    product_id VARCHAR(20),
    plant_id VARCHAR(20),
    production_line VARCHAR(20),
    raw_material_supplier_id VARCHAR(20),
    batch_start_datetime TIMESTAMP,
    batch_end_datetime TIMESTAMP,
    planned_quantity INTEGER,
    actual_quantity INTEGER,
    yield_percent NUMERIC(5,2),
    operator_id VARCHAR(20),
    batch_status VARCHAR(30)
);

SELECT COUNT(*) AS total_records
FROM staging.stg_mes_batch_production;

SELECT *
FROM staging.stg_mes_batch_production
LIMIT 10;

SELECT batch_id, COUNT(*) AS occurrences
FROM staging.stg_mes_batch_production
GROUP BY batch_id
HAVING COUNT(*) > 1;

SELECT
    COUNT(*) AS total_records,
    COUNT(batch_id) AS batch_id_present,
    COUNT(product_id) AS product_id_present,
    COUNT(plant_id) AS plant_id_present,
    COUNT(raw_material_supplier_id) AS supplier_id_present,
    COUNT(batch_start_datetime) AS start_date_present,
    COUNT(batch_end_datetime) AS end_date_present,
    COUNT(planned_quantity) AS planned_qty_present,
    COUNT(actual_quantity) AS actual_qty_present,
    COUNT(yield_percent) AS yield_present
FROM staging.stg_mes_batch_production;