# Modular Knowledge Packs — Convention Reference

> Descriptive contributor reference. Documents the cross-plugin modular-knowledge pattern and site-workspace convention as they exist today. Does **not** prescribe a single unified shape — the three sub-patterns are documented accurately with their real differences.

See `docs/PLUGIN_SYSTEM.md` for the plugin architecture overview. See `docs/SLUG_RULES.md` for the canonical slug derivation rule.

---

## 1. Why this exists

Three plugins (beacon, reframe, idea-forge) independently arrived at the same structural idea: carry a small library of category- or domain-specific knowledge files that sharpen the plugin's output for a detected context. Rather than hardcoding behaviour per category, each plugin loads the right file at runtime.

What is shared across all three:

- One file per domain key (framework version, site category, business model)
- A fallback file that always exists so the plugin never hard-fails
- Selection by match quality — most-specific match wins, never an arbitrary first-match
- The file shapes differ deliberately to fit each plugin's job

What is plugin-specific:

- How the key is detected (fingerprinting signals, declared signals, or agent inference)
- Whether files are bundled locally or fetched remotely
- Whether files have structured frontmatter or are free-form prose

Convention docs do not override this: each plugin's own documentation remains the authoritative reference for its sub-pattern.

---

## 2. Site-workspace convention

### Layout

Site-analysis plugins write all per-site output under a single root:

```
docs/sites/{slug}/
├── research/     ← beacon output (INDEX.md, tech-stack.md, site-map.md, constants.md, api-surfaces/, specs/, scripts/)
└── redesign/     ← reframe output (INDEX.md, brief.md, run-sheet.md, content-inventory.md, ia-map.md, current-critique.md, .crawl/)
```

The subfolder term for each analysis type is **module** (e.g. `research/`, `redesign/`). Do not use "lens" for workspace subfolders — "lens" is already taken by idea-forge's business-model rubric files.

### Slug derivation

All site-analysis plugins must derive an identical slug from the URL or `docs/sites/{slug}/` will not line up and cross-module interop will silently miss. See `docs/SLUG_RULES.md` for the canonical rule and reference implementation. Short form:

1. Strip scheme (`https?://`)
2. Strip leading `www.`
3. Strip path (everything from the first `/`)
4. Strip trailing `:port`
5. Lowercase
6. Replace `.` with `-`

### Cross-module interop contract

Each module must run completely standalone. Cross-module reads are always optional:

- reframe reads `../research/tech-stack.md` (i.e. `docs/sites/{slug}/research/tech-stack.md`) as a tech-constraint note in the redesign brief. If the file is absent the module continues and emits the named signal `[TECH-STACK-ABSENT]` plus a one-line note in `brief.md §10`.
- Any future module that reads a sibling module's output must follow the same pattern: read is optional, absence is handled gracefully, a named `[MODULE-ABSENT]`-style signal is emitted.
- No module may block on another module's output.

### Current-state vs target-state paths

| Plugin | Current output path | Target output path | When |
|--------|--------------------|--------------------|------|
| reframe | `docs/sites/{slug}/redesign/` | (already at target) | PR-A |
| beacon | `docs/research/{slug}/` | `docs/sites/{slug}/research/` | PR-C (v0.7.0, separate branch) |

Until PR-C ships, beacon writes to `docs/research/{slug}/`. When PR-C ships, `/beacon:load` will check the new path first and fall back to the legacy path, preferring the newest when both exist. The legacy `docs/research/` path will be deprecated in v0.7.0 and removed in v0.8.0.

---

## 3. Three pack sub-patterns

The three existing sub-patterns differ significantly. Each is documented as-is; none is being forced into a shared shape.

---

### 3a. fingerprint-pack (beacon)

**Location:** `plugins/beacon/technologies/{framework}/{version}.md`

**Examples:** `technologies/nextjs/15.x.md`, `technologies/shopify/storefront.md`

**Key traits:**

