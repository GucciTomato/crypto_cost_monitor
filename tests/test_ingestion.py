import pytest
import src.ingestion.ingestion
from src.ingestion.ingestion import main, trim_order_book
from copy import deepcopy
from pathlib import Path
import json


def test_trim_order_book():
    payload = {
        "bids": list(range(60)),
        "asks": list(range(70))
    }

    result = trim_order_book(payload)

    assert len(result["bids"]) == 50


fixture_path = Path(__file__).parent / "sample_output.json"
sample_output = json.loads(fixture_path.read_text(encoding="utf-8"))


def fetch_simulation(url, sample_output):
    return deepcopy(sample_output[url])


@pytest.fixture
def writer_simulation():
    written_records = []

    def fake_writer(key, record):
        written_records.append((key, record))

    return fake_writer, written_records


def test_main_healthy(writer_simulation):
    writer, written_records = writer_simulation
    SOURCES = src.ingestion.ingestion.SOURCES
    fetcher = lambda url: fetch_simulation(url, sample_output=sample_output)
    main(writer = writer, fetcher = fetcher, SOURCES = SOURCES)

    assert len(written_records) == 4

    for key, record in written_records:
        assert record["source"] in SOURCES
        assert key.startswith(record["source"] + "/")
        for value in record.values():
            assert value is not None


def test_main_api_unhealthy(writer_simulation):
    writer, written_records = writer_simulation
    sample_output["https://api.kraken.com/0/public/Depth?pair=XBTEUR&count=50"] = {"error": ["EGeneral:Temporary lockout"]}
    SOURCES = src.ingestion.ingestion.SOURCES
    fetcher = lambda url: fetch_simulation(url, sample_output=sample_output)
    with pytest.raises(RuntimeError):
        main(writer = writer, fetcher = fetcher, SOURCES = SOURCES)