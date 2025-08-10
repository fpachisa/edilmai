from fastapi.testclient import TestClient
from main import app


def test_healthz():
    client = TestClient(app)
    r = client.get("/healthz")
    assert r.status_code == 200
    body = r.json()
    assert body.get("status") == "ok"

