# learn

Structured AI-powered lessons for any topic, rendered in a local browser UI.

## Install

```bash
claude plugin install learn
```

## Usage

Start the visual server first by passing `serve` to the `/learn` router:

```
/learn serve
```

*(Runs the visual server — handled by the `/learn` router)*

Open **http://localhost:7337** in your browser, then teach yourself anything:

```
/learn CSS flexbox
/learn how async/await works
/learn:micro "the event loop" --level beginner
```

## What you get

Each lesson includes:
- **Concept** — clear, jargon-minimal explanation
- **Why it matters** — real-world motivation
- **Example** — syntax-highlighted code
- **Common mistakes** — pre-empts wrong mental models
- **Generate task** — a production challenge to try
- **Quiz** — 3 questions, scored with explanations

## Expertise levels

`beginner` · `intermediate` (default) · `advanced`

Set inline: `"teach me flexbox, I'm a beginner"`
Or on first use when prompted.

## Versions

| Version | Scope |
|---------|-------|
| 0.1.0 | `learn` router + `learn:micro` + visual server |
| 0.2.0 | `learn:quiz` standalone + `learn:explain` (Feynman) |
| 0.3.0 | `learn:recall` + file-based progress |
