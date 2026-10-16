-- Manufacturing batch reconciliation
SELECT
    COUNT(*) AS source_batches,
    COUNT(f.batch_id) AS matched_batches,
    COUNT(*) FILTER (
        WHERE f.batch_id IS NULL
    ) AS missing_in_warehouse,
    COUNT(*) FILTER (
        WHERE f.batch_id IS NOT NULL
          AND f.actual_quantity IS DISTINCT FROM
              m.actual_quantity
    ) AS actual_quantity_mismatches,
    COUNT(*) FILTER (
        WHERE f.batch_id IS NOT NULL
          AND f.planned_quantity IS DISTINCT FROM
              m.planned_quantity
    ) AS planned_quantity_mismatches
FROM staging.stg_mes_batch_production m
LEFT JOIN dw.fact_batch_production f
    ON f.batch_id = m.batch_id
WHERE m.batch_id IS NOT NULL;


-- Laboratory result reconciliation
SELECT
    COUNT(*) AS source_tests,
    COUNT(f.test_id) AS matched_tests,
    COUNT(*) FILTER (
        WHERE f.test_id IS NULL
    ) AS missing_in_warehouse,
    COUNT(*) FILTER (
        WHERE f.test_id IS NOT NULL
          AND f.result_value IS DISTINCT FROM
              l.result_value
    ) AS result_value_mismatches,
    COUNT(*) FILTER (
        WHERE f.product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE f.test_date_key IS NULL
    ) AS missing_test_date_keys
FROM staging.stg_lims_lab_test_results l
LEFT JOIN dw.fact_lab_test f
    ON f.test_id = l.test_id
WHERE l.test_id IS NOT NULL;

-- Inventory reconciliation
SELECT
    COUNT(*) AS source_inventory_records,
    COUNT(f.inventory_id) AS matched_records,
    COUNT(*) FILTER (
        WHERE f.inventory_id IS NULL
    ) AS missing_in_warehouse,
    COUNT(*) FILTER (
        WHERE f.inventory_id IS NOT NULL
          AND f.quantity_on_hand IS DISTINCT FROM
              i.quantity_on_hand
    ) AS quantity_mismatches,
    COUNT(*) FILTER (
        WHERE f.product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE f.warehouse_key IS NULL
    ) AS missing_warehouse_keys
FROM staging.stg_wms_warehouse_inventory i
LEFT JOIN dw.fact_inventory f
    ON f.inventory_id = i.inventory_id
WHERE i.inventory_id IS NOT NULL;