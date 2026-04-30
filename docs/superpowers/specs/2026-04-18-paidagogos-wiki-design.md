# paidagogos:wiki — Course generator from product docs

> Design spec. Status: **draft**, awaiting user review.
> Target: paidagogos `v0.5.0` (additive — no changes to `:micro` behaviour when invoked directly).
> Date: 2026-04-18 · Author: Georgios Pilitsoglou (with Claude Opus 4.7)

---

## 1. Summary

`paidagogos:wiki` is a new sibling skill to `paidagogos:micro`. Given a product name or a docs URL, it ingests the product's published `llms.txt`, curates a 6–12 lesson learning path, and emits one `course` SurfaceSpec (the index) plus one `lesson` SurfaceSpec per curated concept (generated sequentially by `:micro` running in a new **grounded mode**).

Visual-kit gains one new SurfaceSpec type (`course`); `:micro` gains one optional input (`source_page`). Everything else is net-new and isolated to `plugins/paidagogos/skills/paidagogos-wiki/`.

---

## 2. Motivation

`paidagogos:micro` teaches a single concept. The router skill currently treats broad topics ("teach me Turso", "teach me Postgres") as a deferred feature ("learning paths coming in v0.3.0"), and the existing v0.3.0 / v0.4.0 roadmap entries (`:quiz`, `:explain`, `:recall`) do not address them either.

A purely AI-synthesised curriculum for a specific product risks hallucinating features that don't exist or missing key concepts. A docs-grounded course solves both: the curriculum is curated from the product's own published `llms.txt`, and each lesson's concept and code are grounded in the corresponding source page rather than synthesised.

---

## 3. Goals and non-goals

### 3.1 Goals (v1)

- **G-1** New skill `paidagogos:wiki` invokable as `/paidagogos:wiki <name|url>`.
- **G-2** Ingest from `llms.txt` only — no sitemap fallback, no generic crawler.
- **G-3** Curate 6–12 lessons via a single LLM call with a fixed path shape (mental model → quickstart → core concepts → key features → next steps).
- **G-4** Generate lessons sequentially by invoking `:micro` with a new optional `source_page` input. The user can start lesson 1 while later lessons are still generating.
- **G-5** Course index page (`course` SurfaceSpec) renders immediately after curation; lesson cards flip from `generating` to `ready` as files land.
- **G-6** Cache ingested pages on disk for 14 days; `--refresh` forces re-ingest.
- **G-7** Small product registry (5–25 entries) maps friendly names → docs URLs. Anything not in the registry must be invoked by URL.

### 3.2 Non-goals (v1)

- Sites without `llms.txt` (Mintlify, Docusaurus, GitBook *without* a published `llms.txt`).
- Auth-required docs (private GitBook, Notion, Confluence).
- Progress tracking — defer to paidagogos `v0.4.0` `:recall` integration.
- Per-lesson regenerate flag — only whole-course `--refresh`.
- Goal-driven courses ("teach me Turso for serverless edges") — only the default curated path.
- Mid-course re-curation when source docs update — `--refresh` is all-or-nothing.
- Multi-language docs — pick the default English `llms.txt`.
- User-customisable path shape.

---

## 4. Architecture

### 4.1 Components

| Component | What it is | Location |
|---|---|---|
| `paidagogos:wiki` skill | Orchestrator | `plugins/paidagogos/skills/paidagogos-wiki/SKILL.md` |
| Ingest procedure | `llms.txt` fetcher + parser, executed by Claude via Bash/Read | `plugins/paidagogos/skills/paidagogos-wiki/references/ingest.md` |
| Curation procedure | Single-LLM-call prompt scaffold | `plugins/paidagogos/skills/paidagogos-wiki/references/curation.md` |
| Product registry | Name → URL lookup | `plugins/paidagogos/skills/paidagogos-wiki/references/registry.json` |
| Course schema | Registered with visual-kit | `vk://schemas/course.v1.json` |
| Course renderer | New visual-kit component | `visual-kit` repo |
| Grounded `:micro` mode | Existing skill, additive change | `plugins/paidagogos/skills/paidagogos-micro/SKILL.md` |

### 4.2 Two integration points with existing code

- **`paidagogos:micro`** gets one new optional input (`source_page`). Additive; existing direct invocations unchanged.
- **`visual-kit`** gets one new SurfaceSpec type (`course`). The `lesson` surface is unchanged.

---

## 5. File layout

Per-invocation files written to the workspace:

```
<workspace>/.paidagogos/
├── wiki-cache/
│   └── <slug>/                       ← per-source ingested cache
│       ├── manifest.json
│       └── pages/
│           ├── 0001-introduction.md  ← one file per ingested page
│           └── ...
└── content/                          ← visual-kit watches this dir
    ├── <slug>-course.json            ← course SurfaceSpec (index)
    ├── <slug>-01-introduction.json   ← lesson SurfaceSpec
    └── ...
```

