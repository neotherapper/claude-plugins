---
category: residential-brokerage
display_name: Residential Brokerage
detect_signals: ["property", "properties", "listing", "listings", "real estate", "bedrooms", "bathrooms", "sqft", "sq m", "for sale", "for rent", "schedule viewing", "book viewing", "request info", "inquire", "agent", "broker", "realtor", "MLS", "RealEstateListing", "schema.org/RealEstateAgent", "open house", "price reduced", "neighborhood", "school district", "valuation", "home value", "market report", "virtual tour", "floor plan", "lot size", "acreage", "Rightmove", "Idealista", "immobilienscout", "se loger"]
---

# Residential Brokerage — Redesign Pack

## Redesign priorities
1. **Property discovery must be frictionless** — search bar above the fold with location/type/price; filters must not require a tutorial; every additional click between landing and listing detail costs conversion. The search UX is the product.
2. **Agent trust must be woven into every listing, not siloed on an "About" page** — each listing card shows the assigned agent's face; each detail page has a sticky agent sidebar; the team page is one click from anywhere. For agencies under 3 years old, lead with agent credentials and service quality over firm longevity.
3. **Mobile-first execution is non-negotiable** — 60%+ of real estate traffic is mobile; click-to-call on every page; sticky bottom CTA bar; swipeable photo galleries; touch targets ≥44px. Design for small screens first, then scale up.
4. **Price and key facts must never be hidden** — beds/baths/sqft/price appear above the fold on every listing card and detail page; no "register to see price" walls. Price transparency is a trust signal.
5. **Multilingual and multi-currency must feel native, not bolted on** — language switcher with native names (Ελλληνικά not "Greek"); currency toggle; measurement units adapt (sqft/m², acres/hectares); hreflang for SEO. 76% of buyers prefer content in their own language.
6. **Conversion path clarity** — the brief must map the current path from landing → inquiry/viewing booking and count every click and field; anything above 3 clicks or 3 fields is a redesign target. 78% of local real estate searches lead to action within 24 hours.

## Conversion patterns
- **Search bar as primary homepage element** — location field with typeahead, property type dropdown, price range; positioned above the fold, visually dominant. Not buried below hero imagery. The search UX is the first impression.
- **Inquiry form max 3 fields** — Name, Email, Phone. Every extra field drops conversion 5-10%. No "budget range", "move-in date", or "how did you hear about us" on the first touch. Capture the lead, qualify later.
- **Viewing booking as a distinct CTA** — "Schedule Viewing" or "Book Tour" with date/time preference; separate from general inquiry; low-commitment framing ("No obligation"). Video listings get 403% more inquiries than those without.
- **Click-to-call on mobile** — sticky `tel:` button in header/footer bar on every page. Phone numbers must be tappable, not in small print. 71% of buyers find property via mobile.
- **WhatsApp floating button** — essential for international buyers; positioned bottom-right; pre-filled message with property code. 76% of customers prefer products in their own language; WhatsApp bridges language gaps.
- **Save/favorite with email capture** — heart icon on every listing card; guest users prompted for email to save; logged-in users save directly. Drives repeat visits and builds remarketing list.
- **Valuation tool as seller lead magnet** — "What's your home worth?" on homepage and search pages; captures seller leads who aren't ready to list yet. High-converting, low-commitment entry point.
- **Agent-assigned inquiry** — when a user inquires on a listing, the inquiry goes to the specific agent shown on that listing, not a generic inbox. Personal connection drives faster response and higher conversion.
- **Urgency without manipulation** — "New" and "Price Reduced" badges on listing cards are honest signals; no fake countdown timers or "3 people viewing this" fabrication. Trust is the product.

