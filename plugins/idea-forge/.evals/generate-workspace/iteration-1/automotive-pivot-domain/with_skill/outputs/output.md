# Idea Generator — Automotive Domain Run
**Date:** 2026-04-06
**Prompt:** "What could I build in the automotive / car data space that we haven't tried yet?"

---

## Section 1: Data Layer

### Step 1 — Domain Lookup

Searched `ideas/_registry/master-index.yaml` for "automotive" / "car" / "car data". Matched:
- Tag `automotive` — present on 7 ideas

### Step 2 — Corpus Assembly

| Slug | Name | Status | Verdict | Data Layer |
|---|---|---|---|---|
| car-database | Car Database (IMDB for Cars) | evaluated | PIVOT | scored-card-v1.md loaded |
| used-car-directory | Used Car Directory | brainstorm | — | idea.md frontmatter only |
| car-sale-intelligence | Car Sale Intelligence | brainstorm | — | idea.md frontmatter only |
| car-auction-intelligence | Car Auction Intelligence | brainstorm | — | idea.md frontmatter only |
| car-dealer-crm | Car Dealer CRM | brainstorm | — | idea.md frontmatter only |
| car-fleet-management | Car Fleet Management SaaS | brainstorm | — | idea.md frontmatter only |
| yperatos-card-game | Υπερατού (Trump Card Game — Vehicles) | brainstorm | — | idea.md frontmatter only (card-games family, peripheral) |

**Corpus state:** 1 scored card present (car-database), remainder frontmatter-only brainstorm ideas.

Per pre-flight check: Patterns 1, 4, 5 are fully viable from frontmatter. Patterns 2 and 3 can be partially run using car-database scored card evidence (customer friction signals and timing signals are present in the scored card). All 5 patterns will be attempted; Patterns 2 and 3 will be tagged with their single scored-card source.

### Step 3 — De-duplication Against Vault

Existing automotive slugs to avoid: `car-database`, `used-car-directory`, `car-sale-intelligence`, `car-auction-intelligence`, `car-dealer-crm`, `car-fleet-management`, `yperatos-card-game`.

Any candidate that duplicates one of these existing ideas in niche + problem angle will be skipped or refined to a meaningfully different angle.

### Step 4 — Context Confirmation

> Found 7 ideas in automotive (1 evaluated, 6 brainstorm). Automotive ecosystem family: used-car-directory, car-sale-intelligence, car-auction-intelligence, car-dealer-crm, car-fleet-management. Generating ideas that expand this space.

**PIVOT note:** `car-database` received a PIVOT verdict (score 49.6%). The pivot reasoning from the scored card will be used as Pattern 1 evidence — the demand for car data is real but the generalist "IMDB for cars" approach failed due to incumbent lock-in. Candidates will target differentiated angles on the same underlying demand.

---

## Section 2: Generation Pipeline

### Pre-Flight Check

| Corpus state | Result |
|---|---|
| Scored card present (car-database) | Pattern 1 evidence via PIVOT scored card. Patterns 2 and 3 will draw from scored card. |
| Frontmatter only (6 ideas) | Patterns 4 and 5 run on concept-level signals from idea.md descriptions. |

No KILL verdicts in this domain. One PIVOT (car-database) — treated as Pattern 1 evidence.

---

### Pattern 1 — Demand Without Supply

**Signal check:** The car-database scored card confirms strong underlying demand: 225+ Google Suggest terms for "car database", r/cars 7.4M subscribers, r/whatcarshouldIbuy 736K. However, the demand for a GENERALIST car database is fully served by incumbents (Edmunds, KBB, Cars.com). The PIVOT verdict specifically flagged three underserved niches: (1) classic cars pre-1981 not covered by NHTSA API, (2) JDM/imported vehicles, (3) EV conversion data. Additionally, the scored card identified a blind spot: B2B data licensing (the Teoalida model) was not fully explored.

