CREATE TABLE IF NOT EXISTS business_metrics (
    day TIMESTAMP PRIMARY KEY,
    visitors INTEGER NOT NULL,
    leads INTEGER NOT NULL,
    orders INTEGER NOT NULL,
    revenue NUMERIC(12, 2) NOT NULL,
    conversion_rate NUMERIC(8, 4) NOT NULL,
    cac NUMERIC(10, 2) NOT NULL,
    ltv NUMERIC(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS grafana_demo_metrics (
    id BIGSERIAL PRIMARY KEY,
    measured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    country_code_2 CHAR(2) NOT NULL,
    country_code_3 CHAR(3) NOT NULL,
    department TEXT NOT NULL,
    active_users INTEGER NOT NULL,
    orders INTEGER NOT NULL,
    revenue NUMERIC(12, 2) NOT NULL,
    response_ms NUMERIC(8, 2) NOT NULL,
    cpu_load NUMERIC(5, 2) NOT NULL,
    conversion_rate NUMERIC(6, 4) NOT NULL
);

CREATE INDEX IF NOT EXISTS grafana_demo_metrics_measured_at_idx
    ON grafana_demo_metrics (measured_at);

CREATE OR REPLACE PROCEDURE insert_grafana_demo_metric()
LANGUAGE plpgsql
AS $$
DECLARE
    country_index INTEGER;
    department_index INTEGER;
    country_code_2_values TEXT[] := ARRAY['US', 'GB', 'DE', 'FR', 'BR', 'IN', 'JP', 'AU'];
    country_code_3_values TEXT[] := ARRAY['USA', 'GBR', 'DEU', 'FRA', 'BRA', 'IND', 'JPN', 'AUS'];
    department_values TEXT[] := ARRAY['sales', 'support', 'marketing', 'finance', 'platform', 'delivery'];
BEGIN
    LOOP
        country_index := floor(random() * array_length(country_code_2_values, 1) + 1);
        department_index := floor(random() * array_length(department_values, 1) + 1);

        INSERT INTO grafana_demo_metrics (
            measured_at,
            country_code_2,
            country_code_3,
            department,
            active_users,
            orders,
            revenue,
            response_ms,
            cpu_load,
            conversion_rate
        )
        VALUES (
            now(),
            country_code_2_values[country_index],
            country_code_3_values[country_index],
            department_values[department_index],
            floor(random() * 900 + 100)::INTEGER,
            floor(random() * 80 + 1)::INTEGER,
            round((random() * 50000 + 1000)::NUMERIC, 2),
            round((random() * 900 + 50)::NUMERIC, 2),
            round((random() * 95 + 1)::NUMERIC, 2),
            round((random() * 0.18 + 0.01)::NUMERIC, 4)
        );

        DELETE FROM grafana_demo_metrics
        WHERE id IN (
            SELECT id
            FROM grafana_demo_metrics
            ORDER BY measured_at DESC, id DESC
            OFFSET 1024
        );

        COMMIT;

        PERFORM pg_sleep(random() * 4 + 1);
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE insert_business_metrics()
LANGUAGE plpgsql
AS $$
BEGIN
    LOOP
        INSERT INTO business_metrics (
            day,
            visitors,
            leads,
            orders,
            revenue,
            conversion_rate,
            cac,
            ltv
        )
        VALUES (
                   now(),
            floor(random() * 1000 + 500)::INTEGER,
            floor(random() * 100 + 50)::INTEGER,
            floor(random() * 30 + 10)::INTEGER,
            round((random() * 100000 + 50000)::NUMERIC, 2),
            round((random() * 0.05 + 0.01)::NUMERIC, 4),
            round((random() * 500 + 500)::NUMERIC, 2),
            round((random() * 2000 + 5000)::NUMERIC, 2)
        );

        DELETE FROM business_metrics
        WHERE CTID IN (
            SELECT CTID
            FROM business_metrics
            ORDER BY DAY DESC
            OFFSET 1024
        );

        COMMIT;

        PERFORM pg_sleep(random() * 4 + 1);
    END LOOP;
END;
$$;
