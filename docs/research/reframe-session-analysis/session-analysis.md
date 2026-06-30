# Reframe Session Analysis: AMS & TrustYourPhysio

**Source sessions analysed** (both run from `~/Developer/projects/pilitsoglou`, reframe v0.3.0):

- **trustyourphysio** — `b3fe4b41-cb3d-4f0b-8f4e-6a3cf52f1e4c.jsonl` (~237 records, 64 tool calls) → redesigned `trustyourphysio.com`
- **ams** — `7a16dbae-0c11-4650-9d66-b8ead2ebd84b.jsonl` (~479 records, ~70 tool calls) → redesigned `amarsolutions.gr` (slug `amarsolutions-gr`)

**Purpose:** Drive improvements to the `reframe` plugin (`site-redesign` skill) based on real usage patterns. Companion to `docs/research/beacon-session-analysis/`.

---

## TL;DR — the headline thesis

**Both runs produced complete, paste-ready, token-clean output. The plugin did not do that alone — the harness `advisor()` did.** In both sessions the external advisor caught substantive errors the skill's own guardrails missed:

- **trustyourphysio:** would have shipped **false "this section is empty" findings** (Jina markdown silently dropped populated sections) and a **false causation claim** in brief §10 (CSR wrongly blamed for a `/book` 404). Advisor caught both; the agent re-rendered with headless Playwright and corrected them.
- **ams:** the agent declared "I have everything for synthesis" and was about to **write all six files without reading the templates/format contract and without running `detect-category.py`** (skipping category detection entirely). Advisor caught it; the agent complied and produced conformant output.

`advisor()` is a harness feature, **not part of reframe**. So the correct conclusion is: **plugin + advisor → excellent output; plugin alone → substantive errors in both runs.** That gap is the entire improvement thesis. The skill's deterministic guardrails (`coverage-metrics.py`, `detect-category.py`, `check-output-complete.sh`) verify **form** (files exist, no `{{TOKEN}}` left) but never **substance** (claims verified against render, category actually detected, templates actually read, markers actually emitted). Both runs passed the form gate while leaning on advisor for substance.

Secondary signal worth its own weight: **two failure patterns flagged in the beacon analysis — write-before-Read on scaffolded files, and phase-skipping — recurred here.** Prose instructions alone ("Write, not touch"; "always in this order") did not stick across plugins. Enforcement, not more exhortation, is the lever.

---

## Per-session snapshot

| | trustyourphysio | ams |
|---|---|---|
| Completed 9 phases / 6 files | ✅ all 6, zero `{{}}` left | ✅ all 6, zero `{{}}` left |
| `check-output-complete.sh` | ✅ ran, exit 0 | ✅ ran twice, exit 0 |
| `coverage-metrics.py` | ✅ ran | ❌ **skipped** (python3 was available) |
| `detect-category.py` | ✅ ran → `local-service` | ✅ ran → `ecommerce` (near-skipped; advisor-rescued) |
| Phase markers emitted | P1,P2,P5,P6,P8,P9 (P3/P4/P7 missing) | P1,P9 + `[PACK-LOADED]` only (P2–P8 missing) |
| Strategic question timing | moved **early**, before deliverable writes | moved **early**, before category detection |
| Recon reuse | no | **yes** — built entirely on prior beacon recon |
| advisor() calls | 2 (both changed the output) | 1 (prevented non-conformant rewrite) |
| User corrections | 0 (only the 1 planned question) | 4 steers ("anything missed?", worktree/PR, legacy-path question) |
| Active agent time | ~26 min (rest = 6h human-answer gap) | ~13 min core run |
| Paths (plugin-root vs skill-dir) | ✅ correct | ✅ correct |

Both runs were **lean and competent** on mechanics. The weaknesses are systemic, not sloppiness.

---

## Findings, split by fix type

The advisor's key structural insight: findings need **opposite fixes**. Separate them or the recommendations blur.

### Bucket A — Skill ALREADY says it; agents ignored it anyway → needs ENFORCEMENT (highest leverage)

Adding more prose here will not help — the prose exists and was skipped. The fix is a deterministic gate.