## Trust signals
- **Agent headshots with personality** — real photos, not corporate stock. Name, license/registration number, years active, specialties, and a short human note. A smiling headshot outperforms a stock image of a handshake every time. Video testimonials convert 25-35% higher than text.
- **Transaction count and volume** — "500+ properties sold", "€50M in transactions" — placed on homepage hero strip and agent bios. Concrete numbers beat vague "trusted leader" claims. For agencies under 3 years old, replace with individual agent experience metrics ("15 years in the market").
- **Google/Trustpilot review count and rating** — linked, not screenshotted. Placed on homepage and each agent page. 93% of consumers consult reviews before purchase; real review count matters more than a 5-star average from 3 reviews.
- **Years in business** — "Est. 2005" or "20+ years in [region]" — signals stability. Place on homepage and About page. If absent or <3 years, the brief flags "new agency" and pivots trust strategy to agent credentials + service quality.
- **Local expertise content** — neighborhood guides, area descriptions, school catchment info, local market reports. Demonstrates knowledge, not just listings. 26% of homebuyers want to move to a different part of the country; local content captures them.
- **Professional credentials** — Realtor®, CRS, ABR, SRES, or local equivalent (KMEPE in Greece, RICS internationally). Logos near CTAs, not buried in footer. Baseline trust signal.
- **Media mentions** — "As Seen In" logo strip (local press, industry publications). Transfers credibility through association. Even one local newspaper mention adds legitimacy.
- **Team/office photography** — real team shots, office exterior, behind-the-scenes. Fights "anonymous website" perception. Humanizes the brand.
- **Response time promise** — "Average response time: 30 minutes" or "Available 7 days a week". Top signal buyers use to evaluate agents pre-contact. Easier to guarantee when you're small — new agencies should lean into this.
- **Legal/regulatory clarity** — license number, regulatory body, professional indemnity insurance. Required in many jurisdictions; absence signals illegitimacy. Place in footer on every page.

**New agency adaptation:** For agencies under 3 years old, emphasize agent credentials over agency track record. Individual experience (years in industry, previous firm, certifications) substitutes for firm longevity. Local personal network ("our connections with notaries, lawyers, architects ensure smooth transactions") becomes the value proposition. Service quality over volume: "We handle every transaction personally" beats "500+ sold".

## IA conventions
- **Nav:** Home / Buy (Properties for Sale) / Rent / Sell (Valuation) / About & Team / Contact + language/currency switcher in top bar.
- **Buy sub-nav:** By property type (Houses, Villas, Apartments, Commercial, Land) + by status (New, Price Reduced, Open House) + by location (region/city dropdown).
- **Rent sub-nav:** Apartments, Houses, Commercial spaces — mirrors Buy structure.
- **Home:** Hero (property search bar + aspirational location imagery) → featured listings carousel → property type cards → agent highlight strip → trust signals (years, reviews, transaction count) → neighborhood/area content → footer CTA.
- **Search/listing page:** Filter sidebar (price, type, beds, baths, sqft, lot size, keywords) + grid/list toggle + map view toggle + sort (newest, price low-high, price high-low) + result count + pagination. Split-panel IA (gallery left, details right) for listing detail.
- **Listing detail:** Photo gallery (20+ photos, lightbox, video/3D tour embed) → key facts bar (price, beds, baths, sqft, lot size) → description (150-250 words, first sentence includes location + primary selling point for SEO) → interactive map showing nearby amenities → floor plan → mortgage calculator → agent sidebar (sticky on desktop: photo, name, phone, email, CTA) → similar properties carousel.
- **Agent page:** Headshot + bio emphasizing local expertise + credentials + active listings grid + reviews/testimonials with real names + contact methods (phone, email, WhatsApp, scheduling link).
- **Sell/Valuation:** "What's your home worth?" tool → property details form → instant estimate or agent callback → recent comparable sales. High-converting seller lead magnet.
- **Contact:** Full NAP, embedded map, opening hours, parking/transport, contact form, WhatsApp button, social links.
- **Journey shape (buyer):** Search → Listing detail → Trust check (agent page/reviews) → Inquiry/Viewing booking → Confirmation. Every page funnels toward the agent contact CTA.
- **Journey shape (seller):** Homepage or Sell page → Valuation tool → Agent consultation booking → Listing agreement.

