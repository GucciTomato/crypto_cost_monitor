{{ config(materialized='table') }}

with runs as (
    select snapshot_ts from {{ ref('bv_snapshot_runs') }}
),
books as (
    select hk_market, ldts, valid_to, side, level_rank, price, quantity from {{ ref('ma_sat_v1_market_bitstamp') }}
    union all
    select hk_market, ldts, valid_to, side, level_rank, price, quantity from {{ ref('ma_sat_v1_market_coinbase') }}
    union all
    select hk_market, ldts, valid_to, side, level_rank, price, quantity from {{ ref('ma_sat_v1_market_kraken') }}
),
levels as (
    select runs.snapshot_ts, hub_exchange.exchange_code, books.side, books.level_rank, books.price, books.quantity
    from runs
    inner join books on runs.snapshot_ts >= books.ldts and runs.snapshot_ts < books.valid_to
    inner join {{ ref('link_market') }} as link_market on link_market.hk_market = books.hk_market
    inner join {{ ref('hub_exchange') }} as hub_exchange on hub_exchange.hk_exchange = link_market.hk_exchange
    where books.hk_market not in ('00000000000000000000000000000000', 'ffffffffffffffffffffffffffffffff') -- exclude ghost records
)

select
    snapshot_ts,
    exchange_code,
    side,
    level_rank,
    price,
    quantity,
    sum(quantity) over (partition by snapshot_ts, exchange_code, side order by level_rank) as cumulative_quantity,
    sum(price * quantity) over (partition by snapshot_ts, exchange_code, side order by level_rank) as cumulative_value_eur
from levels