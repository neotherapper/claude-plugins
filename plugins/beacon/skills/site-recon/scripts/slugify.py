#!/usr/bin/env python3
"""Canonical URL->slug for beacon — the single source of truth.

Mirrors the rule documented in docs/SLUG_RULES.md. Both scaffold.sh and
fleet.py call this so the scaffolder and the fleet ledger can never disagree
on a slug (a mismatch would make fleet.py read the wrong INDEX.md).

Rule (order matters): lowercase -> strip scheme -> strip leading www. ->
strip path -> strip :port -> dots to dashes.
"""
import re
import sys


def slugify(url: str) -> str:
    s = url.strip().lower()
    s = re.sub(r"^https?://", "", s)
    s = re.sub(r"^www\.", "", s)
    s = re.sub(r"/.*$", "", s)
    s = re.sub(r":[0-9]+$", "", s)
    return s.replace(".", "-")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.stderr.write("usage: slugify.py <url>\n")
        sys.exit(2)
    print(slugify(sys.argv[1]))
