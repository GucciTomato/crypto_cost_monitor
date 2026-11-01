import json
import requests

SOURCES = {
    "kraken": "https://api.kraken.com/0/public/Ticker?pair=XBTEUR",
    "coinbase": "https://api.exchange.coinbase.com/products/BTC-EUR/ticker",
    "bitstamp": "https://www.bitstamp.net/api/v2/ticker/btceur/",
    "mempool": "https://mempool.space/api/v1/fees/recommended",
}

def fetch_url(url):
    response = requests.get(url, timeout=10, )
    return response.json()


def main():
    for url in SOURCES.values():
        result = fetch_url(url)
        print(result)


if __name__  == "__main__":
    main()