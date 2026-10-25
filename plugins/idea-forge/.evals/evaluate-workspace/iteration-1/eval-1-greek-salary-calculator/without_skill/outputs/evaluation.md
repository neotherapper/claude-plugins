# Business Idea Evaluation: Greek Salary Calculator

**Date:** 2026-03-26
**Evaluator:** Claude (default capabilities, no specialized skill)
**Idea:** Greek Salary Calculator — a free tool for Greeks to check market salary rates by job title, experience, and city

---

## 1. Idea Summary

A free, public-facing web tool for Greece where users input:
- Job title
- Years of experience
- City

And receive: estimated market salary range for their profile.

**Monetization:**
- Display advertising
- Premium "personalized salary report" upsell

**Data source:** Job board data (already partially in hand)

---

## 2. Problem Assessment

### Is the problem real?

Yes. Greece has a notoriously opaque labor market. Key characteristics:
- Salaries are rarely posted publicly in Greek job listings (unlike Anglo-Saxon markets)
- Strong cultural taboo around discussing compensation
- Workers frequently accept underpaid roles without benchmarks
- Limited Greek-language resources for salary transparency

This is a genuine, persistent pain point. The problem is not manufactured.

### Who feels this pain most acutely?

- Job seekers preparing for salary negotiation
- Employees wondering if they should switch jobs
- Recent graduates entering the workforce
- HR managers benchmarking their offers (secondary persona)
- Recruiters (potential B2B angle)

---

## 3. Market Assessment

### Market Size

Greece has approximately 4.2 million employed workers (2024 estimate). The addressable digital audience is smaller — perhaps 1.5-2 million Greek internet users who are active job-seekers or salary-curious professionals in any given year. This is a modest but real audience.

### Comparable markets and proxies

Tools like Glassdoor, Levels.fyi, and Payscale dominate English-language markets. In Greece:
- Glassdoor has Greek listings but very sparse data — poor user experience
- Kariera.gr and Skywalker.gr are job boards but do not publish salary benchmarks prominently
- No dedicated Greek salary transparency tool appears to dominate this niche

**The gap is real and the competition is weak in the Greek language.**

### Market dynamics

Greece is a small economy. Ad revenue per user will be modest (Greek CPMs are lower than Western European averages). The market size caps the revenue ceiling unless:
- A premium B2B product is built (e.g., HR benchmarking reports)
- The model is expanded to Cyprus or the Greek diaspora
- It serves as a lead-gen tool into adjacent services (job board, recruiting)

---

## 4. Business Model Assessment

### Revenue Stream 1: Display Advertising

**Verdict: Weak standalone.**

- Typical Greek display CPM: $0.50–$2.00
- Salary tool users are high-intent but visit infrequently (not daily)
- A user checks their salary once, maybe twice a year
- To generate meaningful ad revenue requires very high traffic volume
- Realistic monthly traffic for a niche Greek tool: 10,000–50,000 sessions
- Revenue estimate: $500–$2,500/month at scale. This is pocket money.

Ads can supplement income but cannot be the primary revenue engine.

### Revenue Stream 2: Premium Personalized Report

**Verdict: More promising, but conversion risk.**

- "Get a 10-page personalized salary report" at €9–€19 is a plausible upsell
- Target conversion rate: 2–5% of free users
- At 10,000 monthly users x 3% conversion x €12 = €3,600/month potential
- This scales much better than ads

**Risk:** Greeks tend to be price-sensitive. The report must feel meaningfully different from the free result. What's in the report that justifies payment? This needs a crisp answer.

### Unexplored Revenue Streams (worth considering)

- **B2B salary benchmarking:** Sell anonymized data or reports to HR teams, recruiters, or companies. This is where Glassdoor makes most of its money.
- **Job board integration / affiliate:** Partner with Kariera.gr or similar — refer job-seekers who discover they're underpaid directly to job listings. Affiliate/referral revenue.
- **Recruiter access:** Charge recruiters for access to candidate salary expectations.

---

## 5. Competitive Advantage Assessment

### Data moat

The founder mentions having "some data from job boards." This is the single most important asset.

**Key questions:**
1. How much data? A few hundred rows or tens of thousands?
2. How was it collected — scraped, licensed, or manual?
3. Is it recent (2024-2025) and refreshed regularly?
4. Does it have salary ranges, or just job postings without salaries?

A salary tool with thin data will give wide, unhelpful ranges and lose user trust instantly. The data quality question is make-or-break.

### Network effects

Salary tools benefit from a slow-building network effect: more submissions = more accurate data = more trust = more users = more submissions. Getting this flywheel started is hard. Consider adding a "contribute your salary" feature to supplement job board data with crowdsourced input.

### Technical barrier

