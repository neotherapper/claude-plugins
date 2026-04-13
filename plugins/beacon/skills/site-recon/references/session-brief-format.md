# Session Brief — Full Schema

The session brief is built up incrementally across all 12 phases. Copy this template
at the start of Phase 1 and append to each section as the run progresses.

```markdown
## Session Brief — {site-slug}

**Target:** {full URL}
**Started:** {ISO timestamp}
**Plugin version:** {semver from .claude-plugin/plugin.json}

---

### Infrastructure

| Property | Value | Evidence |
|----------|-------|---------|
| Framework | unknown | — |
| Framework version | unknown | — |
| Web server | unknown | — |
| CDN | unknown | — |
| Auth mechanism | unknown | — |
| Bot protection | unknown | — |
| Hosting | unknown | — |

*Update each row as phases 2–3 produce signals.*

---

### Tool Availability

*(fill in during Phase 1)*

- Wappalyzer MCP: [AVAILABLE] or [TOOL-UNAVAILABLE:wappalyzer]
- Firecrawl MCP/CLI: [AVAILABLE] or [TOOL-UNAVAILABLE:firecrawl]
- Chrome DevTools MCP: [AVAILABLE] or [TOOL-UNAVAILABLE:chrome-devtools-mcp]
- cmux browser: [AVAILABLE] or [TOOL-UNAVAILABLE:cmux-browser]
- GAU: [AVAILABLE] or [TOOL-UNAVAILABLE:gau]

---

### Tech Pack

*(fill in during Phase 4)*

- Loaded: [LOADED:{framework}:{version}] or [TECH-PACK-UNAVAILABLE:{f}:{v}]
- Source: github / context7 / web-search / inline-generated
- Version match: exact / [TECH-PACK-VERSION-MISMATCH:{f}:{found}→{used}]
- Inline scripts: [GENERATED-INLINE:{path}] (list any)

---

### Phase 2 — Passive Recon

**Subdomains (crt.sh):**
*(list each found subdomain)*

**Passive probes:**
| Probe | Result |
|-------|--------|
| robots.txt | found / not found / {notable disallowed paths} |
| sitemap | {url} / not found / {approx page count} |
| security.txt | found ({contact}) / not found |
| humans.txt | found / not found |
| /.well-known/jwks.json | found (JWT confirmed) / not found |
| /.well-known/openapi.json | found / not found |
| HTTP headers | {notable: Server, X-Powered-By, CF-Ray, etc.} |

---

### Phase 3 — Fingerprint

**Detection result:**
- Framework: {name}
- Version: {version or unknown}
- Evidence: {list signals used}
- Wappalyzer confidence: {N}% / not used

---

### Phase 4 — Tech Pack

**Pack:** {path or UNAVAILABLE}
**Source:** {github/context7/web-search}
**Notes:** {e.g., "14.x used for Next.js 15.x site — version mismatch warned"}

---

### Phase 5 — Known Pattern Probes

*(copy checklist from tech pack Section 9, mark each item)*

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| /example | GET | ✓ 200 | returns paginated list |
| /example | GET | ✗ 403 | auth-gated |
| /example | GET | – 404 | not present |

---

### Phase 6 — Feeds & Structured Data

- RSS feed: {url or not found}
- Atom feed: {url or not found}
- JSON-LD types: {list of @type values found}
- OpenGraph: {notable og:type values}
- GraphQL: {endpoint or not found} | Introspection: open / closed
- API versions active: {list e.g. /api/v1, /api/v2}

---

### Phase 7 — JS Analysis

- Bundles found: {count}
- Source maps available: {count} of {total}
- Notable source paths (from maps): {list file paths recovered}

**Endpoints extracted from bundles:**
*(append each unique path with source bundle)*

---

### Phase 8 — OpenAPI

- Spec: {url if found} or not found
- Source: auto-downloaded / not found (will scaffold in Phase 12)

---

### Phase 9 — OSINT

- Wayback novel paths: {count} new endpoints vs Phase 5
- CommonCrawl novel paths: {count}
- GitHub repos referencing domain: {count}; exposed keys: yes/no
- Dork findings: {summary}

---

### Discovered Endpoints (accumulates across phases)

| Method | Endpoint | Auth | Phase | Notes |
|--------|----------|------|-------|-------|
| GET | /api/v1/example | No | 5 | returns list |

*(append throughout the run)*

---

### Browse Plan

*(written in Phase 10)*

Priority 1 — {reason}
- [ ] {action} {url}
...

---

### Phase 11 — Active Browse

- Tool used: cmux / Chrome DevTools MCP / [PHASE-11-SKIPPED]
- New endpoints found: {count}
- HAR captured: {path or N/A}
- OpenAPI generated from HAR: {path or N/A}

---

### PR Offer

*(if web search fallback used for tech pack)*
- Framework: {name} {version}
- Temporary pack: built from web search during this session
- Status: offered to user at Phase 12 end
```

## Notes on keeping the brief manageable

- The brief lives in context throughout the run — keep individual section entries concise
- Use tables for endpoint lists (more token-efficient than prose)
- Don't duplicate data already in output files — the brief is working memory, not the final doc
- Phase 12 reads the brief once and writes all output files; then the brief can be dropped
