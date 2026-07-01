# site-recon bundled helper scripts

This directory contains 12 helper scripts that ship alongside the site-recon skill.

## IMPORTANT: reference-only — NOT invoked by the phase flow

**All 12 scripts are currently orphaned.** The skill's 16-phase flow does not call any of them; they exist as standalone helpers that an operator can run manually or wire in later. Only `osint.py` (exercised by `test_osint.py` and `run_osint_tests.sh`) has any automated test coverage. The remaining 9 scripts are **untested**.

---

## Script inventory (read-verified)

| Script | Serves (phase) | What it does (verified) | Status |
|---|---|---|---|
| `osint.py` | Phase 9 — OSINT | Python CLI orchestrator (uses `google-fire`). Discovers all executable `*.sh` scripts in this directory, runs each one with TARGET as its first argument, and returns a JSON document mapping script-stem → `{stdout, stderr, exit_code}`. Entry points: `run_all --target <domain>` and `list`. | orphaned; has test coverage (see below) |
| `test_osint.py` | Test harness for `osint.py` | Python unit test: invokes `osint.py run_all --target example.com` as a subprocess, asserts exit 0, and validates the JSON output shape (dict with `stdout`/`stderr`/`exit_code` per script). Not a phase helper — a correctness test for the orchestrator. | orphaned; automated test |
| `run_osint_tests.sh` | Test harness for `osint.py` | Thin shell wrapper that calls `osint.py run_all --target example.com` and checks for exit 0. Minimal CI-style smoke test for the Python orchestrator. | orphaned; automated test |
| `sublist3r.sh` | Phase 9 — OSINT / Phase 1.5 — Domain Discovery | Subdomain enumeration via Sublist3r (gracefully skips if not installed). Reads `TARGET` env var; saves results to `sublist3r.txt`. | orphaned; untested |
| `passive_dns.sh` | Phase 9 — OSINT / Phase 1.5 — Domain Discovery | Passive DNS lookups from two sources: VirusTotal public domain-reports API (no key required, prints up to 100 subdomains) and DNSDB (requires `$DNSDB_API_KEY`; skipped if unset). | orphaned; untested |
| `tls_fingerprint.sh` | Phase 3 — Fingerprinting | TLS/SSL analysis using whichever of `testssl.sh`, `sslyze`, or `tls-scan` is installed. Reads `TARGET` env var; each tool is tried in sequence and skipped if absent. | orphaned; untested |
| `graphql_introspect.sh` | Phase 8 — OpenAPI / API Surface Detection | Sends a GraphQL introspection query (`__schema { types { name fields { name } } }`) to `https://${TARGET}/graphql` and pretty-prints the result via `jq`. | orphaned; untested |
| `openapi_detect.sh` | Phase 8 — OpenAPI / API Surface Detection | HTTP-probes five common OpenAPI/Swagger spec paths (`/swagger.json`, `/swagger.yaml`, `/openapi.json`, `/openapi.yaml`, `/v1/api-docs`) and prints `FOUND:` for any that return HTTP 200. | orphaned; untested |
| `config_leakage.sh` | Phase 6b — Security Exposure Scan | Probes for publicly accessible configuration and secret files (`.env`, `config.yml`, `settings.json`, `.gitlab-ci.yml`, `.github/workflows/*.yml`) and prints the first 20 lines of any that respond with 2xx. | orphaned; untested |
| `cloud-enum.sh` | Phase 6b — Security Exposure Scan / Phase 9 — OSINT | Enumerates cloud storage buckets using naming patterns derived from TARGET: AWS S3 (both path-style and virtual-hosted), Azure Blob Storage, Google Cloud Storage, and Cloudflare R2. Reports any that return 2xx. | orphaned; untested |
| `container-scan.sh` | Phase 6b — Security Exposure Scan | Checks for exposed Docker Registry API endpoints (`/v2/_catalog`, `/v2/`), Kubernetes API server ports (6443, 8443, 8080, 443), and container orchestration dashboards (`/dashboard`, `/rancher`, `/portainer`, etc.). | orphaned; untested |
| `cicd-scan.sh` | Phase 6b — Security Exposure Scan | Probes for exposed CI/CD pipeline configs (GitHub Actions workflows, `.gitlab-ci.yml`, Jenkins dashboard + API, Travis CI, Azure Pipelines, CircleCI, Jenkinsfile) and build/webhook endpoints (`/build`, `/ci`, `/pipeline`, `/deploy`, `/webhook`, `/hooks`). | orphaned; untested |

---

## Drift risk

Several scripts duplicate logic that the skill already performs inline:

- **`openapi_detect.sh`** probes the same Swagger/OpenAPI paths that Phase 8 checks inline — two sources of truth that can diverge independently.
- **`osint.py`** and its shell helpers cover subdomain and OSINT enumeration that Phase 9 also handles with inline `curl`/CDX commands.
- **`config_leakage.sh`** checks for `.env`, `.gitlab-ci.yml`, and GitHub Actions files — paths that Phase 6b's inline security scan also covers.
- **`cicd-scan.sh`** overlaps with `config_leakage.sh` on `.gitlab-ci.yml` and `.github/workflows` paths, creating a second intra-scripts duplication.

Any change to the inline phase commands should be checked against the corresponding script, and vice versa.

---

**Follow-up: wire-or-delete — decide per script whether to invoke it from its phase or remove it.**
