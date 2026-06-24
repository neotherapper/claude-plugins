# reframe — Testing Guide

> How to validate reframe behaviour against its acceptance criteria.

reframe has no runtime application code — it is an AI agent system. "Testing" means running the plugin in Claude Code and verifying observable outputs match the Gherkin scenarios in `docs/plugins/reframe/specs/`.

---

## Feature files

| File | What it covers |
|------|---------------|
| `specs/site-redesign.feature` | 9-phase pipeline, render escalation, greenfield detection, category fallback, beacon deference |

---

## Running a scenario

1. Open a project in Claude Code with reframe installed
2. Identify the scenario to test (copy the `Scenario:` title)
3. Set up the `Given` preconditions manually (target URL, tool availability, prior research, etc.)
4. Run the `When` step as a natural language command or `/reframe:analyze {url}`
5. Verify each `Then` assertion against actual files and Claude output

---

## Validation

Run before any PR from the repo root:

```bash
bash scripts/validate-marketplace.sh          # manifest present, valid JSON, plugin registered
```

Then dispatch the **`plugin-dev:plugin-validator`** agent on `plugins/reframe/` — it checks manifest fields, skill folder layout, command frontmatter, and reference file presence.

To evaluate the skill description's triggering accuracy, run **`skill-creator`** on `skills/site-redesign/SKILL.md`. The triggering eval guards the beacon collision: every positive prompt (containing "redesign") must select `site-redesign`; bare-URL and API-intent prompts must NOT.

---

## Helper scripts (v0.2.0+)

The skill prefers three deterministic helper scripts for its mechanical steps, falling back to inspection when `python3`/the script is unavailable. They live in `skills/site-redesign/scripts/`:

| Script | Used in | CLI |
|--------|---------|-----|
| `coverage-metrics.py` | Phase 3 gates | `python3 …/coverage-metrics.py <markdown-file>` (or `--stdin`) → JSON `{body_text_chars, nav_link_count, unique_headings, non_nav_prose_words, signals}` |
| `detect-category.py` | Phase 7 | `python3 …/detect-category.py --categories <dir> --corpus <file-or-dir>` → JSON `{winner, scores, tie, tied}` |
| `check-output-complete.sh` | Phase 9 done-signal | `bash …/check-output-complete.sh docs/sites/{slug}/redesign` → exit 0 when six files exist, non-empty, no `{{token}}` |

Two test layers cover them:

- **Per-function unit tests** (local dev) — `python3 skills/site-redesign/scripts/test_coverage_metrics.py` and `test_detect_category.py`.
- **CLI contract smoke test** (runs in CI) — `bash tests/validate-reframe-helpers.sh` invokes each helper the way `SKILL.md` does and asserts the JSON keys, exit codes, and one behavior each (empty shell → `[RENDER-ESCALATED]`; clinic corpus → `local-service`; zero-match → `generic`; leftover `{{token}}` → non-zero exit). This is the gate that catches a wiring/contract break, not just internal-logic regressions.

The canonical slug rule has its own CI guard: `bash tests/validate-slug-rule.sh` (drift across copies + edge-case correctness). All three — marketplace, slug, helper-contract — run in `.github/workflows/validate.yml`.

---

## Output folder assertions

After a successful `/reframe:analyze` run, verify:

```
docs/sites/{site}/redesign/
├── INDEX.md               — assumptions header, coverage manifest, file table, how-to-use
├── brief.md               — 10 sections present; no {{TOKEN}} remaining
├── run-sheet.md           — validate → key screen → remaining prompts in order
├── content-inventory.md   — rows with URL, verdict, ROT flags
├── ia-map.md              — nav hierarchy, intent triplets, journeys, conversion path
└── current-critique.md    — findings with severity (0–4), cited best-practice, concrete fix
```

Each file must be non-empty. No file may contain an unresolved `{{` token. `.crawl/` should be present but is git-ignored.

---

## Phase coverage checklist

Run `/reframe:analyze` on a known site and verify each phase produces output:

| Phase | Name | Verification |
|-------|------|-------------|
| 1 | Scaffold + tool check | `docs/sites/{slug}/redesign/` created with all six output files (empty) + `.gitignore` containing `.crawl/`; tool availability block in session brief |
| 2 | Structure discovery | `ia-map.md` skeleton written; URL count and cluster table in session brief |
| 3 | Render + coverage gate | Coverage manifest in session brief; `[RENDER-ESCALATED]` logged for SPA sites; `[GREENFIELD-MODE]` halts pipeline for placeholder sites |
| 4 | Content crawl + screenshots | `.crawl/` populated with per-page markdown; at least one screenshot or `[TOOL-UNAVAILABLE:chrome-mcp]` noted |
| 5 | Content audit | `content-inventory.md` written with at least one row per sampled page |
| 6 | IA / journey map | `ia-map.md` completed with intent triplets, journeys, and conversion path |
| 7 | Intent inference | Session brief updated with `[PACK-LOADED:{category}]`; pivot question asked and recorded |
| 8 | Current-design critique | `current-critique.md` written with severity-rated findings citing named best-practices |
| 9 | Synthesize | All six output files finalised; no `{{` remaining in any file |

---

## Live smoke test

Run against `https://trustyourphysio.com/` (the canonical SPA test case):

1. `/reframe:analyze https://trustyourphysio.com/`
2. Verify `[RENDER-ESCALATED]` fires — homepage returns near-empty HTML; markdown crawler escalates
3. Verify `[PACK-LOADED:local-service]` — site is a physiotherapy clinic
4. Verify the pivot question is asked before Phase 9 finalises the brief
5. Verify all six output files are written under `docs/sites/trustyourphysio-com/redesign/`
6. Verify `brief.md` contains the verbatim web-capture-override sentence
7. Verify no `{{` tokens remain in any output file

---

## Regression checklist before any PR

- [ ] `bash scripts/validate-marketplace.sh` passes
- [ ] `bash tests/validate-slug-rule.sh` passes (slug drift + correctness)
- [ ] `bash tests/validate-reframe-helpers.sh` passes (helper CLI contract)
- [ ] `plugin-dev:plugin-validator` on `plugins/reframe/` reports no errors
- [ ] `skill-creator` triggering eval: all redesign-intent prompts select `site-redesign`; bare-URL and API-intent prompts do not
- [ ] `/reframe:analyze` completes all 9 phases without halting on a normal site
- [ ] Output folder created at `docs/sites/{site}/redesign/` with correct file structure
- [ ] No unresolved `{{` tokens in any output file
- [ ] `[RENDER-ESCALATED]` fires correctly on a JS-rendered SPA
- [ ] `[GREENFIELD-MODE]` fires correctly on a placeholder/coming-soon page and halts pipeline
- [ ] `[PACK-LOADED:{category}]` present in every successful run
- [ ] Pivot question asked in every run before Phase 9
- [ ] `brief.md` web-capture-override sentence present verbatim