**Slug convention:** derived from the URL host with leading `docs.` and `www.` stripped (`docs.turso.tech` → `turso`, `neon.tech` → `neon`). Cached page filenames prefixed with a 4-digit sequential number reflecting `llms.txt` order (`0001-introduction.md`, `0002-quickstart.md`, ...). Lesson files prefixed `<slug>-NN-<concept-slug>` where `NN` is the curated lesson order, not the cached page number.

**Separation rationale:** `wiki-cache/` holds the (expensive) ingest; `content/` holds rendered surfaces. Wiping `content/` re-renders without re-ingesting.

---

## 6. Data flow

1. **Resolve.** Name or URL → canonical source URL + slug. Registry lookup first; URL accepted directly.
2. **Cache check.** If `wiki-cache/<slug>/manifest.json` exists and `ingested_at` < 14 days old, skip ingestion. `--refresh` overrides.
3. **Pre-flight.** Verify visual-kit is running (read `<workspace>/.visual-kit/server/state/server-info`). Halt if not.
4. **Ingest.** `GET <source>/llms.txt`. Parse the spec'd format. For each linked page: `GET` the page, store as markdown in `pages/`. Write `manifest.json`.
5. **Curate.** Single LLM call (see §8). Output: ordered list of 6–12 page IDs with rationale + a one-sentence course summary.
6. **Write course index.** Emit `<slug>-course.json` with all curated lessons listed at `status: "generating"`.
7. **Generate lessons sequentially.** For each curated page in order, invoke `:micro` with `source_page=<absolute path to cached page>` and `level=intermediate`. After each lesson file is written, update the course JSON to flip that lesson's `status` to `"ready"`.
8. **Final response.** Chat output: `Course ready: <Product> (<N> lessons). Open http://localhost:{port}. Estimated total: <minutes> min.`

---

## 7. Schemas

### 7.1 Product registry — `references/registry.json`

```json
{
  "turso":     { "url": "https://docs.turso.tech",        "llms_txt": "/llms.txt" },
  "neon":      { "url": "https://neon.tech/docs",         "llms_txt": "/llms.txt" },
  "supabase":  { "url": "https://supabase.com/docs",      "llms_txt": "/llms.txt" },
  "vercel":    { "url": "https://vercel.com/docs",        "llms_txt": "/llms.txt" },
  "prisma":    { "url": "https://www.prisma.io/docs",     "llms_txt": "/llms.txt" }
}
```

`llms_txt` is overridable because not every site puts it at root.

### 7.2 Cache manifest — `wiki-cache/<slug>/manifest.json`

```json
{
  "source_url": "https://docs.turso.tech",
  "slug": "turso",
  "ingested_at": "2026-04-18T14:32:00Z",
  "llms_txt_url": "https://docs.turso.tech/llms.txt",
  "pages": [
    {
      "id": "0001-introduction",
      "title": "Introduction",
      "source_url": "https://docs.turso.tech/introduction",
      "path": "pages/0001-introduction.md"
    }
  ],
  "failed_pages": []
}
```

### 7.3 Course SurfaceSpec — `vk://schemas/course.v1.json`

```json
{
  "surface": "course",
  "version": 1,
  "source": {
    "name": "Turso",
    "url": "https://docs.turso.tech",
    "ingested_at": "2026-04-18T14:32:00Z"
  },
  "title": "Turso — A guided course",
  "summary": "Learn Turso from intro through your first deployment and core features.",
  "estimated_total_minutes": 95,
  "level": "intermediate",
  "lessons": [
    {
      "order": 1,
      "slug": "turso-01-introduction",
      "title": "What Turso is and why it exists",
      "rationale": "Mental model before mechanics.",
      "estimated_minutes": 8,
      "status": "ready"
    }
  ],
  "caveat": "Course curated by AI from official docs. Lesson content grounded in source pages."
}
```

`status` ∈ `"generating" | "ready" | "failed"`.

### 7.4 Grounded `:micro` input

Additive to existing `:micro`:

```
source_page (optional): absolute path to a markdown file on disk
```

When `source_page` is set, `:micro`:

- Reads the markdown file.
- Uses its content verbatim or near-verbatim for the `concept`, `why`, and `code` sections instead of synthesising.
- Prepends a `resources[]` entry: `{ type: "docs", url: <original page URL>, label: "Source" }`.
- Still synthesises `mistakes`, `quiz`, `generate`, `next`.
- Sets `caveat` to `"Grounded in <source name> docs. Mistakes, quiz, and practice task AI-generated."`

When `source_page` is unset, `:micro` behaves exactly as today.

---

## 8. Curation algorithm

A single LLM call after ingestion. Inputs: page list (titles + first paragraph + URL of each). Output: ordered subset of 6–12 pages.

**Prompt scaffold:**

