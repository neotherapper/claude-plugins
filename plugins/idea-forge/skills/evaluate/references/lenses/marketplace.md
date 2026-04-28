# Marketplace Lens — Scoring Rubrics

Business model: Two-sided (or multi-sided) platform connecting buyers with sellers, service providers with customers, or supply with demand. The platform facilitates transactions and takes a cut.

Revenue models: Transaction fees (take rate), listing fees, featured placements, subscription tiers for sellers, lead generation fees.

## Weight Overrides

Marketplace success is dominated by the cold-start problem and network effects. Andrew Chen (a16z) identifies five stages: Cold Start, Tipping Point, Escape Velocity, Hitting the Ceiling, and The Moat. The hard side is typically supply — power users (20% of supply) drive 60% of transactions. Distribution and defensibility are weighted highest because they determine whether the marketplace achieves liquidity.

| # | Criterion | Weight | Change | Rationale |
|---|-----------|--------|--------|-----------|
| 1 | Market Demand | 10% | -2% | Market exists but cold start is the real test |
| 2 | Problem Severity | 8% | -2% | Marketplaces solve coordination, not always pain |
| 3 | Revenue Potential | 12% | — | Take rate x GMV |
| 4 | Competitor Revenue | 5% | -5% | Winner-take-most dynamics change validation |
| 5 | Competition Gap | 6% | — | Gap matters but network effects dominate |
| 6 | Timing | 5% | -3% | Platform decay creates opportunity windows |
| 7 | Automation → Matching | 5% | -3% | Matching algorithm complexity |
| 8 | Distribution | 15% | +7% | Cold start problem is THE #1 killer |
| 9 | Defensibility | 14% | +6% | Network effects are the strongest moat type |
| 10 | Data Availability → Supply | 1% | -4% | Can you identify and onboard supply side? |
| 11 | Founder-Team Fit | 9% | +3% | Supply-side relationships are existential |
| 12 | MVP Speed | 1% | -4% | Two-sided complexity extends build time |
| 13 | Early Validation Signal | 9% | NEW | Cold-start validation is existential |

## Key Benchmarks (from research)
- Cold start sequence: "supply, demand, supply, supply, supply" (a16z)
- Power users: 20% of supply drives 60% of transactions (Uber model)
- Take rates: 10-20% for services, 5-15% for products
- Network effects: strongest moat — once achieved, nearly unbeatable
- 83% of VCs rate business model as most important evaluation factor
- Tipping point: minimum viable liquidity before growth can begin

## Lens-Specific Evidence Requirements

### Criterion 3: Revenue Potential
- Score >=4: High transaction values (>$500 per transaction) with 10-20% take rate viable, OR high volume with 5-10% take rate
- Score >=3: Moderate transaction values ($50-500) with clear take rate model
- Key signals: Average transaction value in the category, competitor take rates, willingness of sellers to pay for access to buyers
- Unique to marketplace: Revenue = GMV x Take Rate. Both sides must see value.
- Revenue benchmarks: $1M GMV at 15% take rate = $150K revenue

### Criterion 4: Competitor Revenue Validation
- Score >=4: Established marketplaces exist with visible GMV, funding, or public financials
- Score >=3: Regional or niche marketplaces exist with some traction
- Key signals: Marketplace funding rounds (Crunchbase), seller counts, listing volumes, app store ratings/downloads
- CLI tools: `cli.serper` for marketplace discovery, `cli.domain_rank` for traffic, `cli.appstores` for mobile presence

### Criterion 5: Competition Gap
- Focus on: Niche underserved by horizontal marketplaces (Etsy, Amazon, Fiverr)
- Score >=4: No dedicated vertical marketplace exists; buyers/sellers use general platforms or offline methods
- Score >=3: Existing marketplaces are regional, outdated, or poorly trusted
- Score <=2: Well-funded vertical marketplace already dominates (e.g., Airbnb for lodging)
- Unique concern: Marketplace competition is winner-take-most due to network effects

### Criterion 6: Why Now / Timing
- Extra important for marketplaces: Regulatory change, gig economy shift, or platform decay (Craigslist replacement opportunity)
- Score >=4: Regulatory change creates new transaction type OR existing platform is declining/trust-broken
- Score <=2: Established incumbent with strong network effects and no sign of weakness

### Criterion 7: Automation Potential
- Focus on: Matching algorithm complexity, payment processing, trust/safety systems
- Score >=4: Simple matching (search + filter), standard payment processing (Stripe Connect)
- Score >=3: Moderate matching complexity, basic verification needed
- Score <=2: Complex matching algorithms (ML-based), heavy verification/vetting, regulatory compliance

### Criterion 8: Distribution Opportunity — The Cold-Start Problem
- THIS IS THE MAKE-OR-BREAK for marketplaces. How do you solve chicken-and-egg?
- Score >=4: Can start single-player (useful to one side without the other) OR can seed supply side easily
- Score >=3: Can launch in one city/niche and expand (geographic or vertical constraint strategy)
- Score <=2: Both sides needed simultaneously with no single-player utility
- Key strategies to identify: Supply-side seeding, constrained launch, single-player mode, come-for-tool-stay-for-network

### Criterion 9: Defensibility
- Primary moat: NETWORK EFFECTS (strongest moat type — more sellers attract more buyers attract more sellers)
- Score >=4: True network effects + data advantages (review history, reputation, transaction data)
- Score >=3: Some network effects but low switching costs (multi-tenanting common)
- Score <=2: No network effects; commodity service where users compare on price alone
- Unique to marketplace: Winner-take-most dynamics — if you're not #1 or #2, you're dead

### Criterion 10: Data Availability → Supply-Side Feasibility
- Reinterpret: Can you identify and onboard the supply side?
- Score >=4: Supply side is easily identifiable and contactable (public businesses, licensed professionals)
- Score >=3: Supply side exists but fragmented or hard to reach
- Score <=2: Supply side must be recruited one-by-one with high friction

### Criterion 11: Founder-Team Fit
- Weight: 9% (expanded — supply-side relationships are the founder's most critical asset)
- Ask: (1) Does the founder have direct relationships with the supply side (sellers/providers)? (2) Do they understand both sides of the transaction from personal experience? (3) Can they seed the marketplace manually in the early stages? (4) Do they have credibility that makes supply side trust them with listings/inventory?
- Score >=4: Founder has existing supply-side relationships + understands both sides + credibility in the niche
- Score <=2: No network on supply side, no domain experience, cannot manually seed marketplace

### Criterion 12: MVP Speed
- Key factor: Two-sided complexity doubles development vs single-sided products
- Score >=4: Can use existing marketplace template/framework (Sharetribe, Saleor) = 2-4 weeks
- Score >=3: Custom build with standard stack but simple matching = 4-8 weeks
- Score <=2: Complex matching + verification + compliance = 3+ months

### Criterion 13: Early Validation Signal
- Weight: 9% (cold-start validation is existential for marketplaces)
- For marketplaces, the most critical validation is supply-side. A marketplace without committed supply is not a marketplace — it's an empty room. Score this criterion conservatively unless real supply-side commitments exist.
- Score 5: Supply side committed (10+ suppliers/providers said "yes"), AND at least 1 successful transaction completed
- Score 4: Supply side interested (5+ providers expressed willingness to list/participate)
- Score 3: At least 3 supply-side conversations, OR 20+ demand-side signups on a waitlist
- Score <=2: No conversations with either side; only desk research done
