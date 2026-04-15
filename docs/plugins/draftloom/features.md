# Draftloom — Features

## v1.0 — Ships now

### Profile system
- [x] `/draftloom:setup` — 3-question onboarding (profile name, audience, tone)
- [x] Deferred optional fields (blog URL, content pillars, channels, length, inspiration, CTA goal)
- [x] Field-by-field profile editing via `/draftloom:setup edit {name}`
- [x] Multiple named profiles per user (e.g. `george-personal`, `vanguard-corporate`)
- [x] Project-local storage (`.draftloom/profiles/`) with global fallback (`~/.draftloom/`)
- [x] Profile delete with confirmation
- [x] Tone presets for users who aren't sure what adjectives to use
- [x] Slug-format validation on profile name

### Draft workflow
- [x] 4-question brief interview (topic, insight, examples, length)
- [x] Optional SEO brief extension (keyword, competitor URLs, publish date)
- [x] Numbered wireframe proposal with word counts and section purposes
- [x] Parse-able wireframe editor (`change 3 to 500w`, `add section between 1 and 2: ...`, `remove 4`)
- [x] Brief saved to `posts/{slug}/brief.md` (locked during iteration)
- [x] Session checkpointing and resume (`session.json`)
- [x] Multi-profile tiered selection (recent first with draft count)
- [x] Halt/finalize mid-loop (`"finalize"`, `"publish now"`, `"skip iterations"`)

### Eval loop
- [x] 4 specialist eval agents in parallel: SEO, hook, voice, readability
- [x] Per-agent output files (`seo-eval.json` etc) — no race conditions
- [x] Atomic writes (tmp → rename) — file presence signals completion
- [x] Orchestrator aggregates into `scores.json` after validation
- [x] Aggregate score = minimum of all 4 dimensions
- [x] Routing: patch (50–74) / escalate (<50) / pass (≥75) per dimension
- [x] Writer patches `sections_affected` only — passing sections preserved verbatim
- [x] Max 3 iterations with user choice on limit reached (publish / extend / discard)
- [x] Structured escalation (max 1× per run) with 4 user questions
- [x] Retry logic: 3 attempts with backoff, graceful skip on all retries failed
- [x] Per-workspace scoring weights in `scoring-config.json` (default: SEO 35, hook 30, voice 25, readability 10)

### Distribution
- [x] Distribution agent runs after all pass or on halt
- [x] `distribution.json` with: X hook (≤280 chars), LinkedIn opener (≤300 chars), email subject (≤60 chars), newsletter blurb (≤150 words)
- [x] Platform limits enforced — agent re-generates if over limit (no truncation)
- [x] `draft_hash` in `distribution.json` — re-runs if draft changes after generation

### Backend
- [x] File-based workspace (`posts/{slug}/`) — zero dependencies, Git-trackable
- [x] Optional Turso MCP backend (reference doc + backend flag in config)
- [x] Turso failure never blocks iteration — file system is primary source of truth

### Hook
- [x] SessionStart: hint `/draftloom:setup` if no profiles detected (silent if profiles exist)

---

## v2.0 — Next cycle

### Style extraction
- [ ] Feed existing blog posts → auto-extract voice profile (`brand_voice_examples`)
- [ ] `/draftloom:learn` command reads a folder of posts and populates profile fields

### Visual wireframe
- [ ] Interactive drag-drop wireframe (browser-based, local server — same pattern as brainstorming visual companion)
- [ ] Sections as draggable cards with live word count
- [ ] Add / remove / reorder without typing commands

### Research agents
- [ ] SERP research agent: analyse top-ranking posts for target keyword before drafting
- [ ] Competitor headline analysis informs wireframe section priorities

### Additional eval dimensions
- [ ] E-E-A-T validation (Google 2025 guidelines — expertise, experience, authority, trust signals)
- [ ] Fact-check / citation verification agent (cross-reference claims against sources)
- [ ] Sentiment / emotional resonance eval (surprise, joy, awe trigger scoring)

### Distribution expansion
- [ ] Visual content recommendations with placement suggestions (Unsplash/Pexels links)
- [ ] Platform variant generation: full X thread, LinkedIn carousel outline, TikTok script hook

### Infrastructure
- [ ] Workspace file locking for concurrent sessions (session_id + lock in session.json)
- [ ] Performance feedback loop: capture post analytics → update profile scoring weights
- [ ] Global `~/.draftloom/` cloud sync across projects

---

## Eval dimension rubrics (v1)

| Dimension | What it checks | Pass threshold |
|-----------|---------------|----------------|
| SEO | keyword density 1–3%, meta description completeness, H1→H2→H3 hierarchy, Flesch ≥60, internal link suggestions | 75/100 |
| Hook | first-sentence novelty, curiosity gap, title specificity (numbers/concrete claims), scroll-stop power | 75/100 |
| Voice | tone adjective match vs profile, sentence rhythm, vocabulary range, brand_voice_examples comparison | 75/100 |
| Readability | paragraph length ≤4 sentences, subheading every 300w, bullet/list distribution, sentence length variance | 75/100 |
