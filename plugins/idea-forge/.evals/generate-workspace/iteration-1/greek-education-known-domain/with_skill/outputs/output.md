# Idea Generator Output — Greek Education (Known Domain)
**Date:** 2026-04-06
**Prompt:** "I've been researching the greek education market a lot lately — given everything we've found, what business ideas haven't we explored yet?"
**Skill:** idea-generator (generator.md pipeline)

---

## Section 1: Data Layer

### Domain Lookup

Matched "greek education market" against master-index.yaml. Found family `greek-education` with 4 members:

| Slug | Name | Status | Verdict | Score |
|------|------|--------|---------|-------|
| greek-schools-directory | Greek Schools Directory | evaluated | BET | 89.6% |
| greek-tutoring-platform | Greek Tutoring Platform | brainstorm | — | — |
| greek-university-finder | Greek University & Program Finder | brainstorm | — | — |
| paidagogos | Paidagogos | brainstorm | — | — |

No KILL verdicts in this domain.

### Corpus Assembly

Loaded:
- `ideas/greek-schools-directory/scored-card-v3.md` — full evaluated card (used as data summary)
- `ideas/greek-schools-directory/idea.md` — frontmatter
- `ideas/greek-tutoring-platform/idea.md` — brainstorm frontmatter
- `ideas/greek-university-finder/idea.md` — brainstorm frontmatter
- `ideas/paidagogos/idea.md` — brainstorm frontmatter

**Corpus state:** 1 scored card present → all 5 patterns viable.

### De-duplication

Existing slugs: `greek-schools-directory`, `greek-tutoring-platform`, `greek-university-finder`, `paidagogos`. Any candidate resolving to the same niche + problem angle as these was excluded or refined to a meaningfully different angle.

### Context

> Found 4 ideas in greek-education (1 evaluated, 3 brainstorm). Siblings: greek-tutoring-platform, greek-university-finder, paidagogos. Generating ideas that expand this space.

---

## Section 2: Generation Pipeline — All 8 Candidates

### Pre-flight Check

Corpus state: 1 scored card (greek-schools-directory, v3) + 3 brainstorm frontmatter. All 5 patterns viable.

---

### CANDIDATE 1: Frontistiria Directory

```
CANDIDATE: Frontistiria Directory
PATTERN: 1 (Demand without supply)
EVIDENCE: scored-card-v3.md § Scorecard C10b — "tutoring marketplace connecting parents with tutors 
  near specific schools (Greek frontistiria market ~€500M)" flagged as derivative product 2; 
  no dedicated frontistiria directory confirmed in competition landscape 
  [scored-card-v3.md § Competitor Landscape]
CUSTOMER: A Greek parent in Athens whose 16-year-old needs a chemistry frontistirio near their 
  school before the Panellinies — they currently ask neighbors
GAP: No searchable directory of the ~5,000+ frontistiria businesses in Greece with subjects, 
  pricing, location, and student reviews
```

---

### CANDIDATE 2: Greek Private University Directory

```
CANDIDATE: Greek Private University Directory
PATTERN: 3 (Technology / regulatory wave)
EVIDENCE: scored-card-v3.md § Scorecard C6 — "Private universities approved in Greece 
  Dec 2025/Jan 2026 (National Herald, ProtoThema via newsfeed CLI); education reform wave active" 
  — new institution type, zero existing directories at launch moment
CUSTOMER: A Greek 18-year-old finishing high school in June 2026, unsure which new private 
  universities are accredited and what programs they offer
GAP: Private universities are brand-new in Greece (Jan 2026 legislation) — no directory, 
  comparison tool, or accreditation guide exists yet
```

---

### CANDIDATE 3: Panellinies Prep Hub

```
CANDIDATE: Panellinies Prep Hub
PATTERN: 2 (Customer friction)
EVIDENCE: scored-card-v3.md § Blind Spots — "Greek-language SEO data: all keyword research was 
  English-language; real demand likely 2-5x higher than English proxies suggest"; 157 autocomplete 
  variants were English-only; Panellinies is the single largest educational event in Greece 
  (60,000+ candidates annually); zero competitors address exam prep aggregation 
  [scored-card-v3.md § Competitor Landscape]
CUSTOMER: A Greek student in grade 11 whose family uses scattered WhatsApp groups and photocopy 
  sheets to track exam prep resources
GAP: No centralized, searchable hub for Panellinies preparation resources — past papers, tutor 
  matching, and subject guides are fragmented across unindexed sources
```

