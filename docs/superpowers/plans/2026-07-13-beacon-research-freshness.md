# Beacon Research Freshness Signals — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** site-intel warns the user when a site's research bundle is stale (>30 days), computed deterministically from `INDEX.md`'s OKF `timestamp:` field by a small helper.

**Architecture:** A `freshness.py` helper reads `INDEX.md`'s `timestamp:` frontmatter and prints one advisory signal (`[RESEARCH-STALE:Nd]` / `[RESEARCH-FRESH:Nd]` / `[RESEARCH-DATE-UNKNOWN]`, always exit 0). site-intel Step 2 runs it and prepends a one-line warning only when stale. No hook, no new output files.

**Tech Stack:** Python 3 (stdlib `datetime`/`re`; optional PyYAML with a regex fallback), pytest, Claude Code skill markdown.

**Spec:** `docs/superpowers/specs/2026-07-13-beacon-research-freshness-design.md`

## Global Constraints

Copied from the spec; every task implicitly includes these.

- **Signal format (exact):** `[RESEARCH-STALE:{N}d]` when `N > 30`; `[RESEARCH-FRESH:{N}d]` when `0 ≤ N ≤ 30`; `[RESEARCH-DATE-UNKNOWN]` when the file is missing / has no frontmatter / `timestamp:` is missing/empty/unparseable / `timestamp:` is in the future. `N` = whole days (floor).
- **Threshold:** `STALE_AFTER_DAYS = 30`, a named constant. Boundary: exactly 30 days → FRESH; 31 → STALE.
- **Fail-safe:** `freshness.py` never raises and **always exits 0** (advisory, not a gate). Every error path → `[RESEARCH-DATE-UNKNOWN]`.
- **`--now <ISO-8601>`** override exists **solely** for test determinism; default is real current UTC time.
- **Advisory only:** freshness never blocks or changes an answer beyond a single prepended warning line; no hook; the signal is never written into `INDEX.md`.
- **Warning copy (on STALE):** `⚠️ This research is {N} days old (analysed {date}) and may be out of date — re-run `/beacon:analyze {url}` to refresh.` where `{url}` = INDEX `resource:`, `{date}` = the date part of `timestamp:`.
- **Version:** minor bump to `0.10.0`.

---

## File Structure

**Create:**
- `plugins/beacon/skills/site-intel/scripts/freshness.py` — the deterministic freshness helper (CLI + importable `freshness()`).
- `plugins/beacon/skills/site-intel/scripts/test_freshness.py` — pure unit tests.

**Modify:**
- `plugins/beacon/skills/site-intel/SKILL.md` — Step 2 runs the helper + prepends the warning; `version:` → `0.10.0`.
- `plugins/beacon/.claude-plugin/plugin.json` — `version` → `0.10.0`.
- `plugins/beacon/CHANGELOG.md` — `[0.10.0]` Added entry.
- `docs/plugins/beacon/ROADMAP.md` — move Research Freshness to Shipped; promote the next item.

---

## Task 1: `freshness.py` deterministic helper

**Files:**
- Create: `plugins/beacon/skills/site-intel/scripts/freshness.py`
- Test: `plugins/beacon/skills/site-intel/scripts/test_freshness.py`

**Interfaces:**
- Produces: CLI `python3 freshness.py <INDEX.md> [--now <ISO-8601>]` printing one signal line, exit 0; importable `freshness(index_path, now=None) -> str`.
- Consumes: nothing (stdlib; optional PyYAML).

- [ ] **Step 1: Write the failing tests**

Create `plugins/beacon/skills/site-intel/scripts/test_freshness.py`:

