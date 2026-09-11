CREATE TABLE IF NOT EXISTS staging.stg_erp_supplier_master (
    supplier_id VARCHAR(20),
    product_id VARCHAR(20),
    supplier_name VARCHAR(150),
    country VARCHAR(50),
    material_type VARCHAR(100),
    certification_status VARCHAR(100),
    lead_time_days INTEGER,
    quality_rating NUMERIC(3,1),
    contract_start_date DATE,
    is_approved VARCHAR(10)
);

SELECT COUNT(*) AS total_records
FROM staging.stg_erp_supplier_master;

SELECT *
FROM staging.stg_erp_supplier_master
LIMIT 10;

SELECT supplier_id, COUNT(*) AS occurrences
FROM staging.stg_erp_supplier_master
GROUP BY supplier_id
HAVING COUNT(*) > 1;