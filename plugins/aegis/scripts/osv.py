#!/usr/bin/env python3
"""OSV.dev query — packages/JS-libs -> known vulns (no auth). Primary CVE source."""
import argparse, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

OSV_QUERY = "https://api.osv.dev/v1/query"

def _cvss(sev):
    scores = []
    for s in sev or []:
        if not isinstance(s, dict):
            continue
        try:
            scores.append(float(s.get("score")))
        except (TypeError, ValueError):
            continue  # None, vector-string ("CVSS:3.1/..."), or missing → skip
    return max(scores) if scores else None

def query(name, version, ecosystem="npm"):
    r = _http.post_json(OSV_QUERY, {"version": version,
                                    "package": {"name": name, "ecosystem": ecosystem}})
    if not isinstance(r, dict) or "vulns" not in r:
        return []
    out = []
    for v in r["vulns"]:
        if not isinstance(v, dict):
            continue
        summary = v.get("summary") or v.get("details") or ""
        if not isinstance(summary, str):
            summary = str(summary)
        out.append({"id": v.get("id"), "summary": summary[:200],
                    "cvss": _cvss(v.get("severity")), "aliases": v.get("aliases", []), "source": "osv"})
    return out

def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--name", required=True); p.add_argument("--version", required=True)
    p.add_argument("--ecosystem", default="npm"); p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    print(json.dumps(query(a.name, a.version, a.ecosystem), indent=2))
    return 0

if __name__ == "__main__":
    sys.exit(main())