```python
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
SCRIPT = HERE / "freshness.py"


def write_index(tmp_path, ts_line):
    # ts_line is a full "timestamp: ...\n" line, or "" to omit it
    p = tmp_path / "INDEX.md"
    p.write_text("---\ntype: site-index\n" + ts_line + "status: complete\n---\n# x\n")
    return p


def run(index, now=None):
    args = [sys.executable, str(SCRIPT), str(index)]
    if now:
        args += ["--now", now]
    return subprocess.run(args, capture_output=True, text=True)


def test_fresh(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-07-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-06T00:00:00Z")  # 5 days
    assert r.returncode == 0
    assert r.stdout.strip() == "[RESEARCH-FRESH:5d]"


def test_stale(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-06-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-16T00:00:00Z")  # 45 days
    assert r.stdout.strip() == "[RESEARCH-STALE:45d]"


def test_boundary_30_is_fresh(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-06-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-01T00:00:00Z")  # exactly 30 days
    assert r.stdout.strip() == "[RESEARCH-FRESH:30d]"


def test_boundary_31_is_stale(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-06-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-02T00:00:00Z")  # 31 days
    assert r.stdout.strip() == "[RESEARCH-STALE:31d]"


def test_missing_timestamp(tmp_path):
    idx = write_index(tmp_path, "")  # no timestamp line
    r = run(idx, now="2026-07-16T00:00:00Z")
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_garbage_timestamp(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "not-a-date"\n')
    r = run(idx, now="2026-07-16T00:00:00Z")
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_missing_file(tmp_path):
    r = run(tmp_path / "nope.md", now="2026-07-16T00:00:00Z")
    assert r.returncode == 0
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_future_timestamp(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2027-01-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-16T00:00:00Z")
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_date_only_timestamp(tmp_path):
    idx = write_index(tmp_path, 'timestamp: 2026-06-01\n')  # date-only, unquoted
    r = run(idx, now="2026-07-16T00:00:00Z")  # 45 days
    assert r.stdout.strip() == "[RESEARCH-STALE:45d]"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest plugins/beacon/skills/site-intel/scripts/test_freshness.py -q`
Expected: FAIL — `freshness.py` does not exist (collection error / no such file).

- [ ] **Step 3: Write `freshness.py`**

Create `plugins/beacon/skills/site-intel/scripts/freshness.py`:

