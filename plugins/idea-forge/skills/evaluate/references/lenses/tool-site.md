# Tool Site Lens — Scoring Rubrics

Business model: Free web utilities (calculators, converters, generators, formatters, analyzers) that solve a specific functional need. Users visit, use the tool, and leave — no accounts, no subscriptions needed. Revenue comes from the traffic the utility generates.

Revenue models: Display ads (primary — RPM-based), freemium upgrade (premium features/API), lead generation (related services), affiliate links (related products), white-label licensing, sponsored tools.

## Proven Examples

- **Omni Calculator** — 23M visits/month, ~$500K/month from AdSense (~$6M ARR)
- **Calculator.net** — 400M+ annual visits, estimated $5-10M+ annual ad revenue
- **TimeAndDate.com** — massive traffic, ad-supported time zone/calendar tools
- **TinyPNG** — free image compression, freemium API for developers
- **Coolors.co** — color palette generator, freemium ($3/month pro)
- **Remove.bg** — background remover, credit-based premium ($1.99/image)

## Weight Overrides

Tool sites share DNA with content businesses (SEO-driven, ad-monetized) but differ fundamentally: the value is in functional utility, not written content. Tools have higher engagement (users interact, not just read), higher RPMs (more time on page = more impressions), and dramatically lower maintenance costs (build once vs constant content refresh). The key risk is that simple tools are easy to clone — defensibility comes from UX polish, brand recognition, and compound SEO authority.

| # | Criterion | Weight | Change | Rationale |
|---|-----------|--------|--------|-----------|
| 1 | Market Demand | 12% | — | Search volume for tool queries matters equally |
| 2 | Problem Severity | 10% | — | Tool queries signal active intent ("I need to calculate X right now") |
| 3 | Revenue Potential | 12% | — | RPM $5-20 typical; higher engagement = more impressions per visit |
| 4 | Competitor Revenue | 6% | -4% | Tool sites are often side projects with unclear revenue |
| 5 | Competition Gap | 10% | +2% | UX quality gap is the primary opportunity (many bad tools exist) |
| 6 | Timing | 6% | -2% | Tools are evergreen — less timing-dependent |
| 7 | Automation → Build Complexity | 5% | -3% | Once built, nearly zero maintenance; question is initial build effort |
| 8 | Distribution | 14% | +6% | SEO is everything — each tool page is a high-intent keyword target |
| 9 | Defensibility | 10% | +2% | UX polish + brand + compound SEO + feature depth create moat |
| 10 | Data Availability → Input Data | 1% | -4% | You build the logic, not aggregate data (unless the tool needs external data feeds) |
| 11 | Founder-Team Fit | 8% | +2% | Domain expertise matters for accuracy and trust |
| 12 | MVP Speed | 2% | -3% | Simple tools fast (<1 week), complex tools (data-driven) take longer |
| 13 | Early Validation Signal | 4% | NEW | Tools launch fast; validation via traffic is post-launch |

## Key Benchmarks

- **RPM by niche**: Finance tools $15-30, health tools $8-15, developer tools $5-10, general utility $3-8
- **Ad network progression**: AdSense (any) → Ezoic (10K sessions) → Mediavine (25K) → Raptive (100K)
- **Traffic benchmark**: Calculator.net gets 400M+ visits/year; Omni Calculator 23M/month
- **Engagement**: Tool pages get 5-10 min avg session vs 2-3 min for content pages
- **Build cost**: Simple calculator = days; data-driven tool with API = weeks
- **Maintenance**: Near-zero once built (unlike content which needs constant refreshing)

## Lens-Specific Evidence Requirements

### Criterion 3: Revenue Potential
- Score >=4: Tool niche has RPM >$10 (finance, health, legal) AND search volume >50K/month for primary keyword
- Score >=3: RPM >$5 with moderate search volume, or freemium potential exists
- Key signals: Competitor tool sites running Mediavine/Raptive ads, API pricing pages, freemium tiers visible

### Criterion 5: Competition Gap
- Score >=4: Existing tools have poor UX (clunky, ad-heavy, slow, not mobile-friendly) — clear opportunity to build better
- Score >=3: Some tools exist but are outdated or missing key features
- Score <=2: Polished, fast, ad-light tools already exist (e.g., Google's built-in calculators)
- Key test: Google the query — if the top results are ugly/slow, that's your gap

### Criterion 8: Distribution
- Score >=4: Tool keyword has 100K+ monthly searches, long-tail variations abundant (e.g., "salary calculator [city]", "[job] salary range")
- Score >=3: 10K+ monthly searches for primary keyword with programmatic page generation potential
- Score <=2: Niche tool with <5K monthly searches — will never reach meaningful ad revenue
- Key signals: Google Suggest depth for tool-related queries, number of existing competitor tools in SERPs

### Criterion 9: Defensibility
- Primary moats: UX quality, calculation accuracy, brand trust, compound SEO authority, feature depth
- Score >=4: Tool solves a complex problem requiring significant domain knowledge (tax calculator, nutrition analyzer)
- Score >=3: Moderate complexity — better UX + more features than competitors creates switching cost
- Score <=2: Trivially simple tool (unit converter, random number generator) anyone can clone in hours

### Criterion 11: Founder-Team Fit
- Weight: 8% (expanded — domain expertise determines calculation accuracy and user trust)
- Ask: (1) Does the founder have subject-matter expertise relevant to the tool's domain (finance, health, dev, legal)? (2) Can they validate that the tool's logic/calculations are correct? (3) Do they understand SEO well enough to target the right query variations? (4) Can they build and maintain the tool without outside help?
- Score >=4: Founder has domain expertise + can verify accuracy + SEO competency + can build solo
- Score <=2: No domain knowledge, tool logic would need external validation, no SEO competency

### Criterion 12: MVP Speed
- Score >=4: Static calculator/converter with no external data = launch in 1-3 days
- Score >=3: Tool requiring one API integration = 1-2 weeks
- Score <=2: Complex data-driven tool requiring multiple APIs + regular data updates = 4+ weeks

### Criterion 13: Early Validation Signal
- Weight: 4% (lower weight — tools launch fast and validate via traffic post-launch)
- Score 4: Early version (even rough) already launched with measurable usage (100+ monthly users)
- Score 3: Shared idea/mockup publicly with positive feedback; similar tool exists proving demand
- Score <=2: Idea only; no version built or shared

## Tool Site Sub-Types

| Type | Examples | Revenue Model | Key Metric |
|------|---------|---------------|------------|
| **Calculator** | Salary, mortgage, BMI, tax | Ads + affiliate | Search volume per calculator |
| **Converter** | Unit, currency, timezone | Ads | Massive volume, low RPM |
| **Generator** | Password, color palette, name | Ads + freemium | Engagement time |
| **Analyzer** | SEO audit, speed test, readability | Freemium + leads | Conversion to paid |
| **Formatter** | JSON, SQL, code beautifier | Ads | Developer traffic |
| **Checker** | Grammar, plagiarism, accessibility | Freemium | Feature depth |

## Key Questions for Tool Site Evaluation

1. **What's the search volume?** — "salary calculator" has millions; "obscure converter" has hundreds
2. **How bad are existing tools?** — Ugly, slow, ad-heavy competitors = your opportunity
3. **Can you go programmatic?** — "salary calculator" → "salary calculator [every city]" → 10,000 pages
4. **What's the RPM?** — Finance tools ($15-30) vs utility tools ($3-8) is a 5x difference
5. **Is there a freemium path?** — Can you add API access, premium features, or white-label?
6. **How defensible is the logic?** — Tax calculations require expertise; unit conversion does not
