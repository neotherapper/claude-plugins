# SEO — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-001 — Weighted 0–100 scoring, not binary pass/fail

**Decision:** Use a 0–100 weighted composite score across five categories (Technical 25 · On-Page 25 · Schema 20 · Content 15 · Performance 15), not binary pass/fail per rule.

**Why:** Binary scoring loses nuance. A site passing 8/10 on-page checks while failing 2 is very different from one passing 2/10. Weighted scoring captures the gradient and makes before/after comparison meaningful — you can read the same report after a fix and see exactly how many points the fix recovered.

**Trade-off rejected:** Binary (each rule pass/fail, total = % passed). Too coarse to drive prioritisation: "we passed 73%, what's the biggest delta we can recover?"

---

## D-002 — Python scripts over MCP server

**Decision:** Ship standalone Python scripts (`meta_audit.py`, `heading_audit.py`, `structured_data_validate.py`, `composite_scorer.py`) callable from any agent, rather than a dedicated MCP server.

**Why:** Python scripts work in any environment (CLI, agent, CI). No MCP server runtime to manage, no process startup latency, easier to debug on user hardware. Each script is < 200 lines and trivially inspectable. The plugin can later wrap them in an MCP if multi-agent orchestration becomes a real need — not a hypothetical.

**Trade-off rejected:** Full MCP server (`mcp-seo` pattern). More impressive at first glance but adds operational burden for a v0.1.0 audit that runs in < 30 seconds.

---

## D-003 — Reuse nikai CLI tools via subprocess, not reimplementation

**Decision:** Call nikai's `tools/cli/pagespeed.py`, `serper.py`, `builtwith.py`, `google_suggest.py` via subprocess, instead of reimplementing PageSpeed, SERP, tech-stack detection inside this plugin.

**Why:** 231 CLI tools already exist under `nikai/tools/cli/` with `--json` output and graceful error handling. Duplication is the most expensive form of technical debt — nikai is the canonical source for these utilities. Reuse also means nikai updates propagate without explicit porting.

**Trade-off rejected:** Copy scripts into `plugins/seo/scripts/`. Diverges from nikai updates, doubles maintenance burden, and `mcp-seo`'s anti-pattern of inlining 18 tools.

---

## D-004 — Zero API keys required for the core audit

**Decision:** Meta, heading, schema, technical, and content categories must run with zero API keys. SERP and enrichment layers are optional.

**Why:** Most users will not have any SEO APIs configured on day one. A blocked audit is a dead plugin — they'd uninstall before realising they could enable enrichment later. The core audit must work out of the box with only `httpx` (Python stdlib urllib is used to avoid an external dependency entirely).

**Trade-off rejected:** Require a Serper.dev / PageSpeed API key. Blocks 90% of first-time users from ever seeing the report, and blocking the core categories to gate the enrichment is overkill — every category has a no-key fallback documented in `free-tools.md`.

---

## D-005 — Output to `docs/sites/{slug}/seo/`, not plugin-local folder

**Decision:** Audit output lands at `docs/sites/{site-slug}/seo/`, sharing the per-site workspace with beacon (`research/`) and reframe (`redesign/`).

**Why:** Cross-plugin workflows need it. beacon writes `research/tech-stack.md` that SEO reads to skip redundant detection. reframe reads `seo-report.md` to populate the SEO section of `current-critique.md`. A `plugins/seo/audit-output/` folder would break both integrations. The `docs/sites/{slug}/` convention (established in beacon D-09) is the right home.

**Trade-off rejected:** Plugin-local output (`plugins/seo/outputs/{slug}/`). Cleanly namespaced but breaks both integration contracts.

---

## D-006 — Three skills (orchestrator + 2 specialists), not one mega-skill

**Decision:** Split audit logic across `site-audit` (orchestrator, 8 phases), `technical-audit` (technical subagent / standalone command), and `on-page-audit` (on-page subagent / standalone command).

**Why:** A user often wants only one slice — "just run the technical audit, I don't need the on-page pass today" — and a 5,000-line mega-skill loads its full SKILL.md into context on every invocation. Splitting lets users (and the orchestrator itself) load only the relevant slice. The orchestrator skill composes the two specialists via Phase 3–7 invocations.

**Trade-off rejected:** Single `SKILL.md`. Easier to author but burns context budget and forces users who want fast technical-only audits to pay the on-page cost.

---

## D-007 — Token-based output templates, not freeform markdown

**Decision:** Output files (`INDEX.md`, `seo-report.md`, `technical-audit.md`, `on-page-audit.md`) are generated from `templates/*.md.template` files using `{{TOKEN}}` substitution.

**Why:** Freeform generation drifts. Two runs against the same site produce different section orders, different table columns, different heading hierarchies. Token-based templates lock the schema so downstream readers (reframe, paidagogos) can parse without re-discovering structure each time. Same pattern as beacon D-07.

**Trade-off rejected:** Freeform `print(markdown)` from the Python script. Flexible but unreviewable — and breaks reframe downstream, which expects `INDEX.md` to have a `: Score` line in a known position.

---

## D-008 — Reuse beacon's recon data; do not re-detect tech

**Decision:** When `docs/sites/{slug}/research/tech-stack.md` exists, the SEO audit reads it and skips its own tech-stack detection. Only when beacon has not been run does the audit emit a `[NO-RECON]` signal and rely on raw HTML meta for tech inference.

**Why:** Detection is expensive and noisy. Beacon's `validate-fingerprinting.sh` enforces high-signal tech detection with 12 tech packs and self-healing regression checks. Reimplementing tech detection inside SEO would be a half-quality duplicate. Reuse is the cheaper, more accurate path.

**Trade-off rejected:** Always re-detect tech inside the audit. Cheaper for users who haven't run beacon, but worse output quality, and forces SEO plugin maintainers to track 12+ framework signatures.

---

## D-009 — Curriculum lives in paidagogos, not in the SEO plugin

**Decision:** The 12-lesson SEO Developer Mastery curriculum lives at `plugins/paidagogos/skills/paidagogos-micro/references/curricula/seo-developer-mastery.md`, not in `plugins/seo/`.

**Why:** Separation of concerns: SEO plugin = audit tools, paidagogos = learning. Lesson 12 references `/seo:audit` as the final practical exercise, but the curriculum can be reviewed and updated without touching the audit code or the plugin manifest. Outline, quizzes, and resources are paidagogos's domain; check inputs and rule thresholds are SEO's domain.

**Trade-off rejected:** Embed curriculum in `plugins/seo/curricula/`. Bundles tool and pedagogy, breaks the "paidagogos owns the wiki" precedent (2026-04-18-paidagogos-wiki-design spec).
