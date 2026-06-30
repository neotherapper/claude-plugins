# Reframe Session-Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the gaps surfaced by the `ams` + `trustyourphysio` reframe sessions so the `site-redesign` skill produces correct output *without* depending on the harness `advisor()` to rescue it.

**Architecture:** Two fix classes (per `docs/research/reframe-session-analysis/session-analysis.md`). (A) **Enforcement** — the skill already instructs steps agents skip anyway; convert the worst into a deterministic gate by formalising a machine-checkable `## Run log` block in `INDEX.md` and extending `check-output-complete.sh` to assert it. (B) **New prose/rungs** — add the substance rule (don't infer from lossy render), a local-Playwright screenshot fallback, a prior-recon reuse branch, a per-route render check, a B2B/industrial category pack, and small tool notes. Plus a Phase-7 *split* (strategic question early; category detection stays mandatory).

**Tech Stack:** Markdown skill docs, Bash (`check-output-complete.sh`), Python 3 (`detect-category.py`, pytest tests). No new runtime deps.

## Global Constraints

- Plugin under edit: `plugins/reframe/` (reframe **v0.3.0 → v0.4.0** in this plan).
- `categories/` and `templates/` live at **plugin root** (`plugins/reframe/`); `references/` and `scripts/` live under `plugins/reframe/skills/site-redesign/`.
- Skill paths in docs resolve via `${CLAUDE_PLUGIN_ROOT}`.
- The Phase-9 token contract in `SKILL.md` lists tokens as "the deduplicated union across all six templates. Do not add or rename tokens." This plan **deliberately adds exactly two** tokens (`{{PHASE_MARKERS}}`, `{{SIGNALS_FIRED}}`); update the contract count from **36 → 38** wherever it appears.
- Run all script tests from `plugins/reframe/skills/site-redesign/scripts/` with `python3 -m pytest -q`.
- Commit after every task. Conventional-commit prefixes: `feat(reframe):` / `fix(reframe):` / `docs(reframe):`.
- Do NOT delete or rewrite the analysis doc at `docs/research/reframe-session-analysis/session-analysis.md` — it is the spec; it ships with this branch.

## File Structure

| Path | Responsibility | Tasks |
|------|----------------|-------|
| `plugins/reframe/templates/INDEX.md.template` | Adds the `## Run log` block (2 new tokens) | T1 |
| `plugins/reframe/skills/site-redesign/scripts/check-output-complete.sh` | Substance gate: asserts phase markers + `[PACK-LOADED:]` present | T1 |
| `plugins/reframe/skills/site-redesign/scripts/test_check_output_complete.py` | New pytest for the gate (subprocess) | T1 |
| `plugins/reframe/skills/site-redesign/SKILL.md` | Phase-7 split; token-contract bump; new-rule wiring; recon branch; Write-not-touch; color step | T1,T2,T3,T5,T7 |
| `plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md` | Lossy-render rule, per-route render check, Playwright rung, pageshot two-step | T3,T4 |
| `plugins/reframe/skills/site-redesign/references/tool-availability.md` | Playwright rung, Jina-451 note, pageshot two-step | T4 |
| `plugins/reframe/categories/b2b-industrial.md` | New 6th category pack | T6 |
| `plugins/reframe/skills/site-redesign/scripts/test_detect_category.py` | New B2B-detection test case | T6 |
| `plugins/reframe/.claude-plugin/plugin.json` | Version 0.3.0 → 0.4.0 | T8 |
| `plugins/reframe/CHANGELOG.md` | 0.4.0 entry | T8 |

---

## Task 1: Substance gate — Run log block + `check-output-complete.sh` enforcement

The two worst failures (category detection nearly skipped; phase markers dropped) passed the form-only gate. Make them fail-closed. Evidence must live in a committed file → formalise `## Run log` in `INDEX.md`, then have the gate assert it.

**Files:**
- Modify: `plugins/reframe/templates/INDEX.md.template`
- Modify: `plugins/reframe/skills/site-redesign/scripts/check-output-complete.sh`
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md` (token contract 36→38; INDEX uses new tokens; gate description)
- Test: `plugins/reframe/skills/site-redesign/scripts/test_check_output_complete.py`

**Interfaces:**
- Produces (consumed by T2's Phase-9 wiring): `INDEX.md` must contain a `## Run log` section with a `**Phase markers:**` line listing `[P1✓]`…`[P9✓]` (or `[GREENFIELD-MODE]`) and a `**Signals fired:**` line containing `[PACK-LOADED:<cat>]` (or `[GREENFIELD-MODE]`).
- Produces: `check-output-complete.sh` exit 1 when those are absent; exit 0 when present (in addition to existing file/token checks).
- New tokens: `{{PHASE_MARKERS}}`, `{{SIGNALS_FIRED}}`.

- [ ] **Step 1: Write the failing test**

Create `plugins/reframe/skills/site-redesign/scripts/test_check_output_complete.py`:

```python
"""Tests for check-output-complete.sh — the reframe output substance gate."""
import subprocess
from pathlib import Path

SCRIPT = Path(__file__).parent / "check-output-complete.sh"
SIX_FILES = ["INDEX.md", "brief.md", "run-sheet.md",
             "content-inventory.md", "ia-map.md", "current-critique.md"]

GOOD_RUNLOG = (
    "## Run log\n"
    "**Phase markers:** [P1✓] [P2✓] [P3✓] [P4✓] [P5✓] "
    "[P6✓] [P7✓] [P8✓] [P9✓]\n"
    "**Signals fired:** [PACK-LOADED:local-service] [TECH-STACK-ABSENT]\n"
)

def _make_output(tmp_path: Path, *, index_extra: str = GOOD_RUNLOG) -> Path:
    d = tmp_path / "redesign"
    d.mkdir()
    for f in SIX_FILES:
        body = "# heading\n\nreal content here\n"
        if f == "INDEX.md":
            body += "\n" + index_extra
        (d / f).write_text(body, encoding="utf-8")
    return d

def _run(d: Path):
    return subprocess.run(["bash", str(SCRIPT), str(d)],
                          capture_output=True, text=True)

def test_complete_run_passes(tmp_path):
    r = _run(_make_output(tmp_path))
    assert r.returncode == 0, r.stdout + r.stderr

def test_missing_phase_marker_fails(tmp_path):
    bad = GOOD_RUNLOG.replace(" [P5✓]", "")  # drop P5
    r = _run(_make_output(tmp_path, index_extra=bad))
    assert r.returncode == 1
    assert "P5" in r.stdout or "phase marker" in r.stdout.lower()

def test_missing_pack_loaded_fails(tmp_path):
    bad = "## Run log\n**Phase markers:** " + " ".join(
        f"[P{i}✓]" for i in range(1, 10)) + "\n**Signals fired:** none\n"
    r = _run(_make_output(tmp_path, index_extra=bad))
    assert r.returncode == 1
    assert "PACK-LOADED" in r.stdout

def test_greenfield_index_only_passes(tmp_path):
    # Greenfield halts after INDEX.md only; gate must not demand the other five.
    d = tmp_path / "redesign"
    d.mkdir()
    (d / "INDEX.md").write_text(
        "# x\n\n## Run log\n**Phase markers:** [GREENFIELD-MODE]\n"
        "**Signals fired:** [GREENFIELD-MODE]\n", encoding="utf-8")
    r = _run(d)
    assert r.returncode == 0, r.stdout + r.stderr

def test_unresolved_token_still_fails(tmp_path):
    d = _make_output(tmp_path)
    (d / "brief.md").write_text("# x\n\n{{UNRESOLVED}}\n", encoding="utf-8")
    r = _run(d)
    assert r.returncode == 1
    assert "{{UNRESOLVED}}" in r.stdout
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd plugins/reframe/skills/site-redesign/scripts && python3 -m pytest test_check_output_complete.py -q`
Expected: FAILs — `test_missing_phase_marker_fails`, `test_missing_pack_loaded_fails`, and `test_greenfield_index_only_passes` fail because the current script has no Run-log logic and hard-requires all six files.

- [ ] **Step 3: Add the Run-log block to `INDEX.md.template`**

Append to `plugins/reframe/templates/INDEX.md.template` (after the existing "How to use" list):

```markdown

## Run log
**Phase markers:** {{PHASE_MARKERS}}
**Signals fired:** {{SIGNALS_FIRED}}
```

- [ ] **Step 4: Implement gate logic in `check-output-complete.sh`**

In `check-output-complete.sh`, after the existing token-check block (just before `# Summary`), insert a greenfield-aware file requirement and the Run-log assertions. Replace the existing **Check 1** loop guard and add **Check 3** as follows.

First, immediately after `OUTPUT_DIR="$1"` validation and `FAILED=0`, detect greenfield:

```bash
# Greenfield runs halt after writing only INDEX.md (SKILL.md Phase 3).
GREENFIELD=0
if [[ -f "$OUTPUT_DIR/INDEX.md" ]] && grep -q '\[GREENFIELD-MODE\]' "$OUTPUT_DIR/INDEX.md"; then
  GREENFIELD=1
fi
```

Then in **Check 1**, skip the five non-INDEX files when greenfield:

```bash
for file in "${EXPECTED_FILES[@]}"; do
  filepath="$OUTPUT_DIR/$file"
  if [[ $GREENFIELD -eq 1 && "$file" != "INDEX.md" ]]; then
    printf "  ${GREEN}ok${RESET}    $file skipped (greenfield)\n"
    continue
  fi
  if [[ ! -f "$filepath" ]]; then
    printf "  ${RED}FAIL${RESET}  Missing: $file\n"; FAILED=1
  elif [[ ! -s "$filepath" ]]; then
    printf "  ${RED}FAIL${RESET}  Empty: $file\n"; FAILED=1
  else
    printf "  ${GREEN}ok${RESET}    $file exists and is non-empty\n"
  fi
done
```

Then add **Check 3** before `# Summary`:

```bash
# Check 3: Run-log substance assertions in INDEX.md
echo ""
echo "Checking run-log (phase markers + pack)..."
INDEX="$OUTPUT_DIR/INDEX.md"
if [[ ! -f "$INDEX" ]]; then
  printf "  ${RED}FAIL${RESET}  INDEX.md missing — cannot verify run log\n"; FAILED=1
elif [[ $GREENFIELD -eq 1 ]]; then
  printf "  ${GREEN}ok${RESET}    greenfield halt recorded\n"
else
  for n in 1 2 3 4 5 6 7 8 9; do
    if ! grep -q "\[P${n}✓\]" "$INDEX"; then
      printf "  ${RED}FAIL${RESET}  Phase marker [P${n}✓] not found in INDEX.md run log\n"
      FAILED=1
    fi
  done
  if ! grep -q '\[PACK-LOADED:' "$INDEX"; then
    printf "  ${RED}FAIL${RESET}  No [PACK-LOADED:<cat>] in INDEX.md — category detection did not run\n"
    FAILED=1
  fi
  if [[ $FAILED -eq 0 ]]; then
    printf "  ${GREEN}ok${RESET}    all phase markers + pack present\n"
  fi
fi
```

Also update the header comment block's "Checks:" list to add: `3. INDEX.md run log lists all phase markers [P1✓]–[P9✓] and a [PACK-LOADED:<cat>] (unless [GREENFIELD-MODE])`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd plugins/reframe/skills/site-redesign/scripts && python3 -m pytest test_check_output_complete.py -q`
Expected: PASS (5 passed). Then run the full suite: `python3 -m pytest -q` → Expected: all previous 37 + new tests pass.

- [ ] **Step 6: Wire the new tokens + gate into SKILL.md**

In `SKILL.md`:
1. Phase-9 token contract line — change "MUST resolve every one of these **36** tokens" → "**38** tokens", and append `` `{{PHASE_MARKERS}}` `{{SIGNALS_FIRED}}` `` to the token list.
2. Phase 9 Action 5 (write `INDEX.md`) — add: "Populate `{{PHASE_MARKERS}}` with the emitted `[P1✓]`…`[P9✓]` (or `[GREENFIELD-MODE]`) and `{{SIGNALS_FIRED}}` with every degradation signal that fired this run, including the `[PACK-LOADED:<cat>]` from Phase 7."
3. Phase 9 Action 7 (completeness check) — append: "The gate now also fails if `INDEX.md` is missing any phase marker or the `[PACK-LOADED:<cat>]` token; resolve by recording the genuine run log (do not fabricate markers for phases you skipped — run them)."

- [ ] **Step 7: Commit**

```bash
git add plugins/reframe/templates/INDEX.md.template \
        plugins/reframe/skills/site-redesign/scripts/check-output-complete.sh \
        plugins/reframe/skills/site-redesign/scripts/test_check_output_complete.py \
        plugins/reframe/skills/site-redesign/SKILL.md
git commit -m "feat(reframe): substance gate — enforce phase markers + PACK-LOADED in INDEX run log"
```

---

## Task 2: Split Phase 7 — strategic question early, category detection stays mandatory

Both sessions independently pulled the same-vs-new-purpose question ahead of the deliverable writes (signal the order is wrong), but `ams` pulling it early is what nearly skipped category detection. Split them.

**Files:**
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md`

**Interfaces:**
- Consumes: T1's gate (Phase 7 must emit `[PACK-LOADED:]`, now gate-enforced).
- Produces: a phase table + Phase-7 text where the *question* is step 4a after crawl and *category detection* remains a hard, separate sub-step feeding Phase 8.

- [ ] **Step 1: Update the phase table**

In the "The 9 phases" table, change the Phase 7 row Writes cell and add a note column footnote. Replace the Phase 7 row with:

```markdown
| 7 | Intent inference + category detect (+ strategic question) | session brief |
```

And immediately under the table add:

```markdown
> **Ordering note (the one allowed flex):** the *strategic question* (P7 step 4) may be asked any time after Phase 4 (crawl) and **must** be asked before writing the deliverable files (P5/P6/P8) — its answer reframes them. **Category detection (P7 step 2) is never skipped or deferred**: it must run and emit `[PACK-LOADED:<cat>]` before Phase 8's pack-cited critique. Asking the question early does NOT license skipping detection.
```

- [ ] **Step 2: Reorder the Phase-7 action steps**

In Phase 7's **Actions** list, reorder so detection is unmissable and the question is explicitly relocatable. Replace step 4 ("Ask the one question…") text with:

```markdown
4. **Ask the one question** (may be asked any time after Phase 4; MUST precede writing `content-inventory.md`/`ia-map.md`/`current-critique.md`): "Redesigning for the same purpose or a new one?" — record as `current purpose (inferred)` vs `target purpose (declared)`. Only human question in the pipeline. **Asking this early does not permit skipping steps 1–3 above** — category detection and `[PACK-LOADED:<cat>]` are mandatory and gate-enforced (see Phase 9).
```

- [ ] **Step 3: Verify the contract text is consistent**

Run: `grep -n "PACK-LOADED\|strategic question\|step 4\|Category detection" plugins/reframe/skills/site-redesign/SKILL.md`
Expected: the ordering note + Phase-7 step 4 both state detection is mandatory; no remaining text says "always in this order" without the documented flex. If `commands/reframe-analyze.md` line ~12 still implies the question is only "before finalising the brief", leave it (consistent) — it already says before finalising.

- [ ] **Step 4: Commit**

```bash
git add plugins/reframe/skills/site-redesign/SKILL.md
git commit -m "fix(reframe): split Phase 7 — strategic question relocatable, category detection mandatory"
```

---

## Task 3: Substance rule — don't infer from lossy render + per-route render check

Jina markdown silently dropped populated sections → seeded false "section empty/broken" findings (only advisor caught them). And a sitemap route (`/book`, priority 0.9) returned a client-side 404 the homepage-only render gate missed.

**Files:**
- Modify: `plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md`
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md` (Phase 3 + Phase 8 wiring)

**Interfaces:**
- Produces: a named rule `[INFER-GUARD]` referenced from Phase 8; a per-route render line in the Phase-3 coverage manifest.

- [ ] **Step 1: Add the lossy-render rule to `crawl-and-coverage.md`**

Under the `### Coverage Manifest` section, append:

```markdown
### Render fidelity — do not infer absence from a lossy render

Markdown crawlers (especially Jina Reader) silently drop content on scroll-reveal / JS-hydrated SPAs: they can under-report nav links and omit whole populated sections. **A markdown crawl is evidence of presence, never evidence of absence.**

Rule `[INFER-GUARD]`: before asserting in any output file that a section/page is *empty, missing, broken, or absent*, cross-check against a second source — a JS render (Chrome MCP / local Playwright render, Phase 4) or the raw HTML (`curl -s -H "X-Return-Format: html" "https://r.jina.ai/{url}"`). If the two disagree, trust the JS render and downgrade the claim. Never ship an "empty section" finding verified by markdown alone.

### Per-route render check

A `200` status on a route is not proof it renders content — client-rendered apps return a `200` shell then 404 in JS. For each sampled route in the coverage manifest, record **renders-content: yes/no** (does the rendered body contain the route's expected headings/prose, or only the app shell?). Flag any sitemap-listed route that returns a content-less shell as a finding, not as a healthy page.
```

- [ ] **Step 2: Wire the rule into SKILL.md Phase 3 and Phase 8**

In `SKILL.md` Phase 3 Actions, after the Coverage-manifest bullet (item 3), add:

```markdown
   - **Per-route render check:** for each sampled route, record whether it renders real content or only an app shell (a client-side 404 returns a 200 shell). Flag shell-only routes as findings. See `references/crawl-and-coverage.md` → "Per-route render check".
```

In `SKILL.md` Phase 8 Actions, after item 2 (the finding fields), add:

```markdown
   - **`[INFER-GUARD]`:** do NOT record a "section empty / content missing / link broken" finding unless it is verified against a JS render or raw HTML — not markdown alone (markdown crawlers drop JS-revealed content). See `references/crawl-and-coverage.md` → "Render fidelity".
```

- [ ] **Step 3: Verify the rule is wired into both files**

Run: `grep -n "INFER-GUARD\|Per-route render\|Playwright" plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md plugins/reframe/skills/site-redesign/SKILL.md`
Expected: `INFER-GUARD` appears in both files; `Per-route render` appears in both; `Playwright` present (spelled correctly).

- [ ] **Step 4: Commit**

```bash
git add plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md \
        plugins/reframe/skills/site-redesign/SKILL.md
git commit -m "fix(reframe): add INFER-GUARD render-fidelity rule + per-route render check"
```

---

## Task 4: Tool rungs — local Playwright fallback, Jina pageshot two-step, Jina 451 note

Chrome DevTools MCP single-instance lock ("browser already running… use `--isolated`") blocked the only sanctioned screenshot path; the agent had to invent a local Playwright render. Jina pageshot returns a signed URL, not a PNG. Jina 451 = geo/legal block.

**Files:**
- Modify: `plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md`
- Modify: `plugins/reframe/skills/site-redesign/references/tool-availability.md`

**Interfaces:**
- Produces: a 5th screenshot/render fallback rung (local Playwright) and a documented Chrome-MCP-lock recovery, referenced by `[INFER-GUARD]` (Task 3) and Phase 4.

- [ ] **Step 1: Add the local-Playwright rung + lock recovery to `crawl-and-coverage.md`**

In `### Screenshots`, after the "Chrome MCP `take_screenshot`" item (4), add item 5 and a lock note:

```markdown
5. **Local headless browser (Playwright/Puppeteer)** — if the repo has `node_modules/playwright` or `npx playwright` is available, render and screenshot locally:
   ```bash
   npx -y playwright screenshot --full-page "{url}" .crawl/screenshots/{slug-path}.png
   ```
   This is the most reliable rung when Chrome DevTools MCP is locked by another session.

**Chrome MCP "browser is already running / use --isolated" lock:** the MCP profile is single-instance. If `new_page`/`list_pages` errors with a lock message, do NOT retry-loop — either reuse the existing page via `list_pages` → `select_page`, or fall straight through to rung 5 (local Playwright). Only ask the user to `pkill -f chrome-devtools-mcp` as a last resort.
```

Also in the same file's render-escalation sequence (Phase 3, the Chrome MCP item 4), add a final line: "If Chrome MCP is locked, fall through to a local Playwright render (see Screenshots rung 5)."

- [ ] **Step 2: Add the pageshot two-step + Jina 451 note to `tool-availability.md`**

In the Jina Reader "Usage pattern" block, replace the screenshot line comment with the explicit two-step:

```bash
# Screenshot (pageshot) — returns a SIGNED URL (text), not image bytes; download it:
PAGESHOT_URL=$(curl -s -H "X-Respond-With: pageshot" "https://r.jina.ai/{target_url}")
curl -sL "$PAGESHOT_URL" -o .crawl/screenshots/{slug-path}.png
```

And under the Jina "Limit:" bullet, add:

```markdown
- HTTP 451 from `r.jina.ai` = geo/legal block on the target (seen on some EU/Greek sites); treat Jina as unavailable for that target and fall through the chain (Firecrawl → Crawl4AI → local Playwright). Not a transient error — do not retry.
```

- [ ] **Step 3: Verify**

Run: `grep -n "playwright\|--isolated\|already running\|451\|PAGESHOT_URL" plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md plugins/reframe/skills/site-redesign/references/tool-availability.md`
Expected: local Playwright rung in crawl-and-coverage; lock recovery present; `451` + `PAGESHOT_URL` in tool-availability.

- [ ] **Step 4: Commit**

```bash
git add plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md \
        plugins/reframe/skills/site-redesign/references/tool-availability.md
git commit -m "docs(reframe): add local-Playwright rung, Chrome-lock recovery, Jina pageshot two-step + 451 note"
```

---

## Task 5: Prior-recon reuse branch + Write-not-touch reinforcement

`ams` built the whole redesign on a pre-existing beacon recon corpus — the skill has no path for this, so the agent improvised and only advisor reminded it to read ALL recon files and be honest in provenance tokens. Also `ams` created scaffolds via Bash heredoc (despite "Write, not touch") → forced redundant Reads.

**Files:**
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md`

**Interfaces:**
- Consumes: existing tokens `{{SAMPLING_NOTE}}`, `{{AUDITED_COUNT}}`, `{{COVERAGE_MANIFEST}}`.
- Produces: a `[RECON-REUSE]` branch + provenance wording, used by Phases 3–5 and 9.

- [ ] **Step 1: Add the recon-reuse branch to Phase 1**

In `SKILL.md` Phase 1 Actions, after item 4 (tool detection), add:

```markdown
5. **Check for prior beacon recon:** if `docs/sites/{slug}/research/` (or legacy `docs/research/{slug}/`) exists, log `[RECON-REUSE]` and read **every** file in it (not just `site-map.md`/`tech-stack.md` — include `osint.md`, `INDEX.md`, any `claude-design-inputs`/competitive/performance files). The recon corpus becomes a content source for Phases 3–5; still **live-re-verify the homepage** (render gate) and spot-check 1–2 key routes. Never treat recon as a substitute for the render gate.
```

- [ ] **Step 2: Add provenance honesty to Phase 9**

In `SKILL.md` Phase 9 Actions, after item 4 (finalize the phase-5/6/8 files), add:

```markdown
   - **If `[RECON-REUSE]` fired:** `{{SAMPLING_NOTE}}` must state plainly that the audit reused a prior beacon recon and live-re-verified only the homepage + key routes (e.g. "re-verified recon synthesis, not a fresh crawl of all N URLs"); `{{AUDITED_COUNT}}` counts only pages actually (re-)read this run. Do not imply a full fresh crawl.
```

- [ ] **Step 3: Reinforce Write-not-touch in Phase 1**

In `SKILL.md` Phase 1 Action 2, append to the existing "(Write, not touch)" instruction:

```markdown
 — create each file with the **Write tool**, never `touch`/Bash heredoc/`>`-redirect. Bash-created files are untracked by the harness and force a redundant Read before every later Write (observed cost: 6 wasted Reads in a prior run).
```

- [ ] **Step 4: Add `[RECON-REUSE]` to the degradation-signals table**

In the "Graceful degradation signals" table, add a row:

```markdown
| `[RECON-REUSE]` | A prior beacon recon exists at `docs/sites|research/{slug}/research/`; its files were read as a content source and the homepage live-re-verified. Provenance recorded in `{{SAMPLING_NOTE}}`. |
```

- [ ] **Step 5: Verify**

Run: `grep -n "RECON-REUSE\|Write tool\|every. *file\|SAMPLING_NOTE" plugins/reframe/skills/site-redesign/SKILL.md`
Expected: `[RECON-REUSE]` in Phase 1, Phase 9, and the signals table; Write-tool reinforcement present.

- [ ] **Step 6: Commit**

```bash
git add plugins/reframe/skills/site-redesign/SKILL.md
git commit -m "feat(reframe): add [RECON-REUSE] branch + provenance honesty; reinforce Write-not-touch"
```

---

## Task 6: B2B / industrial-distributor category pack

`ecommerce` won on dead WooCommerce demo pages for a no-checkout B2B supplier (`amarsolutions`). Add a dedicated pack; `detect-category.py` auto-discovers it via glob (no code change), so this is pack + a detection test.

**Files:**
- Create: `plugins/reframe/categories/b2b-industrial.md`
- Modify: `plugins/reframe/skills/site-redesign/scripts/test_detect_category.py`

**Interfaces:**
- Consumes: `detect-category.py` `load_packs()` glob + `detect_signals` inline-list convention (`["a","b"]`).
- Produces: category key `b2b-industrial`.

- [ ] **Step 1: Write the failing detection test**

Append to `plugins/reframe/skills/site-redesign/scripts/test_detect_category.py` (match the file's existing test style — it imports/loads the real `categories/` dir; if it uses a fixtures dir, mirror that pattern instead):

```python
def test_b2b_industrial_wins_on_distributor_corpus(tmp_path, run_detect):
    # run_detect is the existing helper that calls detect-category against the
    # real categories/ dir with a corpus file. If the suite uses a different
    # harness, adapt to it — the assertion is what matters.
    corpus = tmp_path / "corpus.md"
    corpus.write_text(
        "Request a quote for our industrial valves and marine spare parts. "
        "We are an authorized distributor and OEM supplier. Datasheet PDF, "
        "MOQ, lead time, bulk pricing, RFQ. Wholesale B2B. Ship spares, "
        "on-board repair, technical specifications.", encoding="utf-8")
    result = run_detect(corpus)
    assert result["winner"] == "b2b-industrial", result
```

If `test_detect_category.py` has no reusable `run_detect` fixture, add this minimal one near the top:

```python
import json, subprocess, sys
from pathlib import Path
import pytest

SCRIPTS = Path(__file__).parent
CATEGORIES = SCRIPTS.parent.parent.parent / "categories"  # plugins/reframe/categories

@pytest.fixture
def run_detect():
    def _run(corpus_path):
        out = subprocess.run(
            [sys.executable, str(SCRIPTS / "detect-category.py"),
             "--categories", str(CATEGORIES), "--corpus", str(corpus_path)],
            capture_output=True, text=True, check=True)
        return json.loads(out.stdout)
    return _run
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd plugins/reframe/skills/site-redesign/scripts && python3 -m pytest test_detect_category.py -k b2b -q`
Expected: FAIL — winner is `ecommerce` or `generic`, not `b2b-industrial` (pack doesn't exist yet).

- [ ] **Step 3: Create the pack**

Create `plugins/reframe/categories/b2b-industrial.md`:

```markdown
---
category: b2b-industrial
display_name: B2B / Industrial Distributor
detect_signals: ["request a quote", "request quote", "RFQ", "get a quote", "quote", "datasheet", "data sheet", "spec sheet", "technical specifications", "MOQ", "minimum order", "lead time", "bulk pricing", "wholesale", "distributor", "authorized distributor", "OEM", "supplier", "spare parts", "spares", "industrial", "manufacturer", "catalogue", "catalog", "part number", "SKU", "marine", "valves", "bearings", "on-board repair", "after-sales", "B2B"]
---

# B2B / Industrial Distributor — Redesign Pack

## Redesign priorities
1. The primary conversion is **"Request a Quote" / RFQ**, not checkout — even if a WooCommerce/store plugin is installed, do not optimise a cart funnel; optimise the quote/enquiry path and the product-find path that feeds it.
2. Make the catalogue **findable and filterable** — buyers arrive knowing a part number, brand, or spec; surface search, category filters, and part-number lookup before marketing copy.
3. Every product/category page must answer "can they supply *my* exact part, in *my* quantity, in *my* timeframe?" — datasheet, part number, MOQ, lead time, and a quote CTA on every PDP.
4. Establish supplier credibility: years in business, brands/OEMs represented, certifications (ISO, class approvals), and real client/sector logos — B2B trust is institutional, not consumer-emotional.
5. Treat the site as a **sales-enablement tool**: downloadable catalogues/brochures, clear contact routes to a human (phone, email, named reps), and fast response promises.

## Conversion patterns
- **"Request a Quote" as the single primary CTA** — per product, per category, and global. A quote form captures part/brand/quantity/timeframe; never force account creation first.
- **Part-number / brand search** prominent in the header — the fastest path to "do you have it?".
- **Downloadable assets** (catalogue PDF, datasheets, brochures) as a secondary conversion and lead capture.
- **Dead/demo store pages are a liability** — if a checkout exists but is non-functional or unused, remove or convert it to enquiry; a broken cart erodes B2B trust faster than no cart.

## Trust signals
- Years/heritage stated concretely (founding year + "X years supplying Y").
- Brands / OEMs / principals represented (logos, named lines).
- Certifications and class approvals (ISO 9001, marine class societies, industry bodies).
- Sector/client references and case examples; real premises, warehouse, and team photos.
- Named contacts and fast-response commitments (B2B buyers want a human and an SLA).

## IA conventions
- **Nav:** Home / Products (or Catalogue, with categories) / Brands / About / Contact / Request a Quote.
- **Home:** what you supply + to whom → search/part-lookup → product/category cards → brands represented → credibility strip (years, certs) → quote CTA.
- **Products:** category index (filterable) → product/category pages with specs, datasheet, part number, MOQ, lead time, quote CTA.
- **Brands:** the OEMs/principals carried, each linking to its catalogue subset.
- **Journey shape:** technical search → product/category page → spec/datasheet check → Request a Quote → human follow-up.

## Design-system seed (opinionated)
- Palette: #14304F (industrial navy, primary), #0E7C9B (technical cyan, CTA/links), #F4F6F8 (surface/light grey), #FFFFFF (base), #2A2F36 (body text), #E2A100 (caution/accent for badges only). Reads "engineering-grade and dependable", not consumer-retail.
- Type: body — Inter or IBM Plex Sans (technical clarity, good at dense spec tables; IBM Plex if Greek/Cyrillic glyphs needed); headings — same family Bold; mono (IBM Plex Mono / JetBrains Mono) for part numbers and spec values.
- Spacing/radius/motion: dense but scannable spec tables; radius 4–6px (engineered, not playful); minimal motion (120ms ease); no decorative animation.
- Borders vs shadows: 1px borders dominate (tables, cards, spec rows); shadows reserved for dropdowns/overlays. Tables are a first-class component, not an afterthought.

## Reference sites
- **RS Components (rs-online.com)** — part-number search, filterable catalogue, datasheets, technical depth without consumer fluff.
- **Grainger (grainger.com)** — industrial catalogue scale, strong search/filtering, quote/account paths.
- **Misumi (misumi.com)** — configurable parts, spec-first product pages.

## Anti-references & strict NOs
- **Consumer-ecommerce templates** with lifestyle hero imagery and "Add to Cart" emotional copy — wrong register entirely for a quote-driven B2B buyer.
- **Dead WooCommerce/demo store pages** left live (the `amarsolutions` failure) — they make the site score as ecommerce and signal neglect.

Strict NOs:
- NO forced cart/checkout for products that are actually quote-only.
- NO hiding part numbers, datasheets, MOQ, or lead time behind a contact wall.
- NO account-creation gate before a quote request.
- NO stock "handshake / corporate teamwork" imagery in place of real product/warehouse/team photos.
- NO burying the catalogue under marketing pages — search and categories come first.
- NO vague "quality products and solutions" copy — name the brands, specs, and sectors.

## Emphasize in the brief
1. **Quote-path audit:** map the current path from "I know my part" to "I've sent an RFQ" — count clicks and dead ends; any non-functional store pages are removal/convert targets.
2. **Catalogue findability:** is there part-number/brand search and category filtering? If not, that is the priority build.
3. **Credibility surface:** are years-in-business, brands represented, and certifications visible on the homepage and product pages, not just buried in About?
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd plugins/reframe/skills/site-redesign/scripts && python3 -m pytest test_detect_category.py -k b2b -q`
Expected: PASS. Then full suite `python3 -m pytest -q` → all pass (confirm the new pack didn't break existing detection expectations; if an existing test asserted a specific winner on a corpus that now also matches B2B signals, inspect — the B2B signals are quote/spec-specific and should not steal `local-service`/`ecommerce` fixtures, but verify).

- [ ] **Step 5: Commit**

```bash
git add plugins/reframe/categories/b2b-industrial.md \
        plugins/reframe/skills/site-redesign/scripts/test_detect_category.py
git commit -m "feat(reframe): add b2b-industrial category pack (6th pack) + detection test"
```

---

## Task 7: Color-sampling micro-step for the design-system seed

Both briefs' seed hex were guesses ("sample exact brand hex from the live capture; these are the targets"). Add an optional measured step.

**Files:**
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md` (Phase 4)
- Modify: `plugins/reframe/skills/site-redesign/references/brief-format.md` (seed block note)

**Interfaces:**
- Consumes: the homepage screenshot from Phase 4 / homepage HTML.
- Produces: measured brand-hex values feeding `{{DESIGN_DIRECTION_SEED}}` §7.

- [ ] **Step 1: Add the sampling step to Phase 4**

In `SKILL.md` Phase 4 Actions, after item 6 (save screenshots), add:

```markdown
7. **Sample brand colours (best-effort):** extract the dominant brand hex values from the homepage — grep the page CSS/inline styles for `#rrggbb`/`rgb()` on the logo/header/primary-CTA, or sample the homepage screenshot. Record the measured values for the §7 seed's KEEP palette. If unsampleable, mark the seed palette "(approximate — sample on capture)" so it is not presented as measured.
```

- [ ] **Step 2: Note it in `brief-format.md`**

In the "Design-System Seed Block Format" section, after the "Seed values must be numbers and hex codes." line, add:

```markdown
**Brand-KEEP hex must be measured, not guessed, when possible** — use the Phase-4 colour-sampling step (homepage CSS/screenshot). If a value is an unverified target rather than a sampled brand colour, label it "(approx — sample on capture)". Do not present guessed hex as the site's actual brand colour.
```

- [ ] **Step 3: Verify**

Run: `grep -n "Sample brand colours\|approx — sample\|colour-sampling" plugins/reframe/skills/site-redesign/SKILL.md plugins/reframe/skills/site-redesign/references/brief-format.md`
Expected: sampling step in Phase 4; measured-not-guessed note in brief-format.

- [ ] **Step 4: Commit**

```bash
git add plugins/reframe/skills/site-redesign/SKILL.md \
        plugins/reframe/skills/site-redesign/references/brief-format.md
git commit -m "feat(reframe): add best-effort brand-colour sampling step for the seed palette"
```

---

## Task 8: Version bump, CHANGELOG, final full-suite gate

**Files:**
- Modify: `plugins/reframe/.claude-plugin/plugin.json`
- Modify: `plugins/reframe/CHANGELOG.md`
- (Already present from setup) `docs/research/reframe-session-analysis/session-analysis.md`

- [ ] **Step 1: Bump the version**

In `plugins/reframe/.claude-plugin/plugin.json`, change `"version": "0.3.0"` → `"version": "0.4.0"`.

- [ ] **Step 2: Add the CHANGELOG entry**

Insert at the top of `plugins/reframe/CHANGELOG.md` (after the `# Changelog` / intro line, above `## 0.3.0`):

```markdown
## 0.4.0 — 2026-06-27

Hardening from two real redesign sessions (`amarsolutions.gr`, `trustyourphysio.com`) — see `docs/research/reframe-session-analysis/`. The driving finding: clean output depended on the harness `advisor()` rescuing both runs; these changes move those rescues into the skill.

- **Substance gate** — `check-output-complete.sh` now fails closed unless `INDEX.md`'s new `## Run log` lists all phase markers `[P1✓]`–`[P9✓]` and a `[PACK-LOADED:<cat>]` (greenfield-aware). Two new tokens `{{PHASE_MARKERS}}`/`{{SIGNALS_FIRED}}` (contract 36→38).
- **`[INFER-GUARD]`** — never assert a section is empty/missing/broken from a lossy markdown crawl; cross-check a JS render or raw HTML first. Plus a per-route render check (catches client-side 404 shells).
- **Phase 7 split** — the strategic question is relocatable (after crawl, before deliverables) but category detection is mandatory and gate-enforced.
- **`[RECON-REUSE]` branch** — explicit path for reusing a prior beacon recon (read ALL recon files; live-re-verify homepage; honest provenance tokens).
- **Tool rungs** — local Playwright screenshot/render fallback + Chrome-MCP `--isolated`/lock recovery; Jina pageshot two-step (signed URL → download); Jina HTTP 451 = geo-block note.
- **New `b2b-industrial` category pack** (6th) — quote/RFQ-driven distributors that previously mis-detected as `ecommerce` on dead store pages.
- **Brand-colour sampling** step so seed palettes are measured, not guessed. Reinforced "Write tool, not touch" in Phase 1.
```

- [ ] **Step 3: Final full-suite gate**

Run: `cd plugins/reframe/skills/site-redesign/scripts && python3 -m pytest -q`
Expected: all tests pass (37 original + new gate tests + new B2B detection test).

Run: `grep -rn "{{" plugins/reframe/templates/INDEX.md.template` → Expected: shows `{{PHASE_MARKERS}}`/`{{SIGNALS_FIRED}}` (templates legitimately contain tokens; this is just a sanity check that they're the only additions).

- [ ] **Step 4: Commit**

```bash
git add plugins/reframe/.claude-plugin/plugin.json plugins/reframe/CHANGELOG.md \
        docs/research/reframe-session-analysis/session-analysis.md
git commit -m "chore(reframe): v0.4.0 — session-fixes changelog + analysis doc"
```

---

## Self-Review (completed during planning)

**1. Spec coverage** — every ranked rec in `session-analysis.md` maps to a task: substance gate (T1), INFER-GUARD/false-claims (T3), category-detection precondition (T1+T2), local-Playwright rung (T4), recon-reuse (T5), Phase-7 split (T2), stop-scaffolding/Write-not-touch (T5), per-route render (T3), B2B pack (T6), pageshot two-step (T4), color sampling (T7), Jina-451 (T4). Phase-marker enforcement (form item) folded into T1.

**2. Placeholder scan** — code/markdown steps contain literal content. The one intentional typo ("Playriht") is fixed within T3 Step 3 and asserted by grep.

**3. Type/contract consistency** — token count stated as 36→38 everywhere; new tokens `{{PHASE_MARKERS}}`/`{{SIGNALS_FIRED}}` defined in T1 and consumed in T1 Step 6; `[INFER-GUARD]`, `[RECON-REUSE]` used consistently across SKILL.md + references + CHANGELOG; gate behaviour (greenfield-aware) consistent between `check-output-complete.sh` and its tests.
```
