# Brief Questions

Questions asked during the draft brief interview. Load this file during Step 2 of the draft skill.

## Mandatory questions (4) — ask in order

### Q1 — Topic and angle
"What's the topic or angle for this post? Be specific — what's the take or twist that makes it worth writing?"

Examples:
- "Why I stopped using React Query and went back to fetch"
- "The hidden cost of 'free' AI APIs for startups"
- "How I went from 0 to 500 newsletter subscribers in 60 days"

Validation: free text, 20–200 characters. If too vague (e.g. "AI"), probe: "What's the specific angle or opinion?"

### Q2 — Core insight
"What's the one insight you want the reader to leave with? If they forget everything else, what's the sentence that stays?"

Validation: free text, 20–300 characters. This becomes the post's thesis and directly informs hook scoring.

### Q3 — Examples, data, stories
"Any specific examples, data points, or stories to include? (optional — press Enter to skip)"

Validation: free text or empty. If the user provides URLs, treat them as reference material for the writer agent.

### Q4 — Target length
"How long should this post be?
  short  — ~500 words (opinion, quick take)
  medium — ~1000 words (how-to, explainer)
  long   — ~2000+ words (deep dive, case study)"

Accept: "short", "medium", "long", or a word count like "800 words". Normalise to short/medium/long for the wireframe.

---

## Optional questions (3) — offer as a group after mandatory

### Q5 — Primary keyword (SEO)
"What's the primary keyword you want to rank for? (e.g. 'react state management')"

Stored in `meta.json` → keywords[0]. Used by seo-eval agent.

### Q6 — Competitor posts to beat
"Any competitor posts you want to outrank or write a better version of? Paste URLs (one per line, or press Enter to skip)"

Stored in `brief.md` → Competitor URLs. Writer agent uses these as style/depth references.

### Q7 — Target publish date
"Do you have a target publish date?" (optional, used for scheduling context only)

---

## brief.md format

Write all answers in this format to `posts/{slug}/brief.md`:

```markdown
# Brief: {Title}

**Topic:** {Q1 answer}
**Insight:** {Q2 answer}
**Audience:** {from profile.audience}
**Tone:** {from profile.tone, joined by commas}
**Examples:** {Q3 answer or "none provided"}
**Length:** {short/medium/long}
**Key Messages:** {derived from Q1 and Q2 by the skill}
**CTA:** {from profile.cta_goal}
**Constraints:** {any hard constraints mentioned by user}

## Optional
**Primary keyword:** {Q5 or null}
**Competitor URLs:** {Q6 urls or null}
**Publish date:** {Q7 or null}

## Sections
{wireframe block appended after Step 3}
```
