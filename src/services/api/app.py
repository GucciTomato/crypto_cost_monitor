# app.py
import os
from flask import Flask, jsonify, request
from data_services import get_latest_mid_prices

FLASK_APP = os.environ.get("FLASK_APP")

app = Flask(__name__)

@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/mid-prices/latest")
def latest_mid_prices():
    return jsonify(get_latest_mid_prices())


if __name__ == "__main__":
    app.run(debug=True)
