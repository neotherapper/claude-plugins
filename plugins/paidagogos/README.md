# paidagogos

Structured AI-powered lessons and curriculum roadmaps for any topic, rendered in a local browser UI.

## Install

```
/plugin marketplace add neotherapper/claude-plugins
/plugin install paidagogos@neotherapper-plugins
```

## Usage

### Starting the visual server

Before running lessons, start visual-kit (per workspace):

```bash
visual-kit serve --project-dir .
```

The port is derived from the workspace path, so it differs per project — use the
URL printed in the output rather than a fixed one.

### Learning one thing

```
/paidagogos CSS flexbox
/paidagogos how async/await works
/paidagogos:micro "the event loop" --level beginner
```

### Learning a whole subject

```
/paidagogos:path                      # the roadmap index — every curriculum available
/paidagogos:path AI engineering       # one curriculum, rendered as a roadmap
"I want to become an AI engineer"
```

A curriculum renders as a roadmap spine: tracks sit on a central line, concepts
branch off it, and clicking any concept opens its detail — why it matters, the
techniques, common pitfalls, and sourced resources. Pick one and it hands off to
`paidagogos:micro` to actually teach it.

## What a lesson gives you

- **Concept** — clear, jargon-minimal explanation
- **Why it matters** — real-world motivation
- **Example** — syntax-highlighted code
- **Common mistakes** — pre-empts wrong mental models
- **Generate task** — a production challenge to try
- **Quiz** — 3 questions, scored with explanations

## Curriculum packs

A curriculum is a directory under `packs/<slug>/` holding a `pack.json` manifest
and its surface specs. Discovery is a filesystem glob, so a new subject appears
in the index by existing — no skill edit, no registry to update.

```
packs/
  ai-engineering/
    pack.json          # manifest: title, badges, surfaces[]
    curriculum.json    # the roadmap itself (a `tree` SurfaceSpec)
    catalogue.json     # external courses, by institution
```

To add one, write the manifest against `schemas/pack.v1.json` and the curriculum
against visual-kit's `tree.v1.json`, then run:

```bash
node plugins/paidagogos/scripts/build-index.mjs --out .paidagogos/content/roadmaps.json
```

The generator fails closed: one invalid manifest aborts the whole index rather
than emitting a directory with a silent hole in it.

### Shipped packs

| Pack | Covers | Format |
|---|---|---|
| AI Engineering | 38 concepts across 5 tracks, CCAR-F front-loaded, plus a course catalogue | `tree` |
| Developer SEO Mastery | 12 lessons, strictly linear | markdown — archive only, not rendered |

## Expertise levels

`beginner` · `intermediate` (default) · `advanced`

Set inline: `"teach me flexbox, I'm a beginner"`, or on first use when prompted.

## Sourcing

Curriculum resources carry three independent fields, because none substitutes
for another:

| Field | Answers |
|---|---|
| `verified_at` | When did someone last look? |
| `lifecycle` | Does it still exist in the form described? |
| `provenance` | Is this first-hand, or am I repeating someone? |

A resource claiming a certification must carry both a URL and a verification
date or the spec fails validation.

## Versions

| Version | Shipped |
|---------|---------|
| 0.1.0 | `paidagogos` router + `paidagogos:micro` + in-house visual server |
| 0.2.0 | Migrated to visual-kit; lesson SurfaceSpec v1; dropped in-house server |
| 0.3.0 | `paidagogos:path` + AI Engineering curriculum + course catalogue |
| 0.4.0 | Curriculum packs + generated roadmap index |
