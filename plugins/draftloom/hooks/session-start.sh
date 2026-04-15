#!/bin/bash
# Draftloom session start hook
# Hints /draftloom:setup if no profiles found in the current project

PROFILES_DIR=".draftloom/profiles"

if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR" 2>/dev/null)" ]; then
  echo "No Draftloom profiles found. Run \`/draftloom:setup\` to create your first writing profile."
fi
