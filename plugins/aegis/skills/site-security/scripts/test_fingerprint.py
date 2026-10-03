import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import fingerprint

TECH_STACK_BEACON = """---
type: tech-stack
title: "Tech Stack — example-com"
resource: "https://example.com"
tags: []
timestamp: "2025-07-15T00:00:00Z"
status: complete
---

# Tech Stack — example-com

## Framework Detection
| Signal | Framework | Confidence |
|--------|-----------|------------|
| `x-powered-by: Express` | Express | High |

## Version Evidence
- **Express:** 4.18.2

## Server Info
- **Server:** nginx/1.25.3
"""

TECH_STACK_WORDPRESS = """---
type: tech-stack
title: "Tech Stack — my-wp-site"
resource: "https://my-wp-site.com"
status: complete
---

# Tech Stack — my-wp-site

| Property | Value |
|----------|-------|
| Framework | WordPress 6.5 |
| CDN | Cloudflare |
| Auth | WordPress login |

## Server Info
- **Server:** Apache/2.4.57
"""

TECH_STACK_NO_VERSION = """---
type: tech-stack
resource: "https://bare.com"
status: complete
---

| Property | Value |
|----------|-------|
| Framework | Django |
"""


def test_from_slug_beacon_framework_table(monkeypatch, tmp_path):
    research_dir = tmp_path / "docs" / "sites" / "example-com" / "research"
    research_dir.mkdir(parents=True)
    (research_dir / "tech-stack.md").write_text(TECH_STACK_WORDPRESS)
    monkeypatch.setattr(fingerprint, "_research_root", lambda: tmp_path / "docs" / "sites")
    fp = fingerprint.from_slug("example-com")
    assert fp["source"] == "beacon"
    assert fp["url"] == "https://my-wp-site.com"
    comps = fp["components"]
    assert any(c["name"] == "WordPress" and c["version"] == "6.5" for c in comps)


def test_from_slug_beacon_framework_detection_table(monkeypatch, tmp_path):
    research_dir = tmp_path / "docs" / "sites" / "example-com" / "research"
    research_dir.mkdir(parents=True)
    (research_dir / "tech-stack.md").write_text(TECH_STACK_BEACON)
    monkeypatch.setattr(fingerprint, "_research_root", lambda: tmp_path / "docs" / "sites")
    fp = fingerprint.from_slug("example-com")
    assert fp["source"] == "beacon"
    assert fp["url"] == "https://example.com"
    comps = fp["components"]
    assert any(c["name"] == "Express" and c["version"] == "4.18.2" for c in comps)
    assert any(c["name"] == "nginx" for c in comps)


def test_from_slug_no_version_marks_unknown(monkeypatch, tmp_path):
    research_dir = tmp_path / "docs" / "sites" / "bare-com" / "research"
    research_dir.mkdir(parents=True)
    (research_dir / "tech-stack.md").write_text(TECH_STACK_NO_VERSION)
    monkeypatch.setattr(fingerprint, "_research_root", lambda: tmp_path / "docs" / "sites")
    fp = fingerprint.from_slug("bare-com")
    comps = fp["components"]
    django = [c for c in comps if c["name"] == "Django"]
    assert len(django) == 1
    assert django[0]["version"] is None


def test_from_slug_no_file_returns_headers_or_none(monkeypatch, tmp_path):
    monkeypatch.setattr(fingerprint, "_research_root", lambda: tmp_path / "docs" / "sites")
    fp = fingerprint.from_slug("nonexistent-com")
    assert fp["source"] in ("headers", "none")


def test_from_url_fallback(monkeypatch):
    def fake_headers(url):
        return {"source": "headers", "components": [{"name": "Apache", "version": None, "kind": "server"}], "url": url}
    monkeypatch.setattr(fingerprint, "_from_headers", fake_headers)
    fp = fingerprint.from_url("https://example.com")
    assert fp["source"] == "headers"
    assert fp["components"][0]["name"] == "Apache"
