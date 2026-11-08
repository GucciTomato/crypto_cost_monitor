{{ config(materialized='view') }}

with source as (
    select record
    from {{ source('raw', 'api_snapshots') }}
    where record:source::string = 'mempool'
),
fee_rates as (
    select
        source.record:run_id::string as run_id,
        source.record:fetched_at::timestamp_tz as fetched_at,
        'bitcoin' as network_code,
        -- all fee rates in standard unit sat/vB
        source.record:payload:fastestFee::number(10, 2) as fastest_fee_rate,
        source.record:payload:halfHourFee::number(10, 2) as half_hour_fee_rate,
        source.record:payload:hourFee::number(10, 2) as hour_fee_rate,
        source.record:payload:economyFee::number(10, 2) as economy_fee_rate,
        source.record:payload:minimumFee::number(10, 2) as minimum_fee_rate
    from source
)

select * from fee_rates