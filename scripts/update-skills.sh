#!/usr/bin/env bash
#
# update-skills.sh — update skills across all installed agents via gh skill
#
#   scripts/update-skills.sh          # interactive update
#   scripts/update-skills.sh --all    # update without prompting
#   scripts/update-skills.sh --dry-run # check for updates only
set -euo pipefail

MODE="${1:-}"

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not installed. Install: https://cli.github.com"
  exit 1
fi

if ! gh skill --help &>/dev/null 2>&1; then
  echo "Error: gh skill not available. Update GitHub CLI: gh upgrade"
  exit 1
fi

case "$MODE" in
  --dry-run)
    echo "Checking for skill updates..."
    gh skill update --dry-run
    ;;
  --all)
    echo "Updating all skills..."
    gh skill update --all
    ;;
  *)
    echo "Interactive skill update..."
    gh skill update
    ;;
esac
