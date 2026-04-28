# Scoring Criteria Reference

## Scoring Methodology: v1.0
## Effective: 2026-03-01

13 weighted criteria for evaluating business ideas across all model types (directory, e-commerce, SaaS, marketplace, content). Each criterion is scored 1-5 using the rubrics below. The weighted total determines the verdict.

**Note:** These are the baseline (directory) weights. For non-directory models, see `references/lenses/{model}.md` for weight overrides that shift emphasis based on what matters most for that business type.

## Verdict Thresholds

| Verdict | Weighted Score | Action |
|---------|---------------|--------|
| **KILL** | < 40% (< 2.0 weighted avg) | Don't pursue — fundamental flaws |
| **PIVOT** | 40-55% (2.0-2.75) | Reframe the idea — promising elements exist |
| **BUILD** | 55-75% (2.75-3.75) | Solid opportunity — proceed with confidence |
| **BET** | > 75% (> 3.75) | High conviction — move fast |

---

## Criterion 1: Market Demand (Weight: 12%)

**What it measures:** Is there proven search demand and audience interest in this niche?

**Data sources:** `trends interest`, `suggest google`, `suggest expand`, `wiki views`

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No measurable demand | Google Trends shows flat/zero interest, fewer than 5 autocomplete suggestions, no Wikipedia article |
| 2 | Minimal niche demand | Some autocomplete suggestions but low variety, Google Trends below 20 baseline, Wikipedia article with <500 monthly views |
| 3 | Moderate proven demand | 10+ autocomplete variations, Google Trends score 30-60, Wikipedia views 1K-5K/month |
| 4 | Strong demand | 20+ autocomplete variations across multiple angles, rising Google Trends (50-80), Wikipedia views 5K-20K/month |
| 5 | Exceptional demand | 30+ autocomplete variations, Google Trends 80+ and rising, Wikipedia views >20K/month, multiple related trending queries |

---

## Criterion 2: Problem Severity (Weight: 10%)

**What it measures:** How painful is the problem this directory solves? Are people actively searching for solutions?

**Data sources:** `suggest google` (problem-oriented queries), `reddit search`, `search web` (forum complaints)

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No discernible pain | No problem-oriented searches ("best X", "find X", "X near me"), no forum complaints |
| 2 | Mild inconvenience | Some "best X" searches but low volume, occasional Reddit posts asking for recommendations |
| 3 | Moderate pain | Active Reddit threads asking for comparisons, "how to find" and "best X for Y" queries present |
| 4 | Significant pain | Multiple subreddits discussing the problem, comparison queries dominate autocomplete, users express frustration with current options |
| 5 | Severe, urgent pain | Dedicated subreddits for the problem, "X alternatives" and "X vs Y" queries abundant, users describing wasted time/money finding solutions |

---

## Criterion 3: Revenue Potential (Weight: 12%)

**What it measures:** Can this directory realistically generate revenue? What are the monetization paths?

**Data sources:** `search web` (competitor pricing pages), `appstores google` (related paid apps), `suggest google` (commercial intent queries)

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No clear monetization | Free information space, no one charges for this data, no affiliate programs |
| 2 | Weak monetization | Minor affiliate commissions possible, very low willingness to pay, ad-only model |
| 3 | Moderate monetization | Some competitors charge ($10-50/mo), affiliate programs exist, featured listings viable |
| 4 | Strong monetization | Competitors charge $50-200/mo, multiple revenue streams (subscriptions, affiliates, leads), B2B angle present |
| 5 | Exceptional monetization | High-value B2B market, competitors charge $200+/mo, lead generation with high LTV, enterprise willingness to pay |

---

## Criterion 4: Competitor Revenue Validation (Weight: 7%)

**What it measures:** Are existing competitors making money? Revenue validation from real businesses.

