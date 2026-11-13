


USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS crypto_wh WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 120 INITIALLY_SUSPENDED = TRUE;
CREATE DATABASE IF NOT EXISTS crypto_cost_monitor;
CREATE SCHEMA IF NOT EXISTS crypto_cost_monitor.raw;
ALTER ACCOUNT SET TIMEZONE = 'UTC'; --for correct seed dates (snowflake uses L.A. time by default)

CREATE STORAGE INTEGRATION s3_crypto_raw
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = ''
    STORAGE_ALLOWED_LOCATIONS = ('s3://');

DESC INTEGRATION s3_crypto_raw;

CREATE TABLE IF NOT EXISTS crypto_cost_monitor.raw.api_snapshots (
    record VARIANT,
    file_name STRING,
    loaded_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

COPY INTO crypto_cost_monitor.raw.api_snapshots (record, file_name)
FROM (SELECT $1, METADATA$FILENAME FROM @crypto_cost_monitor.raw.s3_raw);

SELECT *
FROM crypto_cost_monitor.raw.api_snapshots
ORDER BY loaded_at DESC
LIMIT 10;