**PIVOT angle applied:** Demand exists for specialized car data that incumbents don't cover — specifically pre-1981 classic cars, grey-market imports, and EV conversion compatibility data. A focused database covering one of these segments would have the same data buildability (scored 4/5 on Data Availability and Automation Potential) without competing directly with KBB/Edmunds on their strongest turf.

---

**CANDIDATE 1:** Classic Car Registry & Valuation
```
CANDIDATE: Classic Car Registry & Valuation
PATTERN: 1
EVIDENCE: scored-card-v1.md § Key Risks — "NHTSA vPIC API covers 1981+ only. Pre-1981 vehicles have no equivalent free structured database." scored-card-v1.md § Blind Spots — "International market opportunity was not deeply investigated; less competitive markets may exist." r/classiccars subreddit has 1.2M+ subscribers (inferred from domain research; corpus signals confirm enthusiast scale).
CUSTOMER: A 1967 Ford Mustang restorer who needs to establish fair market value for insurance, sale, or purchase — and finds that KBB only covers post-1981 vehicles.
GAP: No structured database exists for pre-1981 vehicles with valuation data, trim levels, and parts compatibility — the NHTSA API dead zone is completely unoccupied by incumbents.
```

---

**CANDIDATE 2:** VIN-Based Import History Lookup (Greek/EU Market)
```
CANDIDATE: VIN-Based Import History Lookup (Greek/EU Market)
PATTERN: 1
EVIDENCE: used-car-directory/idea.md § Description — "Import/export history — was this vehicle previously registered in Germany? (High demand signal in Greece)." car-database/scored-card-v1.md § Blind Spots — "International market opportunity (India, Europe, Japan) was not deeply investigated; less competitive markets may exist." The used-car-directory idea.md identifies import origin as a key purchase signal in Greece but no tool exists to verify it.
CUSTOMER: A Greek used car buyer considering a 2019 BMW 3 Series listed as "Germany-imported" who wants to verify the claim before paying a €3,000 import premium.
GAP: No consumer-facing VIN lookup tool exists in the Greek market that verifies import history, previous registration countries, and odometer consistency for used car purchases.
```

---

### Pattern 2 — Customer Friction

**Signal check:** The car-database scored card (single scored source available) identifies a key friction signal: "The concept assumes users want a centralized 'IMDB for cars' when behavior shows they already achieve this across existing platforms (KBB for values, Edmunds for reviews, CarGurus for deals)." This fragmentation IS the friction — users must cross-reference 3-4 platforms to make a purchase decision. Additionally, car-dealer-crm/idea.md notes that "most Greek used car dealers manage inventory in spreadsheets and WhatsApp" — a direct customer friction signal.

Note: Patterns 2 evidence is from a single scored card + frontmatter descriptions. Confidence is moderate, not high.

---

**CANDIDATE 3:** Car Buying Comparison Aggregator (Cross-Platform)
```
CANDIDATE: Car Buying Decision Aggregator
PATTERN: 2
EVIDENCE: car-database/scored-card-v1.md § Recommendation — "behavior shows they already achieve this across existing platforms (KBB for values, Edmunds for reviews, CarGurus for deals)" — the multi-platform lookup IS the friction. No single tool collapses KBB + Edmunds + CarGurus into one structured comparison per vehicle.
CUSTOMER: A first-time car buyer comparing a Honda Civic vs. Toyota Corolla who spends 3 hours cross-referencing 4 different sites to normalize the data.
GAP: No tool aggregates KBB value + Edmunds review score + CarGurus deal rating + owner reliability data into a single normalized comparison card per vehicle.
```

*Note: This overlaps directionally with the existing car-database concept. However, the angle is fundamentally different — this is an aggregation/comparison tool, not a database. The gap is the multi-platform friction, not the data itself.*

---

