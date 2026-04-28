# E-commerce Lens — Scoring Rubrics

Business model: Selling physical or digital products directly to consumers or businesses. Includes art sales, fashion, specialty goods, food products, and digital downloads.

Revenue models: Product sales (direct margin), subscription boxes, wholesale, print-on-demand, licensing, commissions on marketplace sales.

## Weight Overrides

E-commerce success is driven by product margins, repeat purchases, and distribution (social commerce). Data availability is nearly irrelevant since you create/source products rather than aggregate data. Research shows 60% of DTC revenue comes from returning customers, and contribution margins of 30-40% (DTC) to 60%+ (luxury) determine viability.

| # | Criterion | Weight | Change | Rationale |
|---|-----------|--------|--------|-----------|
| 1 | Market Demand | 12% | — | Market size still matters |
| 2 | Problem Severity | 8% | -2% | E-commerce often solves wants, not pains |
| 3 | Revenue Potential | 15% | +3% | Margins, AOV, repeat purchase rate are everything |
| 4 | Competitor Revenue | 5% | -5% | Market validated differently (Etsy reviews, not SaaS ARR) |
| 5 | Competition Gap | 10% | +2% | Product differentiation is critical vs commodity |
| 6 | Timing | 6% | -2% | Less timing-dependent than tech |
| 7 | Automation Potential | 5% | -3% | Production/fulfillment, not data pipelines |
| 8 | Distribution | 12% | +4% | Social commerce, influencer, omnichannel critical |
| 9 | Defensibility | 10% | +2% | Brand IS the moat |
| 10 | Data Availability | 1% | -4% | You create products, not aggregate data |
| 11 | Founder-Team Fit | 9% | +3% | Aesthetic sense + maker credibility matter |
| 12 | MVP Speed | 2% | -3% | Same |
| 13 | Early Validation Signal | 5% | NEW | Pre-orders and early sales are strong signals |

## Key Benchmarks (from research)
- Repeat purchase rate: 25-30% average DTC, 35-45% consumables
- Average order value: $72 median DTC
- Contribution margin: 30-40% DTC, 60%+ luxury/art
- First orders rarely profitable — second and third purchases drive margins
- 60% of revenue from returning customers (convert at 60-70% vs 5-20% new)

## Lens-Specific Evidence Requirements

### Criterion 3: Revenue Potential
- Score >=4: Average order value >$100 AND repeat purchase potential (consumables, collectibles, seasonal)
- Score >=3: Clear pricing power — products are differentiated, not commoditized
- Key signals: Product margins (>50% for digital/art, >30% for physical), AOV, customer LTV, pricing of comparable products on Etsy/Amazon
- Unique to e-commerce: Shipping costs, return rates, payment processing fees reduce effective margin

### Criterion 4: Competitor Revenue Validation
- Score >=4: Competitors on Shopify/Etsy with 1000+ reviews OR funded DTC brands in the space
- Score >=3: Active sellers on Etsy/Amazon with visible sales volume
- Key signals: Etsy shop review counts (proxy for sales), Shopify store detection, Amazon BSR rankings
- CLI tools: `cli.duckduckgo` for Etsy/Amazon search, `cli.trustpilot` for brand reviews

### Criterion 5: Competition Gap
- Focus on: Product differentiation, not feature gaps
- Score >=4: No one sells exactly this type of product at this quality/price point
- Score <=2: Amazon/Etsy flooded with identical products at lower prices
- Key signals: Product uniqueness, handmade vs mass-produced, brand story strength

### Criterion 7: Automation Potential
- Focus on: Production, fulfillment, and marketing automation
- Score >=4: Print-on-demand or digital products (zero inventory), automated email marketing
- Score >=3: Dropshipping or 3PL fulfillment available
- Score <=2: Handmade one-of-a-kind items requiring personal production time (scalability bottleneck)
- Unique to e-commerce: Artist/maker time is the scarcest resource

### Criterion 8: Distribution Opportunity
- Focus on: Social commerce, influencer marketing, marketplace presence
- Score >=4: Instagram/Pinterest/TikTok aesthetic niche with viral potential, large relevant hashtag communities
- Score >=3: Etsy/Amazon marketplace presence viable, some social media communities
- Key signals: Instagram hashtag volume, Pinterest pin counts, TikTok views for niche, Etsy category depth
- CLI tools: WebSearch for social metrics, `cli.duckduckgo` for marketplace presence

### Criterion 9: Defensibility
- Primary moats: Brand identity, unique artistic style, customer relationships, email list, storytelling
- Score >=4: Unique products that cannot be replicated (original art, proprietary designs) + strong brand
- Score >=3: Semi-unique products with brand differentiation
- Score <=2: Commodity products easily sourced by competitors
- Unique to e-commerce: Personal brand of the maker/artist IS the moat

### Criterion 10: Data Availability → Product Sourcing Feasibility
- Reinterpret for e-commerce: Can products be sourced/created at scale?
- Score >=4: Digital products or print-on-demand (infinite inventory at zero marginal cost)
- Score >=3: Reliable suppliers or manageable production capacity
- Score <=2: One-person handmade production with no scaling path

### Criterion 11: Founder-Team Fit
- Weight: 9% (expanded — maker credibility and aesthetic sense are core to e-commerce success)
- Ask: (1) Does the founder have genuine passion and expertise in the product niche? (2) Do they have an existing audience or community (social following, email list) in this space? (3) Can they create/source the product without needing a large team? (4) Do they understand social commerce platforms relevant to this niche?
- Score >=4: Founder has niche expertise + existing audience + ability to create/source products + social commerce competency
- Score <=2: No connection to the product category, no audience, full outsourcing of production needed

### Criterion 12: MVP Speed
- Key factor: Shopify/Etsy/Squarespace setup time, product photography, initial inventory
- Score >=4: Digital products on Gumroad/Etsy = launch in 1 week
- Score >=3: Physical products on Shopify with print-on-demand = launch in 2-3 weeks
- Score <=2: Custom e-commerce build + physical inventory + photography = 2+ months

### Criterion 13: Early Validation Signal
- Weight: 5%
- Score 4: Pre-orders received, OR product sold at a market/event, OR Etsy/Shopify beta store with first sale
- Score 3: Sample or prototype shown to 10+ potential buyers with positive reactions
- Score <=2: No customer contact; idea only validated via market research
