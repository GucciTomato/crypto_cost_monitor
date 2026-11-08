{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: exchange_fees
ldts: 'valid_from'
rsrc: '!manual_seed'
hashed_columns:
    hk_exchange:
        - exchange_code
    hd_exchange_fees:
        is_hashdiff: true 
        columns:
            - taker_fee_pct
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}