# Project rules (Antigravity)

The authoritative, tool-agnostic instructions for this repo live in **`AGENTS.md`** at the repo
root, which Antigravity already reads natively. This file is a thin pointer so the rules are also
discoverable under `.agents/rules/`; it does not duplicate that content.

@../../AGENTS.md

## Skills

This repo's skills are exposed to Antigravity under **`.agents/skills/`** (symlinks into
`plugins/<plugin>/skills/`). Match a skill by its `description` and follow it when it applies. See
`docs/platform/multi-tool-support.md` for the full multi-tool layout.
