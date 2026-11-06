{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: stg_mempool__fee_rates
ldts: 'fetched_at'
rsrc: '!mempool_api'
hashed_columns:
    hk_network:
        - network_code
    hd_fee_rates:
        is_hashdiff: true 
        columns:
            - fastest_fee_rate
            - half_hour_fee_rate
            - hour_fee_rate
            - economy_fee_rate
            - minimum_fee_rate
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}