{{ config(materialized='view') }}

{%- set yaml_metadata -%}
sat_v0: 'sat_exchange_fees'
hashkey: 'hk_exchange'
hashdiff: 'hd_exchange_fees'
ledts_alias: 'valid_to'
add_is_current_flag: true
{%- endset -%}    

{{ datavault4dbt.sat_v1(yaml_metadata=yaml_metadata) }}