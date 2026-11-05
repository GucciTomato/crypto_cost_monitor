{{ config(materialized='view') }}

with source as (
    select record
    from {{ source('raw', 'api_snapshots') }}
    where record:source::string = 'bitstamp'
),
levels as (
    select
        source.record:run_id::string as run_id,
        source.record:fetched_at::timestamp_tz as fetched_at,
        'bitstamp' as exchange_code,
        'btceur' as trading_pair_code,
        book_side.key as side,,
        level.index + 1 as level_rank,
        level.value[0]::number(18, 8) as price,
        level.value[1]::number(18, 8) as quantity
    from source,
        lateral flatten(input => source.record:payload) as book_side,
        lateral flatten(input => book_side.value) as level
    where book_side.key in ('bids', 'asks')
)

select * from levels