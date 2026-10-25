# Idea Evaluation: Greek Schools Directory

**Date:** 2026-03-27
**Evaluator:** Claude (baseline, no skill)
**Verdict:** BUILD with caveats

---

## Summary

A web directory listing all ~14,000 public and private primary and secondary schools in Greece, with location, type, contact details, and eventually parent ratings. The founder has domain knowledge (Greek), technical skills (web dev), and a pre-scraped dataset from the Ministry of Education. The market gap is real: no good central directory currently exists.

**Score: 64 / 100**

---

## Evaluation Criteria

### 1. Problem Clarity — 9/10

The problem is concrete and verifiable: parents, teachers, and administrators in Greece lack a single searchable directory for schools. The Ministry of Education data is spread across bureaucratic pages that are not user-friendly or aggregable. This is a genuine friction point experienced by parents relocating within Greece, expats, or anyone doing school research for their children.

**Strengths:**
- Specific, well-defined gap
- Founder has personal experience of the problem
- ~14,000-school dataset already collected confirms the gap is real

### 2. Market Size — 5/10

Greece has approximately 10.4 million people. There are roughly 1.4 million students in primary and secondary education. The addressable audience is parents (roughly 800,000–1.2 million households with school-age children), teachers, school administrators, real estate agents, and relocation services.

This is a small total addressable market by global standards. Greece's population is concentrated, and the market has limited international expansion path (the directory is inherently Greek-language and geography-specific unless the model is exported to other countries). Revenue potential is modest unless monetization is well-structured.

**Risks:**
- Small national market limits absolute revenue ceiling
- Advertising CPMs in Greece are among the lowest in Europe
- No built-in subscription pull from end-users (parents expect free information)

### 3. Founder-Market Fit — 9/10

This is one of the strongest dimensions of the idea. The founder is:
- Greek (native cultural and linguistic understanding)
- A web developer (can build and maintain without outsourcing)
- Already has the dataset (massive head start, months of work saved)

This is rare and material. Most directory businesses fail because acquiring the core dataset is expensive and slow. The founder has already cleared the hardest early barrier.

### 4. Competitive Landscape — 6/10

There is no dominant Greek schools directory. The Ministry of Education has a registry but it is not user-friendly, not searchable by filters, and lacks enrichment (ratings, photos, reviews). This is the classic "government data, bad UX" gap that directory businesses have successfully exploited in other domains (e.g., Zocdoc for doctors, Yelp for restaurants).

**Potential threats:**
- The Ministry of Education could eventually improve its own portal (low probability in medium term, but a real long-term risk)
- A larger Greek media or edtech company could replicate the directory with more resources
- Google Maps already has some school listings; parents may default to Google

**Defensibility:** Moderate. Data is freely available from government sources, so the moat must come from UX, ratings/reviews, and community trust — not data exclusivity.

### 5. Business Model Viability — 5/10

This is the weakest dimension. Directory sites need to answer: "How do we make money?"

**Possible monetization paths:**

| Model | Feasibility | Risk |
|-------|------------|------|
| Display advertising | Low yield; Greek market CPMs ~€0.50–1.50 | Volume required is very high |
| Premium school profiles (B2B, paid by schools) | Moderate; private schools have marketing budgets | Requires sales effort |
| Lead gen for tutoring/services | Moderate; attach to searches for adjacent services | Requires partner network |
| Subscription for parents | Low; parents expect free info | Conversion will be poor |
| Licensing data to real estate, relocation agencies | Moderate; good B2B angle | Small number of potential buyers |
| EdTech marketplace (books, tutoring, supplies) | Speculative but interesting | Requires significant scope expansion |

The clearest early path is **premium profiles sold to private schools** — private schools (approximately 2,000–3,000 in Greece) pay for visibility in competitive parent markets. This is a proven model (e.g., PrivateSchoolReview.com in the US).

### 6. Execution Complexity — 7/10 (favorable)

For a solo web developer, this is well-scoped:
- Dataset already exists (scraped, ~14,000 records)
- Technology is standard: a searchable, filterable directory with a map view
- No hard real-time data requirements
- No complex backend logic initially (CRUD + search + maps)

The ratings/reviews feature adds social complexity later (moderation, fake reviews, legal exposure in Greece regarding defamation of institutions), but this can be deferred.

**Tech recommendation:** Astro + Neon (Postgres) + Algolia or Meilisearch for search. Map view via Mapbox or Google Maps API. SEO-first architecture is critical for this type of directory.

### 7. Traction Potential — 6/10

