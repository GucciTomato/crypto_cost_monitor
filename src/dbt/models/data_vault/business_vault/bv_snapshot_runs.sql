{{ config(materialized='table') }}

with all_ldts as (
    select ldts from {{ ref('ma_sat_market_bitstamp') }}
    union
    select ldts from {{ ref('ma_sat_market_coinbase') }}
    union
    select ldts from {{ ref('ma_sat_market_kraken') }}
)

select ldts as snapshot_ts
from all_ldts
where year(ldts) between 2000 and 3000 -- ghost records use default years like 0001