- **Versioned:** one file per major framework version (e.g. `15.x`), not per framework
- **Remote-ready:** designed to be contributed externally and updated frequently as frameworks evolve
- **Schema-validated:** `plugins/beacon/schemas/tech-pack.schema.json` defines required frontmatter keys (`framework`, `version`, `last_updated`, `author`, `status`) and the 10 required H2 sections
- **Fingerprint-selected:** the pack is loaded based on beacon's Phase 2 fingerprinting output — Wappalyzer signals, HTTP headers, HTML patterns, and probe results determine the `{framework}/{version}` key
- **Section contract (10 required):** Fingerprinting Signals, Default API Surfaces, Config / Constants Locations, Auth Patterns, JS Bundle Patterns, Source Map Patterns, Common Plugins & Extensions, Known Public Data, Probe Checklist, Gotchas
- **No generic fallback:** selection is only triggered when a known framework is detected; unrecognised stacks fall through to generic beacon methodology

Selection rule: most-specific version match first (e.g. `15.x.md` beats a hypothetical `next.md`). Tiebreak: prefer the file whose section coverage better fits the detected stack; if equal, do not pick arbitrarily — flag ambiguity and proceed with generic beacon methodology.

---

### 3b. category-pack (reframe)

**Location:** `plugins/reframe/categories/{category}.md`

**Examples:** `categories/ecommerce.md`, `categories/saas-marketing.md`, `categories/local-service.md`

**Key traits:**

- **Local only:** bundled with the plugin, not fetched remotely
- **Signal-declared:** frontmatter `detect_signals` lists URL patterns, content signals, or nav signals that indicate this category (e.g. `["cart", "checkout", "shop"]` for ecommerce)
- **Fixed section set (8 required):** Redesign priorities, Conversion patterns, Trust signals, IA conventions, Design-system seed, Reference sites, Anti-references & strict NOs, Emphasize in the brief
- **generic.md fallback:** `categories/generic.md` always exists with `detect_signals: []` and is used when no category-specific pack matches. This is the required fallback for this sub-pattern.
- **Template:** `categories/_TEMPLATE.md` is the canonical template for new packs

Selection rule: score each pack by how many of its `detect_signals` appear in the site's content, URL, and nav. Pick the dominant match — the highest-scoring pack wins. Do not merge sections from two packs. If two packs score equally, prefer the one whose section coverage better fits the detected site structure; if still equal, fall back to `generic.md`.

---

### 3c. inference-lens (idea-forge)

**Location:** `plugins/idea-forge/skills/evaluate/references/lenses/{model}.md`

**Examples:** `lenses/saas.md`, `lenses/ecommerce.md`, `lenses/content.md`, `lenses/marketplace.md`, `lenses/directory.md`, `lenses/tool-site.md`

**Key traits:**

- **Local only:** bundled with the plugin
- **Agent-inferred:** no `detect_signals` frontmatter; the agent reads the business idea description and infers which lens to apply based on the business model described
- **No frontmatter:** files begin with a `#` heading and are free-form prose with markdown tables. There is no structured YAML frontmatter.
- **Content:** each file contains weight overrides for scoring criteria, benchmarks, and lens-specific evidence requirements — all specific to one business model type
- **Described, not migrated:** idea-forge's workspace (`ideas/{slug}/`) is idea-centric, not site-centric, and is out of scope for the `docs/sites/{slug}/` convention. This sub-pattern is documented here for completeness. It is not being conformed to either of the other shapes.

Selection rule: agent inference from the idea description. No signal-based scoring. Tiebreak: the agent picks the most plausible primary business model and applies that lens alone — it does not blend lenses.

---

## 4. Shared rules

These rules apply to all three sub-patterns, despite their differences:

**One file per domain key.** Each distinct value of the selection key (framework version, site category, business model) maps to exactly one file. Do not split a single key across multiple files.

**A fallback must always exist.** Every sub-pattern must have a file that handles the "no specific match found" case without hard-failing. For category-pack: `generic.md`. For fingerprint-pack: no generic file — the beacon methodology itself is the fallback. For inference-lens: the agent proceeds with baseline criteria when inference is low-confidence.

**Dominant-pick, never merge.** When selecting a pack, pick the best match and use it exclusively. Do not merge sections from two different packs for the same key. Merged packs produce incoherent output.

**Score by most-specific match, not first-match.** Evaluate all candidate files before selecting. The first file found is not necessarily the best match. Score all candidates, then pick.

**Tiebreak rule:** If two candidates score equally, prefer the file whose section coverage best fits the detected content structure. If still equal, fall back to the generic/baseline file. Never pick arbitrarily.

