---
idea: "Greek Schools Directory"
slug: "greek-schools-directory"
model: "directory"
verdict: "BUILD"
score: 65.2
weighted_avg: 3.26
evaluated: 2026-03-26
scoring_methodology: "v1.0"
evaluation_version: v2
cli_status: "unavailable - estimated"
---

# Greek Schools Directory

**Verdict: BUILD** | **Score: 65.2%** | **Evaluated: 2026-03-26**

## Idea Summary

A comprehensive directory of all 14,000+ public and private primary and secondary schools in Greece, listing location, type (public/private), contact details, and eventually parent ratings. Greece has no good central school directory — the Ministry of Education's own system is administrative and not consumer-facing. The founder is Greek, a web developer who personally experienced the pain, and has already scraped the complete 14,000-school dataset from the Ministry of Education website.

## Scorecard

| # | Criterion | Weight | Score | Evidence |
|---|-----------|--------|-------|----------|
| 1 | Market Demand | 12% | 3/5 | edu4schools.gr draws 265K monthly visits proving demand exists; Wikipedia "Education_in_Greece" has daily views; strong Google autocomplete for "ιδιωτικά σχολεία αθήνα" — BUT Greece's 10.4M population creates a ceiling on total addressable market (CLI unavailable - estimated) |
| 2 | Problem Severity | 10% | 3/5 | Private school fees €6K-€18K/year make this a high-stakes decision; €1.8-2.2B annual private tutoring market shows parent investment intensity; founder personally frustrated by absence of a good directory; expats specifically struggle finding schools outside Athens (CLI unavailable - estimated) |
| 3 | Revenue Potential | 12% | 2/5 | Only ~300 private/international schools as potential premium listing buyers; edu4schools.gr earns ~$11K/year from display ads alone; no Greek-specific school platform has demonstrated meaningful revenue; Niche.com model works at US scale but Greece cannot replicate that scale (CLI unavailable - estimated) |
| 4 | Competitor Revenue Validation | 10% | 2/5 | No Greek-specific competitor demonstrates meaningful revenue; edu4schools.gr is minimal ($11K/year); international models (Niche.com: $35M raised, 70M users) prove model at scale Greece cannot match; no funding announcements or scale signals from Greek education directory operators (CLI unavailable - estimated) |
| 5 | Competition Gap | 8% | 4/5 | No dedicated Greek school comparison platform with ratings/reviews exists; edu4schools.gr is basic and informational only — no comparison or review features; international-schools-database.com covers only 23 international schools in Greece; MySchool (gov) is administrative-only; parents rely on word-of-mouth and Facebook groups (CLI unavailable - estimated) |
| 6 | Why Now / Timing | 8% | 3/5 | Golden Visa applications: 9,289 in 2024 (+9.6% YoY), US now >50% of applicants creating English-speaking family demand; Digital Nomad Visa includes family; 750+ school closures force parents to compare alternatives — BUT these are gradual trends, not explosive catalysts (CLI unavailable - estimated) |
| 7 | Automation Potential | 8% | 4/5 | Founder has already scraped 14,000-school dataset from Ministry of Education — data pipeline is solved; AI can generate school descriptions at scale, automate map data enrichment, and process updates; fee/review data still needs manual/community collection but core infrastructure is automated (CLI unavailable - estimated) |
| 8 | Distribution Opportunity | 8% | 3/5 | r/greece (270K subscribers), expat Facebook groups, Golden Visa consultant referral networks; strong bilingual SEO opportunity ("ιδιωτικά σχολεία αθήνα", "international schools Athens"); no dedicated school-search subreddit or high-volume YouTube channel (CLI unavailable - estimated) |
| 9 | Defensibility | 8% | 3/5 | Pre-built 14,000-school dataset enables first-mover launch; Greek-language content provides barrier vs international platforms; UGC review accumulation creates moat over time — BUT government could release consumer-facing portal; international-schools-database.com could expand Greek coverage (CLI unavailable - estimated) |
| 10 | Data Availability | 5% | 5/5 | Founder ALREADY HAS complete 14,000-school dataset scraped from Ministry of Education website — this is not a future data need, it is fully resolved; structured, comprehensive, single authoritative source covering all public and private primary and secondary schools in Greece |
| 11 | Founder-Market Fit | 6% | 5/5 | Greek national + personally frustrated parent (direct user with lived pain) + web developer (can build independently) + already scraped 14,000-school dataset (unique data access). Meets "insider with edge" criterion: domain expertise, personal pain, technical capability, AND proprietary head start all present |
| 12 | MVP Speed | 5% | 5/5 | Web developer + complete 14,000-school CSV dataset already in hand + directory starter template = launch in under 1 week. Flat data structure (school name, type, location, contact) maps directly to a static site generator + CSV. No data acquisition needed before launch. |

