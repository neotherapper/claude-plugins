import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import nvd

NVD_RESP = {
    "vulnerabilities": [
        {"cve": {
            "id": "CVE-2025-2",
            "descriptions": [{"lang": "en", "value": "RCE in WordPress"}],
            "metrics": {"cvssMetricV31": [{"cvssData": {"baseScore": 8.1}}]}
        }},
        {"cve": {
            "id": "CVE-2025-3",
            "descriptions": [{"lang": "en", "value": "XSS in plugin"}],
            "metrics": {"cvssMetricV30": [{"cvssData": {"baseScore": 6.5}}]}
        }}
    ]
}


def test_search_maps_fields(monkeypatch):
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: NVD_RESP)
    out = nvd.search("WordPress 6.5")
    assert len(out) == 2
    assert out[0]["id"] == "CVE-2025-2"
    assert out[0]["cvss"] == 8.1
    assert out[0]["source"] == "nvd"
    assert "RCE in WordPress" in out[0]["summary"]


def test_search_cvss_v30_fallback(monkeypatch):
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: NVD_RESP)
    out = nvd.search("WordPress 6.5")
    assert out[1]["cvss"] == 6.5


def test_search_error_returns_empty(monkeypatch):
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: {"error": "down"})
    assert nvd.search("WordPress 6.5") == []


def test_search_no_vulnerabilities_returns_empty(monkeypatch):
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: {"vulnerabilities": []})
    assert nvd.search("nonexistent") == []


def test_search_missing_metrics_is_safe(monkeypatch):
    resp = {"vulnerabilities": [{"cve": {"id": "CVE-2025-99",
        "descriptions": [{"lang": "en", "value": "No metrics"}]}}]}
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: resp)
    out = nvd.search("something")
    assert out[0]["cvss"] is None


def test_search_missing_descriptions_is_safe(monkeypatch):
    resp = {"vulnerabilities": [{"cve": {"id": "CVE-2025-100",
        "descriptions": [], "metrics": {"cvssMetricV31": [{"cvssData": {"baseScore": 5.0}}]}}}]}
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: resp)
    out = nvd.search("something")
    assert out[0]["summary"] == ""


def test_search_malformed_entries_do_not_crash(monkeypatch):
    resp = {"vulnerabilities": ["not-a-dict", {"cve": None}]}
    monkeypatch.setattr(nvd._http, "get_json", lambda *a, **k: resp)
    out = nvd.search("something")
    assert out == []  # both malformed → skipped