---

## 5. Local vs remote

**Bundle locally** when:
- The knowledge is relatively stable (categories, business models)
- The plugin is the primary contributor
- External contributions are not expected

**Fetch remotely** when there is a genuine versioning and contribution-cadence driver — the knowledge changes frequently as the upstream technology evolves, and contributors outside the plugin team need to add and update files without a plugin release cycle.

Beacon's fingerprint-packs have this driver: framework APIs change with major versions, new frameworks are constantly added, and community contributions are expected (e.g. via `status: community` packs). Reframe's category-packs and idea-forge's inference-lenses do not have this driver today — they are bundled locally.

**Preference:** local unless you have a real cadence driver. Remote packs add schema validation and fetch complexity that is only worth the cost when the alternative (shipping stale knowledge in the bundle) is worse.

---

## 6. How to add

### Add a category-pack (reframe)

1. Copy `plugins/reframe/categories/_TEMPLATE.md` to `plugins/reframe/categories/{category}.md`
2. Fill in all 8 required sections
3. Set `detect_signals` to 3–8 URL/content/nav signals specific to this category
4. Verify `generic.md` still has `detect_signals: []` (the fallback)
5. Test detection by running `/reframe:analyze` on a representative site of this category

### Add a new workspace module

A new site-analysis skill that writes per-site output should:

1. Write to `docs/sites/{slug}/{module}/` using the canonical slug rule from `docs/SLUG_RULES.md`
2. Choose a unique `{module}` name (check `docs/PLUGIN_SYSTEM.md` for existing modules)
3. Declare the cross-module interop contract: which sibling modules (if any) it optionally reads, what named signal it emits on absence
4. Add a current→target path row to §2 of this doc if the plugin is migrating paths
5. Document the module's file schema in the plugin's own `docs/plugins/{name}/architecture.md`

### Add a site-analysis skill

1. Follow the plugin skill creation guide in `docs/PLUGIN_SYSTEM.md`
2. Implement the canonical slug rule (copy from `docs/SLUG_RULES.md`) in Phase 1
3. Write all output to `docs/sites/{slug}/{module}/`
4. Implement the interop contract for any cross-module reads (always optional, always with fallback + named signal)
5. Add the module to the workspace layout table in §2 of this doc

---

## 7. Current instances

| Sub-pattern name | Plugin | Pack location | Selection mechanism | Frontmatter | Fallback | Schema validated | Status |
|-----------------|--------|---------------|--------------------|--------------------|----------|-----------------|--------|
| fingerprint-pack | beacon | `plugins/beacon/technologies/{fw}/{ver}.md` | Fingerprinting signals (Phase 2) | Yes — `framework`, `version`, `last_updated`, `author`, `status` | No generic file; beacon methodology is fallback | Yes — `schemas/tech-pack.schema.json` + `tests/validate-tech-pack.sh` | Shipped (v0.6.x); path migrates to `docs/sites/{slug}/research/` in PR-C v0.7.0 |
| category-pack | reframe | `plugins/reframe/categories/{category}.md` | `detect_signals` scoring | Yes — `category`, `display_name`, `detect_signals` | `generic.md` (`detect_signals: []`) | No (template only; no automated validator yet) | Shipped in PR-A; output at `docs/sites/{slug}/redesign/` |
| inference-lens | idea-forge | `plugins/idea-forge/skills/evaluate/references/lenses/{model}.md` | Agent inference from idea description | No — files begin with `#` heading; no YAML frontmatter | Agent proceeds with baseline criteria | No | Shipped; workspace is `ideas/{slug}/` (not `docs/sites/`); described here, not migrated |

**Divergences noted honestly:**

- fingerprint-pack is the most formally constrained: schema file, shell validator, 10 required sections, YAML frontmatter with a status field. The other two sub-patterns have no automated validator.
- inference-lens is the least constrained: no frontmatter at all, free-form prose. It is not being reformed — the agent-inference selection mechanism does not require structured detection signals.
- category-pack sits between: structured frontmatter with `detect_signals`, fixed 8 sections by convention, but no schema validator to date.
- idea-forge has its own workspace convention (`ideas/{slug}/`) separate from `docs/sites/{slug}/`. It is not participating in the site-workspace unification and should not be modified to do so.
