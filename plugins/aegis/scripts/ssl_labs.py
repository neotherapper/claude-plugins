#!/usr/bin/env python3
"""SSL Labs API v3 — TLS grade for a host (no auth, async poll)."""
import argparse
import json
import sys
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

SSLLABS = "https://api.ssllabs.com/api/v3/analyze"
_MAX_POLLS = 6
_POLL_DELAY = 5


def grade(host):
    url = f"{SSLLABS}?host={host}&all=done"
    for _ in range(_MAX_POLLS):
        r = _http.get_json(url, cache_ttl=0)
        if not isinstance(r, dict) or "error" in r:
            return {"grade": None, "error": r.get("error", "request failed")}
        status = r.get("status")
        if status == "READY":
            endpoints = r.get("endpoints", [])
            if endpoints and isinstance(endpoints[0], dict):
                return {"grade": endpoints[0].get("grade")}
            return {"grade": None}
        if status == "DNS_ERROR":
            return {"grade": None, "error": "dns_error"}
        time.sleep(_POLL_DELAY)
    return {"grade": None, "error": "timeout"}


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--host", required=True)
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    print(json.dumps(grade(a.host), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
