# Trust Your Physio — Redesign Brief

## 1. Assumptions (edit if wrong)

- **Site:** trustyourphysio.com — solo physiotherapist's practice site (Konstantinos Varvagiannnis, Athens, Greece)
- **Category:** local-service (confidence: high — physiotherapy, appointment-booking intent, single practitioner)
- **Primary audience:** Greek-speaking adults aged 45–70 with chronic knee/hip osteoarthritis or lower back pain; also English-speaking international patients seeking online physiotherapy programs
- **Primary goal:** Convert site visitors into Active Life Program enrolments (8-week online course; €—/unpriced)
- **Inferred purpose:** Market and sell a structured online physiotherapy program for OA pain management
- **Target purpose:** Same — same purpose redesign (confirmed: redesign for same audience and product, improved conversion and credibility)
- **Language:** Mixed Greek/English; primary audience is Greek-speaking; English hero copy targets broader reach
- **Crawler:** Jina Reader (SPA-rendered); sitemap.xml empty → `[NO-SITEMAP]`; crawl `[SAMPLED:2-templates]` (homepage + /about; /book and /guides both 404)

## 2. What the site is

Trust Your Physio is the personal practice site of Konstantinos Varvagiannnis, a Greek physiotherapist with 8 years' experience specialising in knee/hip osteoarthritis and chronic lower back pain. The site's primary commercial product is the "Active Life Program" — an 8-week, 16-session online physiotherapy course with at-home exercises, weekly progress tracking, and ongoing practitioner support. The program is delivered digitally, targeting patients who want to manage pain without medication or repeated clinic visits. There is also an /about page with practitioner bio, and an application form on the homepage for program enrolment. A digital guides section and a booking page are referenced but both 404 at time of analysis.

## 3. Target audience

- **Primary:** Greek-speaking adults 45–70 with diagnosed or undiagnosed knee/hip OA or chronic lower back pain; pain-avoiding, medication-wary, seeking an affordable and autonomous management path
- **Secondary:** English-speaking patients (international or diaspora Greek) with similar pain profiles who find the site via search
- **Pain state:** Chronic sufferers who have tried medication, may have had scans/imaging, fear surgery, and are looking for a structured self-management program with expert guidance
- **Motivation triggers:** Autonomy, avoidance of surgery/medication, proof that improvement is possible without hospital visits

## 4. Redesign goals & success criteria

**Goals:**
1. Fix the broken primary CTA (/book 404) — this is the single highest-priority change
2. Add a visible phone number or WhatsApp contact on every page (mobile-first)
3. Resolve the pricing/investment ambiguity — visitors cannot evaluate the program without a cost signal
4. Establish practitioner credibility with registration number and governing-body affiliation
5. Clarify the language split — English hero for reach, Greek body for primary audience, or full bilingual with hreflang

**Success criteria:**
- Application form submissions increase (baseline: current broken CTA → any working CTA is a win)
- Phone/WhatsApp contacts visible on homepage above fold
- Bounce rate decrease on mobile (currently no click-to-call)
- Practitioner licence number added and verifiable

## 5. KEEP / CHANGE / ADD

**KEEP:**
- The program concept and 8-week/16-session structure — it is well-defined and differentiating
- The "Five reasons" value proposition format — clear benefit enumeration works well in this audience
- The "My Guarantee" section — the 1 extra month free offer is a strong trust signal; keep and make it more prominent
- Konstantinos's personal tone and direct commitment language — "I commit to work with you" is authentic and should be preserved
- Testimonials ("Real Stories" / "Αληθινές Ιστορίες") — video social proof is strong; keep and place higher on the page
- The application-form-then-call model — appropriate for a high-touch, personalized program

**CHANGE:**
- Fix /book (404) — redirect to the working application form
- Fix /guides (404) — either build the page or remove the homepage section reference
- Replace "Book Position Now" CTA copy with "Apply Now — Free Consultation" or "Join the Program"
- Add programme pricing transparency — even a price range or "investment from €X" removes the biggest conversion hesitation
- Move testimonial videos higher — currently placed mid-page; they should be above the application form
- Add Konstantinos's registration/licence number to /about and the homepage bio section
- Language consistency — decide on a primary language and use it consistently for the hero, CTAs, and SEO metadata; mark up mixed sections with lang attributes

