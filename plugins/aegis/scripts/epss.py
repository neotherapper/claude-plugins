#!/usr/bin/env python3
"""FIRST.org EPSS scores — exploit prediction scoring for CVE IDs (no auth)."""
import argparse
import json
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

EPSS_URL = "https://api.first.org/data/v1/epss"


def scores(cve_ids):
    if not cve_ids:
        return {}
    chunk_size = 100
    result = {}
    for i in range(0, len(cve_ids), chunk_size):
        chunk = cve_ids[i:i + chunk_size]
        url = f"{EPSS_URL}?cve={','.join(chunk)}"
        r = _http.get_json(url, cache_ttl=86400)
        if not isinstance(r, dict) or "data" not in r:
            continue
        for d in r["data"]:
            if not isinstance(d, dict):
                continue
            cve = d.get("cve")
            epss_str = d.get("epss")
            if cve and epss_str:
                try:
                    result[cve] = float(epss_str)
                except (TypeError, ValueError):
                    pass
    return result


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--cve", action="append", required=True)
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    print(json.dumps(scores(a.cve), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