```python
#!/usr/bin/env python3
"""Deterministic research-freshness signal for beacon site-intel.

Reads INDEX.md's OKF `timestamp:` frontmatter (ISO 8601, set at scaffold time),
computes whole days since then against the system clock, and prints exactly one
advisory signal line — ALWAYS exit 0, never a traceback:

  [RESEARCH-STALE:{N}d]     when N > 30
  [RESEARCH-FRESH:{N}d]     when 0 <= N <= 30
  [RESEARCH-DATE-UNKNOWN]   file missing / no frontmatter / bad or future timestamp

site-intel Step 2 runs this and prepends a warning ONLY on the STALE signal.
The date is never something the model should compute in prose — the system
clock here is the source of truth.
"""
import re
import sys
from datetime import datetime, timezone

STALE_AFTER_DAYS = 30

try:
    import yaml  # optional; a regex line-scan is used if absent
    _YAML = True
except ImportError:
    _YAML = False


def _read_timestamp(path):
    """Return the raw `timestamp:` string from the file's frontmatter, or None."""
    try:
        text = open(path, encoding="utf-8").read()
    except (OSError, UnicodeDecodeError):
        return None
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        return None
    block = m.group(1)
    if _YAML:
        try:
            data = yaml.safe_load(block)
            if isinstance(data, dict) and data.get("timestamp") not in (None, ""):
                return str(data["timestamp"])
        except yaml.YAMLError:
            pass  # fall through to the line scan
    for line in block.splitlines():
        m2 = re.match(r"\s*timestamp\s*:\s*(.+?)\s*$", line)
        if m2:
            return m2.group(1).strip().strip('"').strip("'") or None
    return None


def _parse_iso(ts):
    """Parse an ISO-8601 (datetime or date-only) string to aware UTC, or None."""
    if not ts:
        return None
    s = str(ts).strip().replace("Z", "+00:00")
    dt = None
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        try:
            dt = datetime.fromisoformat(s[:10])  # date-only fallback
        except ValueError:
            return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def freshness(index_path, now=None):
    """Return the one-line freshness signal for the given INDEX.md path."""
    if now is None:
        now = datetime.now(timezone.utc)
    ts = _parse_iso(_read_timestamp(index_path))
    if ts is None:
        return "[RESEARCH-DATE-UNKNOWN]"
    days = (now - ts).days  # timedelta.days floors toward -inf, so future -> negative
    if days < 0:
        return "[RESEARCH-DATE-UNKNOWN]"  # future-dated / clock skew
    if days > STALE_AFTER_DAYS:
        return f"[RESEARCH-STALE:{days}d]"
    return f"[RESEARCH-FRESH:{days}d]"


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    now = None
    if "--now" in argv:
        i = argv.index("--now")
        if i + 1 < len(argv):
            now = _parse_iso(argv[i + 1])
            del argv[i:i + 2]
        else:
            del argv[i:i + 1]
    if not argv:
        # usage error stays fail-safe: advisory tool never errors out
        print("[RESEARCH-DATE-UNKNOWN]")
        return 0
    print(freshness(argv[0], now=now))
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest plugins/beacon/skills/site-intel/scripts/test_freshness.py -q`
Expected: PASS (9 passed).

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-intel/scripts/freshness.py plugins/beacon/skills/site-intel/scripts/test_freshness.py
git commit -m "feat(beacon): freshness.py — deterministic research-staleness signal"
```

---

## Task 2: Wire into site-intel Step 2 + package v0.10.0

**Files:**
- Modify: `plugins/beacon/skills/site-intel/SKILL.md` (Step 2 + `version:`)
- Modify: `plugins/beacon/.claude-plugin/plugin.json`
- Modify: `plugins/beacon/CHANGELOG.md`
- Modify: `docs/plugins/beacon/ROADMAP.md`

**Interfaces:**
- Consumes: `freshness.py` from Task 1 (CLI signal contract).
- Produces: no code symbols (docs/config).

- [ ] **Step 1: Wire the freshness check into Step 2**

Read `plugins/beacon/skills/site-intel/SKILL.md`. Find `## Step 2: Open INDEX.md first`. Immediately after its existing instruction to open `INDEX.md`, insert this block (verbatim):

```markdown
Then check research freshness deterministically — do not compute the age yourself:

​```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-intel/scripts/freshness.py" {INDEX path}
​```

- `[RESEARCH-STALE:{N}d]` → **prepend one line** to your eventual answer:
  `⚠️ This research is {N} days old (analysed {date}) and may be out of date — re-run \`/beacon:analyze {url}\` to refresh.`
  (`{url}` = INDEX frontmatter `resource:`; `{date}` = the date part of `timestamp:`.)
- `[RESEARCH-FRESH:{N}d]`, `[RESEARCH-DATE-UNKNOWN]`, or a missing/errored script → no warning; answer normally.

The warning is prepended once, before the answer; it does not repeat per file loaded and never changes routing.
```

(The ​``` fences above are shown with a zero-width marker so they nest in this plan — write them as normal triple backticks.)

- [ ] **Step 2: Bump the site-intel skill version**

In `plugins/beacon/skills/site-intel/SKILL.md` frontmatter, change `version: 0.8.0` to `version: 0.10.0`.

- [ ] **Step 3: Bump plugin.json**

In `plugins/beacon/.claude-plugin/plugin.json`, change `"version": "0.9.0"` to `"version": "0.10.0"`.

- [ ] **Step 4: Add the CHANGELOG entry**

In `plugins/beacon/CHANGELOG.md`, insert a new dated section immediately **above** the `## [0.9.0] — 2026-07-12` line:

