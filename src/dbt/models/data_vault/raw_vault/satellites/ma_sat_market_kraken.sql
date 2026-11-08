{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
source_model: 'stg_kraken__vault_stage'
parent_hashkey: 'hk_market'
src_hashdiff: 'hd_market_kraken'
src_ma_key: 
    - 'side'
    - 'level_rank'
src_payload: 
    - price
    - quantity
{%- endset -%}

{{ datavault4dbt.ma_sat_v0(yaml_metadata=yaml_metadata) }}