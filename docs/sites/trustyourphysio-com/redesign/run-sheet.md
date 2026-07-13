# Trust Your Physio — Run Sheet

Sequential canvas prompts. Paste each block into Claude Design in order. Do not skip the validate step.

## Step 1 — Validate

```
Validate the design system before building any screens. Using the brief I just shared:

1. Generate a palette swatch card showing all 5 colours: #1B4F72 (primary/navy), #2E86AB (CTA/action), #FFFFFF (background), #F4F9FC (surface), #5D6D7E (secondary text) + accent #E8F4F8.
2. Render a type specimen: Nunito at 17px body / 28px h2 / 40px h1, all in #1B4F72 on white.
3. Confirm WCAG AA contrast for: white text on #1B4F72, #1B4F72 text on #F4F9FC, #2E86AB button on white.
4. Show a single card component: 10px radius, F4F9FC background, 1px #E8F4F8 border, a heading, 2 lines body text, a #2E86AB action button.

Flag any contrast failure before proceeding. Do not start the hero until this step is approved.
```

## Step 2 — Key screen

```
Build the homepage hero section for Trust Your Physio (trustyourphysio.com). This is the most critical conversion screen.

Design requirements:
- Background: #1B4F72 (deep navy)
- Above-fold content (no scroll required on desktop 1280px and mobile 390px):
  - Top nav: Logo left | "Program" / "Digital Guides" / "About" / "Book Free Consultation" (navy button, white text) right
  - Sticky mobile bar: phone icon + WhatsApp icon (always visible)
  - H1: "End knee & hip pain in 8 weeks — from home" (white, Nunito 700, 48px desktop / 32px mobile)
  - Subhead: "Evidence-based physiotherapy program by Konstantinos Varvagiannnis, certified physiotherapist. 8 weeks · 16 sessions · lifetime access." (white, 18px)
  - Primary CTA button: "Apply Now — Free Consultation" (#2E86AB background, white text, 10px radius, 52px height)
  - Secondary CTA: "How it works ↓" (text link, white, underline)
  - Hero image: Konstantinos in a warm, professional setting (right side on desktop; below text on mobile). NOT a stock medical image.

Immediately below the fold:
  - Social proof strip: Google rating badge + review count (placeholder: ★★★★★ 4.9 · 127 reviews) | "8 years clinical experience" | "200+ patients helped"
  - These should appear on a white background at 16px, using #5D6D7E for labels.

Do not include: pop-ups, animations that loop, auto-play video, stock imagery of stethoscopes or consultation rooms.
```

## Step 3 — Remaining screens

```
Build remaining screens in this order (highest severity first):

SCREEN A — Program details section (homepage, below the hero):
- Section heading: "The Active Life Program — 8 weeks to less pain" (#1B4F72, h2)
- 3-column benefit cards (F4F9FC background, 10px radius): 1) "16 guided sessions in 4 phases" 2) "Specialized for knee & hip OA" 3) "From home — no clinic visits needed"
- Program phases accordion or step list: Phase 1 (Introduction & safety) / Phase 2 (Understanding your imaging) / Phase 3 (Hip & knee anatomy) / Phase 4 (Psychology of OA)
- "My Guarantee" callout box: shield icon, navy border, text "If you complete the program and still need support, I'll give you 1 extra month of guidance free." — make this visually prominent, not buried.
- End with: "Apply Now — Free Consultation" CTA (full-width on mobile, centered on desktop)

SCREEN B — About / Practitioner section (homepage inline + /about page):
- Practitioner photo (real headshot, warm professional setting) left; bio right on desktop; stacked on mobile
- Name: Konstantinos Varvagiannnis — Physiotherapist, Athens, Greece
- Registration: [Add licence number here — placeholder: Lic. XXXXX, Greek Physiotherapy Association]
- Specialties: Knee & hip osteoarthritis · Chronic lower back pain · Evidence-based pain management
- 8+ years experience · 200+ patients treated
- Quote: "I commit to working with you step by step until you see results."
- Review block: linked Google reviews widget (star rating + count)

SCREEN C — Application form section (homepage bottom):
- Heading: "Apply for the Active Life Program"
- 5-field form max: Full name | Phone number | Email | Condition (knee / hip / back / other — dropdown) | "Tell us about your pain in one sentence" (textarea, optional)
- Submit button: "Send My Application" (#2E86AB)
- Below form: "Konstantinos will contact you within 24 hours for a free 15-minute consultation call."
- Privacy note: "Your details are not shared with third parties."

SCREEN D — /about page:
- Full practitioner bio (English primary, Greek secondary or bilingual toggle)
- Credentials section: photo + name + registration number + governing body logo + specialties
- "Why I built this program" — personal narrative (2–3 sentences)
- Link to program application

SCREEN E — /book page (replace current 404):
- Heading: "Book Your Free Consultation"
- Embedded scheduling widget (Calendly or equivalent placeholder)
- Below: "Or apply via the program form and Konstantinos will call you"
- Phone number visible: [+30 XXX XXX XXXX]
```

## Step 4 — Components

```
Build these components after screens are approved:

COMPONENT 1 — Sticky mobile CTA bar:
- Fixed to bottom of viewport on mobile only (≤768px)
- Left: phone icon + "Call" text (tel: link, #2E86AB)
- Right: WhatsApp icon + "WhatsApp" text (#25D366 green)
- Background: white, 1px top border #E8F4F8
- Height: 56px, full width

COMPONENT 2 — Programme benefit card:
- F4F9FC background, 10px radius, 1px #E8F4F8 border
- Icon (physiotherapy/movement theme) top-left
- Heading: Nunito 700 20px #1B4F72
- Body: 16px #5D6D7E
- Hover: subtle box-shadow 0 4px 12px rgba(0,0,0,0.08), lift 2px

COMPONENT 3 — Testimonial video card:
- 16:9 thumbnail with play button overlay
- Patient name + outcome quote below (2 lines max)
- "Real Stories" badge (navy pill label)
- Grid: 2-up on desktop, 1-up on mobile

COMPONENT 4 — Guarantee badge:
- Shield icon (solid #2E86AB)
- Headline: "My Guarantee" (Nunito 700 18px #1B4F72)
- Body: "1 extra month free if you complete the program and need more support"
- Background: E8F4F8, 10px radius, navy left border accent (3px)

COMPONENT 5 — Nav header:
- Logo left (Ενεργός Ζωή / Trust Your Physio wordmark)
- Links: Program / Digital Guides / About (text, #5D6D7E, 15px)
- CTA: "Book Free Consultation" (#2E86AB button, white text, 8px radius)
- Mobile: hamburger → full-screen overlay with same links + sticky phone/WhatsApp bar at bottom
```