```markdown
## [0.10.0] — 2026-07-13

### Added
- **Research Freshness Signals**: `site-intel` now warns when a site's research is stale. Step 2
  runs `skills/site-intel/scripts/freshness.py`, which reads `INDEX.md`'s OKF `timestamp:` field and
  emits `[RESEARCH-STALE:{N}d]` / `[RESEARCH-FRESH:{N}d]` / `[RESEARCH-DATE-UNKNOWN]` against the
  system clock (30-day threshold, fail-safe, always exit 0). On a stale bundle site-intel prepends a
  one-line warning suggesting a `/beacon:analyze` re-run. Advisory only — no hook, no INDEX changes.

---
```

- [ ] **Step 5: Update the ROADMAP**

In `docs/plugins/beacon/ROADMAP.md`:

1. In the `## Shipped` table, add this row after the `✅ v0.9.0` fleet row:
   ```markdown
   | ✅ v0.10.0 | **Research Freshness Signals** — site-intel stale-research warnings via `freshness.py` (30-day threshold, deterministic) | site-intel-only; advisory, no hook |
   ```
2. Change the heading `## Research Freshness Signals — 🔜 next` to `## Research Freshness Signals — ✅ SHIPPED (v0.10.0)`.
3. Promote the next backlog item: change `## Additional Tech Packs — 📋 planned` to `## Additional Tech Packs — 🔜 next`.
4. End the version-number collision (Research Freshness took v0.10.0): change `## v0.10.0 — Multi-Site Comparison` to `## Multi-Site Comparison — 📋 planned`, and `## v0.11.0 — Export Formats` to `## Export Formats — 📋 planned` (consistent with the roadmap's own "numbers assigned at release" convention).

- [ ] **Step 6: Verify the full regression + packaging**

Run:
```bash
python3 -m pytest plugins/beacon/skills/site-intel/scripts/test_freshness.py -q
bash scripts/sync-skills.sh --check
python3 -m json.tool plugins/beacon/.claude-plugin/plugin.json > /dev/null && echo "plugin.json OK ($(grep '\"version\"' plugins/beacon/.claude-plugin/plugin.json | tr -d ' '))"
python3 -c "import yaml; yaml.safe_load(open('plugins/beacon/skills/site-intel/SKILL.md').read().split('---')[1]); print('site-intel frontmatter OK')"
grep -q '## \[0.10.0\]' plugins/beacon/CHANGELOG.md && echo "CHANGELOG 0.10.0 OK"
grep -q 'Research Freshness Signals — ✅ SHIPPED' docs/plugins/beacon/ROADMAP.md && echo "ROADMAP shipped OK"
```
Expected: all green — freshness tests pass, sync-skills farm OK (no new skill dir), plugin.json valid at 0.10.0, site-intel frontmatter parses, CHANGELOG + ROADMAP updated.

- [ ] **Step 7: Commit**

```bash
git add plugins/beacon/skills/site-intel/SKILL.md plugins/beacon/.claude-plugin/plugin.json plugins/beacon/CHANGELOG.md docs/plugins/beacon/ROADMAP.md
git commit -m "feat(beacon): wire research-freshness warning into site-intel; v0.10.0"
```

---

## Notes for the executor

- `freshness.py` follows beacon's established frontmatter-reader tolerance (PyYAML if present, else a
  regex line-scan) — same pattern as `okf_validate.py`. Do not add a hard PyYAML dependency.
- `timedelta.days` floors toward negative infinity, which is why a future timestamp yields a negative
  `days` and maps to `[RESEARCH-DATE-UNKNOWN]` — keep that check.
- Step 2's wiring is skill prose (not unit-testable); the deterministic behavior lives entirely in
  `freshness.py`, which is fully tested. That split is intentional.
- No `AGENTS.md` change and no new skill directory, so `sync-skills.sh --check` should already pass —
  the check in Task 2 Step 6 is cheap insurance, not a fix.
