# Directory Lens — Scoring Rubrics

Business model: Listing/comparison sites that aggregate, organize, and present information about entities (businesses, products, services, places).

Revenue models: Display ads, affiliate commissions, premium/featured listings, lead generation, data licensing, API access.

## Weight Overrides

Directory weights are the baseline — no overrides needed. These weights were calibrated from YC, Paul Graham, Sequoia, and a16z evaluation frameworks and validated through `research/guides/business-evaluation-best-practices.md`.

| # | Criterion | Weight | Notes |
|---|-----------|--------|-------|
| 1 | Market Demand | 12% | Baseline |
| 2 | Problem Severity | 10% | Baseline |
| 3 | Revenue Potential | 12% | Baseline |
| 4 | Competitor Revenue | 7% | -3% from baseline |
| 5 | Competition Gap | 6% | -2% from baseline |
| 6 | Timing | 8% | Baseline |
| 7 | Automation | 8% | Baseline |
| 8 | Distribution | 8% | Baseline |
| 9 | Defensibility | 8% | Baseline |
| 10 | Data Availability | 2% | -3% from baseline |
| 11 | Founder-Team Fit | 10% | +4% expanded |
| 12 | MVP Speed | 3% | -2% from baseline |
| 13 | Early Validation | 6% | NEW |

## Lens-Specific Evidence Requirements

### Criterion 3: Revenue Potential
- Score >=4: Competitors charge $50+/mo for premium listings OR affiliate programs with >5% commission exist
- Score >=3: At least one competitor has a visible pricing page or runs display ads
- Key signals: Ad RPM for the vertical, affiliate program availability, B2B listing buyer count

### Criterion 4: Competitor Revenue Validation
- Score >=4: At least 1 competitor with Tranco rank <500K AND domain age >3 years AND visible monetization
- Score >=3: Competitors with Wayback history >2 years and a pricing page
- Key signals: Tranco rank, domain age, Shopify/Stripe detection, employee count (via Hunter)

### Criterion 7: Automation Potential
- Focus on: Data pipeline automation — can listing data be scraped, API-pulled, or crowdsourced?
- Score >=4: Public APIs or existing scrapers cover 80%+ of needed data fields
- Score <=2: All data requires manual curation with no structured sources

### Criterion 9: Defensibility
- Primary moats: User-generated content (reviews/ratings), proprietary data enrichment, SEO authority, community
- Score >=4: Network effects possible (more users = better data = more users)
- Score <=2: Commodity data that anyone can scrape; no UGC or community lock-in

### Criterion 10: Data Availability
- Focus on: Can you populate the directory from automated sources?
- Key signals: Public APIs, GitHub datasets, government open data, existing scrapers
- Score >=4: Multiple redundant data sources with structured formats
- Score <=2: No APIs, no datasets; requires original research

### Criterion 11: Founder-Team Fit
- Weight: 10% (expanded from 6% — founder fit is a stronger signal than previously weighted)
- Ask: (1) Does the founder have direct experience with this directory niche? (2) Do they have contacts in the industry that help seed supply/listings? (3) Can they execute the data pipeline without hiring? (4) Do they understand SEO well enough to grow organic traffic?
- Score >=4: Founder has personal experience in niche + network to seed listings + SEO competency
- Score <=2: No domain knowledge, no relevant network, no technical ability to build or maintain

### Criterion 12: MVP Speed
- Key factor: Starter templates (Next.js, Astro directory starters), data bootstrapping time
- Score >=4: Directory template + API data source = launch in 1-3 weeks
- Score <=2: Complex data model + no data sources = 3+ months

### Criterion 13: Early Validation Signal
- Weight: 6% (NEW — measures whether any pre-launch demand signal exists)
- Score 4: Landing page with 50+ pre-launch signups OR early SEO content with measurable traffic
- Score 3: Domain registered, basic "coming soon" page, or informal interest from 10+ potential users
- Score <=2: No pre-launch activity; idea not yet tested with external audience
