---
name: beacon:load
description: Load existing research for a known site. Routes questions about a known site to its pre-built research files in docs/sites/{slug}/research/ (or legacy docs/research/{slug}/). Invokes the site-intel skill.
---

Invoke the site-intel skill for the provided site name or question.

If no site name was provided, list available researched sites (new location first, legacy labelled):
```bash
# New (scoped to */research/ — excludes reframe redesign/ folders):
find docs/sites -path '*/research/INDEX.md' 2>/dev/null | sed -E 's#docs/sites/(.*)/research/INDEX.md#\1#'
# Legacy (deprecated, read-only, removed in 0.8.0):
find docs/research -maxdepth 2 -name INDEX.md 2>/dev/null | sed -E 's#docs/research/(.*)/INDEX.md#  \1 (legacy)#'
```

Then ask: "Which site would you like to query?"

If no exact folder match, list the closest options and ask the user to confirm.
If neither path has any researched sites, tell the user to run /beacon:analyze first.

Route the user's question to the correct research file using the site-intel skill (which prefers the new path and falls back to legacy).
