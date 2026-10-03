---
category: local-service
display_name: Local Service
detect_signals: ["book appointment", "book online", "appointment", "booking", "services", "clinic", "contact us", "call us", "location", "opening hours", "LocalBusiness", "schema.org/LocalBusiness", "tel:", "address", "physiotherapy", "physio", "dentist", "dental", "GP", "chiropractic", "osteopath", "solicitor", "plumber", "electrician", "accountant", "salon", "practice", "NAP"]
---

# Local Service — Redesign Pack

## Redesign priorities
1. Book/contact conversion is the only job — every page must funnel toward a booking form, phone number, or contact action; remove anything that doesn't serve this.
2. Establish local trust immediately: credentials, registration numbers, practitioner names and faces, and a verifiable address must appear above the fold or within one scroll.
3. Make the service offering unambiguous — what conditions/problems you treat or services you provide, stated in plain language (not professional jargon), within the first screenful.
4. Mobile-first execution is non-negotiable — the majority of local-service traffic is mobile; click-to-call and a thumb-reachable booking CTA must be present on every page.
5. Resolve the insurance/coverage/cost question before the visitor has to ask — hidden fees or unexplained gaps create bounce; a clear "we accept X, we don't accept Y" builds more trust than vague "check with your insurer".
6. Local SEO hygiene: consistent NAP (name, address, phone) in the footer on every page; structured `LocalBusiness` schema; embedded Google Map on the Contact page.

## Conversion patterns
- **Click-to-call as primary CTA on mobile** — a sticky `tel:` button in the header/footer bar; do not bury the number in small print.
- **Booking form above the fold on desktop** — a short inline form (name, service, preferred date/time, phone) visible without scrolling; not a "Book now" button that loads a third-party tool four clicks deep.
- **Service-specific landing pages** — one URL per core service (e.g. `/services/physiotherapy`, `/services/sports-injury`); each has its own CTA and can be the destination of a Google Ad without the visitor seeing irrelevant services first.
- **Friction floors**: booking form max 5 fields; do not ask for insurance details pre-booking; phone confirmation over email for new patients (they trust it more).
- **Callback widget or WhatsApp button** as a secondary conversion for visitors not ready to commit to a form.

## Trust signals
- **Practitioner bios with real photos** — name, qualification letters, registration/license number, plain-English specialty, and a short human note. A smiling headshot outperforms a stock image of a consultation room every time.
- **Governing-body registration logos** — HCPC, CSP, GDC, SRA, Gas Safe — prominently placed near the booking CTA, not buried in the footer.
- **Google/Trustpilot review count and rating** — linked (not screenshotted), placed on the homepage and on each service page. Real review count builds more trust than a 5-star average from 3 reviews.
- **Insurance and coverage clarity** — logos of accepted insurance providers (BUPA, AXA Health, Vitality, WPA, Cigna, etc.) visible on the homepage, Services page, and Booking page.
- **Real photography** — team headshots, the actual premises, equipment in use; no stock hospital corridors or generic medical imagery.
- **Specific outcome language** — "average patient sees improvement in 3–5 sessions" beats "we get results".

## IA conventions
- **Nav:** Home / Services / About & Team / Booking / Contact (+ optional Locations if multi-site)
- **Home:** Hero (who you are + primary CTA) → social proof strip (rating + review count) → services overview (cards) → practitioner highlight → insurance logos → location/map snippet → footer CTA.
- **Services:** index page (all services with brief description + CTA per card) + individual service pages (problem, our approach, what to expect, CTA).
- **About & Team:** clinic ethos → team member bios (photo, name, qualifications, registration, specialties) → clinic history/founding context.
- **Booking:** inline form or embedded booking tool; include service selector, date/time preference, and whether they are a new or returning patient.
- **Contact:** full NAP, embedded Google Map, opening hours, parking/transport notes, a secondary contact form.
- **Journey shape:** cold search → Homepage or Service page → Trust check (About/Reviews) → Booking → Confirmation. Design every page to move the visitor to the next stage, with the exit door being the booking CTA.

## Design-system seed (opinionated)
- Palette: #1B4F72 (deep teal-navy, primary/headers — calm and professional), #FFFFFF (background), #2E86AB (action/CTA — accessible against white at AA), #F4F9FC (surface/card — clean off-white), #5D6D7E (secondary text). Accent warmth: #E8F4F8 for highlight bands. Avoid clinical white-on-white; the palette must read "trusted professional", not "hospital corridor".
- Type: body — Lato or Nunito (warm, approachable, legible at small sizes for elderly users); headings — the same family at Bold (700), or pair with Merriweather for a slightly warmer serif heading. Min 17px body (accessibility; local-service users skew older). UI labels — same body face at 14–15px.
- Spacing/radius/motion: generous vertical spacing (32–48px section padding minimum on mobile); radius 8–12px on cards and form inputs (rounded, not pill — approachable but professional); transitions 120–150ms ease; no motion on the booking form (motion near a form adds cognitive load).
- Borders vs shadows: 1px borders on form inputs (not shadow); light box-shadow `0 2px 8px rgba(0,0,0,0.08)` on practitioner bio cards; avoid heavy shadows (too "sales-y").

## Reference sites
- **Clapham Physiotherapy (claphamphysio.co.uk)** — clean service navigation, real practitioner photos, booking CTA prominent; demonstrates what "local trust" looks like without enterprise budget.
- **The Physio Company (thephysiocompany.com, Ireland)** — HCPC logos visible, insurance partners listed, service pages with outcome language, no jargon overload.
- **Absolute Health (absolutehealth.com, UK)** — good example of combining multiple services (physio/pilates/sports) without fragmenting trust.
- **Six Physio (sixphysio.com)** — strong bio pages with credentials and registration numbers; shows how to present a multi-practitioner team without looking corporate.

## Anti-references & strict NOs
- **Any site where the phone number takes more than 2 seconds to find on mobile** — the visit is over.
- **Sites using Canva-generated hero banners with stock hands-on-shoulders imagery** — anonymous and generic; destroys local credibility.
- **Any local clinic that buries its address in the footer in 10px text** — Google cannot trust NAP inconsistency and neither can the patient.
- **Corporate hospital network sites (NHS Trust templates)** — over-complex navigation, no personality, inaccessible booking flows — everything to avoid in a small independent practice.

Strict NOs:
- NO stock medical imagery (stethoscopes, generic consultations, stock X-rays) — use real team/premises photography only.
- NO hidden phone number — `tel:` must be in the header, visible and tappable on every page on mobile.
- NO booking flow that redirects to an unbranded third-party domain without explaining why.
- NO jargon in service names ("manual therapy for musculoskeletal dysfunction" → "back and neck pain treatment").
- NO pricing coyness — if you charge £85/session, say so; vague "prices on request" erodes trust for price-sensitive patients.
- NO aggressive pop-ups on a first visit — booking-intent visitors are not subscription-funnel traffic.
- NO auto-play video in the hero on mobile — it is slow, intrusive, and often muted anyway.
- NO missing alt text on practitioner photos — these pages are heavily used by people using screen readers and by search engines alike.

## Emphasize in the brief
1. **Booking-friction audit:** map the current booking path step by step — count the clicks, form fields, and page loads between landing and confirmed appointment. Every step above 3 is a fix.
2. **Trust-signal placement:** confirm that credentials, review count, and insurance logos appear on the homepage and on each service page — not only on a dedicated "About" page that most visitors never reach.
3. **Mobile conversion path:** load the homepage on a phone — can a new patient call, book, or find the address within one thumb-reach and without zooming? If not, the entire mobile layout is a priority redesign target.
