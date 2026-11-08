{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_network'
src_hashdiff: 'hd_fee_rates'
src_payload:
    - fastest_fee_rate
    - half_hour_fee_rate
    - hour_fee_rate
    - economy_fee_rate
    - minimum_fee_rate
source_model: 'stg_mempool__vault_stage'
{%- endset -%}    

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}