**Weighted Score: 3.26/5.0 (65.2%)**

### Score Calculation

```
(3 × 0.12) + (3 × 0.10) + (2 × 0.12) + (2 × 0.10) + (4 × 0.08) + (3 × 0.08) +
(4 × 0.08) + (3 × 0.08) + (3 × 0.08) + (5 × 0.05) + (5 × 0.06) + (5 × 0.05)

= 0.36 + 0.30 + 0.24 + 0.20 + 0.32 + 0.24 + 0.32 + 0.24 + 0.24 + 0.25 + 0.30 + 0.25
= 3.26
= 65.2%
```

## Competitor Landscape

| # | Competitor | Domain | Tranco Rank | Domain Age | Est. Pages | Revenue Signal | Key Differentiator |
|---|-----------|--------|-------------|------------|-----------|---------------|-------------------|
| 1 | Edu4Schools | edu4schools.gr | ~500K est. | ~8yr | ~15K | $11K/year display ads | Comprehensive listing, Greek-language, info-only |
| 2 | International Schools DB | international-schools-database.com | ~800K est. | ~10yr | ~5K | Subscription (B2B) | International schools globally, only 23 in Greece |
| 3 | MySchool (Gov) | myschool.minedu.gov.gr | Gov domain | ~10yr | ~50K | None (public service) | Official school registry, administrative use only |
| 4 | GreatSchools (US) | greatschools.org | Top 50K | ~24yr | ~1M+ | Data licensing + grants | Ratings, reviews, SEO at massive scale — US only |
| 5 | Niche.com (US) | niche.com | Top 20K | ~12yr | ~5M+ | $35M raised, 1000+ paying schools | Full comparison + reviews + rankings — US only |

*Note: Tranco ranks and domain ages are estimated from available context; CLI tools unavailable for verified metrics.*

### Feature Gap Matrix

| Feature | Us (planned) | edu4schools.gr | international-schools-db | MySchool (Gov) |
|---------|-------------|----------------|--------------------------|----------------|
| Complete school list (all 14,000) | Yes | Partial | No (23 only) | Yes (admin) |
| Consumer-facing search | Yes | Basic | Yes | No |
| Parent ratings/reviews | Yes | No | No | No |
| School comparison tool | Yes | No | No | No |
| Fee transparency | Planned | No | No | No |
| Map view | Yes | No | Partial | No |
| Mobile-friendly | Yes | Partial | Yes | No |
| Bilingual (GR + EN) | Yes | Greek only | English only | Greek only |

## Business Foundation (feeds → Business Documentation Framework)

### Top 3 Problems (→ IDEA-04, IDEA-09 box 1)

1. **No central comparison resource** — Parents choosing between private schools in Athens have no structured way to compare options. Word-of-mouth and scattered Facebook groups are the current solution. Evidence: edu4schools.gr is informational only; no rating/review platform exists in Greece.

2. **Expat families navigating Greek education blind** — The 9,289 Golden Visa applicants in 2024 (>50% US-based) and Digital Nomad Visa holders with families have no English-language school finder for Greece. Evidence: international-schools-database.com covers only 23 Greek schools; no expat-specific Greek school directory exists.

3. **High-stakes decision with no information infrastructure** — Private school fees range €6K-€18K/year. Parents commit to these costs without access to peer reviews, comparison data, or fee transparency. Evidence: €1.8-2.2B annual private tutoring market signals extreme parental investment culture.

**Existing alternatives:** Word-of-mouth among parent networks, scattered Facebook groups, edu4schools.gr (informational only), Google search for individual school websites.

### Primary Customer Profile (→ IDEA-02 JTBD, IDEA-09 box 2)

- **Who:** Greek parents considering private schools for their children; expat families (Golden Visa holders, digital nomads) relocating to Greece with school-age children
- **Where:** Athens and Thessaloniki (primary); secondary cities with private school presence
- **When:** School enrollment season (January-May), upon relocation to Greece, when current school closes due to enrollment drops
- **Early adopters:** Expat families — highest motivation (navigating unfamiliar system), highest willingness to pay, and English-language content serves an underserved segment with no Greek-language barrier requirement

### Channels (→ IDEA-09 box 5)

