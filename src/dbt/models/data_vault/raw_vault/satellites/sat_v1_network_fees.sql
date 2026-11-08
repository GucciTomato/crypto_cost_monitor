{{ config(materialized='view') }}

{%- set yaml_metadata -%}
sat_v0: 'sat_network_fees'
hashkey: 'hk_network'
hashdiff: 'hd_fee_rates'
ledts_alias: 'valid_to'
add_is_current_flag: true
{%- endset -%}    

{{ datavault4dbt.sat_v1(yaml_metadata=yaml_metadata) }}