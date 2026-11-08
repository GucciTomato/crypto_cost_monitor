{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
hashkey: 'hk_exchange'
business_keys: 
    - exchange_code
source_models: 
    - name: stg_bitstamp__vault_stage
    - name: stg_kraken__vault_stage
    - name: stg_coinbase__vault_stage
{%- endset -%}

{{ datavault4dbt.hub(yaml_metadata=yaml_metadata) }}