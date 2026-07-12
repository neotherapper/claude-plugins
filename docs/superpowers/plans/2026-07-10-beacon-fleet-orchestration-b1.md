# Beacon Fleet Orchestration — B1 Sequential Core — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/beacon:fleet` command that recons a list of sources one at a time through the real `site-analyst`, wrapped by a durable ledger and a deterministic completeness gate that closes the Option-A residual gap.

**Architecture:** Sequential fleet. Each source is reconned whole (Phases 1–12) in one context, so Subsystem A's per-source output contract is reused unchanged. A `fleet.py` script owns a durable `docs/sites/.fleet/` ledger (init/update/pending/sweep/pause/resume/waive/close); a `Stop`-only `fleet-sweep.sh` hook blocks the orchestrator's stop until every source is terminal. A shared `slugify.py` gives `scaffold.sh` and `fleet.py` one slug rule.

**Tech Stack:** Python 3 (stdlib only: `argparse`, `json`, `fcntl`, `subprocess`, `os`, `re`, `datetime`), Bash, pytest, Claude Code plugin skills/commands/hooks.

**Spec:** `docs/superpowers/specs/2026-07-10-beacon-fleet-orchestration-design.md`

## Global Constraints

Copied verbatim from the spec; every task's requirements implicitly include these.

- **Sequential only.** One source reconned at a time; each source reconned **whole (Phases 1–12) in a single context**. The `SKILL.md:700` / `site-analyst.md:47` split (background subagent 1–9, main 10–11) is **prohibited in B1** — it re-opens the N-C1 content seam. No parallelism, concurrency cap, browser serialization, capability-restricted agent, content hand-off, or rate-limit backoff (all deferred to B2).
- **Ledger location:** `docs/sites/.fleet/` — `fleet-<ts>.json` (source of truth, `<ts>` = UTC second precision + `-<pid>`), `fleet-<ts>.md` (regenerated view), `active.json` = `{"ledger": "<path>"}` (pure pointer; `state` lives in the ledger). Resolved **relative to repo root** (the cwd convention `okf-gate.sh`/`scaffold.sh` use). Never inside a per-source bundle root.
- **Ledger `state`:** `active | paused`. **Source `status`:** `pending | reconning | complete | blocked | inconclusive`. **Terminal states:** `complete`, `blocked`. **Verdict:** `complete | blocked:<reason> | inconclusive | null`.
- **Completeness signal of record** is `INDEX.md` `status` via `okf_validate.py --is-complete` (deterministic). `verdict` is advisory metadata; a bad verdict can never force a `complete`.
- **Single-writer invariant:** the main session is the only ledger writer; `fleet.py update` takes an `flock`.
- **Anti-clobber:** `init` refuses when `active.json` points at an unresolved fleet.
- **Deterministic re-arm:** `fleet.py pending` flips `state: paused → active` as a side effect.
- **Skill entry branch:** args → `init`; no args (or an already-active fleet) → `pending`, never `init`.
- **Canonical slug:** one `slugify.py`; `scaffold.sh` and `fleet.py` call it; keep the `sed` copies in `docs/SLUG_RULES.md` and reframe's `SKILL.md`.
- **Version:** minor bump to `0.8.0`.

---

## File Structure

**Create:**
- `plugins/beacon/skills/site-recon/scripts/slugify.py` — canonical URL→slug (CLI + importable `slugify()`).
- `plugins/beacon/skills/site-recon/scripts/test_slugify.py` — slug fixtures.
- `plugins/beacon/skills/site-recon/scripts/fleet.py` — ledger + sweep + lifecycle CLI.
- `plugins/beacon/skills/site-recon/scripts/test_fleet.py` — fleet unit tests.
- `plugins/beacon/hooks/fleet-sweep.sh` — `Stop`-only completeness gate.
- `plugins/beacon/hooks/test_fleet_sweep.sh` — hook harness.
- `plugins/beacon/skills/site-fleet/SKILL.md` — the orchestration skill.
- `plugins/beacon/commands/beacon-fleet.md` — the `/beacon:fleet` command.

**Modify:**
- `plugins/beacon/skills/site-recon/scripts/scaffold.sh:6` — call `slugify.py` instead of inline `sed`.
- `tests/validate-slug-rule.sh` — extend to cover `slugify.py`.
- `plugins/beacon/hooks/hooks.json` — register `fleet-sweep.sh` on `Stop`.
- `plugins/beacon/.claude-plugin/plugin.json` — version `0.8.0`.
- `plugins/beacon/CHANGELOG.md` — `[Unreleased]` Added entry.
- `docs/SLUG_RULES.md` — point implementers at `slugify.py` (keep the `sed` copy).
- `AGENTS.md` — register the `site-fleet` skill + intent mapping.

---

## Task 1: Decide the dispatch actor (spike)

**Files:**
- Create: `docs/superpowers/plans/notes/2026-07-10-fleet-dispatch-actor.md`

**Interfaces:**
- Produces: a recorded decision — `ACTOR = subagent | main-session-loop` — consumed by Task 7's skill prose.

This is a blocking investigation (spec §14 Task 0), not a code task. The spec's preferred actor is "`site-analyst` as a foreground subagent per source"; the safe fallback is "main session runs the whole `site-recon` per source." The deterministic core (Tasks 2–6) does not depend on the outcome — only Task 7's dispatch prose does.