| Channel | Opportunity | Evidence |
|---------|------------|----------|
| Programmatic SEO (Greek) | Strong | Each of 14,000 schools = unique SEO page; "ιδιωτικά σχολεία [city]" pattern shows clear intent |
| Programmatic SEO (English) | Strong | "international schools Athens", "private schools Greece" — expat audience underserved |
| Expat community distribution | Moderate | r/greece (270K subscribers), expat Facebook groups, Golden Visa consultant network |
| Referral partnerships | Moderate | Golden Visa consultants, relocation agencies actively place families and need school resources |
| Direct school outreach | Moderate | Schools themselves have incentive to claim/update their listings (free marketing) |

### Revenue Model (→ IDEA-09 box 6)

- **Primary model:** Display advertising (near-term) + premium/featured listings for private schools (medium-term)
- **Competitor benchmark:** edu4schools.gr earns ~$11K/year from ads alone on 265K monthly visits; Niche.com charges schools for premium placement and enrollment inquiry leads
- **Realistic Greek ceiling:** ~300 private/international schools × €50-100/month premium listing = €15K-€30K/year theoretical max; display ads from 100K monthly visits at €2-5 RPM = €2.4-6K/year
- **Adjacent revenue:** Tutoring referrals (affiliate), school supply affiliate links, expat relocation services referrals

### Unfair Advantage (→ IDEA-09 box 9)

- **Data moat:** 14,000-school dataset already scraped and in hand — competitors start from zero. First-mover to launch with complete coverage creates a compounding SEO and data advantage.
- **Founder edge:** Greek national with personal pain + web dev background + existing dataset. Can build, launch, and iterate without external dependencies.
- **Defensibility path:** Each parent review added is data no competitor has. Greek-language content authority from being first and most comprehensive.

### AI Leverage Assessment (→ IDEA-09 Unfair Advantage, Criterion 7)

| AI Application | Replaces | Impact |
|---------------|----------|--------|
| School description generation | Manual content writing for 14,000 schools | Generate structured descriptions from available data fields at scale in hours |
| Map data enrichment | Manual geocoding/address lookup | AI-assisted geocoding + Google Maps API = location data for all schools automatically |
| Review moderation | Human content moderator | AI flags inappropriate content, reducing moderation overhead to spot-checks |
| Bilingual content | Professional translation | AI generates English descriptions from Greek data fields, serving expat audience at zero marginal cost |
| SEO page optimization | SEO consultant | AI generates meta titles, descriptions, and structured data markup for all 14,000 pages |

**AI Disruption Signal:** Not strong in this vertical — incumbents (edu4schools.gr) do not rely on expensive human labor as their core value. AI is primarily a cost-reduction and speed advantage for the founder, not a disruption opportunity against incumbents.

**Solo Founder Viability:** Solo founder + AI + existing dataset = equivalent of a 3-person team. Fully viable for MVP and initial growth phase.

### Success Metrics (→ IDEA-09 box 8)

| Metric | Target (30 days) | Target (90 days) | How to Measure |
|--------|-----------------|-----------------|----------------|
| Monthly organic visits | 1,000 | 10,000 | Google Search Console |
| School pages indexed | 5,000 | 14,000 | Google Search Console |
| Parent reviews submitted | 10 | 100 | Internal database |
| Private school inquiries (willingness to pay signal) | 5 conversations | 2 paying schools | CRM / outreach log |

## Strengths

1. **Complete dataset in hand — zero data acquisition cost** — Founder already has all 14,000 schools scraped from the Ministry of Education. This eliminates the biggest barrier to building a comprehensive directory: the data bootstrapping problem. Launch timeline is days, not months.

2. **Clear competition gap in a high-stakes decision space** — No Greek school comparison platform with ratings and reviews exists. Parents making €6K-€18K/year private school decisions have no information infrastructure. The closest competitor (edu4schools.gr) is informational only with no comparison or review functionality.

3. **Strong founder-market fit with three overlapping edges** — Greek national + personally frustrated parent + web developer + already has the data. All four conditions for a high-conviction founder are met simultaneously.

## Weaknesses

1. **Small addressable market structurally caps revenue** — Greece has only ~300 private/international schools as potential premium listing buyers. Even at aggressive pricing, the annual revenue ceiling is €15K-€30K from listings. This is a lifestyle business ceiling, not a venture-scale outcome.

2. **Unproven revenue model in Greek market** — No Greek-specific school platform has demonstrated meaningful monetization. The international precedents (Niche.com) required US-scale audiences that Greece cannot provide. Revenue validation requires active school outreach before committing to a premium listing model.

