{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: stg_kraken__order_book_levels
ldts: 'fetched_at'
rsrc: '!kraken_api'
hashed_columns:
    hk_exchange:
        - exchange_code
    hk_trading_pair:
        - trading_pair_code
    hk_market:
        - exchange_code
        - trading_pair_code
    hd_market_kraken:
        is_hashdiff: true
        columns:
            - price 
            - quantity
multi_active_config:
    multi_active_key:
        - side 
        - level_rank
    main_hashkey_column: 'hk_market'
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}