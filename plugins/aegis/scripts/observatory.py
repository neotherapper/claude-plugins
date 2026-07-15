#!/usr/bin/env python3
"""Mozilla Observatory — header security grade + failed checks for a host (no auth)."""
import argparse
import json
import sys
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

OBSERVATORY = "https://http-observatory.security.mozilla.org/api/v1/analyze"
_MAX_POLLS = 6
_POLL_DELAY = 3


def grade(host):
    url = f"{OBSERVATORY}?host={host}"
    for _ in range(_MAX_POLLS):
        r = _http.get_json(url, cache_ttl=0)
        if not isinstance(r, dict) or "error" in r:
            return {"grade": None, "score": None, "failed": [],
                    "error": r.get("error", "request failed")}
        state = r.get("state")
        if state in ("FINISHED", "ERROR"):
            scan = r.get("scan", {})
            tests = r.get("tests", {})
            failed = [name for name, t in tests.items()
                      if isinstance(t, dict) and not t.get("pass", True)]
            return {
                "grade": scan.get("grade"),
                "score": scan.get("score"),
                "failed": failed,
            }
        time.sleep(_POLL_DELAY)
    return {"grade": None, "score": None, "failed": [], "error": "timeout"}


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--host", required=True)
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    print(json.dumps(grade(a.host), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