SEO is the primary organic growth channel. Queries like "σχολεία [city]" (schools in [city]) or "ιδιωτικά σχολεία Αθήνα" (private schools Athens) have real search volume. A well-structured directory with individual pages per school can capture long-tail SEO traffic rapidly.

Social proof (parent ratings) creates a flywheel if the community adopts it — but Greek internet users are not heavy review contributors (compared to, say, the US or UK), which slows this loop.

**Timeline to meaningful traffic:** 6–18 months with disciplined SEO.

### 8. Legal and Data Risks — 4/10 (caution)

This is an under-appreciated risk area:

- **GDPR (EU):** School contact data includes email addresses and phone numbers for staff. Scraping and publishing this data without consent may conflict with GDPR Articles 6 and 14 (right to be informed). The Ministry's data being public does not automatically grant republication rights under GDPR for personal data elements.
- **Ratings of institutions:** Under Greek law, publishing false or misleading reviews of schools could expose the platform to legal complaints. Defamation law applies to legal persons (institutions) in Greece.
- **Copyright on dataset:** The Ministry of Education's data is public, but the specific format/compilation may have database right protections under EU Directive 96/9/EC.

**Recommendation:** Consult a Greek data privacy lawyer before launch. Strip personal contact data (teacher names, personal emails) from public-facing pages. Show only institutional contacts.

### 9. Strategic Upside — 6/10

The directory, if it achieves market leadership in Greece, becomes a defensible data asset:
- B2B licensing to relocation companies, real estate portals
- Expansion to a broader Greek education marketplace (tutors, after-school activities)
- Potential acquisition target for a Greek media group or edtech company
- Template exportable to other small European markets (Cyprus, Malta, similar-sized nations)

The ceiling is modest in absolute terms but the asset value relative to effort is reasonable.

### 10. Urgency / Timing — 7/10

No urgent competitor threat is visible. The gap has existed for years and no one has filled it well. This argues the market timing is permissive (no need to rush), but also that revenue may be slow to materialize (the gap has persisted because monetization is hard). The founder's dataset gives a time-to-launch advantage that is real but not permanent.

---

## Key Risks

1. **Monetization is unclear** — The idea is easy to build but hard to make profitable at meaningful scale for a Greek market.
2. **GDPR exposure** — Personal data in the dataset needs legal review before publishing.
3. **Government portal risk** — Ministry of Education improving its UX would undercut the core value proposition (low probability, worth monitoring).
4. **SEO timeline** — 6–18 months to meaningful organic traffic requires patience and sustained effort from a solo founder.
5. **Review integrity** — Parent ratings, if implemented naively, will attract fake reviews and require moderation resources.

---

## Recommendations

**Build it, but with tight constraints:**

1. **Launch an MVP in 4–6 weeks** — Basic directory, search by city/type, individual school pages, map view. No ratings yet.
2. **Prioritize SEO from day one** — Individual URL per school, structured data markup (Schema.org/School), Greek-language meta tags.
3. **Validate private school premium profiles early** — Contact 10 private schools in Athens to test willingness to pay €50–200/year for enhanced profiles. If 3/10 say yes, the B2B model is viable.
4. **Get legal clarity on GDPR before launch** — Specifically on republishing Ministry contact data. This is a 1–2 hour consultation, not a major blocker.
5. **Defer ratings until you have traffic** — Reviews without volume look empty and damage credibility. Wait until you have 1,000+ MAU before enabling reviews.

---

## Comparable Businesses

- **PrivateSchoolReview.com** (US) — Monetizes via premium school profiles; similar model
- **Ofsted/ISI school finders** (UK) — Government-operated but shows the UX gap private players can fill
- **SchoolMyKids.com** (India) — Good analog: directory + ratings in an underserved market, monetizes via school advertising
- **Zocdoc** (US, doctors) — Classic "government data + bad UX" → "clean directory + reviews" playbook

---

## Final Verdict

**BUILD** — This is a real problem, the founder has unusual advantages (dataset + domain knowledge + technical skills), and the MVP is low-complexity. The primary concern is monetization ceiling in a small market. Go lean, validate the B2B premium profile model early, and treat this as a 12-month project with defined revenue milestones. If it doesn't hit €500/month in revenue by month 12, reassess before investing further.

| Dimension | Score |
|-----------|-------|
| Problem Clarity | 9/10 |
| Market Size | 5/10 |
| Founder-Market Fit | 9/10 |
| Competitive Landscape | 6/10 |
| Business Model Viability | 5/10 |
| Execution Complexity | 7/10 |
| Traction Potential | 6/10 |
| Legal/Data Risks | 4/10 |
| Strategic Upside | 6/10 |
| Urgency/Timing | 7/10 |
| **Total** | **64/100** |
