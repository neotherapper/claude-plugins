# Trust Your Physio — Redesign Brief

## 1. Assumptions (edit if wrong)
- **Inferred purpose:** Online physiotherapy practice (Athens, Greece) run by a single practitioner (Konstantinos Varvagiannis) offering a structured 8-week digital rehabilitation program ("Active Life Program") for knee and hip pain, supplementary home-visit sessions, and downloadable PDF guides — bilingual EN/Greek SPA.
- **Target purpose:** Same as inferred (same-purpose redesign — no pivot declared).
- **Audience:** Greek-speaking adults (primarily 50+) with chronic knee/hip pain or osteoarthritis, seeking evidence-based, home-friendly physiotherapy without repeated clinic visits. Secondary: English-speaking expats or international patients.
- **Primary goal:** Drive applications to the "Active Life Program" via the "Book Free Call" entry point and the inline application form.
- **Category:** local-service (confidence: high); secondary: digital-product (online programme + PDF guides).
- **Coverage:** Homepage SPA-rendered (prior Chrome session) — full content extracted. /about and /contact pages returned near-empty static HTML (SPA render required but Chrome timed out on attempt — `[RENDER-ESCALATED]` for homepage confirmed; /about and /contact text-only from homepage footer data).
- **Signals fired:** `[RENDER-ESCALATED]` `[NO-SITEMAP]` `[PACK-LOADED:local-service]` `[SAMPLED:1-template]`

## 2. What the site is
A solo-practitioner physiotherapy business operating primarily online. The flagship product is a structured 8-week, 16-session evidence-based programme targeting osteoarthritis of the knee and hip, delivered entirely from home. Supplementary income streams include home-visit sessions (Athens), downloadable PDF guides sold via Stripe, and a newsletter. The site is a bilingual SPA (React or similar), heavy on Greek-language content below the fold despite an EN toggle. The single practitioner (Konstantinos Varvagiannis, Φυσικοθεραπευτής, Athens, email: kostas.varvagiannis@gmail.com, phone: +30 698 594 1957) is central to the trust proposition. Real patient video testimonials (4 named patients) are present.

## 3. Target audience
- **Primary:** Greek adults 50–70 with diagnosed or suspected osteoarthritis of the knee or hip; mobile-dominant, YouTube- and social-driven discovery; price-conscious but pain-motivated; decision often involves a spouse or family member.
- **Secondary:** Younger active adults (30–50) with sports injuries or MSK conditions in Athens; English-speaking patients.
- **Job to be done:** "Convince me this online programme will actually reduce my pain — and that this specific physio can be trusted — so I feel safe submitting my details."

## 4. Redesign goals & success criteria
1. **Increase "Book Free Call" conversion** — measured by form submissions / unique homepage visitors.
2. **Immediate single-practitioner trust** — name, photo, credentials, and patient video testimonials visible above the fold or within one scroll.
3. **Clarify programme offer** — 8-week structure, cost, and guarantee; no ambiguity about price or scope.
4. **Mobile-first** — click-to-call (`tel:`) and booking CTA thumb-reachable on every page.
5. **Bilingual parity** — EN and EL content structurally equivalent; currently Greek content is richer below the fold.

**Success signals:** ≥ 2× conversion rate on primary CTA; bounce rate reduction on mobile; NPS improvement from new patients.

## 5. KEEP / CHANGE / ADD

### KEEP
- Practitioner name and personal commitment narrative ("Η Δέσμευσή μου") — primary trust differentiator.
- Real patient video testimonials (Βασιλική, Δροσούλα, Σταματίνα, Αλεξάνδρα) — authentic social proof; move higher in page hierarchy.
- 4-phase / 16-session programme structure — the product's clearest differentiator; render it visually.
- "Book Free Call" as primary CTA — low-friction entry point; correct for high-consideration purchase.
- FAQ section — appropriate for an online health programme; expand to include insurance/cost question.
- Newsletter subscription — retain for retention.
- Programme guarantee ("1 additional month free if you complete and still need support") — rare and powerful trust signal; make it prominent.

### CHANGE
- Hero copy: "Move Again Without Pain" is adequate but generic — replace with condition-specific outcome language e.g. "End knee and hip pain in 8 weeks — from home, with a certified physio."
- Phone number: currently in footer/contact only — must be sticky on mobile header with `tel:` link.
- Programme pricing: absent from homepage — add explicit price or "from €X" anchor; vague pricing is a trust barrier.
- Language toggle: move to header; currently implicit; bilingual users need to switch on arrival.
- Below-fold content ratio: too much Greek-only content when scrolled; apply EN/EL parity throughout.
- Application form: 8 fields is acceptable but "Where did you hear about us" should be optional (data-collection, not patient-benefit).
- Gmail address as primary contact: replace with a branded @trustyourphysio.com address for credibility.

### ADD
- Practitioner credentials block above the fold: qualification title + registration number (if applicable) + years of experience — not just a first name.
- Governing-body badge (Greek Physiotherapy Association / ΠΦΣ) near the primary CTA.
- Explicit pricing anchor on homepage — even "from €X / programme"; link to /pricing page.
- Insurance/self-pay clarity: "Self-pay · No insurance required" to eliminate the implicit question.
- Outcome-specific language: "Average patient reduces pain score by 60% in 8 weeks" (use real data if available).
- `LocalBusiness` + `Person` + `Service` + `FAQPage` JSON-LD schema.
- NAP in footer on every page: full name, Athens address, phone, email — consistent for local SEO.
- WhatsApp/Viber secondary CTA — dominant messaging channels in Greece.

## 6. Information architecture (proposed)

