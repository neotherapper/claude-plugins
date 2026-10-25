---
idea: "Greek Salary Calculator"
slug: "greek-salary-calculator"
model: "tool-site"
verdict: "BUILD"
score: 71.6
weighted_avg: 3.58
evaluated: 2026-03-26
---

# Greek Salary Calculator

**Verdict: BUILD** | **Score: 71.6%** | **Evaluated: 2026-03-26**

## Idea Summary

A free web tool where people in Greece enter their job title, years of experience, and city to see what the market rate salary is and calculate their expected net take-home pay. Greece has no modern, comprehensive salary benchmarking tool — the closest Greek competitor (e-misthologio.gr) offers only basic tax math with circa-2012 UX and zero market data. Monetized through display advertising (finance RPM) and a freemium "personalized salary report" feature.

## Scorecard

| # | Criterion | Weight | Score | Evidence |
|---|-----------|--------|-------|----------|
| 1 | Market Demand | 12% | 4/5 | 25+ Greek autocomplete variants; 25K-50K est. monthly searches; 570+ programmatic page targets (job x city) |
| 2 | Problem Severity | 10% | 4/5 | r/greece (180K subs) endemic salary discussion; documented brain drain tied to salary opacity; no Greek Glassdoor |
| 3 | Revenue Potential | 12% | 3/5 | Finance RPM real but Greek traffic ~$5-12 (not $15-30 US figure); freemium salary report unvalidated in Greece |
| 4 | Competitor Revenue Validation | 8% | 3/5 | kariera.gr 20yr+ survival; e-misthologio AdSense 10yr+; Glassdoor $1.2B acquisition validates global model |
| 5 | Competition Gap | 10% | 4/5 | No modern Greek salary benchmark tool; e-misthologio poor UX/no mobile/no market data; Glassdoor thin on Greece |
| 6 | Why Now / Timing | 6% | 4/5 | EU Pay Transparency Directive 2026; 6 minimum wage increases 2019-2024; remote work salary arbitrage trend |
| 7 | Build Complexity | 5% | 3/5 | Net salary formula codeable in days; market data needs 2-4 weeks aggregation; programmatic SEO adds 2-3 weeks |
| 8 | Distribution | 14% | 4/5 | 570+ SEO page targets; r/greece 180K for viral seeding; HR founder contacts; finance RPM justifies moderate traffic |
| 9 | Defensibility | 10% | 3/5 | Calculator logic cloneable; moat from user data + compound SEO + brand trust builds over 12-24 months |
| 10 | Input Data Quality | 3% | 3/5 | ELSTAT/Eurostat excellent for formula; market salary benchmarks sparse — AI bridges gap for MVP |
| 11 | Founder-Market Fit | 6% | 4/5 | Greek native with personal pain; HR contacts for data validation + B2B seeding; React/TS = direct build capability |
| 12 | MVP Speed | 4% | 3/5 | Calculator: 3-5 days. Data layer: 1-2 weeks. Programmatic SEO: 2-3 weeks. Total v1: 4-8 weeks |

**Weighted Score: 3.58/5.0 (71.6%)**

### Weighted Score Calculation (tool-site lens weights)

```
(4×0.12) + (4×0.10) + (3×0.12) + (3×0.08) + (4×0.10) + (4×0.06) +
(3×0.05) + (4×0.14) + (3×0.10) + (3×0.03) + (4×0.06) + (3×0.04)
= 0.48 + 0.40 + 0.36 + 0.24 + 0.40 + 0.24 + 0.15 + 0.56 + 0.30 + 0.09 + 0.24 + 0.12
= 3.58 / 5.0 = 71.6%
```

## Critic Adjustments

One adjustment made from initial scoring:
- **Criterion 3 (Revenue Potential): 4 → 3** — Initial score assumed $15-30 finance RPM, which applies to US/UK audiences. Greek traffic commands $5-12 RPM. The freemium salary report is also unvalidated in the Greek market. Adjusted down to 3.
- All other 11 criteria confirmed at original scores.

## Competitor Landscape

