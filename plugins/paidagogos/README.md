# paidagogos

Structured AI-powered lessons for any topic, rendered in a local browser UI.

## Install

```bash
claude plugin install paidagogos
```

## Usage

### Starting the visual server

Before running lessons, start visual-kit (per workspace):

```bash
visual-kit serve --project-dir .
```

You can then use `/paidagogos [topic]` and lessons will appear in your browser at the URL shown in the output.

Open **http://localhost:7337** in your browser, then teach yourself anything:

```
/paidagogos CSS flexbox
/paidagogos how async/await works
/paidagogos:micro "the event loop" --level beginner
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
| 0.1.0 | `paidagogos` router + `paidagogos:micro` + in-house visual server |
| 0.2.0 | Migrated to visual-kit dependency; lesson SurfaceSpec v1; dropped in-house server |
| 0.3.0 | `paidagogos:quiz` standalone + `paidagogos:explain` (Feynman) |
| 0.4.0 | `paidagogos:recall` + file-based progress |
