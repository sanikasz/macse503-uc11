
INSERT INTO dw.dim_product (
    product_id, product_name, drug_category, dosage_form,
    strength, unit_of_measure, standard_cost_usd,
    shelf_life_months, primary_plant_id, is_active
)
SELECT
    product_id, product_name, drug_category, dosage_form,
    strength, unit_of_measure, standard_cost_usd,
    shelf_life_months, primary_plant_id, is_active
FROM staging.stg_erp_product_master
WHERE product_id IS NOT NULL
ON CONFLICT (product_id) DO NOTHING;



INSERT INTO dw.dim_supplier (
    supplier_id, supplier_name, country, material_type,
    certification_status, lead_time_days, quality_rating,
    contract_start_date, is_approved
)
SELECT
    supplier_id, supplier_name, country, material_type,
    certification_status, lead_time_days, quality_rating,
    contract_start_date, is_approved
FROM staging.stg_erp_supplier_master
WHERE supplier_id IS NOT NULL
ON CONFLICT (supplier_id) DO NOTHING;



INSERT INTO dw.dim_plant (plant_id)
SELECT plant_id
FROM (
    SELECT primary_plant_id AS plant_id
    FROM staging.stg_erp_product_master

    UNION

    SELECT plant_id
    FROM staging.stg_mes_batch_production

    UNION

    SELECT plant_id
    FROM staging.stg_qms_quality_deviations

    UNION

    SELECT plant_id
    FROM staging.stg_iot_equipment_sensors
) AS plants
WHERE plant_id IS NOT NULL
ON CONFLICT (plant_id) DO NOTHING;



INSERT INTO dw.dim_warehouse (warehouse_id)
SELECT warehouse_id
FROM staging.stg_wms_warehouse_inventory
WHERE warehouse_id IS NOT NULL

UNION

SELECT origin_warehouse_id
FROM staging.stg_supply_chain_shipments
WHERE origin_warehouse_id IS NOT NULL

ON CONFLICT (warehouse_id) DO NOTHING;



INSERT INTO dw.bridge_supplier_product (
    supplier_key, product_key
)
SELECT
    s.supplier_key,
    p.product_key
FROM staging.stg_erp_supplier_master src
JOIN dw.dim_supplier s
    ON s.supplier_id = src.supplier_id
JOIN dw.dim_product p
    ON p.product_id = src.product_id
WHERE src.supplier_id IS NOT NULL
  AND src.product_id IS NOT NULL
ON CONFLICT (supplier_key, product_key) DO NOTHING;


SELECT 'dim_product' AS table_name, COUNT(*) AS rows_loaded
FROM dw.dim_product

UNION ALL
SELECT 'dim_supplier', COUNT(*)
FROM dw.dim_supplier

UNION ALL
SELECT 'dim_plant', COUNT(*)
FROM dw.dim_plant

UNION ALL
SELECT 'dim_warehouse', COUNT(*)
FROM dw.dim_warehouse

UNION ALL
SELECT 'dim_date', COUNT(*)
FROM dw.dim_date

UNION ALL
SELECT 'bridge_supplier_product', COUNT(*)
FROM dw.bridge_supplier_product;





INSERT INTO dw.fact_batch_production (
    batch_id, product_key, plant_key, supplier_key,
    start_date_key, end_date_key, production_line,
    operator_id, batch_status, planned_quantity,
    actual_quantity, yield_percent, batch_duration_hours
)
SELECT
    m.batch_id,
    p.product_key,
    pl.plant_key,
    s.supplier_key,
    ds.date_key,
    de.date_key,
    m.production_line,
    m.operator_id,
    m.batch_status,
    m.planned_quantity,
    m.actual_quantity,
    m.yield_percent,
    EXTRACT(EPOCH FROM
        (m.batch_end_datetime - m.batch_start_datetime)
    ) / 3600.0
FROM staging.stg_mes_batch_production m
LEFT JOIN dw.dim_product p ON p.product_id = m.product_id
LEFT JOIN dw.dim_plant pl ON pl.plant_id = m.plant_id
LEFT JOIN dw.dim_supplier s
    ON s.supplier_id = m.raw_material_supplier_id