**ADD:**
- Phone number / WhatsApp button in the header (sticky on mobile)
- `LocalBusiness` or `MedicalBusiness` schema.org markup with NAP fields
- Third-party review integration (Google Business reviews or equivalent)
- A clear pricing/investment section or FAQ entry on the homepage
- A "Who is this for / not for" clarity section to pre-qualify applicants and reduce low-quality enquiries
- Insurance/reimbursement information if applicable to Greek healthcare system

## 6. Information architecture (proposed)

```
/                   — Hero (program) → Social proof → Program details → Practitioner bio → Pricing → Apply
/about              — Full bio with credentials, photo, registration number, specialties, clinic info
/program            — Full program page: 16 modules, 4 phases, what to expect, FAQ, pricing, apply CTA
/guides             — Digital guides library (fix or build; currently 404)
/book               — Self-service booking for initial free consultation (fix 404; integrate Calendly or equivalent)
/contact            — Phone, WhatsApp, address (Athens), opening hours, contact form
```

**Nav:** Home / Program / Digital Guides / About / Book Free Consultation

**Primary conversion path:**
Homepage → Program details → Apply form → Konstantinos call → Enrolment

## 7. Design direction + design-system seed

**Direction:** Warm clinical authority. The design must read "trusted expert" without feeling like a hospital. Personal, direct, evidence-referenced. The practitioner's face and voice should dominate — this is a personal practice, not a clinic chain.

**Design-system seed (local-service pack, physio variant):**
- **Palette:** #1B4F72 (deep teal-navy, primary/headers — calm and professional), #FFFFFF (background), #2E86AB (action/CTA — accessible against white at AA), #F4F9FC (surface/card — clean off-white), #5D6D7E (secondary text). Accent: #E8F4F8 for highlight bands.
- **Typography:** Body — Nunito or Lato (warm, approachable, legible at 17px+ for the 45+ audience); headings — same family at 700 weight. Avoid clinical serifs or ultra-thin weights. Min 17px body on mobile.
- **Spacing:** Generous vertical spacing (40–56px section padding on mobile). Radius 10px on cards and form inputs. Transitions 120ms ease. No motion near the application form.
- **Photography:** Konstantinos's real photo (warm, professional setting — not a clinical white-coat stock image). Real-life movement footage rather than staged medical imagery.
- **Imagery direction:** Older adults in movement — walking, stretching, gardening — conveying the outcome (freedom), not the condition (pain). Avoid: hospital corridors, stethoscopes, generic anatomy diagrams.

**Contrast check required:** Ensure all text on #1B4F72 backgrounds passes WCAG AA at 17px body size for the 45+ primary audience.

## 8. Reference + anti-reference sites

**Reference sites:**
- **Clapham Physiotherapy (claphamphysio.co.uk)** — clean service navigation, real practitioner photos, booking CTA prominent; demonstrates "local trust" done right without enterprise budget
- **The Physio Company (thephysiocompany.com, Ireland)** — insurance partners listed, service pages with outcome language, no jargon overload
- **Six Physio (sixphysio.com)** — strong bio pages with credentials and registration numbers

**Anti-references (what to avoid):**
- Any site where the phone number takes more than 2 seconds to find on mobile
- Sites using stock medical imagery (stethoscopes, generic consultation rooms, anonymous hands)
- Any local clinic that buries its address in the footer in small text
- Sites with aggressive pop-ups on a first visit
- Homepage where the practitioner's credentials are on a separate "About" page only — put them on the homepage

## 9. Web-capture instruction

Capture the live URL for content, structure, and brand assets to KEEP (logo, brand color, product photography) only. The design direction above OVERRIDES all captured visual styling.

URL to capture: https://trustyourphysio.com/

Assets to keep: "Ενεργός Ζωή" program logo (cloudfront CDN), any practitioner photography, the program phase/module structure text. Discard: current colour palette, layout, typography, broken navigation, mixed-language hero.

## 10. Tech / export target + handoff

No beacon tech-stack found — specify the target stack manually, or run beacon first.

*Note: `[TECH-STACK-ABSENT]` — no `docs/sites/trustyourphysio-com/research/tech-stack.md` found and no legacy `docs/research/trustyourphysio-com/tech-stack.md` found. Run `/beacon:analyze https://trustyourphysio.com/` first to identify the current tech stack (React SPA likely, possibly Next.js or Vite + React Router based on client-side rendering behaviour). For export: if Webflow is not the stack, Claude Design output can be exported as static HTML/CSS for handoff to the developer.*
