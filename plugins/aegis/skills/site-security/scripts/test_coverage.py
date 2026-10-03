import json
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import coverage

FP_COMPONENTS = [
    {"name": "WordPress", "version": "6.5", "kind": "framework"},
    {"name": "nginx", "version": "1.25.3", "kind": "server"},
]

OSV_CVES = [{"id": "GHSA-wp-1", "summary": "XSS in WP", "cvss": 7.5, "aliases": ["CVE-2025-1"], "source": "osv"}]
NVD_CVES = [{"id": "CVE-2025-2", "summary": "RCE in nginx", "cvss": 8.1, "source": "nvd"}]
KEV_IDS = {"CVE-2025-2"}
EPSS_SCORES = {"CVE-2025-2": 0.42}
TLS_GRADE = {"grade": "A"}
OBS_GRADE = {"grade": "B", "score": 65, "failed": ["content-security-policy"]}


def _patch_all(monkeypatch):
    monkeypatch.setattr(coverage.fingerprint, "from_slug",
        lambda slug: {"source": "beacon", "components": FP_COMPONENTS, "url": "https://example.com"})
    monkeypatch.setattr(coverage.osv, "query",
        lambda name, ver, eco="npm": OSV_CVES if name == "WordPress" else [])
    monkeypatch.setattr(coverage.nvd, "search",
        lambda kw, limit=20: NVD_CVES if "nginx" in kw else [])
    monkeypatch.setattr(coverage.kev, "exploited_ids", lambda: KEV_IDS)
    monkeypatch.setattr(coverage.epss, "scores", lambda ids: EPSS_SCORES)
    monkeypatch.setattr(coverage.ssl_labs, "grade", lambda host: TLS_GRADE)
    monkeypatch.setattr(coverage.observatory, "grade", lambda host: OBS_GRADE)


def test_run_returns_report_model(monkeypatch, tmp_path):
    _patch_all(monkeypatch)
    report = coverage.run(slug="example-com", out_dir=tmp_path)
    assert report["slug"] == "example-com"
    assert report["fingerprint_source"] == "beacon"
    assert len(report["components"]) == 2
    assert report["misconfig"]["tls_grade"] == "A"
    assert report["misconfig"]["headers_grade"] == "B"
    assert report["summary"]["components"] == 2


def test_kev_cve_marked(monkeypatch, tmp_path):
    _patch_all(monkeypatch)
    report = coverage.run(slug="example-com", out_dir=tmp_path)
    nginx_cves = [c for comp in report["components"] if comp["name"] == "nginx"
                  for c in comp["cves"]]
    assert any(c["kev"] is True for c in nginx_cves)
    assert any(c["epss"] == 0.42 for c in nginx_cves)


def test_findings_ordered_kev_first(monkeypatch, tmp_path):
    _patch_all(monkeypatch)
    report = coverage.run(slug="example-com", out_dir=tmp_path)
    # KEV CVE should be first in the flattened findings list
    all_cves = [c for comp in report["components"] for c in comp["cves"]]
    kev_idx = next(i for i, c in enumerate(all_cves) if c["kev"] is True)
    assert kev_idx == 0


def test_coverage_incomplete_on_error(monkeypatch, tmp_path):
    _patch_all(monkeypatch)
    monkeypatch.setattr(coverage.ssl_labs, "grade", lambda host: {"grade": None, "error": "timeout"})
    report = coverage.run(slug="example-com", out_dir=tmp_path)
    assert "ssl_labs" in report["summary"]["coverage_incomplete"]


def test_version_unknown_marks_incomplete(monkeypatch, tmp_path):
    monkeypatch.setattr(coverage.fingerprint, "from_slug",
        lambda slug: {"source": "beacon",
                      "components": [{"name": "Django", "version": None, "kind": "framework"}],
                      "url": "https://example.com"})
    monkeypatch.setattr(coverage.osv, "query", lambda *a, **k: [])
    monkeypatch.setattr(coverage.nvd, "search", lambda *a, **k: [])
    monkeypatch.setattr(coverage.kev, "exploited_ids", lambda: set())
    monkeypatch.setattr(coverage.epss, "scores", lambda ids: {})
    monkeypatch.setattr(coverage.ssl_labs, "grade", lambda host: {"grade": "A"})
    monkeypatch.setattr(coverage.observatory, "grade", lambda host: {"grade": "A", "score": 90, "failed": []})
    report = coverage.run(slug="test-com", out_dir=tmp_path)
    assert report["components"][0]["version_known"] is False
    assert any("Django" in x for x in report["summary"]["coverage_incomplete"])


def test_writes_json_and_md(monkeypatch, tmp_path):
    _patch_all(monkeypatch)
    coverage.run(slug="example-com", out_dir=tmp_path)
    assert (tmp_path / "coverage.json").is_file()
    assert (tmp_path / "coverage.md").is_file()
    data = json.loads((tmp_path / "coverage.json").read_text())
    assert data["slug"] == "example-com"
    md = (tmp_path / "coverage.md").read_text()
    assert "Coverage" in md or "coverage" in md


def test_run_from_url(monkeypatch, tmp_path):
    monkeypatch.setattr(coverage.fingerprint, "from_url",
        lambda url: {"source": "headers", "components": [{"name": "nginx", "version": None, "kind": "server"}], "url": url})
    monkeypatch.setattr(coverage.nvd, "search", lambda *a, **k: [])
    monkeypatch.setattr(coverage.kev, "exploited_ids", lambda: set())
    monkeypatch.setattr(coverage.epss, "scores", lambda ids: {})
    monkeypatch.setattr(coverage.ssl_labs, "grade", lambda host: {"grade": "B"})
    monkeypatch.setattr(coverage.observatory, "grade", lambda host: {"grade": "C", "score": 40, "failed": []})
    report = coverage.run(url="https://example.com", out_dir=tmp_path)
    assert report["fingerprint_source"] == "headers"
