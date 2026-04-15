# Learn — Testing Guide

> How to validate Learn behaviour against its acceptance criteria.

Learn has no runtime application code — it is an AI skill system with a companion visual server. "Testing" means running the plugin in Claude Code and verifying observable outputs match the Gherkin scenarios in `docs/plugins/learn/specs/`, and verifying the visual server renders lessons correctly.

---

## Feature files

| File | What it covers |
|------|---------------|
| `specs/learn.feature` | Router: intent detection, scope classifier, routing decisions surfaced to user |
| `specs/learn-micro.feature` | Lesson generation: Lesson JSON shape, expertise level, quiz, resource links |
| `specs/visual-server.feature` | Server startup, file-watcher, port conflict, auto-exit, browser rendering |

---

## Running a scenario

1. Open a project in Claude Code with Learn installed
2. Identify the scenario to test (copy the `Scenario:` title)
3. Set up the `Given` preconditions manually (start the visual server, set env vars, etc.)
4. Run the `When` step as a natural language command
5. Verify each `Then` assertion against actual files and Claude output

**Example — "Router surfaces routing decision before acting":**

```
Given  LEARN_DEBUG is not set
When   user types: "teach me CSS flexbox"
Then   Claude outputs which skill it is routing to before generating the lesson
       Claude does not silently invoke learn:micro without informing the user
```

**Example — "Scope classifier fires on broad topic":**

```
Given  user types: "teach me JavaScript"
When   router evaluates topic scope (> 3 sub-concepts detected)
Then   Claude asks: "Do you want a full roadmap or one focused concept?"
       Claude waits for the user's answer before proceeding
       Claude does not silently route to learn:micro
```

---

## File-output assertions

After a successful `/learn` run, verify:

```
screen_dir/
├── lesson-{id}.html      — non-empty, fully rendered lesson page
└── waiting.html          — present between lesson generations

state_dir/
└── events                — JSON lines, one per quiz interaction (written by visual server)
```

Open `lesson-{id}.html` directly and verify it contains all lesson sections:
- Concept explanation
- Why (motivation)
- Example with syntax highlighting
- Common mistakes list
- Generate task
- Quiz (3 questions, default ON)
- Resource links

---

## Lesson JSON contract validation

Before HTML is written, `learn:micro` must produce a valid Lesson JSON. Verify the shape:

```json
{
  "topic": "<string>",
  "level": "beginner | intermediate | advanced",
  "concept": "<2-3 sentence explanation>",
  "why": "<real-world motivation>",
  "example": {
    "code": "<optional string>",
    "prose": "<optional string>",
    "language": "<optional string>"
  },
  "common_mistakes": ["<string>", "<string>"],
  "generate_task": "<production task prompt>",
  "quiz": [
    {
      "type": "multiple_choice | fill_blank | explain",
      "question": "<string>",
      "options": ["<string>"],
      "answer": "<string>",
      "explanation": "<string>"
    }
  ],
  "resources": [
    {
      "title": "<string>",
      "url": "<string>",
      "type": "docs | tutorial | video | interactive"
    }
  ],
  "estimated_minutes": <number>
}
```

Missing any required field = validation failure. Do not write HTML if Lesson JSON is malformed.

---

## Router behaviour — what to verify

| Input | Expected behaviour |
|-------|-------------------|
| `"teach me async/await"` (narrow concept) | Routes directly to learn:micro, announces routing |
| `"teach me JavaScript"` (broad, > 3 sub-concepts) | Scope classifier fires, asks user to choose |
| `"teach me async/await, I'm a beginner"` | Expertise level set to beginner for this lesson |
| `"build me an app"` | Explains V1 scope, offers to start with a specific concept |
| `"teach me X"` with LEARN_DEBUG=1 | Routing decision log printed before action |

---

## Expertise level adaptation — what to verify

1. Run `"teach me closures"` with no prior context
2. Verify Claude defaults to `intermediate` level
3. Run `"teach me closures, I'm new to programming"`
4. Verify the concept explanation uses simpler vocabulary, the generate task is appropriately scoped
5. Run `"teach me closures"` as George (senior, 10+ years)
6. Verify the explanation skips basics, the generate task is non-trivial

---

## Visual server scenarios

**Happy path:**
1. Run `learn serve` in a terminal
2. Verify output includes `listening on http://127.0.0.1:7337`
3. Run a lesson via `/learn teach me X`
4. Verify browser opens (or URL is logged)
5. Verify lesson content renders with all sections visible

**Port conflict:**
1. Start any process on port 7337
2. Run `learn serve`
3. Verify server starts on the next free port (e.g. 7338)
4. Verify the actual URL is logged: `learn serve: listening on http://127.0.0.1:7338`

**Auto-exit:**
1. Start `learn serve`
2. Wait 30 minutes with no lesson activity
3. Verify the server process exits cleanly

**Server not running:**
1. Do NOT start `learn serve`
2. Run a lesson via `/learn teach me X`
3. Verify Claude shows the error message: `"Visual server is not running — start it with 'learn serve'"`
4. Verify no `.html` file is written to `screen_dir/`

---

## Edge cases to test

**Broad topic routing:**
- `"teach me machine learning"` → scope classifier must fire, not silently route
- `"teach me React"` → scope classifier must fire and ask

**Quiz opt-out:**
1. Run `"teach me flexbox, skip the quiz"`
2. Verify the generated lesson HTML contains no quiz section
3. Verify Lesson JSON has an empty `quiz` array

**Lesson generation failure:**
1. Introduce a deliberately broken prompt constraint that causes generation to fail
2. Verify no `.html` file is written to `screen_dir/`
3. Verify Claude shows an explicit error message, does not silently continue

**Knowledge vault miss:**
1. Request a lesson on a topic with no matching entry in `knowledge/`
2. Verify resource links are still generated
3. Verify each AI-generated link is marked `(AI-suggested, verify link)`
4. Verify no link is presented as verified when the vault was not matched

**AI-generated caveat:**
1. Request a lesson on a niche topic unlikely to be in the knowledge vault
2. Verify the lesson includes the caveat: `"This explanation is AI-generated — verify against official documentation."`

---

## Regression checklist before any PR

- [ ] `/learn teach me X` (narrow concept) routes to learn:micro and announces routing
- [ ] `/learn teach me X` (broad topic) fires scope classifier and asks the user before proceeding
- [ ] Router never silently reroutes — routing decision always surfaced in output
- [ ] `LEARN_DEBUG=1 /learn teach me X` prints routing decision log
- [ ] `learn:micro` generates valid Lesson JSON before writing any HTML
- [ ] No partial HTML written on lesson generation failure
- [ ] Quiz present in lesson output by default (3 questions)
- [ ] Quiz absent when user explicitly opts out
- [ ] Expertise level adapts to inline user signal ("I'm a beginner")
- [ ] `learn serve` starts on port 7337 by default
- [ ] `learn serve` auto-increments port on conflict and logs actual URL
- [ ] Visual server exits after 30 minutes of inactivity
- [ ] Server-not-running error message shown when skill runs without server
- [ ] Knowledge vault miss falls back to AI-suggested links, marked with caveat
- [ ] All AI-synthesised content includes the AI-generated caveat
