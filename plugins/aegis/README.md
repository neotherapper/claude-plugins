# aegis — Passive Vulnerability Coverage

**v0.1.0** — passive lookup only; no active scanning.

## What it does

Turns a site's fingerprint (from beacon or HTTP headers) into a prioritized security-coverage report:

1. **Fingerprint** — reads beacon's `tech-stack.md` (or falls back to HTTP headers)
2. **CVE lookup** — OSV.dev for packages, NVD keyword search for frameworks/servers
3. **Prioritize** — overlays CISA KEV (exploited-in-the-wild) + EPSS (exploit likelihood)
4. **Misconfig** — SSL Labs TLS grade + Mozilla Observatory header checks
5. **Report** — writes `docs/sites/{slug}/security/coverage.{json,md}`

## Usage

```
/aegis:scan https://example.com
/aegis:scan my-site-slug
```

Or run the orchestrator directly:

```bash
python3 plugins/aegis/scripts/coverage.py --url https://example.com
python3 plugins/aegis/scripts/coverage.py --slug my-site-slug
```

## Data Sources

| Source | Purpose |
|--------|---------|
| OSV.dev | Package CVE lookup (npm, PyPI, Go, Rust, etc.) |
| NVD | Framework/server keyword CVE search |
| CISA KEV | Exploited-in-the-wild overlay |
| FIRST EPSS | Exploit likelihood scoring |
| SSL Labs | TLS configuration grade |
| Mozilla Observatory | HTTP security headers grade |

## Honesty Signals

- **`[VERSION-UNKNOWN]`** — component version missing → reported as "not assessed," never read as "clean"
- **`coverage_incomplete`** — a feed failed → the gap is surfaced, never silently treated as zero-vulns
- **Passive only** — no active probing; v0.2 will add scope-gated active confirmation

## v0.2 Roadmap

- Authorized-target gate + allowlist for active scanning
- `site-utils nuclei-scan` integration (scope-gated)
- Per-JS-library SBOM (retire.js-style)
- WordPress depth via Wordfence feed

## Development

```bash
# Run all tests
python3 -m pytest plugins/aegis/scripts/ -q

# Individual module tests
python3 -m pytest plugins/aegis/scripts/test_http.py -q
python3 -m pytest plugins/aegis/scripts/test_osv.py -q
```

Zero third-party dependencies — stdlib `urllib` only.