- [ ] **Step 1: Attempt the spike**

Dispatch `site-analyst` as a **foreground** subagent (run to completion) against one simple, low-risk site, asking it to run the full recon end-to-end (`scaffold.sh` + curl passive phases + one browser Phase-11 step) and report whether each worked. Observe: did it produce a `status: complete` bundle, and did the browser step run inside the subagent?

- [ ] **Step 2: Apply the decision rule**

- If the foreground subagent completed a full recon **including** the browser step → `ACTOR = subagent`.
- If it could not (browser/Bash unavailable to subagents) **or the spike is impractical to run in this environment** → `ACTOR = main-session-loop` (the safe default; the subagent path becomes a documented B-future optimization).

- [ ] **Step 3: Record and commit the decision**

Write `docs/superpowers/plans/notes/2026-07-10-fleet-dispatch-actor.md` with: what was attempted, what was observed, and the chosen `ACTOR` with one sentence of rationale.

```bash
git add docs/superpowers/plans/notes/2026-07-10-fleet-dispatch-actor.md
git commit -m "spike(beacon): decide fleet dispatch actor (Task 0)"
```

---

## Task 2: Canonical slug helper `slugify.py`

**Files:**
- Create: `plugins/beacon/skills/site-recon/scripts/slugify.py`
- Test: `plugins/beacon/skills/site-recon/scripts/test_slugify.py`

**Interfaces:**
- Produces: `slugify(url: str) -> str` (importable) and a CLI `python3 slugify.py <url>` printing the slug. Consumed by `scaffold.sh` (Task 3) and `fleet.py` (Task 4).

- [ ] **Step 1: Write the failing test**

Create `plugins/beacon/skills/site-recon/scripts/test_slugify.py`:

```python
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))
import slugify as S

# (input url, expected slug) — mirrors scaffold.sh's historical sed rule
CASES = [
    ("https://example.com", "example-com"),
    ("http://example.com/", "example-com"),
    ("https://www.jetpens.com", "jetpens-com"),
    ("https://api.example.com:8080/v1/things", "api-example-com"),
    ("HTTPS://Example.COM/Path", "example-com"),
    ("https://msi.nga.mil/NavWarnings", "msi-nga-mil"),
    ("example.com", "example-com"),
]


@pytest.mark.parametrize("url,expected", CASES)
def test_slugify_func(url, expected):
    assert S.slugify(url) == expected


@pytest.mark.parametrize("url,expected", CASES)
def test_slugify_cli(url, expected):
    out = subprocess.run(
        [sys.executable, str(Path(__file__).parent / "slugify.py"), url],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    assert out == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_slugify.py -q`
Expected: FAIL — `ModuleNotFoundError: No module named 'slugify'`.

- [ ] **Step 3: Write minimal implementation**

Create `plugins/beacon/skills/site-recon/scripts/slugify.py`:

```python
#!/usr/bin/env python3
"""Canonical URL->slug for beacon — the single source of truth.

Mirrors the rule documented in docs/SLUG_RULES.md. Both scaffold.sh and
fleet.py call this so the scaffolder and the fleet ledger can never disagree
on a slug (a mismatch would make fleet.py read the wrong INDEX.md).

Rule (order matters): lowercase -> strip scheme -> strip leading www. ->
strip path -> strip :port -> dots to dashes.
"""
import re
import sys


def slugify(url: str) -> str:
    s = url.strip().lower()
    s = re.sub(r"^https?://", "", s)
    s = re.sub(r"^www\.", "", s)
    s = re.sub(r"/.*$", "", s)
    s = re.sub(r":[0-9]+$", "", s)
    return s.replace(".", "-")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.stderr.write("usage: slugify.py <url>\n")
        sys.exit(2)
    print(slugify(sys.argv[1]))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_slugify.py -q`
Expected: PASS (14 passed).

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/slugify.py plugins/beacon/skills/site-recon/scripts/test_slugify.py
git commit -m "feat(beacon): canonical slugify.py slug helper"
```

---

## Task 3: Switch `scaffold.sh` to `slugify.py` + extend the drift guard

**Files:**
- Modify: `plugins/beacon/skills/site-recon/scripts/scaffold.sh:6`
- Modify: `tests/validate-slug-rule.sh`

**Interfaces:**
- Consumes: `slugify.py` from Task 2.
- Produces: no new symbols; `scaffold.sh` now produces slugs via `slugify.py`.

- [ ] **Step 1: Point scaffold.sh at slugify.py**

In `plugins/beacon/skills/site-recon/scripts/scaffold.sh`, replace line 6:

```bash
SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
```

with (the file already sets `DIR=$(cd "$(dirname "$0")" && pwd)` on line 3):

```bash
SLUG=$(python3 "$DIR/slugify.py" "$URL")
```

- [ ] **Step 2: Verify scaffold regression still passes**

Run: `bash plugins/beacon/skills/site-recon/scripts/test_scaffold.sh`
Expected: `OK` (the suite passes an explicit `OUTPUT_ROOT` and checks the `resource:` URL; the slug change must not break it).

- [ ] **Step 3: Extend the slug drift guard**

`tests/validate-slug-rule.sh` currently greps for the `sed` one-liner and tests an inline bash `slugify()`. Add a check that runs `slugify.py` against the same case table. Append this block before the guard's final success echo (adapt the exact case list to the ones already in the guard):

```bash
# --- Check 3: slugify.py (beacon runtime) matches the canonical rule ---
SLUGIFY_PY="plugins/beacon/skills/site-recon/scripts/slugify.py"
declare -A SLUG_CASES=(
  ["https://www.jetpens.com"]="jetpens-com"
  ["https://api.example.com:8080/v1"]="api-example-com"
  ["HTTPS://Example.COM/Path"]="example-com"
)
for url in "${!SLUG_CASES[@]}"; do
  got=$(python3 "$SLUGIFY_PY" "$url")
  [ "$got" = "${SLUG_CASES[$url]}" ] || { echo "FAIL: slugify.py '$url' -> '$got' != '${SLUG_CASES[$url]}'"; exit 1; }
