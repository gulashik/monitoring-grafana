CREATE TABLE IF NOT EXISTS business_metrics (
    day DATE PRIMARY KEY,
    visitors INTEGER NOT NULL,
    leads INTEGER NOT NULL,
    orders INTEGER NOT NULL,
    revenue NUMERIC(12, 2) NOT NULL,
    conversion_rate NUMERIC(8, 4) NOT NULL,
    cac NUMERIC(10, 2) NOT NULL,
    ltv NUMERIC(10, 2) NOT NULL
);
