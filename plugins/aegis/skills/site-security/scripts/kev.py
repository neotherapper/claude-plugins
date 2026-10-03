#!/usr/bin/env python3
"""CISA Known Exploited Vulnerabilities (KEV) — set of exploited CVE IDs (no auth)."""
import argparse
import json
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

KEV_URL = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"


def exploited_ids():
    r = _http.get_json(KEV_URL, cache_ttl=86400)
    if not isinstance(r, dict) or "vulnerabilities" not in r:
        return set()
    ids = set()
    for v in r["vulnerabilities"]:
        if isinstance(v, dict) and "cveID" in v:
            ids.add(v["cveID"])
    return ids


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--json", action="store_true")
    p.parse_args(argv)
    print(json.dumps(sorted(exploited_ids()), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
