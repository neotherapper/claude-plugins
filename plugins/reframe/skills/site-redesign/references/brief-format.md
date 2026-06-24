# Brief Format — `brief.md` and `run-sheet.md` Contracts

Specifies the exact section order, per-page intent triplet format, design-system seed block format, and the canonical web-capture-override sentence. These are contracts — other tasks bind to the exact strings defined here.

---

## `brief.md` Section Order

Sections must appear in this order. Do not reorder; Claude Design reads them top-to-bottom as onboarding context.

1. **Assumptions header** *(editable, first)* — inferred purpose, audience, category, goal; current-vs-target purpose. Printed so a wrong inference is correctable at a glance before pasting into Claude Design.

2. **What the site is** — inferred purpose / value proposition. One or two sentences, grounded in on-page evidence.

3. **Target audience** — described using on-page evidence (language, tone, content specificity, testimonials, FAQs). Use proxies where direct evidence is absent; label any proxy-based inference.

4. **Redesign goals & success criteria** — 3–5 measurable or judgeable statements (e.g. "a first-time visitor understands what this does in 5 seconds"). No adjectives. No design theory.

5. **KEEP / CHANGE / ADD**
   - **KEEP** — brand assets (logo, brand color, wordmark — a visual constraint), ranking/high-value URLs plus a redirect map, working flows that convert.
   - **CHANGE** — concrete keep/fix deltas drawn from `current-critique.md`.
   - **ADD** — coverage gaps: journey stages with no supporting page or content.

6. **Information architecture (proposed)** — the screen/page list enumerated from the content audit, plus primary journeys and the conversion path. Each page carries an **intent triplet** (see format below).

7. **Design direction + design-system seed** — category-pack-sourced opinionated values (see seed block format below). No neutral re-description of current visuals.

8. **Reference + anti-reference sites** — taste in 3 words or a short `X × Y` compound. Include strict NOs (visual patterns, conventions, or aesthetics to avoid).

9. **Web-capture instruction (critical)** — the canonical sentence below, verbatim.

10. **Tech / export target + handoff** — stack note from `docs/sites/{slug}/research/tech-stack.md` (primary) or `docs/research/{slug}/tech-stack.md` (legacy fallback); if neither found, log `[TECH-STACK-ABSENT]` and write: "No beacon tech-stack found — specify the target stack manually, or run beacon first". Append "export ZIP / Open in Claude Code".

---

## Per-Page Intent Triplet Format

Every page in the IA section (§6) carries an intent triplet on a single line:

```
concrete subject · target audience · the page's single job
```

**Examples:**
```
Physiotherapy services for lower back pain · adults 30–55 in Bristol · persuade a sufferer this clinic treats their condition
About the practice and its lead therapist · first-time visitors evaluating trust · establish credibility before the booking step
Contact and booking · a visitor ready to book · remove friction from the first appointment
```

Rules:
- All three fields must be populated — no empty field
- "Single job" is one verb + object (persuade, establish, remove friction) — not a description of the page
- Audience is as specific as the evidence allows; use "general visitors" only as a last resort
- Subject is the concrete topic, not the page type ("About us" is a page type, not a subject)

---

## Design-System Seed Block Format

The seed block in §7 must provide concrete values, not adjectives. Fields:

```
Palette: 3–5 hex values, each followed by its role
  e.g. #1A2E44 (primary / navy trust anchor), #E8F4F8 (surface / light teal wash), #F4A01C (accent / warm CTA), #FFFFFF (base), #2D2D2D (body text)

Font candidates: body font + UI/heading font, with fallback stack
  e.g. Body: Inter / system-ui; Heading: Fraunces (serif weight contrast) or DM Serif Display

Spacing base: base unit in px or rem
  e.g. 8px grid (0.5rem increments)

Radius philosophy: none / subtle / rounded / pill — one word + brief rationale
  e.g. Subtle (4px cards, 8px buttons) — clinical trust, not SaaS playfulness

Motion: duration + easing stance
  e.g. 150ms ease-out transitions; no decorative animation

Borders vs shadows: which dominates and when
  e.g. Thin borders (1px #E0E0E0) for card separation; drop shadows only for elevated overlays (modals, dropdowns)
```

Do not emit "modern/clean/trustworthy" prose in this block. If the category pack does not supply values, use the `generic.md` pack defaults. Seed values must be numbers and hex codes.

---

## Canonical Web-Capture-Override Sentence

This is the exact string that must appear verbatim in §9 of every `brief.md`. Do not paraphrase.

> "Capture the live URL for content, structure, and brand assets to KEEP (logo, brand color, product photography) only. The design direction above OVERRIDES all captured visual styling."

This sentence prevents Claude Design's web-capture from cloning the existing visual design. It must follow immediately after any URL instruction in §9.

---

## `run-sheet.md` Ordering

The run-sheet is a sequenced set of canvas follow-up prompts derived from the site's actual pages. Order:

1. **Paste onboarding** — confirm the brief is loaded into Claude Design
2. **Validate** — render palette swatch + one hero screen; judge the feel against the brief's design direction before committing to more screens
3. **Key screen** — the highest-priority screen identified in the critique's top issues
4. **Remaining screens / components** — ordered by the critique's severity ratings (highest severity first), not by site navigation order

Each prompt in the run-sheet references a specific page from the IA section and its intent triplet.
