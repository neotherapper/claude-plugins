# Beacon Workspace Migration (PR-C) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate beacon's output workspace from `docs/research/{slug}/` to the unified `docs/sites/{slug}/research/`, with a read-only legacy fallback, bumping beacon to v0.7.0.

**Architecture:** Pure path/string migration across beacon's skill, command, agent, hook, schema, and doc files. Write-side paths move to `docs/sites/{slug}/research/`. Read-side discovery (`site-intel`, `beacon:load`, the Phase 2.5 cross-scan) becomes dual-path: new location first, legacy `docs/research/` as a deprecated read-only fallback. Beacon's slug derivation is aligned to the repo's canonical rule. No runnable code is involved — these are Markdown/JSON/bash skill instructions — so verification is targeted `grep` with expected output plus a repo-wide audit, not a unit-test suite (beacon has no test harness).

**Tech Stack:** Markdown skill files, bash snippets inside skills, JSON schema, shell hook.

## Global Constraints

Every task's requirements implicitly include this section. Copy values verbatim.

- **New write path:** `docs/sites/{slug}/research/` (replaces `docs/research/{slug}/`).
- **Legacy path:** `docs/research/{slug}/` — **read-only fallback, deprecated in 0.7.0, removed in 0.8.0.** Never write here in 0.7.0.
- **Canonical slug rule** (from `docs/SLUG_RULES.md` / unification design §4) — beacon MUST adopt this exact derivation:
  ```bash
  SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
  ```
  Examples that must hold: `https://www.example.com/` → `example-com`; `https://api.example.com/v2` → `api-example-com`; `http://example.com:8080` → `example-com`; `https://Example.COM` → `example-com`.
- **Glob scoping is load-bearing.** After unification a `docs/sites/{slug}/` may contain `redesign/` (reframe) **without** `research/` (beacon). Every beacon glob over the shared workspace MUST be scoped to `*/research/`, **never** bare `docs/sites/*/`. Concrete collision to prevent: `docs/sites/trustyourphysio-com/redesign/INDEX.md` exists today and must NOT be picked up as beacon research. Canonical forms:
  - New: `find docs/sites -path '*/research/INDEX.md'`
  - Legacy: `find docs/research -maxdepth 2 -name INDEX.md`
  - Union the two.
