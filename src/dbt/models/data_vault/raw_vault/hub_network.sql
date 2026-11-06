{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
hashkey: 'hk_network'
business_keys:
    - network_code
source_models: stg_mempool__vault_stage
{%- endset -%}

{{ datavault4dbt.hub(yaml_metadata=yaml_metadata) }}