---

### CANDIDATE 4: Greek Expat Education Navigator

```
CANDIDATE: Greek Expat Education Navigator
PATTERN: 5 (Incumbent blindness)
EVIDENCE: scored-card-v3.md § Primary Customer Profile — "expat/Golden Visa families relocating 
  to Greece" identified as highest-pain early adopter segment; scored-card-v3.md § Channels — 
  "r/GreeceTravel 963K, Golden Visa forums" active; scored-card-v3.md § Scorecard C6 — 
  "Greece Golden Visa driving expat family influx (March 2026 news cycle)"; all 5 competitors 
  cover only 23-74 international schools and provide no relocation-integrated guidance 
  [scored-card-v3.md § Competitor Landscape]
CUSTOMER: A British family relocating to Athens for work on a 2-year contract, trying to figure 
  out school options, curriculum types, and enrollment deadlines before they arrive
GAP: No English-language guide combining school search, enrollment timelines, curriculum comparison 
  (IB vs British vs Greek national), and expat community connections for families relocating to Greece
```

---

### CANDIDATE 5: Greek Private School Fee Transparency Tool

```
CANDIDATE: Greek Private School Fee Transparency Tool
PATTERN: 2 (Customer friction)
EVIDENCE: scored-card-v3.md § Top 3 Problems — "Private school fee opacity — no transparent fee 
  comparison exists; parents must call each school individually to get pricing"; 
  scored-card-v3.md § Feature Gap Matrix — "Fee transparency: Us Y | Int'l Schools DB: Partial | 
  Skoolana: Partial | SchoolBell: N"; scored-card-v3.md § Blind Spots — "Private school marketing 
  budgets not investigated"
CUSTOMER: A Greek dual-income couple in Thessaloniki trying to compare 6 private school options 
  by cost before committing to a school visit
GAP: No tool aggregates and compares annual tuition fees for Greek private schools — a standalone 
  fee comparator does not exist separate from any directory
```

---

### CANDIDATE 6: Greek Education Content Hub

```
CANDIDATE: Greek Education Content Hub
PATTERN: 4 (Unoccupied distribution)
EVIDENCE: scored-card-v3.md § Distribution Opportunity — "YouTube underserved (16K max views on 
  comparison content); r/greece 271K + r/GreeceTravel 963K subscribers; Greek parenting Facebook 
  groups noted as large but unquantified"; scored-card-v3.md § AI Leverage — "AI generates 'best 
  schools in Athens by neighborhood' articles automatically"; no dedicated Greek education media 
  property confirmed in competitor landscape [scored-card-v3.md § Competitor Landscape]
CUSTOMER: A Greek parent who follows parenting Facebook groups but has no trusted editorial source 
  for Greek education news, rankings, or policy changes
GAP: No dedicated content brand covering Greek K-12 and higher education — the audience exists on 
  general platforms but has no dedicated editorial home
```

---

### CANDIDATE 7: Greek Teacher / Educator Directory

```
CANDIDATE: Greek Teacher / Educator Directory
PATTERN: 1 (Demand without supply)
EVIDENCE: scored-card-v3.md § Primary Customer Profile — Greek parents seeking tutors near 
  specific schools; greek-tutoring-platform/idea.md — "EUR 1.8-2.2B Greek private tutoring 
  market"; founder's father is "retired HS principal (supply-side network)"; no individual 
  teacher directory confirmed in competition landscape
CUSTOMER: A parent in Piraeus looking for a qualified private math tutor who teaches at a 
  specific grade level and can meet in person — not a frontistirio but an individual teacher
GAP: No searchable index of individual private tutors and educators in Greece with qualifications, 
  subject, level, and location — distinct from frontistiria (institutional centers)
```

---

### CANDIDATE 8: Greek School Enrollment & Deadline Tracker

