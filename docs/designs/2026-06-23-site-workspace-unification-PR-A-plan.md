# Site Workspace Unification — PR-A (reframe) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. **Design spec (read FIRST; all `§N` refer to it):** `/Users/georgiospilitsoglou/Developer/projects/claude-plugins/docs/designs/2026-06-23-site-workspace-unification-design.md`

**Goal:** Repoint the (unmerged) reframe plugin's output to the unified `docs/sites/{slug}/redesign/` workspace, fix its beacon-interop read, canonicalize its slug rule, add a repo-root `.gitignore` safety net, and write the lean modular-knowledge convention doc — i.e. all of spec §5. (Beacon migration = spec §6 = a separate later branch, NOT in this plan.)

**Architecture:** Pure markdown/skill edits + two new docs. No runtime code. Reframe is unmerged, so there's no back-compat or data migration here. "Tests" = grep assertions, `git check-ignore`, `scripts/validate-marketplace.sh`, and a live re-smoke.

**Tech Stack:** Claude Code plugin (markdown skill + references + command), repo docs.

## Global Constraints

- New reframe output path: **`docs/sites/{slug}/redesign/`** (was `docs/redesign/{slug}/`). Verbatim.
- Subfolder term is **"module"**, never "lens" (avoid idea-forge collision).
- **Canonical slug rule** (spec §4): strip scheme → strip leading `www.` → strip path (from first `/`) → strip `:port` → lowercase → `.`→`-`. Reference impl:
  ```bash
  SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
  ```
- Beacon-interop read order: **`docs/sites/{slug}/research/tech-stack.md` first, then legacy `docs/research/{slug}/tech-stack.md`**; if neither, emit `[TECH-STACK-ABSENT]` + a visible `brief.md` §10 note.
- Do NOT touch beacon, idea-forge, or any `.evals/` (beacon migration is out of scope here).
- reframe SKILL.md must keep its 36-token Phase-9 contract intact and stay ≤ ~15,200 bytes.
- This work lands on the existing `feat/reframe-plugin` branch.

---

## File Structure

```
plugins/reframe/skills/site-redesign/SKILL.md          ← path repoint + canonical slug + interop fix (Task 1)
plugins/reframe/skills/site-redesign/references/brief-format.md ← interop read-order + §10 note (Task 1)
plugins/reframe/commands/reframe-analyze.md             ← output-path prose (Task 1)
docs/SLUG_RULES.md                                      ← NEW canonical slug rule (Task 1)
plugins/reframe/README.md  CHANGELOG.md                 ← path refs + changelog note (Task 2)
docs/plugins/reframe/{_index,TESTING,ROADMAP}.md
docs/plugins/reframe/specs/site-redesign.feature        ← path refs (Task 2)
.gitignore (repo root)                                  ← .crawl/ + screenshot safety net (Task 3)
docs/MODULAR_KNOWLEDGE_PACKS.md                         ← NEW convention doc (Task 4)
docs/PLUGIN_SYSTEM.md  docs/GLOSSARY.md                 ← stub + cross-links (Task 4)
```

Historical reframe design/plan docs (`docs/plugins/reframe/designs/*`, `plans/*`) are **left as-is** (dated records that predate the path change) — only live contributor docs are updated.

---

### Task 1: Reframe behavior — repoint output, canonical slug, interop read fix

**Files:**
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md`
- Modify: `plugins/reframe/skills/site-redesign/references/brief-format.md`
- Modify: `plugins/reframe/commands/reframe-analyze.md`
- Create: `docs/SLUG_RULES.md`

**Interfaces:**
- Produces: output now under `docs/sites/{slug}/redesign/`; slug derived per the canonical rule; interop reads new-then-legacy tech-stack path; new signal `[TECH-STACK-ABSENT]`.

- [ ] **Step 1: Repoint every `docs/redesign/{slug}/` → `docs/sites/{slug}/redesign/` in the three plugin files.** This includes the scaffold path, every phase write reference, and the path where the skill writes the per-run `.gitignore` (it should write `docs/sites/{slug}/redesign/.gitignore` containing `.crawl/`). In `reframe-analyze.md`, update the output-path prose line.

- [ ] **Step 2: Verify the repoint is complete.**

Run: `grep -rn "docs/redesign" plugins/reframe/skills plugins/reframe/commands`
Expected: no matches (zero stray legacy write paths in the skill/command).
Run: `grep -rn "docs/sites/{slug}/redesign\|docs/sites/${SLUG}/redesign" plugins/reframe/skills/site-redesign/SKILL.md | head`
Expected: the scaffold + write references now use the new path.

- [ ] **Step 3: Replace the slug derivation in SKILL.md Phase 1 with the canonical rule.** Remove the ambiguous prose ("strip www., then example.com → example-com") and insert the canonical sed from Global Constraints, plus a one-line pointer: "Slug rule is canonical — see `docs/SLUG_RULES.md`." Include the four worked examples (`www.example.com/`→`example-com`, `api.example.com/v2`→`api-example-com`, `example.com:8080`→`example-com`, `Example.COM`→`example-com`).

- [ ] **Step 4: Create `docs/SLUG_RULES.md`** as the single canonical source:

```markdown
# Site slug derivation (canonical)

