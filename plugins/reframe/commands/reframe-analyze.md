---
name: reframe:analyze
description: Analyse an existing website and produce a purpose-driven redesign brief for Claude Design. Invokes the site-redesign skill.
---

Invoke the site-redesign skill for the provided URL.

If no URL was provided with the command, ask: "What site URL would you like to redesign?"

Run the full 9-phase site-redesign workflow and write all output to docs/sites/{slug}/redesign/ as defined in the skill.

Always ask the one strategic question the skill requires — "redesign for the same purpose, or a new one?" — before finalising the brief.

If the site renders no usable content (greenfield/placeholder), say so and stop rather than inventing a brief.
