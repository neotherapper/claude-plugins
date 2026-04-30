# OSINT Sources — Phase 9 Reference


---

## Passive DNS Lookup (VirusTotal, DNSDB)

Leverage passive DNS services to uncover historical subdomains, DNS records, and infrastructure changes.

```bash
TARGET="example.com"

# VirusTotal (no API key for basic lookup)
curl -s "https://www.virustotal.com/ui/domain_reports/${TARGET}" \
  | python3 -c "
import sys, json
j = json.load(sys.stdin)
subs = j.get('data', {}).get('attributes', {}).get('subdomains', [])
for s in subs[:100]:
    print(s)
"

# DNSDB (requires API key)
if [ -n "${DNSDB_API_KEY}" ]; then
  curl -s "https://api.dnsdb.info/lookup/rrset/name/${TARGET}/ANY" \
    -H "X-API-Key: ${DNSDB_API_KEY}" \
    | jq -r '.[].rrname' | sort -u
fi
```

**What to look for:**
- Historical subdomains no longer active.
- A records indicating past hosting providers.
- TXT records that may contain verification tokens or configuration snippets.

---

## TLS Fingerprinting (testssl.sh, sslyze, tls-scan)

Identify supported cipher suites, protocol versions, and certificate details to spot misconfigurations or legacy support.

```bash
TARGET="example.com"

# testssl.sh (requires installation)
if which testssl.sh &>/dev/null; then
  testssl.sh --fast ${TARGET}
fi

# sslyze (Python package)
if which sslyze &>/dev/null; then
  sslyze --regular ${TARGET}:443
fi

# tls-scan (Go binary)
if which tls-scan &>/dev/null; then
  tls-scan ${TARGET}:443
fi
```

**What to look for:**
- Enabled TLS 1.0/1.1 or deprecated ciphers.
- Certificate chain anomalies (self‑signed, expired).
- Public key size below recommended thresholds.

---

## GraphQL Introspection Queries

Many services expose a GraphQL endpoint that can be introspected to reveal the full schema.

```bash
TARGET="example.com"
ENDPOINT="https://${TARGET}/graphql"

# Basic introspection query via curl
curl -s -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { types { name fields { name } } } }"}' \
  | jq .
```

**What to look for:**
- List of types, queries, and mutations revealing data models.
- Potential enumeration of private fields or admin‑only queries.
- Endpoints that differ from documented public API paths.

---

## OpenAPI / Swagger Detection

Detect OpenAPI specifications via common URLs or GitHub searches.

```bash
TARGET="example.com"

# Common discovery paths
for path in "/swagger.json" "/swagger.yaml" "/openapi.json" "/openapi.yaml" "/v1/api-docs"; do
  url="https://${TARGET}${path}"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$status" = "200" ]; then
    echo "FOUND: $url"
  fi
done

# GitHub search for OpenAPI specs referencing the domain (run manually or via API)
# Example Google dork: site:github.com "${TARGET}" "openapi" filetype:yaml
```

**What to look for:**
- Full endpoint listings, parameter schemas, and example payloads.
- Authentication flows (API keys, OAuth scopes).
- Versioned API docs (`/v1/openapi.json`).

---

## Configuration File Leakage (env, yaml, json, ini)

Search for exposed configuration files that may contain secrets, database URLs, or internal endpoints.

```bash
TARGET="example.com"

# Common config filenames
for file in .env config.yml settings.json .gitlab-ci.yml .github/workflows/*.yml; do
  url="https://${TARGET}/${file}"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [[ "$status" =~ ^2 ]]; then
    echo "PUBLIC CONFIG: $url"
    # Optionally dump a few lines for manual review
    curl -s "$url" | head -n 20
  fi
done
```

**What to look for:**
- API keys, database connection strings, AWS credentials.
- Internal service URLs (`internal.api.example.com`).
- Feature flags revealing hidden functionality.

---

## SMTP Service Banner Enumeration

Enumerate mail servers and capture SMTP banners to discover software versions and potential open relay.

```bash
TARGET="example.com"

# Resolve MX records
mxhosts=$(dig +short MX ${TARGET} | awk '{print $2}' | tr -d '.')

for host in $mxhosts; do
  echo "--- ${host} ---"
  # Connect to SMTP (port 25) and grab banner
  timeout 5 bash -c "echo -e 'QUIT\r\n' | openssl s_client -starttls smtp -connect ${host}:25 2>/dev/null | head -n 5"

done
```

