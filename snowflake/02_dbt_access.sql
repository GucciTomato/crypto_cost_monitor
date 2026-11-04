USE ROLE ACCOUNTADMIN;

-- role for dbt: read raw data, build its own schemas
CREATE ROLE IF NOT EXISTS transformer;
GRANT USAGE ON WAREHOUSE crypto_wh TO ROLE transformer;
GRANT USAGE, CREATE SCHEMA ON DATABASE crypto_cost_monitor TO ROLE transformer;
GRANT USAGE ON SCHEMA crypto_cost_monitor.raw TO ROLE transformer;
GRANT SELECT ON ALL TABLES IN SCHEMA crypto_cost_monitor.raw TO ROLE transformer;
GRANT SELECT ON FUTURE TABLES IN SCHEMA crypto_cost_monitor.raw TO ROLE transformer;

-- type: service i.e. access only via key-pair auth
CREATE USER IF NOT EXISTS dbt_user TYPE = SERVICE DEFAULT_ROLE = transformer DEFAULT_WAREHOUSE = crypto_wh RSA_PUBLIC_KEY = '<public key>';
GRANT ROLE transformer TO USER dbt_user;