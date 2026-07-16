---
name: aegis:scan
description: Run a passive vulnerability-coverage scan on a site. Produces a prioritized report of known CVEs, KEV exploited items, EPSS likelihood scores, and TLS/header misconfig grades.
---

Run the site-security skill for the provided target.

If a URL or slug was provided as `$ARGUMENTS`, pass it to coverage.py:

```bash
# If argument looks like a URL:
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/coverage.py" --url "$ARGUMENTS"

# If argument looks like a slug:
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/coverage.py" --slug "$ARGUMENTS"
```

If no argument was provided, ask the user: "Which site would you like to scan? (URL or slug)"

Present the results with KEV exploited items highlighted first, then high-EPSS/high-CVSS findings.
State that this is a passive lookup — no active probing was performed.
