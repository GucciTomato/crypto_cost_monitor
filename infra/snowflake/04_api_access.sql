USE ROLE ACCOUNTADMIN;

-- read only role for API queries
CREATE ROLE IF NOT EXISTS api;
GRANT USAGE ON WAREHOUSE crypto_wh TO ROLE api;
GRANT USAGE ON DATABASE crypto_cost_monitor TO ROLE api;
GRANT USAGE ON SCHEMA crypto_cost_monitor.dev_marts TO ROLE api;

-- type: service to bypass MFA requirements, consequence: access only via key-pair auth
CREATE USER IF NOT EXISTS api_user TYPE = SERVICE DEFAULT_ROLE = api DEFAULT_WAREHOUSE = crypto_wh RSA_PUBLIC_KEY = '<public key>';
GRANT ROLE api TO USER api_user;


