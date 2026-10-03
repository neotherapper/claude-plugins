import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import ssl_labs
import observatory


# --- ssl_labs tests ---

def test_grade_ready_returns_grade(monkeypatch):
    resp = {"status": "READY", "endpoints": [{"grade": "A"}]}
    monkeypatch.setattr(ssl_labs._http, "get_json", lambda *a, **k: resp)
    result = ssl_labs.grade("example.com")
    assert result["grade"] == "A"
    assert "error" not in result


def test_grade_polls_until_ready(monkeypatch):
    calls = {"n": 0}
    def fake_get(url, **kw):
        calls["n"] += 1
        if calls["n"] < 3:
            return {"status": "IN_PROGRESS"}
        return {"status": "READY", "endpoints": [{"grade": "B"}]}
    monkeypatch.setattr(ssl_labs._http, "get_json", fake_get)
    monkeypatch.setattr(ssl_labs.time, "sleep", lambda *a: None)
    result = ssl_labs.grade("example.com")
    assert result["grade"] == "B"
    assert calls["n"] == 3


def test_grade_timeout_returns_error(monkeypatch):
    monkeypatch.setattr(ssl_labs._http, "get_json", lambda *a, **k: {"status": "IN_PROGRESS"})
    monkeypatch.setattr(ssl_labs.time, "sleep", lambda *a: None)
    result = ssl_labs.grade("example.com")
    assert result["grade"] is None
    assert "error" in result


def test_grade_error_returns_error(monkeypatch):
    monkeypatch.setattr(ssl_labs._http, "get_json", lambda *a, **k: {"error": "down"})
    result = ssl_labs.grade("example.com")
    assert result["grade"] is None
    assert "error" in result


def test_grade_no_endpoints(monkeypatch):
    monkeypatch.setattr(ssl_labs._http, "get_json",
        lambda *a, **k: {"status": "READY", "endpoints": []})
    result = ssl_labs.grade("example.com")
    assert result["grade"] is None


# --- observatory tests ---

def test_grade_maps_fields(monkeypatch):
    resp = {
        "state": "FINISHED",
        "scan": {"grade": "B", "score": 65},
        "tests": {
            "content-security-policy": {"pass": False, "name": "content-security-policy"},
            "x-content-type-options": {"pass": True, "name": "x-content-type-options"},
        }
    }
    monkeypatch.setattr(observatory._http, "get_json", lambda *a, **k: resp)
    result = observatory.grade("example.com")
    assert result["grade"] == "B"
    assert result["score"] == 65
    assert "content-security-policy" in result["failed"]
    assert "x-content-type-options" not in result["failed"]


def test_grade_polls_until_finished(monkeypatch):
    calls = {"n": 0}
    def fake_get(url, **kw):
        calls["n"] += 1
        if calls["n"] < 2:
            return {"state": "PENDING"}
        return {"state": "FINISHED", "scan": {"grade": "A", "score": 90}, "tests": {}}
    monkeypatch.setattr(observatory._http, "get_json", fake_get)
    monkeypatch.setattr(observatory.time, "sleep", lambda *a: None)
    result = observatory.grade("example.com")
    assert result["grade"] == "A"
    assert calls["n"] == 2


def test_grade_error_returns_error(monkeypatch):
    monkeypatch.setattr(observatory._http, "get_json", lambda *a, **k: {"error": "down"})
    result = observatory.grade("example.com")
    assert result["grade"] is None
    assert "error" in result


def test_grade_missing_tests(monkeypatch):
    resp = {"state": "FINISHED", "scan": {"grade": "C", "score": 40}}
    monkeypatch.setattr(observatory._http, "get_json", lambda *a, **k: resp)
    result = observatory.grade("example.com")
    assert result["grade"] == "C"
    assert result["failed"] == []
