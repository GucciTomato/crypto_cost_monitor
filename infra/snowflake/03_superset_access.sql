USE ROLE ACCOUNTADMIN;

-- read only role for the dashboard
CREATE ROLE IF NOT EXISTS reporter;
GRANT USAGE ON WAREHOUSE crypto_wh TO ROLE reporter;
GRANT USAGE ON DATABASE crypto_cost_monitor TO ROLE reporter;
GRANT USAGE ON SCHEMA crypto_cost_monitor.dev_marts TO ROLE reporter;
GRANT SELECT ON ALL TABLES IN SCHEMA crypto_cost_monitor.dev_marts TO ROLE reporter;
GRANT SELECT ON FUTURE TABLES IN SCHEMA crypto_cost_monitor.dev_marts TO ROLE reporter;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA crypto_cost_monitor.dev_marts TO ROLE reporter;

-- type: service to bypass MFA requirements, consequence: access only via key-pair auth
CREATE USER IF NOT EXISTS superset_user TYPE = SERVICE DEFAULT_ROLE = reporter DEFAULT_WAREHOUSE = crypto_wh RSA_PUBLIC_KEY = '<public key>';
GRANT ROLE reporter TO USER superset_user;