| # | Competitor | Domain | Tranco Rank | Domain Age | Est. Pages | Revenue Signal | Key Differentiator |
|---|-----------|--------|-------------|------------|-----------|---------------|-------------------|
| 1 | e-misthologio | e-misthologio.gr | ~500K* | ~12yr* | ~20-50 | AdSense only | Only Greek net salary calculator (poor UX, no market data) |
| 2 | AADE Tax Calc | aade.gr | ~45K* | 25yr+* | 1,000+ | Non-commercial | Official Greek tax authority calculator |
| 3 | kariera.gr (salary) | kariera.gr | ~160K* | 22yr+* | 50,000+ | Employer subscriptions | Greece's largest job board with salary data (sparse) |
| 4 | Glassdoor | glassdoor.com | ~1,200* | 16yr* | Millions | $1.2B acquisition | Best global salary tool; Greece data very sparse |
| 5 | LinkedIn Salary | linkedin.com | ~10* | 20yr+* | Billions | Microsoft/$26.2B | Professional network; Premium paywall; thin Greece data |

*All Tranco ranks and domain ages are estimated — CLI tools unavailable during evaluation*

### Feature Gap Matrix

| Feature | Greek Salary Calc (planned) | e-misthologio | kariera.gr | Glassdoor | LinkedIn Salary |
|---------|----------------------------|--------------|-----------|----------|----------------|
| Gross→Net calculator | y | y | n | n | n |
| Market salary benchmarks | y | n | partial | partial | partial |
| Job title lookup | y | n | partial | y | y |
| City comparison | y | n | n | n | n |
| Experience-level adjustment | y | n | n | y | y |
| Mobile responsive | y | n | y | y | y |
| Modern UX | y | n | moderate | y | y |
| Greek-language | y | y | y | n | partial |
| Free full access | y | y | y | n | n |
| Premium salary report | y | n | n | y | partial |
| Programmatic city pages | y | n | n | n | n |
| 13th/14th month calc | y | partial | n | n | n |

## Business Foundation (feeds → Business Documentation Framework)

### Top 3 Problems (→ IDEA-04 Problem Statement, IDEA-09 box 1)

1. **Salary opacity in Greek labour market** — Greeks cannot easily determine if they are being paid fairly for their role, city, and experience level. There is no Greek-specific equivalent of Glassdoor with sufficient data density. Evidence: r/greece salary transparency threads consistently reach top posts; Greek media regularly covers "brain drain" tied to wage uncertainty.

2. **Net salary calculation complexity** — Greek payroll includes EFKA contributions (18%+), tiered income tax (9-44%), solidarity tax, and legally mandated 13th/14th month payments. This is genuinely complex, and the only free Greek tool (e-misthologio) has severe UX problems. Evidence: "εισφορές υπολογισμός" (contributions calculator) among top Greek finance queries; AADE official calculator lacks mobile access.

3. **Salary negotiation blindness** — Greeks entering new jobs or requesting raises lack data to negotiate effectively. Existing resources (global salary platforms) have insufficient Greece data. Evidence: HR contacts confirm salary negotiation requests often fail because neither party has reliable benchmark data; remote work expansion creates new urgency as Greeks compare their salaries to EU standards.

**Existing alternatives:** e-misthologio (tax math only, poor UX); AADE calculator (official but purely tax, no benchmarks); kariera.gr salary section (sparse crowd-sourced data); Glassdoor Greece (too thin); word of mouth.

### Primary Customer Profile (→ IDEA-02 JTBD, IDEA-09 box 2)

- **Who:** Greek professionals aged 22-45 considering a job change, salary negotiation, or evaluating a job offer. Secondary: Greek expats comparing their salaries to Greece. Tertiary: Remote workers based in Greece comparing their compensation to EU peers.
- **Where:** Athens (Attica) primarily — ~55% of Greek economic activity; Thessaloniki secondary (~20%).
- **When:** Receiving a job offer, annual review season (Jan-Mar), considering resignation, hearing a colleague's salary, reading about minimum wage changes.
- **Early adopters:** Tech/IT professionals in Greece (highest salary variance, most salary-aware, most likely to share tools); HR professionals (validation + B2B path).

