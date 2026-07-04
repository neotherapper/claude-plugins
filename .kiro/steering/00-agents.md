---
inclusion: always
---

# Project steering (Kiro)

The authoritative, tool-agnostic instructions for this repo live in `AGENTS.md` at the repo root
(which Kiro also reads as an always-included file). This steering file pins it explicitly and
notes where the skills are.

#[[file:AGENTS.md]]

Skills are exposed to Kiro under `.kiro/skills/` (symlinks into `plugins/<plugin>/skills/`). Match
a skill by its `description` and follow it when it applies. See
`docs/platform/multi-tool-support.md` for the full multi-tool layout.
