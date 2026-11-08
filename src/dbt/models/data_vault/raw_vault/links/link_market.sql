{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
link_hashkey: 'hk_market'
foreign_hashkeys: 
    - 'hk_exchange'
    - 'hk_trading_pair'
source_models:
    - name: stg_bitstamp__vault_stage
    - name: stg_coinbase__vault_stage
    - name: stg_kraken__vault_stage
{%- endset -%}    

{{ datavault4dbt.link(yaml_metadata=yaml_metadata) }}