## Design-system seed (opinionated)
- Palette: #0D2A4A (deep navy — primary/headers, trust and authority; used by Compass, Douglas Elliman), #F7F5F0 (warm gallery white — background; used by K11 ARTUS, Sotheby's), #C9A96E (warm gold — CTA accent, signals premium; used by Century 21 Digital, LUXE, Barry Cohen), #E8E3D9 (vellum cream — listing card surfaces), #5A6B7A (slate gray — secondary text), #184A45 (forest green — success/available badges), #8D312E (muted red — price reduced badges, not aggressive). The palette reads "trusted local expert", not "bank website" or "luxury-only".
- Type: headlines — Playfair Display (serif, the dominant luxury real estate headline font; signals lifestyle gravitas; used by The Coloradan, Sotheby's); body — Inter (sans-serif, clean, highly legible at 17px; used by Compass, FIND Real Estate); UI/utility — DM Sans (geometric sans, form labels, filters, metadata). Scale: H1 48-64px desktop / 28-36px mobile; H2 24-32px; body 17-18px; line-height 1.5. Serif headline + sans body is the dominant award-winning pattern in real estate.
- Spacing/radius/motion: generous whitespace as brand expression (80-100px section padding desktop, 48-64px mobile; Sotheby's model); radius 6-8px on cards and inputs (subtle, not pill); standard motion: subtle fade-in on scroll, card hover lift with shadow transition, 120-150ms ease; premium motion: GSAP scroll animations for luxury microsites; no motion on search and inquiry forms. Photography as the only color — neutral interface lets images carry visual weight (Compass model).
- Borders vs shadows: 1px borders on form inputs (not shadow); light box-shadow `0 2px 12px rgba(0,0,0,0.06)` on listing cards (subtle lift); no heavy drop shadows (too "sales-y"); hero section uses full-bleed image with text overlay, no border. 12-column grid desktop, 4-column mobile. Listing card gap: 24-32px. Max content width: 1200-1400px.

## Reference sites
- **Compass (compass.com)** — The gold standard for modern brokerage UX. 3-font system, black-and-white-only interface where photography carries all color, Collections collaborative shortlisting. Demonstrates how to be premium without being fussy. Use as the IA and interaction benchmark.
- **Village Properties (villageproperties.com)** — Regional brokerage done right. Santa Barbara identity woven through arched frames, terracotta/cream palette, local architectural motifs. Proves a regional brokerage can be design-forward without enterprise budget. Use as the "regional identity" benchmark.
- **Sotheby's International Realty (sothebysrealty.com)** — Lifestyle-first IA. Editorial magazine integration, curated neighborhood content, agent-as-storyteller model. Shows how to sell aspiration, not just square footage. Use as the content and editorial benchmark.
- **Di Jones (dijones.com.au)** — Sydney brokerage with animated hero, orange CTAs, Montserrat/Open Sans pairing. Demonstrates how a mid-market regional brokerage can feel modern without luxury pretension. Use as the "accessible modern" benchmark.

## Anti-references & strict NOs
- **Generic template brokerage sites** — WordPress themes with stock hero images, no brand personality, identical to 10,000 other sites. These exist to fill space, not to convert.
- **Zillow/Rightmove clone attempts** — portal UX on a brokerage budget. You don't have the traffic to support that model. A brokerage is not a portal.
- **Over-designed luxury microsites** — custom cursors, ambient audio, 10-second scroll animations on a 3-agent brokerage. The design must match the business size and audience.
- **Agent photo sites with no property search** — all team headshots, no listings. The agent page is important but not the homepage.

Strict NOs:
- NO "Register to view price" walls — kills conversion; price must be visible on every listing card. 84% of buyers refuse to use non-mobile-friendly sites; registration walls are worse.
- NO hero carousels with 4+ competing CTAs — one hero, one CTA, one message. Award-winning sites use single-purpose heroes.
- NO stock photography (handshakes, keys, generic city skylines, Canva-generated banners) — use real property photos and real team headshots only.
- NO forms with more than 3 fields on initial capture — every extra field drops conversion 5-10%.
- NO buried phone numbers — click-to-call in header on every page, tappable on mobile.
- NO auto-play video in hero on mobile — slow, intrusive, often muted anyway.
- NO "Welcome to our website" hero copy — get to the search bar or the value proposition immediately.
- NO missing alt text on property photos — heavily used by screen readers and search engines.
- NO fake urgency ("3 people viewing!", "Limited time!") — honest badges only (New, Price Reduced).
- NO unbranded third-party redirects for inquiry or viewing booking — explain if it happens, or keep it native.
- NO dark patterns for cookie consent or newsletter signup — respect the user.
- NO desktop-first design — 60%+ of traffic is mobile; design for small screens first.

## Emphasize in the brief
1. **Property search friction audit:** Load the homepage — how many clicks from landing to viewing a listing detail? Count the fields in the search form. Map the full path from search → listing → inquiry → confirmation. Every step above 3 clicks or 3 fields is a redesign target. 100ms improvement in load time = 7-10% conversion lift.
2. **Trust-signal placement check:** Do agent headshots, credentials, review count, and transaction volume appear on the homepage and on each listing detail page — not only on a dedicated "About" page that most visitors never reach? If trust is siloed, the brief must fix it. Trust badges adjacent to forms/conversion points = 15-30% conversion lift.
3. **Mobile conversion path:** Load the homepage on a phone — can a visitor search, tap a listing, see the price, and call or inquire within one thumb-reach without zooming? If not, the entire mobile layout is a priority redesign target. Target LCP < 2.5s, INP < 200ms, CLS < 0.1.