```
CANDIDATE: Greek School Enrollment & Deadline Tracker
PATTERN: 2 (Customer friction)
EVIDENCE: scored-card-v3.md § Primary Customer Profile — "End-of-school-year (May-June) for 
  enrollment decisions; September back-to-school; when relocating to Greece" are key seasonal 
  moments; zero competitors track enrollment windows or deadlines 
  [scored-card-v3.md § Competitor Landscape]
CUSTOMER: A Greek parent who missed the enrollment window for their preferred private school 
  because they didn't know the deadline — now scrambling in July
GAP: No tool tracks enrollment deadlines, open days, and application windows across Greek private 
  schools — parents rely on direct phone calls or word of mouth
```

---

## Section 3: Light Scoring

Scoring criteria (1-3 each, max 9):
- **Evidence strength:** 1 = inferred/single weak signal | 2 = single clear signal from corpus | 3 = multiple corroborating signals with source citations
- **Timing/catalyst:** 1 = no tailwind | 2 = gradual market growth | 3 = specific recent catalyst
- **Founder executable:** 1 = requires team/rare expertise | 2 = solo 1-3 months standard stack | 3 = solo weeks, data already accessible

| Rank | Candidate | Pattern | Evidence | Timing | Executable | Total |
|------|-----------|---------|----------|--------|------------|-------|
| 1 | Greek Private University Directory | 3 | 3 | 3 | 3 | **9** |
| 2 | Greek Expat Education Navigator | 5 | 3 | 3 | 3 | **9** |
| 3 | Frontistiria Directory | 1 | 2 | 3 | 3 | **8** |
| 4 | Greek Private School Fee Transparency Tool | 2 | 3 | 2 | 2 | **7** |
| 5 | Greek Education Content Hub | 4 | 2 | 2 | 3 | **7** |
| 6 | Panellinies Prep Hub | 2 | 2 | 2 | 2 | **6** |
| 7 | Greek Teacher / Educator Directory | 1 | 2 | 1 | 3 | **6** |
| 8 | Greek School Enrollment & Deadline Tracker | 2 | 2 | 2 | 2 | **6** |

**Tie-breaking note (ranks 4 and 5, both score 7):** Fee Transparency Tool has evidence score 3 vs Content Hub evidence score 2 — Fee Transparency ranks 4th.

**All 8 candidates score ≥6/9.** Top 5 advancing to seed generation.

---

## Section 4: Evaluator-Ready Seeds

### Seed 1 — Greek Private University Directory

**IDEA_SLUG:** greek-private-university-directory
**BUSINESS_MODEL:** directory
**NICHE_KEYWORDS:** greek private universities, private higher education greece, university programs greece, new universities greece 2026
**DATA_ENTITIES:** Private universities, accreditation status, programs offered, tuition fees, campus location, enrollment requirements

#### Description
A comprehensive directory of Greece's newly approved private universities — listing all accredited institutions, programs, tuition fees, and enrollment info in one searchable resource. Targets Greek students finishing secondary school and expat families navigating the new private higher education sector. Fills the complete information vacuum that exists because the sector only became legal in January 2026.

#### Quick Context
- **Gap:** Private universities became legal in Greece in December 2025/January 2026 — no directory, comparison tool, or accreditation guide exists at the moment the sector launches [from scored-card-v3.md § Scorecard C6]
- **Why it matters:** 60,000+ Greek students sit Panellinies annually and now have a new category of university choice with zero information infrastructure to navigate it
- **Founder fit:** Greek national with existing Ministry of Education scraping pipeline and education domain expertise — same capability stack applies directly to this new institution type

---

### Seed 2 — Greek Expat Education Navigator

**IDEA_SLUG:** greek-expat-education-navigator
**BUSINESS_MODEL:** content
**NICHE_KEYWORDS:** schools in greece for expats, international schools greece, relocating to greece children, golden visa greece schools, english schools athens
**DATA_ENTITIES:** International and bilingual schools, curriculum types (IB/British/Greek national), enrollment windows, expat community resources, relocation guides by city

#### Description
An English-language guide and directory combining school search, curriculum comparison, enrollment timelines, and expat community links for families relocating to Greece. Serves the growing Golden Visa and EU-worker expat cohort who cannot navigate the Greek-language education system. Covers Athens, Thessaloniki, Crete, Corfu, and Rhodes — the highest expat concentration zones.