LEFT JOIN dw.dim_date ds
    ON ds.full_date = m.batch_start_datetime::date
LEFT JOIN dw.dim_date de
    ON de.full_date = m.batch_end_datetime::date
WHERE m.batch_id IS NOT NULL
ON CONFLICT (batch_id) DO NOTHING;


SELECT COUNT(*) AS batches_loaded
FROM dw.fact_batch_production;

SELECT *
FROM dw.fact_batch_production
ORDER BY batch_production_key
LIMIT 10;



INSERT INTO dw.fact_lab_test (
    test_id,
    batch_id,
    product_key,
    test_date_key,
    test_type,
    result_value,
    unit,
    specification_min,
    specification_max,
    result_status,
    tested_by,
    is_out_of_spec
)
SELECT
    l.test_id,
    l.batch_id,
    p.product_key,
    d.date_key,
    l.test_type,
    l.result_value,
    l.unit,
    l.specification_min,
    l.specification_max,
    l.result_status,
    l.tested_by,
    CASE
        WHEN l.result_value IS NULL THEN NULL
        WHEN l.specification_min IS NOT NULL
             AND l.result_value < l.specification_min THEN TRUE
        WHEN l.specification_max IS NOT NULL
             AND l.result_value > l.specification_max THEN TRUE
        WHEN l.specification_min IS NOT NULL
             AND l.specification_max IS NOT NULL THEN FALSE
        ELSE NULL
    END
FROM staging.stg_lims_lab_test_results l
LEFT JOIN dw.dim_product p
    ON p.product_id = l.product_id
LEFT JOIN dw.dim_date d
    ON d.full_date = l.test_date
WHERE l.test_id IS NOT NULL
ON CONFLICT (test_id) DO NOTHING;



SELECT
    COUNT(*) AS tests_loaded,
    COUNT(*) FILTER (
        WHERE is_out_of_spec = TRUE
    ) AS out_of_spec_tests,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE test_date_key IS NULL
    ) AS missing_date_keys
FROM dw.fact_lab_test;


INSERT INTO dw.fact_quality_deviation (
    deviation_id,
    product_key,
    plant_key,
    reported_date_key,
    closed_date_key,
    batch_id,
    deviation_type,
    severity,
    root_cause_code,
    capa_status,
    days_to_close
)
SELECT
    q.deviation_id,
    p.product_key,
    pl.plant_key,
    rd.date_key,
    cd.date_key,
    q.batch_id,
    q.deviation_type,
    q.severity,
    q.root_cause_code,
    q.capa_status,
    CASE
        WHEN q.reported_date IS NOT NULL
         AND q.closed_date IS NOT NULL
        THEN q.closed_date - q.reported_date
        ELSE NULL
    END
FROM staging.stg_qms_quality_deviations q
LEFT JOIN dw.dim_product p
    ON p.product_id = q.product_id
LEFT JOIN dw.dim_plant pl
    ON pl.plant_id = q.plant_id
LEFT JOIN dw.dim_date rd
    ON rd.full_date = q.reported_date
LEFT JOIN dw.dim_date cd
    ON cd.full_date = q.closed_date
WHERE q.deviation_id IS NOT NULL
ON CONFLICT (deviation_id) DO NOTHING;



SELECT
    COUNT(*) AS deviations_loaded,
    COUNT(*) FILTER (
        WHERE closed_date_key IS NULL
    ) AS without_closure_date,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE reported_date_key IS NULL
    ) AS missing_reported_dates
FROM dw.fact_quality_deviation;



INSERT INTO dw.fact_clinical_trial (
    trial_id,
    product_key,
    start_date_key,
    end_date_key,
    phase,
    site_id,
    country,
    trial_status,
    enrolled_patients,
    adverse_event_count
)
SELECT
    t.trial_id,
    p.product_key,
    sd.date_key,
    ed.date_key,
    t.phase,
    t.site_id,
    t.country,
    t.trial_status,
    t.enrolled_patients,
    t.adverse_event_count
FROM staging.stg_ctms_clinical_trials t
LEFT JOIN dw.dim_product p
    ON p.product_id = t.product_id
LEFT JOIN dw.dim_date sd
    ON sd.full_date = t.start_date