All site-analysis plugins (beacon, reframe) MUST derive the same slug so their
output lines up under `docs/sites/{slug}/`. Rule:

1. Lowercase
2. Strip scheme (`https?://`)
3. Strip leading `www.`
4. Strip path (everything from the first `/`)
5. Strip trailing `:port`
6. Replace `.` with `-`

```bash
SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
```

| Input | Slug |
|-------|------|
| `https://www.example.com/` | `example-com` |
| `https://api.example.com/v2` | `api-example-com` |
| `http://example.com:8080` | `example-com` |
| `https://Example.COM` | `example-com` |

IDN/Unicode: v1 supports ASCII/punycode input only; non-ASCII is slugified
as-is and should be flagged. Full punycode normalization is a later enhancement.
```

- [ ] **Step 5: Fix the beacon-interop read** in SKILL.md (the phase that builds `{{TECH_EXPORT_HANDOFF}}`) and `references/brief-format.md`. The skill must: read `docs/sites/{slug}/research/tech-stack.md` first; if absent, read legacy `docs/research/{slug}/tech-stack.md`; if neither exists, proceed and (a) log `[TECH-STACK-ABSENT]`, (b) emit a one-line note in `brief.md` §10 ("No beacon tech-stack found — specify the target stack manually, or run beacon first"). Add `[TECH-STACK-ABSENT]` to the SKILL.md graceful-degradation signals table with that meaning.

- [ ] **Step 6: Verify slug + interop + token/size invariants.**

Run: `grep -n "sed -E 's#\^https" plugins/reframe/skills/site-redesign/SKILL.md` → canonical sed present.
Run: `grep -n "docs/sites/{slug}/research/tech-stack\|docs/research/{slug}/tech-stack\|TECH-STACK-ABSENT" plugins/reframe/skills/site-redesign/SKILL.md plugins/reframe/skills/site-redesign/references/brief-format.md` → dual-path + signal present in both.
Run: `grep -oE '\{\{[A-Za-z0-9_]+\}\}' plugins/reframe/skills/site-redesign/SKILL.md | sort -u | wc -l` → 37 (36 contract tokens + the `{{TOKEN}}` prose placeholder).
Run: `wc -c plugins/reframe/skills/site-redesign/SKILL.md` → ≤ 15200.

- [ ] **Step 7: Commit.**

```bash
git add plugins/reframe/skills/site-redesign/SKILL.md plugins/reframe/skills/site-redesign/references/brief-format.md plugins/reframe/commands/reframe-analyze.md docs/SLUG_RULES.md
git commit -m "feat(reframe): output to docs/sites/{slug}/redesign/, canonical slug, beacon-interop read fix"
```

---

### Task 2: Reframe docs — path references

**Files:**
- Modify: `plugins/reframe/README.md`, `plugins/reframe/CHANGELOG.md`
- Modify: `docs/plugins/reframe/_index.md`, `docs/plugins/reframe/TESTING.md`, `docs/plugins/reframe/ROADMAP.md`, `docs/plugins/reframe/specs/site-redesign.feature`

**Interfaces:**
- Consumes: the new path from Task 1. Produces: docs consistent with the new output location.

- [ ] **Step 1: Update path references** `docs/redesign/{slug}/` → `docs/sites/{slug}/redesign/` in README.md, `_index.md`, `TESTING.md`, `ROADMAP.md`, and `specs/site-redesign.feature` (output-structure blocks, "how to use", scenario paths).

- [ ] **Step 2: Add a CHANGELOG note** under reframe's `## 0.1.0` (it's pre-release, so amend the entry rather than add a new version): change the output-path mention to `docs/sites/{slug}/redesign/` and add a bullet: "Output lives under the shared `docs/sites/{slug}/` workspace (alongside beacon's `research/`)."

