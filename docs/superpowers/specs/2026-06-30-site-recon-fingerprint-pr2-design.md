# site-recon PR2 — Phase 3 fingerprint partial offload + validator rewrite

- **Date:** 2026-06-30
- **Status:** approved (design); ready for implementation
- **Branch:** `refactor/site-recon-fingerprint-pr2` (worktree off `origin/main`, includes PR1 #31 + #32)
- **Predecessor:** PR1 (#31, merged) reconciled Phase 1→2.5 and offloaded that bash. SKILL.md is now 5,288 words; this PR lands it under the ~5,000 ceiling.

## Goals
1. Offload the two **static fingerprint signal lookup tables** from Phase 3 to a new `references/fingerprints.md`, keeping the executable parts inline.
2. Rewrite the dead `tests/validate-fingerprinting.sh` (29/64 failing, stale, not in CI) into an honest, passing fingerprint-coverage guard, and wire it into CI.
3. SKILL.md `wc -w` < 5,000.

## Part A — Phase 3 partial offload

Phase 3 (SKILL.md ~216–325 on `origin/main`) decomposes as:

| Region | Lines (approx) | Disposition |
|---|---|---|
| Wappalyzer step + method order | 218 | **inline** (method) |
| **HTTP-headers signal table** (`header/pattern → Framework (confidence)`) | 220–275 | **OFFLOAD** |
| **JS-globals / cookies signal table** | 277–292 | **OFFLOAD** |
| Endpoint probes (live `curl`) | 294–306 | **inline** (executed mid-phase) |
| No-match + log-result | 308–310 | **inline** |
| Version-extraction rules | 312–324 | **inline** (executed mid-phase) |

- New `plugins/beacon/skills/site-recon/references/fingerprints.md`: a short header + the two signal tables, **byte-identical** content, in two sections ("HTTP header / path signals", "JS globals & cookies").
- In Phase 3, replace the two tables with an **imperative pointer**: e.g. "**Load `references/fingerprints.md` for the full header/path and JS-global signal tables before fingerprinting.**" Keep the numbered method order coherent and retain the Definitive/High/Medium confidence vocabulary inline.
- Add `references/fingerprints.md` to SKILL.md's reference-files list.
- **Three legitimate signals currently missing from Phase 3** are added to `references/fingerprints.md` so they exist in the union (they are real fingerprints, and the validator asserts them): Astro `_astro/` + `astro-island`; Django `csrfmiddlewaretoken`; Shopify `cdn.shopify.com`.

## Part B — Rewrite `tests/validate-fingerprinting.sh`

Current rot: `EXPECTED_PACK_COUNT=12` (real: 54); slug checks reference an outdated `s|\.|-|g` (canonical rule is `s/\./-/g`, already covered by `validate-slug-rule.sh` in CI); signal greps scan only SKILL.md (would break on the offload); 29 hard failures, not in CI.

Rewrite to:
1. **Drop the slug checks entirely** — they duplicate `tests/validate-slug-rule.sh` (the CI slug gate) and are stale. This validator is fingerprint-only.
2. **Union signal source:** every signal grep scans `SKILL.md` Phase 3 **+** `references/fingerprints.md` (so offloaded signals are found). Keep the named checks (Astro, Django, FastAPI, Rails, Shopify, Strapi); they pass against the union once Part A adds the 3 missing signals.
3. **Coverage = regression-guard + warning report, not hard gate:**
   - Loop over every tech-pack dir (dynamic count, no hardcoded `EXPECTED_PACK_COUNT`).
   - A pack with a signal in the union → PASS. A pack **without** → emit a **WARNING** (informational) and count it; do **not** FAIL. This surfaces the real ~30-pack coverage gap without masking it or failing CI.
   - Print a summary: "N/54 packs have a Phase 3 fingerprint signal (M uncovered — see warnings)."
4. **Exit 0** when the named signal checks pass and there are no regressions; non-zero only on a genuine regression (a named/known signal absent from the union) or a structural error (SKILL.md or fingerprints.md missing).
5. **Wire into CI:** add a step to `.github/workflows/validate.yml` running `bash tests/validate-fingerprinting.sh`.

## Verification gates
Let `SK=plugins/beacon/skills/site-recon/SKILL.md`, `FP=plugins/beacon/skills/site-recon/references/fingerprints.md`.
1. **G-A offload conservation:** the two signal tables' lines leave `$SK` and appear in `$FP`; whole-branch `comm` (old `$SK` vs new `$SK`+`$FP`+other references) shows only justified deltas (the 2 tables moved; the pointer text added; the 3 new signals added).
2. **G-E offload integrity:** a signature line from each table (`x-shopify-stage: production` from headers; `__VIEWSTATE` from JS-globals) is present in `$FP` and absent from `$SK`; `$SK` retains an imperative `fingerprints.md` pointer; reference-list updated.
3. **Inline-retained:** the endpoint-probe `curl` block, the version-extraction rules, and the Definitive/High/Medium vocabulary remain in `$SK` Phase 3 (`grep` for `admin/init`, `swagger-ui`, `Version extraction`, `Definitive`).
4. **Validator passes:** `bash tests/validate-fingerprinting.sh` exits 0; its output reports the coverage warnings (not failures).
5. **All CI green:** `validate-slug-rule.sh`, `validate-marketplace.sh`, `validate-reframe-helpers.sh`, **and the newly-wired `validate-fingerprinting.sh`** all pass; `test_osint.py` exits 0.
6. **Word budget:** `wc -w $SK` < 5,000 (report the number).
7. **CI wiring:** `validate.yml` contains the new fingerprinting step.

## Non-goals
- Closing the full ~30-pack fingerprint-coverage gap (warned, not fixed — its own effort).
- Touching Phase 3's method order, probes, or version-extraction logic beyond moving the two tables.
- Any other phase. No version bump (internal restructure).

## Execution
Subagent-driven-development in the worktree, block-level edits, editor ≠ verifier:
- **Task P1:** Part A offload (implementer + reviewer; G-A/G-E + inline-retained gates).
- **Task P2:** Part B validator rewrite + CI wiring (implementer + reviewer; validator-passes + all-CI-green gates).
Then a final whole-branch review + the verification gates, then open PR2.