LEFT JOIN dw.dim_date ed
    ON ed.full_date = t.end_date
WHERE t.trial_id IS NOT NULL
ON CONFLICT (trial_id) DO NOTHING;


SELECT
    COUNT(*) AS trials_loaded,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE start_date_key IS NULL
    ) AS missing_start_dates
FROM dw.fact_clinical_trial;


INSERT INTO dw.fact_inventory (
    inventory_id,
    product_key,
    warehouse_key,
    expiry_date_key,
    batch_id,
    quantity_on_hand,
    storage_location,
    storage_temp_c,
    stock_status
)
SELECT
    i.inventory_id,
    p.product_key,
    w.warehouse_key,
    d.date_key,
    i.batch_id,
    i.quantity_on_hand,
    i.storage_location,
    i.storage_temp_c,
    i.stock_status
FROM staging.stg_wms_warehouse_inventory i
LEFT JOIN dw.dim_product p
    ON p.product_id = i.product_id
LEFT JOIN dw.dim_warehouse w
    ON w.warehouse_id = i.warehouse_id
LEFT JOIN dw.dim_date d
    ON d.full_date = i.expiry_date
WHERE i.inventory_id IS NOT NULL
ON CONFLICT (inventory_id) DO NOTHING;



SELECT
    COUNT(*) AS inventory_records_loaded,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE warehouse_key IS NULL
    ) AS missing_warehouse_keys,
    COUNT(*) FILTER (
        WHERE expiry_date_key IS NULL
    ) AS missing_expiry_dates
FROM dw.fact_inventory;



INSERT INTO dw.fact_shipment (
    shipment_id,
    product_key,
    warehouse_key,
    ship_date_key,
    delivery_date_key,
    batch_id,
    destination_country,
    carrier,
    shipment_status,
    quantity_shipped,
    transit_days
)
SELECT
    s.shipment_id,
    p.product_key,
    w.warehouse_key,
    sd.date_key,
    dd.date_key,
    s.batch_id,
    s.destination_country,
    s.carrier,
    s.shipment_status,
    s.quantity_shipped,
    CASE
        WHEN s.ship_date IS NOT NULL
         AND s.delivery_date IS NOT NULL
        THEN s.delivery_date - s.ship_date
        ELSE NULL
    END
FROM staging.stg_supply_chain_shipments s
LEFT JOIN dw.dim_product p
    ON p.product_id = s.product_id
LEFT JOIN dw.dim_warehouse w
    ON w.warehouse_id = s.origin_warehouse_id
LEFT JOIN dw.dim_date sd
    ON sd.full_date = s.ship_date
LEFT JOIN dw.dim_date dd
    ON dd.full_date = s.delivery_date
WHERE s.shipment_id IS NOT NULL
ON CONFLICT (shipment_id) DO NOTHING;



SELECT
    COUNT(*) AS shipments_loaded,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE warehouse_key IS NULL
    ) AS missing_warehouse_keys,
    COUNT(*) FILTER (
        WHERE ship_date_key IS NULL
    ) AS missing_ship_dates,
    COUNT(*) FILTER (
        WHERE delivery_date_key IS NULL
    ) AS missing_delivery_dates
FROM dw.fact_shipment;


INSERT INTO dw.fact_regulatory_submission (
    submission_id,
    product_key,
    submission_date_key,
    approval_date_key,
    trial_id,
    regulatory_authority,
    submission_type,
    approval_status,
    target_country,
    days_to_approval
)
SELECT
    r.submission_id,
    p.product_key,
    sd.date_key,
    ad.date_key,
    r.trial_id,
    r.regulatory_authority,
    r.submission_type,
    r.approval_status,
    r.target_country,
    CASE
        WHEN r.submission_date IS NOT NULL
         AND r.approval_date IS NOT NULL
        THEN r.approval_date - r.submission_date
        ELSE NULL
    END
FROM staging.stg_regulatory_submissions r
LEFT JOIN dw.dim_product p
    ON p.product_id = r.product_id
LEFT JOIN dw.dim_date sd
    ON sd.full_date = r.submission_date
LEFT JOIN dw.dim_date ad
    ON ad.full_date = r.approval_date
