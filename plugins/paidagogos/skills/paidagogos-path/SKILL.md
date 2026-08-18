---
name: paidagogos-path
description: >
  Use when the user wants a whole learning path rather than one lesson — "I want
  to become an AI engineer", "give me a roadmap for X", "show me the curriculum",
  "what should I learn next", "show the learning tree", "/paidagogos:path". Also
  use when the user asks what a curriculum covers, which concepts feed which, or
  what resources exist for a topic already in a curriculum. Renders a curriculum
  as an interactive tree in the browser and routes individual concepts to
  paidagogos:micro for teaching.
license: MIT
metadata:
  version: "0.3.0"
  author: Georgios Pilitsoglou
---

# paidagogos:path — Curriculum paths

Loads a curriculum catalogue, renders it as an interactive tree, and hands
individual concepts to `paidagogos:micro` when the user wants to actually learn one.

A curriculum is **data**, not prose. Never author a learning path inline in the
conversation — write or load a curriculum file and render it.

## Available curricula

Do not keep a list here. Run:

```bash
node plugins/paidagogos/scripts/build-index.mjs
```

It prints a `gallery` SurfaceSpec built from `plugins/paidagogos/packs/*/pack.json`.
Every pack that exists is in that output; anything not in it does not exist.
A list written into this file would be a second source of truth that drifts
from the first one silently.

## Phase sequence

Do not reorder these.

### Phase 1 — Identify the curriculum

Match the user's request to a curriculum by running
`node plugins/paidagogos/scripts/build-index.mjs` and reading the gallery output.
If nothing matches, say so and offer either `paidagogos:micro` for a single
concept or to author a new curriculum (Phase 6). Never silently substitute a
neighbouring curriculum.

### Phase 2 — Show the index when the request is not about one subject

If the user asked what curricula exist, or asked for "the roadmaps", stage the
index instead of a single curriculum:

```bash
node plugins/paidagogos/scripts/build-index.mjs --out .paidagogos/content/roadmaps.json
```

Give them `http://localhost:<port>/p/paidagogos/roadmaps`. Each card links
straight to its curriculum. If the script exits non-zero, report its stderr
verbatim and stop — a manifest is broken, and rendering a partial index would
present a missing curriculum as one that does not exist.

If the user named a subject, skip this phase.

### Phase 3 — Start the renderer

Run `visual-kit serve --project-dir .` with `run_in_background: true`. Poll
`.visual-kit/server/state/server-info` until `status` is `"running"`, then read
the `port`. Do **not** ask the user to start it.

If `visual-kit` is not on PATH, fall back to Phase 5 and report the tree in text.

### Phase 4 — Stage and open

Copy the curriculum JSON to `.paidagogos/content/<surface-id>.json`, where
`<surface-id>` matches `^[a-zA-Z0-9_-]+$` — the server rejects anything else, so
strip dots from the filename.

Give the user the URL: `http://localhost:<port>/p/paidagogos/<surface-id>`

State what they can do with it: click any node for the concept detail and its
resources, and switch study sequence if the curriculum defines more than one.

### Phase 5 — Orient, don't dump

Summarise in **at most 10 lines**: the tracks, the recommended first concept, and
why that one is first. The tree carries the detail — repeating it in chat defeats
the point of rendering it.

If the curriculum defines `orderings`, name which is default and what the
alternative optimises for.

### Phase 6 — Route to teaching

When the user picks a concept, invoke `paidagogos:micro` with:

- `topic` = the node's `label`
- `level` = the level in the node's `badges`, if present
- Seed context = the node's `detail.summary` and `detail.body`

If the node has `requires`, check whether the user has covered those first. Say so
once; do not refuse to teach.

## Authoring a new curriculum

Curricula are `tree` SurfaceSpecs validated against
`plugins/visual-kit/schemas/surfaces/tree.v1.json`. Read that schema before
authoring — it is the contract, and the server rejects anything that fails it.

Conventions this plugin adds on top of the schema:

| Convention | Rule |
|---|---|
| Concept ids | Kebab-case, prefixed with the track letter: `c-entailment-checking` |
| Track ids | Single letters where the curriculum has stable tracks |
| `kind` | `branch` for tracks, `leaf` for teachable concepts |
| `badges` | Estimated time first, then level: `["45 min", "beginner"]` |
| `detail.meta` | Domain fields the tree surface does not model — axis, exam weight, build-to-prove-it |
| `requires` | Real prerequisites only, including cross-track ones. This is what makes it a DAG rather than a list. |
| `orderings` | One per defensible study sequence. Mark one `default`. |
| Pack manifest | Every curriculum needs `packs/<slug>/pack.json` validated against `plugins/paidagogos/schemas/pack.v1.json`. Without it the curriculum is invisible to the index. |

### Sourcing rules for resources

A curriculum that cites a certification is making a factual claim about a third
party. The schema enforces the minimum — any resource with a `certification` field
must carry both `url` and `verified_at` — but the discipline is yours:

1. Read the figure off the **vendor's own page or exam guide**. Never a study-guide
   site; several publish invented blueprints, and one matching the official
   weights once is not evidence the next will.
2. Cite the durable landing page as `url`. If you read a generated PDF, put it in
   `artifact_url` — those links rotate.
3. Set `verified_at` to the date **you** checked it, not the date someone told you.
4. If you are relaying a figure you did not verify yourself, set `provenance` and
   explain in `note`. Do not launder second-hand facts into first-hand ones.

Set `provenance` on every resource — `primary` (you read the publisher's own
page), `secondary` (summarised from someone else's write-up), `relayed` (taken
from another party's extraction unchecked). The three verification fields are
orthogonal and none substitutes for another:

| Field | Answers |
|---|---|
| `verified_at` | When did someone last look? |
| `lifecycle` | Does it still exist in the form described? |
| `provenance` | Is this first-hand, or am I repeating someone? |

**Dropping the URL is not the cautious option.** A precise figure with no source
is unfalsifiable while the precision still reads as verification — that is worse
than a source with no figure. If you cannot cite it, mark it `secondary` and say
what it came from.

Check retirement status before recommending any certification. Search results
routinely present retired exams as current.

### Validate before rendering

```bash
node -e "
import('ajv/dist/2020.js').then(async ({default:A})=>{
  const fs=await import('node:fs/promises');
  const ajv=new A({strict:false,allErrors:true});
  (await import('ajv-formats')).default(ajv);
  const v=ajv.compile(JSON.parse(await fs.readFile('plugins/visual-kit/schemas/surfaces/tree.v1.json','utf8')));
  const ok=v(JSON.parse(await fs.readFile(process.argv[1],'utf8')));
  console.log(ok?'VALID':v.errors);
});" <curriculum.json>
```

The schema cannot express four things you must check by hand: ids are unique,
every `requires` target exists, every `orderings.sequence` entry exists, and every
`group` referenced by a node is declared.

## Out of scope

Lesson generation belongs to `paidagogos:micro`. Rendering belongs to `visual-kit`.
Progress tracking is not modelled — curricula are content, and any progress overlay
is a separate file so the curriculum stays reusable by other learners.