done
echo "Check 3 OK: slugify.py matches canonical rule"
```

- [ ] **Step 4: Run the drift guard**

Run: `bash tests/validate-slug-rule.sh`
Expected: all checks pass, including `Check 3 OK`. (The `sed` copies in `docs/SLUG_RULES.md` and reframe's `SKILL.md` remain, so the guard's "found a slug-rule copy" check still passes.)

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/scaffold.sh tests/validate-slug-rule.sh
git commit -m "refactor(beacon): scaffold.sh uses slugify.py; drift guard covers it"
```

---

## Task 4: `fleet.py` — ledger I/O + `init` / `update` / `pending`

**Files:**
- Create: `plugins/beacon/skills/site-recon/scripts/fleet.py`
- Test: `plugins/beacon/skills/site-recon/scripts/test_fleet.py`

**Interfaces:**
- Consumes: `slugify.py` (Task 2), `okf_validate.py --is-complete` (existing).
- Produces (CLI, all resolving `docs/sites/.fleet/` from cwd):
  - `init <url…>` → writes ledger + `active.json`; refuses duplicate slugs and an already-active unresolved fleet; prints `[FLEET:<path>]`.
  - `update <slug> --status S [--verdict V] [--agent-id A]` → mutates one row under `flock`.
  - `pending` → flips `paused→active`, prints non-terminal slugs one per line.
- Produces (importable, for tests): module functions `slug_of`, `ledger_path`, `load`, and the `cmd_*` handlers.

- [ ] **Step 1: Write the failing tests**

Create `plugins/beacon/skills/site-recon/scripts/test_fleet.py`:

```python
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

HERE = Path(__file__).parent
FLEET = HERE / "fleet.py"


def run(args, cwd):
    return subprocess.run(
        [sys.executable, str(FLEET), *args],
        cwd=cwd, capture_output=True, text=True,
    )


def read_active(root):
    return json.loads((root / "docs/sites/.fleet/active.json").read_text())


def read_ledger(root):
    path = read_active(root)["ledger"]
    return json.loads((root / path).read_text())


def test_init_creates_ledger_and_active(tmp_path):
    r = run(["init", "https://a.com", "https://b.com"], tmp_path)
    assert r.returncode == 0
    assert r.stdout.startswith("[FLEET:")
    led = read_ledger(tmp_path)
    assert led["state"] == "active"
    assert set(led["sources"]) == {"a-com", "b-com"}
    assert led["sources"]["a-com"]["status"] == "pending"


def test_init_rejects_duplicate_slug(tmp_path):
    r = run(["init", "https://a.com/x", "https://a.com/y"], tmp_path)
    assert r.returncode == 2
    assert "duplicate slug" in r.stderr


def test_init_refuses_second_active_fleet(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    r = run(["init", "https://b.com"], tmp_path)
    assert r.returncode == 2
    assert "already active" in r.stderr


def test_update_mutates_row(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    r = run(["update", "a-com", "--status", "reconning", "--agent-id", "x1"], tmp_path)
    assert r.returncode == 0
    led = read_ledger(tmp_path)
    assert led["sources"]["a-com"]["status"] == "reconning"
    assert led["sources"]["a-com"]["agent_id"] == "x1"


def test_pending_lists_non_terminal_and_rearms(tmp_path):
    run(["init", "https://a.com", "https://b.com"], tmp_path)
    run(["update", "a-com", "--status", "complete", "--verdict", "complete"], tmp_path)
    run(["pause"], tmp_path)  # defined in Task 5; import-time presence is fine
    r = run(["pending"], tmp_path)
    assert r.returncode == 0
    assert r.stdout.split() == ["b-com"]
    assert read_ledger(tmp_path)["state"] == "active"  # re-armed
```

Note: `test_pending_lists_non_terminal_and_rearms` calls `pause`, added in Task 5. Until then it will error on the `pause` subcommand; that is expected and turns green after Task 5. Run the other four tests in Step 2.

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_fleet.py -q -k "not rearms"`
Expected: FAIL — `fleet.py` does not exist yet.

- [ ] **Step 3: Write `fleet.py` with I/O + init/update/pending**

Create `plugins/beacon/skills/site-recon/scripts/fleet.py`:

```python
#!/usr/bin/env python3
"""Beacon fleet ledger + completeness sweep (Subsystem B1).

Sequential-fleet state lives under docs/sites/.fleet/, resolved relative to the
repo root (the cwd convention okf-gate.sh and scaffold.sh already use). The main
session is the single writer; `update` takes an flock for defense in depth.
"""
import argparse
import fcntl
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