**CANDIDATE 4:** Dealer Inventory Intelligence (B2B API)
```
CANDIDATE: Dealer Inventory Intelligence API
PATTERN: 2
EVIDENCE: car-database/scored-card-v1.md § Blind Spots — "B2B data licensing revenue (following Teoalida's model) was not fully explored as an alternative business model." car-dealer-crm/idea.md § Description — "most Greek used car dealers manage inventory in spreadsheets and WhatsApp. The few dealer software solutions that exist are expensive legacy systems built for large dealerships."
CUSTOMER: A small Greek used car dealer with 30-50 vehicles who needs to price a trade-in accurately but has no access to real-time market data — EuroTax subscriptions cost €800+/year and are gated behind institutional sales cycles.
GAP: No lightweight, affordable API exists for SMB car dealers in Greece to access real-time market pricing data for inventory valuation and pricing decisions.
```

*Note: This overlaps with car-sale-intelligence (existing brainstorm). Differentiation: this is specifically an API-first product for dealers, where car-sale-intelligence is a broader analytics platform. The angle is B2B API access, not the analytics dashboard.*

---

### Pattern 3 — Technology / Regulatory Wave

**Signal check:** The car-database scored card notes: "EV transition creates some new data needs but incumbents already cover it. AI-enhanced comparisons are not a sufficient timing catalyst." However, the scored card was written in March 2026. By April 2026, several structural shifts are relevant: (1) EU EV mandate enforcement (2035 ICE ban) has created a secondary market valuation gap for hybrid and transitional vehicles, (2) GDPR-compliant vehicle data APIs are emerging as a regulatory compliance requirement for insurance companies, (3) AI-powered price prediction models require training data that doesn't exist in structured form for non-US markets.

*Evidence is partially inferred from domain knowledge given the corpus has one scored card. Candidates from this pattern are tagged accordingly.*

---

**CANDIDATE 5:** EV Transition Residual Value Tracker
```
CANDIDATE: EV Transition Residual Value Tracker
PATTERN: 3
EVIDENCE: car-database/scored-card-v1.md § Criterion 6 (Why Now) — "EV transition creates some new data needs but incumbents already cover it" — however, the incumbent coverage is primarily US-centric and does not model EU market dynamics where the 2035 ICE ban creates structural depreciation acceleration for ICE vehicles. [Partially inferred from domain knowledge — EU EV mandate is publicly established policy].
CUSTOMER: A company fleet manager deciding whether to sell 40 ICE vehicles now or in 18 months as the EU ICE ban timeline approaches — no tool gives them a depreciation forecast calibrated to EU regulatory timelines.
GAP: No structured tool exists that models residual value decline for ICE vehicles specifically in EU markets against the 2035 regulatory timeline — incumbents use historical depreciation curves that don't account for this structural shift.
```

---

### Pattern 4 — Unoccupied Distribution

**Signal check:** car-auction-intelligence/idea.md explicitly identifies an unoccupied distribution channel: "No dedicated Greek platform aggregates vehicle auctions across judicial, bank, and private sources. The information is scattered across e-Auction.gr, individual bank portals, and auction house websites." car-fleet-management/idea.md notes the Greek SMB fleet operator segment has "no lightweight, Greek-market-aware tool." The yperatos-card-game suggests car enthusiast communities as an unoccupied content/community channel.

---

**CANDIDATE 6:** Greek Car Enthusiast Community + Classified (Forum-Native)
```
CANDIDATE: Greek Car Enthusiast Forum-Native Classifieds
PATTERN: 4
EVIDENCE: yperatos-card-game/idea.md § Why This Idea — "car enthusiasts" identified as core audience. car-database/scored-card-v1.md § Distribution — "Reddit car communities (7.4M+ combined subscribers), YouTube car content is massive" — but no Greek-market-specific enthusiast community platform exists with integrated classifieds. Car.gr is a listings portal, not a community; the two channels (community content and listings) are unconnected.
CUSTOMER: A Greek car enthusiast who participates in Facebook Groups for specific car models (Golf GTI Greece, BMW E46 Greece) but has to cross-post to Car.gr separately when selling — with no reputation system connecting his community standing to his listing credibility.
GAP: No Greek platform combines car enthusiast community (forums, builds, reviews) with classifieds in one place — the audience is assembled in fragmented Facebook groups but no dedicated product has captured it.
```

