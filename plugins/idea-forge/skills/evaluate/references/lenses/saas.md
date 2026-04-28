# SaaS Lens — Scoring Rubrics

Business model: Software as a Service — cloud-hosted software sold via subscriptions. Users pay monthly/annually for access to features, storage, or usage.

Revenue models: Freemium → paid tiers, usage-based pricing, per-seat pricing, enterprise contracts, API access fees.

## Weight Overrides

SaaS success is driven by recurring revenue (MRR/ARR), low churn, and high switching costs. Problem severity matters more than in directories because users must justify ongoing subscription cost. Research shows LTV:CAC >3x (ideally 4x+) is the key investor metric, NRR >120% commands 25% higher valuations, and 83% of VCs rate business model as the most important factor.

| # | Criterion | Weight | Change | Rationale |
|---|-----------|--------|--------|-----------|
| 1 | Market Demand | 10% | -2% | Niche SaaS can work with smaller TAM |
| 2 | Problem Severity | 12% | +2% | Must solve real pain to justify subscription |
| 3 | Revenue Potential | 12% | — | MRR/ARR, pricing tiers, LTV/CAC are core |
| 4 | Competitor Revenue | 5% | -5% | Funding data + pricing pages validate |
| 5 | Competition Gap | 6% | — | Feature gaps matter |
| 6 | Timing | 6% | -2% | Same |
| 7 | Automation → Tech Feasibility | 5% | -3% | Can you actually build this solo? |
| 8 | Distribution | 10% | +2% | PLG, content marketing, integrations |
| 9 | Defensibility | 12% | +4% | Switching costs, data lock-in are everything |
| 10 | Data Availability → APIs | 2% | -3% | What APIs/services can you leverage? |
| 11 | Founder-Team Fit | 10% | — | Domain expertise + sales ability are critical |
| 12 | MVP Speed | 2% | -3% | SaaS needs more iteration |
| 13 | Early Validation Signal | 8% | NEW | Highest weight — willingness-to-pay is hardest signal |

## Key Benchmarks (from research)
- MRR growth: 8-20% month-over-month early stage, 5-15% established
- Annual churn: <5% is healthy
- LTV:CAC ratio: >3x minimum, top quartile >5x
- NRR: 110-120%+ shows expansion revenue potential
- Series A readiness: $150K-$500K ARR with consistent growth
- B2B dominates YC batches (162 B2B vs consumer in W24)

## Lens-Specific Evidence Requirements

### Criterion 3: Revenue Potential
- Score >=4: B2B SaaS with $50+/user/month potential, clear willingness to pay (competitors charge similar)
- Score >=3: B2C SaaS with freemium model and $10-30/month paid tier viable
- Key signals: Competitor pricing pages, G2/Capterra reviews mentioning pricing, enterprise vs SMB target
- Unique to SaaS: LTV/CAC ratio matters more than single-purchase revenue. Recurring revenue is the goal.
- Revenue benchmarks: Rule of thumb — 100 paying customers at $50/mo = $60K ARR (lifestyle); 1000 at $100/mo = $1.2M ARR (funded startup territory)

### Criterion 4: Competitor Revenue Validation
- Score >=4: Competitors with visible funding (Crunchbase), 50+ employees (Hunter email count), or public revenue data
- Score >=3: 3+ competitors with pricing pages and Tranco rank <500K
- Key signals: Crunchbase funding rounds, G2 review counts (>100 = established), job postings (hiring = growing), Tranco rank
- CLI tools: `cli.opencorporates`, `cli.hunter`, `cli.domain_rank`, `cli.serper` for "[competitor] pricing"

### Criterion 5: Competition Gap
- Focus on: Feature gaps, UX problems, pricing gaps, integration gaps
- Score >=4: Competitors are legacy/enterprise-only and no modern, affordable alternative exists
- Score >=3: Competitors exist but are missing key features or have poor UX
- Score <=2: Well-funded competitors with feature parity and strong brand recognition
- Key signals: G2/Capterra negative reviews (pain points), competitor feature pages, integration directories

### Criterion 7: Automation Potential → Technical Feasibility
- Reinterpret for SaaS: How complex is this to build? What's the technical risk?
- Score >=4: Standard CRUD app with well-understood patterns, no AI/ML required, existing libraries available
- Score >=3: Moderate complexity — requires some specialized knowledge or API integrations
- Score <=2: Deep tech (ML models, real-time processing, complex algorithms) requiring PhD-level expertise
- Key factor: Solo developer feasibility — can one person build and maintain this?

### Criterion 8: Distribution Opportunity
- Focus on: Product-led growth (PLG), content marketing, integration marketplaces
- Score >=4: Natural viral loop (collaboration features, sharing, embeds) OR strong content/SEO play
- Score >=3: Integration marketplace distribution (Shopify apps, Chrome extensions, Slack apps)
- Score <=2: Requires enterprise sales team; no self-serve motion possible
- Key signals: Competitor marketing channels, integration ecosystem size, community presence

### Criterion 9: Defensibility
- Primary moats: Data lock-in, workflow integration, switching costs, network effects, API ecosystem
- Score >=4: Users' data lives in the product (high switching cost) + integrations with other tools
- Score >=3: Some workflow dependency; users would need to retrain to switch
- Score <=2: Commodity feature set easily replicated; no data or workflow lock-in
- Unique to SaaS: The longer users use it, the harder it is to leave (data gravity)

### Criterion 10: Data Availability → Technical Feasibility
- Reinterpret for SaaS: What APIs, services, and tools can you leverage?
- Score >=4: Rich API ecosystem exists (Stripe for payments, Auth0 for auth, Twilio for comms, etc.)
- Score >=3: Most needed APIs exist but some custom development required
- Score <=2: No relevant APIs; everything must be built from scratch

### Criterion 11: Founder-Team Fit
- Weight: 10% (baseline — in B2B SaaS, founder credibility closes deals)
- Ask: (1) Does the founder understand the target buyer's daily workflow intimately? (2) Do they have existing relationships with 10+ potential customers? (3) Can they build the core product solo or with a small team? (4) Do they have domain expertise that builds trust during demos/sales calls?
- Score >=4: Founder has worked in the target industry + has warm pipeline of potential beta customers + can build core product
- Score <=2: No domain knowledge, no network in the target market, full technical outsourcing needed

### Criterion 12: MVP Speed
- Key factor: No-code/low-code options, starter templates, boilerplate availability
- Score >=4: Can ship functional MVP in 1-2 weeks using existing frameworks (Next.js, Supabase, Clerk)
- Score >=3: 3-6 weeks with standard web stack
- Score <=2: 3+ months due to technical complexity (ML training, complex algorithms, regulatory compliance)

### Criterion 13: Early Validation Signal
- Weight: 8% (highest across all lenses — SaaS subscription requires strongest validation signal)
- The hardest question in SaaS is not "will users try it?" but "will businesses pay $X/month?" — validation must include willingness-to-pay signals, not just interest signals.
- Score 5: Multiple paying customers OR signed pilots OR LOIs from named companies
- Score 4: 1 paying beta customer, OR 100+ waitlist signups, OR 3+ companies gave verbal commitment to pilot
- Score 3: 20-50 waitlist signups, OR 5+ customer interviews with "I'd pay for that" responses
- Score <=2: No conversations with potential B2B buyers; no waitlist
