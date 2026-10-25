# Idea Evaluation: Greek Salary Calculator

**Evaluator:** Claude Sonnet 4.6 (no skill, baseline reasoning)
**Date:** 2026-03-27
**Verdict:** PURSUE WITH CAUTION

---

## Idea Summary

A free web tool for Greek workers to benchmark their salary against market rates by entering job title, years of experience, and city. Revenue through display ads and a premium personalized salary report upsell. Founder has some job board data as a starting point.

---

## Overall Score: 52 / 100

**Verdict: Marginal — Addressable but structurally constrained. Worth a small, fast experiment before committing.**

---

## Criterion-by-Criterion Evaluation

### 1. Problem Clarity (8/10)

The problem is real and well-defined. Greece has one of the most opaque salary markets in the EU — collective agreements (ΕΣΣΕ) set floors but rarely reflect actual employer pay, and cultural taboos around discussing compensation compound the opacity. Workers genuinely don't know if they're underpaid. The Jobs-to-Be-Done is clear: "When I'm evaluating a job offer or preparing for a performance review, help me know whether my salary is competitive so I can negotiate confidently."

Score deduction: The problem is real but not urgent in a way that drives daily or weekly return visits. Salary benchmarking is a point-in-time need, not a recurring engagement loop.

---

### 2. Market Size (5/10)

Greece's employed workforce is approximately 3.9 million people (2025 estimate). The realistic addressable audience for a digital salary tool skews toward white-collar, educated, urban workers — roughly 800,000–1.2 million people. This is a small market by global SaaS standards.

For an ad-monetized product: if 5% of the addressable audience visits per year (40,000–60,000 sessions/year), and average RPM is €1.50–€3.00 (Greek ad market is low-yield), annual ad revenue is roughly €60–€180. That is not a business.

To generate meaningful ad revenue (e.g., €10k/year) you would need ~500,000–700,000 annual sessions, which implies a far larger share of the workforce or significant organic SEO dominance — achievable in theory, but hard given the data limitations (see below).

**The market size is viable for a side project or lead-gen asset, not a standalone business.**

---

### 3. Monetization Model (4/10)

**Ads:** Structurally weak for this use case. Greek CPMs are low (€0.5–€2 for general content, slightly better for finance/career content). The use case is high-intent but low-frequency. Users visit once, get their answer, leave. Repeat visits are rare without a strong content strategy. Ads will underperform.

**Premium Report:** More promising conceptually, but faces the classic chicken-and-egg credibility problem — users will only pay for a report if they trust the underlying data is accurate and comprehensive. If the dataset is thin (job board scraping covers only publicly listed roles, which skews toward lower-paying positions and misses senior/specialist roles), the premium report may not deliver enough differentiation to justify payment. Greek consumers are also price-sensitive and accustomed to free information.

**Alternatives not considered by the founder:**
- B2B HR/recruitment tool (sell to companies that want to post salary-transparent listings)
- Affiliate partnerships with job boards (Kariera.gr, LinkedIn, Indeed Greece)
- Recruitment agency partnerships (agencies pay for data or referrals)
- Career coaching upsell

The B2B angle is significantly more monetizable than B2C ads for a small-market data product.

---

### 4. Data Moat & Feasibility (5/10)

This is the central tension of the idea. Salary data quality determines whether the product is useful or a misleading toy.

**Job board data limitations:**
- Only covers roles explicitly advertised (excludes internal promotions, referral hires)
- Greek job boards (Kariera.gr, e-Go, Indeed Greece) often omit salary from listings — Greece has one of the highest rates of "salary not disclosed" listings in the EU
- Data skews toward entry/mid-level roles; senior and executive compensation is largely invisible
- Job title standardization is poor (Greek employers use inconsistent titles)

**Building a real data moat requires:**
- User-submitted salary data (like Glassdoor/Levels.fyi model) — requires cold-start critical mass
- Partnerships with payroll providers or HR platforms
- Continuous data refresh

The founder's existing job board data is a starting point but is likely insufficient for trustworthy benchmarks across job titles and cities. Athens will have decent coverage; Thessaloniki will be thin; other cities will be unreliable.

---

### 5. Competition (6/10)

**Direct competitors in Greece:**
- **Kariera.gr** has basic salary survey data embedded in the platform — low quality, infrequently updated, but it exists
- **LinkedIn Salary Insights** — available to Premium subscribers, covers Greece but with limited data points for Greek-specific roles
- **Glassdoor** — covers Greece but with very sparse Greek company data
- **PayScale / Salary.com** — minimal Greece coverage

**The gap is real:** None of these provide a Greece-first, Greek-language, granular salary benchmarking experience. There is a legitimate whitespace.

**Risk:** The gap exists partly because the market is small and the data is hard to collect. The absence of a strong competitor is not always market opportunity — sometimes it signals that the unit economics don't support the product.

---

### 6. Founder-Market Fit (Unknown — 5/10 assumed)

The founder has "some data from job boards" which suggests technical capability to collect and process data. No other founder-specific context was provided. Score is neutral.

**What would increase confidence:** Domain expertise in HR/recruitment, existing relationships with Greek employers, or a large existing audience (e.g., a career-focused newsletter or community).

---

### 7. Distribution & Growth (4/10)

**SEO potential:** Moderate. Queries like "μισθός μηχανικός Αθήνα" (salary engineer Athens) have real search volume and low competition. A well-structured tool with individual landing pages per job title/city could rank. However, Greek-language SEO has a smaller total search volume, and Google's AI Overviews may increasingly answer simple salary queries directly.