```
/ (Home)
  Hero (who + problem + primary CTA)
  → Trust strip (credentials + review count + video testimonial preview)
  → Programme overview (8 weeks / 16 sessions / 4 phases — visual card row)
  → Who it's for (condition cards: knee pain / hip pain / osteoarthritis)
  → How it works (Free Call → Assessment → Programme → Support)
  → Practitioner bio (name, photo, credentials, registration, personal note)
  → Patient video testimonials (real names + stated outcomes)
  → Pricing anchor (programme cost + guarantee badge)
  → FAQ (top 6)
  → Footer CTA + NAP

/about        — Practitioner story, credentials, clinical philosophy, contact
/programme    — Full 4-phase breakdown, pricing, guarantee, apply CTA (full form)
/services/home-visits     — Athens home-visit offering, conditions, booking CTA
/services/musculoskeletal — MSK conditions treated, approach, CTA
/services/sports          — Sports physiotherapy, CTA
/guides       — PDF guide listings with Stripe checkout
/blog
/contact      — NAP, embedded map (Athens), tel + WhatsApp, contact form
```

**Per-page intent triplets:**

| Page | Subject · Audience · Job |
|------|--------------------------|
| Home | 8-week online physio programme for knee/hip pain · Pain-motivated adults 50+ in Greece · Convert cold visitor to "Book Free Call" applicant |
| /about | Solo practitioner credentials and clinical philosophy · Sceptical patient checking who they're trusting · Build personal trust sufficient to proceed to booking |
| /programme | Active Life Programme structure, pricing, and guarantee · Warm lead who clicked CTA but wants full detail · Remove remaining objections and collect the application |
| /services/home-visits | Athens in-home physiotherapy sessions · Athens-local patients preferring in-person care · Generate booking inquiry via call or form |
| /guides | Downloadable evidence-based physiotherapy guides · Self-managing patients · Stripe purchase (low-friction secondary revenue) |
| /contact | Full NAP, map, call/WhatsApp, form · Patient ready to contact via any channel · Provide zero-friction route to contact |

## 7. Design direction + design-system seed

**Direction:** "Trusted, warm, clinical-without-coldness." Palette and type must read "qualified professional I can trust with my body" — not corporate healthcare. Solo-practitioner context calls for warmth and approachability over institutional distance.

**Palette:**
```
--color-primary:    #1B4F72;  /* deep teal-navy — calm, professional */
--color-bg:         #FFFFFF;
--color-cta:        #2E86AB;  /* accessible blue — AA on white */
--color-surface:    #F4F9FC;  /* off-white card background */
--color-text-muted: #5D6D7E;
--color-band:       #E8F4F8;  /* highlight band */
--color-warm-bg:    #FFF8F0;  /* testimonial / guarantee block */
```

**Typography:**
- Body: Nunito 17px minimum (approachable; Greek character set support; older users)
- Headings: Nunito 700, or pair with Merriweather for serif warmth on hero H1
- UI labels: Nunito 14–15px
- Line-height: 1.65 (Greek prose needs more leading than Latin)

**Spacing / radius / motion:**
- Section padding: 40–56px desktop; 32–40px mobile
- Card radius: 10px (approachable, not pill)
- Form input radius: 8px with 1px border
- Bio card shadow: `0 2px 8px rgba(0,0,0,0.08)`
- Transitions: 130ms ease; NO motion on booking/application form
- Sticky mobile header: 56px; logo + `tel:` button + "Book Free Call"

## 8. Reference + anti-reference sites

**References:**
- **claphamphysio.co.uk** — clean service navigation, real practitioner photos, booking CTA prominent; local trust without enterprise budget.
- **thephysiocompany.com** (Ireland) — credentials visible, insurance partners, service pages with outcome language.
- **sixphysio.com** — strong bio pages with credentials and registration numbers (adapt for solo context).

**Anti-references:**
- Any site where phone takes > 2 seconds to find on mobile.
- Canva-generated hero banners with stock hands-on-shoulders imagery.
- NHS Trust template navigation — over-complex, no personality.
- Auto-play video in hero on mobile.
- Pricing coyness — "contact for pricing" erodes trust for cost-sensitive patients.
- Pop-ups on first visit.
- Unbranded third-party redirect for booking without embedded context.

**Strict NOs:**
- NO stock medical imagery — use real practitioner/patient photography only.
- NO hidden phone — `tel:` in header, visible on every page on mobile.
- NO booking flow that redirects to an unbranded third-party domain.
- NO jargon in service names ("manual therapy for MSK dysfunction" → "back and neck pain treatment").
- NO pricing coyness.
- NO missing alt text on practitioner or patient photos.

## 9. Web-capture instruction

Capture the live URL for content, structure, and brand assets to KEEP (logo, brand color, product photography) only. The design direction above OVERRIDES all captured visual styling.

Specifically: capture the practitioner headshot, any real patient photography, the current logo, and the programme phase structure. Do NOT import the current hero layout, navigation style, card designs, or color application — these are being replaced wholesale.

## 10. Tech / export target + handoff

- **Framework:** React or Next.js — upgrade SPA to SSG/SSR for local SEO; current SPA is near-invisible to search crawlers.
- **Hosting:** trustyourphysio.com — Vercel/Netlify compatible.
- **Payments:** Stripe (already integrated for PDF guides) — extend for programme checkout.
- **Booking:** Embed Calendly or Cal.com inline (not redirect) for "Book Free Call."
- **i18n:** next-intl or react-i18next with URL-based locale routing (`/en/`, `/el/`) and proper `hreflang`.
- **Schema:** `LocalBusiness` + `Person` + `Service` + `FAQPage` JSON-LD injected server-side.
- **Analytics:** Plausible or GA4 with conversion events: `form_submit`, `cta_click`, `tel_click`.
- **Export path:** Figma → design tokens (CSS custom properties) → developer handoff with component list.
