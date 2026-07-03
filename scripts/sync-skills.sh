#!/usr/bin/env bash
#
# sync-skills.sh — expose each plugins/<plugin>/skills/<skill>/ at the top-level
# skill paths that non-Claude agents scan, via a symlink farm.
#
#   scripts/sync-skills.sh          # (re)create + prune the symlinks (default)
#   scripts/sync-skills.sh --check  # verify the farm is complete & links resolve; no writes (CI)
#
# Why: the canonical skills live once, under plugins/<plugin>/skills/<skill>/. Only Claude Code
# walks that nested layout (via the marketplace). Codex, OpenCode, Antigravity, and Kiro each scan
# a fixed, shallow, top-level dir. These symlinks put every skill where each tool looks:
#
#   .agents/skills/<skill>  -> ../../plugins/<plugin>/skills/<skill>   # Codex + Antigravity + OpenCode(fallback)
#   .kiro/skills/<skill>    -> ../../plugins/<plugin>/skills/<skill>   # Kiro
#
# Symlinking the directory (not copying) keeps ONE source of truth and carries each skill's
# scripts/references/assets along for free. See docs/platform/multi-tool-support.md.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="sync"
if [ "${1:-}" = "--check" ]; then MODE="check"; fi

exec python3 - "$ROOT" "$MODE" <<'PY'
import os, re, sys

root, mode = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(root, "scripts", "lib"))
from skill_frontmatter import discover_skills, parse_frontmatter

# Each entry is a top-level dir whose <skill> symlinks point at ../../plugins/<plugin>/skills/<skill>
LINK_DIRS = [".agents/skills", ".kiro/skills"]
KIRO_NAME_RE = re.compile(r"^[a-z0-9-]{1,64}$")   # Kiro: name lowercase/digit/hyphen, matches folder, <=64
KIRO_DESC_MAX = 1024                               # Kiro: description <= 1024 chars

fails = warns = 0
def err(m):
    global fails; fails += 1; print(f"  \033[31mFAIL\033[0m  {m}")
def warn(m):
    global warns; warns += 1; print(f"  \033[33mWARN\033[0m  {m}")
def ok(m):
    print(f"  \033[32mok\033[0m    {m}")

print(f"Syncing skill symlink farm ({mode})...\n")

# 1. Discover canonical skills: plugins/<plugin>/skills/<skill>/SKILL.md (nested .evals/ etc. excluded)
skills, dupes = discover_skills(root)

# 2. Name collisions are fatal — a flat mirror namespace can't hold two skills with the same folder
# name. Drop the colliding name from `skills` entirely so neither plugin's skill is exposed under
# it: exposing an arbitrary winner would silently serve the wrong plugin's content to every tool.
for name, paths in dupes.items():
    err(f"skill-name collision '{name}': {', '.join(paths)} — rename one; flat mirror dirs need unique names")
    del skills[name]

# 3. Frontmatter validation — Kiro's stricter limits gate the whole farm
for name, rel in skills.items():
    fm = parse_frontmatter(os.path.join(root, rel, "SKILL.md")) or {}
    if fm.get("name", "") != name:
        warn(f"{rel}/SKILL.md name '{fm.get('name','')}' != folder '{name}'")
    if not KIRO_NAME_RE.match(name):
        err(f"'{name}': not Kiro-safe (need ^[a-z0-9-]{{1,64}}$)")
    if len(fm.get("description", "")) > KIRO_DESC_MAX:
        err(f"'{name}': description {len(fm.get('description',''))} chars > Kiro max {KIRO_DESC_MAX}")

# 4. Reconcile each link dir against the discovered skills
def want_target(rel):        # resolved relative to <linkdir>/: up 2 levels to repo root, then rel
    return os.path.join("..", "..", rel)

expected = {name: want_target(rel) for name, rel in skills.items()}  # same for every LINK_DIRS entry

changed = 0
for ld in LINK_DIRS:
    absld = os.path.join(root, ld)
    if mode == "sync":
        os.makedirs(absld, exist_ok=True)
    all_entries = set()
    existing_links = {}
    if os.path.isdir(absld):
        for e in sorted(os.listdir(absld)):
            p = os.path.join(absld, e)
            all_entries.add(e)
            if os.path.islink(p):
                existing_links[e] = os.readlink(p)

    # stale: any entry (symlink or not) with no matching skill. Non-symlink stale content is
    # flagged but never auto-deleted in sync mode — we only clean up what we created ourselves.
    for e in sorted(all_entries):
        if e in expected:
            continue
        if e in existing_links:
            if mode == "check":
                err(f"{ld}/{e} is a stale symlink (no matching skill)")
            else:
                os.unlink(os.path.join(absld, e)); changed += 1
                ok(f"removed stale {ld}/{e}")
        else:
            err(f"{ld}/{e} is unexpected content (no matching skill) — not a symlink, refusing to delete automatically")

    # missing / wrong / broken
    for name, want in expected.items():
        p = os.path.join(absld, name)
        cur = existing_links.get(name)
        resolves = cur is not None and os.path.exists(os.path.join(absld, cur))
        if cur == want and resolves:
            continue
        if mode == "check":
            if cur is None and not os.path.exists(p):
                err(f"{ld}/{name} missing (run scripts/sync-skills.sh)")
            elif cur is None:
                err(f"{ld}/{name} exists but is not a symlink")
            elif cur != want:
                err(f"{ld}/{name} -> {cur} (expected {want})")
            else:
                err(f"{ld}/{name} is a broken symlink -> {cur}")
        else:
            if os.path.islink(p):
                os.unlink(p)
            elif os.path.isdir(p):
                err(f"{ld}/{name} is a real directory, refusing to replace"); continue
            elif os.path.exists(p):
                os.unlink(p)
            os.symlink(want, p); changed += 1
            ok(f"linked {ld}/{name} -> {want}")

# 5. Summary
print()
if mode == "check":
    if fails:
        print(f"{fails} error(s), {warns} warning(s) — farm out of sync")
    else:
        print(f"farm OK — {len(skills)} skill(s) x {len(LINK_DIRS)} dir(s); {warns} warning(s)")
else:
    print(f"synced {len(skills)} skill(s) into {len(LINK_DIRS)} dir(s); {changed} change(s), {warns} warning(s)")
sys.exit(1 if fails else 0)
PY
