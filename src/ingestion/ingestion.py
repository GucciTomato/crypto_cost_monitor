import json
import requests
import uuid
from datetime import datetime, timezone
from pathlib import Path
import logging
import os
import boto3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


BUCKET = os.environ.get("BUCKET")

SOURCES = {
    "kraken": "https://api.kraken.com/0/public/Depth?pair=XBTEUR&count=50",
    "coinbase": "https://api.exchange.coinbase.com/products/BTC-EUR/book?level=2",
    "bitstamp": "https://www.bitstamp.net/api/v2/order_book/btceur/",
    "mempool": "https://mempool.space/api/v1/fees/recommended",
}


def fetch_url(url: str) -> dict:
    response = requests.get(
        url, timeout=10, headers={"User-Agent": "crypto-cost-monitor/0.1"}
    )
    response.raise_for_status()
    return response.json()


def kraken_error(payload) -> None:
    if payload.get("error"):
        raise ValueError(f"Kraken API error: {payload['error']}")


depth = 50


def trim_order_book(payload: dict) -> dict:
    payload["bids"] = payload["bids"][:depth]
    payload["asks"] = payload["asks"][:depth]
    return payload


def write_to_s3(key, record) -> None:
    body = json.dumps(record)
    boto3.client("s3").put_object(Bucket=BUCKET, Key=key, Body=body)


def write_to_local(key, record) -> None:
    body = json.dumps(record)
    path = Path("data/raw") / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body)


def lambda_handler(event, context) -> None:
    main(writer=write_to_s3, fetcher=fetch_url, SOURCES=SOURCES)


def main(writer, fetcher, SOURCES) -> None:
    run_id = str(uuid.uuid4())  # generating unique identifier for each run
    fetched_at = datetime.now(timezone.utc)
    failures = []

    for source, url in SOURCES.items():
        try:
            payload = fetcher(url)
            if source == "kraken":
                kraken_error(payload)
            if source in ("coinbase", "bitstamp"):
                payload = trim_order_book(payload)
            record = {
                "run_id": run_id,
                "source": source,
                "fetched_at": fetched_at.isoformat(),
                "payload": payload,
            }
            key = f"{source}/{fetched_at.strftime('%Y-%m-%d')}/{run_id}.json"
            writer(key, record)
            logger.info(f"Wrote raw data successfully for {source}")
        except Exception as e:
            failures.append(source)
            logger.exception(f"Ingestion failed: {e}")

    if failures:
        raise RuntimeError(f"Ingestion failed for: {', '.join(failures)}")


if __name__ == "__main__":
    main(writer=write_to_local, fetcher=fetch_url, SOURCES=SOURCES)
