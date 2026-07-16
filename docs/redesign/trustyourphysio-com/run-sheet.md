# Trust Your Physio — Run Sheet

Sequential canvas prompts. Paste each block into Claude Design in order. Do not skip the validate step.

## Step 1 — Validate

```
I'm redesigning trustyourphysio.com — a solo-practitioner online physiotherapy practice in Athens, Greece.
The brief and design-system seed are in brief.md. Before generating screens, confirm:

1. Palette: primary #1B4F72, CTA #2E86AB, background #FFFFFF, surface #F4F9FC — apply as CSS custom properties.
2. Font: Nunito 17px body, 700 weight headings — confirm Greek character set is supported.
3. The sticky mobile header (56px) must contain: logo left / tel: +30 698 594 1957 center / "Book Free Call" button right.
4. All CTAs labeled "Book Free Call" link to the application form section.
5. No stock medical imagery — use placeholder blocks labeled [REAL PHOTO: Konstantinos headshot] and [REAL PHOTO: patient testimonial].

Acknowledge the constraints and show the design-system token set before proceeding to the first screen.
```

## Step 2 — Key screen

```
Design the homepage hero section for trustyourphysio.com.

Content:
- H1: "End knee and hip pain in 8 weeks — from home, with a certified physio."
- Sub: "Evidence-based rehabilitation programme. 16 sessions. Personalized to you. From Athens, Greece."
- Primary CTA button: "Book Free Call" (#2E86AB background, white text, 10px radius)
- Secondary link: "Learn how it works ↓"
- Trust strip immediately below hero: [Credential badge: Konstantinos Varvagiannis, Physiotherapist] + [ΠΦΣ registration badge placeholder] + [★ 4.9 · 47 reviews — link to Google] + [Self-pay · No referral required]
- Left/right layout on desktop: left = headline + CTAs + trust strip; right = [REAL PHOTO: Konstantinos headshot, warm background]
- Mobile: stacked; photo above fold is 40vh, headline below; sticky bar at bottom with tel: and Book Free Call.

Apply the design system seed from brief.md. No animations on CTA. Return the hero + trust strip as a single artboard.
```

## Step 3 — Remaining screens

```
1. PROGRAMME OVERVIEW SECTION (homepage scroll — severity 3: pricing absent)
Design the "Active Life Programme" section as it appears on the homepage scroll.
Content: 4 phase cards in a horizontal row (desktop) / vertical stack (mobile).
Phase 1: Safety & Understanding (4 sessions) · Phase 2: Movement with Control (4 sessions) · Phase 3: Body Support (4 sessions) · Phase 4: Consistency & Autonomy (4 sessions).
Below cards: programme summary row — "8 Weeks · 16 Sessions · 100% Online · Lifetime access to materials."
Below summary: pricing block — "Active Life Programme — €[PRICE] · Includes 1 free extra month if you need it."
CTA: "Apply Now — Book Free Call" button.
Card style: #F4F9FC background, 10px radius, 1px border #E8F4F8, phase number in #1B4F72 large display type.

2. PRACTITIONER BIO SECTION (homepage scroll — severity 3: credentials buried)
Full-width section, #E8F4F8 background band.
Left: [REAL PHOTO: Konstantinos, smiling, professional], right: name (Konstantinos Varvagiannis) in H2, "Certified Physiotherapist · Athens, Greece" subtitle, credential letters + registration number, 3-bullet personal commitment ("I commit to working with you step by step..."), guarantee badge: "Complete the programme — or get 1 free extra month of guidance."

3. TESTIMONIALS SECTION (homepage scroll)
Section heading: "What patients say."
4 cards in 2×2 grid (desktop) / vertical (mobile): each card has real patient name, video thumbnail placeholder [VIDEO: Βασιλική], and a pull-quote. Warm background #FFF8F0 per card, 10px radius.

4. /CONTACT PAGE (severity 2: NAP incomplete, no WhatsApp)
Page layout: left column = contact details (full NAP, click-to-call, WhatsApp/Viber button, email @trustyourphysio.com); right column = embedded Google Map placeholder (Athens) + opening hours table.
Below: short contact form (Name, Email, Phone, Message — all optional except Name).
Footer NAP block: repeat full Name/Address/Phone/Email in footer for SEO consistency.
```

## Step 4 — Components

```
Design the following reusable components in the established design system:

1. STICKY MOBILE HEADER (56px height)
   Left: logo (text "TrustYourPhysio" in #1B4F72 Nunito 600); Center: [tel: +30 698 594 1957, tap-target 44px]; Right: "Book Free Call" button (#2E86AB, white text, 8px radius, 44px height).

2. SERVICE CARD (for /services/* index and homepage services strip)
   #F4F9FC background, 10px radius, condition icon placeholder, H3 service name in plain language, 2-line description, "Book Free Call →" text link. Width: 1/3 desktop, full mobile.

3. PDF GUIDE CARD (for /guides listing)
   White card, 1px border, PDF badge top-right, guide title (Greek + EN), 3 bullet "what you'll learn," price, "Buy — Secure Stripe payment" button in #2E86AB.

4. FAQ ACCORDION ITEM
   Question in Nunito 600 #1B4F72, chevron right, answer in Nunito 400 #5D6D7E 17px. No motion — simple show/hide. Max 8 items.

5. WHATSAPP / VIBER CTA BUTTON
   Secondary CTA for contact page and homepage footer: WhatsApp green #25D366 or Viber purple #7360F2, white icon + "Message us on WhatsApp", 10px radius, 44px height.
```