```
You are designing a learning path for {product_name}.
The user is an intermediate developer who has never used this product.

Goal: a coherent course of 6–12 lessons that takes them from
"never heard of it" to "can build something real with it."

Path shape (in order):
  1. Mental model / what is this and why does it exist  (1 lesson)
  2. Quickstart / first hands-on success                (1 lesson)
  3. Core concepts (the 3-5 things you must understand) (3-5 lessons)
  4. Key features the user will reach for first         (1-3 lessons)
  5. Where to go next (deployment, advanced, ecosystem) (1 lesson)

Avoid:
  - Reference pages (API listings, error code tables) — these aren't lessons
  - Marketing pages (pricing, comparisons) — not learning content
  - Per-language SDK pages unless the product is SDK-defined
  - Migration guides (off-topic for first-time learners)

Available pages:
{page list with titles + first paragraph}

Return JSON:
{
  "lessons": [
    { "page_id": "...", "title": "...", "rationale": "one line why this lesson, here, in this order" }
  ],
  "summary": "one sentence describing what the course covers"
}
```

**Validation:**

- 6 ≤ `lessons.length` ≤ 12 — else halt with curation error.
- Every `page_id` exists in the manifest — else halt.
- No duplicates — else halt.

No retries; halt cleanly on first validation failure.

---

## 9. Course visual surface

What visual-kit's new course renderer must produce, top-to-bottom:

1. **Header.** Title (h1), summary, meta line (`<N> lessons · ~<M> min · <level>`), provenance (`Source: <host> · ingested <date>`).
2. **Lesson list.** One card per lesson. Card shows: order number, title, rationale, estimated minutes.
3. **Card states.**
   - `ready` — clickable; links to `/render?slug=<lesson-slug>` (existing lesson surface URL).
   - `generating` — disabled card with spinner, title shows `<title> — generating…`.
   - `failed` — disabled card with error icon and message.
4. **Footer.** `caveat` text.
5. **Live updates.** Page subscribes to visual-kit's existing SSE stream and re-renders on course JSON updates.

No new visual-kit features required beyond the schema registration and the renderer component itself.

---

## 10. Error handling

| Failure | Where | User message | Action |
|---|---|---|---|
| Name not in registry, no URL provided | Resolve | `Don't know <name>. Try /paidagogos:wiki <url>, or pick a known product: <comma-separated list of registry keys>.` | Halt. |
| `llms.txt` returns 404 | Ingest | `<source> doesn't publish an llms.txt. v1 only supports docs sites with llms.txt. File an issue with the source URL if you'd like it added.` | Halt. No partial cache written. |
| `llms.txt` parse fails | Ingest | Same as 404. | Halt. |
| Individual page fetch fails (404, 5xx) | Ingest | *(no message)* | Skip page, log to `failed_pages[]`, continue. If >50% of pages fail, halt with `Source unreachable — too many fetch failures.` |
| Curation invalid (count out of range, unknown ID, duplicate) | Curate | `Could not generate a course outline for this source. The docs may be too sparse or too sprawling.` | Halt. |
| `:micro` lesson generation fails for one lesson | Generate | *(per-card error in browser; chat continues)* | Mark lesson `status: "failed"`, continue with next lesson. Course completes with stub for that one. User re-runs whole course on `--refresh`. |
| visual-kit not running | Pre-flight | `visual-kit is not running. Run \`visual-kit serve --project-dir .\` to start it.` | Halt before ingest. |
| Cache disk write fails | Ingest / Generate | `Could not write to <path>. Check disk space and permissions.` | Halt. |

Pre-flight runs before any network call: visual-kit running, workspace dir writable, source resolved.

---

## 11. Open questions

None for v1. All decisions captured above are settled.

### 11.1 Future enhancements (v2+)

- **Sitemap → generic crawl fallback chain.** Cover docs sites without `llms.txt`.
- **Auth-required docs.** Private GitBook API tokens, Notion integrations, internal Confluence.
- **Progress integration with `:recall`.** Lock unfinished lessons until prereqs are complete (depends on paidagogos `v0.4.0`).
- **Goal-driven curation.** "Teach me X for Y use case" — narrows the curated path to pages relevant to a stated goal.
- **Per-lesson regenerate flag.** Re-run a single lesson without re-curating the whole course.

### 11.2 Roadmap-style navigation (v2+) — non-linear courses

Inspired by [roadmap.sh](https://roadmap.sh)'s tree-of-tracks UX. Replace the linear lesson list with a directed acyclic graph: foundations → parallel specialisation tracks → convergence points → advanced.

**Schema impact** — additive, non-breaking on v1:

- New `course.v2` schema with optional `prerequisites: string[]` and `track: string` per lesson.
- v1 courses (no `prerequisites`, no `track`) render as today.
- v2 courses with these fields render as a graph.

**Curation impact:** the curation prompt outputs a DAG instead of an ordered list. The path-shape constraint changes from a fixed sequence to a layered graph (Foundations layer → Specialisation tracks → Synthesis).

**Visual-kit impact:** new course-graph renderer. Nodes clickable as today; edges show prerequisite relationships; tracks are visually grouped (columns or coloured swimlanes). A "recommended path" can be highlighted while still allowing free navigation.

**Why this stays out of v1:** the linear list is the simplest UX that proves the ingest → curate → ground → render pipeline works end-to-end. Graph rendering and DAG-shaped curation are meaningful chunks of work that should land on top of a working linear baseline, not as part of the first release.
