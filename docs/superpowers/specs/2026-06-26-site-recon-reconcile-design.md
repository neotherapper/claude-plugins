# site-recon SKILL.md — reconcile + word-budget offload

- **Date:** 2026-06-26
- **Status:** approved (design); pending implementation plan
- **Branch:** `refactor/site-recon-restructure`
- **Scope owner:** beacon plugin / `plugins/beacon/skills/site-recon/SKILL.md`

## Context

`site-recon` is beacon's core 16-phase investigation skill. A `plugin-dev:skill-reviewer`
sweep flagged it as ~3× the SKILL.md word budget (964 lines / ~6,333 words; ceiling ~5,000)
with phases "pasted 2–3 times." Closer reading shows the duplication is not clean copies — it
is a **scrambled three-way merge** of the `Phase 1 → 2.5` region. PR #30 already applied
surgical fixes (null-safe `find`, `${CLAUDE_PLUGIN_ROOT}` paths); this work does the structural
reconcile that was deliberately deferred from that PR.

## Root cause

The interleaving was introduced by a mis-resolved merge, most likely around `3d77d4d`
(PR #27, "migrate output to docs/sites/{slug}/research/", +59 lines on this file). The output-path
migration's three-way merge duplicated the `Phase 1.5 / 2 / 2.5` sections and pushed Phase 1's
scaffold content below Phase 2.5. This is a **reconcile**, not a delete-the-duplicate.

## Current-state fragment map (lines refer to `main` @ 132ff63)

| Fragment | Location(s) | Status |
|---|---|---|
| `## Phase 1` header + domain-discovery intro only | 99–135 | Phase 1 body is **missing** (scattered below) |
| Phase 1.5 inline bash | 101–125 **and** 239–263 | byte-identical duplicate |
| Phase 1.5 structured section (Input/Actions/Output) | 137–152 **and** 310–325 | byte-identical duplicate |
| `## Phase 2` header | 156 **and** 329 | dup; **copy 2 (329) uniquely adds** the `references/phase-detail.md` pointer (331) |
| Phase 2.5 inline bash | 160–198 **and** 335–373 | **DIVERGED** — see below |
| Phase 2.5 structured section | 210–227 **and** 385–402 | byte-identical duplicate |
| **Canonical slug rule** bash (slug + mkdir + legacy check) | **229–237 only** | single copy, **misplaced** under Phase 2.5; belongs in Phase 1; **CI-gated** |
| **"Write files directly, don't `touch`"** + empty-file Writes | **275–283 only** | single copy, belongs in Phase 1 |
| **Tool-availability + AI-crawler order + Jina note** | **285–296 only** | single copy, belongs in Phase 1 |
| **Chrome MCP namespace** detection note | **298–302 only** | single copy, belongs in Phase 1 |
| **gau alias check** | **304–306 only** | single copy, belongs in Phase 1 |

### Diverged block — which copy wins

The Phase 2.5 "previous scan results" `find` differs between copies:

- Copy 1 (188–190): `find ... 2>/dev/null; } | while IFS= read -r research` — **null-unsafe**.
- Copy 2 (363–365): `find ... -print0 2>/dev/null; } | while IFS= read -r -d '' research` — **null-safe**.

**Resolution: keep copy 2 (null-safe).** Likewise keep Phase 2 copy 2 (carries the
`phase-detail.md` pointer).

## Goals

1. One clean, correctly-ordered copy of each phase: `Phase 1 → 1.5 → 2 → 2.5 → 3`.
2. Phase 1 reassembled with its scaffold body restored (slug rule → Write-files → tool checks).
3. SKILL.md comfortably under the ~5,000-word ceiling (target ~3,500–4,000) by offloading
   detail to `references/`, **not** by cutting capability.
4. The 12 `scripts/` files documented and no longer orphaned.
5. Zero loss of unique content; zero behaviour change to the investigation flow.

## Non-goals (explicitly out of scope)

- Rewriting phase *logic* or changing the 16-phase sequence/semantics.
- Wiring the `scripts/` into phase execution (kept as documentation only this round).
- Touching phases 3–12 beyond the fingerprint-table offload and incidental pointer text.
- Chasing a 2,000-word target at the expense of a usable spine.

### Discovered anomaly (flagged, not fixed here)

`## Phase 8.5 — PII and Payment Data Classification` sits at line 867 — **after** Phase 10/11,
just before Phase 12 — i.e. out of numeric order. This looks like the same merge damage but is
**outside the Phase 1→2.5 reconcile scope**. Recorded here for a possible follow-up; do not reorder
it as part of this work unless explicitly expanded.

## Design

### 1. Reassemble Phase 1 (the reconcile core)

Reorder into one `## Phase 1 — Scaffold and tool check` block:

1. Canonical slug rule + `mkdir -p docs/sites/${SLUG}/research/{...}` + legacy-workspace check (from 229–237) — **verbatim**, slug `sed` expression unchanged.
2. "Write output files directly, don't `touch`" + the empty-string `Write` list (from 275–283).
3. Tool-availability check + AI-crawler check order + Jina note (285–296).
4. Chrome MCP namespace detection (298–302).
5. gau alias check (304–306).

The domain-discovery intro currently sitting under Phase 1 (101–102) belongs to **Phase 1.5** and
moves there.

### 2. Collapse duplicates

- Phase 1.5: keep one structured section (137–152) + one log table; bash → `references/`.
- Phase 2: keep one header **with** the `phase-detail.md` pointer.
- Phase 2.5: keep one structured section + one log table; keep the **null-safe** bash → `references/`.

### 3. Word-budget offload → `references/`

- Move the Phase 1.5 domain-discovery bash and the Phase 2.5 data-source-inventory bash into
  `references/phase-detail.md` (already referenced from Phase 2). SKILL.md keeps the structured
  Input/Actions/Output summary + a one-line pointer to the reference.
- Move the Phase 3 fingerprint header/table (~lines 406–509) into a reference
  (`references/phase-detail.md` or a new `references/fingerprints.md` — chosen at plan time after
  reading the block's exact extent). SKILL.md keeps a short "first match wins" summary + pointer.

### 4. Document the scripts

Add `scripts/README.md` mapping each of the 12 scripts to the phase it serves, **read-verified per
script** (not inferred from filename): `osint.py` (+ `test_osint.py`, `run_osint_tests.sh`),
`sublist3r.sh`, `passive_dns.sh`, `tls_fingerprint.sh`, `graphql_introspect.sh`,
`openapi_detect.sh`, `config_leakage.sh`, `cloud-enum.sh`, `container-scan.sh`, `cicd-scan.sh`.
Reference `scripts/README.md` once from SKILL.md (reference-files list). No behaviour change.

## Verification gates (content-loss guard)

Run after the reconcile; all must pass before commit:

1. **Fragment survival** — each of these appears **exactly once** (grep count == 1, not 0, not 2):
   canonical slug `sed` line; "Write output files directly"/no-`touch`; Chrome MCP namespace note;
   gau alias check; the `phase-detail.md` pointer; the null-safe previous-scan `find` (`-print0` +
   `read -r -d ''`).
2. **Phase headers** — the genuine duplicate `## Phase` sections **Phase 1.5, Phase 2, Phase 2.5**
   each go from 2 occurrences to **exactly 1**. All other `## Phase` header counts are **unchanged**:
   in particular **Phase 11 must remain 2** — "Phase 11 — Active browse" (753) and
   "Phase 11 — cmux usage guide" (839) are distinct subsections, **not** a duplicate to collapse.
   The canonical ordered phase list at line 33 ("## The 16 phases — always in this order") must
   remain intact. (Phases 5/6/7/9 are not `##`-headed in the body — they live in the canonical list
   and `references/` — and are out of scope here.)
3. **No null-unsafe `find`** — zero occurrences of `find ... | while IFS= read -r research`
   (without `-print0`/`-d ''`) remain.
4. **CI green:** `bash tests/validate-slug-rule.sh`, `bash scripts/validate-marketplace.sh`,
   `python3 plugins/beacon/skills/site-recon/scripts/test_osint.py` (exit 0).
5. **Frontmatter** parses as valid YAML with `name` + `description`.
6. **Word count** down materially and under ~5,000 (`wc -w SKILL.md`); report the number.
7. **Referenced files exist** — any new `references/*` / `scripts/README.md` pointer resolves.

## Execution approach

Because the blast radius is real, the reconcile is done with the fragment-survival check (gate 1)
as a **hard gate**. Either the main agent edits directly, or a tightly-scoped subagent does the
mechanical move with this spec's fragment map as its checklist and a mandatory verification pass.
The implementation plan (writing-plans) sequences this: read full file → reassemble Phase 1 →
collapse dups → offload to references → scripts/README → run all gates → commit.

## Risks

- **Silent content drop** during reassembly → mitigated by gate 1 (per-fragment grep-count == 1).
- **Slug-rule drift** breaking `validate-slug-rule.sh` → mitigated by keeping the `sed` line
  verbatim + gate 4.
- **Over-offloading** detail the model needs inline mid-run → mitigated by keeping each phase's
  structured Input/Actions/Output summary in SKILL.md and offloading only bash/tables.
