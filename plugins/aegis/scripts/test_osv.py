import sys
from pathlib import Path
from unittest import mock
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