**Viral/social:** Low. Salary discussions remain somewhat taboo in Greek professional culture, limiting organic sharing. Tools like this don't naturally generate "share with friends" behavior.

**Community:** Greek professional communities on LinkedIn and Facebook groups are active. A well-targeted launch to these communities (e.g., "Τι μισθό παίρνεις;" groups) could generate initial traffic.

**Retention:** Very low. No reason to return unless actively job-searching or reviewing compensation. A newsletter or regular content layer (salary trend reports, industry analysis) would be needed to build an engaged audience.

---

### 8. Execution Complexity (7/10 — favorable)

This is a content/data product, not a complex SaaS. Core MVP is:
- Data normalization pipeline (job title → standardized category, salary cleaning)
- Simple web interface with filters
- Results page with percentile visualization

A React/TypeScript developer (aligned with founder profile) can build the frontend in a weekend. The data pipeline is the real work. Time to MVP: 2–4 weeks if data is already collected.

**No backend complexity, no auth required for free tier, no real-time requirements.** This is genuinely low-effort to launch.

---

### 9. Business Model Sustainability (4/10)

The core problem: salary data is not evergreen. It requires continuous collection and refresh to remain trustworthy. A one-time job board scrape will become stale within 6–12 months, at which point the tool becomes actively misleading.

Sustaining the data requires:
- Ongoing scraping and data maintenance
- Or user-submitted data (requires sustained traffic and trust)

Without a revenue model that funds data refresh, the product degrades over time. The ad model likely won't generate enough to justify ongoing maintenance.

---

### 10. Strategic Optionality (6/10)

If the product gains traction, there are legitimate adjacent moves:
- Expand to job board integration (show salary-transparent listings)
- Build a community around salary transparency (newsletter, annual salary survey)
- Pivot to B2B: sell anonymized benchmarking data to HR teams or recruiters
- Become a broader "career toolkit" for Greek professionals (CV templates, interview prep)

The B2B pivot is the most viable exit from the structural constraints of B2C ads. If the founder can collect enough user-submitted data to have a defensible dataset, selling access to that data to Greek HR teams and recruitment agencies is a more realistic revenue path than ads.

---

## Competitor Landscape Summary

| Tool | Coverage | Quality | Greece-Specific |
|---|---|---|---|
| Kariera.gr salary data | Limited | Low | Yes |
| LinkedIn Salary | Moderate | Medium | Partial |
| Glassdoor | Sparse | Medium | No |
| PayScale | Very sparse | Low | No |
| **Proposed tool** | Job board scrapes | Unproven | Yes |

The whitespace is real but fragile.

---

## Business Foundation Assessment

**Strengths:**
- Genuine, validated user pain (salary opacity in Greece is a documented problem)
- Low technical complexity for MVP
- Clear SEO distribution path
- Real whitespace in the market

**Weaknesses:**
- Small addressable market by revenue standards
- Ad monetization structurally weak for low-frequency use cases
- Data quality is the core product risk — existing job board data is an insufficient moat
- No natural retention loop without significant content investment
- Premium report upsell requires data credibility that must be earned, not assumed

**The central question the founder must answer before building:**
"Do I have enough salary data to give answers that are genuinely more accurate and trustworthy than what users can piece together from LinkedIn and Kariera.gr?"

If the answer is yes (or will be yes after 2–4 weeks of data work), the MVP is worth launching as a low-cost experiment. If the answer is "not really, but I'll improve it over time," the risk is that early users find the tool unreliable and the SEO/word-of-mouth case collapses before data improves.

---

## Recommendation

**Build a lean MVP in 2–3 weeks, but design the experiment correctly:**

1. Focus on 3–5 high-volume job categories where you have sufficient data (e.g., software engineers, accountants, nurses, teachers, sales reps in Athens)
2. Be honest about confidence intervals — show sample size and data freshness, don't fake precision you don't have
3. Add a user-submitted salary form from day one — this is how you build the data moat
4. Measure whether users trust the results (NPS prompt, return visits, time on page)
5. Only invest in the premium report feature if the free tool generates 1,000+ monthly active users within 3 months

**Do NOT pursue if:**
- Your job board data covers fewer than 500 data points per major job category
- You are expecting ad revenue to justify the work within 12 months
- You are not willing to build the user-submission flywheel

**Consider pivoting to B2B first if:**
- You can sign 2–3 Greek recruitment agencies or HR teams willing to pay €50–€200/month for salary benchmarking access before you build anything

---

## Final Scores

| Criterion | Score |
|---|---|
| Problem Clarity | 8/10 |
| Market Size | 5/10 |
| Monetization Model | 4/10 |
| Data Moat & Feasibility | 5/10 |
| Competition | 6/10 |
| Founder-Market Fit | 5/10 |
| Distribution & Growth | 4/10 |
| Execution Complexity | 7/10 |
| Business Model Sustainability | 4/10 |
| Strategic Optionality | 6/10 |
| **TOTAL** | **52/100** |

**Verdict: PURSUE WITH CAUTION — Low-cost MVP worth running as an experiment, but the current monetization model (ads + premium report) is unlikely to generate sustainable revenue without a B2B pivot or a significant user-submitted data flywheel. The idea is not worth killing outright; it is worth a constrained 3-week test.**