| # | What the skill says | What happened | Enforcement fix |
|---|---|---|---|
| A1 | "create empty output files (**Write, not touch**)" (SKILL.md:55) | **ams** created scaffolds via Bash heredoc → harness forced 6 redundant Reads before Write (write-before-Read). **Same pattern as beacon analysis finding #1.** | Phase-1 scaffold check, or have `check-output-complete.sh` (or a new pre-Phase-9 gate) assert files were Write-tracked. Better: stop scaffolding empty files at all — Write them at first real content. |
| A2 | "Run `coverage-metrics.py` … Fallback **if python3 or the script is unavailable**" (SKILL.md:90) | **ams** skipped it and eyeballed the render gate while python3 was demonstrably available (the other two scripts ran). | Gate should require the script when python3 is present; manual inspection allowed only on genuine script error. |
| A3 | Per-phase markers `[P1✓]`…`[P9✓]`; "always in this order" (SKILL.md:33) | Markers largely **not emitted** (ams: only P1, P9, PACK-LOADED). No consequence — nothing checks them. | `check-output-complete.sh` should assert all 9 markers + `[PACK-LOADED:x]` are present in the session record/INDEX; fail-closed if any missing. |
| A4 | Phase 7 must run `detect-category.py` and emit `[PACK-LOADED]` before the Phase-8 pack-cited critique | **ams** nearly wrote all 6 files with **no category detection at all** — only advisor stopped it. | Make "`[PACK-LOADED:x]` fired" a hard precondition of Phase 9; completeness gate fails if it never fired. |

> **Why this bucket is #1:** the beacon-recurrence proves prose doesn't stick. The completeness gate is the one place reframe already enforces something deterministically — extending it from "no leftover tokens" to "category detected + scripts run + markers present + no untracked scaffolds" converts four soft instructions into hard ones at near-zero cost.

### Bucket B — Skill is SILENT → needs NEW prose / new rungs

| # | Gap | Evidence | Fix |
|---|---|---|---|
| B1 | **Unverified inference → false claims.** Jina markdown is silently lossy on JS-reveal SPAs (under-reported nav 1 vs 8; dropped whole populated sections) → seeded multiple **false "section empty/missing" findings**. | trustyourphysio; caught only by advisor | Add a coverage rule: *Jina markdown ≠ ground truth on scroll/JS-reveal SPAs; before any "section is empty/missing/broken" claim, cross-check against a JS render.* Promote from advisor-luck to a Phase-3/8 rule. |
| B2 | **Chrome DevTools MCP single-instance lock** ("browser already running… use `--isolated`") blocked the only skill-sanctioned screenshot/verify path. Agent had to **invent** a local Playwright headless render. | trustyourphysio (msgs ~148–170) | Add a fallback rung to `references/crawl-and-coverage.md`: local Playwright/Puppeteer (`node_modules` or `npx playwright`) headless render; and tell the Chrome-MCP rung to use `--isolated` / reuse `list_pages` when the profile is locked. |
| B3 | **No prior-recon reuse branch.** ams built the whole redesign on an existing `docs/research/{slug}/` beacon corpus; the skill has no path for this, so the agent improvised and advisor had to remind it to be honest in `{{SAMPLING_NOTE}}`/`{{AUDITED_COUNT}}` and to read **all** recon files (it skipped `osint.md`/`INDEX.md` until the user asked "anything missed?"). | ams | Add an explicit branch: *if `docs/sites|research/{slug}/research/` exists → reuse + live re-verify homepage; read ALL recon files before synthesis; mandated provenance-token wording.* |
| B4 | **Render gate is homepage-only.** A sitemap route with priority 0.9 (`/book`) returned a client-side 404; caught manually. | trustyourphysio | Add a per-route "does it render real content, not just a 200 shell?" sub-check to the Phase-3 coverage manifest. |
| B5 | **Missing B2B / industrial-distributor pack.** `ecommerce` won on **dead WooCommerce demo pages** for a no-checkout B2B supplier; agent reframed checkout→"Request a Quote" but the fit was awkward. | ams | Add a B2B/industrial-distributor category pack (6th pack). `detect-category.py` auto-discovers via glob — no code change. |
| B6 | **Jina pageshot returns a signed GCS URL, not a PNG** → 3-call detour. | trustyourphysio | Document the two-step (`X-Respond-With: pageshot` → download returned URL) in `references/crawl-and-coverage.md`. |
| B7 | **Design-system seed hex are guesses**, not sampled. | both (brief §7) | Add an optional micro-step: extract dominant brand hex from the homepage screenshot/CSS so §7 is measured, not approximated. |
| B8 | **Jina HTTP 451** (geo/legal block) on the Greek site — handled correctly as "unavailable", but undocumented. | ams (Phase 1) | One line in tool-availability: 451 = geo/legal block → treat as unavailable, fall through chain. |