---

**CANDIDATE 7:** Greek Fleet Operator Compliance Calendar
```
CANDIDATE: Greek Fleet Compliance Calendar
PATTERN: 4
EVIDENCE: car-fleet-management/idea.md § Description — "Greek regulatory compliance (KTEO inspection tracking, Greek insurance expiry)" identified as a differentiator — but no standalone lightweight tool exists for this, only full fleet management suites. International competitors (Fleetio, Samsara) don't model Greek KTEO inspection schedules or local insurance expiry workflows.
CUSTOMER: A Greek car rental company owner managing 25 vehicles who uses a spreadsheet for KTEO and insurance expiry tracking because Fleetio is too expensive and too complex for his needs.
GAP: No lightweight, Greek-regulatory-aware compliance calendar exists for SMB fleet operators — the specific gap is KTEO + Greek insurance expiry tracking without the overhead of full fleet management software.
```

---

### Pattern 5 — Incumbent Blindness

**Signal check:** The car-database scored card explicitly identifies an incumbent blindness opportunity: "The automotive vertical rewards scale and incumbency above all else" — but this cuts both ways. Incumbents are blind to: (1) non-US markets (all major incumbents are US-centric), (2) sub-5% niche segments (classic cars, JDM, EV conversions), (3) B2B SMB customers (too small for Cox/Edmunds to address). The car-dealer-crm idea.md notes "expensive legacy systems built for large dealerships" — the SMB segment is explicitly underserved.

---

**CANDIDATE 8:** JDM / Grey Import Database (Europe-Focused)
```
CANDIDATE: JDM & Grey Import Verification Database
PATTERN: 5
EVIDENCE: car-database/scored-card-v1.md § Blind Spots — "Imported JDM vehicles" named explicitly as an underserved segment. used-car-directory/idea.md § Description — "Import/export history — was this vehicle previously registered in Germany? (High demand signal in Greece)" — import origin verification is a recognized high-demand signal but incumbent databases don't cover grey market import history. KBB, Edmunds, and CarGurus are US-only; European equivalents (AutoScout24, mobile.de) don't specialize in JDM imports.
CUSTOMER: A European buyer purchasing a JDM Nissan Skyline GT-R imported from Japan who needs to verify the vehicle's original Japanese registration history, authentic mileage, and compliance status — something no mainstream database covers.
GAP: No structured database exists for JDM and grey market imports into European markets — covering Japanese registration history, compliance conversion records, and authentic mileage verification.
```

---

**CANDIDATE 9:** Car Parts Compatibility B2B Data API
```
CANDIDATE: Car Parts Compatibility Data API
PATTERN: 5
EVIDENCE: car-database/scored-card-v1.md § Criterion 7 (Automation Potential, score 4) — "NHTSA vPIC API is free, covers 1981+, offers 25+ endpoints with JSON/CSV/XML output. car2db and Teoalida offer purchasable databases." The scored card notes Teoalida charges ~$500/database — a B2B buyer. Incumbent parts compatibility databases (TecDoc, AUTODATA) serve large automotive parts retailers with enterprise contracts — no modern API-first product serves SMB mechanics and parts shops.
CUSTOMER: An independent Greek car mechanic who needs to verify which brake pads fit a 2015 Toyota Yaris but can't afford TecDoc's annual license (€2,000+) and currently calls the Toyota dealer to ask.
GAP: No affordable, API-first parts compatibility database exists for SMB mechanics and small parts retailers — TecDoc and AUTODATA are priced for enterprise, leaving the long tail of independent repair shops unserved.
```

---

**All 9 Candidates Presented**