FLEET_DIR = os.path.join("docs", "sites", ".fleet")
ACTIVE = os.path.join(FLEET_DIR, "active.json")
TERMINAL = {"complete", "blocked"}
_SCRIPTS = os.path.dirname(os.path.abspath(__file__))
VALIDATE = os.path.join(_SCRIPTS, "okf_validate.py")
SLUGIFY = os.path.join(_SCRIPTS, "slugify.py")


def slug_of(url):
    return subprocess.run(
        [sys.executable, SLUGIFY, url],
        capture_output=True, text=True, check=True,
    ).stdout.strip()


def _now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _stamp():
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + str(os.getpid())


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def ledger_path():
    if not os.path.isfile(ACTIVE):
        return None
    return load(ACTIVE).get("ledger")


def index_path(slug):
    return os.path.join("docs", "sites", slug, "research", "INDEX.md")


def is_complete(slug):
    idx = index_path(slug)
    if not os.path.isfile(idx):
        return False
    return subprocess.run(
        [sys.executable, VALIDATE, "--is-complete", idx],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0


def _render_md(led):
    out = [f"# Fleet ledger — created {led['created']} — state: {led['state']}", "",
           "| slug | status | verdict | url |", "|------|--------|---------|-----|"]
    for slug, s in led["sources"].items():
        out.append(f"| {slug} | {s['status']} | {s['verdict'] or ''} | {s['url']} |")
    return "\n".join(out) + "\n"


def _write(path, led):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(led, f, indent=2)
    with open(path[:-5] + ".md", "w", encoding="utf-8") as f:
        f.write(_render_md(led))


def _mutate(fn):
    """Read-modify-write the active ledger under flock; regenerate the .md."""
    path = ledger_path()
    if not path or not os.path.isfile(path):
        sys.stderr.write("[FLEET-ERROR] no active fleet (missing active.json)\n")
        return None
    with open(path, "r+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        try:
            f.seek(0)
            led = json.load(f)
            fn(led)
            f.seek(0)
            f.truncate()
            json.dump(led, f, indent=2)
            f.flush()
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)
    with open(path[:-5] + ".md", "w", encoding="utf-8") as f:
        f.write(_render_md(led))
    return led


def cmd_init(a):
    resolved = {}
    for url in a.urls:
        s = slug_of(url)
        if s in resolved:
            sys.stderr.write(
                f"[FLEET-ERROR] duplicate slug '{s}' from URLs "
                f"'{resolved[s]}' and '{url}' — one bundle per source; remove one.\n")
            return 2
        resolved[s] = url
    existing = ledger_path()
    if existing and os.path.isfile(existing):
        led = load(existing)
        if any(v["status"] not in TERMINAL for v in led["sources"].values()):
            sys.stderr.write(
                f"[FLEET-ERROR] an unresolved fleet is already active ({existing}). "
                f"Run 'fleet.py pending' to resume it, or 'fleet.py close' to abandon "
                f"it, before starting a new one.\n")
            return 2
    os.makedirs(FLEET_DIR, exist_ok=True)
    led = {"created": _now(), "state": "active",
           "sources": {s: {"url": u, "agent_id": None, "status": "pending",
                           "verdict": None, "retries": 0}
                       for s, u in resolved.items()}}
    path = os.path.join(FLEET_DIR, f"fleet-{_stamp()}.json")
    _write(path, led)
    with open(ACTIVE, "w", encoding="utf-8") as f:
        json.dump({"ledger": path}, f)
    print(f"[FLEET:{path}]")
    return 0


def cmd_update(a):
    def fn(led):
        if a.slug not in led["sources"]:
            raise KeyError(a.slug)
        row = led["sources"][a.slug]
        row["status"] = a.status
        if a.verdict is not None:
            row["verdict"] = a.verdict
        if a.agent_id is not None:
            row["agent_id"] = a.agent_id
    try:
        return 0 if _mutate(fn) is not None else 1
    except KeyError as e:
        sys.stderr.write(f"[FLEET-ERROR] unknown slug {e}\n")
        return 2


def cmd_pending(a):
    # deterministic re-arm: resuming un-pauses so the gate can never stay disarmed
    led = _mutate(lambda l: l.__setitem__("state", "active"))
    if led is None:
        return 1
    for slug, s in led["sources"].items():
        if s["status"] not in TERMINAL:
            print(slug)
    return 0


def build_parser():
    p = argparse.ArgumentParser(prog="fleet.py")
    sub = p.add_subparsers(dest="cmd", required=True)
    pi = sub.add_parser("init"); pi.add_argument("urls", nargs="+"); pi.set_defaults(fn=cmd_init)
    pu = sub.add_parser("update")
    pu.add_argument("slug")
    pu.add_argument("--status", required=True)
    pu.add_argument("--verdict")
    pu.add_argument("--agent-id", dest="agent_id")
    pu.set_defaults(fn=cmd_update)
    pp = sub.add_parser("pending"); pp.set_defaults(fn=cmd_pending)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_fleet.py -q -k "not rearms"`
Expected: PASS (4 passed).

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/fleet.py plugins/beacon/skills/site-recon/scripts/test_fleet.py
git commit -m "feat(beacon): fleet.py ledger core (init/update/pending)"
```

---

## Task 5: `fleet.py` — `sweep` / `pause` / `resume` / `waive` / `close`

**Files:**
- Modify: `plugins/beacon/skills/site-recon/scripts/fleet.py`
- Modify: `plugins/beacon/skills/site-recon/scripts/test_fleet.py`

**Interfaces:**
- Consumes: the Task-4 module.
- Produces (CLI): `sweep` (prints `[FLEET-COMPLETE]` or `[FLEET-INCOMPLETE:<slug>:<reason>]…`, exit 0 always), `pause`, `resume`, `waive <slug> [--reason R]`, `close`.

- [ ] **Step 1: Write the failing tests**

Append to `plugins/beacon/skills/site-recon/scripts/test_fleet.py`:

```python
def _mk_index(root, slug, status):
    d = root / "docs/sites" / slug / "research"
    d.mkdir(parents=True, exist_ok=True)
    (d / "INDEX.md").write_text(
        f"---\ntype: site-index\nstatus: {status}\n---\n# {slug}\n")


def test_sweep_flags_incomplete(tmp_path):
    run(["init", "https://a.com", "https://b.com"], tmp_path)
    _mk_index(tmp_path, "a-com", "complete")
    run(["update", "a-com", "--status", "complete", "--verdict", "complete"], tmp_path)
    _mk_index(tmp_path, "b-com", "draft")
    run(["update", "b-com", "--status", "inconclusive", "--verdict", "inconclusive"], tmp_path)
    r = run(["sweep"], tmp_path)
    assert r.returncode == 0
    assert "[FLEET-INCOMPLETE:b-com:inconclusive]" in r.stdout
    assert "a-com" not in r.stdout


def test_sweep_all_complete(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    _mk_index(tmp_path, "a-com", "complete")
    run(["update", "a-com", "--status", "complete", "--verdict", "complete"], tmp_path)
    r = run(["sweep"], tmp_path)
    assert "[FLEET-COMPLETE]" in r.stdout


def test_sweep_missing_index_is_incomplete(tmp_path):
    run(["init", "https://a.com"], tmp_path)  # no INDEX written
    run(["update", "a-com", "--status", "reconning"], tmp_path)
    r = run(["sweep"], tmp_path)
    assert "[FLEET-INCOMPLETE:a-com:" in r.stdout


def test_pause_sets_state(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    run(["pause"], tmp_path)
    assert read_ledger(tmp_path)["state"] == "paused"


def test_waive_makes_terminal(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    run(["waive", "a-com", "--reason", "auth-gated"], tmp_path)
    row = read_ledger(tmp_path)["sources"]["a-com"]
    assert row["status"] == "blocked"
    assert row["verdict"] == "blocked:auth-gated"


def test_close_removes_active(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    run(["close"], tmp_path)
    assert not (tmp_path / "docs/sites/.fleet/active.json").exists()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_fleet.py -q -k "sweep or pause or waive or close or rearms"`
Expected: FAIL — those subcommands are unknown.

- [ ] **Step 3: Add the handlers and register them**

In `fleet.py`, add these handlers above `build_parser`:

```python
def cmd_sweep(a):
    path = ledger_path()
    if not path or not os.path.isfile(path):
        sys.stderr.write("[FLEET-ERROR] no active fleet\n")
        return 1
    led = load(path)
    incomplete = []
    for slug, s in led["sources"].items():
        if is_complete(slug):
            continue
        reason = (s["verdict"] or s["status"] or "unknown")
        # fail toward flagging: a missing/invalid INDEX counts as incomplete
        incomplete.append((slug, reason))
    if not incomplete:
        print("[FLEET-COMPLETE]")
    else:
        for slug, reason in incomplete:
            print(f"[FLEET-INCOMPLETE:{slug}:{reason}]")
    return 0


def cmd_pause(a):
    return 0 if _mutate(lambda l: l.__setitem__("state", "paused")) is not None else 1


def cmd_resume(a):
    return 0 if _mutate(lambda l: l.__setitem__("state", "active")) is not None else 1


def cmd_waive(a):
    def fn(led):
        row = led["sources"][a.slug]
        row["status"] = "blocked"
        row["verdict"] = f"blocked:{a.reason or 'waived'}"
    return 0 if _mutate(fn) is not None else 1


def cmd_close(a):
    if os.path.isfile(ACTIVE):
        os.remove(ACTIVE)
    print("[FLEET-CLOSED]")
    return 0
```

Then extend `build_parser` (add before `return p`):

```python
    ps = sub.add_parser("sweep"); ps.set_defaults(fn=cmd_sweep)
    sub.add_parser("pause").set_defaults(fn=cmd_pause)
    sub.add_parser("resume").set_defaults(fn=cmd_resume)
    pw = sub.add_parser("waive"); pw.add_argument("slug"); pw.add_argument("--reason")
    pw.set_defaults(fn=cmd_waive)
    sub.add_parser("close").set_defaults(fn=cmd_close)
```

- [ ] **Step 4: Run the full fleet test suite**

Run: `python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_fleet.py -q`
Expected: PASS (all tests, including `rearms`).

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/fleet.py plugins/beacon/skills/site-recon/scripts/test_fleet.py
git commit -m "feat(beacon): fleet.py sweep + pause/resume/waive/close"
```

---

## Task 6: `fleet-sweep.sh` Stop hook + register it

**Files:**
- Create: `plugins/beacon/hooks/fleet-sweep.sh`
- Test: `plugins/beacon/hooks/test_fleet_sweep.sh`
- Modify: `plugins/beacon/hooks/hooks.json`

**Interfaces:**
- Consumes: `fleet.py` (`sweep`), `docs/sites/.fleet/active.json`, the ledger `state`.
- Produces: exit 0 (no fleet / paused / all-terminal → deactivates) or exit 2 with `[FLEET-SWEEP-PENDING:<slugs>]` (unresolved).

- [ ] **Step 1: Write the failing test harness**

Create `plugins/beacon/hooks/test_fleet_sweep.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
HOOK="$DIR/fleet-sweep.sh"
FLEET="$DIR/../skills/site-recon/scripts/fleet.py"

# case 1: no active.json -> exit 0, no-op
T1=$(mktemp -d); ( cd "$T1" && bash "$HOOK" ); [ $? -eq 0 ] || { echo "FAIL case1"; exit 1; }

# case 2: all-terminal fleet -> exit 0 AND active.json removed
T2=$(mktemp -d)
( cd "$T2" && python3 "$FLEET" init https://a.com >/dev/null
  mkdir -p docs/sites/a-com/research
  printf -- '---\ntype: site-index\nstatus: complete\n---\n' > docs/sites/a-com/research/INDEX.md
  python3 "$FLEET" update a-com --status complete --verdict complete >/dev/null
  bash "$HOOK" )
rc=$?; [ $rc -eq 0 ] || { echo "FAIL case2 rc=$rc"; exit 1; }
[ ! -f "$T2/docs/sites/.fleet/active.json" ] || { echo "FAIL case2 not deactivated"; exit 1; }

# case 3: unresolved fleet -> exit 2 with [FLEET-SWEEP-PENDING]
T3=$(mktemp -d)
out=$( cd "$T3" && python3 "$FLEET" init https://a.com >/dev/null
       python3 "$FLEET" update a-com --status reconning >/dev/null
       bash "$HOOK" 2>&1 )
rc=$?; [ $rc -eq 2 ] || { echo "FAIL case3 rc=$rc"; exit 1; }
grep -q "\[FLEET-SWEEP-PENDING:" <<<"$out" || { echo "FAIL case3 no marker: $out"; exit 1; }

# case 4: paused fleet -> exit 0 no-op, active.json preserved
T4=$(mktemp -d)
( cd "$T4" && python3 "$FLEET" init https://a.com >/dev/null
  python3 "$FLEET" update a-com --status reconning >/dev/null
  python3 "$FLEET" pause >/dev/null
  bash "$HOOK" )
rc=$?; [ $rc -eq 0 ] || { echo "FAIL case4 rc=$rc"; exit 1; }
[ -f "$T4/docs/sites/.fleet/active.json" ] || { echo "FAIL case4 dropped handle"; exit 1; }

echo "OK"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash plugins/beacon/hooks/test_fleet_sweep.sh`
Expected: FAIL — `fleet-sweep.sh` does not exist.

- [ ] **Step 3: Write the hook**

Create `plugins/beacon/hooks/fleet-sweep.sh`:

```bash
#!/usr/bin/env bash
# Beacon fleet completeness gate (Subsystem B1). Registered on `Stop` ONLY
# (never SubagentStop — it must not fire on per-source subagent completion).
# Closes the Option-A residual gap: an abandoned/zero-output source stays
# non-terminal, so this blocks the orchestrator's stop until every source is
# complete/blocked/waived — regardless of whether the skill prose ran `sweep`.
set -uo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
FLEET="$HOOKS/../skills/site-recon/scripts/fleet.py"
ACTIVE="docs/sites/.fleet/active.json"

[ -f "$ACTIVE" ] || exit 0   # no fleet in flight

LEDGER=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['ledger'])" "$ACTIVE" 2>/dev/null)
[ -n "$LEDGER" ] && [ -f "$LEDGER" ] || exit 0   # unreadable handle -> don't block on our own bug

