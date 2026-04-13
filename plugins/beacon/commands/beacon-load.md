---
name: beacon:load
description: Load existing research for a known site. Routes questions to pre-built docs/research/{site}/ files. Invokes the site-intel skill.
---

Invoke the site-intel skill for the provided site name or question.

If no site name was provided, list available sites:
```bash
ls docs/research/
```

Then ask: "Which site would you like to query?"

Route the user's question to the correct research file using the site-intel skill.
