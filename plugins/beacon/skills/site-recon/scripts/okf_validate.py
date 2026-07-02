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

def is_complete(path: Path) -> bool:
    """True iff path's frontmatter has status: complete (quote-normalizing,
    frontmatter-anchored — same parser validate_node/validate_bundle use).
    Any read/parse failure fails closed to False."""
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return False
    fm = parse_frontmatter(text)
    if fm is None:
        return False
    return fm.get("status") == "complete"

def validate_node(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as e:
        return [f"cannot read: invalid UTF-8: {e}"]
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
        if field not in fm:
            continue
        val = fm[field]
        if not isinstance(val, str) or val not in allowed:
            errs.append(f"invalid {field} '{val}' (not in enum)")
    return errs

_LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
_TOKEN = re.compile(r"\{\{[^}]+\}\}")

def _body(text: str) -> str:
    m = re.match(r"^---\s*\n.*?\n---\s*\n", text, re.DOTALL)
    return text[m.end():] if m else text

def validate_bundle(root: Path) -> dict[str, list[str]]:
    results: dict[str, list[str]] = {}
    md = [p for p in root.rglob("*.md") if ".beacon" not in p.parts]
    if not md:
        return {str(root): ["empty bundle: no OKF concept files (fail-closed)"]}
    has_index = False
    for p in md:
        errs = validate_node(p)
        text = p.read_text(encoding="utf-8", errors="ignore")
        fm = parse_frontmatter(text) or {}
        if fm.get("type") in ("site-index", "data-source-index"):
            has_index = True
        for tgt in _LINK.findall(_body(text)):
            tgt = tgt.split("#", 1)[0].strip()
            if not tgt or tgt.startswith(("http://", "https://", "mailto:")):
                continue
            if not (p.parent / tgt).exists():
                errs.append(f"link target does not resolve: {tgt}")
        if fm.get("status") == "complete" and _TOKEN.search(_body(text)):
            errs.append("unfilled template token in a status:complete file")
        if errs:
            results[str(p)] = errs
    if not has_index:
        results[str(root)] = results.get(str(root), []) + ["no INDEX.md entrypoint (type site-index/data-source-index)"]
    return results

def main() -> int:
    ap = argparse.ArgumentParser(description="Beacon OKF validator (fail-closed)")
    ap.add_argument("root", nargs="?", default=None,
                     help="output bundle root (e.g. docs/sites/<slug>/research)")
    ap.add_argument("--is-complete", metavar="FILE", default=None,
                     help="check a single file's frontmatter status:complete and exit "
                          "0 (complete) or 1 (not complete/unreadable); no bundle validation")
    args = ap.parse_args()
    if args.is_complete is not None:
        return 0 if is_complete(Path(args.is_complete)) else 1
    if not args.root:
        ap.error("root is required unless --is-complete is given")
    results = validate_bundle(Path(args.root))
    for path, errs in results.items():
        print(f"\n{path}:")
        for e in errs:
            print(f"  - {e}")
    print(f"\nbeacon-okf-validate: {len(results)} file(s)/root with failures.")
    return 1 if results else 0

if __name__ == "__main__":
    sys.exit(main())