**Data sources:** `competitors wayback` (longevity = revenue), `competitors shopify` (e-commerce presence), `search web` (competitor revenue data), `appstores google/apple`

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No competitors generating revenue | No existing directories/listings in this space, no paid products |
| 2 | Minimal validation | 1-2 small competitors, unclear revenue, sites look abandoned or side projects |
| 3 | Some validation | 3-5 competitors, some with Wayback history >2 years, at least one with pricing page |
| 4 | Strong validation | Multiple funded competitors, clear pricing pages, Wayback shows 5+ years of operation, some with Shopify/payment integration |
| 5 | Proven market | Competitors with visible revenue (funding announcements, job postings, scale indicators), multiple businesses sustaining >5 years |

---

## Criterion 5: Competition Gap (Weight: 6%)

**What it measures:** Is there a meaningful gap in the existing competitive landscape? Can you differentiate?

**Data sources:** `search web` (existing directories), `competitors sitemap` (content depth), `competitors schema` (structured data quality)

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | Saturated, no gap | 5+ well-funded, well-maintained directories with comprehensive coverage and modern UX |
| 2 | Small gaps only | Strong incumbents with minor UX or data freshness issues, hard to meaningfully differentiate |
| 3 | Moderate gap | Existing directories are outdated, missing key features (filters, comparisons), or have poor UX |
| 4 | Significant gap | No dominant player, existing solutions are fragmented, major feature gaps (no API, no structured data, poor search) |
| 5 | Wide open | No dedicated directory exists despite clear demand, only scattered blog posts or generic lists |

---

## Criterion 6: Why Now / Timing (Weight: 8%)

**What it measures:** Is there a reason this opportunity is ripe right now? Regulatory changes, technology shifts, market events?

**Data sources:** `news google`, `news hn`, `trends rising`, `search web` (industry news)

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No timing advantage | Stable market with no recent changes, this could have been built 5 years ago with same outcome |
| 2 | Minor tailwinds | Some industry growth but no specific catalyst, gradual market expansion |
| 3 | Moderate timing | New technology or regulation creating fresh demand, emerging category with growing coverage |
| 4 | Strong timing | Recent regulatory change (new law, standard), technology breakthrough, major industry shift in last 12 months |
| 5 | Perfect timing | Breaking industry disruption, new regulation with compliance deadline, explosive category growth (2x+ YoY), major news coverage |

---

## Criterion 7: Automation & AI Leverage (Weight: 8%)

**What it measures:** How much of the business can be automated, and specifically how much does AI amplify a solo founder's capabilities? In the AI era, a single person with AI tools can do work that previously required a team — this criterion measures how strongly that applies to this idea.

**Data sources:** `github_search repos` (scrapers, APIs), `search web` (API documentation), assessment of data structure, assessment of AI applicability

**AI Leverage dimensions to evaluate:**
- Content generation: Can AI write descriptions, blog posts, listings at scale?
- Customer service: Can AI handle support via chatbot, email automation?
- Data processing: Can AI categorize, enrich, deduplicate data?
- Operations: Can AI automate monitoring, scraping, updates?
- Marketing: Can AI generate social posts, ads, email campaigns?
- Development: Can AI help build/maintain the product faster?

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | Fully manual, AI adds little | Core value requires human expert judgment that AI can't replicate (e.g., fine art appraisal, medical diagnosis) |
| 2 | Mostly manual, AI assists | AI can draft content or automate some data tasks, but human expertise is the primary value driver |
| 3 | Mixed — AI handles 50% | AI generates content, processes data, handles routine support; human needed for curation, strategy, quality control |
| 4 | AI-first — solo founder viable | AI handles content at scale, customer support, data pipeline, and marketing. One person + AI can operate what previously needed 3-5 people. |
| 5 | AI-native — massive leverage | The business IS an AI application. AI does 90%+ of the work. Solo founder orchestrates AI agents for content, data, support, and growth. Competitors without AI need 10x the team. |

---

