# site-recon SKILL.md — reconcile + word-budget offload

- **Date:** 2026-06-26 (rev. 2 after multi-angle design evaluation)
- **Status:** approved (design); ready for implementation
- **Branch:** `refactor/site-recon-restructure` (spec) → PR1 implemented in a worktree
- **Scope owner:** beacon plugin / `plugins/beacon/skills/site-recon/SKILL.md`

## Context

`site-recon` is beacon's core 16-phase investigation skill. Its SKILL.md is 964 lines /
~6,333 words (ceiling ~5,000). A `plugin-dev:skill-reviewer` sweep flagged it as bloated with
phases "pasted 2–3 times." The duplication is not clean copies — it is a scrambled `Phase 1→2.5`
region. This spec reconciles that region, offloads detail to `references/`, and documents the
12 `scripts/`. A four-angle adversarial design review (content-loss, verification, approach,
scope) produced rev. 2; its corrections are folded in below.

## Root cause (corrected in rev. 2)

The duplicate `## Phase 1.5 / 2 / 2.5` headers were introduced by **`9fc7b8d`
("fix(beacon): resolve PR #23 review issues")** — its diff adds exactly those headers. The
previously-blamed `3d77d4d` (PR #27) added **zero** phase headers; it only rewrote
`docs/research` → `docs/sites` content inside an already-duplicated structure. The last clean
revision is **`b7ad368`** ("chore: stage remaining changes"): 738 lines / **4,984 words**, one copy
of each phase, order `1 → 1.5 → 2 → 2.5 → 3`.

**Implication:** even in the clean `b7ad368`, the Phase 1 scaffold body (slug rule, `mkdir`,
Write-files, tool checks, Chrome-MCP, gau) already lived **under Phase 2.5**. So "reassemble
Phase 1" is a deliberate **structural improvement**, not a restoration of lost order. `b7ad368` is
used as a **fragment-inventory oracle** to seed the survival checklist (NOT as a byte-diff gate —
paths, slug rule and null-safe finds legitimately changed since).

## PR plan (split, per evaluation)

- **PR1 (this work):** reconcile + collapse duplicates + offload the Phase 1.5/2.5 bash to
  `references/` + Phase 8.5 reorder + `scripts/README.md`. Diff reads as pure moves. Expected
  ~5,330 words (improved; **not yet under 5k** — that is a PR2 deliverable).
- **PR2 (deferred):** Phase 3 fingerprint **partial** offload (static signal table only) paired
  with the `tests/validate-fingerprinting.sh` fix; achieves the <5k target. Out of scope here.

## Current-state fragment map (lines ref `main` @ 132ff63)

| Lines | Fragment | Status | Reconciled home |
|---|---|---|---|
| 99 | `## Phase 1` header | — | Phase 1 |
| 101–102 / 239–240 | "New: Multi-source Domain Discovery" intro | dup | **Phase 1.5** (lead-in) |
| 103–125 / 241–263 | Phase 1.5 inline bash | dup | → `references/phase-detail.md` |
| 127–133 / 265–271 | `### Discovered Domains` log table | dup | Phase 1.5 (keep one) |
| 137–152 / 310–325 | Phase 1.5 structured section | dup | Phase 1.5 (keep one) |
| 156 / 329 | `## Phase 2` header | dup; copy 2 (329) adds the `phase-detail.md` pointer (331) | keep copy 2 |
| **158–159 / 333–334** | **"New: Data Source Inventory" intro** ("After passive recon, run Phase 2.5…") | **dup — was MISSED in rev.1** | **Phase 2** (after the pointer, as the 2.5 lead-in) |
| 160–198 / 335–373 | Phase 2.5 inline bash | **DIVERGED** (see below) | keep copy 2 → `references/phase-detail.md` |
| 200–206 / 375–381 | `### Data Sources` log table | dup | Phase 2.5 (keep one) |
| 210–227 / 385–402 | Phase 2.5 structured section | dup | Phase 2.5 (keep one) |
| 229–237 | Canonical slug rule bash (slug + `mkdir` + legacy check) | single, misplaced under 2.5 | **Phase 1** (first) |
| 275–283 | "Do NOT use `touch`" + empty-string Writes | single, misplaced | **Phase 1** (after slug) |
| 285–296 | Tool matrix + AI-crawler order + Jina note | single, misplaced | **Phase 1** |
| 298–302 | Chrome MCP namespace note | single, misplaced | **Phase 1** |
| 304–306 | gau alias check | single, misplaced | **Phase 1** |

### Diverged block — which copy wins

Phase 2.5 "previous scan results" `find`:
- Copy 1 (188–190): `find … 2>/dev/null; } | while IFS= read -r research` — **null-unsafe**.
- Copy 2 (363–365): `find … -print0 2>/dev/null; } | while IFS= read -r -d '' research` — **null-safe**.

**Keep copy 2** (null-safe). The three preceding finds (schema/migration/seed) are already
null-safe in both copies. Keep Phase 2 copy 2 (carries the `phase-detail.md` pointer).

## Design — PR1

### 1. Reassemble Phase 1 (one `## Phase 1 — Scaffold and tool check`)

Order (the only hard dependency: slug `mkdir` must precede the Write list):
1. Canonical slug rule + `mkdir -p docs/sites/${SLUG}/research/{...}` + legacy check (229–237) — **verbatim**, slug `sed` unchanged.
2. "Do NOT use `touch`" + empty-string `Write` list (275–283).
3. Tool-availability + AI-crawler order + Jina note (285–296).
4. Chrome MCP namespace (298–302).
5. gau alias check (304–306).

The domain-discovery intro (101–102) moves to Phase 1.5.

> Behaviour note (rev. 2): this is **near-zero behaviour change** — it corrects an ordering
> inconsistency where the document referenced `${SLUG}` (Phase 1.5 output path) before defining it.
> The skill re-derives `SLUG` per Bash call, so it is a consistency/readability fix, not a hard
> runtime bug. The "zero behaviour change" claim is softened accordingly.

### 2. Collapse duplicates

- Phase 1.5: one structured section + one `### Discovered Domains` table; bash → reference.
- Phase 2: one header **with** the `phase-detail.md` pointer **and** the "New: Data Source
  Inventory" lead-in (158–159) — the fragment rev.1 missed; it must survive exactly once.
- Phase 2.5: one structured section + one `### Data Sources` table; keep the **null-safe** bash → reference.

### 3. Offload the Phase 1.5/2.5 bash → `references/phase-detail.md`

Move the Phase 1.5 domain-discovery bash and the (null-safe) Phase 2.5 data-source-inventory bash
into `references/phase-detail.md` (already referenced from Phase 2). SKILL.md keeps each phase's
structured Input/Actions/Output summary + the log table + an **imperative** pointer
("Load `references/phase-detail.md` before executing this phase", matching the Phase 11/12
convention). Update the reference-files list (SKILL.md ~961): the `phase-detail.md` description
currently reads "phases 2, 5, 6, 7, and 9" → add **1.5, 2.5**.

### 4. Phase 8.5 reorder (pulled into scope per evaluation)

`## Phase 8.5 — PII and Payment Data Classification` (body 867–920, self-contained, ends before
Phase 12) is misordered — it sits after Phase 11. The line-33 overview list and the Phase 12
completion gate (`[P8.5✓]`, ~937) both place it between 8 and 9. Move the 867–920 block to its
numeric slot **after Phase 8 / before Phase 9** as an isolated commit. Pure cut-and-paste, no
duplicate/divergence. This aligns the body with the skill's own declared order.

### 5. Document the scripts → `scripts/README.md`

Map each of the 12 scripts to the phase it serves, **read-verified per script** (not inferred):
`osint.py`, `test_osint.py`, `run_osint_tests.sh`, `sublist3r.sh`, `passive_dns.sh`,
`tls_fingerprint.sh`, `graphql_introspect.sh`, `openapi_detect.sh`, `config_leakage.sh`,
`cloud-enum.sh`, `container-scan.sh`, `cicd-scan.sh`. Reference it once from SKILL.md's
reference-files list. **Honesty requirements (rev. 2):** state that these are **reference-only,
not currently invoked by the phase flow**; mark each **orphaned vs wired** (all currently
orphaned); note only `osint.py`/`test_osint.py` is exercised by CI (the other 11 untested); flag
that several duplicate inline phase logic (`openapi_detect.sh`↔Phase 8, `osint.py`↔Phase 9,
`config_leakage.sh`↔Phase 6b) and so risk drift; end with "follow-up: wire-or-delete." No
behaviour/flow change.

## Verification gates (rev. 2 — rewritten; all must pass before commit)

Let `SK=plugins/beacon/skills/site-recon/SKILL.md`,
`REF=plugins/beacon/skills/site-recon/references`,
`SCR=plugins/beacon/skills/site-recon/scripts`.

1. **G-A — line conservation (keystone).** No pre-existing content vanishes from *all*
   destinations:
   ```bash
   git show HEAD:$SK | sed 's/[[:space:]]*$//' | grep -v '^[[:space:]]*$' | sort -u > /tmp/old.txt
   cat $SK $REF/*.md $SCR/README.md | sed 's/[[:space:]]*$//' | grep -v '^[[:space:]]*$' | sort -u > /tmp/new.txt
   comm -23 /tmp/old.txt /tmp/new.txt
   ```
   A clean de-dup + move prints **nothing**. Every printed line MUST be individually justified as
   an intentional rewrite (e.g. a pointer reworded). Unjustified line ⇒ FAIL.
2. **G-B — placement.** Each relocated fragment sits under its target header:
   - slug `sed` (`s/:[0-9]+$//`) appears between `## Phase 1 ` and `## Phase 1.5 ` in `$SK`.
   - the moved Phase 2.5 bash signature (`CREATE TABLE|ALTER TABLE`) lives in `$REF/phase-detail.md`, not `$SK`.
   - the "Do NOT use `touch`" line is between `## Phase 1 ` and `## Phase 1.5 `.
   (Use `awk` section extraction; a fragment surviving once but under the wrong header = FAIL.)
3. **G-C — header counts (anchored).** In `$SK`: `^## Phase 1.5 ` ==1, `^## Phase 2 ` ==1,
   `^## Phase 2.5 ` ==1; `^## Phase 11 ` ==2 (Active browse + cmux — **unchanged**);
   `^## Phase 8.5 ` ==1 and now positioned after `## Phase 8 ` and before `## Phase 9`/Phase 10.
   The line-33 "## The 16 phases" list is byte-unchanged.
4. **G-D — no null-unsafe find.** Zero matches for `while IFS= read -r research` *without* `-d ''`
   across `$SK` and `$REF` (`grep -rn`).
5. **G-E — offload integrity.** The moved bash actually landed: `grep -Fq 'FROM stores WHERE url LIKE'`
   and `grep -Fq 'CREATE TABLE|ALTER TABLE'` succeed in `$REF/phase-detail.md`; the corresponding
   blocks are **gone** from `$SK`; `$SK` retains an imperative `phase-detail.md` pointer in both
   Phase 1.5 and Phase 2.5.
6. **G-F — scripts/README completeness.** Each of the 12 basenames appears in `$SCR/README.md`
   (loop `grep -Fq`); the file states "reference-only / not invoked".
7. **G-G — CI + tests green.** `bash tests/validate-slug-rule.sh`,
   `bash scripts/validate-marketplace.sh`, `bash tests/validate-reframe-helpers.sh`
   (the **three real CI gates**) all exit 0; `python3 $SCR/test_osint.py` exits 0 (sanity — note it
   is NOT in CI and orthogonal to this change); SKILL.md frontmatter parses as valid YAML with
   `name` + `description`. **Note:** `validate-slug-rule.sh` greps the *whole repo* (8 slug copies)
   so it does **NOT** detect slug loss from `$SK` — G-A + G-B are the real slug guard, not G-G.
8. **G-H — word count.** Report `wc -w $SK` before/after; expect a material drop to ~5,300
   (PR1 does not yet reach <5k — that is PR2). `validate-fingerprinting.sh` is intentionally **not
   run** here (PR1 leaves Phase 3 inline, so it is unaffected).

## Execution approach (rev. 2)

- **Block-level `Edit`s only — NO full-file `Write` of SKILL.md.** This keeps the diff reviewable
  as moves and prevents paraphrase/regeneration drift.
- Work in an **isolated git worktree** (per request). Subagent-driven-development: the work splits
  into a few tasks — (T1) reassemble Phase 1 + collapse dups, (T2) offload 1.5/2.5 bash to the
  reference + pointers + reference-list desc, (T3) Phase 8.5 reorder, (T4) `scripts/README.md`
  (independent). T1→T2 are sequential (same region); T3/T4 are independent.
- **Editor ≠ verifier.** Whoever performs the edits, a **separate** verification pass runs gates
  G-A…G-H against the diff — second eyes, not second author. Seed G-A/G-B's expectations from the
  `b7ad368` oracle, not from hand-memory.

## Non-goals

- Rewriting phase *logic* or changing the 16-phase sequence/semantics.
- Wiring `scripts/` into phase execution (documentation only this round).
- **Phase 3 fingerprint offload + `validate-fingerprinting.sh`** — deferred to PR2.
- Version bump: PR1 is an internal restructure with no capability change → **no version bump**. (If
  one is ever wanted, `plugin.json` + `marketplace.json` must be synced — `validate-marketplace.sh`
  is a live CI gate on that parity.)
- Chasing a 2,000-word target at the expense of a usable 16-phase spine.

## Risks

- **Silent content drop / wrong-copy / wrong-placement** → G-A (line conservation) + G-B
  (placement) + keep-copy-2 rule.
- **Slug-rule loss invisible to CI** (whole-repo grep) → guarded by G-A/G-B, not G-G.
- **Offload truncation** (file exists but content not landed) → G-E.
- **Over-offloading** detail needed inline → keep each phase's structured summary + log table inline;
  move only bash.
- **`scripts/README` ossifying dead code as toolkit** → honesty requirements (orphaned/untested/
  drift + wire-or-delete follow-up).
