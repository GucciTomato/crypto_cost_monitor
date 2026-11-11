{{ config(materialized='table') }}

-- cost of buying btc for a given eur amount and sending it; grain one row per run

with amounts as (
    select column1 as amount_eur
    from values (10), (50), (100), (500), (1000), (5000)
),
asks as (
    select
        snapshot_ts,
        exchange_code,
        price,
        cumulative_quantity,
        cumulative_value_eur,
        cumulative_quantity - quantity as prev_cumulative_quantity,
        cumulative_value_eur - price * quantity as prev_cumulative_value_eur
    from {{ ref('bv_order_book_levels') }}
    where side = 'asks'
),
mid_prices as (
    select
        snapshot_ts,
        exchange_code,
        (max(case when side = 'bids' then price end) + max(case when side = 'asks' then price end)) / 2 as mid_price
    from {{ ref('bv_order_book_levels') }}
    where level_rank = 1
    group by snapshot_ts, exchange_code
),
fills as (
    select
        amounts.amount_eur,
        asks.snapshot_ts,
        asks.exchange_code,
        asks.prev_cumulative_quantity + (amounts.amount_eur - asks.prev_cumulative_value_eur) / asks.price as btc_received
    from amounts
    inner join asks on amounts.amount_eur > asks.prev_cumulative_value_eur and amounts.amount_eur <= asks.cumulative_value_eur
),
-- one row per network fee type
fees as (
    select snapshot_ts, exchange_code, taker_fee_pct, 'fastest' as fee_type, fastest_fee_rate as fee_rate_sat_vb from {{ ref('bv_run_fees') }}
    union all
    select snapshot_ts, exchange_code, taker_fee_pct, 'half_hour' as fee_type, half_hour_fee_rate as fee_rate_sat_vb from {{ ref('bv_run_fees') }}
    union all
    select snapshot_ts, exchange_code, taker_fee_pct, 'hour' as fee_type, hour_fee_rate as fee_rate_sat_vb from {{ ref('bv_run_fees') }}
    union all
    select snapshot_ts, exchange_code, taker_fee_pct, 'economy' as fee_type, economy_fee_rate as fee_rate_sat_vb from {{ ref('bv_run_fees') }}
    union all
    select snapshot_ts, exchange_code, taker_fee_pct, 'minimum' as fee_type, minimum_fee_rate as fee_rate_sat_vb from {{ ref('bv_run_fees') }}
),
costs as (
    select
        mid_prices.snapshot_ts,
        mid_prices.exchange_code,
        amounts.amount_eur,
        fees.fee_type,
        mid_prices.mid_price,
        fills.btc_received is not null as is_depth_sufficient,
        amounts.amount_eur - fills.btc_received * mid_prices.mid_price as execution_cost_eur,
        amounts.amount_eur * fees.taker_fee_pct / 100 as trading_fee_eur,
        -- fee rate in sat/vB times size, converted to eur
        fees.fee_rate_sat_vb * {{ var('tx_vbytes', 140) }} / 100000000 * mid_prices.mid_price as network_fee_eur
    from mid_prices
    cross join amounts -- no common column
    inner join fees on fees.snapshot_ts = mid_prices.snapshot_ts and fees.exchange_code = mid_prices.exchange_code --for every run/exchange there are fees 
    left join fills on fills.snapshot_ts = mid_prices.snapshot_ts and fills.exchange_code = mid_prices.exchange_code and fills.amount_eur = amounts.amount_eur
)

select
    snapshot_ts,
    exchange_code,
    amount_eur,
    fee_type,
    mid_price,
    is_depth_sufficient,
    round(execution_cost_eur, 4) as execution_cost_eur,
    round(trading_fee_eur, 4) as trading_fee_eur,
    round(network_fee_eur, 4) as network_fee_eur,
    round(execution_cost_eur + trading_fee_eur + network_fee_eur, 4) as total_cost_eur,
    round((execution_cost_eur + trading_fee_eur + network_fee_eur) / amount_eur * 100, 4) as total_cost_pct
from costs