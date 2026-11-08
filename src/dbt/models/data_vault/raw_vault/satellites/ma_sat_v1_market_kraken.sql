{{ config(materialized='view') }}

{%- set yaml_metadata -%}
sat_v0: 'ma_sat_market_kraken'
hashkey: 'hk_market'
hashdiff: 'hd_market_kraken'
ma_attribute: 
    - 'side'
    - 'level_rank'
ledts_alias: 'valid_to'
add_is_current_flag: true
{%- endset -%}

{{ datavault4dbt.ma_sat_v1(yaml_metadata=yaml_metadata) }}