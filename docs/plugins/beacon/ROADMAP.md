# Beacon — Roadmap

Planned features and capabilities in priority order. Each version ships as a complete, tested unit.

---

## v0.6.0 — site-intel: Tech Pack Cross-Referencing

**Goal:** When the user asks a *how-do-I* or framework-specific question, site-intel loads the relevant tech pack alongside the research file — so answers draw on both what was discovered *and* framework conventions.

**What changes:**
- New Step 3a in site-intel SKILL.md: detect framework from INDEX.md/tech-stack.md, load `technologies/{framework}/{major}.x.md` when question involves query patterns, endpoint conventions, or framework APIs
- Clear trigger heuristics: "how do I", "query", "pagination", "auth flow", "what's the pattern for" → load tech pack
- Factual questions ("what endpoints exist?", "what CDN?") → research files only, no tech pack needed
- validate-site-intel.sh test (12 checks, TDD)

---

## v0.7.0 — Query Proof Scripts

**Goal:** Give site-intel the ability to optionally generate and run simple data-fetching scripts that prove discovered endpoints return real, useful data — showing the user the actual output, not just the status code.

**What changes:**
- Framework-specific query templates added to each tech pack (5–10 line curl/Python snippets)
- site-intel new Step 5: when user asks "show me what this returns" or "give me a sample", generate a minimal fetch script using the template and run it inline
- New output file type: `scripts/query-{surface}-{site}.sh` — one file per API surface, generated on demand (not auto-generated during Phase 12)
- Templates cover: pagination, listing resources, introspection (GraphQL), schema inspection (OpenAPI, Strapi), authenticated fetch

**Example output:**
```bash
# query-wp-rest-example-com.sh — WordPress REST API proof-of-life
curl -s "https://example.com/wp-json/wp/v2/posts?per_page=3" \
  | python3 -c "import sys,json; [print(p['id'], p['slug']) for p in json.load(sys.stdin)]"
```

---

## v0.8.0 — Research Freshness Signals

**Goal:** surface when research is stale and give the user a clear re-run path.

**What changes:**
- INDEX.md gains an `Analysed:` date field (already templated, but not used by site-intel)
- site-intel Step 2 checks the date; if research is older than 30 days, prepends a freshness warning to every answer
- New signal: `[RESEARCH-STALE:{days}d]` — logged in site-intel responses, not in INDEX.md
- Optional: suggest which phases to re-run for freshness (e.g., Phase 3 for framework version, Phase 8 for OpenAPI)

---

## v0.9.0 — Additional Tech Packs

**Goal:** expand framework coverage beyond the current 12 packs.

**Candidates (in priority order):**
1. Remix / React Router v7 (file-based routing, loader/action pattern)
2. SvelteKit (file routes, `+page.server.ts` endpoints, form actions)
3. Express (no conventions, OSINT-heavy; generic probe checklist)
4. Spring Boot (Actuator endpoints, Spring Data REST, OpenAPI auto-generation)
5. Payload CMS (REST + GraphQL, version-specific admin paths)
6. Directus (REST + GraphQL, `/items/{collection}` pattern, system collections)

Each new pack triggers a failing check in `validate-fingerprinting.sh` automatically (self-healing coverage loop).

---

## v0.10.0 — Multi-Site Comparison

**Goal:** answer questions that span two research folders — "how does X differ from Y?", "which site has a public GraphQL API?", "compare the auth flows".

**What changes:**
- site-intel gains a multi-site mode: when the user references two sites, finds both research folders and loads INDEX.md for each before routing
- New routing table entries for comparative questions
- No new output files; operates on existing research

---

## v0.11.0 — Export Formats

**Goal:** convert the OpenAPI spec discovered during analysis into formats that are immediately usable in other tools.

**What changes:**
- New command `/beacon:export {site} {format}` — runs post-processing on `specs/{site}.openapi.yaml`
- Formats: Postman collection (via `openapi-to-postman`), Bruno collection, Insomnia workspace
- Falls back to manual scaffolding if spec is partial
- Output: `docs/research/{site}/exports/{format}/`
