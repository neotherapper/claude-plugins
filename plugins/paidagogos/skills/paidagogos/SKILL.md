---
name: paidagogos
description: >
  Use when the user wants to learn something, be taught a topic, understand a
  concept, or explore something visually or interactively. Triggers on: "teach
  me X", "explain X", "how does X work", "I want to learn X", "I don't
  understand X", "walk me through X", "show me X visually", "animate X", "plot
  X with sliders". Also triggers when the user names something they're confused
  about without using the word "learn" — e.g. "I keep mixing up SQL joins" or
  "I want to understand git rebase". Routes to paidagogos:micro for focused
  concepts. Handles server start ("/paidagogos serve") and future features
  (quiz, progress, curriculum). Use this skill for any learning intent even
  when the request is indirect.
---

# paidagogos — Router

Entry point for the `paidagogos` plugin. Classify the user's learning intent and scope, then route to the right sub-skill. Always say which sub-skill you're routing to — never silently reroute.

## Routing table

| User input | Action |
|---|---|
| "teach me [concept]" | Scope check → route to `paidagogos:micro` |
| "explain [thing]" | Scope check → route to `paidagogos:micro` |
| "how does [thing] work" | Scope check → route to `paidagogos:micro` |
| "what is [thing]" (learning context) | Scope check → route to `paidagogos:micro` |
| "I don't understand [thing]" | Scope check → route to `paidagogos:micro` |
| "walk me through [thing]" | Scope check → route to `paidagogos:micro` |
| "show me [thing] visually / with sliders / animated" | Scope check → route to `paidagogos:micro` (interactive mode) |
| "/paidagogos [topic]" (bare invocation) | Scope check → route to `paidagogos:micro` |
| "/paidagogos serve" or "start the server" | Start visual-kit: run `visual-kit serve --project-dir .` in background (`run_in_background: true`), poll `.visual-kit/server/state/server-info` until `status` is `"running"`, report the URL. Do NOT ask the user to run it. |
| "quiz me on [thing]" | Respond: "`paidagogos:quiz` is coming in v0.2.0. Use `/paidagogos [topic]` to get a lesson with a built-in quiz." |
| "what have I learned" / "show progress" | Respond: "Progress tracking is coming in v0.2.0." |
| "continue my lesson on X" | Respond: "Session recall is coming in v0.2.0." |
| "I want to become [role]" / "roadmap for X" | Scope check → if broad, explain path is v0.3.0, offer first concept |

## Scope classifier

Before routing to `paidagogos:micro`, decide if the topic is a single concept or a broad area.

**Single concept → route directly:**
Maps to ≤3 distinct sub-concepts. Examples: "CSS flexbox", "async/await", "the event loop", "SQL JOINs", "Python list comprehensions", "derivatives", "(a+b)²".

**Broad topic → ask first:**
Maps to >3 sub-concepts or is a whole technology/field. Examples: "React", "machine learning", "system design", "calculus", "Python".

When the topic is broad, respond:

```
**[Topic]** is a broad area with many concepts. What would you like to do?

1. **One focused lesson** — pick one concept to learn right now (I'll suggest a good starting point)
2. **Full learning path** — a structured roadmap with milestones *(coming in v0.3.0)*

Which would you prefer?
```

If the user picks option 1: suggest the best entry concept and invoke `paidagogos:micro`.
If the user picks option 2: "Learning paths are coming in v0.3.0. For now, I can teach you [entry concept]. Want to start there?"

When genuinely uncertain, default to the broad topic flow and ask.

## Debug mode

If `PAIDAGOGOS_DEBUG=1` is set, print before routing:

```
[paidagogos:router] intent=micro topic="{topic}" level={level} scope={single|broad}
```

## Out of scope

Lesson generation, visual rendering, progress storage, and curriculum planning are all delegated — this skill only classifies and routes.
