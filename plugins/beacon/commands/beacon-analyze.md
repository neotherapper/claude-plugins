---
name: beacon:analyze
description: Analyse a website and produce structured API surface documentation in docs/research/{site}/. Invokes the site-recon skill.
---

Invoke the site-recon skill to analyse the provided URL.

If no URL was provided with the command, ask: "What URL would you like to analyse?"

Run the full 12-phase site-recon workflow for the given URL.
Output all findings to docs/research/{site-name}/ as defined in the skill.
