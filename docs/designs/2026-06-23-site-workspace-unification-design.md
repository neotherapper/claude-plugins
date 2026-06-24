# Site Workspace Unification + Modular-Knowledge Convention — Design Spec

**Date:** 2026-06-23
**Status:** Approved design — ready for implementation planning (PR-A)
**Scope:** beacon, reframe, + a repo-level convention doc
**Author:** Georgios Pilitsoglou (with Claude)
**Validated by:** 4 parallel adversarial reviews (migration-safety, architecture, scope/landing, edge-cases)

---

## 1. Summary

Today each site-analysis plugin writes to its own root: beacon → `docs/research/{slug}/`, reframe → `docs/redesign/{slug}/`. This unifies them under a single per-site workspace, `docs/sites/{slug}/`, with one subfolder per analysis **module** (`research/` = beacon, `redesign/` = reframe). It also adds a lean, accurate convention doc capturing the cross-plugin "modular knowledge pack" pattern.

The work **splits into two independently-shippable phases**:
- **PR-A (now, on `feat/reframe-plugin`):** repoint reframe (unmerged → free), fix its beacon-interop read, add the `.gitignore` safety net, canonicalize the slug rule, and write the convention doc.
- **PR-C (separate branch, after reframe merges):** migrate the shipped beacon plugin (breaking-ish, ~17 files, read-both back-compat) to `docs/sites/{slug}/research/`, bump it 0.6.3 → 0.7.0.

idea-forge is **out of scope** — its `ideas/{slug}/` workspace is idea-centric, not site-centric, and is not migrated (only *described* in the convention doc).

---

## 2. Locked decisions