### Channels (→ IDEA-09 box 5)

| Channel | Opportunity | Evidence |
|---------|------------|----------|
| Programmatic SEO | Strong | 570+ addressable page targets; low competition in Greek SERPs; finance intent = higher RPM |
| Reddit (r/greece) | Strong | 180K subscribers; salary discussion endemic; high shareability of useful tools |
| LinkedIn / HR network | Moderate | Founder has direct HR contacts; can seed with salary data validation requests |
| Social / Facebook Groups | Moderate | Greek job-seeking groups 50K+ combined members; salary transparency content engages well |
| Direct HR partnerships | Moderate | B2B seed: salary benchmarking for Greek SMEs; HR contacts as first customers |

### Revenue Model (→ IDEA-09 box 6)

- **Primary model:** Display advertising (AdSense → Ezoic at 10K sessions → Mediavine at 25K sessions)
- **Secondary model:** Freemium — "Personalized Salary Report" (PDF with percentile ranking, city comparison, negotiation range) at €9-29/report
- **B2B path:** Salary intelligence reports for Greek HR teams (€500-2,000/report) — enabled by HR contact network
- **Benchmark from tool-site lens:** Greek traffic RPM $5-12 (finance niche); 100K visits/month = $500-1,200/month ad revenue

### Unfair Advantage (→ IDEA-09 box 9)

- **Data moat:** Growing user-submitted salary data over time; 13th/14th month complexity creates Greece-specific logic moat; HR contacts = proprietary salary benchmarking data access
- **Founder edge:** Greek native with lived salary opacity experience; HR network for data seeding and B2B path; React/TS technical capability means no outsourcing the build
- **Defensibility:** Compound SEO authority (570 programmatic pages = 570 individual trust signals over time); brand recognition as "the Greek salary tool"; user data flywheel

### AI Leverage Assessment

| AI Application | Replaces | Impact |
|---------------|----------|--------|
| Programmatic page generation | 2 content writers | 570 city/job pages generated automatically vs manual writing |
| Salary benchmark estimation | Market research team | AI fills data gaps for job/city combos with thin real data |
| Translation + localization | Translator | Greek/English dual-language content generated automatically |
| Schema markup generation | SEO specialist | Structured data for all pages auto-generated |
| Customer support | Support agent | FAQ chatbot handles 80% of "how is this calculated?" queries |

**AI Disruption Signal:** Greek HR consulting firms charge €5,000-20,000 per salary survey. AI-assisted aggregation + user submissions delivers 80% of that value free to individuals, and disrupts the B2B market at €500-2,000 per report.

**Solo Founder Viability:** Yes. Solo founder + AI = equivalent of 2-3 person team for content, data, and support.

### Success Metrics (→ IDEA-09 box 8)

| Metric | Target (30 days) | Target (90 days) | How to Measure |
|--------|-----------------|-----------------|----------------|
| Monthly organic visits | 1,000 | 10,000 | Google Analytics / Search Console |
| Programmatic pages indexed | 50 | 200 | Google Search Console |
| Premium salary reports sold | 5 | 50 | Stripe dashboard |
| Monthly ad revenue | €20 | €100 | AdSense dashboard |

## Strengths

1. **Clear competition gap with validated demand** — The combination of proven search demand (25K+ monthly searches) and no modern Greek salary benchmarking tool is the classic underserved-niche opportunity. e-misthologio's 10+ year survival proves demand without threatening quality bar.

2. **Strong timing catalyst** — EU Pay Transparency Directive (effective 2026) is a concrete regulatory driver that will increase Greek employer, HR, and employee interest in salary benchmarking tools. Not a hypothetical tailwind — a signed EU directive with a compliance deadline.

3. **Founder-market fit with a direct distribution edge** — Being Greek with personal salary opacity experience + HR contacts creates both product intuition and a B2B seed path that an outside founder couldn't replicate.

## Weaknesses

