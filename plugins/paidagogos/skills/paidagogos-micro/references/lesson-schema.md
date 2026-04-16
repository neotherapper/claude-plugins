# Lesson JSON Schema

This is the canonical data shape output by `paidagogos:micro`. The visual server reads it; future MCP layers will too. Do not deviate from this shape.

## TypeScript Interface

```typescript
interface Lesson {
  topic: string;
  level: "beginner" | "intermediate" | "advanced";
  concept: string;
  why: string;

  renderers: RendererKey[];      // V2: required. [] if plain code/text only.

  example: {
    code?: string;
    prose?: string;
    language?: string;
    renderer?: RendererKey;      // V2: if set, use this edu-[name] for the example
    config?: Record<string, unknown>;  // V2: renderer-specific config object
  };
  common_mistakes: string[];
  generate_task: string;
  quiz: QuizQuestion[];
  resources: Resource[];
  next: string;
  estimated_minutes: number;
}

type RendererKey =
  | "math" | "code" | "chart" | "geometry" | "sim-2d";

interface QuizQuestion {
  type: "multiple_choice" | "fill_blank" | "explain";
  question: string;
  options?: string[];
  answer: string;
  explanation: string;
}

interface Resource {
  title: string;
  url: string;
  type: "docs" | "tutorial" | "video" | "interactive";
  source: "vault" | "ai-suggested";
}
```

## Rules

- `common_mistakes` MUST have exactly 2–3 items. Never 0, never 4+.
- `quiz` MUST have exactly 3 items. One `multiple_choice`, one `fill_blank`, one `explain`.
- `resources` MUST have at least 1 item with `type: "docs"`.
- Any resource with `source: "ai-suggested"` will be shown with a `(AI-suggested, verify link)` badge in the UI.
- `estimated_minutes` should account for reading + generate task attempt. Typically 8–15 minutes.
- `next` MUST be a single concept one step up in complexity from the lesson topic.
- `renderers` MUST always be present. Empty array `[]` is valid for lessons with no subject-domain rendering (e.g., pure text concepts).
- `renderers` values MUST come from the `RendererKey` union. `example.renderer` must also be listed in `renderers[]` (if set).
- V2 renderer keys: `math`, `code`, `chart`, `geometry`, `sim-2d`.

## Example (valid Lesson JSON)

```json
{
  "topic": "CSS Flexbox",
  "level": "beginner",
  "renderers": ["code"],
  "concept": "Flexbox is a CSS layout model that arranges items in a row or column and distributes space between them automatically. You define a flex container with `display: flex`, and its direct children become flex items.",
  "why": "You'll use this whenever you need to centre something, build a navigation bar, or lay out a card grid without writing complex float or position hacks.",
  "example": {
    "code": ".container {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}\n\n.item {\n  flex: 1;\n}",
    "language": "css",
    "renderer": "code"
  },
  "common_mistakes": [
    "Applying flex properties to the wrong element — `justify-content` goes on the container, not the items.",
    "Forgetting that `flex-direction: column` changes the axis, so `justify-content` then controls vertical and `align-items` controls horizontal.",
    "Using `width` instead of `flex-basis` inside a flex container — `flex-basis` plays nicer with the flex algorithm."
  ],
  "generate_task": "Write a `.navbar` flex container with the logo on the left and three nav links on the right, all vertically centred, using only flexbox — no positioning.",
  "quiz": [
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
  ],
  "resources": [
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
  ],
  "next": "CSS Grid — the two-dimensional layout companion to flexbox",
  "estimated_minutes": 10
}
```
