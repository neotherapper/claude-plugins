import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import kev
import epss

KEV_RESP = {
    "vulnerabilities": [
        {"cveID": "CVE-2025-1"},
        {"cveID": "CVE-2025-9"},
    ]
}
EPSS_RESP = {
    "data": [
        {"cve": "CVE-2025-1", "epss": "0.42"},
        {"cve": "CVE-2025-2", "epss": "0.01"},
    ]
}


# --- kev tests ---

def test_exploited_ids_maps_cve_ids(monkeypatch):
    monkeypatch.setattr(kev._http, "get_json", lambda *a, **k: KEV_RESP)
    ids = kev.exploited_ids()
    assert ids == {"CVE-2025-1", "CVE-2025-9"}


def test_exploited_ids_error_returns_empty(monkeypatch):
    monkeypatch.setattr(kev._http, "get_json", lambda *a, **k: {"error": "down"})
    assert kev.exploited_ids() == set()


def test_exploited_ids_missing_vulnerabilities(monkeypatch):
    monkeypatch.setattr(kev._http, "get_json", lambda *a, **k: {})
    assert kev.exploited_ids() == set()


def test_exploited_ids_malformed_entries(monkeypatch):
    resp = {"vulnerabilities": ["not-a-dict", {"cveID": "CVE-2025-3"}, None]}
    monkeypatch.setattr(kev._http, "get_json", lambda *a, **k: resp)
    ids = kev.exploited_ids()
    assert ids == {"CVE-2025-3"}


# --- epss tests ---

def test_scores_maps_epss_floats(monkeypatch):
    monkeypatch.setattr(epss._http, "get_json", lambda *a, **k: EPSS_RESP)
    scores = epss.scores(["CVE-2025-1", "CVE-2025-2"])
    assert scores == {"CVE-2025-1": 0.42, "CVE-2025-2": 0.01}


def test_scores_error_returns_empty(monkeypatch):
    monkeypatch.setattr(epss._http, "get_json", lambda *a, **k: {"error": "down"})
    assert epss.scores(["CVE-2025-1"]) == {}


def test_scores_missing_data(monkeypatch):
    monkeypatch.setattr(epss._http, "get_json", lambda *a, **k: {})
    assert epss.scores(["CVE-2025-1"]) == {}


def test_scores_empty_input(monkeypatch):
    scores = epss.scores([])
    assert scores == {}


def test_scores_malformed_entries(monkeypatch):
    resp = {"data": ["not-a-dict", {"cve": "CVE-2025-5", "epss": "0.88"}, None]}
    monkeypatch.setattr(epss._http, "get_json", lambda *a, **k: resp)
    scores = epss.scores(["CVE-2025-5"])
    assert scores == {"CVE-2025-5": 0.88}


def test_scores_bad_epss_value(monkeypatch):
    resp = {"data": [{"cve": "CVE-2025-6", "epss": "not-a-number"}]}
    monkeypatch.setattr(epss._http, "get_json", lambda *a, **k: resp)
    scores = epss.scores(["CVE-2025-6"])
    assert "CVE-2025-6" not in scores
