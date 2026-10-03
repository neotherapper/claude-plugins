#!/usr/bin/env python3
"""aegis coverage orchestrator: fingerprint → CVE lookup → KEV/EPSS overlay → misconfig → report."""
import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import fingerprint
import osv
import nvd
import kev
import epss
import ssl_labs
import observatory


def _derive_slug(url):
    """Best-effort slug from URL: host with dots→dashes."""
    from urllib.parse import urlparse
    host = urlparse(url).hostname or url
    return host.replace(".", "-").strip("-")


def _order_cves(cves):
    """KEV first, then cvss≥7 & epss≥0.1, then the rest."""
    def sort_key(c):
        is_kev = 0 if c.get("kev") else 1
        high_epss = 0 if (c.get("cvss", 0) or 0) >= 7 and (c.get("epss", 0) or 0) >= 0.1 else 1
        return (is_kev, high_epss, -((c.get("cvss") or 0)))
    return sorted(cves, key=sort_key)


def _render_coverage_md(report):
    """Render a human-readable coverage.md from the report model."""
    lines = [f"# Security Coverage — {report['slug']}", ""]
    lines.append(f"**Generated:** {report['generated']}")
    lines.append(f"**Target:** {report['url'] or 'N/A'}")
    lines.append(f"**Fingerprint source:** {report['fingerprint_source']}")
    lines.append("")

    s = report["summary"]
    lines.append(f"## Summary")
    lines.append(f"- **Components:** {s['components']}")
    lines.append(f"- **CVEs found:** {s['cves']}")
    lines.append(f"- **KEV exploited:** {s['kev']}")
    lines.append(f"- **High priority:** {s['high']}")
    if s.get("coverage_incomplete"):
        lines.append(f"- **Coverage incomplete:** {', '.join(s['coverage_incomplete'])}")
    lines.append("")

    # Misconfig
    m = report.get("misconfig", {})
    if m:
        lines.append("## Misconfiguration")
        lines.append(f"- **TLS grade:** {m.get('tls_grade') or 'N/A'}")
        lines.append(f"- **Headers grade:** {m.get('headers_grade') or 'N/A'}")
        if m.get("failed"):
            lines.append(f"- **Failed checks:** {', '.join(m['failed'])}")
        lines.append("")

    # Per-component CVEs
    lines.append("## Findings")
    for comp in report["components"]:
        ver_note = comp.get("version") or "unknown"
        vk = "" if comp.get("version_known", True) else " [VERSION-UNKNOWN]"
        lines.append(f"### {comp['name']} {ver_note}{vk}")
        if not comp.get("cves"):
            lines.append("No known CVEs found.")
        else:
            lines.append("| CVE | CVSS | KEV | EPSS | Source | Summary |")
            lines.append("|-----|------|-----|------|--------|---------|")
            for c in comp["cves"]:
                kev_mark = "YES" if c.get("kev") else ""
                epss_val = f"{c['epss']:.2f}" if c.get("epss") else ""
                summary = (c.get("summary") or "")[:60]
                lines.append(f"| {c['id']} | {c.get('cvss') or 'N/A'} | {kev_mark} | {epss_val} | {c.get('source')} | {summary} |")
        lines.append("")

    if s.get("coverage_incomplete"):
        lines.append("## Coverage Incomplete")
        lines.append(f"The following sources failed or returned partial data: {', '.join(s['coverage_incomplete'])}")
        lines.append("")

    return "\n".join(lines)


