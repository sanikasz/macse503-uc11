CREATE TABLE WMS1 (
    inventory_id VARCHAR(20) PRIMARY KEY,
    batch_id VARCHAR(20),
    product_id VARCHAR(20),
    warehouse_id VARCHAR(20),
    quantity_on_hand INTEGER,
    storage_location VARCHAR(50),
    storage_temp_c NUMERIC(5,2),
    expiry_date DATE,
    stock_status VARCHAR(30)
);

SELECT * FROM WMS1;

TRUNCATE TABLE public.WMS1;

SELECT COUNT(*) FROM public.WMS1;

SELECT * FROM public.WMS1 LIMIT 10;