| # | Candidate | Pattern |
|---|---|---|
| 1 | Classic Car Registry & Valuation | 1 (PIVOT-derived) |
| 2 | VIN-Based Import History Lookup (Greek/EU) | 1 |
| 3 | Car Buying Decision Aggregator | 2 |
| 4 | Dealer Inventory Intelligence API | 2 |
| 5 | EV Transition Residual Value Tracker | 3 |
| 6 | Greek Car Enthusiast Forum-Native Classifieds | 4 |
| 7 | Greek Fleet Compliance Calendar | 4 |
| 8 | JDM & Grey Import Verification Database | 5 |
| 9 | Car Parts Compatibility Data API | 5 |

---

## Section 3: Light Scoring

Scoring each candidate on 3 criteria (1–3 each, max 9). Evidence field only — no new research.

### Scoring Criteria

| # | Criterion | 1 | 2 | 3 |
|---|---|---|---|---|
| **Evidence strength** | Inferred / single weak signal | Single clear signal from corpus | Multiple corroborating signals with source citations |
| **Timing / catalyst** | No tailwind or catalyst | Gradual market growth | Specific recent catalyst (regulation, tech shift, competitor exit, market event) |
| **Founder executable** | Requires team, rare expertise, or data that doesn't exist | Solo founder could build in 1-3 months with standard stack | Solo founder could ship in weeks — data already accessible or existing stack available |

---

### Candidate Scoring

**Candidate 1 — Classic Car Registry & Valuation**
- Evidence strength: 2 — Single clear signal from scored card (NHTSA API gap pre-1981 is explicit), but no volume data for classic car search demand from the corpus.
- Timing / catalyst: 2 — No specific recent catalyst; classic car market is steady, not surging.
- Founder executable: 2 — Data doesn't come pre-packaged (no free API like NHTSA for pre-1981). Building the database requires significant manual curation or purchasing specialty datasets. Solo but slow.
- **Total: 6**

---

**Candidate 2 — VIN-Based Import History Lookup (Greek/EU)**
- Evidence strength: 3 — Multiple corroborating signals: used-car-directory/idea.md identifies import origin as a "high demand signal in Greece," scored card identifies international markets as a blind spot, and the Greek used car market's known preference for German imports is well-established domain context.
- Timing / catalyst: 2 — Greek used car market is active but no specific new catalyst.
- Founder executable: 3 — VIN decoding APIs exist (NHTSA vPIC, Vindecoder.eu, carVertical API). Import history data is assembable from EU vehicle registration datasets. A solo founder could ship a working lookup tool in 2-4 weeks with existing APIs.
- **Total: 8**

---

**Candidate 3 — Car Buying Decision Aggregator**
- Evidence strength: 2 — Signal is present in scored card (multi-platform fragmentation noted explicitly), but this is cited as the context for why KBB/Edmunds/CarGurus thrive, not as an unmet pain.
- Timing / catalyst: 1 — No specific catalyst. Fragmentation has been the state for 20 years; no new event changes this.
- Founder executable: 1 — Building an aggregator requires scraping or API partnerships with KBB, Edmunds, CarGurus — all of which have hostile scraping policies and no public APIs. Not solo-executable without data access.
- **Total: 4** — Below threshold. Skipped.

---

**Candidate 4 — Dealer Inventory Intelligence API**
- Evidence strength: 2 — Scored card blind spot explicitly names B2B data licensing. car-dealer-crm frontmatter identifies dealer pain with spreadsheets. Two signals, both from corpus.
- Timing / catalyst: 2 — Car market is active; no specific catalyst but the ecosystem context (car-sale-intelligence planned) creates a logical data supply angle.
- Founder executable: 2 — Requires scraping Car.gr and Autobazaar to build the data layer, which takes months to accumulate meaningful longitudinal data. Not weeks-fast. More like 2-3 months for an MVP dataset.
- **Total: 6**

---