- [ ] **Step 3: Verify.**

Run: `grep -rn "docs/redesign" plugins/reframe/README.md plugins/reframe/CHANGELOG.md docs/plugins/reframe/_index.md docs/plugins/reframe/TESTING.md docs/plugins/reframe/ROADMAP.md docs/plugins/reframe/specs/`
Expected: no matches (all updated). (Historical `docs/plugins/reframe/designs/` and `plans/` are intentionally NOT changed.)

- [ ] **Step 4: Commit.**

```bash
git add plugins/reframe/README.md plugins/reframe/CHANGELOG.md docs/plugins/reframe/
git commit -m "docs(reframe): update output path refs to docs/sites/{slug}/redesign/"
```

---

### Task 3: Repo-root `.gitignore` safety net

**Files:**
- Modify: `.gitignore` (repo root)

**Interfaces:**
- Produces: screenshots/`.crawl` ignored regardless of the per-dir `.gitignore` the skill writes (closes the create-order race, spec §5.4).

- [ ] **Step 1: Append the safety-net block** to the repo-root `.gitignore`:

```
# Site-analysis working data (reframe .crawl, captured screenshots) — safety net
docs/sites/**/redesign/.crawl/
docs/redesign/**/.crawl/
docs/sites/**/*.png
docs/research/**/*.png
```

- [ ] **Step 2: Verify the patterns ignore the intended paths.**

Run: `git check-ignore -v docs/sites/example-com/redesign/.crawl/x.png docs/sites/example-com/redesign/.crawl/shot.png docs/sites/example-com/research/specs/screenshot.png`
Expected: each path prints a matching `.gitignore` rule (ignored). Then confirm a normal output file is NOT ignored:
Run: `git check-ignore docs/sites/example-com/redesign/brief.md; echo "exit=$?"`
Expected: no output, `exit=1` (brief.md is tracked, not ignored).

- [ ] **Step 3: Commit.**

```bash
git add .gitignore
git commit -m "chore: gitignore safety net for site-analysis .crawl/ and screenshots"
```

---

### Task 4: Convention doc + discoverability

**Files:**
- Create: `docs/MODULAR_KNOWLEDGE_PACKS.md`
- Modify: `docs/PLUGIN_SYSTEM.md`, `docs/GLOSSARY.md`

**Interfaces:**
- Consumes: the slug rule (`docs/SLUG_RULES.md`, Task 1) and workspace layout. Produces: the descriptive convention reference.

- [ ] **Step 1: Write `docs/MODULAR_KNOWLEDGE_PACKS.md`** following spec §7's 7-section outline exactly: (1) why this exists / shared-vs-specific; (2) site-workspace convention — `docs/sites/{slug}/{module}/`, link to `docs/SLUG_RULES.md`, the cross-module interop contract (sibling `../research/` reads are always optional, graceful fallback + named signal, each module runs standalone), and a **current→target table** (reframe = `docs/sites/.../redesign/` now; beacon = `docs/research/` today → `docs/sites/.../research/` in 0.7.0); (3) the **three sub-patterns** — `fingerprint-pack` (beacon: versioned/remote/schema-validated/fingerprint-selected), `category-pack` (reframe: local/`detect_signals`/fixed sections/`generic` fallback), `inference-lens` (idea-forge: local/agent-inferred/no frontmatter — **described, not migrated; do not conform it**); (4) shared rules — one-file-per-key, fallback-required, dominant-pick-**never-merge**, score-by-most-specific (not first-match), tiebreak → best section-coverage else generic; (5) local-vs-remote guidance; (6) how to add a category-pack / module / site-analysis skill; (7) current-instances table with divergences. Use "module" for the workspace subfolder, never "lens".

- [ ] **Step 2: Add a discoverability stub to `docs/PLUGIN_SYSTEM.md`** — a short "Knowledge packs & site workspace" subsection: one paragraph summarizing that site-analysis plugins write under `docs/sites/{slug}/{module}/` and use category-keyed knowledge packs, with a link to `docs/MODULAR_KNOWLEDGE_PACKS.md` and `docs/SLUG_RULES.md`.