STATE=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('state',''))" "$LEDGER" 2>/dev/null)
[ "$STATE" = "paused" ] && exit 0   # intentional multi-session pause; handle preserved

SWEEP=$(python3 "$FLEET" sweep 2>/dev/null)
if grep -q '\[FLEET-INCOMPLETE:' <<<"$SWEEP"; then
  SLUGS=$(grep -oE '\[FLEET-INCOMPLETE:[^:]+' <<<"$SWEEP" | sed 's/\[FLEET-INCOMPLETE://' | paste -sd, -)
  echo "[FLEET-SWEEP-PENDING:$SLUGS] fleet has unresolved sources — finish, waive, or 'fleet.py pause'/'close'" >&2
  echo "$SWEEP" >&2
  exit 2
fi
# all terminal -> deactivate so later, unrelated stops no-op
rm -f "$ACTIVE"
exit 0
```

- [ ] **Step 4: Run to verify it passes**

Run: `bash plugins/beacon/hooks/test_fleet_sweep.sh`
Expected: `OK`.

- [ ] **Step 5: Register the hook on `Stop`**

In `plugins/beacon/hooks/hooks.json`, add a `Stop` entry pointing at `fleet-sweep.sh` (keep existing `Stop`/`SubagentStop`/`SessionStart` entries). The `Stop` array should include both the existing `okf-gate.sh` and the new `fleet-sweep.sh`:

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/fleet-sweep.sh",
  "timeout": 30
}
```

