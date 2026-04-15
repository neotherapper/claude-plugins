---
name: site-intel
description: This skill should be used when the user asks questions about a site that has already been analysed with site-recon — "what endpoints does X have?", "how do I query Y?", "what did we find on Z?", "load research for...", "tell me about [site]", "what auth does X use?", "give me the API for...". If a docs/research/ folder exists for the site, use this skill rather than re-analysing. Routes to the right pre-built file without re-running the full analysis.
version: 0.6.0
---

# site-intel — Router Mode

Answer questions about a previously-analysed site by routing to the correct
pre-built research file. Read the file, then answer directly — do not re-analyse.

## Step 1: Find the research folder

```bash
ls docs/research/ | grep -i "{keyword-from-question}"
```

If no folder matches → tell the user to run `/beacon:analyze {url}` first:
```
No research found for {site}. Run /beacon:analyze {url} to analyse it first.
```

If multiple folders could match → list them and ask which one:
```
Multiple researched sites found:
- docs/research/example-com/ (see INDEX.md for analysis date)
- docs/research/example-api-com/

Which site are you asking about?
```

## Step 2: Open INDEX.md first

Always read `docs/research/{site}/INDEX.md` first — it has the infrastructure summary,
quick API reference, and links to every other file. This gives you the framework name
and version before routing.

## Step 3: Route to the specific file

| Question type | File to open |
|--------------|-------------|
| Tech stack, framework, hosting, CDN, bot protection | `tech-stack.md` |
| Available pages, URL patterns, site structure | `site-map.md` |
| Category IDs, taxonomy values, enums, nonces, public config | `constants.md` |
| A specific API endpoint (REST, GraphQL, AJAX) | `api-surfaces/{surface}.md` |
| Full endpoint list, OpenAPI spec | `specs/{site}.openapi.yaml` |
| How to query / test the site | `scripts/test-{site}.sh` |
| General overview, key findings | `INDEX.md` (already open) |

If the question spans multiple surfaces, open all relevant files before answering.

## Step 3a: Cross-reference the tech pack for framework-specific questions

After opening the research file, check whether the question is **framework-specific**:

**Load the tech pack when the question involves:**
- Query patterns, pagination, filtering ("how do I get all posts?", "how do I paginate?")
- Endpoint conventions specific to the framework ("what are the REST routes?")
- Authentication flows tied to the framework ("how does Laravel handle CSRF?")
- Framework-specific admin, dashboard, or config paths
- Anything phrased as "how do I" or "what's the pattern for" a specific framework feature — where the framework name or a framework-specific term (e.g., "WooCommerce", "Blade", "Eloquent") appears in the question

**Do not load the tech pack for factual questions:**
- "What endpoints did we find?" → research file is the source of truth
- "What CDN does this site use?" → tech-stack.md only
- "Show me the site map" → site-map.md only

**How to load:**
1. Read the framework name and major version from INDEX.md infrastructure table (e.g., `WordPress 6.5` → `wordpress`, `6.x`)
2. Load: `technologies/{framework}/{major}.x.md`
   - If version is missing or partial, use the nearest available major and note it in your response (e.g., "Using WordPress 6.x pack — site is on 6.5")
   - If no tech pack exists for the detected framework, proceed with research files only and note it once in your answer: "No tech pack available for {framework} — answer based on research files only"
3. Use the tech pack's probe checklist and known endpoint patterns to **supplement** what the research files contain — never contradict confirmed research findings with tech pack assumptions

**Example:**
> User: "How do I query products in WooCommerce?"
>
> Load: `docs/research/example-com/api-surfaces/woocommerce.md` (from Step 3)
> Also load: `technologies/wordpress/6.x.md` (from Step 3a — framework-specific query question)
> Answer: combine what was discovered in the API surface file with the WooCommerce REST API conventions from the tech pack

## Step 4: Answer directly

After reading the relevant file(s):

1. Answer the question — quote specific endpoints, field names, status codes, constraints
2. Include auth requirements for any endpoint mentioned
3. Cite the source file(s) — distinguish between "found in research (Phase 5)" and "from WordPress tech pack (not confirmed in this site's research)"
4. Keep it concrete: "The endpoint is `GET /wp-json/wp/v2/posts?per_page=10`, returns
   a JSON array of post objects. No auth required. Found in Phase 5 via the WordPress
   tech pack probe checklist."

**When combining research + tech pack:** clearly label which facts are confirmed (from research) and which are conventional (from tech pack). Do not present tech pack conventions as confirmed discoveries.

## When research is incomplete

If the file exists but doesn't answer the question (e.g., a section says
"Phase 11 skipped — no browser available"):

```
The research file notes that [reason]. The {specific data} was not captured.
To get this, re-run /beacon:analyze {url} with a browser tool available,
or manually visit {url} and share what you see.
```

Do not guess or fabricate endpoint details. Only report what the research files contain.
If the tech pack suggests an endpoint conventionally exists but the research didn't confirm it,
say so explicitly: "The WordPress tech pack suggests `GET /wp-json/wc/v3/products` exists,
but this was not confirmed in the Phase 5 probes for this site."