- [ ] **Step 3: Add `docs/GLOSSARY.md` entries** — `category-pack`, `inference-lens`, and `site workspace`; update the existing `tech-pack` entry to cross-reference `docs/MODULAR_KNOWLEDGE_PACKS.md`.

- [ ] **Step 4: Verify.**

Run: `grep -cE '^#{1,3} ' docs/MODULAR_KNOWLEDGE_PACKS.md` → ≥ 7 (the outline sections present).
Run: `grep -n "MODULAR_KNOWLEDGE_PACKS" docs/PLUGIN_SYSTEM.md docs/GLOSSARY.md` → cross-links present in both.
Run: `grep -in "lens" docs/MODULAR_KNOWLEDGE_PACKS.md | grep -vi "inference-lens"` → confirm "lens" appears ONLY as "inference-lens" (no stray use of "lens" for the workspace module).

- [ ] **Step 5: Commit.**

```bash
git add docs/MODULAR_KNOWLEDGE_PACKS.md docs/PLUGIN_SYSTEM.md docs/GLOSSARY.md
git commit -m "docs: add modular-knowledge-packs convention + site-workspace, cross-link from PLUGIN_SYSTEM/GLOSSARY"
```

---

### Task 5: Re-smoke reframe at the new path (MAIN SESSION)

> Runs in the MAIN SESSION — drives Chrome MCP / network. Not a background subagent.

**Files:** none created (produces `docs/sites/trustyourphysio-com/redesign/` as a real-world check; do not commit it).

- [ ] **Step 1: Run `/reframe:analyze https://trustyourphysio.com/`** (or follow the skill against that URL). Per spec §5 it should now use a markdown crawler (Jina-first) for the SPA, not the slow Chrome-MCP path.

- [ ] **Step 2: Verify output location + structure.**

Run: `find docs/sites/trustyourphysio-com/redesign -maxdepth 1 -type f | sort`
Expected: `INDEX.md, brief.md, run-sheet.md, content-inventory.md, ia-map.md, current-critique.md` (and `.crawl/` dir).
Run: `git check-ignore docs/sites/trustyourphysio-com/redesign/.crawl; echo exit=$?`
Expected: ignored (exit 0).

- [ ] **Step 3: Verify the interop fallback + slug.** Confirm the slug is exactly `trustyourphysio-com`, and that with no beacon research present the run logged `[TECH-STACK-ABSENT]` and `brief.md` §10 carries the manual-stack note.

- [ ] **Step 4: Marketplace validator still green.**

Run: `bash scripts/validate-marketplace.sh; echo exit=$?`
Expected: `0 error(s)`, exit 0.

- [ ] **Step 5:** If the smoke surfaced a fix, apply + commit it; otherwise note the smoke result in the ledger. Do NOT commit the generated `docs/sites/trustyourphysio-com/` output.

---

## Self-Review

**Spec coverage (§5):** §5.1 repoint → Task 1 (skill/command) + Task 2 (docs); §5.2 canonical slug → Task 1 Steps 3–4; §5.3 interop read fix → Task 1 Step 5; §5.4 `.gitignore` net → Task 3; §5.5 convention doc → Task 4; §5.6 re-smoke → Task 5. The canonical slug rule (§4) → Task 1 + `docs/SLUG_RULES.md`. All covered.

**Out-of-scope confirmed absent:** no task touches beacon, idea-forge, or `.evals/` (that's spec §6 / PR-C).

**Placeholder scan:** none — every edit is a concrete string-repoint with a verifying grep, the new-file contents are given (SLUG_RULES.md in full, MODULAR_KNOWLEDGE_PACKS.md by the §7 outline it must follow), and the slug sed / interop logic / gitignore lines are literal.

**Consistency:** "module" (not "lens") used throughout; the canonical sed is identical in Global Constraints, Task 1 Step 4, and `docs/SLUG_RULES.md`; `[TECH-STACK-ABSENT]` named consistently in Task 1 Steps 5–6 and Task 5 Step 3; the 36-token contract + ≤15200-byte budget guarded in Task 1 Step 6.

**Test model:** markdown plugin — verification is grep/`git check-ignore`/validator/live-smoke, not unit tests. Task 5 is main-session (Chrome MCP).
