# Brand Interview

## Personal Branding Flow

Trigger when the user's description contains any of these signals:
- Keywords: "portfolio", "freelance", "personal site", "my name", "my website", "consulting", "my work"
- Pattern: a human first/last name as the primary subject (e.g., "I need a domain for John Smith")

### Personal Brand Name Patterns

Generate availability checks for these patterns (substitute actual name):
- `{firstname}.com`
- `{firstname}.dev`
- `{firstnamelastname}.com`
- `{firstnamelastname}.dev`
- `{f}{lastname}.com` (initial + last name, e.g., jpilitsoglou.com)
- `{f}{lastname}.dev`
- `{firstname}.studio` / `{firstname}.design` / `{firstname}.work`
- `{firstname}.io` / `{firstname}.co` / `{firstname}.me`

Run these patterns through `check-domains.sh` following the availability check process in SKILL.md Step 5. Present results, then offer: "Want me to also generate creative branded alternatives beyond your name?"

---

## Standard Interview — 6 Questions

Ask one question per message. Wait for the answer before proceeding.

### Q1 — What are you building?
```
What are you building? A one-liner or a few keywords works perfectly.
```
*Open answer. Extract: core function, target audience, industry.*

### Q2 — Personality / Tone
```
How should the name feel? Pick the closest:

a) Cool/media-brand — Minimal, confident, modern (Figma, Letterboxd, Vercel, Linear)
b) Authoritative/benchmark — Credible, established, serious (Bloomberg, Stripe, Notion, Atlassian)
c) Playful/community — Fun, approachable, social (Discord, Duolingo, Mailchimp)
```

### Q3 — Direction
```
What direction for the name itself?

a) Functional — The name says what it does or who it's for (DevAtlas, CodeShip, DataMint, BuildStack)
b) Abstract/invented — A memorable coined word with no literal meaning (Lumora, Vercel, Spotify, Figma)
```

### Q4 — Budget Mode
```
TLD budget preference?

a) Budget — Open to .icu, .xyz, .top, .online, .site (cheapest viable, ~$1–5/yr)
b) Balanced — Mix of .com, .io, .dev, .app (common tech TLDs, ~$10–40/yr)
c) Premium — .com strongly preferred; .io/.dev as fallback only
```

### Q5 — Name Length
```
Name length preference?

a) Short & punchy — 6 characters or fewer (Figma, Driv, Vercel, Vex, Navo)
b) Expressive — 7+ characters, room for personality (Letterboxd, Cloudflare, BuildStack)
```

### Q6 — Hard Constraints
```
Any hard constraints? For example:
- Must include a specific word
- No hyphens
- Specific TLD required (.com only, etc.)
- Max character count

Or type "none" to skip.
```

---

## Weighting Rules

Apply these rules to archetype generation counts in Wave 1:

| Answer combination | Effect on generation |
|-------------------|---------------------|
| Q2=A + Q3=B | Abstract/Brandable ×2, Domain Hacks ×1.5 |
| Q2=A + Q3=A | Descriptive ×1.5, Compound/Mashup ×1.5, Thematic TLD Play ×1.5 |
| Q2=B + Q3=A | Descriptive ×2, Compound/Mashup ×2 |
| Q2=B + Q3=B | Abstract/Brandable ×1.5, Short & Punchy ×1.5 |
| Q2=C | Playful/Clever ×2, Short & Punchy ×1.5 |
| Q4=A | Bias TLD selection to: .icu, .xyz, .top, .online, .site, .fun, .space |
| Q4=C | Bias TLD selection to: .com primary; .io, .dev as secondary only |
| Q5=A | Short & Punchy ×2; cap all generated names at 6 characters where possible |

Default (no strong signal): distribute evenly across all 7 archetypes.