Verify the file is valid JSON: `python3 -m json.tool plugins/beacon/hooks/hooks.json > /dev/null && echo "hooks.json OK"`

- [ ] **Step 6: Confirm `fleet-sweep.sh` is NOT on `SubagentStop`**

Read `hooks.json` and confirm `fleet-sweep.sh` appears only under `Stop` (never `SubagentStop`) — a `SubagentStop` registration would block every per-source subagent completion.

- [ ] **Step 7: Commit**

```bash
git add plugins/beacon/hooks/fleet-sweep.sh plugins/beacon/hooks/test_fleet_sweep.sh plugins/beacon/hooks/hooks.json
git commit -m "feat(beacon): fleet-sweep.sh Stop gate closing the Option-A gap"
```

---

## Task 7: `site-fleet` skill + `/beacon:fleet` command

**Files:**
- Create: `plugins/beacon/skills/site-fleet/SKILL.md`
- Create: `plugins/beacon/commands/beacon-fleet.md`

**Interfaces:**
- Consumes: `fleet.py` (all subcommands), `site-analyst` OR the `site-recon` skill (per Task-1 `ACTOR`).
- Produces: the `/beacon:fleet` user surface.

- [ ] **Step 1: Write the skill**

Create `plugins/beacon/skills/site-fleet/SKILL.md`. Use the Task-1 `ACTOR` decision for the dispatch step (below shows both; keep the chosen one prominent, the other as a noted fallback):

