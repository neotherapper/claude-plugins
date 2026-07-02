# Beacon Enforced OKF Output Contract — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `site-recon` output files exist from Phase 1 as validated OKF concepts, and gate run completion deterministically so a recon can never finish having written nothing or non-conforming files.

**Architecture:** A Phase-1 `scaffold.sh` pre-creates the output tree from OKF-frontmatter templates into a caller-supplied `OUTPUT_ROOT`; phases edit those files in place; a fail-closed `okf_validate.py` checks frontmatter/enums/links; a `SubagentStop`/`Stop` hook runs the validator and blocks completion on violations. Beacon is an OKF producer — it conforms to Google OKF v0.1 and defines its own `type` enum + typed producer fields.

**Tech Stack:** Python 3 (validator + tests, PyYAML optional with regex fallback), Bash (scaffold + hook), Markdown+YAML (templates), Claude Code plugin hooks (`hooks.json`).

**Design source:** `docs/superpowers/specs/2026-07-02-beacon-okf-output-contract-design.md`.

## Global Constraints

- **Conform to Google OKF v0.1:** every output markdown file is a concept with a required `type` field; reserved optional fields are `title`, `description`, `resource`, `tags`, `timestamp`; relationships are markdown links; `INDEX.md` is the entrypoint, `log.md` the history. Producers may add custom fields.
- **No hard dependency on ai-sdlc.** Beacon ships its own validator (modelled on ai-sdlc's `okf_validate.py`, not importing it). Beacon lives in the `claude-plugins` repo.
- **Fail-closed:** unparseable/missing frontmatter, unknown `type`, illegal enum value, dangling link, or nothing checkable → non-zero exit.
- **Paths:** scripts under `plugins/beacon/skills/site-recon/scripts/`; templates under `plugins/beacon/templates/okf/`; hooks under `plugins/beacon/hooks/`; reference under `plugins/beacon/skills/site-recon/references/`.
- **Closed beacon `type` enum (verbatim):** `site-index`, `tech-stack`, `site-map`, `api-surface`, `constants`, `session-brief`, `phase-checklist`, `data-source-index`, `dataset`, `access-profile`.
- **Enum fields (verbatim):**
  - `access_mode`: `open-api | bulk-download | scrape | gated | mixed`
  - `auth`: `none | api-key | oauth | session | cac-pki | account`
  - `bot_protection`: `none | cloudflare | akamai | datadome | perimeterx | f5 | recaptcha | turnstile`
  - `verification`: `live-verified | wayback-verified | asserted-unverified`
  - `status`: `draft | in-progress | complete`
- **Slug rule:** reuse the canonical rule already in `SKILL.md` / `docs/SLUG_RULES.md` (lowercase, strip scheme/`www.`/path/`:port`, `.`→`-`).
- **Commit style:** end messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

## File Structure

| File | Create/Modify | Responsibility |
|------|---------------|----------------|
| `plugins/beacon/skills/site-recon/references/okf-profile.md` | Create | The authoritative beacon OKF schema (types, fields, enums, examples). |
| `plugins/beacon/skills/site-recon/scripts/okf_validate.py` | Create | Fail-closed validator: frontmatter, enums, links, entrypoint, stub-completeness. |
| `plugins/beacon/skills/site-recon/scripts/test_okf_validate.py` | Create | Unit tests for the validator. |
| `plugins/beacon/skills/site-recon/scripts/scaffold.sh` | Create | Phase-1 scaffold: resolve OUTPUT_ROOT, mkdir tree, copy templates, write `.beacon/*`. |
| `plugins/beacon/skills/site-recon/scripts/test_scaffold.sh` | Create | Scaffold smoke test (scaffold → validator passes on draft bundle). |
| `plugins/beacon/templates/okf/*.md` | Create | OKF-frontmatter stub templates (7 files). |
| `plugins/beacon/hooks/okf-gate.sh` | Create | Stop/SubagentStop hook body: validate the active output root, block on failure. |
| `plugins/beacon/hooks/hooks.json` | Modify | Register the new `Stop` + `SubagentStop` hooks. |
| `plugins/beacon/skills/site-recon/SKILL.md` | Modify | Quickstart, Phase-1 scaffold call, OUTPUT_ROOT, Phase-12 gate. |
| `plugins/beacon/agents/site-analyst.md` | Modify | OKF-author awareness + broadened role. |

---

### Task 1: Validator core — frontmatter, type enum, required + enum fields

**Files:**
- Create: `plugins/beacon/skills/site-recon/scripts/okf_validate.py`
- Create: `plugins/beacon/skills/site-recon/scripts/test_okf_validate.py`
- Create: `plugins/beacon/skills/site-recon/references/okf-profile.md`

**Interfaces:**
- Produces: `validate_node(path: pathlib.Path) -> list[str]` (empty list = valid); module constants `TYPE_ENUM`, `ACCESS_MODE`, `AUTH`, `BOT_PROTECTION`, `VERIFICATION`, `STATUS`, `REQUIRED_BY_TYPE`; `parse_frontmatter(text: str) -> dict | None`.

- [ ] **Step 1: Write the failing tests**

```python
# plugins/beacon/skills/site-recon/scripts/test_okf_validate.py
import pathlib, tempfile, textwrap
import okf_validate as V

def _write(tmp, name, text):
    p = pathlib.Path(tmp) / name
    p.write_text(textwrap.dedent(text), encoding="utf-8")
    return p

def test_valid_api_surface_passes():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", """\
            ---
            type: api-surface
            title: NGA MSI
            access_mode: open-api
            auth: none
            verification: live-verified
            status: complete
            ---
            body
            """)
        assert V.validate_node(p) == []

def test_unknown_type_fails():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", "---\ntype: bogus\nstatus: draft\n---\n")
        assert any("unknown type" in e for e in V.validate_node(p))

def test_bad_enum_value_fails():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", """\
            ---
            type: api-surface
            title: X
            access_mode: telepathy
            auth: none
            verification: live-verified
            status: complete
            ---
            """)
        assert any("access_mode" in e for e in V.validate_node(p))

def test_missing_frontmatter_fails_closed():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", "no frontmatter here\n")
        assert V.validate_node(p) != []

def test_api_surface_missing_required_field_fails():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", "---\ntype: api-surface\ntitle: X\nstatus: draft\n---\n")
        assert any("access_mode" in e for e in V.validate_node(p))
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd plugins/beacon/skills/site-recon/scripts && python3 -m pytest test_okf_validate.py -v`
Expected: FAIL / collection error — `okf_validate` not found.

- [ ] **Step 3: Write the minimal validator**

```python
# plugins/beacon/skills/site-recon/scripts/okf_validate.py
#!/usr/bin/env python3
"""Beacon OKF validator — fail-closed gate for site-recon output bundles.
Conforms to Google OKF v0.1 (type required, markdown-link graph). See
../references/okf-profile.md for the authoritative schema."""
from __future__ import annotations
import argparse, re, sys
from pathlib import Path

try:
    import yaml
    _YAML = True
except ImportError:
    _YAML = False

TYPE_ENUM = {"site-index", "tech-stack", "site-map", "api-surface", "constants",
             "session-brief", "phase-checklist", "data-source-index", "dataset", "access-profile"}
ACCESS_MODE = {"open-api", "bulk-download", "scrape", "gated", "mixed"}
AUTH = {"none", "api-key", "oauth", "session", "cac-pki", "account"}
BOT_PROTECTION = {"none", "cloudflare", "akamai", "datadome", "perimeterx", "f5", "recaptcha", "turnstile"}
VERIFICATION = {"live-verified", "wayback-verified", "asserted-unverified"}
STATUS = {"draft", "in-progress", "complete"}
ENUM_FIELDS = {"access_mode": ACCESS_MODE, "auth": AUTH,
               "bot_protection": BOT_PROTECTION, "verification": VERIFICATION, "status": STATUS}
# every beacon concept needs type+status; api-surface needs the access triad too
REQUIRED_BY_TYPE = {
    "api-surface": ("type", "title", "access_mode", "auth", "verification", "status"),
}
REQUIRED_DEFAULT = ("type", "status")

def parse_frontmatter(text: str):
    m = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return None
    body = m.group(1)
    if _YAML:
        try:
            d = yaml.safe_load(body)
            return d if isinstance(d, dict) else None
        except yaml.YAMLError:
            return None
    fm = {}
    for raw in body.split("\n"):
        if ":" not in raw or raw[:1] in (" ", "\t"):
            continue
        k, _, v = raw.partition(":")
        fm[k.strip()] = v.strip().strip("'\"")
    return fm

def validate_node(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        return [f"cannot read: {e}"]
    fm = parse_frontmatter(text)
    if fm is None:
        return ["missing or unparseable YAML frontmatter (fail-closed)"]
    t = fm.get("type")
    if t not in TYPE_ENUM:
        return [f"unknown type '{t}' (not in beacon enum)"]
    errs = []
    for f in REQUIRED_BY_TYPE.get(t, REQUIRED_DEFAULT):
        if not fm.get(f):
            errs.append(f"missing/empty required field: {f}")
    for field, allowed in ENUM_FIELDS.items():
        if field in fm and fm[field] not in allowed:
            errs.append(f"invalid {field} '{fm[field]}' (not in enum)")
    return errs
```

Also create `references/okf-profile.md` documenting the same enums + the api-surface example from the spec (the human-readable mirror of these constants).

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd plugins/beacon/skills/site-recon/scripts && python3 -m pytest test_okf_validate.py -v`
Expected: 5 passed.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/okf_validate.py \
        plugins/beacon/skills/site-recon/scripts/test_okf_validate.py \
        plugins/beacon/skills/site-recon/references/okf-profile.md
git commit -m "feat(beacon): OKF validator core + producer profile

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Validator — link integrity, entrypoint, stub-completeness, bundle scan + CLI

**Files:**
- Modify: `plugins/beacon/skills/site-recon/scripts/okf_validate.py`
- Modify: `plugins/beacon/skills/site-recon/scripts/test_okf_validate.py`

**Interfaces:**
- Consumes: `validate_node`, constants from Task 1.
- Produces: `validate_bundle(root: Path) -> dict[str, list[str]]`; a `main()` CLI: `okf_validate.py <root>` → exit 0 valid / 1 on any failure or empty.

- [ ] **Step 1: Write the failing tests**

```python
# append to test_okf_validate.py
def test_dangling_link_fails():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "INDEX.md", "---\ntype: site-index\ntitle: X\nstatus: complete\n---\nsee [x](missing.md)\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert any("does not resolve" in e for errs in res.values() for e in errs)

def test_bundle_requires_index_entrypoint():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "tech-stack.md", "---\ntype: tech-stack\ntitle: X\nstatus: complete\n---\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert any("no INDEX.md entrypoint" in e for errs in res.values() for e in errs)

def test_complete_status_with_unfilled_token_fails():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "INDEX.md", "---\ntype: site-index\ntitle: X\nstatus: complete\n---\nvalue {{FRAMEWORK}}\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert any("unfilled template token" in e for errs in res.values() for e in errs)

def test_draft_stub_with_token_passes():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "INDEX.md", "---\ntype: site-index\ntitle: X\nstatus: draft\n---\nvalue {{FRAMEWORK}}\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert res == {}

def test_empty_bundle_fails_closed():
    with tempfile.TemporaryDirectory() as t:
        res = V.validate_bundle(pathlib.Path(t))
        assert res != {}
```

- [ ] **Step 2: Run to verify they fail**

Run: `cd plugins/beacon/skills/site-recon/scripts && python3 -m pytest test_okf_validate.py -v`
Expected: the 5 new tests FAIL (`validate_bundle` not defined).

- [ ] **Step 3: Extend the validator**

```python
# add to okf_validate.py
_LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
_TOKEN = re.compile(r"\{\{[^}]+\}\}")

def _body(text: str) -> str:
    m = re.match(r"^---\s*\n.*?\n---\s*\n", text, re.DOTALL)
    return text[m.end():] if m else text

def validate_bundle(root: Path) -> dict[str, list[str]]:
    results: dict[str, list[str]] = {}
    md = [p for p in root.rglob("*.md") if ".beacon" not in p.parts]
    if not md:
        return {str(root): ["empty bundle: no OKF concept files (fail-closed)"]}
    has_index = False
    for p in md:
        errs = validate_node(p)
        text = p.read_text(encoding="utf-8", errors="ignore")
        fm = parse_frontmatter(text) or {}
        if fm.get("type") in ("site-index", "data-source-index"):
            has_index = True
        for tgt in _LINK.findall(_body(text)):
            tgt = tgt.split("#", 1)[0].strip()
            if not tgt or tgt.startswith(("http://", "https://", "mailto:")):
                continue
            if not (p.parent / tgt).exists():
                errs.append(f"link target does not resolve: {tgt}")
        if fm.get("status") == "complete" and _TOKEN.search(_body(text)):
            errs.append("unfilled template token in a status:complete file")
        if errs:
            results[str(p)] = errs
    if not has_index:
        results[str(root)] = results.get(str(root), []) + ["no INDEX.md entrypoint (type site-index/data-source-index)"]
    return results

def main() -> int:
    ap = argparse.ArgumentParser(description="Beacon OKF validator (fail-closed)")
    ap.add_argument("root", help="output bundle root (e.g. docs/sites/<slug>/research)")
    args = ap.parse_args()
    results = validate_bundle(Path(args.root))
    for path, errs in results.items():
        print(f"\n{path}:")
        for e in errs:
            print(f"  - {e}")
    print(f"\nbeacon-okf-validate: {len(results)} file(s)/root with failures.")
    return 1 if results else 0

if __name__ == "__main__":
    sys.exit(main())
```

Note: the error strings in the tests (`"no INDEX.md entrypoint"`, `"unfilled template token"`, `"does not resolve"`) must match verbatim.

- [ ] **Step 4: Run to verify all pass**

Run: `cd plugins/beacon/skills/site-recon/scripts && python3 -m pytest test_okf_validate.py -v`
Expected: 10 passed.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/okf_validate.py \
        plugins/beacon/skills/site-recon/scripts/test_okf_validate.py
git commit -m "feat(beacon): OKF validator link/entrypoint/stub checks + CLI

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: OKF stub templates

**Files:**
- Create: `plugins/beacon/templates/okf/INDEX.md`, `tech-stack.md`, `site-map.md`, `constants.md`, `api-surface.md`, `session-brief.md`, `phase-checklist.md`

**Interfaces:**
- Consumes: the beacon `type` enum + enum fields (Task 1). Templates use `{{TOKEN}}` placeholders and carry `status: draft`.
- Produces: template files the scaffold (Task 4) copies. A draft stub must pass `validate_node` (tokens allowed while draft).

- [ ] **Step 1: Write the templates**

`INDEX.md`:
```markdown
---
type: site-index
title: "{{SITE_NAME}} — Research Index"
resource: "{{URL}}"
tags: []
timestamp: "{{TIMESTAMP}}"
status: draft
---

# {{SITE_NAME}} — Research Index

## Infrastructure
| Property | Value |
|----------|-------|
| Framework | {{FRAMEWORK}} |

## Research Files
| File | Contents |
|------|----------|
| [tech-stack.md](tech-stack.md) | Framework, CDN, auth, hosting |
| [site-map.md](site-map.md) | Discovered URLs |
| [constants.md](constants.md) | IDs, nonces, enums |
```

`api-surface.md`:
```markdown
---
type: api-surface
title: "{{SURFACE_NAME}}"
resource: "{{BASE_URL}}"
tags: []
timestamp: "{{TIMESTAMP}}"
access_mode: open-api
auth: none
bot_protection: none
verification: asserted-unverified
status: draft
---

# {{SURFACE_NAME}}

## Endpoints
{{ENDPOINTS}}
```

`session-brief.md`:
```markdown
---
type: session-brief
title: "Session Brief — {{SITE_SLUG}}"
timestamp: "{{TIMESTAMP}}"
status: draft
---

# Session Brief — {{SITE_SLUG}}

### Discovered Endpoints
| Endpoint | Method | Auth | Phase | Notes |
```

`phase-checklist.md`:
```markdown
---
type: phase-checklist
title: "Phase checklist — {{SITE_SLUG}}"
timestamp: "{{TIMESTAMP}}"
status: draft
---

# Phase checklist — {{SITE_SLUG}}
- [ ] P1 Scaffold + tool check
- [ ] P2 Passive recon
- [ ] P3 Fingerprint
- [ ] P9 OSINT (mode-appropriate)
- [ ] P12 Document
```

`tech-stack.md`, `site-map.md`, `constants.md`: same pattern — frontmatter `type` = `tech-stack`/`site-map`/`constants`, `title`, `timestamp`, `status: draft`, a one-line heading + a placeholder table.

- [ ] **Step 2: Verify each template validates as a draft node**

Run:
```bash
cd plugins/beacon/skills/site-recon/scripts
for f in ../../../templates/okf/*.md; do python3 -c "import okf_validate as V,pathlib,sys; e=V.validate_node(pathlib.Path('$f')); sys.exit(1) if e else print('OK', '$f')"; done
```
Expected: `OK` for all 7 (drafts with tokens are valid).

- [ ] **Step 3: Commit**

```bash
git add plugins/beacon/templates/okf/
git commit -m "feat(beacon): OKF stub templates for site-recon output

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Scaffold script (Phase 1)

**Files:**
- Create: `plugins/beacon/skills/site-recon/scripts/scaffold.sh`
- Create: `plugins/beacon/skills/site-recon/scripts/test_scaffold.sh`

**Interfaces:**
- Consumes: templates (Task 3), validator (Task 2).
- Produces: a scaffolded bundle at `OUTPUT_ROOT` + `.beacon/{session-brief.md,phase-checklist.md,recon-active.json}`. Invocation: `URL=<url> [OUTPUT_ROOT=<path>] bash scaffold.sh`.

- [ ] **Step 1: Write the failing test**

```bash
# plugins/beacon/skills/site-recon/scripts/test_scaffold.sh
#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
OUTPUT_ROOT="$TMP/out" URL="https://msi.nga.mil/NavWarnings" bash "$DIR/scaffold.sh"
test -f "$TMP/out/INDEX.md" || { echo "FAIL: no INDEX.md"; exit 1; }
test -f "$TMP/out/.beacon/phase-checklist.md" || { echo "FAIL: no phase-checklist"; exit 1; }
test -f "$TMP/out/.beacon/recon-active.json" || { echo "FAIL: no active marker"; exit 1; }
python3 "$DIR/okf_validate.py" "$TMP/out" || { echo "FAIL: validator rejected fresh scaffold"; exit 1; }
echo "OK"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash plugins/beacon/skills/site-recon/scripts/test_scaffold.sh`
Expected: FAIL — `scaffold.sh` not found / no INDEX.md.

- [ ] **Step 3: Write the scaffold**

```bash
# plugins/beacon/skills/site-recon/scripts/scaffold.sh
#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
TPL="$DIR/../../../templates/okf"
: "${URL:?set URL}"
SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
OUTPUT_ROOT="${OUTPUT_ROOT:-docs/sites/${SLUG}/research}"
[ -n "${OUTPUT_ROOT_OVERRIDDEN:-}" ] && echo "[OUTPUT-OVERRIDE:${OUTPUT_ROOT}]"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mkdir -p "$OUTPUT_ROOT/api-surfaces" "$OUTPUT_ROOT/specs" "$OUTPUT_ROOT/.beacon"
render() { sed -e "s#{{SITE_SLUG}}#${SLUG}#g" -e "s#{{SITE_NAME}}#${SLUG}#g" \
              -e "s#{{URL}}#${URL}#g" -e "s#{{TIMESTAMP}}#${TS}#g" "$1"; }
for f in INDEX tech-stack site-map constants; do render "$TPL/$f.md" > "$OUTPUT_ROOT/$f.md"; done
render "$TPL/session-brief.md"   > "$OUTPUT_ROOT/.beacon/session-brief.md"
render "$TPL/phase-checklist.md" > "$OUTPUT_ROOT/.beacon/phase-checklist.md"
printf '{"output_root":"%s","retries":0}\n' "$OUTPUT_ROOT" > "$OUTPUT_ROOT/.beacon/recon-active.json"
echo "[SCAFFOLD:${OUTPUT_ROOT}]"
```

- [ ] **Step 4: Run to verify it passes**

Run: `bash plugins/beacon/skills/site-recon/scripts/test_scaffold.sh`
Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/scripts/scaffold.sh \
        plugins/beacon/skills/site-recon/scripts/test_scaffold.sh
git commit -m "feat(beacon): Phase-1 OKF scaffold script + OUTPUT_ROOT override

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Stop-hook gate

**Files:**
- Create: `plugins/beacon/hooks/okf-gate.sh`
- Modify: `plugins/beacon/hooks/hooks.json`
- Create: `plugins/beacon/hooks/test_okf_gate.sh`

**Interfaces:**
- Consumes: validator (Task 2), the `.beacon/recon-active.json` marker (Task 4).
- Produces: a hook that is a **silent no-op unless `INDEX.md` is `status: complete`** (Option A —
  a fresh/mid-run `status: draft` bundle passes through untouched: no validation, no block, no
  marker deletion). Only once completion is claimed does it validate the output root; on failure
  it prints violations and exits non-zero (deterministic gate); after 2 failed retries it lets the
  stop through with a persistent `[OKF-GATE-FAILED]` log so it can't loop forever. This supersedes
  the always-validate draft below — see `plugins/beacon/hooks/okf-gate.sh` for the shipped logic.

- [ ] **Step 1: Write the failing test**

```bash
# plugins/beacon/hooks/test_okf_gate.sh
#!/usr/bin/env bash
set -euo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
SCAF="$HOOKS/../skills/site-recon/scripts"
TMP=$(mktemp -d); cd "$TMP"
OUTPUT_ROOT="$TMP/out" URL="https://example.com" bash "$SCAF/scaffold.sh" >/dev/null
# fresh scaffold is all draft → gate should pass (nothing claimed complete)
bash "$HOOKS/okf-gate.sh" || { echo "FAIL: gate rejected a valid draft bundle"; exit 1; }
# now corrupt a file: claim complete but leave a token
printf -- '---\ntype: site-index\ntitle: X\nstatus: complete\n---\n{{FRAMEWORK}}\n' > "$TMP/out/INDEX.md"
if bash "$HOOKS/okf-gate.sh"; then echo "FAIL: gate passed an invalid complete bundle"; exit 1; fi
echo "OK"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash plugins/beacon/hooks/test_okf_gate.sh`
Expected: FAIL — `okf-gate.sh` not found.

- [ ] **Step 3: Write the hook**

```bash
# plugins/beacon/hooks/okf-gate.sh
#!/usr/bin/env bash
# Beacon OKF gate: on Stop/SubagentStop, validate the active recon output root.
set -uo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
VALIDATE="$HOOKS/../skills/site-recon/scripts/okf_validate.py"
MARK=$(find . -path '*/.beacon/recon-active.json' -not -path '*/node_modules/*' 2>/dev/null | head -1)
[ -z "$MARK" ] && exit 0   # no active beacon recon → not our concern
ROOT=$(python3 -c "import json,sys; print(json.load(open('$MARK'))['output_root'])" 2>/dev/null || echo "")
[ -z "$ROOT" ] && exit 0
if python3 "$VALIDATE" "$ROOT"; then
  rm -f "$MARK"; exit 0
fi
RETRIES=$(python3 -c "import json; print(json.load(open('$MARK')).get('retries',0))" 2>/dev/null || echo 0)
if [ "$RETRIES" -ge 2 ]; then
  echo "[OKF-GATE-FAILED:$ROOT] validation still failing after retries — allowing stop" >&2
  rm -f "$MARK"; exit 0
fi
python3 -c "import json; d=json.load(open('$MARK')); d['retries']=$RETRIES+1; json.dump(d,open('$MARK','w'))"
echo "[OKF-GATE-BLOCK:$ROOT] output files missing/invalid — fix before finishing (see errors above)" >&2
exit 2
```

- [ ] **Step 4: Register the hooks in `hooks.json`**

Modify `plugins/beacon/hooks/hooks.json` to add (alongside the existing `SessionStart`):
```json
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/okf-gate.sh", "timeout": 30 } ] }
    ],
    "SubagentStop": [
      { "hooks": [ { "type": "command", "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/okf-gate.sh", "timeout": 30 } ] }
    ]
```

- [ ] **Step 5: Run to verify the gate test passes + JSON is valid**

Run:
```bash
bash plugins/beacon/hooks/test_okf_gate.sh
python3 -c "import json; json.load(open('plugins/beacon/hooks/hooks.json')); print('hooks.json OK')"
```
Expected: `OK` then `hooks.json OK`.

- [ ] **Step 6: Commit**

```bash
git add plugins/beacon/hooks/okf-gate.sh plugins/beacon/hooks/hooks.json plugins/beacon/hooks/test_okf_gate.sh
git commit -m "feat(beacon): Stop/SubagentStop OKF gate hook

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: SKILL.md wiring — Quickstart, Phase 1 scaffold, Phase 12 gate

**Files:**
- Modify: `plugins/beacon/skills/site-recon/SKILL.md`

**Interfaces:**
- Consumes: `scaffold.sh` (Task 4), `okf_validate.py` (Task 2), `okf-profile.md` (Task 1).

- [ ] **Step 1: Add a Quickstart block** immediately after the H1 (`# site-recon — Research Mode`), before "## Output structure":

```markdown
## Quickstart — do this first (deterministic floor)

Before reading the phase detail below, run the scaffold so every output file exists as a valid
OKF stub, then edit into those files as you go:

```bash
URL="{url}" bash "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/scaffold.sh"
# honour a caller-supplied path: OUTPUT_ROOT="docs/research/{slug}" OUTPUT_ROOT_OVERRIDDEN=1 URL="{url}" bash .../scaffold.sh
```

Output conforms to `references/okf-profile.md` (Google OKF v0.1 + beacon types/enums). Never
create output files by hand — edit the scaffolded stubs and flip `status: draft → complete` as
each is finished. A `Stop` hook validates the bundle and blocks an unfinished/invalid run.
```

- [ ] **Step 2: Replace the Phase 1 scaffold bash** (the `SLUG=…; mkdir -p docs/sites/…` block) with a call to `scaffold.sh`, and add the `OUTPUT_ROOT` override note. Keep the tool-availability checks that follow.

- [ ] **Step 3: Update the Phase 12 gate** — in the "Phase completion gate" section, add:

```markdown
Then run the deterministic OKF gate before declaring done:
`python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/okf_validate.py" "$OUTPUT_ROOT"`
Fix every reported violation; the `Stop` hook runs the same check and will block otherwise.
```

- [ ] **Step 4: Verify the wiring references resolve**

Run:
```bash
grep -q "scaffold.sh" plugins/beacon/skills/site-recon/SKILL.md
grep -q "okf_validate.py" plugins/beacon/skills/site-recon/SKILL.md
grep -q "okf-profile.md" plugins/beacon/skills/site-recon/SKILL.md
test -f plugins/beacon/skills/site-recon/scripts/scaffold.sh
echo "wiring OK"
```
Expected: `wiring OK`.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/SKILL.md
git commit -m "feat(beacon): wire scaffold + OKF gate into site-recon SKILL.md

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: site-analyst agent — OKF-author awareness

**Files:**
- Modify: `plugins/beacon/agents/site-analyst.md`

**Interfaces:**
- Consumes: `okf-profile.md`, `scaffold.sh`, `okf_validate.py`.

- [ ] **Step 1: Update the "Output standards" section** to point at the OKF profile and the scaffold-then-edit flow, replacing the ad-hoc structure block:

```markdown
## Output standards

Run `scripts/scaffold.sh` first; then EDIT the scaffolded OKF stubs (never hand-create output).
Every file conforms to `skills/site-recon/references/okf-profile.md` (Google OKF v0.1 + beacon
types/enums). Flip `status: draft → complete` per file as it's finished; a Stop hook validates
the bundle via `scripts/okf_validate.py` and blocks an unfinished run.
```

- [ ] **Step 2: Broaden the description + "When to use"** so an orchestrator reaches for this agent for a full per-source recon (not only sub-tasks). Change the `description:` frontmatter to include "runs a full per-source site-recon end-to-end and emits the validated OKF research bundle," and add a "full end-to-end per-source recon" bullet to "When to use this agent."

- [ ] **Step 3: Verify**

Run:
```bash
grep -q "okf-profile.md" plugins/beacon/agents/site-analyst.md
grep -q "scaffold.sh" plugins/beacon/agents/site-analyst.md
echo "agent OK"
```
Expected: `agent OK`.

- [ ] **Step 4: Commit**

```bash
git add plugins/beacon/agents/site-analyst.md
git commit -m "feat(beacon): site-analyst emits validated OKF bundle; broaden role

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Component 1 (OKF profile + enums) → Tasks 1, 3. ✅
- Component 2 (scaffold + OUTPUT_ROOT) → Task 4. ✅
- Component 3 (fail-closed validator) → Tasks 1–2. ✅
- Component 4 (Stop-hook gate) → Task 5. ✅
- Component 5 (SKILL.md Quickstart/Phase 1/Phase 12) → Task 6; site-analyst → Task 7. ✅
- Goal 5 (caller output root) → Task 4 `OUTPUT_ROOT`. ✅
- Subsystem B → correctly out of scope (spec deferral). ✅

**Placeholder scan:** No "TBD/TODO/handle edge cases" — every code step has real code; every enum value is verbatim from Global Constraints. ✅

**Type consistency:** `validate_node` (Task 1) and `validate_bundle` (Task 2) names are stable and reused in Tasks 4–5; the `.beacon/recon-active.json` shape (`output_root`, `retries`) is written in Task 4 and read in Task 5; error strings asserted in tests match the strings produced in the implementation. ✅
