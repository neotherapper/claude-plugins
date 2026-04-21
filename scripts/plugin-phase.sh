#!/usr/bin/env bash
# plugin-phase.sh — switch between local dev and published (GitHub) plugin loading
#
# Usage:
#   ./scripts/plugin-phase.sh local    # point Claude Code at this repo's source files
#   ./scripts/plugin-phase.sh stable   # restore the GitHub-pulled cache versions
#   ./scripts/plugin-phase.sh status   # show which phase is active

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
BACKUP="${INSTALLED}.bak"

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n'  "$*"; }

require_installed_json() {
  if [[ ! -f "$INSTALLED" ]]; then
    echo "ERROR: $INSTALLED not found — is Claude Code installed?" >&2; exit 1
  fi
}

# All data + logic lives in Python so we don't depend on bash 4 associative arrays.
run_py() {
  python3 - "$INSTALLED" "$PROJECT_ROOT" "$BACKUP" "$1" <<'PYEOF'
import sys, json, os, shutil, textwrap

installed_path, project_root, backup_path, mode = sys.argv[1:]

PLUGINS = {
    "visual-kit@neotherapper-plugins":  "plugins/visual-kit",
    "paidagogos@neotherapper-plugins":  "plugins/paidagogos",
    "namesmith@neotherapper-plugins":   "plugins/namesmith",
    "draftloom@neotherapper-plugins":   "plugins/draftloom",
    "beacon@neotherapper-plugins":      "plugins/beacon",
}

def local_dir(key):
    return os.path.join(project_root, PLUGINS[key])

def local_version(key):
    pj = os.path.join(local_dir(key), ".claude-plugin", "plugin.json")
    return json.load(open(pj))["version"]

def load():
    return json.load(open(installed_path))

def save(data):
    tmp = installed_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, installed_path)

def entries(data, key):
    return data.get("plugins", {}).get(key, [])

def current_mode(data):
    modes = set()
    for key in PLUGINS:
        for e in entries(data, key):
            path = e.get("installPath", "")
            modes.add("local" if path == local_dir(key) else "stable")
    if not modes:
        return "unknown"
    return "mixed" if len(modes) > 1 else modes.pop()

def cmd_status(data):
    mode = current_mode(data)
    labels = {"local": "LOCAL  (fast iteration — reading from this repo)",
              "stable": "STABLE (reading from GitHub cache)",
              "mixed":  "MIXED  (plugins point to different sources — run local or stable to fix)",
              "unknown":"UNKNOWN"}
    print(f"\nPhase: {labels.get(mode, mode)}\n")
    fmt = "  {:<42}  {:<8}  {} {}"
    print(fmt.format("PLUGIN", "VERSION", "TYPE", "PATH"))
    print(fmt.format("------", "-------", "----", "----"))
    for key in sorted(PLUGINS):
        es = entries(data, key)
        if not es:
            print(fmt.format(key, "?", "[?]", "not installed"))
            continue
        e = es[0]
        path = e.get("installPath", "?")
        tag  = "[local]" if path == local_dir(key) else "[cache]"
        print(fmt.format(key, e.get("version", "?"), tag, path))
    print()

if mode == "status":
    cmd_status(load())

elif mode == "local":
    data = load()
    if current_mode(data) == "local":
        print("Already in LOCAL mode.")
        cmd_status(data)
        sys.exit(0)
    shutil.copy2(installed_path, backup_path)
    for key in PLUGINS:
        for e in entries(data, key):
            e["installPath"] = local_dir(key)
            e["version"]     = local_version(key)
    save(data)
    print("\033[1mSwitched to LOCAL mode\033[0m")
    cmd_status(data)

    # visual-kit needs its dist/ built before the binary can load.
    vk_dist = os.path.join(project_root, "plugins", "visual-kit", "dist", "cli.js")
    if not os.path.exists(vk_dist):
        print("\033[33m⚠ visual-kit dist/cli.js not found — building now...\033[0m")
        import subprocess
        vk_dir = os.path.join(project_root, "plugins", "visual-kit")
        result = subprocess.run(["pnpm", "build"], cwd=vk_dir, capture_output=True, text=True)
        if result.returncode == 0:
            print("\033[32m✓ visual-kit built successfully\033[0m")
        else:
            print(f"\033[31m✗ visual-kit build failed:\033[0m\n{result.stderr.strip()}")
            print("  Fix the build error, then re-run: ./scripts/plugin-phase.sh local")
            sys.exit(1)

    print("\033[32m→ Run /reload-plugins in Claude Code to apply\033[0m\n")

elif mode == "stable":
    data = load()
    if current_mode(data) == "stable":
        print("Already in STABLE mode.")
        cmd_status(data)
        sys.exit(0)
    if not os.path.exists(backup_path):
        print("ERROR: no backup found — run '! claude plugins update' then try again.", file=sys.stderr)
        sys.exit(1)
    shutil.copy2(backup_path, installed_path)
    print("\033[1mRestored from backup (STABLE mode)\033[0m")
    cmd_status(load())
    print("\033[32m→ Run /reload-plugins in Claude Code to apply\033[0m")
    print("\033[32m→ Optionally run '! claude plugins update' to pull latest GitHub HEAD\033[0m\n")
PYEOF
}

# ── main ─────────────────────────────────────────────────────────────────────

require_installed_json

case "${1:-}" in
  local|stable|status) run_py "$1" ;;
  *)
    bold "plugin-phase.sh — switch plugin loading between local dev and GitHub cache"
    echo ""
    echo "Usage:"
    echo "  ./scripts/plugin-phase.sh local    # fast iteration: reads from this repo"
    echo "  ./scripts/plugin-phase.sh stable   # validation:    reads from GitHub cache"
    echo "  ./scripts/plugin-phase.sh status   # show current phase"
    echo ""
    echo "After switching, run /reload-plugins in Claude Code."
    ;;
esac