## Criterion 8: Distribution Opportunity (Weight: 8%)

**What it measures:** Can you acquire users through organic channels — SEO, social, communities?

**Data sources:** `suggest google` (keyword demand), `reddit stats`, `youtube search`, `social presence`, `social instagram`, `social tiktok`

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No organic channels | No search demand for individual listings, no relevant subreddits or communities, no social presence |
| 2 | Weak distribution | A few keywords with low volume, small subreddits (<10K), minimal YouTube coverage |
| 3 | Moderate distribution | 10+ rankable keywords, relevant subreddit with 10K-50K subscribers, some YouTube content |
| 4 | Strong distribution | 50+ long-tail keywords, active subreddit(s) with 50K+ subscribers, YouTube creators covering the space, Instagram/TikTok hashtags with engagement |
| 5 | Exceptional distribution | Hundreds of long-tail keywords (each listing = SEO page), large subreddits (100K+), active YouTube/TikTok community, viral content potential |

---

## Criterion 9: Defensibility & AI Disruption Risk (Weight: 8%)

**What it measures:** Can you build lasting competitive advantage — through data moats, community, brand, network effects, platform/cluster moats, or multi-channel distribution? AND how does AI affect the competitive landscape?

**Data sources:** Assessment based on all research data (not a single CLI tool)

**Five defensibility types to evaluate:**

**Type A — Data Moat:** Longitudinal data that cannot be reconstructed retroactively (price history, time-to-sell curves, neighborhood scoring built over months). First-mover in data collection creates a permanent gap.

**Type B — Community/Network Effects:** User-contributed data (reviews, ratings, listings) creates a moat that AI can enrich further. Network effects make the product more valuable with each user.

**Type C — Brand/SEO Moat:** Being first in a niche creates domain authority that takes years to replicate. A cluster of cross-linked sites compounds SEO authority across the entire family.

**Type D — Platform/Cluster Moat (Operational Moat):** A founder who has already built the rapid-deployment infrastructure stack (monorepo, shared data pipelines, shared social automation, Telegram bot templates, MCP server templates) can spin up new products in days — not months. A competitor entering the same space starts from zero on each product. This moat scales with the number of products deployed: each new product strengthens the ad network, the cross-linking SEO graph, and the shared audience. Key signals: existing monorepo deployment, shared Telegram bot framework, shared social media automation pipeline, owned ad network across properties.

**Type E — Multi-Channel Distribution Moat:** Occupying web portal + Telegram bot + MCP plugin + API + browser extension simultaneously for a niche makes displacement disproportionately hard. A competitor must replicate every channel, not just the web product. The MCP plugin layer is especially defensible in 2025-2026: first-mover status in the Claude/ChatGPT ecosystem for a data niche creates durable distribution inside the AI assistant layer.