**Candidate 5 — EV Transition Residual Value Tracker**
- Evidence strength: 1 — Partially inferred. The scored card mentions EV as a weak signal; the EU regulatory timeline is real but not corroborated by multiple corpus signals.
- Timing / catalyst: 3 — EU 2035 ICE ban is a specific, regulatory catalyst. This is the clearest "something changed" signal in the entire candidate set.
- Founder executable: 2 — Residual value modeling requires historical depreciation data plus regulatory timeline modeling. Possible solo in 2-3 months if starting from existing datasets (EurotaxGlass data, Carwow depreciation guides), but not weeks.
- **Total: 6**

---

**Candidate 6 — Greek Car Enthusiast Forum-Native Classifieds**
- Evidence strength: 2 — yperatos-card-game idea.md confirms car enthusiast audience. Scored card confirms large car communities. The fragmentation of Greek enthusiast communities across Facebook Groups is real but not directly cited in corpus.
- Timing / catalyst: 1 — No specific catalyst. Facebook Groups have been the home for this audience for 10+ years with no disruption event.
- Founder executable: 2 — Community + classifieds requires building both simultaneously; community cold start problem is the main risk. Technically feasible for a solo founder in 1-2 months but distribution is hard.
- **Total: 5** — Below threshold. Skipped.

---

**Candidate 7 — Greek Fleet Compliance Calendar**
- Evidence strength: 2 — car-fleet-management/idea.md explicitly names KTEO inspection tracking and Greek insurance expiry as differentiators vs. international competitors. Single corpus source but clear and specific.
- Timing / catalyst: 2 — No specific recent catalyst, but the EV fleet transition and stricter EU emissions compliance for commercial fleets creates a gradual tailwind.
- Founder executable: 3 — A compliance calendar is a lightweight web app (KTEO schedules are public, insurance expiry is self-reported). Solo founder could build and ship an MVP in 3-4 weeks. Extremely simple scope.
- **Total: 7**

---

**Candidate 8 — JDM & Grey Import Verification Database**
- Evidence strength: 3 — Multiple explicit signals: scored card names JDM as a blind spot, used-car-directory idea.md names import origin verification as a high-demand signal, and the scored card notes international markets were not explored. Three distinct corpus points.
- Timing / catalyst: 2 — No specific recent catalyst, but the European used car market has expanded with grey imports as supply tightens post-COVID chip shortage (domain knowledge, partially inferred).
- Founder executable: 2 — Japanese vehicle registration history requires access to Japanese data sources (MLIT, Japanese auction records). Not trivially accessible but APIs exist (e.g., carVertical covers Japanese JDM history). 2-3 months to build a credible product.
- **Total: 7**

---

**Candidate 9 — Car Parts Compatibility Data API**
- Evidence strength: 2 — Scored card explicitly names Teoalida's B2B model (~$500/database) as a blind spot worth exploring. TecDoc incumbent pricing gap is inferred from domain knowledge, not corpus-cited.
- Timing / catalyst: 2 — Right-to-Repair legislation in EU is a real tailwind for independent mechanics (partially inferred, publicly established policy). Gradual, not acute.
- Founder executable: 1 — TecDoc and AUTODATA data is proprietary. Building a parts compatibility database from scratch requires manufacturer data agreements or significant engineering. Not solo-executable in a reasonable timeframe without an existing data supply.
- **Total: 5** — Below threshold. Skipped.

---

### Scoring Table

| Rank | Candidate | Pattern | Evidence | Timing | Executable | Total |
|------|---|---|---|---|---|---|
| 1 | VIN-Based Import History Lookup | 1 | 3 | 2 | 3 | **8** |
| 2 | JDM & Grey Import Verification Database | 5 | 3 | 2 | 2 | **7** |
| 3 | Greek Fleet Compliance Calendar | 4 | 2 | 2 | 3 | **7** |
| 4 | Classic Car Registry & Valuation | 1 | 2 | 2 | 2 | **6** |
| 5 | Dealer Inventory Intelligence API | 2 | 2 | 2 | 2 | **6** |
| 5 | EV Transition Residual Value Tracker | 3 | 1 | 3 | 2 | **6** |
| — | Car Buying Decision Aggregator | 2 | 2 | 1 | 1 | **4** (below threshold) |
| — | Greek Car Enthusiast Forum-Native Classifieds | 4 | 2 | 1 | 2 | **5** (below threshold) |
| — | Car Parts Compatibility Data API | 5 | 2 | 2 | 1 | **5** (below threshold) |

