#!/usr/bin/env python3
"""NVD keyword CVE search — frameworks/servers -> known vulns (no auth). Fallback CVE source."""
import argparse
import json
import sys
from urllib.parse import quote
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

NVD_CVES = "https://services.nvd.nist.gov/rest/json/cves/2.0"


def _cvss(metrics):
    for key in ("cvssMetricV31", "cvssMetricV30", "cvssMetricV2"):
        pairs = metrics.get(key, [])
        if pairs:
            try:
                return pairs[0]["cvssData"]["baseScore"]
            except (KeyError, IndexError, TypeError):
                pass
    return None


def _description(cve):
    for d in cve.get("descriptions", []):
        if d.get("lang") == "en":
            return d.get("value", "")
    return ""


def search(keyword, limit=20):
    url = f"{NVD_CVES}?keywordSearch={quote(keyword)}&resultsPerPage={limit}"
    r = _http.get_json(url, cache_ttl=86400)
    if not isinstance(r, dict) or "vulnerabilities" not in r:
        return []
    out = []
    for item in r["vulnerabilities"]:
        if not isinstance(item, dict):
            continue
        cve = item.get("cve")
        if not isinstance(cve, dict):
            continue
        out.append({
            "id": cve.get("id"),
            "cvss": _cvss(cve.get("metrics", {})),
            "summary": _description(cve),
            "source": "nvd",
        })
    return out


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--keyword", required=True)
    p.add_argument("--limit", type=int, default=20)
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    print(json.dumps(search(a.keyword, a.limit), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
