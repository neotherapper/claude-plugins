---
name: beacon:analyze
description: Analyze a website and produce structured API surface documentation. Invokes the site-recon skill.
---

Invoke the site-recon skill to analyze the provided URL.

If no URL was provided with the command, ask: "What URL would you like to analyze?"

Run the full 12-phase site-recon workflow for the given URL.
Output all findings to docs/research/ as defined in the skill.

If the site is unreachable or the URL is malformed, report the error and stop — do not produce partial output.