**AI Disruption Risk assessment:**
- Could AI commoditize the core value? (If your moat is "human curation" and AI can do 80%, your moat erodes)
- Does AI give you COST advantage? (Solo founder + AI vs competitor's 10-person team = lower prices possible)
- Does the business COMPOUND with AI? (More data → better AI → better product → more data = flywheel)
- Can competitors easily replicate with AI too? (If yes, AI is not YOUR moat — it's everyone's)

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No defensibility + AI commoditizes | Commodity data/content anyone can replicate with AI, no network effects, no cluster moat |
| 2 | Weak defensibility + AI neutral | Some first-mover advantage but data is easily copied; no cluster, no multi-channel presence |
| 3 | Moderate defensibility + AI helps cost | Proprietary data enrichment possible; OR platform moat present (existing monorepo stack reduces new-product cost); AI gives cost/speed advantage over manual competitors |
| 4 | Strong defensibility + AI amplifies moat | Longitudinal data moat forming; OR multi-channel distribution (web + bot + MCP) deployed; OR cluster of 3+ cross-linked products creating shared SEO authority and owned ad network |
| 5 | Exceptional defensibility + AI flywheel | Type D + Type E combined: existing deployment infrastructure enables rapid product family expansion; MCP ecosystem presence for the niche; longitudinal proprietary dataset; owned ad network across cluster; AI compounds value with usage. Solo founder + this stack can outperform a funded single-product team. |

**AI Industry Disruption Signal (bonus for scoring):** When evaluating Competition Gap (Criterion 5) and Revenue Potential (Criterion 3), specifically look for industries where:
- Incumbents rely on expensive human labor (consultants, researchers, curators, support staff)
- That labor CAN NOW be partially or fully automated by AI
- The incumbent's pricing reflects human labor costs (high margins but also high expenses)
- A solo founder with AI could offer 50-80% of the quality at 10-20% of the price
- Examples: Legal research (traditionally $500/hr lawyers, now AI-assisted), real estate appraisal, financial advisory, content agencies, translation services, customer support centers, data entry, market research firms

When this signal is strong, it should boost Competition Gap (the gap IS the AI disruption opportunity) and Revenue Potential (you can price competitively while maintaining high margins because your costs are near-zero).

---

## Criterion 10: Data Availability (Weight: 2%)

**What it measures:** Is the core data for this idea accessible and of sufficient quality? AND does this dataset have portfolio potential — can the same data power multiple distinct products?

**Data sources:** `github_search repos`, `github_search datasets`, `search web` (APIs, open data)

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No accessible data | Data locked behind enterprise paywalls, no APIs, no scrapable sources, requires original research |
| 2 | Scarce data | Limited APIs with tight rate limits, scattered across many sites, poor quality or inconsistent formats |
| 3 | Adequate data | Some public APIs, websites with scrapable structured data, but gaps in coverage or freshness |
| 4 | Good data | Multiple data sources (APIs, GitHub datasets, scrapable sites), structured formats, reasonable update frequency |
| 5 | Excellent data | Public APIs with comprehensive coverage, open datasets on GitHub, multiple redundant sources, real-time or daily updates |

### Data Repurposing Bonus (+0.5 to final score, capped at 5.0)

After scoring data availability 1–5, assess **derivative product potential**: how many meaningfully different products could be built from the same core dataset without re-collecting data?

**Ask:** If you had this dataset fully built, what else could you launch — and is there independent evidence that someone wants each derivative product?

Each derivative product must meet ALL three criteria to count:
1. **Different buyer or use-case** — not just a repackaging of the same product for the same audience
2. **Independent demand signal** — at least one of: (a) a competitor already building it, (b) measurable search volume for this derivative use-case, (c) a distinct B2B customer class willing to pay for it, or (d) the derivative has its own revenue model separate from the primary product
3. **Same dataset, no re-collection** — the derivative uses the existing data without requiring a fundamentally different data acquisition effort

| Bonus | Condition |
|-------|-----------|
| +0.0 | 0–1 validated derivative product, OR derivatives are all same audience/use-case |
| +0.25 | 2 validated derivatives with independent demand signals |
| +0.5 | 3+ validated derivatives, each with independent demand signals |

**Good examples (pass all 3 criteria):**
- Car database → (1) used car marketplace [buyers exist, AutoTrader proves it] + (2) insurance comparison [different buyer: insurers, independent search volume] + (3) automotive quiz game [different use-case, Sporcle/Trivial Pursuit proves entertainment demand] = +0.5
- Greek schools data → (1) school comparison tool [parents, eduadvisor.gr proves it] + (2) tutoring marketplace [different buyer: tutors/students, Tutor.com proves model] = +0.25 (only 2 validated)

**Inflated examples (fail — don't award the bonus):**
- "Salary data could power a calculator, a tax tool, AND a cost-of-living index" — all three serve the same user (employee checking their pay) with no independent revenue model; this is one product with multiple features, not 3 derivatives. Award +0.0.
- "School data could power a blog AND a newsletter AND a podcast" — same audience (parents), same content repurposed, no independent monetization. Award +0.0.

**Why this tightening matters:** The bonus is meant to reward genuine platform optionality — data that creates multiple independent business lines. Conceivable derivative uses are not the same as validated derivative products. Default to +0.0 when in doubt; the critic can upgrade if the evidence is strong.

**Note for scoring agent:** For each derivative you count, explicitly state: (1) who the buyer is, (2) what the independent demand signal is, (3) how the revenue model differs from the primary product.

---

## Criterion 11: Founder-Team Fit (Weight: 10%)

**What it measures:** Does the founder have the domain expertise, technical ability, and unfair insight needed to win in this specific space? This is the highest-weighted criterion in the Angel Investor Scorecard (30%) and top-3 for YC. A weak team kills strong ideas; a strong team can pivot through weak ideas.

**Data sources:** ASK THE USER — this criterion cannot be scored by automated research. Ask five targeted questions:
1. "What's your connection to this niche?" (domain expertise)
2. "Can you build the MVP yourself, or do you have a technical co-founder?" (build ability)
3. "Have you shipped and launched a product before?" (execution track record)
4. "What do you know about this market that most people don't?" (unfair insight — YC's most important question)
5. "Do you have existing infrastructure, tech stack, or audience that gives you a launch advantage?" (operational moat — e.g., existing monorepo with shared deployment, Telegram bot templates, social media automation pipeline, newsletter audience, MCP server pattern already built). A "yes" here lifts both C11 and C12.

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | No connection, no ability to build, purely opportunistic | Never used products in this space; no technical skills; no prior launches |
| 2 | Casual familiarity; needs to hire for most execution | Some awareness; can learn to build but not fluent; no relevant launches |
| 3 | Active user who can build; has shipped something before | Regular user; can code or has low-code skills; launched at least 1 project |
| 4 | Domain expert who can build; proven execution; meaningful insight | Professional experience in the industry; shipped products users paid for; knows 1-2 non-obvious truths about the market |
| 5 | Insider with unique access + technical ability + track record + unfair insight | Industry insider with unique data/network/audience; strong technical builder; multiple successful launches; knows something competitors don't |

---

## Criterion 12: MVP Speed (Weight: 3%)

**What it measures:** How quickly can a functional MVP be built and launched?

**Data sources:** Assessment based on automation potential, data availability, and directory complexity

**Infrastructure Boost (applies when founder already has a deployment stack):** If the founder has an existing monorepo/deployment infrastructure (e.g., Astro + Nx + Neon stack, shared component library, existing scraper framework), add +1 to the base score — capped at 5. A new directory that would normally take 3-6 weeks becomes 1-3 weeks when the infrastructure already exists. Ask the founder: "Do you have an existing tech stack you can reuse for this?"

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | 3+ months | Complex data model, multiple integrations required, custom scraping infrastructure needed from scratch |
| 2 | 6-12 weeks | Moderate complexity, some custom development, 2-3 data sources to integrate |
| 3 | 3-6 weeks | Standard directory structure, available templates, 1-2 APIs to connect |
| 4 | 1-3 weeks | Simple data model, existing scraper/API available, can use directory starter templates |
| 5 | Under 1 week | Flat data structure, single API source, can launch with static site generator + CSV; OR any model where the founder has existing infrastructure that reduces build time to under 1 week |

---

## Criterion 13: Early Validation Signal (Weight: 6%)

**What it measures:** Has anyone outside the founder shown real interest — through actions, not words? Early validation separates ideas that feel good from ideas people actually want. This is the traction signal that YC, Techstars, and every serious investor evaluate first.

**Data sources:** ASK THE USER — this criterion cannot be scored by automated research. Ask:
> "Before we wrap up — any early validation signals? For example: a landing page with signups, people you've talked to who said they'd pay, a waiting list, early users, or even just strong reactions when you described the idea?"

Also look for signals in the research: competitor funding (proves the market), ProductHunt launches with high votes (proves community interest), job postings from funded competitors (proves companies are spending money).

| Score | Description | Evidence Example |
|-------|-------------|-----------------|
| 1 | Idea only exists in founder's head; no external feedback sought | Not talked to potential users; no landing page; no signals |
| 2 | Founder has researched and believes in the opportunity | Read articles, analyzed competitors, convinced themselves — but no external validation |
| 3 | Informal validation: positive reactions, interest expressed, 5-20 people engaged | Mentioned idea at a meetup and 10 people asked for updates; 15 newsletter signups from a tweet; 3 friends said "I'd pay for that" |
| 4 | Structured validation: 50+ waitlist signups, OR beta users giving feedback, OR 1 paying customer | Landing page with 75 signups; 5 beta users who actively use an early version; 1 customer paid $50 for early access |
| 5 | Strong validation: 200+ waitlist, multiple paying customers, LOIs from B2B buyers, or measurable usage data | 300 waitlist emails; 3 companies signed LOIs; 50 beta users with >70% weekly retention; already generating revenue |

**Per-model adaptation note:** Validation looks different by model type — see the lens file for model-specific examples. A directory can validate via SEO traffic to a pre-launch page; a SaaS validates via paid pilot; a marketplace validates via supply-side commitments.

---

## Weight Summary

| # | Criterion | Weight | Scored By |
|---|-----------|--------|-----------|
| 1 | Market Demand | 12% | Research Agent |
| 2 | Problem Severity | 10% | Research Agent |
| 3 | Revenue Potential | 12% | Research Agent |
| 4 | Competitor Revenue Validation | 7% | Research Agent |
| 5 | Competition Gap | 6% | Research Agent |
| 6 | Why Now / Timing | 8% | Research Agent |
| 7 | Automation & AI Leverage | 8% | Research Agent |
| 8 | Distribution Opportunity | 8% | Research Agent |
| 9 | Defensibility | 8% | Scoring Agent (synthesis) |
| 10 | Data / Resource Availability | 2% | Research Agent |
| 10b | Data Repurposing Bonus | +0/+0.25/+0.5 | Research Agent |
| 11 | Founder-Team Fit | 10% | User (asked directly) |
| 12 | MVP Speed | 3% | Scoring Agent (synthesis) |
| 13 | Early Validation Signal | 6% | User (asked directly) + Research signals |
| | **Total** | **100% + bonus** | |

## Weighted Score Calculation

```
weighted_score = (
    score_1  * 0.12 +   # Market Demand
    score_2  * 0.10 +   # Problem Severity
    score_3  * 0.12 +   # Revenue Potential
    score_4  * 0.07 +   # Competitor Revenue Validation
    score_5  * 0.06 +   # Competition Gap
    score_6  * 0.08 +   # Why Now / Timing
    score_7  * 0.08 +   # Automation & AI Leverage
    score_8  * 0.08 +   # Distribution Opportunity
    score_9  * 0.08 +   # Defensibility
    score_10 * 0.02 +   # Data / Resource Availability
    score_11 * 0.10 +   # Founder-Team Fit
    score_12 * 0.03 +   # MVP Speed
    score_13 * 0.06     # Early Validation Signal
)
data_repurposing_bonus = 0.0 | 0.25 | 0.5
raw_score = weighted_score + data_repurposing_bonus
final_score = min(raw_score, 5.0)
percentage = (final_score / 5.0) * 100
```

Example: If all scores are 3 with a +0.5 repurposing bonus → raw_score = 3.5, percentage = 70% = BUILD.

**The bonus is small but meaningful:** It separates two identical-looking ideas where one has a dataset with portfolio potential. A +0.5 bonus can shift a PIVOT (53%) to BUILD (58%), which is the correct signal — the data asset IS more valuable.
