---
name: site-security
description: Use when the user asks to "scan my site for vulnerabilities", "what CVEs does X have", "security coverage for", "check my site's security", or runs /aegis:scan. Produces a prioritized passive vulnerability-coverage report from a site's fingerprint — known CVEs (OSV-first) ranked by CISA KEV + EPSS, plus TLS/header misconfig. Passive lookup only (no active probing).
license: MIT
metadata:
  version: "0.1.0"
  author: Georgios Pilitsoglou
---

# site-security — Passive Vulnerability Coverage

Produce a prioritized security-coverage report for a target site. This is a **passive
lookup only** — it queries public CVE feeds and grading services, never probes the target.

**v0.1 scope:** passive data-lookup (OSV, NVD, KEV, EPSS, SSL Labs, Mozilla Observatory).
Active scanning / exploit confirmation is a future v0.2 step requiring explicit authorization.

## Quickstart

Resolve the target (slug or URL), then run the orchestrator:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/coverage.py" --slug {slug}
# or
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/coverage.py" --url {url}
```

Output is written to `docs/sites/{slug}/security/coverage.{json,md}`.

## Workflow

1. **Resolve target.** Accept a URL or a site slug. If a URL is given, derive the slug
   (host dots → dashes). If a beacon research folder exists (`docs/sites/{slug}/research/`),
   the fingerprint stage reuses it automatically.

2. **Run coverage.py.** The orchestrator chains: fingerprint → OSV/NVD CVE lookup →
   KEV/EPSS overlay → SSL Labs / Observatory misconfig → report.

3. **Present results.** Show the report summary, **KEV/high-EPSS items first**:
   - Components found and CVE count
   - KEV exploited CVEs (highest priority)
   - High CVSS + high EPSS CVEs
   - Misconfig grades (TLS, headers)
   - Any coverage-incomplete sources (never silently ignored)

4. **Honesty notes.** Always surface:
   - `[VERSION-UNKNOWN]` components (version missing → not assessed, not clean)
   - `coverage_incomplete` sources (feed failures → gaps, not zero-vulns)
   - This is passive lookup — active confirmation is a separate future step

## Data Sources

| Source | Purpose | Auth |
|--------|---------|------|
| OSV.dev | Package CVE lookup (npm, PyPI, etc.) | none |
| NVD | Framework/server keyword CVE search | none |
| CISA KEV | Exploited-in-the-wild overlay | none |
| FIRST EPSS | Exploit likelihood overlay | none |
| SSL Labs | TLS configuration grade | none |
| Mozilla Observatory | HTTP security headers grade | none |

## Report Location

`docs/sites/{slug}/security/coverage.json` and `coverage.md`

## v0.1 Limitations (state these to the user)

- Passive only — no active scanning or exploit confirmation
- CVE coverage depends on OSV/NVD feed completeness
- Missing component versions → reported as `[VERSION-UNKNOWN]`, not "clean"
- SSL Labs and Observatory are asynchronous — may timeout on complex sites