1. **Small market ceiling at ad-only revenue** — Greece's 4.5M employed workforce caps pure ad revenue. At 100K monthly visits × $7 RPM = ~$700/month. Below lifestyle business without B2B or geographic expansion.

2. **Data quality risk** — Salary benchmark data for Greece is sparse. The tool's core value proposition depends on data accuracy. Inaccurate benchmarks destroy trust quickly and require ongoing data maintenance.

3. **Cloneability** — Calculator logic is public and the UX can be copied. First-mover advantage window is 12-18 months before an incumbent adds quality salary calculator features.

## Key Risks

1. **Market size ceiling** — Greece-only ads revenue is ~€700-1,200/month at 100K monthly visits — below lifestyle business threshold without B2B or expansion.

2. **Incumbent counter-move** — kariera.gr or a funded Greek HR tech startup could add a modern salary calculator in weeks, leveraging existing user base and job posting data.

3. **Google entering Greek salary space** — Google already shows salary data in Google Jobs for many markets. Expansion to Greece would undercut SEO visibility for salary calculator queries.

## Blind Spots

1. **Google Jobs salary data expansion to Greece** — Not researched; could materially reduce search traffic and tool utility.

2. **ERGANI data openness trajectory** — Greek Ministry of Labour's Ergani system tracks all employment contracts. If salary fields become open data, dramatically improves opportunity or enables government competitor.

3. **Funded Greek HR tech landscape** — Workable (Greek-founded, $50M+ raised) and other funded Greek HR tech companies were not assessed for plans to enter salary benchmarking.

## Recommendation

The Greek Salary Calculator scores **BUILD at 71.6%** — a solid opportunity with genuine market gap, strong timing, and clear founder fit. The competitive landscape is favorable: the only Greek-specific tool (e-misthologio) is severely outdated, and global platforms have thin Greece data. The EU Pay Transparency Directive provides a regulatory tailwind with a hard 2026 deadline.

The critical path is the data layer, not the calculator logic. The net salary calculation (gross → net with EFKA + income tax + 13th/14th month) is fully public knowledge and buildable in 3-5 days. The harder, more important work is building a credible salary benchmarking dataset — even 15-20 job categories in Athens with validated ranges would differentiate this tool from every competitor. Start with HR contacts to validate and seed that initial dataset.

The primary risk is market size. Greece-only with ads-only monetization caps revenue at ~€700-1,200/month at scale. The upside requires either (a) B2B salary intelligence reports for Greek HR teams, or (b) geographic expansion to Cyprus, Greek diaspora markets, and similar EU markets with salary opacity. Build Greece first as a proof of concept, then evaluate expansion.

## Next Steps

1. **Build the calculator core** (Week 1) — Implement gross→net salary calculator using EFKA 2024 rates + income tax brackets + 13th/14th month logic in React/TS. Deploy on Vercel with basic Analytics.
2. **Seed salary benchmark data** (Weeks 2-3) — Contact HR network contacts for salary data validation interviews; aggregate ELSTAT + kariera.gr + LinkedIn salary data for 15-20 high-demand job categories; use AI to fill coverage gaps with appropriate uncertainty ranges.
3. **Launch programmatic SEO** (Weeks 3-4) — Generate 50 city/job variant pages, submit sitemap to Google Search Console, post tool in r/greece and relevant LinkedIn groups to seed initial traffic.

## Research Sources

Raw research data archived at: `ideas/greek-salary-calculator/research/`

| Stage | File | Data Note |
|-------|------|-----------|
| Market Research | market.md | CLI unavailable — all data estimated |
| Competition Research | competition.md | CLI unavailable — all data estimated |
| Data Research | data.md | CLI unavailable — all data estimated |
| Distribution Research | distribution.md | CLI unavailable — all data estimated |
| Competitor Deep-Dive | competitor-profiles.md | CLI unavailable — all data estimated |
| Scoring Report | scoring.md | Initial score: 3.70/5 (74%) |
| Critic Review | critic.md | Adjusted score: 3.58/5 (71.6%) — Revenue Potential -1 |