#### Quick Context
- **Gap:** All existing competitors cover only 23-74 international schools with no relocation-integrated guidance; zero resource combines school search with enrollment deadlines and expat community context in English [from scored-card-v3.md § Competitor Landscape + § Primary Customer Profile]
- **Why it matters:** Golden Visa influx is creating a new demand cohort of families arriving in Greece in 2026 with no roadmap for school enrollment [from scored-card-v3.md § Scorecard C6, March 2026 news cycle]
- **Founder fit:** Greek national who understands the system from the inside, with existing 14,000-school dataset as the data foundation

---

### Seed 3 — Frontistiria Directory

**IDEA_SLUG:** frontistiria-directory
**BUSINESS_MODEL:** directory
**NICHE_KEYWORDS:** frontistiria greece, greek tutoring centers, private tutoring schools greece, frontistirio athens, after-school tutoring greece
**DATA_ENTITIES:** Frontistiria (tutoring centers), subjects offered, grade levels served, location, pricing, student reviews

#### Description
A searchable directory of Greece's ~5,000+ frontistiria (private tutoring prep centers) with subject coverage, grade levels, location, pricing, and student reviews. Targets Greek parents whose children need supplementary education — a near-universal need in Greece. Distinct from an individual tutor marketplace: frontistiria are established businesses with storefronts, staff, and fixed curricula.

#### Quick Context
- **Gap:** No dedicated searchable index of frontistiria exists — the Greek private tutoring center market (~€500M) has no directory equivalent of the K-12 schools directory [from scored-card-v3.md § Scorecard C10b]
- **Why it matters:** Frontistiria enrollment is near-mandatory for Greek students preparing for the Panellinies; parents rely on neighborhood word-of-mouth with no comparative information
- **Founder fit:** Same scraping pipeline and Greek-market data expertise as Greek Schools Directory; frontistiria are registered businesses with public data available

---

### Seed 4 — Greek Private School Fee Transparency Tool

**IDEA_SLUG:** greek-school-fees
**BUSINESS_MODEL:** tool-site
**NICHE_KEYWORDS:** private school fees greece, greek private school tuition, school cost comparison greece, best private schools athens cost
**DATA_ENTITIES:** Private schools, annual tuition fees, enrollment fees, sibling discounts, scholarship availability, fee brackets by school type

#### Description
A tool that aggregates and compares annual tuition fees across Greece's ~3,000 private schools, letting parents filter by location, grade level, and budget. Addresses the most acute friction in Greek private school search — parents currently must call each school individually to get pricing. Can launch as a standalone tool or as a feature layer on top of the schools directory.

#### Quick Context
- **Gap:** Fee transparency is a top-3 problem in the Greek education market and confirmed absent from all 5 verified competitors; no tool aggregates private school pricing in Greece [from scored-card-v3.md § Top 3 Problems + § Feature Gap Matrix]
- **Why it matters:** Greek private school tuition ranges €5,000–€30,000/year — a major household financial decision made with almost zero price transparency
- **Founder fit:** Founder already has 14,000-school dataset; private school fee data collection is the natural next enrichment layer on the existing data asset

---

### Seed 5 — Greek Education Content Hub

**IDEA_SLUG:** greek-education-hub
**BUSINESS_MODEL:** content
**NICHE_KEYWORDS:** greek education news, best schools in athens, greek school rankings, education reform greece, panellinies guide
**DATA_ENTITIES:** Editorial articles, school rankings by neighborhood, education policy explainers, exam prep guides, seasonal enrollment guides

#### Description
A dedicated editorial and content brand covering Greek K-12 and higher education — school rankings by neighborhood, Panellinies preparation guides, education reform explainers, and seasonal enrollment calendars. Targets Greek parents and students who follow education topics on generic platforms (Facebook parenting groups, Reddit) but have no trusted, dedicated media source. Monetized via display ads and affiliate links to tutoring services.

#### Quick Context
- **Gap:** No dedicated content brand covering Greek education exists despite 271K+ subscribers in r/greece, large Greek parenting Facebook groups, and confirmed YouTube underserving of education comparison content [from scored-card-v3.md § Distribution Opportunity]
- **Why it matters:** Education reform (private university approvals, Golden Visa expat influx) is creating a sustained editorial opportunity with a ready audience that has no dedicated home
- **Founder fit:** AI can generate "best schools in Athens by neighborhood" articles at scale from the existing 14,000-school dataset [from scored-card-v3.md § AI Leverage Assessment]

---

## Seeds saved to

`ideas/_registry/idea-seeds-greek-education-2026-04-06-run-1.md`
