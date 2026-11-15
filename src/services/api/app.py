from datetime import datetime

from data_services import (
    EXCHANGES,
    FEE_COLUMNS,
    get_latest_mid_prices,
    get_purchase_costs,
)
from flask import Flask, jsonify, request

app = Flask(__name__)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/mid-prices/latest")
def latest_mid_prices():
    return jsonify(get_latest_mid_prices())


@app.get("/costs")
def purchase_costs():
    try:
        amount = float(request.args["amount"])
    except (KeyError, ValueError):
        return {"error": "parameter 'amount' is required and must be a number"}, 400
    if amount <= 0:
        return {"error": "parameter 'amount' must be positive"}, 400

    fee_type = request.args.get("fee_type", "half_hour")
    if fee_type not in FEE_COLUMNS:
        return {"error": f"parameter 'fee_type' must be one of {sorted(FEE_COLUMNS)}"}, 400

    exchange = request.args.get("exchange")
    if exchange is not None and exchange not in EXCHANGES:
        return {"error": f"parameter 'exchange' must be one of {sorted(EXCHANGES)}"}, 400

    at = request.args.get("at")
    if at is not None:
        try:
            datetime.fromisoformat(at)
        except ValueError:
            return {"error": "parameter 'at' must be a timestamp (ISO)"}, 400

    return jsonify(get_purchase_costs(amount, fee_type, exchange, at))


if __name__ == "__main__":
    app.run(debug=True)