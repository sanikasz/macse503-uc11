CREATE TABLE DE(
    trial_id VARCHAR(20) PRIMARY KEY,
    product_id VARCHAR(20),
    phase VARCHAR(20),
    site_id VARCHAR(20),
    country VARCHAR(50),
    enrolled_patients INTEGER,
    start_date DATE,
    end_date DATE,
    trial_status VARCHAR(30),
    adverse_event_count INTEGER
);

SELECT * FROM DE;

TRUNCATE TABLE public.DE;

SELECT COUNT(*) FROM public.DE;

SELECT * FROM public.DE LIMIT 10;
