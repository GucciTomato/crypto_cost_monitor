{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
hashkey: 'hk_trading_pair'
business_keys:
  - trading_pair_code
source_models:
  - name: stg_bitstamp__vault_stage
  - name: stg_kraken__vault_stage
  - name: stg_coinbase__vault_stage
{%- endset -%}

{{ datavault4dbt.hub(yaml_metadata=yaml_metadata) }}