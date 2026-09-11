CREATE TABLE IF NOT EXISTS staging.stg_lims_lab_test_results (
    test_id VARCHAR(20),
    batch_id VARCHAR(20),
    product_id VARCHAR(20),
    test_type VARCHAR(50),
    result_value NUMERIC(10,2),
    unit VARCHAR(20),
    specification_min NUMERIC(10,2),
    specification_max NUMERIC(10,2),
    result_status VARCHAR(20),
    tested_by VARCHAR(20),
    test_date DATE
);

SELECT COUNT(*) AS total_records
FROM staging.stg_lims_lab_test_results;

SELECT *
FROM staging.stg_lims_lab_test_results
LIMIT 10;

SELECT test_id, COUNT(*) AS occurrences
FROM staging.stg_lims_lab_test_results
GROUP BY test_id
HAVING COUNT(*) > 1;

SELECT *
FROM staging.stg_lims_lab_test_results;

SELECT
    COUNT(*) AS total_records,
    COUNT(test_id) AS test_id_present,
    COUNT(batch_id) AS batch_id_present,
    COUNT(product_id) AS product_id_present,
    COUNT(test_type) AS test_type_present,
    COUNT(result_value) AS result_value_present,
    COUNT(unit) AS unit_present,
    COUNT(specification_min) AS specification_min_present,
    COUNT(specification_max) AS specification_max_present,
    COUNT(result_status) AS result_status_present,
    COUNT(tested_by) AS tested_by_present,
    COUNT(test_date) AS test_date_present
FROM staging.stg_lims_lab_test_results;