Low. A salary calculator is not technically complex. Anyone with dev skills can build it. The defensibility comes entirely from data quality, brand trust, and SEO — not from technology.

---

## 6. Execution Assessment

### What needs to be built (MVP)

1. Clean data pipeline from job boards → salary database
2. Simple search UI (job title autocomplete, city dropdown, experience slider)
3. Results page with salary range visualization
4. Basic SEO optimization (Greek-language, long-tail queries)
5. Ad integration (Google AdSense or similar)
6. Email capture for premium report funnel

**Time estimate:** 4–8 weeks for a solo developer to build an MVP.

### What makes it hard

- Data cleaning: Job board data is messy. Normalizing job titles across listings is non-trivial.
- Data sparsity: Greece has fewer listings than large markets. Some job/city combinations will have no data.
- Trust: Users won't trust results that look made up. Transparency about sample sizes is essential.
- SEO competition: Glassdoor and LinkedIn rank for salary queries even in Greek. Winning requires dedicated Greek-language SEO work.

### Founder fit

The founder has job board data (a real asset) and is asking the right early questions. This suggests someone practical and resourceful. The idea benefits from being a focused, scope-limited product — good for a small team or solo builder.

---

## 7. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Data is too sparse to give credible results | High | Supplement with crowdsourcing from day one |
| Low ad CPMs make ads unviable | Medium | Prioritize premium report and B2B angles |
| Glassdoor/LinkedIn improve Greek data | Medium | Double down on local trust, language, and UX |
| Legal issues with scraped job board data | Medium-High | Review ToS of data sources; consider licensing deals |
| User churn (one-visit use case) | High | Build email list, create "salary alerts" to retain users |

---

## 8. Strategic Recommendations

### Short term (0–3 months)

1. **Validate data quality first.** Before building anything, spend a week cleaning and analyzing the job board data. Can you produce a credible salary range for the 20 most common job titles in Athens? If yes, proceed. If the data is too thin, you need to solve that first.
2. **Build a landing page with a waitlist.** Gauge demand before full build. A simple "Enter your job title and city and we'll email you the market rate" page can validate interest in weeks.
3. **Add crowdsourcing from launch.** A "Submit your salary anonymously" feature turns users into contributors and builds the data moat.

### Medium term (3–12 months)

4. **Prioritize SEO aggressively.** Target Greek-language queries like "μισθός λογιστής Αθήνα" (accountant salary Athens). These queries have low competition and high intent.
5. **Test the premium report conversion.** A/B test pricing (€7, €12, €19) and report formats. What do users actually want that justifies payment?
6. **Explore B2B.** Reach out to 5 Greek HR managers or recruiters. Would they pay for a salary benchmarking subscription? This could be 10x more valuable than ad revenue.

### Long term (12+ months)

7. **Consider expanding to Cyprus or diaspora communities** if Greek market revenue plateaus.
8. **Position as acquisition target** for a Greek job board (Kariera.gr, e-Go, Skywalker) — they would benefit from salary transparency features.

---

## 9. Overall Verdict

**CONDITIONAL GO**

This is a legitimate, unfilled niche with a real user pain. The idea is small enough to execute quickly and doesn't require significant capital. The core challenge is not building — it's data quality and monetization ceiling.

**Pursue if:**
- The existing job board data can produce credible salary ranges for at least 30-50 job titles across major Greek cities
- The founder is willing to invest in SEO and community-building (not just build and wait)
- The premium report or B2B angle is treated as the primary revenue path, with ads as supplementary

**Do not pursue if:**
- The data is too sparse (fewer than 5 data points per job/city combination on average)
- The founder expects ad revenue alone to sustain the project
- There is no plan for data freshness — stale salary data destroys trust

**Estimated revenue ceiling (optimistic, 12-month horizon):**
- Ads: €500–€2,000/month
- Premium reports: €2,000–€5,000/month
- B2B (if pursued): €1,000–€5,000/month
- **Total realistic range: €3,500–€12,000/month**

This is a solid side project or a lifestyle business. It is not a venture-scale opportunity unless it expands beyond Greece significantly.

---

## 10. Score Summary

| Dimension | Score (1-5) | Notes |
|-----------|-------------|-------|
| Problem clarity | 5/5 | Clear, real, documented pain |
| Market size | 2/5 | Small country, modest addressable market |
| Monetization | 3/5 | Ads weak; premium + B2B viable |
| Competitive advantage | 3/5 | Data moat if cultivated, otherwise weak |
| Execution complexity | 4/5 | Technically simple, data is the hard part |
| Founder fit signal | 4/5 | Has data asset, asking right questions |
| **Overall** | **3.5/5** | **Conditional go — worth a focused 4-week MVP test** |

---

*Evaluation method: Default reasoning, no specialized framework applied.*
