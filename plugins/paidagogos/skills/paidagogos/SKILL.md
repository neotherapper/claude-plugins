---
name: paidagogos
description: >
  This skill should be used when the user wants to learn something, asks to be
  taught a topic, says "teach me X", "explain X", "how does X work", "I want to
  learn X", or similar. Routes to paidagogos:micro for focused concepts.
---

# paidagogos — Router

## Role

Entry point for the `paidagogos` plugin. Classify the user's learning intent, determine scope, and route to the correct sub-skill. Always surface the routing decision — never silently reroute.

## Routing table

| User input | Action |
|---|---|
| "teach me [concept]" | Scope check → route to paidagogos:micro |
| "explain [thing]" | Scope check → route to paidagogos:micro |
| "how does [thing] work" | Scope check → route to paidagogos:micro |
| "what is [thing]" (learning context) | Scope check → route to paidagogos:micro |
| "I don't understand [thing]" | Scope check → route to paidagogos:micro |
| "walk me through [thing]" | Scope check → route to paidagogos:micro |
| "/paidagogos [topic]" (bare invocation) | Scope check → route to paidagogos:micro |
| "/paidagogos serve" or "start the server" | Start visual-kit yourself: run `visual-kit serve --project-dir .` as a background shell command (Bash with `run_in_background: true`), poll `.visual-kit/server/state/server-info` until `status` is `"running"`, then report the URL from the `port` field. Do NOT ask the user to run it. |
| "quiz me on [thing]" | Respond: "`paidagogos:quiz` is coming in v0.2.0. Use `/paidagogos [topic]` to get a lesson with a built-in quiz." |
| "what have I learned" / "show progress" | Respond: "Progress tracking is coming in v0.2.0." |
| "continue my lesson on X" | Respond: "Session recall is coming in v0.2.0." |
| "I want to become [role]" / "roadmap for X" | Scope check → if broad, explain path is v0.3.0, offer first concept |

## Scope classifier

Before routing to paidagogos:micro, classify whether the topic is a single concept or a broad area.

**Single concept (route directly to paidagogos:micro):**
- Maps to ≤3 distinct sub-concepts
- Examples: "CSS flexbox", "async/await", "the event loop", "SQL JOINs", "Python list comprehensions"

**Broad topic (ask before routing):**
- Maps to >3 distinct sub-concepts or is a technology/field name
- Examples: "React", "machine learning", "system design", "become a full-stack engineer", "Python"

When genuinely uncertain whether a topic is single or broad, ask rather than guess — default to the broad topic flow.

When the topic is broad, respond:

```
**[Topic]** is a broad area with many concepts. What would you like to do?

1. **One focused lesson** — pick one concept to learn right now (I'll suggest a good starting point)
2. **Full learning path** — a structured roadmap with milestones *(coming in v0.3.0)*

Which would you prefer?
```

If the user picks option 1: suggest the best entry concept for the topic and invoke paidagogos:micro with it.
If the user picks option 2: respond "Learning paths are coming in v0.3.0. For now, I can teach you [suggest best entry concept]. Want to start there?"

## Debug mode

If `PAIDAGOGOS_DEBUG=1` is set in the environment, print the routing decision before invoking any sub-skill:

```
[paidagogos:router] intent=micro topic="{topic}" level={level} scope={single|broad}
```

## What this skill does NOT handle

- Lesson generation — delegated to paidagogos:micro
- Visual rendering — handled by visual-kit
- Progress storage — V2
- Curriculum planning — V3
