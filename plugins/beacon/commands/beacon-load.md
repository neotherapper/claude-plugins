---
name: beacon:load
description: Load existing research for a known site. Routes questions about a known site to its pre-built research files in docs/research/. Invokes the site-intel skill.
---

Invoke the site-intel skill for the provided site name or question.

If no site name was provided, list available sites:
```bash
ls docs/research/
```

Then ask: "Which site would you like to query?"

If no exact folder match, list the closest options and ask the user to confirm. If docs/research/ is empty, tell the user to run /beacon:analyze first.

Route the user's question to the correct research file using the site-intel skill.
