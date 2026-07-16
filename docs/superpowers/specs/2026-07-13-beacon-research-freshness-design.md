# Beacon Research Freshness Signals — Design

- **Date:** 2026-07-13
- **Status:** Approved for planning
- **Roadmap item:** "Research Freshness Signals" (🔜 next in `docs/plugins/beacon/ROADMAP.md`)
- **Scope:** site-intel only — one small helper script + one SKILL.md step change.

## 1. Motivation

site-intel answers questions from a site's pre-built research bundle. That research can be weeks or
months old, and nothing tells the user it might be stale — so a confident answer can be quietly
wrong (a framework upgraded, an endpoint changed). The roadmap item closes that: surface staleness
and give a clear re-run path.

The date already exists — `INDEX.md` carries the OKF **`timestamp:`** frontmatter field (ISO 8601),
set at scaffold time (Phase 1). Nothing new needs to be recorded; site-intel just needs to read it,
compute age against *today*, and warn when old.

**Why a deterministic helper, not prose.** Computing "days since `timestamp`" in the skill's prose
is exactly the failure the repo's governing principle warns against
([[project_plugin-prose-vs-enforcement]]) — and worse here, because it needs two things models are
unreliable at: parsing an ISO-8601 date **and** knowing what "today" is (the wall-clock date is not
something the model reliably holds). A tiny script using the system clock owns both, matching
beacon's existing script pattern (`fleet.py`, `slugify.py`, `okf_validate.py`, `render_query.sh`).

## 2. Goals / Non-goals

**Goals**
- Deterministically classify a research bundle as fresh / stale / date-unknown from its `INDEX.md`.
- Have site-intel prepend a freshness warning to its answer when the research is stale.

**Non-goals**
- Configurable threshold (hardcode 30 days — YAGNI).
- Per-phase "re-run just Phase 3" guidance (beacon has no single-phase re-run; the suggestion is a
  generic full re-analysis). Deferred.
- Any enforcement/hook — freshness is advisory; it must never block or alter an answer's content
  beyond the prepended warning line.
- Writing the freshness state into `INDEX.md` (the signal lives only in site-intel's response).

## 3. Architecture

A single deterministic helper computes the signal; the skill reacts to it.

- **`freshness.py`** reads `INDEX.md`'s `timestamp:` frontmatter, computes whole days between that
  date and *now* (system clock), and prints exactly one signal line. It never crashes and always
  exits 0 — freshness is advisory.
- **site-intel Step 2** ("Open INDEX.md first") runs the helper and, only on a stale signal,
  prepends a one-line warning to the answer it is about to give.

No new output files, no hook, no new agent.

## 4. Components

### 4.1 `plugins/beacon/skills/site-intel/scripts/freshness.py` (+ `test_freshness.py`)

CLI: `python3 freshness.py <path/to/INDEX.md> [--now <ISO-8601>]`

- Parses the file's YAML frontmatter, reads the reserved OKF `timestamp:` field (ISO 8601, e.g.
  `2026-07-02T16:55:00Z`).
- Computes `N = whole days between timestamp and now` (floor; `now` defaults to the real current UTC
  time, overridable via `--now` **solely** so tests are clock-independent).
- Prints exactly one line to stdout and exits 0:

  | Condition | Output |
  |---|---|
  | `N > STALE_AFTER_DAYS` (30) | `[RESEARCH-STALE:{N}d]` |
  | `0 ≤ N ≤ 30` | `[RESEARCH-FRESH:{N}d]` |
  | file missing, no frontmatter, no/empty/unparseable `timestamp`, or `timestamp` in the future | `[RESEARCH-DATE-UNKNOWN]` |

- `STALE_AFTER_DAYS = 30` is a named module constant.
- **Fail-safe:** every error path (missing file, bad YAML, bad date) resolves to
  `[RESEARCH-DATE-UNKNOWN]` and exit 0 — never a traceback, never a false `STALE`. A future-dated
  timestamp (clock skew / bad data) is `DATE-UNKNOWN`, not a negative age.
- Frontmatter parsing follows the same tolerance as beacon's other readers: extract the leading
  `---`…`---` block; if PyYAML is available use it, else a minimal `key: value` line scan for
  `timestamp` (so the script has no hard dependency the repo doesn't already assume).

### 4.2 `plugins/beacon/skills/site-intel/SKILL.md` — Step 2 change

After the existing "Open INDEX.md first" instruction, add: run
`python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-intel/scripts/freshness.py" <INDEX path>`. Then:

- On `[RESEARCH-STALE:{N}d]` → prepend one line to the answer:
  `⚠️ This research is {N} days old (analysed {timestamp date}) and may be out of date — re-run` `/beacon:analyze {url}` `to refresh.` (`{url}` = INDEX `resource:`; `{timestamp date}` = the date part.)
- On `[RESEARCH-FRESH:{N}d]` or `[RESEARCH-DATE-UNKNOWN]` (or if the script is absent/errors) → no
  warning; answer normally.

The warning is prepended **once**, before the substantive answer; it does not repeat per file loaded
or change routing.

## 5. Data flow

```
site-intel query
  Step 1  find docs/sites/{slug}/research/   (or legacy docs/research/{slug}/)
  Step 2  open INDEX.md
          run freshness.py {INDEX}           → one of [RESEARCH-STALE:Nd] | [RESEARCH-FRESH:Nd] | [RESEARCH-DATE-UNKNOWN]
          if STALE → prepend the ⚠️ warning line to the pending answer
  Step 3  route to the specific file(s)       (unchanged)
  Step 4  answer  (warning line first, if any) (unchanged otherwise)
```

## 6. Testing

`test_freshness.py` — pure, no network, `--now` injected for determinism:
- fresh (`--now` 5 days after timestamp) → `[RESEARCH-FRESH:5d]`.
- stale (`--now` 45 days after) → `[RESEARCH-STALE:45d]`.
- **boundary:** exactly 30 days → `FRESH:30d`; 31 days → `STALE:31d`.
- missing `timestamp:` frontmatter → `[RESEARCH-DATE-UNKNOWN]`.
- garbage `timestamp:` value → `[RESEARCH-DATE-UNKNOWN]`.
- missing file → `[RESEARCH-DATE-UNKNOWN]`, exit 0 (no traceback).
- future-dated timestamp → `[RESEARCH-DATE-UNKNOWN]`.
- exit code is 0 on every case.

site-intel's Step-2 prose is not unit-testable (it's a skill instruction); it is covered by the doc
plus the helper's tests, consistent with the rest of beacon's skills.

## 7. Scope / packaging

Ships as a minor bump — **v0.10.0** (next available number; the roadmap's `v0.10.0`/`v0.11.0`
placeholders slip by one, reconciled in the ROADMAP as PR #41 did for fleet). CHANGELOG `[0.10.0]`
Added entry; `site-intel` SKILL.md `version:` bumped; the ROADMAP "Research Freshness Signals" item
moves from 🔜 to ✅ Shipped. No `AGENTS.md` change (no new skill/command). Run
`scripts/sync-skills.sh --check` in the packaging task — no new skill dir is added, so it should
already be in sync, but the check is cheap insurance.
