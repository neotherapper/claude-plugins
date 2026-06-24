#!/usr/bin/env bash
#
# validate-marketplace.sh — sanity-check the plugin marketplace manifest and
# every plugin manifest in this repo.
#
#   bash scripts/validate-marketplace.sh
#
# Checks (relative to repo root):
#   FAIL (exit 1):
#     - .claude-plugin/marketplace.json is missing or invalid JSON
#     - a plugin LISTED in the manifest has no resolvable .claude-plugin/plugin.json
#     - a listed plugin's plugin.json is invalid, or its `name` disagrees with the manifest
#     - any plugins/<dir>/.claude-plugin/plugin.json is invalid, or `name` != folder name
#   WARN (exit 0):
#     - a plugin on disk is NOT listed in the manifest (unpublished/draft — fine if intentional)
#     - manifest entry `version` (if present) disagrees with the plugin's plugin.json
#     - a second, stale manifest exists at the repo root (marketplace.json)
#
# Single source of truth for a plugin's version is its plugin.json — the
# manifest deliberately does not duplicate it.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

exec python3 - "$ROOT" <<'PY'
import json, os, re, sys

root = sys.argv[1]
fails = 0
warns = 0

def err(m):
    global fails; fails += 1
    print(f"  \033[31mFAIL\033[0m  {m}")
def warn(m):
    global warns; warns += 1
    print(f"  \033[33mWARN\033[0m  {m}")
def ok(m):
    print(f"  \033[32mok\033[0m    {m}")

def load(path):
    try:
        with open(path) as f:
            return json.load(f), None
    except FileNotFoundError:
        return None, "missing"
    except json.JSONDecodeError as e:
        return None, f"invalid JSON ({e})"

print("Validating marketplace + plugin manifests...\n")

# 1. Canonical marketplace manifest
manifest_path = os.path.join(root, ".claude-plugin", "marketplace.json")
manifest, e = load(manifest_path)
if e:
    err(f".claude-plugin/marketplace.json {e}")
    print(f"\n{fails} error(s), {warns} warning(s)")
    sys.exit(1)
ok(".claude-plugin/marketplace.json is valid JSON")

# 2. Every plugin listed in the manifest resolves to a valid plugin.json
listed = {}
for entry in manifest.get("plugins", []):
    name = entry.get("name", "")
    src = entry.get("source", "")
    path = src.get("path", "") if isinstance(src, dict) else src
    path = (path or "").lstrip("./")
    if not name:
        err(f"manifest entry is missing 'name': {entry!r}")
        continue
    if not path:
        err(f"manifest entry '{name}' has no usable source/path")
        continue
    listed[name] = path
    pj, e = load(os.path.join(root, path, ".claude-plugin", "plugin.json"))
    if e:
        err(f"published '{name}' -> {path}/.claude-plugin/plugin.json {e}")
        continue
    if pj.get("name") != name:
        err(f"published '{name}': plugin.json name is '{pj.get('name')}' (manifest/plugin.json mismatch)")
    mver, pver = entry.get("version"), pj.get("version")
    if mver and pver and mver != pver:
        warn(f"published '{name}': manifest version {mver} != plugin.json version {pver}")
    ok(f"published: {name} -> {path} (v{pver})")

# 3. Every plugin.json on disk is valid and self-consistent
plugins_dir = os.path.join(root, "plugins")
if os.path.isdir(plugins_dir):
    for folder in sorted(os.listdir(plugins_dir)):
        pj_path = os.path.join(plugins_dir, folder, ".claude-plugin", "plugin.json")
        if not os.path.isfile(pj_path):
            continue
        pj, e = load(pj_path)
        if e:
            err(f"plugins/{folder}/.claude-plugin/plugin.json {e}")
            continue
        if pj.get("name") != folder:
            err(f"plugins/{folder}: plugin.json name '{pj.get('name')}' != folder name")
        if folder not in listed:
            warn(f"plugins/{folder} (v{pj.get('version')}) is on disk but NOT published in marketplace.json — draft? (ok if intentional)")

# 4. Flag a stale duplicate manifest at the repo root
if os.path.isfile(os.path.join(root, "marketplace.json")):
    warn("a second manifest exists at the repo root (./marketplace.json); Claude Code reads .claude-plugin/marketplace.json — delete the root copy if stale to avoid drift")

# 5. Agent + skill frontmatter across all plugins (regression guard)
def frontmatter_keys(path):
    text = open(path, encoding="utf-8").read()
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    keys = {}
    for line in parts[1].splitlines():
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m:
            keys[m.group(1)] = m.group(2).strip()
    return keys

if os.path.isdir(plugins_dir):
    for folder in sorted(os.listdir(plugins_dir)):
        adir = os.path.join(plugins_dir, folder, "agents")
        if os.path.isdir(adir):
            for fn in sorted(os.listdir(adir)):
                if not fn.endswith(".md") or fn.lower() == "readme.md":
                    continue
                rel = f"plugins/{folder}/agents/{fn}"
                fm = frontmatter_keys(os.path.join(adir, fn))
                if fm is None:
                    err(f"{rel}: agent file has no YAML frontmatter (needs name + description)")
                else:
                    if not fm.get("name"):
                        err(f"{rel}: agent frontmatter missing 'name'")
                    if not fm.get("description"):
                        err(f"{rel}: agent frontmatter missing 'description'")
        sdir = os.path.join(plugins_dir, folder, "skills")
        if os.path.isdir(sdir):
            for sk in sorted(os.listdir(sdir)):
                skill_md = os.path.join(sdir, sk, "SKILL.md")
                if not os.path.isfile(skill_md):
                    continue
                rel = f"plugins/{folder}/skills/{sk}/SKILL.md"
                fm = frontmatter_keys(skill_md)
                if fm is None:
                    err(f"{rel}: SKILL.md has no YAML frontmatter")
                else:
                    name = fm.get("name")
                    if not name:
                        err(f"{rel}: SKILL.md frontmatter missing 'name'")
                    elif name != sk:
                        warn(f"{rel}: SKILL.md name '{name}' != folder '{sk}'")
                    if not fm.get("description"):
                        err(f"{rel}: SKILL.md frontmatter missing 'description'")
    ok("checked agent + skill frontmatter across all plugins")

print(f"\n{fails} error(s), {warns} warning(s)")
sys.exit(1 if fails else 0)
PY
