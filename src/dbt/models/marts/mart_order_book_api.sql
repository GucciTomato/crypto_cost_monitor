{{ config(materialized='view', grants={'select': ['api']}) }}

select
    obl.snapshot_ts,
    obl.exchange_code,
    obl.side,
    obl.level_rank,
    obl.price,
    obl.quantity,
    obl.cumulative_quantity,
    obl.cumulative_value_eur,
    obl.cumulative_quantity - obl.quantity as prev_cumulative_quantity,
    obl.cumulative_value_eur - obl.price * obl.quantity as prev_cumulative_value_eur,
    -- mid price of the run defined here as average of best bid and best ask
    (
        max(case when obl.side = 'bids' and obl.level_rank = 1 then obl.price end) over (partition by obl.snapshot_ts, obl.exchange_code)
        + max(case when obl.side = 'asks' and obl.level_rank = 1 then obl.price end) over (partition by obl.snapshot_ts, obl.exchange_code)
    ) / 2 as mid_price,
    rf.taker_fee_pct,
    rf.fastest_fee_rate,
    rf.half_hour_fee_rate,
    rf.hour_fee_rate,
    rf.economy_fee_rate,
    rf.minimum_fee_rate
from {{ ref('bv_order_book_levels') }} as obl
inner join {{ ref('bv_run_fees') }} as rf on rf.exchange_code = obl.exchange_code and rf.snapshot_ts = obl.snapshot_ts