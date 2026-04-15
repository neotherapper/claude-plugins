# Distribution Guide

Templates and character limits for platform copy. Load this file in the distribution agent.

## Platform constraints

| Platform | Field | Hard limit | Notes |
|----------|-------|-----------|-------|
| X (Twitter) | `x_hook` | 280 chars | No links. Pure text hook that makes people stop. |
| LinkedIn | `linkedin_opener` | 300 chars | Professional tone. Can include an emoji. |
| Email | `email_subject` | 60 chars | No clickbait. Promise what the post delivers. |
| Newsletter | `newsletter_blurb` | 150 words | Conversational. Ends with a CTA link placeholder. |

**Enforcement rule:** If generated copy exceeds the limit, regenerate — do not truncate. Truncating mid-sentence produces bad copy. Regenerate with the constraint as a hard instruction.

## X hook template patterns

Strong X hooks follow one of these patterns:

| Pattern | Example |
|---------|---------|
| Counterintuitive claim | "Most developers optimise for the wrong thing. Here's what actually matters." |
| Specific stat | "I went from 0 to 500 subscribers in 60 days. 3 things I did that nobody talks about." |
| Challenge | "Your state management is the problem. Not your framework." |
| Story hook | "Six months ago I deleted all my React Query code. Here's what happened." |

## LinkedIn opener template

LinkedIn openers should:
- State the core thesis in sentence 1
- Give a specific claim or number in sentence 2
- End with a teaser ("More in the post 👇" or "Here's what I learned:")

## Email subject template

Email subjects should:
- Be specific, not clever
- Promise a concrete takeaway
- Avoid spam trigger words (FREE, !!!!, URGENT)
- Test: would you open this email from an unfamiliar sender?

## newsletter_blurb template

```
{2-3 sentence summary of the post's core argument}

{1 sentence on who this is most useful for}

Read it here → {CTA_LINK}
```

Replace `{CTA_LINK}` with a placeholder — the actual URL is added by the user at publish time.

## Staleness check

The distribution agent writes a SHA-256 hash of `draft.md` to `distribution.json → draft_hash`. If the orchestrator detects that `draft.md` has been modified after `distribution.json` was written (hash mismatch), it re-runs the distribution agent automatically.