### Phase-ordering: a SPLIT, not a wholesale move

Both sessions **independently** moved the strategic same-vs-new-purpose question ahead of the deliverable file-writes — a strong signal the documented order is wrong (the answer reframes every downstream file, and waiting until after writing them invites rework). **But do not just "move Phase 7 early":** ams moved the *question* early **and** nearly skipped *category detection*. The fix is to **split Phase 7**:

- **Strategic question** → after crawl (P4), before the deliverable files (P5/P6/P8). Encode the dependency.
- **Category detection + `[PACK-LOADED]`** → stays mandatory and must feed the Phase-8 pack-cited critique (see A4).

---

## Ranked recommendations (substance above form)

1. **Extend `check-output-complete.sh` into a substance gate (Bucket A2/A3/A4).** Assert: `coverage-metrics.py` ran (or errored), `[PACK-LOADED:x]` fired, all 9 phase markers present, no untracked empty scaffolds. Highest leverage, lowest cost — converts the advisor-rescued failures into deterministic blocks.
2. **Add the "don't infer from lossy render" rule (B1).** A false "section empty" claim is *actively harmful* in a brief; this is the top **substance** risk and it only didn't ship because of advisor.
3. **Make category detection a hard precondition of Phase 9 (A4).** Pairs with #1.
4. **Add the local-Playwright screenshot/verify rung + `--isolated` guidance (B2).** Unblocks the only sanctioned visual path when Chrome MCP is locked.
5. **Add the prior-recon reuse branch with mandated provenance + "read all recon files" (B3).**
6. **Split Phase 7** (question early, detection stays). 
7. **Stop scaffolding empty files; Write at first content (A1)** — also fixes the beacon-recurring write-before-Read.
8. **Add B2B/industrial-distributor pack (B5);** per-route render check (B4); pageshot-URL two-step (B6); color sampling (B7); Jina-451 note (B8).

Form-only items (missing phase markers, verbose briefs) sit below all of the above — a missing `[P4✓]` harms no one; a false claim does.

---

## What went well (so we don't regress it)

- **Completeness gate + no-leftover-token discipline works** — zero `{{TOKEN}}` in either run.
- **Path discipline is solid** — `categories/`+`templates/` read from plugin root, `references/` from skill dir, in both runs. The SKILL.md "Path note" earns its keep.
- **Graceful degradation fired correctly** — greenfield not falsely triggered, WAF chain not needed, multi-locale judgment reasonable (ams English-only → correctly no `[MULTI-LOCALE]`).
- **Progressive disclosure held** — SKILL.md loaded once, references/templates pulled on demand; no mid-run skill re-reads.
- **Recon reuse saved a ~131-URL crawl** (ams) — the *instinct* was right; it just needs to be a first-class, provenance-honest path.

---

## Cross-plugin pattern (durable)

Two failure modes now observed in **both** beacon and reframe sessions:

1. **Write-before-Read on scaffolded empty files** (beacon finding #1; reframe ams A1).
2. **Phase-skipping with no consequence** (beacon: Phases 4/5/7 skipped until user asked; reframe: markers/scripts skipped, category nearly skipped).

**Lesson for all plugins in this repo:** a phase/step that is only *described* in prose will be skipped under synthesis pressure. If a step matters, it needs a **deterministic gate** (a script that fails closed), not a stronger sentence. Both plugins already ship a completeness checker — that's the natural home for the enforcement.

---

## Evidence index

- Skill contract: `plugins/reframe/skills/site-redesign/SKILL.md` (9 phases, 36-token contract, degradation signals)
- Scripts: `…/scripts/{coverage-metrics.py, detect-category.py, check-output-complete.sh}`
- trustyourphysio outputs: `pilitsoglou/docs/sites/trustyourphysio-com/redesign/` (also copied into this repo, untracked)
- ams outputs: `pilitsoglou/docs/sites/amarsolutions-gr/redesign/` (built on `pilitsoglou/docs/research/amarsolutions-gr/`)
- Companion: `docs/research/beacon-session-analysis/session-analysis.md`
