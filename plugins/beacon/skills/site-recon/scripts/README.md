# site-recon bundled helper scripts

This directory contains 12 files: 9 OSINT helper scripts, the `osint.py` orchestrator, and a
two-file test harness (`test_osint.py`, `run_osint_tests.sh`).

## Invoked by the phase flow (Phase 9 — OSINT)

The 9 `.sh` helpers are run in **Phase 9** by `osint.py run_all --target <domain>`, which invokes
each via `bash` (the executable bit is not required) and returns a JSON document mapping
script-stem → `{stdout, stderr, exit_code}`. A shell-loop fallback in the skill runs the same
helpers directly if `osint.py` / `fire` is unavailable. `config_leakage.sh` and `openapi_detect.sh`
are additionally pointed at from Phases 6b and 8.

Only `osint.py` has automated test coverage (via `test_osint.py` / `run_osint_tests.sh`); the 9
`.sh` helpers are exercised end-to-end by the sweep but have no unit tests. The test harness itself
is **not** a phase helper and is skipped by `run_all`.

---

## Script inventory (read-verified)

| Script | Serves | What it does (verified) | Status |
|---|---|---|---|
| `osint.py` | Phase 9 orchestrator | Python CLI (uses `fire`, Google Python Fire). Discovers the `.sh` helpers in this directory (excluding the `*_tests.sh` harness), runs each via `bash` with `TARGET` in the environment (per-helper timeout), and returns JSON mapping script-stem → `{stdout, stderr, exit_code}`. Entry points: `run_all --target <domain> [--exclude a,b]` and `list`. | invoked (Phase 9); has test coverage |
| `test_osint.py` | Test harness | Python unit test: runs `osint.py run_all --target example.com`, asserts exit 0 and validates the JSON shape. Not a phase helper. | test harness (skipped by sweep) |
| `run_osint_tests.sh` | Test harness | Shell wrapper that runs `osint.py run_all --target example.com` and checks exit 0. | test harness (skipped by sweep) |
| `sublist3r.sh` | Phase 9 (also seeds 1.5) | Subdomain enumeration via Sublist3r (gracefully skips if not installed). Reads `TARGET`; saves results to `sublist3r.txt`. | invoked (Phase 9); untested |
| `passive_dns.sh` | Phase 9 (also seeds 1.5) | Passive DNS from VirusTotal's public domain-reports API (no key, up to 100 subdomains) + DNSDB (needs `$DNSDB_API_KEY`; skipped if unset). | invoked (Phase 9); untested |
| `tls_fingerprint.sh` | Phase 9 (informs Phase 3) | TLS/SSL analysis using whichever of `testssl.sh`, `sslyze`, or `tls-scan` is installed. Reads `TARGET`. | invoked (Phase 9); untested |
| `graphql_introspect.sh` | Phase 9 (reinforces Phase 6) | Sends a GraphQL introspection query (`__schema { types { name fields { name } } }`) to `https://${TARGET}/graphql` and pretty-prints via `jq`. | invoked (Phase 9); untested |
| `openapi_detect.sh` | Phase 9 (reinforces Phase 8) | HTTP-probes five common OpenAPI/Swagger spec paths and prints `FOUND:` for any that return HTTP 200. | invoked (Phase 9); untested |
| `config_leakage.sh` | Phase 9 (reinforces Phase 6b) | Probes for public config/secret files (`.env`, `config.yml`, `settings.json`, `.gitlab-ci.yml`, `.github/workflows/ci.yml`, `.github/workflows/main.yml`, `.github/workflows/deploy.yml`) and prints the first 20 lines of any 2xx. | invoked (Phase 9); untested |
| `cloud-enum.sh` | Phase 9 (active infra probe) | Enumerates cloud buckets from TARGET-derived names: AWS S3 (path + virtual-hosted), Azure Blob, GCS, Cloudflare R2. Reports any 2xx. | invoked (Phase 9, scope-gated); untested |
| `container-scan.sh` | Phase 9 (active infra probe) | Checks Docker Registry (`/v2/_catalog`, `/v2/`), Kubernetes API ports (6443/8443/8080/443), and orchestration dashboards. | invoked (Phase 9, scope-gated); untested |
| `cicd-scan.sh` | Phase 9 | Probes exposed CI/CD configs (GitHub Actions, `.gitlab-ci.yml`, Jenkins, Travis, Azure Pipelines, CircleCI, Jenkinsfile) and build/webhook endpoints. | invoked (Phase 9); untested |

---

## Intentional reinforcement (not accidental duplication)

Some helpers deliberately re-cover checks the skill also performs inline — defense-in-depth so the
method still runs even if the inline prose step is skipped under synthesis pressure:

- **`openapi_detect.sh`** ↔ Phase 8's inline Swagger/OpenAPI path probes.
- **`config_leakage.sh`** ↔ Phase 6b's inline `.env` / config / CI checks.
- **`graphql_introspect.sh`** ↔ Phase 6's inline GraphQL introspection.

`cicd-scan.sh` and `config_leakage.sh` also overlap on `.gitlab-ci.yml` / `.github/workflows`. When
changing an inline phase command, check the corresponding helper (and vice versa) so the two do not
drift.

## Scope note

`cloud-enum.sh` and `container-scan.sh` actively probe third-party and infrastructure hosts, so the
Phase 9 sweep **excludes them by default** (`run_all --target <domain> --exclude cloud-enum,container-scan`).
Only drop that flag — re-including them — once the engagement explicitly authorises infrastructure
enumeration.
