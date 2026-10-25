# Automotive / Car Data — Unexplored Business Ideas

**Generated:** 2026-04-06
**Context:** Baseline generation (no skill). Informed by master-index.yaml and the car-database scored evaluation.

---

## What Already Exists in the Automotive Ecosystem

The project already has these automotive ideas logged:

| Slug | Model | Status |
|---|---|---|
| car-database (IMDB for Cars) | directory | PIVOT (49.6) |
| used-car-directory | directory | brainstorm |
| car-sale-intelligence | content/analytics | brainstorm |
| car-auction-intelligence | content | brainstorm |
| car-dealer-crm | saas | brainstorm |
| car-fleet-management | saas | brainstorm |
| yperatos-card-game (Vehicles) | ecommerce | brainstorm |

The car-database evaluation identified that generalist car spec databases fail due to entrenched incumbents (Edmunds, KBB, Cars.com) with deep SEO moats, and that revenue in automotive comes from transactions, not information. The PIVOT recommendation pointed at: (1) underserved niches incumbents ignore, (2) B2B data-as-a-service, or (3) AI-powered personalized comparison.

---

## New Ideas Not Yet Explored

### Idea 1: Classic Car Registry & Provenance Tracker

**Model:** directory + SaaS  
**Domains:** automotive, data, collector-market  
**Why it's a gap:** NHTSA vPIC API only covers 1981+. Pre-1981 classic cars have no structured public database. The classic car market is $15B+ globally and buyers/sellers routinely struggle with provenance, authenticity, and title history. Incumbents (Edmunds, KBB) do not value pre-1981 stock at all.  
**Core product:** A searchable registry where owners register their classic car with VIN (when available), chassis number, original specs, restoration history, and ownership chain. Each car gets a permanent public "passport" URL that can be linked in sale listings.  
**Revenue model:** Paid verification badges, report generation for buyers, premium listings for dealers and auction houses (Barrett-Jackson, RM Sotheby's).  
**Data sources:** NACA/FIVA historical records, marque-specific clubs, user-submitted provenance documents.  
**Why now:** Physical record-keeping is dying out; the generation that built these cars is aging; blockchain provenance is trending in adjacent collectibles (art, watches).  
**Risk:** Data quality is entirely user-submitted; fraud risk is real without physical inspection partners.

---

### Idea 2: JDM Import Compliance Navigator

**Model:** tool-site + directory  
**Domains:** automotive, regulatory, niche  
**Why it's a gap:** Japanese Domestic Market (JDM) imports are legal in the US after 25 years, Canada after 15, and rules vary by EU country. There is no single authoritative tool that tells a buyer "this specific vehicle (year, make, model, variant) is importable to your country, here's exactly what it costs, here are the approved importers, and here are the compliance steps."  
**Core product:** Enter year/make/model + target country → get a step-by-step compliance roadmap with cost estimates, required modifications, approved importers directory, and links to relevant customs/transport authority forms.  
**Revenue model:** Affiliate referrals to approved importers and compliance shops; premium report PDF download; B2B API for import brokers.  
**Data sources:** NHTSA 25-year rule, Transport Canada, UK DVLA, EU type-approval regulations, scraped/maintained importer directories.  
**Why now:** JDM culture has exploded with Gen Z (Skyline GT-R, Supra, NSX). 2025 marks the 25-year eligibility window for a wave of desirable early 2000s JDM vehicles (Honda S2000, Nissan Silvia S15, Subaru Impreza STi versions not sold in the US).  
**Risk:** Regulatory data goes stale; requires ongoing manual curation per country.

---

### Idea 3: EV Total Cost of Ownership Calculator (Hyperlocal)

**Model:** tool-site  
**Domains:** automotive, fintech, consumer  
**Why it's a gap:** Every EV manufacturer publishes optimistic TCO numbers. Generic calculators exist (DoE, EnergySage) but none are hyperlocal — they don't factor in your specific utility rate plan (time-of-use vs flat rate), your actual commute pattern, state-level EV incentives, used vs new market depreciation curves, or local charging infrastructure density.  
**Core product:** Enter your ZIP code, current car, annual mileage, electricity provider → get a 5-year TCO comparison between staying vs switching to specific EV models available in your region, with monthly payment scenarios.  
**Revenue model:** Lead generation to EV dealers and lease brokers; affiliate for home charger installations (Qmerit, Charged Future); display ads.  
**Data sources:** EPA fuel economy data, EIA electricity pricing by ZIP, IRS EV tax credit eligibility rules, DOE AFDC charging station API, vehicle depreciation data from iSeeCars/NADA.  
**Why now:** IRA tax credits (up to $7,500) have made EV math genuinely complex and state-dependent. Consumer confusion is at a peak. Incumbent comparison sites (Edmunds, KBB) have EV TCO tools but none are hyperlocal or account for time-of-use pricing.  
**Risk:** Tax credit rules change frequently; utility rate data integration is technically complex.

---

### Idea 4: Mechanic & Repair Shop Intelligence (Greece-first, expand)

**Model:** directory + marketplace  
**Domains:** automotive, local-services, greek-market  
**Why it's a gap:** Car owners have no reliable way to compare mechanic shops on price transparency, specialization (e.g. who works on diesel Audis), wait times, or actual customer outcomes. Google reviews are gamed. In Greece specifically, no structured mechanic directory exists — you rely entirely on word of mouth.  
**Core product:** Searchable directory of repair shops with: verified specializations, price benchmarks for common jobs (oil change, brake pads, timing belt) by car make, customer reviews with job-specific verification, and "get quotes" request flow.  
**Revenue model:** Freemium listings (free basic, paid featured/verified tier); lead generation per quote request; monthly SaaS for shops to manage reviews and bookings.  
**Data sources:** Google Places API for seed data; user-submitted quotes; shop-submitted specializations.  
**Why now:** Transparency is a rising expectation. Trustpilot/Google reviews are increasingly distrusted. In the Greek market, there is zero structured competition for this.  
**Risk:** Shops are slow to adopt digital tools in Greece; chicken-and-egg problem with reviews and listings.

---

### Idea 5: Car Recall Intelligence & Alert Service

**Model:** tool-site + SaaS (B2C and B2B)  
**Domains:** automotive, safety, data  
**Why it's a gap:** NHTSA publishes all recalls publicly but the UX is terrible. Most car owners never check recalls proactively — they only find out when the dealer mails them (slowly) or if the car fails. A modern recall intelligence service could send proactive alerts, explain severity in plain language, and help owners track recall completion status.  
**Core product:** Enter your VIN or license plate → get all open recalls for your vehicle with plain-language severity explanation, estimated repair time, and "find a dealer who has the parts" functionality. Set up email/SMS alerts for future recalls.  
**B2B angle:** Fleet operators and car rental companies pay for bulk VIN monitoring and recall status dashboards.  
**Revenue model:** Freemium (free VIN lookup, paid recurring monitoring alerts); B2B SaaS subscription for fleet operators; white-label API for insurance companies and fleet management platforms.  
**Data sources:** NHTSA Recalls API (free, comprehensive), NHTSA Complaints database, IIHS safety ratings.  
**Why now:** NHTSA recall volume has increased sharply in recent years (Ford, GM, Tesla mega-recalls). Consumer awareness is rising. The existing NHTSA UX is genuinely terrible. CarFax includes recall data but only as part of a paid vehicle history report — no standalone monitoring service.  
**Risk:** CarFax and Autocheck could add this feature trivially; defensibility depends on UX execution and B2B relationships.

---

### Idea 6: B2B Car Data API (Modern Teoalida)

**Model:** SaaS / API  
**Domains:** automotive, developer-tools, b2b  
**Why it's a gap:** Teoalida is a 1-person operation selling Excel databases for $500. There is no modern, well-documented, REST API offering comprehensive vehicle spec data at developer-friendly pricing. The incumbents (CarMD, Chrome Data/J.D. Power) charge enterprise rates ($10K+/year) aimed at dealers and insurers — completely inaccessible to startups and small apps.  
**Core product:** A REST API with: vehicle decode by VIN or year/make/model, specs (engine, dimensions, safety ratings, fuel economy, MSRP), recall data, and market value estimates. Generous free tier, self-serve paid tiers starting at $49/month.  
**Target customers:** Used car listing apps, fleet tools, insurance comparison apps, auto repair software, ride-share analytics.  
**Revenue model:** Usage-based API billing (free tier up to 500 calls/month, paid tiers by call volume).  
**Data sources:** NHTSA vPIC (free), EPA fuel economy API (free), NHTSA Recalls API (free), supplemented with purchased databases (Teoalida, car2db).  
**Why now:** API economy has matured; developer-first products (Stripe, Twilio model) have proven the market. No modern developer-first car data API exists in this space.  
**Risk:** Large incumbents could pivot to undercut pricing; maintaining data freshness requires ongoing engineering investment.

---

### Idea 7: Car Ownership Cost Tracker (Personal Finance for Car Owners)

**Model:** SaaS  
**Domains:** automotive, fintech, consumer  
**Why it's a gap:** Personal finance tools (YNAB, Mint, Copilot) track car payments but treat the car as a single expense category. They don't help owners understand: total cost per mile, when to repair vs replace, which maintenance is overdue, or the real depreciation curve of their specific car.  
**Core product:** Log your car's make/model/year/mileage → track all expenses (fuel, insurance, maintenance, repairs, registration) → get per-mile cost, depreciation tracking against market comps, and maintenance reminders based on manufacturer schedules. "Is it worth repairing?" calculator when a big repair comes in.  
**Revenue model:** Freemium SaaS ($0 for 1 car basic tracking, $5-9/month for unlimited cars, maintenance predictions, dealer price benchmarking); referral to mechanics and insurance (Lemonade, Root).  
**Data sources:** Manufacturer maintenance schedules (publicly available), iSeeCars/NADA for depreciation curves, user-entered expense data.  
**Why now:** Car ownership costs have surged post-COVID (insurance up 20%+, parts inflation, used car values volatile). Owners are more cost-conscious. No dedicated "car personal finance" app exists — only generic expense trackers.  
**Risk:** Requires behavioral change (logging expenses); retention is the core challenge.

---

### Idea 8: Greek Used Car Market Intelligence (Dealer-Facing)

**Model:** SaaS / content  
**Domains:** automotive, analytics, greek-market  
**Why it's a gap:** Car.gr (the dominant Greek used car marketplace) shows listings but provides no market intelligence. Greek used car dealers have no tool to answer: "What's the right price for a 2018 VW Golf with 80K km in Thessaloniki today?" or "What inventory sells fastest in my region?" The car-sale-intelligence idea in the registry points at this space but has no evaluation yet.  
**Core product:** A dealer-facing dashboard that scrapes/aggregates Greek used car listings (car.gr, Mobile.de Greek listings) to provide: real-time price benchmarks by make/model/year/mileage/region, days-to-sell estimates, demand heat maps by category, and "price your car" recommendations.  
**Revenue model:** Monthly SaaS subscription per dealer (€49-149/month); lead gen for auction houses; data reports sold to importers (which models are Greeks actually buying used?).  
**Data sources:** Car.gr scraping (requires monitoring of ToS), E-TEOTAK (Greek vehicle registration data), manual price collection.  
**Why now:** Greek used car market has been disrupted by post-COVID supply chain issues and EV subsidy programs. Dealers are navigating a volatile market with no data tools.  
**Risk:** Dependency on scraping car.gr — platform could block or send legal notices; Greek market may be too small for SaaS economics at meaningful scale.

---

## Summary Matrix

| Idea | Model | Market | Defensibility | Build Speed | Greek Angle |
|---|---|---|---|---|---|
| Classic Car Registry | directory+SaaS | global | medium (data moat builds over time) | medium | no |
| JDM Import Navigator | tool-site | global niche | medium (regulatory complexity = barrier) | fast | no |
| EV TCO Calculator | tool-site | global | low-medium | fast | no |
| Mechanic Shop Intelligence | directory+marketplace | greek-first | medium (local network effects) | medium | YES |
| Recall Intelligence | tool-site+SaaS | global | low (NHTSA is public) | fast | no |
| B2B Car Data API | SaaS/API | global | medium (developer experience moat) | medium | no |
| Car Ownership Cost Tracker | SaaS | global | medium (data + habits) | medium | no |
| Greek Used Car Market Intel | SaaS/content | greek-market | medium (data aggregation) | fast | YES |

---

## Top 3 Recommendations for Evaluation

**1. B2B Car Data API** — Highest revenue ceiling, clear underserved customer (developers), proven model (Teoalida shows demand at primitive tier). Fast to build with free government data. Monetization from day 1.

**2. Greek Used Car Market Intelligence** — Fits the project's Greek market strength. No local competitor. Dealers will pay for pricing data. Directly extends the car-sale-intelligence and car-dealer-crm brainstorm ideas already in the registry.

**3. EV Total Cost of Ownership Calculator (Hyperlocal)** — Timely (IRA complexity, EV adoption surge), fast to build, clear SEO/distribution angle, multiple revenue streams. Existing tools are generic; hyperlocal is the differentiation.
