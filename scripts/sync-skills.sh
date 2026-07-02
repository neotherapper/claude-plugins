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
plugins_dir = os.path.join(root, "plugins")
skills = {}          # skill-name -> "plugins/<plugin>/skills/<skill>"
dupes = {}
if os.path.isdir(plugins_dir):
    for plugin in sorted(os.listdir(plugins_dir)):
        sdir = os.path.join(plugins_dir, plugin, "skills")
        if not os.path.isdir(sdir):
            continue
        for skill in sorted(os.listdir(sdir)):
            if not os.path.isfile(os.path.join(sdir, skill, "SKILL.md")):
                continue
            rel = f"plugins/{plugin}/skills/{skill}"
            if skill in skills:
                dupes.setdefault(skill, [skills[skill]]).append(rel)
            else:
                skills[skill] = rel

# 2. Name collisions are fatal — a flat mirror namespace can't hold two skills with the same folder name
for name, paths in dupes.items():
    err(f"skill-name collision '{name}': {', '.join(paths)} — rename one; flat mirror dirs need unique names")

# 3. Frontmatter validation — Kiro's stricter limits gate the whole farm
def frontmatter(path):
    txt = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---", txt, re.S)
    if not m:
        return None
    lines = m.group(1).split("\n")
    out = {}
    for i, ln in enumerate(lines):
        mm = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", ln)
        if not mm:
            continue
        key, val = mm.group(1), mm.group(2).strip()
        if val in (">", "|", ">-", "|-", ">+", "|+"):        # folded/block scalar
            buf = []
            for nxt in lines[i + 1:]:
                if re.match(r"^\s+", nxt) or nxt.strip() == "":
                    buf.append(nxt.strip())
                else:
                    break
            val = " ".join(x for x in buf if x)
        out.setdefault(key, val.strip("\"'"))
    return out

for name, rel in skills.items():
    fm = frontmatter(os.path.join(root, rel, "SKILL.md")) or {}
    if fm.get("name", "") != name:
        warn(f"{rel}/SKILL.md name '{fm.get('name','')}' != folder '{name}'")
    if not KIRO_NAME_RE.match(name):
        err(f"'{name}': not Kiro-safe (need ^[a-z0-9-]{{1,64}}$)")
    if len(fm.get("description", "")) > KIRO_DESC_MAX:
        err(f"'{name}': description {len(fm.get('description',''))} chars > Kiro max {KIRO_DESC_MAX}")

# 4. Reconcile each link dir against the discovered skills
def want_target(rel):        # resolved relative to <linkdir>/: up 2 levels to repo root, then rel
    return os.path.join("..", "..", rel)

changed = 0
for ld in LINK_DIRS:
    absld = os.path.join(root, ld)
    if mode == "sync":
        os.makedirs(absld, exist_ok=True)
    expected = {name: want_target(rel) for name, rel in skills.items()}
    existing = {}
    if os.path.isdir(absld):
        for e in sorted(os.listdir(absld)):
            p = os.path.join(absld, e)
            if os.path.islink(p):
                existing[e] = os.readlink(p)

    # stale: a symlink with no matching skill
    for e in list(existing):
        if e not in expected:
            if mode == "check":
                err(f"{ld}/{e} is a stale symlink (no matching skill)")
            else:
                os.unlink(os.path.join(absld, e)); changed += 1
                ok(f"removed stale {ld}/{e}")

    # missing / wrong / broken
    for name, want in expected.items():
        p = os.path.join(absld, name)
        cur = existing.get(name)
        resolves = os.path.islink(p) and os.path.exists(os.path.join(absld, os.readlink(p)))
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
