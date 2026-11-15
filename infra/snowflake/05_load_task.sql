USE ROLE ACCOUNTADMIN;

CREATE TASK IF NOT EXISTS crypto_cost_monitor.raw.load_api_snapshots
  SCHEDULE = '60 MINUTE'
  USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
  COPY INTO crypto_cost_monitor.raw.api_snapshots (record, file_name)
  FROM (SELECT $1, METADATA$FILENAME FROM @crypto_cost_monitor.raw.s3_raw);

ALTER TASK crypto_cost_monitor.raw.load_api_snapshots RESUME;