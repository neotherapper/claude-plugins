#!/usr/bin/env python3
"""Beacon OKF validator — fail-closed gate for site-recon output bundles.
Conforms to Google OKF v0.1 (type required, markdown-link graph). See
../references/okf-profile.md for the authoritative schema."""
from __future__ import annotations
import argparse, re, sys
from pathlib import Path

try:
    import yaml
    _YAML = True
except ImportError:
    _YAML = False

TYPE_ENUM = {"site-index", "tech-stack", "site-map", "api-surface", "constants",
             "session-brief", "phase-checklist", "data-source-index", "dataset", "access-profile"}
ACCESS_MODE = {"open-api", "bulk-download", "scrape", "gated", "mixed"}
AUTH = {"none", "api-key", "oauth", "session", "cac-pki", "account"}
BOT_PROTECTION = {"none", "cloudflare", "akamai", "datadome", "perimeterx", "f5", "recaptcha", "turnstile"}
VERIFICATION = {"live-verified", "wayback-verified", "asserted-unverified"}
STATUS = {"draft", "in-progress", "complete"}
ENUM_FIELDS = {"access_mode": ACCESS_MODE, "auth": AUTH,
               "bot_protection": BOT_PROTECTION, "verification": VERIFICATION, "status": STATUS}
# every beacon concept needs type+status; api-surface needs the access triad too
REQUIRED_BY_TYPE = {
    "api-surface": ("type", "title", "access_mode", "auth", "verification", "status"),
}
REQUIRED_DEFAULT = ("type", "status")

def parse_frontmatter(text: str):
    m = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return None
    body = m.group(1)
    if _YAML:
        try:
            d = yaml.safe_load(body)
            return d if isinstance(d, dict) else None
        except yaml.YAMLError:
            return None
    fm = {}
    for raw in body.split("\n"):
        if ":" not in raw or raw[:1] in (" ", "\t"):
            continue
        k, _, v = raw.partition(":")
        fm[k.strip()] = v.strip().strip("'\"")
    return fm

def validate_node(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        return [f"cannot read: {e}"]
    fm = parse_frontmatter(text)
    if fm is None:
        return ["missing or unparseable YAML frontmatter (fail-closed)"]
    t = fm.get("type")
    if t not in TYPE_ENUM:
        return [f"unknown type '{t}' (not in beacon enum)"]
    errs = []
    for f in REQUIRED_BY_TYPE.get(t, REQUIRED_DEFAULT):
        if not fm.get(f):
            errs.append(f"missing/empty required field: {f}")
    for field, allowed in ENUM_FIELDS.items():
        if field in fm and fm[field] not in allowed:
            errs.append(f"invalid {field} '{fm[field]}' (not in enum)")
    return errs