3. **Review cold-start problem** — The most defensible part of the product (parent ratings) requires a critical mass of contributions. Greek parents may not be habituated to leaving school reviews online. Building genuine review volume in a small market will take 12-24 months.

## Key Risks

1. **Government pre-emption** — Ministry of Education operates MySchool and has committed to open education data under Law 4305/2014. A government-backed consumer-facing school portal or Google Business Profile-style initiative could render the directory redundant.

2. **Revenue ceiling is lifestyle-business level** — With ~300 potential premium clients and a small Greek advertising market, the directory may plateau at €20K-40K/year. This is a viable side business but not a scalable company without significant product expansion.

3. **School legal pushback on negative reviews** — Greek defamation laws are more plaintiff-friendly than US laws. A private school receiving negative reviews could threaten legal action, creating content moderation complexity and potential liability.

## Blind Spots

- Actual quantified search volume (Google Keyword Planner) not available — autocomplete signals are directional but not volume-confirmed (CLI tools unavailable)
- Greek-language-only competitor landscape not fully explored (Facebook groups, Greek-only sites functioning as informal directories)
- School marketing budgets in Greece — how much do private schools actually spend on digital marketing currently?
- Whether Greek parents culturally use online reviews for school decisions vs. relying exclusively on personal networks
- Data freshness and accuracy of the already-scraped dataset — when was it scraped? Are all 14,000 records current and correct?
- Google Knowledge Graph entity recognition for Greek schools — does Google already structure this data in search results?

## Recommendation

This idea is solidly in BUILD territory at 65.2% — a meaningful jump from the v1 score of 57%. The primary driver of this improvement is the founder's dataset. Having 14,000 schools already scraped eliminates the biggest execution risk for a directory business: data bootstrapping. Combined with a web developer who personally feels the pain and understands the Greek market, the risk profile is exceptionally low for an initial launch.

The strategy should be ruthlessly simple: launch the basic directory first. Use the existing CSV to generate 14,000 school profile pages, launch with Astro or Next.js + a directory template, and measure organic traffic over 60 days. The programmatic SEO play alone — 14,000 unique pages indexed by Google — could drive meaningful traffic without any community building or review features.

The revenue constraint is real and should not be ignored. Greece's ~300 private schools are the only meaningful premium listing market. Before building any premium feature, validate that 20+ private schools would pay €50-100/month for enhanced profiles. If schools won't pay, pivot to an affiliate/content model targeting the €1.8-2.2B tutoring market: school-adjacent services (tutors, enrichment programs, school supplies) with affiliate commissions provide a larger revenue pool than direct school listings.

## Next Steps

1. **Launch immediately** — Use existing 14,000-school dataset with Astro + directory template. Deploy a basic school finder with search by city, type (public/private), and grade level. Target 2 weeks to launch. The data problem is already solved.

2. **Validate school willingness to pay** — Within 30 days of launch, contact 20 private schools using contact data from the dataset. Offer free enhanced profiles in exchange for a 15-minute call about their current marketing spend. This validates the premium listing model before building it.

3. **SEO-first growth** — Submit sitemap immediately after launch, add structured data markup (Schema.org/School) to all 14,000 pages, and monitor Google Search Console for indexed pages and impressions. First 90 days is purely SEO and validation, no paid acquisition.

## Research Sources

Raw research data archived at: `ideas/greek-schools-directory/research/v1/`

| Stage | File | Queries | Key Data Points |
|-------|------|---------|----------------|
| Market Research | market.md | CLI unavailable | edu4schools.gr 265K monthly visits, Wikipedia Education_in_Greece, Golden Visa 9,289 applications 2024 |
| Competition Research | competition.md | CLI unavailable | edu4schools.gr ~$11K/year, Niche.com $35M raised, MySchool gov system, international-schools-db 23 Greek schools |
| Data Research | data.md | CLI unavailable | Founder has 14,000-school Ministry of Education dataset, data.gov.gr open data portal |
| Distribution Research | distribution.md | CLI unavailable | r/greece 270K subscribers, bilingual SEO opportunities, Golden Visa consultant referrals |
| Competitor Deep-Dive | competitor-profiles.md | CLI unavailable | edu4schools.gr info-only, no rating platform, MySchool administrative-only |

**Note:** All CLI research tools were unavailable for this evaluation. Scores were estimated based on available context from the idea description, existing research from v1 evaluation (2026-03-22), and domain knowledge about the Greek education market. Evidence marked as "CLI unavailable - estimated" throughout.