| # | Decision |
|---|----------|
| 1 | Unified workspace `docs/sites/{slug}/{module}/`; modules: `research/` (beacon), `redesign/` (reframe). |
| 2 | Subfolder term is **"module"** (not "lens" — "lens" already means idea-forge's business-model rubric; avoid the collision). |
| 3 | beacon back-compat = **read-both**: write new path, `/beacon:load` reads new→legacy, prefer newest, note when both exist. No data moved. Deprecation sunset declared. |
| 4 | Convention doc is **descriptive + lean**, documenting **three sub-patterns** (not one overfit shape). idea-forge marked *described, not migrated* — never "should conform". |
| 5 | **Canonical slug rule** documented once; reframe aligns now, beacon aligns in PR-C. Interop depends on identical slugs. |
| 6 | Split into PR-A (reframe, now) + PR-C (beacon, separate branch after merge). |
| 7 | idea-forge `ideas/{slug}/` unchanged; reframe→idea-forge pipeline deferred (roadmap). |

---

## 3. Workspace layout

```
docs/sites/{slug}/
├── research/     ← beacon  (INDEX.md, tech-stack.md, site-map.md, constants.md, api-surfaces/, specs/, scripts/)
└── redesign/     ← reframe (INDEX.md, brief.md, run-sheet.md, content-inventory.md, ia-map.md, current-critique.md, .crawl/)
```

- **Cross-module interop:** reframe reads sibling `../research/tech-stack.md` (i.e. `docs/sites/{slug}/research/tech-stack.md`) for its tech-constraint note. This is **always optional** — a module must run standalone (see §6 interop contract).
- No shared site-level `INDEX.md` in v1 (reserve the filename for later; not written now).

---

## 4. Canonical slug rule (the interop contract)

Both plugins MUST derive an identical slug or `docs/sites/{slug}/` won't line up and interop silently misses. Canonical rule:

1. Lowercase.
2. Strip scheme (`https?://`).
3. Strip leading `www.`.
4. Strip everything from the first `/` (path).
5. Strip a trailing `:port` (e.g. `:8080`).
6. Replace `.` with `-`.

Reference implementation:
```bash
SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
```

Examples (must match across both plugins):
| Input | Slug |
|-------|------|
| `https://www.example.com/` | `example-com` |
| `https://api.example.com/v2` | `api-example-com` |
| `http://example.com:8080` | `example-com` |
| `https://Example.COM` | `example-com` |

**IDN/Unicode:** v1 supports ASCII/punycode domains only; non-ASCII input is slugified as-is and flagged. (Full punycode normalization is a later enhancement.) Documented in the convention doc and `docs/SLUG_RULES.md`.

---

## 5. PR-A — reframe repoint + interop + safety (NOW, on `feat/reframe-plugin`)

Reframe is unmerged → no user data, no fallback needed. Clean string changes.

**5.1 Repoint output** `docs/redesign/{slug}/` → `docs/sites/{slug}/redesign/` in:
- `plugins/reframe/skills/site-redesign/SKILL.md` (scaffold path, all phase write refs, the `.gitignore`-write path)
- `plugins/reframe/commands/reframe-analyze.md`
- `plugins/reframe/README.md`, `CHANGELOG.md`
- `docs/plugins/reframe/{_index.md, TESTING.md, ROADMAP.md, specs/site-redesign.feature, designs/*, plans/*}` (path references only)

**5.2 Adopt the canonical slug rule** (§4) explicitly in `SKILL.md` Phase 1 (replace the ambiguous prose with the reference sed + examples).

**5.3 Fix beacon-interop read** — Phase 9 / `{{TECH_EXPORT_HANDOFF}}` reads `docs/sites/{slug}/research/tech-stack.md` **first**, falls back to legacy `docs/research/{slug}/tech-stack.md`; if neither exists, proceed and emit `[TECH-STACK-ABSENT]` + a visible one-line note in `brief.md` §10. Update `references/brief-format.md`.

**5.4 `.gitignore` safety net** — add to the **repo-root** `.gitignore` (independent of the per-dir `.gitignore` the skill writes, which has a create-order race):
```
docs/sites/**/redesign/.crawl/
docs/redesign/**/.crawl/          # legacy
docs/sites/**/*.png               # captured screenshots
docs/research/**/*.png            # legacy beacon screenshots
```

**5.5 Convention doc** (§7) — write `docs/MODULAR_KNOWLEDGE_PACKS.md`.

**5.6 Re-smoke** reframe on the trustyourphysio SPA → confirm output now lands at `docs/sites/trustyourphysio-com/redesign/`, all 6 files written, `.crawl/` git-ignored.

---

## 6. PR-C — beacon migration (DEFERRED to its own branch after reframe merges)

Shipped v0.6.3 → **0.7.0**. Specced here; built when its branch opens. **Hard guard: never touch `plugins/beacon/.evals/**`** (historical baselines).

**6.1 Write-side** — change `docs/research/{slug}/` → `docs/sites/{slug}/research/` in every live path, including the easily-missed ones:
- `skills/site-recon/SKILL.md` — scaffold mkdir, the 4 empty-`Write` stubs, **the Phase 1.5 `discovered_domains.txt` write**, **the Phase 2.5 `find docs/research/ -name INDEX.md` cross-scan globs** (update to scan both new + legacy), frontmatter.
- `skills/site-recon/references/output-synthesis.md` — Phase 12 `api-surfaces/` write + completion-checklist paths.
- `skills/site-recon/references/browser-recon.md` + `tool-availability.md` — Phase 11 screenshot + `har-to-openapi` output paths.
- `agents/site-analyst.md` — Output Standards path (subagent writes).
- `hooks/session-start.sh` — banner.
- `commands/beacon-analyze.md` — output-path prose.
- `schemas/output.schema.json` — description string (no validation logic encodes the path).
- User-facing: `plugins/beacon/README.md`, root `README.md`, `AGENTS.md`, `docs/GLOSSARY.md`, the 4 platform docs (cursor/copilot/opencode/gemini-cli).
- `docs/plugins/beacon/{_index.md, TESTING.md, ROADMAP.md, DECISIONS.md, specs/*}` — path refs (NOT historical CHANGELOG/old plan entries).

**6.2 Read-side (explicit dual-path — the highest-risk item):** rewrite `skills/site-intel/SKILL.md` Step 1 and `commands/beacon-load.md` discovery to: check `docs/sites/*/research/` **first**, fall back to legacy `docs/research/*/`; if both exist for a slug, **prefer the newest (by `INDEX.md` mtime)** and note the legacy folder exists (do not silently merge). Replace the hardcoded `ls docs/research/` + "empty → run analyze" logic.

**6.3 Slug** — align beacon's `sed` to the canonical rule (§4) — add the `:port` strip + lowercase it lacks today.

**6.4 Deprecation sunset** — CHANGELOG `## [0.7.0]`: path changed to `docs/sites/{slug}/research/`; legacy `docs/research/` is **read-only fallback, deprecated in 0.7.0, removed in 0.8.0**; include a one-line "move existing folders" migration note. `site-intel` prints a one-line hint when it falls back to a legacy folder.

**6.5 Coexistence note** — Phase 1 scaffold: if a legacy `docs/research/{slug}/` exists for the target, emit a one-line deprecation notice pointing at the new path.

---

## 7. Convention doc — `docs/MODULAR_KNOWLEDGE_PACKS.md` (lean + accurate)

Descriptive contributor reference. Does **not** refactor any existing pack/lens. Outline:

1. **Why this exists** — the cross-plugin convergence; what's shared vs plugin-specific.
2. **Site-workspace convention** — `docs/sites/{slug}/{module}/`; the canonical slug rule (§4); cross-module interop contract (always-optional sibling reads under `../research/`, graceful fallback + named signal, each module independently runnable); current→target table (reframe = `docs/sites/.../redesign/` now; beacon = `docs/research/` today → `docs/sites/.../research/` in 0.7.0).
3. **Three pack sub-patterns** (accurate, not one shape):
   - **fingerprint-pack** (beacon `technologies/{fw}/{ver}.md`) — versioned, remote, SHA/schema-validated, fingerprint-selected.
   - **category-pack** (reframe `categories/{cat}.md`) — local, `detect_signals` frontmatter, fixed section set, `generic.md` fallback.
   - **inference-lens** (idea-forge `references/lenses/{model}.md`) — local, agent-inferred, no frontmatter. *Described, not migrated; do not "conform" it.*
4. **Shared rules** (the genuinely cross-cutting bits): one file per domain key; a fallback must always exist; **dominant-pick, never merge**; score by most-specific match, not first-match; **tiebreak** → if two score equally, prefer the one whose section coverage best fits the detected structure, else fall back to the generic pack (never pick arbitrarily).
5. **Local vs remote** — bundle locally (evergreen, few) unless a real versioning/contribution-cadence driver exists (beacon's framework APIs).
6. **How to add** — a category-pack / a new module / a site-analysis skill (point to each plugin's own template/validator).
7. **Current instances table** — the three, with their divergences noted honestly.

**Discoverability:** add a one-paragraph "Knowledge packs & site workspace" stub to `docs/PLUGIN_SYSTEM.md` linking here; add `category-pack`, `inference-lens`, and `site workspace` entries to `docs/GLOSSARY.md` and cross-reference the existing `tech-pack` entry.

---

## 8. Testing

- **PR-A:** reframe re-smoke writes to `docs/sites/{slug}/redesign/`; `.crawl/` not committed (root `.gitignore` net verified with `git check-ignore`); interop read resolves new path, falls back to legacy, emits `[TECH-STACK-ABSENT]` when absent; `scripts/validate-marketplace.sh` stays green.
- **PR-C:** `/beacon:load` resolves new path, falls back to legacy, prefers newest when both exist; a fresh `/beacon:analyze` writes entirely under `docs/sites/{slug}/research/` (no split-brain — grep output for stray `docs/research/` writes); beacon's existing `tests/validate-*.sh` pass; `.evals/**` untouched (`git diff --stat` shows no `.evals` changes).

---

## 9. Risks & out-of-scope

- **Risk:** a missed hardcoded path in PR-C causes split-brain writes → mitigated by the explicit §6.1 file list + a post-change `grep -rn 'docs/research'` audit over live (non-`.evals`) files.
- **Risk:** slug divergence breaks interop → mitigated by the single canonical rule (§4) both adopt.
- **Out of scope:** idea-forge migration; a reframe→idea-forge pipeline; punycode/IDN normalization; a shared extraction skill (the crawler matrix stays copied at N=2); a shared site-level `INDEX.md` (filename reserved only).

---

## 10. References

- reframe design spec: `docs/plugins/reframe/designs/2026-06-21-reframe-v0.1.0-design.md`
- beacon contributor docs: `docs/plugins/beacon/_index.md`, `DECISIONS.md`
- existing conventions: `docs/PLUGIN_SYSTEM.md`, `docs/TOOL_OPTIONALITY.md`, `docs/GLOSSARY.md`