````markdown
---
name: site-fleet
description: This skill should be used when the user asks to analyse/recon MULTIPLE sites at once — "recon these sites", "map the API surface of A, B and C", "run beacon over this list of URLs", or runs /beacon:fleet. Recons sources one at a time through site-analyst, tracks them in a durable ledger, and gates completion. For a single site, use site-recon instead.
version: 0.8.0
---

# site-fleet — Sequential fleet orchestration

Recon a LIST of sources one at a time, reusing site-recon per source, with a durable
ledger that survives compaction and a deterministic completeness gate.

**Reuses, never replaces:** each source is a full site-recon (Subsystem A). This skill only
adds the ledger, the sequential loop, and the completeness sweep. One source at a time — no
parallelism (that is the deferred B2 subsystem).

## Entry — branch on arguments (REQUIRED)

- **With URLs / a file arg** → start a new fleet:
  ```bash
  python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/fleet.py" init {url1} {url2} …
  ```
  (A file of URLs, one per line: expand it to the arg list first.) Record the printed
  `[FLEET:{ledger}]`. If it prints `[FLEET-ERROR] … already active`, do NOT retry init —
  go to resume.
- **With no args, OR after `[FLEET-ERROR] already active`** → resume; never call `init`:
  ```bash
  python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/fleet.py" pending
  ```

## The loop (sequential)

Repeat until `fleet.py pending` prints nothing:

1. Take the next slug from `fleet.py pending` (it also re-arms a paused fleet).
2. **Reconcile:** if that source's `docs/sites/{slug}/research/INDEX.md` is already complete
   (`python3 …/okf_validate.py --is-complete <INDEX>`), mark it and skip:
   `fleet.py update {slug} --status complete --verdict complete`.
3. Otherwise mark it in flight: `fleet.py update {slug} --status reconning`.
4. **Recon the whole source (Phases 1–12) in ONE context** — <!-- ACTOR = subagent --> dispatch
   the `site-analyst` agent for `{url}` and await it; <!-- ACTOR = main-session-loop --> or run
   the `site-recon` skill for `{url}` yourself. Do NOT split Phases 1–9 from 10–11 across
   contexts — that re-opens the content seam (prohibited in B1).
5. Record the outcome:
   - completed (INDEX flipped `status: complete`) → `fleet.py update {slug} --status complete --verdict complete`
   - blocked for a concrete reason (e.g. auth wall) → `fleet.py update {slug} --status blocked --verdict blocked:{reason}`
   - errored / produced nothing → `fleet.py update {slug} --status inconclusive --verdict inconclusive`, then **retry once**; if still not complete, leave it inconclusive.

## Close

- `python3 …/fleet.py sweep` → prints `[FLEET-COMPLETE]` or `[FLEET-INCOMPLETE:{slug}:{reason}]`.
- Report a slug → status table and the incomplete list.
- **Pausing across sessions:** before an intentional mid-fleet stop, run `fleet.py pause`
  (preserves the resume handle; the Stop gate will not block). Resume next session with
  `/beacon:fleet` (no args) or `fleet.py pending`.
