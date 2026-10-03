#!/usr/bin/env python3
"""Fingerprint: parse beacon tech-stack.md or fall back to HTTP headers."""
import re
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _http

_NAME_VER_SPACE = re.compile(r"^(.*?)\s+(v?\d[\d.]*)$")
_NAME_VER_SLASH = re.compile(r"^(.*?)/(\d[\d.]*)$")


def _research_root():
    return Path("docs") / "sites"


def _parse_framework(value):
    """Split 'WordPress 6.5' or 'nginx/1.25.3' → (name, version)."""
    v = value.strip()
    m = _NAME_VER_SPACE.match(v)
    if m:
        return m.group(1).strip(), m.group(2).strip()
    m = _NAME_VER_SLASH.match(v)
    if m:
        return m.group(1).strip(), m.group(2).strip()
    return v, None


def _parse_version_evidence(text):
    """Parse '- **Framework:** 4.18.2' lines → {name: version}."""
    versions = {}
    for line in text.splitlines():
        m = re.match(r"-\s+\*\*(.+?):\*\*\s+(.+)", line)
        if m:
            versions[m.group(1).strip()] = m.group(2).strip()
    return versions


def _parse_tech_stack(content):
    """Parse a beacon tech-stack.md → components list."""
    components = []

    # Extract frontmatter (simple key: value parser, no yaml dependency)
    fm = {}
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            for line in parts[1].splitlines():
                line = line.strip()
                if ":" in line:
                    k, v = line.split(":", 1)
                    fm[k.strip()] = v.strip().strip('"').strip("'")

    url = fm.get("resource")

    # Strategy 1: | Property | Value | table (old format)
    for m in re.finditer(r"^\|\s*Framework\s*\|\s*(.+?)\s*\|", content, re.MULTILINE):
        name, ver = _parse_framework(m.group(1))
        components.append({"name": name, "version": ver, "kind": "framework"})

    # Strategy 2: Framework Detection table (new format)
    if not components:
        for m in re.finditer(
            r"^\|\s*`[^`]*`\s*\|\s*(.+?)\s*\|\s*\w+\s*\|", content, re.MULTILINE
        ):
            name, ver = _parse_framework(m.group(1))
            components.append({"name": name, "version": ver, "kind": "framework"})

    # Strategy 3: Version Evidence section (extract versions for known names)
    versions = {}
    ve_match = re.search(r"##\s*Version Evidence\s*\n(.*?)(?=\n##|\Z)", content, re.DOTALL)
    if ve_match:
        versions = _parse_version_evidence(ve_match.group(1))

    # Merge versions into existing components
    for comp in components:
        if comp["version"] is None and comp["name"] in versions:
            comp["version"] = versions[comp["name"]]

    # Extract server info
    for m in re.finditer(r"-\s+\*\*Server:\*\*\s+(.+)", content):
        serv = m.group(1).strip()
        name, ver = _parse_framework(serv)
        components.append({"name": name, "version": ver, "kind": "server"})

    return {"source": "beacon", "components": components, "url": url}


def _from_headers(url):
    """Fallback: derive coarse fingerprint from HTTP headers."""
    r = _http.get_json(url, headers={"Accept": "text/html"}, cache_ttl=86400)
    if isinstance(r, dict) and "error" in r:
        return {"source": "none", "components": [], "url": url}

    # get_json returns parsed JSON, but we need raw headers for Server/X-Powered-By.
    # Since _http doesn't expose headers, we do a minimal raw fetch.
    from urllib import request as req, error as err
    try:
        h = req.Request(url, method="HEAD", headers={"User-Agent": "aegis-fingerprint/0.1"})
        with req.urlopen(h, timeout=10) as resp:
            server = resp.headers.get("Server", "")
            powered = resp.headers.get("X-Powered-By", "")
    except Exception:
        return {"source": "none", "components": [], "url": url}

    components = []
    if server:
        name, ver = _parse_framework(server)
        components.append({"name": name, "version": ver, "kind": "server"})
    if powered:
        name, ver = _parse_framework(powered)
        components.append({"name": name, "version": ver, "kind": "framework"})

    source = "headers" if components else "none"
    return {"source": source, "components": components, "url": url}


def from_slug(slug):
    tech_stack = _research_root() / slug / "research" / "tech-stack.md"
    if tech_stack.is_file():
        content = tech_stack.read_text(encoding="utf-8", errors="replace")
        return _parse_tech_stack(content)
    return {"source": "none", "components": [], "url": None}


def from_url(url):
    return _from_headers(url)


def main(argv=None):
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--slug", help="Site slug (reads beacon tech-stack.md)")
    p.add_argument("--url", help="URL (falls back to header fingerprint)")
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    import json
    if a.slug:
        result = from_slug(a.slug)
    elif a.url:
        result = from_url(a.url)
    else:
        p.error("either --slug or --url required")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
