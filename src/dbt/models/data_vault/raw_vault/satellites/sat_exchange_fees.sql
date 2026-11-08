{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_exchange'
src_hashdiff: 'hd_exchange_fees'
source_model: 'stg_exchange_fees__vault_stage'
src_payload:
  - taker_fee_pct
{%- endset -%}

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}