- **A source that genuinely cannot complete:** `fleet.py waive {slug} --reason {why}`.
- **Abandon the fleet:** `fleet.py close`.

If you stop with unresolved sources and have not paused, the `fleet-sweep.sh` Stop hook blocks
with `[FLEET-SWEEP-PENDING:…]` — finish, waive, pause, or close.
````

- [ ] **Step 2: Write the command**

Create `plugins/beacon/commands/beacon-fleet.md`:

```markdown
---
description: Recon multiple sites sequentially through beacon, tracked in a durable fleet ledger with a completeness gate.
---

Run a beacon fleet over the provided URLs (or a file of URLs, one per line): $ARGUMENTS

Invoke the `site-fleet` skill and follow it exactly — branch on argument presence (URLs → new
fleet; none → resume), recon each source whole, and run the completeness sweep at the end.
```

- [ ] **Step 3: Validate skill + command frontmatter**

Run: `python3 -c "import yaml,sys; [yaml.safe_load(open(f).read().split('---')[1]) for f in ['plugins/beacon/skills/site-fleet/SKILL.md','plugins/beacon/commands/beacon-fleet.md']]; print('frontmatter OK')"`
Expected: `frontmatter OK`.

- [ ] **Step 4: Commit**

```bash
git add plugins/beacon/skills/site-fleet/SKILL.md plugins/beacon/commands/beacon-fleet.md
git commit -m "feat(beacon): site-fleet skill + /beacon:fleet command"
```

---

## Task 8: Package — version, CHANGELOG, registrations

**Files:**
- Modify: `plugins/beacon/.claude-plugin/plugin.json`
- Modify: `plugins/beacon/CHANGELOG.md`
- Modify: `docs/SLUG_RULES.md`
- Modify: `AGENTS.md`

**Interfaces:** none (packaging/docs).

- [ ] **Step 1: Bump the version**

In `plugins/beacon/.claude-plugin/plugin.json`, set `"version": "0.8.0"`.

- [ ] **Step 2: Add the CHANGELOG entry**

In `plugins/beacon/CHANGELOG.md`, under `## [Unreleased]` → `### Added`, add:

```markdown
- **Fleet orchestration (B1, sequential core)**: `/beacon:fleet {urls|file}` recons multiple
  sources one at a time through `site-analyst`, tracked in a durable `docs/sites/.fleet/` ledger
  (`scripts/fleet.py`) that survives compaction and resumes via `fleet.py pending`. A `Stop`-only
  `hooks/fleet-sweep.sh` gate blocks the orchestrator until every source is complete/blocked/waived
  — deterministically closing the Option-A residual gap (abandoned/zero-output recons). Adds a
  canonical `scripts/slugify.py` shared by `scaffold.sh` and `fleet.py`. Parallelism is deferred to
  B2.
```

- [ ] **Step 3: Point SLUG_RULES.md at slugify.py**

In `docs/SLUG_RULES.md`, add a line noting `plugins/beacon/skills/site-recon/scripts/slugify.py` is the canonical implementation, and **keep the existing `sed` one-liner** in the doc (reframe's runtime path and the drift guard both rely on it being present).

- [ ] **Step 4: Register the skill in AGENTS.md**

In `AGENTS.md`, add a row to the beacon skills table and the intent-mapping table:

```markdown
| `site-fleet` | `plugins/beacon/skills/site-fleet/SKILL.md` | User asks to recon MULTIPLE sites, or runs `/beacon:fleet` |
```
and intent rows: `"recon these sites" / "run beacon over this list" → site-fleet`.

- [ ] **Step 5: Full regression + validate**

Run:
```bash
python3 -m pytest plugins/beacon/skills/site-recon/scripts/test_slugify.py plugins/beacon/skills/site-recon/scripts/test_fleet.py -q
bash plugins/beacon/skills/site-recon/scripts/test_scaffold.sh
bash plugins/beacon/hooks/test_fleet_sweep.sh
bash tests/validate-slug-rule.sh
python3 -m json.tool plugins/beacon/hooks/hooks.json > /dev/null && echo "hooks.json OK"
python3 -m json.tool plugins/beacon/.claude-plugin/plugin.json > /dev/null && echo "plugin.json OK"
```
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add plugins/beacon/.claude-plugin/plugin.json plugins/beacon/CHANGELOG.md docs/SLUG_RULES.md AGENTS.md
git commit -m "chore(beacon): v0.8.0 — register fleet skill, CHANGELOG, slug docs"
```

---

## Notes for the executor

- **TDD throughout:** every code task writes the test first, watches it fail, implements, watches it pass.
- **`fleet.py` resolves paths from the repo root** — run its tests and the hook from a repo-root cwd (the pytest cases `chdir` via `cwd=tmp_path`, which is the fleet's own root in those tests).
- **The `flock` in `_mutate`** is defense-in-depth; B1 has a single writer (the main session), so it never actually contends — but it matches `okf_marker_retry.py` and future-proofs B2.
- **Do not** register `fleet-sweep.sh` on `SubagentStop`. Stop-only is load-bearing (Task 6, Step 6).