**What to look for:**
- SMTP software and version (e.g., Postfix 3.5.9).
- Open relay indicators (`220 <host> ESMTP` without authentication).
- Misconfigured TLS settings.

---

## Additional High‑Value OSINT Techniques

- **Certificate Transparency Logs via crt.sh / Censys** – already covered.
- **Search engine dorks for exposed admin panels** – e.g., `inurl:/admin/login`.
- **Public code search for hard‑coded endpoints** – extend GitHub Code Search patterns.
- **Third‑party asset discovery (e.g., Cloudflare Radar, Netcraft)**.

---

## Paste Site Search


Search for leaked credentials on paste sites.

```bash
TARGET="example.com"

# Google dorks (run in browser):
# site:pastebin.com "${TARGET}"
# site:gist.github.com "${TARGET}"
```

**What to look for:**
- Leaked API keys, credentials

**When to use:** Selectively — high noise but high impact.

---

## Bug Bounty Scope Search

Bug bounty program scopes reveal documented attack surface.

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:**
- Documented API endpoints (in‑scope)
- Out‑of‑scope areas

**When to use:** To understand target's documented attack surface.

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints found: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh, DNSDumpster):**
- {subdomain} [{flag: STAGING-ENV / API / ADMIN}]

**Passive DNS (VirusTotal, DNSDB):**
- Historical subdomains: {list}

**Infrastructure (ASN):**
- ASN: {number} — provider: {name}

**Live Capture (urlscan.io):**
- Recent scans: {N}
- Notable findings: {endpoint patterns}

**External References:**
- GitHub: {found/not found}
- Package registries: {NPM/PyPI packages}
- Bug bounty scope: {program URL if found}

**Structured Data:**
- JSON‑LD types found: {list}
- Search endpoint: {url if found}
```

Search NPM/PyPI for official SDKs.

```bash
TARGET="example.com"

# npm: https://www.npmjs.com/search?q=${TARGET}
# PyPI: https://pypi.org/search/?q=${TARGET}
```

**What it reveals:**
- Official SDK structure, auth patterns

**When to use:** For sites with official developer SDKs.

---

## Bug Bounty Scope Search

Bug bounty program scopes reveal documented attack surface.

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:**
- Documented API endpoints (in‑scope)
- Out‑of‑scope areas

**When to use:** To understand target's documented attack surface.

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints found: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh, DNSDumpster):**
- {subdomain} [{flag: STAGING-ENV / API / ADMIN}]

**Passive DNS (VirusTotal, DNSDB):**
- Historical subdomains: {list}

**Infrastructure (ASN):**
- ASN: {number} — provider: {name}

**Live Capture (urlscan.io):**
- Recent scans: {N}
- Notable findings: {endpoint patterns}

**External References:**
- GitHub: {found/not found}
- Package registries: {NPM/PyPI packages}
- Bug bounty scope: {program URL if found}

**Structured Data:**
- JSON‑LD types found: {list}
- Search endpoint: {url if found}
```

Search NPM/PyPI for official SDKs.

```bash
TARGET="example.com"

# npm: https://www.npmjs.com/search?q=${TARGET}
# PyPI: https://pypi.org/search/?q=${TARGET}
```

**What it reveals:**
- Official SDK structure, auth patterns

**When to use:** For sites with official developer SDKs.

---

## Bug Bounty Scope Search

Bug bounty program scopes reveal documented attack surface.

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:**
- Documented API endpoints (in-scope)
- Out-of-scope areas

**When to use:** To understand target's documented attack surface.

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints found: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh, DNSDumpster):**
- {subdomain} [{flag: STAGING-ENV / API / ADMIN}]

**Passive DNS (VirusTotal, DNSDB):**
- Historical subdomains: {list}

**Infrastructure (ASN):**
- ASN: {number} — provider: {name}

**Live Capture (urlscan.io):**
- Recent scans: {N}
- Notable findings: {endpoint patterns}

**External References:**
- GitHub: {found/not found}
- Package registries: {NPM/PyPI packages}
- Bug bounty scope: {program URL if found}

**Structured Data:**
- JSON-LD types found: {list}
- Search endpoint: {url if found}
```