def run(slug=None, url=None, out_dir=None):
    # 1. Fingerprint
    if slug:
        fp = fingerprint.from_slug(slug)
    elif url:
        fp = fingerprint.from_url(url)
        slug = slug or _derive_slug(url)
    else:
        raise ValueError("either slug or url required")

    components = fp.get("components", [])

    # 2. CVE lookup per component
    coverage_incomplete = []
    for comp in components:
        name = comp["name"]
        version = comp.get("version")
        kind = comp.get("kind", "framework")

        comp["cves"] = []
        comp["version_known"] = version is not None

        if version is None:
            coverage_incomplete.append(f"VERSION-UNKNOWN:{name}")
            continue

        if kind == "package":
            result = osv.query(name, version)
        else:
            result = nvd.search(f"{name} {version}")

        if result and isinstance(result, list):
            comp["cves"] = result
        elif result and isinstance(result, dict) and "error" in result:
            coverage_incomplete.append(f"{name}")

    # 3. KEV + EPSS overlay
    all_cve_ids = []
    for comp in components:
        for c in comp.get("cves", []):
            if c.get("id"):
                all_cve_ids.append(c["id"])

    kev_ids = kev.exploited_ids()
    epss_scores = epss.scores(all_cve_ids)

    for comp in components:
        for c in comp.get("cves", []):
            cve_id = c.get("id")
            c["kev"] = cve_id in kev_ids if cve_id else False
            c["epss"] = epss_scores.get(cve_id) if cve_id else None

    # 4. Misconfig
    host = None
    if url:
        from urllib.parse import urlparse
        host = urlparse(url).hostname
    elif fp.get("url"):
        from urllib.parse import urlparse
        host = urlparse(fp["url"]).hostname

    tls = {"grade": None, "error": "no host"}
    headers = {"grade": None, "score": None, "failed": [], "error": "no host"}
    if host:
        tls = ssl_labs.grade(host)
        if "error" in tls:
            coverage_incomplete.append("ssl_labs")
        headers = observatory.grade(host)
        if "error" in headers:
            coverage_incomplete.append("observatory")

    # 5. Assemble report
    all_cves_flat = []
    for comp in components:
        all_cves_flat.extend(comp.get("cves", []))
    ordered = _order_cves(all_cves_flat)

    # Re-order per-component cves too
    for comp in components:
        comp["cves"] = _order_cves(comp.get("cves", []))

    report = {
        "slug": slug,
        "url": fp.get("url"),
        "generated": datetime.now(timezone.utc).isoformat(),
        "fingerprint_source": fp.get("source", "none"),
        "components": components,
        "misconfig": {
            "tls_grade": tls.get("grade"),
            "headers_grade": headers.get("grade"),
            "headers_score": headers.get("score"),
            "failed": headers.get("failed", []),
        },
        "summary": {
            "components": len(components),
            "cves": len(all_cves_flat),
            "kev": sum(1 for c in all_cves_flat if c.get("kev")),
            "high": sum(1 for c in all_cves_flat
                        if (c.get("cvss") or 0) >= 7 and (c.get("epss") or 0) >= 0.1),
            "coverage_incomplete": coverage_incomplete,
        },
    }

    # 6. Write output
    if out_dir:
        out_dir = Path(out_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "coverage.json").write_text(json.dumps(report, indent=2))
        (out_dir / "coverage.md").write_text(_render_coverage_md(report))

    return report


def main(argv=None):
    p = argparse.ArgumentParser(description="aegis passive vulnerability coverage")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--slug", help="Site slug (reads beacon research)")
    g.add_argument("--url", help="Target URL (header fingerprint fallback)")
    p.add_argument("--out", help="Output directory (default: docs/sites/{slug}/security/)")
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)

    slug = a.slug or (a.url.split("/")[2].replace(".", "-") if a.url else None)
    out_dir = a.out or str(Path("docs") / "sites" / slug / "security")

    report = run(slug=a.slug, url=a.url, out_dir=out_dir)
    if a.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"Coverage report written to {out_dir}/coverage.{{json,md}}")
        s = report["summary"]
        print(f"  Components: {s['components']}, CVEs: {s['cves']}, "
              f"KEV: {s['kev']}, High: {s['high']}")
        if s["coverage_incomplete"]:
            print(f"  Coverage incomplete: {', '.join(s['coverage_incomplete'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
