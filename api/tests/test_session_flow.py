import json
from pathlib import Path
from fastapi.testclient import TestClient
from main import app


def load_sample():
    sample_path = Path(__file__).parents[1] / "samples" / "enhanced_items.sample.json"
    data = json.loads(sample_path.read_text())
    return data


def test_ingest_and_session_flow():
    client = TestClient(app)
    # Ingest sample items
    data = load_sample()
    r = client.post("/v1/items/ingest", json=data)
    assert r.status_code == 200
    assert r.json()["ingested"] == 1

    # Start session
    start_req = {"learner_id": "learner-1", "item_id": "ALG-S1-E1"}
    rs = client.post("/v1/session/start", json=start_req)
    assert rs.status_code == 200
    body_start = rs.json()
    sid = body_start["session_id"]
    assert sid
    assert body_start.get("prompt")

    # Submit correct response
    step_req = {"session_id": sid, "step_id": "s1", "user_response": "b + 4"}
    rt = client.post("/v1/session/step", json=step_req)
    assert rt.status_code == 200
    body = rt.json()
    assert body.get("correctness") is True
    assert body.get("next_prompt")