**Top 5 candidates (score ≥6) advancing to seed generation.** Tie at rank 4 broken by evidence strength: Classic Car Registry and Dealer Intelligence API both score 2 on evidence — Classic Car Registry advances due to Pattern 1 (PIVOT-derived, higher conviction demand signal). Dealer Intelligence API is 5th.

---

## Section 4: Evaluator-Ready Seeds

---

## Idea Seed: VIN Import History Verifier

**IDEA_SLUG:** vin-import-history-verifier
**BUSINESS_MODEL:** tool-site
**NICHE_KEYWORDS:** vin lookup greece, car import history, vehicle history check eu, used car verification greece
**DATA_ENTITIES:** VIN records, vehicle registration histories by country, mileage checkpoints, import/export declarations

### Description
A consumer-facing VIN lookup tool for the Greek and EU used car market that verifies a vehicle's import history — specifically: which countries it was previously registered in, odometer readings at registration change points, and whether the seller's claimed import origin (e.g., "Germany-imported") is authentic. Aimed at used car buyers who are paying an import premium and want to verify it before purchase.

### Quick Context
- **Gap:** No Greek-market-specific VIN lookup tool exists that surfaces import country history and mileage consistency — the critical pre-purchase verification data buyers need when paying premium for "German imports."
- **Why it matters:** Greek buyers routinely pay €2,000-5,000 premiums for cars marketed as German-imported; fraud (odometer rollback, misrepresented origin) is a known market problem with no affordable verification tool.
- **Founder fit:** The automotive data layer (car-sale-intelligence, used-car-directory) planned in the ecosystem creates a natural distribution path — VIN lookup is the highest-intent entry point for car buyers.

---

## Idea Seed: JDM & Grey Import Database

**IDEA_SLUG:** jdm-grey-import-database
**BUSINESS_MODEL:** directory
**NICHE_KEYWORDS:** jdm import database europe, grey import car history, japanese vehicle records, jdm vin lookup
**DATA_ENTITIES:** JDM vehicle specs, Japanese registration records, compliance conversion history, import documentation

### Description
A structured database covering JDM (Japanese Domestic Market) and grey import vehicles entering European markets — providing Japanese registration history, authentic mileage from Japanese compulsory inspections (Shaken records), compliance conversion documentation, and European import status. Targeted at enthusiasts, specialist importers, and buyers of high-value JDM vehicles (Nissan Skyline, Toyota Supra, Honda NSX, etc.) where authenticity verification commands significant price premiums.

### Quick Context
- **Gap:** No incumbent database (KBB, Edmunds, AutoScout24) covers JDM import history or Japanese vehicle records — the segment is explicitly excluded from all mainstream platforms and is served only by fragmented specialist forums.
- **Why it matters:** JDM import fraud (mileage rollback, misrepresented condition, incorrect compliance documentation) is a real and costly problem; authentic records can add €5,000-15,000 to a vehicle's value and prevent costly compliance failures.
- **Founder fit:** Car data infrastructure (NHTSA API, third-party databases) is established for the founder; Japanese data (carVertical covers JDM records, Japanese auction records are API-accessible) extends the same data engineering skills already scoped for the automotive ecosystem.

---

## Idea Seed: Greek Fleet Compliance Calendar

**IDEA_SLUG:** greek-fleet-compliance-calendar
**BUSINESS_MODEL:** saas
**NICHE_KEYWORDS:** kteo tracking greece, fleet compliance greece, vehicle insurance expiry tracker, greek fleet management
**DATA_ENTITIES:** Vehicles (per fleet), KTEO inspection dates, insurance policy expiry dates, registration renewal dates, driver assignments

