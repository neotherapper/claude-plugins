# Trust Your Physio — Current-Design Critique

Judged against category pack: **local-service**. [VISUAL-GAP: visual-hierarchy critique limited — no screenshot taken; one Jina pageshot available on request but not taken per task bounds. Text-only assessment below.]

| # | Finding | Severity (0–4) | Best-practice violated | Concrete fix | Evidence |
|---|---------|----------------|------------------------|--------------|----------|
| 1 | Primary CTA "Book Position Now" links to /book which returns 404 | 4 (critical) | Book/contact conversion is the only job | Fix or redirect /book to the working application form immediately | Crawl: /book → "404 Page Not Found" |
| 2 | No phone number discoverable in any crawled page | 3 (major) | Click-to-call must be visible and tappable on every page — especially mobile | Add a sticky `tel:` header/footer bar with Konstantinos's phone number | Homepage and /about crawl: no `tel:` link found |
| 3 | Mixed Greek and English content throughout the homepage | 3 (major) | Service offering must be unambiguous in the visitor's language | Pick one primary language per audience segment; English landing for international; Greek landing for local; or bilingual with clear toggle | Homepage: paragraphs alternate between Greek and English mid-section |
| 4 | No registration/licence number or governing-body affiliation cited for the practitioner | 3 (major) | Credentials and registration numbers must appear above the fold or within one scroll | Add Konstantinos's physiotherapy licence number and governing body (e.g. Greek Physiotherapy Association) near the practitioner bio | /about: "8 years clinical experience" cited but no registration number |
| 5 | Booking friction: application form requires a phone follow-up call by Konstantinos rather than self-service booking | 2 (moderate) | Booking form max 5 fields; friction floor must be low | Add an inline Calendly or equivalent self-service booking for an initial consultation call; the current "I'll contact you" model adds an unknown wait | Homepage application section: "fill in details and I'll contact you" |
| 6 | Insurance/pricing information absent from all crawled pages | 2 (moderate) | Resolve the insurance/coverage/cost question before the visitor has to ask | Add a clear pricing block or "program investment" section to the homepage with the total cost, payment options, and whether the program is insurance-reimbursable | No pricing found on / or /about |
| 7 | No trust signals from third parties: no Google Reviews, Trustpilot, or professional body logos | 2 (moderate) | Google/Trustpilot review count and rating — linked, placed on homepage and service pages | Add a linked review widget (Google Business reviews or similar) showing rating + count near the booking CTA | Homepage: testimonials described as "real videos" but no third-party review count |
| 8 | Digital Guides section referenced on homepage but /guides 404s | 2 (moderate) | Content accuracy and NAP consistency | Fix the /guides URL or remove the section from the homepage until the page exists | Homepage: "Digital Guides" section header with broken route |
| 9 | "Book Position Now" as CTA copy is unusual and non-standard English; "Apply for the Active Life Program" is verbose | 1 (minor) | CTA must be a specific action in plain, expected language | Replace with "Join the Program" or "Apply Now — Free Consultation" | Homepage hero CTA button text |
| 10 | Statistics row ("Weeks / Sessions / Online") renders without numbers | 1 (minor) | Specific outcome language beats generic claims | Ensure the JS rendering correctly populates the counter animations; Jina shows unlabelled counter placeholders | Homepage crawl: "Weeks / Sessions / Online" with no numeric values |

## Voice & messaging

**Three vaguest claims identified:**

1. "Transform your life in 8 weeks" — transformation is generic; no qualifier on what transformation means (pain level, mobility, independence)
   - Proposed: "Reduce knee and hip pain by up to 60% — tracked weekly, delivered at home"

2. "Evidence-based physiotherapy program" — "evidence-based" is used by almost every physio practice without citing the evidence
   - Proposed: "Built on the latest clinical guidelines for osteoarthritis management (NICE / EULAR protocols)"

3. "We helped hundreds of people return to the activities they love" (/about) — "hundreds" is unverifiable; "activities they love" is vague
   - Proposed: "Helped 200+ patients with knee and hip OA return to walking, hiking, and daily activity — without surgery or medication"

**Overall voice assessment:** The English copy is warm and empathetic in intent but mixes motivational language ("Transform your life") with clinical process language. The Greek sections (which are the majority of the homepage body) are stronger — more specific and direct. The English hero and CTAs need to match the specificity of the Greek content.

## Content-side SEO/a11y signals

- **Heading structure:** `<h2>` used for major sections ("Apply for the Active Life Program", "Digital Guides") — correct; `<h4>` used for module titles ("Εισαγωγή & αυτοπροστασία") — implies missing `<h3>` level; hierarchy appears inconsistent.
- **Metadata:** Page title "Physiotherapy & Pain Management | Trust Your Physio" is good — includes primary keyword. Meta description not captured in Jina output.
- **Schema:** No `LocalBusiness` or `MedicalBusiness` schema detected in crawl text. A `schema.org/Physician` or `schema.org/LocalBusiness` with NAP fields would improve local search ranking.
- **NAP consistency:** No address or phone visible on any crawled page — Google cannot resolve a consistent NAP for local ranking.
- **Alt text:** One `<img>` detected (program logo) with alt text present ("Ενεργός Ζωή logo") — good. Practitioner photo alt text not confirmed (no photo URL in /about crawl).
- **Language declaration:** Mixed Greek/English content without an `hreflang` tag could confuse search engine locale attribution; recommend `<html lang="el">` for the primary Greek content with English sections marked up or a separate `/en/` landing page.
