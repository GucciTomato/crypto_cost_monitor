{{ config(materialized='table') }}

with runs as (
    select snapshot_ts from {{ ref('bv_snapshot_runs') }}
),
exchange_fees as (
    select 
        hk_exchange, 
        ldts, 
        valid_to, 
        taker_fee_pct
    from {{ ref('sat_v1_exchange_fees') }}
    where hk_exchange not in ('00000000000000000000000000000000', 'ffffffffffffffffffffffffffffffff')     -- exclude ghost records
),
network_fees as (
    select 
        ldts,
        valid_to,
        hd_fee_rates, 
        fastest_fee_rate, 
        half_hour_fee_rate, 
        hour_fee_rate, 
        economy_fee_rate, 
        minimum_fee_rate
    from {{ ref('sat_v1_network_fees') }}
    where hk_network not in ('00000000000000000000000000000000', 'ffffffffffffffffffffffffffffffff') -- exclude ghost records
)

select 
    runs.snapshot_ts, 
    hub_exchange.exchange_code, 
    exchange_fees.taker_fee_pct,
    network_fees.hd_fee_rates, 
    network_fees.fastest_fee_rate, 
    network_fees.half_hour_fee_rate, 
    network_fees.hour_fee_rate, 
    network_fees.economy_fee_rate, 
    network_fees.minimum_fee_rate
from runs
inner join exchange_fees on runs.snapshot_ts >= exchange_fees.ldts and runs.snapshot_ts < exchange_fees.valid_to
inner join {{ ref('hub_exchange') }} as hub_exchange on hub_exchange.hk_exchange = exchange_fees.hk_exchange
left join network_fees on runs.snapshot_ts >= network_fees.ldts and runs.snapshot_ts < network_fees.valid_to