---
name: site-intel
description: This skill should be used when the user asks questions about a site that has already been analysed with site-recon — "what endpoints does X have?", "how do I query Y?", "what did we find on Z?", "load research for...", "tell me about [site]", "what auth does X use?", "give me the API for...". If a docs/research/ folder exists for the site, use this skill rather than re-analysing. Routes to the right pre-built file without re-running the full analysis.
version: 0.1.0
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
quick API reference, and links to every other file. This gives you context before
diving into a specific file.

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

## Step 4: Answer directly

After reading the relevant file(s):

1. Answer the question — quote specific endpoints, field names, status codes, constraints
2. Include auth requirements for any endpoint mentioned  
3. Cite the source file
4. Keep it concrete: "The endpoint is `GET /wp-json/wp/v2/posts?per_page=10`, returns
   a JSON array of post objects. No auth required. Found in Phase 5 via the WordPress
   tech pack probe checklist."

## When research is incomplete

If the file exists but doesn't answer the question (e.g., a section says
"Phase 11 skipped — no browser available"):

```
The research file notes that [reason]. The {specific data} was not captured.
To get this, re-run /beacon:analyze {url} with a browser tool available,
or manually visit {url} and share what you see.
```

Do not guess or fabricate endpoint details. Only report what the research files contain.
