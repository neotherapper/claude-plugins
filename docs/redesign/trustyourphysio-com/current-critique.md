# Trust Your Physio — Current-Design Critique

Judged against category pack: **local-service**. `[VISUAL-GAP: Chrome DevTools timed out on second attempt; visual-hierarchy critique based on homepage screenshot from prior run (.crawl/screenshots/homepage-above-fold.png) and SPA-rendered text content.]`

| # | Finding | Severity (0–4) | Best-practice violated | Concrete fix | Evidence |
|---|---------|----------------|------------------------|--------------|----------|
| 1 | Phone number absent from header; visible only in footer/contact section | 4 (critical) | "Click-to-call as primary CTA on mobile — a sticky `tel:` button in the header/footer bar; do not bury the number in small print." | Add `<a href="tel:+306985941957">` to sticky mobile header alongside "Book Free Call"; make it tap-target size (44×44px min). | homepage.json: phone appears only at bottom of page scroll |
| 2 | Programme pricing not disclosed anywhere on homepage | 3 (major) | "Resolve the insurance/coverage/cost question before the visitor has to ask — hidden fees or unexplained gaps create bounce." | Add a pricing anchor block ("Active Life Programme — from €X") to homepage and a dedicated /pricing page with full breakdown + guarantee. | homepage.json: no price string found in extracted text |
| 3 | Practitioner identified by first name only in hero context; credentials not visible until deep scroll | 3 (major) | "Establish local trust immediately: credentials, registration numbers, practitioner names and faces … must appear above the fold or within one scroll." | Move credential block (full name, qualification title, registration number, years of practice) to within the first two screen-heights; pair with real headshot. | homepage.json: "Κωνσταντίνος Βαρβαγιάννης / Φυσικοθεραπευτής / Αθήνα" appears only after PDF guide section |
| 4 | Primary contact email is a Gmail address (kostas.varvagiannis@gmail.com) — unprofessional for a health service | 2 (moderate) | "Trust signals: governing-body registration logos … prominently placed" — by extension, brand consistency signals credibility. | Register and use @trustyourphysio.com email; takes 10 minutes; eliminates a subconscious trust gap. | homepage.json footer |
| 5 | Hero copy ("Move Again Without Pain") is generic — does not name the specific condition or patient type | 2 (moderate) | "Make the service offering unambiguous … stated in plain language … within the first screenful." | Rewrite to name the condition and timeframe: "End knee and hip pain in 8 weeks — evidence-based programme from home." | homepage-above-fold.png |
| 6 | Governing-body registration badge absent — no ΠΦΣ or equivalent credential logo near CTA | 2 (moderate) | "Governing-body registration logos — HCPC, CSP … prominently placed near the booking CTA, not buried in the footer." | Add ΠΦΣ (Πανελλήνιος Φυσιοθεραπευτικός Σύλλογος) badge or equivalent registration number visibly near "Book Free Call" button. | homepage.json: no credential logo text found |
| 7 | Insurance/self-pay status unstated — patient must wonder whether insurance is needed before booking | 2 (moderate) | "Resolve the insurance/coverage/cost question before the visitor has to ask." | Add a single line near the booking CTA: "Self-pay · No referral or insurance required." | Absent from all crawled content |
| 8 | Below-fold content is predominantly Greek with no EN equivalent for the same sections | 1 (minor) | Bilingual claim in EN nav but content parity absent — creates trust gap for EN-dominant visitors. | Apply i18n translation to all content blocks; current implementation appears to toggle only partial sections. | homepage.json: Greek-only sections after above-fold |
| 9 | Application form "Where did you hear about us" field is mandatory — adds friction with no patient benefit | 1 (minor) | "Friction floors: booking form max 5 fields; do not ask for insurance details pre-booking." | Make attribution field optional; label it "(optional) — helps us improve". | homepage.json: form field listed as required |
| 10 | No `LocalBusiness` or `Person` schema visible (SPA-rendered check) | 1 (minor) | "Local SEO hygiene: … structured `LocalBusiness` schema." | Inject JSON-LD `LocalBusiness` + `Person` server-side (Next.js `<Script>` in `_document`); include NAP, opening hours, practitioner name. | Not found in homepage.json text extraction |

## Voice & messaging

**Three vaguest claims identified:**

1. **"Transform your life in 8 weeks"** — transformation is undefined; proposes no mechanism.
   - Concrete replacement: "Reduce your knee or hip pain score by at least 50% in 8 weeks — or get a free extra month."

2. **"Evidence-based physiotherapy program"** — every programme claims to be evidence-based; this has no differentiating specificity.
   - Concrete replacement: "Based on clinical research in osteoarthritis rehabilitation — the same approach used in NHS physiotherapy guidelines."

3. **"Real transformation: autonomy, confidence, and freedom of movement"** (translated from Greek: "Πραγματική μεταμόρφωση: αυτονομία, αυτοπεποίθηση και ελευθερία κινήσεων") — abstract benefit cluster.
   - Concrete replacement: "Walk without pain. Climb stairs again. Live without planning your day around your knee." (concrete, specific life moments, not abstract concepts)

## Content-side SEO/a11y signals

- **Heading structure:** SPA renders a single H1 ("Move Again Without Pain") — remaining sections use functional headings; structure appears adequate but cannot be verified without a full DOM snapshot. Flag for review.
- **NAP consistency:** Name, phone (+30 698 594 1957), and city (Athens, Greece) present in homepage footer — address not visible in crawled content (no street address). NAP is incomplete for `LocalBusiness` schema and Google My Business consistency.
- **Alt text:** Cannot audit without a DOM snapshot (`[VISUAL-GAP]`). Practitioner and patient photos must have descriptive alt text — flag for developer review.
- **Meta description:** Not auditable from rendered text; SPA likely relies on a single generic meta for all routes — confirm each route has a unique meta description via SSR/SSG.
- **Schema presence:** No JSON-LD or microdata detected in text extraction. Priority fix: add `LocalBusiness` + `Person` + `FAQPage` schemas.
- **`hreflang`:** No locale-specific URLs detected (e.g. `/en/`, `/el/`); EN/EL toggle appears runtime-only. This means Greek and English versions share one URL — search engines cannot differentiate. Implement URL-based locale routing.
- **Core Web Vitals risk:** SPA with no SSR/SSG means LCP is JavaScript-rendered — likely high LCP on mobile. Migrate to Next.js SSG for critical pages (Home, Programme, Contact).
