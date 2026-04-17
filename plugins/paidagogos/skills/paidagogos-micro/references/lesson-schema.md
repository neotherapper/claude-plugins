# Lesson SurfaceSpec — Field Guidance

Paidagogos lessons now write a `lesson` **SurfaceSpec** — the rendering contract owned by visual-kit.

- **Canonical schema:** `vk://schemas/lesson.v1.json` (served by visual-kit at runtime)
- **Design spec:** `docs/superpowers/specs/2026-04-17-visual-kit-design.md §6.1`

The SurfaceSpec wrapper shape is:

```json
{
  "surface": "lesson",
  "version": 1,
  "topic": "...",
  "level": "beginner | intermediate | advanced",
  "estimated_minutes": 12,
  "caveat": "AI-generated — verify against official docs.",
  "sections": [ /* typed section objects — see below */ ]
}
```

Do not deviate from this wrapper. Visual-kit validates the file against `vk://schemas/lesson.v1.json` before rendering; a schema violation causes a render error in the browser.

## Section types (visual-kit core bundle)

The following section types render fully in the visual-kit core bundle:

| type | required field(s) | renders |
|------|-------------------|---------|
| `concept` | `text` | Prose explanation |
| `why` | `text` | Motivation paragraph |
| `code` | `source`, `language` | Static syntax-highlighted block |
| `mistakes` | `items` (string[]) | Bulleted mistake list |
| `generate` | `task` | Challenge prompt |
| `resources` | `items` (Resource[]) | Link list with badges |
| `next` | `concept` | Follow-on concept suggestion |

The following section types render as **inert placeholders** in the core bundle (Plan B adds full rendering):

| type | status |
|------|--------|
| `quiz` | Future work — Plan B |
| `chart` | Future work — Plan B |
| `math` | Future work — Plan B |

## Field population guidance

Use the following rules when deciding what to put in each section when populating the SurfaceSpec:

- **concept** section `text` — 2–3 sentences; no jargon for `beginner`; full technical precision for `advanced`
- **why** section `text` — one concrete real-world situation; starts with "You'll use this when..."
- **code** section `source` — working code for code topics; `language` is required alongside it
- **mistakes** section `items` — exactly 2–3 items; concrete, not generic; framed as "Forgetting that..." not "Always remember to..."
- **generate** section `task` — starts with an action verb; completable in 5–10 minutes; directly exercises the concept
- **quiz** section `items` — exactly 3 questions: one `multiple_choice` (4 options, exactly 1 correct), one `fill_blank`, one `explain`; every `explanation` field states why the answer is correct (Note: quiz renders as an inert placeholder until Plan B is installed)
- **resources** section `items` — at least 1 item with `type: "docs"`; sourced via vault lookup; any item with `source: "ai-suggested"` gets an "(AI-suggested, verify link)" badge in the UI
- **next** section `concept` — one concept directly related to the topic, one step up in complexity; the concept name only (e.g. "CSS Grid")
- `estimated_minutes` (top-level) — realistic read + generate task time; typically 8–15 minutes

## Example (valid SurfaceSpec for CSS Flexbox)

```json
{
  "surface": "lesson",
  "version": 1,
  "topic": "CSS Flexbox",
  "level": "beginner",
  "estimated_minutes": 10,
  "caveat": "AI-generated — verify against official docs.",
  "sections": [
    {
      "type": "concept",
      "text": "Flexbox is a CSS layout model that arranges items in a row or column and distributes space between them automatically. You define a flex container with `display: flex`, and its direct children become flex items."
    },
    {
      "type": "why",
      "text": "You'll use this whenever you need to centre something, build a navigation bar, or lay out a card grid without writing complex float or position hacks."
    },
    {
      "type": "code",
      "language": "css",
      "source": ".container {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}\n\n.item {\n  flex: 1;\n}"
    },
    {
      "type": "mistakes",
      "items": [
        "Applying flex properties to the wrong element — `justify-content` goes on the container, not the items.",
        "Forgetting that `flex-direction: column` changes the axis, so `justify-content` then controls vertical and `align-items` controls horizontal.",
        "Using `width` instead of `flex-basis` inside a flex container — `flex-basis` plays nicer with the flex algorithm."
      ]
    },
    {
      "type": "generate",
      "task": "Write a `.navbar` flex container with the logo on the left and three nav links on the right, all vertically centred, using only flexbox — no positioning."
    },
    {
      "type": "quiz",
      "items": [
        {
          "type": "multiple_choice",
          "question": "Which property centres flex items along the main axis?",
          "options": ["align-items", "justify-content", "align-content", "flex-align"],
          "answer": "justify-content",
          "explanation": "`justify-content` distributes space along the main axis (horizontal by default). `align-items` controls the cross axis."
        },
        {
          "type": "fill_blank",
          "question": "To make a flex container lay out items in a column, you set `flex-direction: ___`.",
          "answer": "column",
          "explanation": "`flex-direction: column` makes the main axis run top-to-bottom, so items stack vertically."
        },
        {
          "type": "explain",
          "question": "In your own words: what's the difference between `justify-content` and `align-items`?",
          "answer": "justify-content controls spacing along the main axis; align-items controls alignment on the cross axis",
          "explanation": "Main axis = the direction items flow (row = horizontal, column = vertical). Cross axis = perpendicular to that."
        }
      ]
    },
    {
      "type": "resources",
      "items": [
        {
          "title": "CSS Flexible Box Layout — MDN",
          "url": "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_flexible_box_layout",
          "type": "docs",
          "source": "vault"
        },
        {
          "title": "Flexbox Froggy",
          "url": "https://flexboxfroggy.com/",
          "type": "interactive",
          "source": "vault"
        }
      ]
    },
    {
      "type": "next",
      "concept": "CSS Grid — the two-dimensional layout companion to flexbox"
    }
  ]
}
```
