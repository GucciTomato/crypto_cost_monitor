import json
import requests
import uuid
from datetime import datetime, timezone
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

SOURCES = {
    "kraken": "https://api.kraken.com/0/public/Ticker?pair=XBTEUR",
    "coinbase": "https://api.exchange.coinbase.com/products/BTC-EUR/ticker",
    "bitstamp": "https://www.bitstamp.net/api/v2/ticker/btceur/",
    "mempool": "https://mempool.space/api/v1/fees/recommended",
}

def fetch_url(url):
    response = requests.get(url, timeout=10, headers={"User-Agent": "btc-cost-monitor/0.1"})
    response.raise_for_status()
    return response.json()

def kraken_error(payload):
    if payload.get("error"):
        raise

def main():
    run_id = str(uuid.uuid4()) # generating unique identifier for each run
    fetched_at = datetime.now(timezone.utc)
    for source, url in SOURCES.items():
        try: 
            record = {"run_id": run_id, "source": source, "fetched_at": fetched_at.isoformat(),"payload": fetch_url(url),}
            kraken_error(record["payload"])
            path = Path("data/raw") / source / fetched_at.strftime("%Y-%m-%d") / f"{run_id}.json"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(record))
            logger.info(f"Wrote raw data successfully for {source}")
        except requests.RequestException:
            logger.exception(f"Ingestion failed.")

if __name__  == "__main__":
    main()