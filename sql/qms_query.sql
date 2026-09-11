CREATE TABLE IF NOT EXISTS staging.stg_qms_quality_deviations (
    deviation_id VARCHAR(20),
    product_id VARCHAR(20),
    batch_id VARCHAR(20),
    plant_id VARCHAR(20),
    deviation_type VARCHAR(50),
    severity VARCHAR(20),
    root_cause_code VARCHAR(20),
    capa_status VARCHAR(20),
    reported_date DATE,
    closed_date DATE
);

SELECT *
FROM staging.stg_qms_quality_deviations
LIMIT 10;

SELECT 
    column_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'stg_qms_quality_deviations'
ORDER BY ordinal_position;

SELECT 
    deviation_id,
    COUNT(*) AS duplicate_count
FROM staging.stg_qms_quality_deviations
GROUP BY deviation_id
HAVING COUNT(*) > 1;

SELECT *
FROM staging.stg_qms_quality_deviations