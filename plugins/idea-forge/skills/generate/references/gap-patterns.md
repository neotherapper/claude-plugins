# Gap Patterns — Reference File

This file is read by generator.md during Stage 1 (generation). Apply all applicable patterns to the corpus as an explicit checklist, working through them in order.

---

## Pre-Flight Check

Before applying patterns, note which data layers are present:

| Corpus state | Patterns to run |
|---|---|
| Scored cards present | All 5 patterns viable |
| Mixed (some evaluated, some brainstorm) | All 5 patterns — scored cards for evidence-heavy patterns, frontmatter as weaker signal |
| Frontmatter only (brainstorm ideas, no scored cards) | Patterns 1, 4, 5 — Patterns 4 and 5 must mark evidence as "(inferred from general knowledge)" since community/incumbent data is not in frontmatter; skip Patterns 2 and 3 (they require customer voice and timing data not present in frontmatter) |
| Description only (no vault match) | Patterns 1, 4, 5 — all evidence marked "(inferred)". Skip Patterns 2 and 3 (no customer voice or timing data available). Note clearly on each candidate. |

---

## The 5 Gap Patterns

| # | Pattern | Signal to detect in corpus |
|---|---|---|
| 1 | **Demand without supply** | Strong search volume / pain signals, but competition shows no dominant or adequate solution |
| 2 | **Customer friction** | Customer voice shows manual workarounds OR segments existing solutions actively exclude |
| 3 | **Technology / regulatory wave** | A cost curve crossed, infrastructure became available, or regulation just changed — making something newly buildable |
| 4 | **Unoccupied distribution** | Active community, channel, or platform where the audience is assembled but no dedicated product exists |
| 5 | **Incumbent blindness** | A large player could serve this segment but doesn't — too small, wrong geography, wrong language, wrong culture |

---

## Candidate Format

Each pattern match produces one candidate. Every candidate **must have a real EVIDENCE field** — no hallucinated gaps. Cite the source file and section: `[from scored-card-v3.md § Competition]`. For inferred evidence (description-only or general knowledge), write `(inferred)` at the end.

```
CANDIDATE: [short name]
PATTERN: [1-5]
EVIDENCE: [specific data point — quote or stat, with source citation or "(inferred)"]
CUSTOMER: [one specific person, not a category]
GAP: [one sentence — what's missing right now]
```

**Evidence verification:** After drafting all candidates, re-read each EVIDENCE citation and confirm the underlying data point actually appears in the cited file section. Paraphrasing is fine — the data point does not need to be word-for-word; but if the cited section does not contain the underlying fact at all, replace the citation with `(inferred)` rather than presenting it as sourced. An inferred candidate is acceptable; a fabricated citation is not.

**Target:** up to 14 candidates total — fewer is fine if evidence is sparse. Do not force candidates to reach a count; a hallucinated EVIDENCE field is worse than a short list. If a pattern produces no evidence from the corpus, skip it and move to the next.

---

## Killed Ideas as Evidence

If a matched idea has `verdict: KILL` in master-index.yaml, treat it as Pattern 1 evidence: the demand existed but the specific approach failed. Load the idea's scored card, note what failed and why (from the verdict reasoning), and use that to shape a different angle on the same demand.

Example: if a "Freelancer Directory for Designers" was killed because supply was too thin, a Pattern 1 candidate might be "Freelancer Directory for Vetted Product Designers (curated supply-first)" — same demand, different angle.

---
