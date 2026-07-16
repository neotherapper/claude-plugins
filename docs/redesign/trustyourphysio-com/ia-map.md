# Trust Your Physio — Information Architecture

## Navigation hierarchy

**Primary nav (current):**
- Home
- Online Physiotherapy
- Home Physiotherapy
- Musculoskeletal Conditions
- Sports Physiotherapy
- About
- Blog
- Contact
- [EN language toggle]
- [Phone: 698 594 1957]
- [Book Free Call — CTA button]

**Footer nav (current):**
- Αρχική (Home)
- Σχετικά (About)
- Blog
- Πρόγραμμα (Programme)
- Τιμές (Pricing)
- Επικοινωνία (Contact)

**Proposed nav (redesign):**
- Home
- Programme (replaces "Online Physiotherapy" — clearer product name)
- Services ▾ (dropdown: Home Visits / MSK / Sports)
- About
- Blog
- Contact
- [EL | EN language toggle — header, right-aligned]
- [tel: +30 698 594 1957 — mobile sticky bar]
- [Book Free Call — primary CTA, header]

## Page purposes

| URL | Template | Subject · Audience · Job |
|-----|----------|--------------------------|
| / | homepage | 8-week online physio programme for knee/hip pain · Pain-motivated adults 50+ in Greece · Convert cold visitor to "Book Free Call" applicant |
| /about | solo-bio | Practitioner credentials, story, philosophy · Sceptical patient verifying who they'd trust · Build personal trust sufficient to proceed to booking |
| /programme | product-detail | Active Life Programme — 4 phases, 16 sessions, pricing, guarantee · Warm lead who clicked CTA but wants full detail · Remove objections and collect application |
| /services/home-visits | service-page | Athens in-home physio sessions · Athens-local patients preferring in-person · Generate booking inquiry via call or form |
| /services/musculoskeletal | service-page | MSK conditions treated · Adults with back/neck/joint pain · Educate on approach and funnel to booking |
| /services/sports | service-page | Sports physiotherapy and injury rehab · Active adults 30–50 · Generate booking inquiry |
| /guides | product-listing | Downloadable evidence-based PDF guides · Self-managing patients · Stripe purchase (secondary revenue) |
| /blog | content-hub | Physiotherapy advice articles · Organic search / awareness · Build authority and capture discovery traffic |
| /contact | contact | Full NAP, map, phone, WhatsApp, contact form · Patient ready to make contact · Provide zero-friction route to any contact channel |

## Journeys

**Primary journey — "Knee pain → Active Life Programme booking"**
1. Cold entry: YouTube video or Google search "φυσιοθεραπεία γόνατο σπίτι" → Homepage
   - *Objection to resolve:* "Is this a real physio or a scam?"
2. Scroll to practitioner bio + video testimonials
   - *Objection to resolve:* "Does this work for people like me?"
3. Click "Book Free Call" → Application form
   - *Objection to resolve:* "What am I committing to and what will it cost?"
4. Submit form → Confirmation page / email
   - *Objection to resolve:* "What happens next?"
5. Free call with Konstantinos → Programme enrolment

**Secondary journey — "Home visit in Athens"**
1. Entry: Google Maps / local search "physiotherapist Athens home visit"
2. Homepage or /services/home-visits → credentials + location check
3. Click-to-call (`tel:`) or contact form

**Secondary journey — "Self-managing patient / PDF guide"**
1. Entry: blog post or social media → /guides
2. Browse guide listing → Stripe checkout (low-friction, no call required)

## Primary conversion path

Cold visit → Homepage hero → Trust strip (credentials + reviews) → Programme overview (4 phases) → Patient video testimonials → Pricing anchor + guarantee → "Book Free Call" CTA → Application form (8 fields) → Confirmation → Free discovery call → Programme enrolment

**Critical decision point:** The application form is the conversion gate. If the visitor reaches it, the submission rate depends on form field count, clarity of what happens next, and visible trust signals on the form page (credentials badge, guarantee reminder).

**Current path friction count:** Homepage → "Book Free Call" → Form = 2 steps (acceptable). Risk is abandonment on the form due to pricing uncertainty and absence of insurance clarity on the form page itself.
