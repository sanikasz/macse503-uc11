CREATE TABLE PRS (
    submission_id VARCHAR(20),
    product_id VARCHAR(20),
    trial_id VARCHAR(20),
    regulatory_authority VARCHAR(50),
    submission_type VARCHAR(100),
    submission_date DATE,
    approval_status VARCHAR(50),
    approval_date DATE,
    target_country VARCHAR(50)
);

SELECT * FROM PRS;