### Description
A lightweight SaaS compliance calendar for SMB fleet operators in Greece — specifically tracking KTEO technical inspection deadlines, insurance expiry dates, and annual registration renewal requirements per vehicle. Designed for rental car companies, corporate fleets, and taxi operators with 5-100 vehicles who currently use spreadsheets and miss compliance deadlines, incurring fines and operational disruption.

### Quick Context
- **Gap:** International fleet management platforms (Fleetio, Samsara) don't model Greek KTEO inspection schedules or Greek insurance regulatory requirements — the compliance calendar gap is explicitly identified in the car-fleet-management brainstorm as the Greek-market differentiator.
- **Why it matters:** Missing a KTEO deadline in Greece means the vehicle cannot legally operate — a direct revenue impact for rental and taxi operators; the current state (spreadsheets, WhatsApp reminders) creates frequent compliance failures.
- **Founder fit:** Extremely low technical complexity — compliance calendar is a CRUD app with notification logic; the Greek regulatory schedule is public and well-documented. Solo MVP feasible in 3-4 weeks.

---

## Idea Seed: Classic Car Registry & Valuation

**IDEA_SLUG:** classic-car-registry-valuation
**BUSINESS_MODEL:** directory
**NICHE_KEYWORDS:** classic car database, pre-1981 car values, vintage car registry, classic car valuation
**DATA_ENTITIES:** Classic vehicles (pre-1981), make/model/year/trim records, auction sale prices, restoration records, provenance documentation

### Description
A structured registry and valuation database for classic and vintage vehicles (pre-1981) — the segment completely excluded from NHTSA's vPIC API and underserved by all major incumbent platforms. The database covers trim levels, factory options, production numbers, and — critically — market valuation derived from auction results (Barrett-Jackson, Mecum, RM Sotheby's) and private sales. Targeted at classic car collectors, restorers, insurers, and estate valuators who need credible values for vehicles that KBB simply doesn't cover.

### Quick Context
- **Gap:** The NHTSA vPIC API that powers most car data products only covers 1981+; pre-1981 vehicles have no equivalent structured database, leaving a well-defined data void that incumbents have not filled despite the classic car market's significant dollar value.
- **Why it matters:** Classic car insurance, estate valuation, and sale transactions all require documented market values — the absence of a structured registry forces reliance on auction house estimates and enthusiast forums, both of which are inconsistent and non-authoritative.
- **Founder fit:** Auction result data is publicly accessible (Barrett-Jackson publishes all results); production record data is available through marque registries and manufacturer archives. Data assembly is achievable but requires domain curation effort.

---

## Idea Seed: Dealer Market Intelligence API

**IDEA_SLUG:** dealer-market-intelligence-api
**BUSINESS_MODEL:** saas
**NICHE_KEYWORDS:** car dealer pricing api greece, used car market data api, dealer inventory intelligence, automotive data api smb
**DATA_ENTITIES:** Vehicle listings (scraped), price histories, time-to-sell data, make/model market benchmarks, dealer profiles

### Description
A B2B data API providing real-time and historical used car market pricing data to SMB car dealers in Greece — enabling accurate trade-in valuation, competitive pricing, and inventory timing decisions. The product follows the Teoalida model (B2B data licensing) but with a modern REST API, daily data freshness from scraped listing portals (Car.gr, Autobazaar), and pricing specifically calibrated to the Greek market rather than generic European tables.

### Quick Context
- **Gap:** EuroTax and DAT are the incumbents for vehicle valuation in Greece but their pricing (€800+/year) and institutional sales process exclude the thousands of SMB dealers who need market intelligence but can't justify enterprise contract overhead.
- **Why it matters:** SMB dealers currently price by gut feel and manual Car.gr browsing — a structured API giving them "what does a 2018 Toyota Yaris sell for and how fast" directly improves their margin and inventory turnover.
- **Founder fit:** The data pipeline for this product is identical to the car-sale-intelligence brainstorm already in the vault — the API product is effectively the B2B monetization layer on top of the same scraping infrastructure.