WHERE r.submission_id IS NOT NULL
ON CONFLICT (submission_id) DO NOTHING;


SELECT
    COUNT(*) AS submissions_loaded,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE submission_date_key IS NULL
    ) AS missing_submission_dates,
    COUNT(*) FILTER (
        WHERE approval_date_key IS NULL
    ) AS missing_approval_dates
FROM dw.fact_regulatory_submission;



INSERT INTO dw.fact_iot_reading (
    reading_id,
    product_key,
    plant_key,
    reading_date_key,
    batch_id,
    production_line,
    equipment_id,
    reading_timestamp,
    temperature_c,
    humidity_percent,
    pressure_bar,
    vibration_mm_s,
    equipment_status
)
SELECT
    i.reading_id,
    p.product_key,
    pl.plant_key,
    d.date_key,
    i.batch_id,
    i.production_line,
    i.equipment_id,
    i.reading_timestamp,
    i.temperature_c,
    i.humidity_percent,
    i.pressure_bar,
    i.vibration_mm_s,
    i.equipment_status
FROM staging.stg_iot_equipment_sensors i
LEFT JOIN dw.dim_product p
    ON p.product_id = i.product_id
LEFT JOIN dw.dim_plant pl
    ON pl.plant_id = i.plant_id
LEFT JOIN dw.dim_date d
    ON d.full_date = i.reading_timestamp::date
WHERE i.reading_id IS NOT NULL
ON CONFLICT (reading_id) DO NOTHING;



SELECT
    COUNT(*) AS readings_loaded,
    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,
    COUNT(*) FILTER (
        WHERE plant_key IS NULL
    ) AS missing_plant_keys,
    COUNT(*) FILTER (
        WHERE reading_date_key IS NULL
    ) AS missing_date_keys
FROM dw.fact_iot_reading;



SELECT 'Batch Production' AS fact_table, COUNT(*) AS rows_loaded
FROM dw.fact_batch_production
UNION ALL
SELECT 'Lab Tests', COUNT(*) FROM dw.fact_lab_test
UNION ALL
SELECT 'Quality Deviations', COUNT(*) FROM dw.fact_quality_deviation
UNION ALL
SELECT 'Clinical Trials', COUNT(*) FROM dw.fact_clinical_trial
UNION ALL
SELECT 'Inventory', COUNT(*) FROM dw.fact_inventory
UNION ALL
SELECT 'Shipments', COUNT(*) FROM dw.fact_shipment
UNION ALL
SELECT 'Regulatory Submissions', COUNT(*)
FROM dw.fact_regulatory_submission
UNION ALL
SELECT 'IoT Readings', COUNT(*) FROM dw.fact_iot_reading
ORDER BY fact_table;


-- Report 1: Production performance by product
SELECT
    p.product_id,
    p.product_name,
    COUNT(f.batch_id) AS total_batches,
    SUM(f.planned_quantity) AS planned_quantity,
    SUM(f.actual_quantity) AS actual_quantity,
    ROUND(AVG(f.yield_percent), 2) AS average_yield_percent
FROM dw.fact_batch_production f
LEFT JOIN dw.dim_product p
    ON p.product_key = f.product_key
GROUP BY p.product_id, p.product_name
ORDER BY total_batches DESC;


-- Report 2: Quality deviations by severity
SELECT
    severity,
    capa_status,
    COUNT(*) AS deviation_count,
    ROUND(AVG(days_to_close), 2) AS average_days_to_close
FROM dw.fact_quality_deviation
GROUP BY severity, capa_status
ORDER BY deviation_count DESC;


-- Report 3: Laboratory out-of-specification results
SELECT
    p.product_id,
    p.product_name,
    COUNT(*) AS total_tests,
    COUNT(*) FILTER (
        WHERE l.is_out_of_spec = TRUE
    ) AS out_of_spec_tests,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE l.is_out_of_spec = TRUE
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS out_of_spec_percent
FROM dw.fact_lab_test l
LEFT JOIN dw.dim_product p
    ON p.product_key = l.product_key
GROUP BY p.product_id, p.product_name
ORDER BY out_of_spec_tests DESC;


