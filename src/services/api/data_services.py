import os
from datetime import datetime
from decimal import Decimal

import snowflake.connector

# fee type in the API -> column in the mart
FEE_COLUMNS = {
    "fastest": "fastest_fee_rate",
    "half_hour": "half_hour_fee_rate",
    "hour": "hour_fee_rate",
    "economy": "economy_fee_rate",
    "minimum": "minimum_fee_rate",
}
EXCHANGES = {"bitstamp", "coinbase", "kraken"}
TX_VBYTES = 140


def get_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user="api_user",
        private_key_file=os.environ["SNOWFLAKE_API_PRIVATE_KEY_PATH"],
        role="api",
        warehouse="crypto_wh",
        database="crypto_cost_monitor",
        schema="dev_marts",
    )


def _clean(value):
    # make snowflake types readable in json
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, datetime):
        return value.isoformat()
    return value


def _query(sql, params=None):
    with get_connection() as conn, conn.cursor(snowflake.connector.DictCursor) as cur:
        cur.execute(sql, params)
        return [
            {key.lower(): _clean(value) for key, value in row.items()}
            for row in cur.fetchall()
        ]


def get_latest_mid_prices():
    sql = """
        select exchange_code, snapshot_ts, max(mid_price) as mid_price
        from mart_order_book_api
        where snapshot_ts = (select max(snapshot_ts) from mart_order_book_api)
        group by exchange_code, snapshot_ts
        order by exchange_code
    """
    return _query(sql)


def get_purchase_costs(amount, fee_type, exchange=None, at=None):
    fee_column = FEE_COLUMNS[fee_type]
    sql = f"""
        with run as (
            select max(snapshot_ts) as snapshot_ts
            from mart_order_book_api
            where snapshot_ts <= coalesce(%(at)s::timestamp_tz, current_timestamp())
        ),

        -- the ask level where the amount is completely filled
        fill as (
            select
                m.exchange_code,
                m.snapshot_ts,
                m.mid_price,
                m.taker_fee_pct,
                m.{fee_column} as fee_rate,
                m.prev_cumulative_quantity 
                    + (%(amount)s - m.prev_cumulative_value_eur) / m.price
                    as btc_received
            from mart_order_book_api as m
            inner join run on m.snapshot_ts = run.snapshot_ts
            where m.side = 'asks'
                and %(amount)s > m.prev_cumulative_value_eur
                and %(amount)s <= m.cumulative_value_eur
                and (%(exchange)s is null or m.exchange_code = %(exchange)s)
        )

        select
            exchange_code,
            snapshot_ts,
            btc_received,
            %(amount)s - btc_received * mid_price as execution_cost_eur,
            %(amount)s * taker_fee_pct / 100 as trading_fee_eur,
            fee_rate * %(tx_vbytes)s / 100000000 * mid_price as network_fee_eur,
            execution_cost_eur + trading_fee_eur + network_fee_eur as total_cost_eur
        from fill
        order by total_cost_eur
    """
    params = {"amount": amount, "exchange": exchange, "at": at, "tx_vbytes": TX_VBYTES}
    return _query(sql, params)