- **Dual-path read semantics:** check new (`docs/sites/{slug}/research/`) first; fall back to legacy (`docs/research/{slug}/`); if both exist for a slug, **prefer the newest by `INDEX.md` mtime** and note the legacy folder exists — never silently merge.
- **HARD GUARD — never touch `plugins/beacon/.evals/**`** (historical baselines; ~94 of the repo's `docs/research` references live there). No task edits, reads-for-edit, or `git add`s anything under `.evals/`.
- **Do NOT rewrite history-of-record:** leave historical CHANGELOG entries, past design/plan docs under `docs/plugins/beacon/{designs,plans}/`, and references to specific external artifacts that physically live at the old path (`docs/research/spitogatos/...`, `docs/research/beacon-session-analysis/...`). Only change references that describe beacon's **current or future** output location.
- **Version:** `plugins/beacon/.claude-plugin/plugin.json` 0.6.3 → **0.7.0**.
- **Commit hygiene:** the working tree has untracked smoke/scratch artifacts (`docs/sites/`, `docs/redesign/`, `docs/research/kayuwriting-com/`, `plugins/beacon/technologies/REGISTRY.md`, `plugins/beacon/technologies/webflow/`). **Never `git add -A` or `git add .`** — each task stages only the explicit file paths it edited.
- **Test gate:** `scripts/validate-marketplace.sh` must stay green (0 errors; one pre-existing idea-forge warning is acceptable). There is no beacon unit-test harness — do not invent one.

---

## File Structure

Files modified, grouped by task (all disjoint — no two tasks touch the same file):

| Task | Files |
|------|-------|
| T1 | `plugins/beacon/skills/site-recon/SKILL.md` |
| T2 | `plugins/beacon/skills/site-recon/references/{output-synthesis,browser-recon,tool-availability}.md` |
| T3 | `plugins/beacon/agents/site-analyst.md`, `plugins/beacon/hooks/session-start.sh`, `plugins/beacon/commands/beacon-analyze.md`, `plugins/beacon/schemas/output.schema.json` |
| T4 | `plugins/beacon/skills/site-intel/SKILL.md`, `plugins/beacon/commands/beacon-load.md` |
| T5 | `plugins/beacon/.claude-plugin/plugin.json`, `plugins/beacon/CHANGELOG.md` |
| T6 | `plugins/beacon/README.md`, `README.md`, `AGENTS.md`, `docs/GLOSSARY.md`, `docs/platform/{cursor,copilot,opencode,gemini-cli}.md`, `docs/plugins/beacon/{_index,DECISIONS,ROADMAP,TESTING}.md`, `docs/MODULAR_KNOWLEDGE_PACKS.md` |

---

## Task 1: Write-side paths + slug + cross-scan + coexistence (`site-recon/SKILL.md`)

**Files:**
- Modify: `plugins/beacon/skills/site-recon/SKILL.md`

**Interfaces:**
- Produces: the canonical on-disk layout `docs/sites/{slug}/research/{INDEX.md,tech-stack.md,site-map.md,constants.md,api-surfaces/,specs/,scripts/,discovered_domains.txt}` that T2–T6 reference. The slug value is derived by the canonical rule.

This file contains the write-side paths in both its skim and detailed regions, so the same change appears more than once — change **every** occurrence. Do not restructure or de-duplicate the file (out of scope).

- [ ] **Step 1: Replace every write-side `docs/research/${SLUG}/` and `docs/research/{site-slug}/` with the new path**

In `plugins/beacon/skills/site-recon/SKILL.md`, change each of these to `docs/sites/...research/...`:
- Frontmatter (line ~3): `...complete persistent docs/research/{site-name}/ folder.` → `...complete persistent docs/sites/{site-slug}/research/ folder.`
- Layout tree header (line ~16): `docs/research/{site-slug}/` → `docs/sites/{site-slug}/research/`
- Slug prose (line ~29–30): keep the slug examples but ensure they describe the folder under `docs/sites/{site-slug}/research/`.
- Scaffold mkdir (line ~222): `mkdir -p docs/research/${SLUG}/{api-surfaces,specs,scripts}` → `mkdir -p docs/sites/${SLUG}/research/{api-surfaces,specs,scripts}`
- The four empty-`Write` stubs (lines ~265–268): `Write docs/research/${SLUG}/INDEX.md` → `Write docs/sites/${SLUG}/research/INDEX.md` (and likewise `tech-stack.md`, `site-map.md`, `constants.md`).
- Phase 1.5 `discovered_domains.txt` writes (lines ~123 and ~248): `docs/research/${SLUG}/discovered_domains.txt` → `docs/sites/${SLUG}/research/discovered_domains.txt`; and the "Output: ... saved to `docs/research/{SLUG}/discovered_domains.txt`" prose (lines ~151, ~311) → `docs/sites/{SLUG}/research/discovered_domains.txt`.

Leave the bare-domain extraction `sed` snippets (lines ~119, ~244, `sed -E 's|https?://||;s|/.*||'`) unchanged — those dedupe discovered domains, they are not the slug.

- [ ] **Step 2: Adopt the canonical slug rule**

Replace the slug derivation (line ~221):
```bash
SLUG=$(echo "{url}" | sed -E 's|https?://(www\.)?||;s|/.*||;s|\.|-|g')
```
with the canonical rule (adds lowercase + `:port` strip):
```bash
# Canonical slug rule (docs/SLUG_RULES.md) — must match reframe for cross-module interop
SLUG=$(printf '%s' "{url}" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
```
Also update the "Strip `www.` before slugifying" prose (line ~30) to point at `docs/SLUG_RULES.md` as the canonical source and keep the existing examples (they still hold).

- [ ] **Step 3: Make the Phase 2.5 cross-scan dual-root and `research/`-scoped**

The Phase 2.5 "Data Source Inventory" cross-scans previously-researched sites. It currently scans only legacy and is unscoped. Update **both** occurrences (the `find` at lines ~183 and ~345, and the glob prose at lines ~214 and ~376) to union new + legacy, scoped to `*/research/`:

Replace the `find docs/research/ -name "INDEX.md"` form with:
```bash
# Inventory previously-researched sites across the new and legacy workspaces.
# New path is scoped to */research/ so reframe's redesign/ folders are NOT picked up.
{ find docs/sites -path '*/research/INDEX.md' 2>/dev/null; \
  find docs/research -maxdepth 2 -name 'INDEX.md' 2>/dev/null; } | sort -u | \
while IFS= read -r research; do
  # ...existing per-INDEX handling...
done
```
Preserve whichever read style the surrounding block already uses (the `-print0 | while IFS= read -r -d ''` variant at line ~345 should keep null-delimited reads; adapt the union accordingly using `find ... -print0`). Update the glob-prose bullets (lines ~214, ~376) from `docs/research/**/INDEX.md` to: "new `docs/sites/*/research/INDEX.md` (scoped — excludes `redesign/`) and legacy `docs/research/*/INDEX.md`."

- [ ] **Step 4: Add the Phase 1 legacy coexistence notice**

In the Phase 1 scaffold section (right after the `mkdir -p docs/sites/${SLUG}/research/...`), add a one-line deprecation notice:
```bash
# If a legacy research folder exists for this slug, point the user at the new path.
if [ -d "docs/research/${SLUG}" ]; then
  echo "[LEGACY-WORKSPACE] Found docs/research/${SLUG}/ (pre-0.7.0). New output goes to docs/sites/${SLUG}/research/. Move the old folder to consolidate; legacy is read-only and removed in 0.8.0."
fi
```

- [ ] **Step 5: Verify no write-side legacy paths remain, and the cross-scan excludes `redesign/`**

Run:
```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
# (a) No write-side legacy paths left (the only docs/research left should be the dual-scan fallback find + the coexistence-check if-guard):
grep -n 'docs/research' plugins/beacon/skills/site-recon/SKILL.md
```
Expected: the only matches are (1) the `find docs/research -maxdepth 2 -name 'INDEX.md'` legacy-fallback line(s) and (2) the `docs/research/${SLUG}` coexistence `if [ -d ... ]` guard / echo. **No `mkdir`, no `Write`, no `discovered_domains.txt`, no `api-surfaces/specs/scripts` write targets under `docs/research/`.**
```bash
# (b) Prove the cross-scan would not pick up reframe's redesign INDEX:
{ find docs/sites -path '*/research/INDEX.md' 2>/dev/null; find docs/research -maxdepth 2 -name 'INDEX.md' 2>/dev/null; } | sort -u | grep -c 'redesign/'
```
Expected: `0` (no `redesign/` paths in the cross-scan output).

- [ ] **Step 6: Commit**

```bash
git add plugins/beacon/skills/site-recon/SKILL.md
git commit -m "feat(beacon): migrate site-recon writes to docs/sites/{slug}/research/ + canonical slug + dual-root scan

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01ToWJNRjianTDAy4XxHEgS9"
```

---

## Task 2: Write-side paths in site-recon references (3 files)

**Files:**
- Modify: `plugins/beacon/skills/site-recon/references/output-synthesis.md`
- Modify: `plugins/beacon/skills/site-recon/references/browser-recon.md`
- Modify: `plugins/beacon/skills/site-recon/references/tool-availability.md`

**Interfaces:**
- Consumes: the layout from Task 1 (`docs/sites/{slug}/research/...`).

These are pure path-string replacements describing where beacon writes output.

- [ ] **Step 1: `output-synthesis.md` — surface-file write + completion checklist**

- Line ~133: `Write each surface file to: \`docs/research/{site-slug}/api-surfaces/{surface-name}.md\`` → `docs/sites/{site-slug}/research/api-surfaces/{surface-name}.md`
- Completion-checklist lines ~178–184: replace the `docs/research/{site-slug}/` prefix in each of the 6 bullets with `docs/sites/{site-slug}/research/` (INDEX.md, tech-stack.md, site-map.md, constants.md, api-surfaces/, specs/{site-slug}.openapi.yaml, scripts/test-{site-slug}.sh).

- [ ] **Step 2: `browser-recon.md` — screenshot + openapi output**

- Line ~148: `cmux browser --surface $SURF screenshot --out docs/research/example-com/screenshot.png` → `docs/sites/example-com/research/screenshot.png`
- Line ~199: `-o docs/research/{site-slug}/specs/{site-slug}.openapi.yaml` → `-o docs/sites/{site-slug}/research/specs/{site-slug}.openapi.yaml`

- [ ] **Step 3: `tool-availability.md` — screenshot + openapi examples**

- Line ~237: `cmux browser --surface $SURF screenshot --out docs/research/example-com/screenshot.png` → `docs/sites/example-com/research/screenshot.png`
- Line ~327: `> docs/research/example-com/specs/example-com.openapi.yaml` → `> docs/sites/example-com/research/specs/example-com.openapi.yaml`

- [ ] **Step 4: Verify no legacy write paths remain**

```bash
grep -rn 'docs/research' plugins/beacon/skills/site-recon/references/
```
Expected: **no output** (these three files contain only write-side paths; all should now be `docs/sites/.../research/`).

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/references/output-synthesis.md plugins/beacon/skills/site-recon/references/browser-recon.md plugins/beacon/skills/site-recon/references/tool-availability.md
git commit -m "feat(beacon): repoint site-recon reference write paths to docs/sites/{slug}/research/

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01ToWJNRjianTDAy4XxHEgS9"
```

---

## Task 3: Supporting files (agent, hook, command, schema)

**Files:**
- Modify: `plugins/beacon/agents/site-analyst.md`
- Modify: `plugins/beacon/hooks/session-start.sh`
- Modify: `plugins/beacon/commands/beacon-analyze.md`
- Modify: `plugins/beacon/schemas/output.schema.json`

**Interfaces:**
- Consumes: the layout from Task 1.

- [ ] **Step 1: `site-analyst.md` — Output Standards**

- Line ~27: `All output goes to \`docs/research/{site-name}/\` with this structure:` → `docs/sites/{site-name}/research/`
- Line ~30 (tree header): `docs/research/{site-name}/` → `docs/sites/{site-name}/research/`

- [ ] **Step 2: `session-start.sh` — banner**

Line ~16: `Output always goes to: docs/research/{site-name}/` → `Output always goes to: docs/sites/{site-name}/research/`

- [ ] **Step 3: `beacon-analyze.md` — output prose**

Line ~11: `Output all findings to docs/research/ as defined in the skill.` → `Output all findings to docs/sites/{slug}/research/ as defined in the skill.`

- [ ] **Step 4: `output.schema.json` — description string**

Line ~5: `"description": "Documents the required structure of a docs/research/{site}/ folder produced by site-recon."` → `"... docs/sites/{site}/research/ folder produced by site-recon."` (description text only — no validation logic encodes the path).

- [ ] **Step 5: Verify + JSON still valid**

```bash
grep -rn 'docs/research' plugins/beacon/agents/site-analyst.md plugins/beacon/hooks/session-start.sh plugins/beacon/commands/beacon-analyze.md plugins/beacon/schemas/output.schema.json
python3 -c "import json,sys; json.load(open('plugins/beacon/schemas/output.schema.json')); print('schema OK')"
```
Expected: no `docs/research` output; `schema OK`.

- [ ] **Step 6: Commit**

```bash
git add plugins/beacon/agents/site-analyst.md plugins/beacon/hooks/session-start.sh plugins/beacon/commands/beacon-analyze.md plugins/beacon/schemas/output.schema.json
git commit -m "feat(beacon): repoint agent/hook/command/schema output paths to docs/sites/{slug}/research/

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01ToWJNRjianTDAy4XxHEgS9"
```

---

## Task 4: Read-side dual-path discovery (HIGHEST RISK)

**Files:**
- Modify: `plugins/beacon/skills/site-intel/SKILL.md`
- Modify: `plugins/beacon/commands/beacon-load.md`

**Interfaces:**
- Consumes: the new layout (Task 1) and the canonical slug (Global Constraints).
- Produces: the user-facing discovery behavior — must resolve new path first, fall back to legacy, prefer newest when both exist.

This task is **logic/instruction inspection, not grep-verifiable.** The prefer-newest-by-mtime, fallback, and legacy-hint behaviors live in prose instructions to the skill model — verify by reading and tracing the decision logic by hand, not just confirming strings changed.

**Known pre-existing condition (do NOT "fix" — note for the reviewer):** the legacy `docs/research/` directory also contains non-site research notes (`browser-automation/`, `osint-tools/`, `claude-plugin-system/`, `js-analysis/`, `beacon-session-analysis/`), so a legacy listing surfaces them as fake "sites." This predates PR-C (`ls docs/research/` already does it) and the spec does not ask us to filter it. The new `docs/sites/*/research/` path is noise-free (only beacon writes `research/`), so it self-resolves as users migrate. Not a regression introduced here.

- [ ] **Step 1: Rewrite `site-intel/SKILL.md` Step 1 (folder discovery)**

Replace the current Step 1 block (lines ~12–30) with dual-path discovery. New content:

````markdown
## Step 1: Find the research folder

Beacon writes to `docs/sites/{slug}/research/` as of v0.7.0. Older runs used the
legacy `docs/research/{slug}/` path (deprecated, read-only, removed in 0.8.0).
Check both — **new location first**:

```bash
# New (scoped to */research/ so reframe redesign/ folders are excluded):
find docs/sites -path '*/research/INDEX.md' 2>/dev/null | sed -E 's#docs/sites/(.*)/research/INDEX.md#\1#' | grep -i "{keyword-from-question}"
# Legacy fallback:
find docs/research -maxdepth 2 -name INDEX.md 2>/dev/null | sed -E 's#docs/research/(.*)/INDEX.md#\1#' | grep -i "{keyword-from-question}"
```

Resolution rules:
- If only the new path has the slug → use `docs/sites/{slug}/research/`.
- If only legacy has it → use `docs/research/{slug}/` and print:
  `[LEGACY-WORKSPACE] Reading deprecated docs/research/{slug}/ (removed in 0.8.0). Re-run /beacon:analyze {url} to write the new docs/sites/{slug}/research/ path.`
- If **both** exist for the slug → prefer the one whose `INDEX.md` is newest
  (`ls -t docs/sites/{slug}/research/INDEX.md docs/research/{slug}/INDEX.md | head -1`),
  use that folder, and note that the other (older) copy also exists — do **not** merge them.

If no folder matches → tell the user to run `/beacon:analyze {url}` first:
```
No research found for {site}. Run /beacon:analyze {url} to analyse it first.
```

If multiple distinct slugs could match → list them (new path shown first) and ask which one:
```
Multiple researched sites found:
- docs/sites/example-com/research/ (see INDEX.md for analysis date)
- docs/research/example-api-com/ (legacy)

Which site are you asking about?
```
````

- [ ] **Step 2: Repoint the rest of `site-intel/SKILL.md` to resolved-folder-relative paths**

The frontmatter (line ~3: "If a docs/research/ folder exists...") and Steps 2/3/3a examples (lines ~26, ~34, ~78) currently hardcode `docs/research/`. Change references that describe **the current default** to `docs/sites/{slug}/research/`, and where a path is the *resolved* folder from Step 1, phrase it as `{research-folder}/INDEX.md` so it works for either location. Specifically:
- Frontmatter line ~3: `If a docs/research/ folder exists for the site` → `If a docs/sites/{slug}/research/ folder exists for the site (or a legacy docs/research/{slug}/)`.
- Step 2 line ~34: `Always read \`docs/research/{site}/INDEX.md\` first` → `Always read the resolved \`{research-folder}/INDEX.md\` first (new \`docs/sites/{site}/research/INDEX.md\`, or legacy \`docs/research/{site}/INDEX.md\`)`.
- Step 3a example line ~78: `docs/research/example-com/api-surfaces/woocommerce.md` → `docs/sites/example-com/research/api-surfaces/woocommerce.md`.

- [ ] **Step 3: Rewrite `beacon-load.md` discovery**

Replace the body (lines ~3–17) so it lists sites from both paths (new first, legacy labelled) and removes the hardcoded `ls docs/research/`:

````markdown
---
name: beacon:load
description: Load existing research for a known site. Routes questions about a known site to its pre-built research files in docs/sites/{slug}/research/ (or legacy docs/research/{slug}/). Invokes the site-intel skill.
---

Invoke the site-intel skill for the provided site name or question.

If no site name was provided, list available researched sites (new location first, legacy labelled):
```bash
# New (scoped to */research/ — excludes reframe redesign/ folders):
find docs/sites -path '*/research/INDEX.md' 2>/dev/null | sed -E 's#docs/sites/(.*)/research/INDEX.md#\1#'
# Legacy (deprecated, read-only, removed in 0.8.0):
find docs/research -maxdepth 2 -name INDEX.md 2>/dev/null | sed -E 's#docs/research/(.*)/INDEX.md#  \1 (legacy)#'
```

Then ask: "Which site would you like to query?"

If no exact folder match, list the closest options and ask the user to confirm.
If neither path has any researched sites, tell the user to run /beacon:analyze first.

Route the user's question to the correct research file using the site-intel skill (which prefers the new path and falls back to legacy).
````

- [ ] **Step 4: Verify by hand-tracing the logic (no grep gate)**

Read both edited files end-to-end and confirm:
- New path (`docs/sites/*/research/`) is checked before legacy in every discovery block.
- The new-path `find` is scoped to `*/research/` (so `docs/sites/{slug}/redesign/INDEX.md` cannot be listed as research).
- The both-exist case prefers newest by `INDEX.md` mtime and notes the other copy (never merges).
- A legacy-only hit prints the `[LEGACY-WORKSPACE]` deprecation hint.
Then run a non-gating sanity check that the new-path find excludes redesign:
```bash
find docs/sites -path '*/research/INDEX.md' 2>/dev/null | grep -c 'redesign/'
```
Expected: `0`.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-intel/SKILL.md plugins/beacon/commands/beacon-load.md
git commit -m "feat(beacon): dual-path read (docs/sites first, legacy fallback) in site-intel + beacon:load

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01ToWJNRjianTDAy4XxHEgS9"
```

---

## Task 5: Version bump + CHANGELOG deprecation sunset

**Files:**
- Modify: `plugins/beacon/.claude-plugin/plugin.json`
- Modify: `plugins/beacon/CHANGELOG.md`

- [ ] **Step 1: Bump version**

In `plugins/beacon/.claude-plugin/plugin.json`, change `"version": "0.6.3"` → `"version": "0.7.0"`.

- [ ] **Step 2: Add the CHANGELOG 0.7.0 entry**

Prepend a new top entry to `plugins/beacon/CHANGELOG.md` (match the file's existing heading style — inspect the top of the file first; do **not** alter any existing entry, including the historical `docs/research/` mentions at lines ~165 and ~235):

```markdown
## [0.7.0] — 2026-06-24

### Changed
- **Output workspace moved** from `docs/research/{slug}/` to the unified `docs/sites/{slug}/research/`, shared with the reframe plugin (`docs/sites/{slug}/redesign/`).
- Slug derivation now follows the repo's canonical rule (`docs/SLUG_RULES.md`): adds lowercasing and `:port` stripping so beacon and reframe resolve identical slugs.

### Deprecated
- Legacy `docs/research/{slug}/` is now a **read-only fallback**: `/beacon:load` and `site-intel` still read it, but `/beacon:analyze` only writes the new path. **Legacy reads are removed in 0.8.0.**

### Migration
- To consolidate existing research, move each folder: `mkdir -p docs/sites/{slug} && git mv docs/research/{slug} docs/sites/{slug}/research`. Until you do, beacon reads the legacy folder and prints a one-line `[LEGACY-WORKSPACE]` hint.
```

- [ ] **Step 3: Verify**

```bash
grep '"version"' plugins/beacon/.claude-plugin/plugin.json   # expect 0.7.0
python3 -c "import json; json.load(open('plugins/beacon/.claude-plugin/plugin.json')); print('plugin.json OK')"
head -30 plugins/beacon/CHANGELOG.md                          # expect the new 0.7.0 entry on top
```

- [ ] **Step 4: Commit**

```bash
git add plugins/beacon/.claude-plugin/plugin.json plugins/beacon/CHANGELOG.md
git commit -m "chore(beacon): bump to 0.7.0 with workspace-migration changelog + deprecation sunset

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01ToWJNRjianTDAy4XxHEgS9"
```

---

## Task 6: User-facing + contributor docs

**Files:**
- Modify: `plugins/beacon/README.md`
- Modify: `README.md` (repo root)
- Modify: `AGENTS.md`
- Modify: `docs/GLOSSARY.md`
- Modify: `docs/platform/cursor.md`, `docs/platform/copilot.md`, `docs/platform/opencode.md`, `docs/platform/gemini-cli.md`
- Modify: `docs/plugins/beacon/_index.md`, `docs/plugins/beacon/DECISIONS.md`, `docs/plugins/beacon/ROADMAP.md`, `docs/plugins/beacon/TESTING.md`
- Modify: `docs/MODULAR_KNOWLEDGE_PACKS.md`

**Rule for this task:** update references that describe beacon's **current/future** output location to `docs/sites/{slug}/research/`. Do **not** touch references to specific external artifacts at the old path (`docs/research/spitogatos/...` in ROADMAP lines ~78/~191) or any historical design/plan prose.

- [ ] **Step 1: Repo-level user docs**

- `plugins/beacon/README.md` line ~18: `Produces \`docs/research/{site}/\`` → `Produces \`docs/sites/{site}/research/\``.
- `README.md` (root): find the beacon output-path reference (`grep -n 'docs/research' README.md`) and repoint it to `docs/sites/{site}/research/`.
- `AGENTS.md` "Output Convention" section (line ~61): `All analysis output goes to \`docs/research/{site-name}/\`` → reframe writes `docs/sites/{slug}/redesign/`, beacon writes `docs/sites/{slug}/research/`. Reword to: `Site-analysis output goes to \`docs/sites/{site-slug}/{module}/\` (beacon → \`research/\`, reframe → \`redesign/\`). Never write site-specific data into the plugin directories.` Also update the site-intel row (line ~24) and any intent-mapping prose that says `docs/research/{site}/`.

- [ ] **Step 2: Platform docs (4 files)**

For each of `docs/platform/{cursor,copilot,opencode,gemini-cli}.md`, run `grep -n 'docs/research' <file>` and repoint each beacon output-path reference to `docs/sites/{slug}/research/`. (These mirror the AGENTS.md convention per platform.)

- [ ] **Step 3: GLOSSARY**

`docs/GLOSSARY.md`: update the beacon/research-workspace reference(s) (`grep -n 'docs/research' docs/GLOSSARY.md`) to `docs/sites/{slug}/research/`. Ensure the existing `site workspace` entry (added in PR-A) and `tech-pack` cross-reference stay consistent.

- [ ] **Step 4: beacon contributor docs**

- `docs/plugins/beacon/_index.md` lines ~7, ~86: `docs/research/{site-slug}/` → `docs/sites/{site-slug}/research/`.
- `docs/plugins/beacon/TESTING.md` lines ~53, ~76, ~113: `docs/research/{site|slug}/` → `docs/sites/{site|slug}/research/`.
- `docs/plugins/beacon/ROADMAP.md`: line ~102 (future `exports/` feature, beacon's own output) → `docs/sites/{site}/research/exports/{format}/`. **Leave lines ~78 and ~191** (external `docs/research/spitogatos/...` real-world artifact references — they physically live at the old path).
- `docs/plugins/beacon/DECISIONS.md` D-02 (lines ~17–21): do **not** silently rewrite the decision. Append a supersede note and add a new decision. Edit the D-02 title to mark it superseded and add a new entry below the decisions:
  ```markdown
  ## D-02 — Output to `docs/research/{site-slug}/` not project root  *(superseded by D-NN in 0.7.0)*
  ```
  Add a new decision (use the next free D-number in the file):
  ```markdown
  ## D-NN — Unified site workspace: output to `docs/sites/{site-slug}/research/` (0.7.0)

  **Decision:** Beacon writes to `docs/sites/{site-slug}/research/`, sharing the per-site workspace with reframe (`docs/sites/{site-slug}/redesign/`). Supersedes D-02.

  **Why:** Multiple site-analysis plugins (beacon, reframe) converged on per-site output. A shared `docs/sites/{slug}/` workspace with one module subfolder per plugin lets them cross-reference (reframe reads beacon's `tech-stack.md`) without colliding. Legacy `docs/research/{slug}/` remains a read-only fallback, deprecated in 0.7.0 and removed in 0.8.0. See `docs/MODULAR_KNOWLEDGE_PACKS.md` and `docs/SLUG_RULES.md`.
  ```

- [ ] **Step 5: Convention doc table**

`docs/MODULAR_KNOWLEDGE_PACKS.md`: the current→target table marks beacon as migrating "in 0.7.0." Update beacon's row to reflect that the migration has landed — beacon now writes `docs/sites/{slug}/research/` (0.7.0+); legacy `docs/research/` is the read-only fallback removed in 0.8.0. Keep reframe's row as-is.

- [ ] **Step 6: Verify scope (no over-reach into history-of-record)**

```bash
# Confirm the protected historical refs are still present and unchanged:
grep -n 'docs/research/spitogatos' docs/plugins/beacon/ROADMAP.md   # expect lines ~78, ~191 still present
# Confirm no remaining current-output refs to legacy in the touched docs:
grep -rn 'docs/research/{site' plugins/beacon/README.md README.md AGENTS.md docs/GLOSSARY.md docs/platform/ docs/plugins/beacon/_index.md docs/plugins/beacon/TESTING.md
```
Expected: spitogatos refs present; the second grep returns no `{site...}`-pattern legacy current-output references (DECISIONS.md D-02 supersede line is allowed to retain the legacy path in its now-superseded title).

- [ ] **Step 7: Commit**

```bash
git add plugins/beacon/README.md README.md AGENTS.md docs/GLOSSARY.md docs/platform/cursor.md docs/platform/copilot.md docs/platform/opencode.md docs/platform/gemini-cli.md docs/plugins/beacon/_index.md docs/plugins/beacon/DECISIONS.md docs/plugins/beacon/ROADMAP.md docs/plugins/beacon/TESTING.md docs/MODULAR_KNOWLEDGE_PACKS.md
git commit -m "docs(beacon): repoint output convention to docs/sites/{slug}/research/ + D-02 supersede

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01ToWJNRjianTDAy4XxHEgS9"
```

---

## Final Verification & Acceptance

Run after all tasks. This is the cross-cutting audit for the #1 risk (split-brain writes) — performed by the controller and the final whole-branch review.

- [ ] **A. No stray write-side legacy paths in live beacon files**

```bash
cd /Users/georgiospilitsoglou/Developer/projects/claude-plugins
grep -rn 'docs/research' plugins/beacon --include='*.md' --include='*.sh' --include='*.json' --include='*.feature' | grep -v '/.evals/'
```
Expected: only **read-side legacy-fallback** references (the dual-path `find docs/research ...` in site-recon/site-intel/beacon-load, the coexistence `if [ -d docs/research/... ]` guard in site-recon), **historical CHANGELOG** entries (lines ~165, ~235 + any pre-0.7.0 entries), and the **D-02 superseded title**. No `mkdir`/`Write`/output-target writes under `docs/research/`.

- [ ] **B. `.evals/**` untouched**

```bash
git diff --stat main...HEAD -- 'plugins/beacon/.evals/**'
```
Expected: **empty** (no `.evals` files changed).

- [ ] **C. Smoke/scratch artifacts not committed**

```bash
git diff --stat main...HEAD -- 'docs/sites/**' 'docs/redesign/**' 'docs/research/kayuwriting-com/**' 'plugins/beacon/technologies/REGISTRY.md' 'plugins/beacon/technologies/webflow/**'
```
Expected: **empty** (none of the untracked scratch artifacts were swept into a commit).

- [ ] **D. Marketplace validator green**

```bash
bash scripts/validate-marketplace.sh; echo "exit=$?"
```
Expected: 0 errors (one pre-existing idea-forge warning is acceptable), `exit=0`.

- [ ] **E. Cross-scan / read-side redesign exclusion**

```bash
find docs/sites -path '*/research/INDEX.md' 2>/dev/null | grep -c 'redesign/'
```
Expected: `0`.
