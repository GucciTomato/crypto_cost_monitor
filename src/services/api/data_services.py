import os
import snowflake.connector


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


def get_latest_mid_prices():
    query = """
        select exchange_code, snapshot_ts, max(mid_price) as mid_price
        from mart_order_book_api
        where snapshot_ts = (select max(snapshot_ts) from mart_order_book_api)
        group by exchange_code, snapshot_ts
        order by exchange_code
    """
    with get_connection() as conn, conn.cursor(snowflake.connector.DictCursor) as cur:
        cur.execute(query)
        return [{key.lower(): value for key, value in row.items()} for row in cur.fetchall()]