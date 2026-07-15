import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import osv

OSV_RESP = {"vulns": [
    {"id": "GHSA-abc", "summary": "XSS in foo",
     "severity": [{"type": "CVSS_V3", "score": "7.5"}], "aliases": ["CVE-2025-1"]}]}

def test_query_maps_fields(monkeypatch):
    monkeypatch.setattr(osv._http, "post_json", lambda *a, **k: OSV_RESP)
    out = osv.query("lodash", "4.17.20", "npm")
    assert out[0]["id"] == "GHSA-abc" and out[0]["source"] == "osv"
    assert "CVE-2025-1" in out[0].get("aliases", [])

def test_query_error_returns_empty(monkeypatch):
    monkeypatch.setattr(osv._http, "post_json", lambda *a, **k: {"error": "down"})
    assert osv.query("lodash", "4.17.20", "npm") == []

def test_no_vulns_returns_empty(monkeypatch):
    monkeypatch.setattr(osv._http, "post_json", lambda *a, **k: {"vulns": []})
    assert osv.query("lodash", "1.0.0", "npm") == []

def test_cvss_picks_max_numeric(monkeypatch):
    resp = {"vulns": [{"id": "x", "severity": [{"type": "CVSS_V3", "score": "7.5"},
                                               {"type": "CVSS_V3", "score": "9.1"}]}]}
    monkeypatch.setattr(osv._http, "post_json", lambda *a, **k: resp)
    assert osv.query("p", "1", "npm")[0]["cvss"] == 9.1

def test_cvss_vector_string_is_none(monkeypatch):
    resp = {"vulns": [{"id": "x", "severity": [{"type": "CVSS_V3", "score": "CVSS:3.1/AV:N/AC:L"}]}]}
    monkeypatch.setattr(osv._http, "post_json", lambda *a, **k: resp)
    assert osv.query("p", "1", "npm")[0]["cvss"] is None

def test_malformed_entries_do_not_crash(monkeypatch):
    resp = {"vulns": [{"id": "x", "severity": [{"type": "CVSS_V3", "score": None}]}, "not-a-dict"]}
    monkeypatch.setattr(osv._http, "post_json", lambda *a, **k: resp)
    out = osv.query("p", "1", "npm")  # must not raise
    assert len(out) == 1 and out[0]["cvss"] is None  # non-dict vuln skipped
