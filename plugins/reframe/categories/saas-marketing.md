---
category: saas-marketing
display_name: SaaS Marketing
detect_signals: ["pricing", "signup", "sign up", "sign-up", "demo", "request a demo", "book a demo", "features", "docs", "documentation", "free trial", "start for free", "get started", "app.", "dashboard", "integrations", "changelog", "roadmap", "API", "enterprise", "per seat", "per month", "annual plan"]
---

# SaaS Marketing — Redesign Pack

## Redesign priorities
1. Communicate the core value proposition in under 5 seconds — a cold visitor reading the hero must understand what the product does, who it is for, and why it is different without scrolling.
2. Convert landing interest into a trial/signup or demo request — the hero CTA is the most important element on the site; everything else defers to it.
3. Prove the claim with social proof that is specific and verifiable — logos of named customers, outcome-tied testimonials, and a believable review count; vague "trusted by thousands" is invisible.
4. Make pricing transparent and anxiety-reducing — even if you have a contact-for-enterprise tier, the baseline pricing page must resolve "can I afford this?" before the visitor leaves.
5. Let the product speak: UI screenshots, short demo video, or an interactive sandbox in the hero or immediately below it — abstract claims without product evidence generate doubt.
6. Establish developer/integration trust if applicable: a docs link in the nav, API mention in the footer, changelog visibility; shows the product is maintained and real.

## Conversion patterns
- **Hero CTA hierarchy:** primary = "Start free trial" or "Get a demo" (one, not both in equal weight); secondary = "See how it works" (scroll-anchored or short video).
- **Pricing page as a conversion page** — not just a table; include a per-tier FAQ, a recommended plan callout, an annual/monthly toggle, and a "talk to us" option for enterprise. Visitors who reach pricing are high intent; do not lose them to ambiguity.
- **Social proof placement:** logo strip immediately below the hero fold; a detailed testimonial (outcome + company + name + role) near the pricing CTA; a G2/Capterra badge if ratings are strong (4.5+).
- **Demo booking as a conversion** — if the product requires a sales conversation, a Calendly-style inline booking experience on the demo page converts better than a "fill this form and we'll call you back" pattern.
- **In-product redirect:** the signup flow should land users in a working state (pre-populated workspace, guided onboarding) within 2 minutes of account creation — the marketing site's job ends at signup; do not let onboarding friction reverse the conversion.

## Trust signals
- **Named customer logos** — real companies, not silhouettes or "Fortune 500 customers". Link logos to case studies where possible.
- **Outcome-tied testimonials** — "We reduced onboarding time by 40%" from a named person with a real job title; not "Great product, very useful".
- **Security and compliance badges** — SOC 2, ISO 27001, GDPR, HIPAA (where applicable) — in the footer and on the pricing page.
- **Docs and changelog visibility** — a maintained, public changelog signals a live product; a link to real documentation signals developer credibility.
- **Review platform links** — G2, Capterra, or Product Hunt rating widget (not a screenshot); third-party validation outweighs self-reported claims.

## IA conventions
- **Nav:** Product (or Features) / Pricing / Docs / Blog / (Case Studies or Customers) / (Changelog) / Contact or Get a Demo
- **Home:** Hero (value prop + CTA) → logo strip → feature highlights → social proof section → pricing teaser (or "Pricing starts at…") → final CTA.
- **Features/Product:** overview page + individual feature sub-pages (one job per page; these serve SEO and ad traffic).
- **Pricing:** tier cards → FAQ → testimonial → CTA. No dark patterns: no pre-selecting annual without clarity, no hiding the free tier below paid tiers, no asterisks that lead to 80% of the visible price.
- **Docs:** publicly accessible, structured, searchable — not a PDF, not a Notion link to a private page, not behind signup.
- **Blog:** only if the team publishes ≥2 pieces/month; otherwise remove from nav and keep a resources landing page.
- **Journey shape:** cold organic/paid → Landing/Features page → Pricing → Signup/Demo → Product onboarding. Design each handoff explicitly.

## Design-system seed (opinionated)
- Palette: #0A0A0A (near-black, headlines — confident), #FFFFFF (background), #6366F1 (action — indigo; distinctive from the ubiquitous SaaS blue without abandoning legibility), #F5F5F7 (surface/card), #6B7280 (body text/secondary). For dark-mode hero variant: #111827 background, #F9FAFB text. Keep the palette restrained — 2 neutrals, 1 action, no rainbow.
- Type: body — Inter (the SaaS default for good reason: optical clarity at small sizes); headings — the same Inter at 700–800 weight, or Cal Sans for a touch of personality without losing grid discipline. Avoid display novelty fonts — they age in 18 months. Min 15px body; 13px for UI labels.
- Spacing/radius/motion: tight 4-point grid for UI elements, 8-point for layout; radius 6px (cards, inputs) or full pill for CTA buttons; hero animations: max 400ms, ease-out, no looping — enter-once animations only; no parallax.
- Borders vs shadows: no shadow on primary cards — use subtle background color shift (#F5F5F7 vs #FFFFFF); soft shadow `0 1px 3px rgba(0,0,0,0.1)` only for modals and tooltips; dividers over shadows for section breaks.

## Reference sites
- **Linear.app** — best-in-class hero copy discipline, confident typography, restrained motion; the benchmark for "we're not trying too hard".
- **Loom.com** — product demo in the hero, strong social proof strip, pricing clarity; shows how to let the product sell itself.
- **Vercel.com** — developer-audience credibility, changelog visible, docs prominent, hero with real output not feature lists.
- **Clerk.com** — value prop in one sentence, interactive code snippet in hero, pricing table with no dark patterns; shows how a developer-focused SaaS earns trust without enterprise bloat.

## Anti-references & strict NOs
- **Any SaaS homepage with a hero tagline that includes "AI-powered", "next-generation", or "seamlessly"** without a single concrete example — meaningless claim stacking.
- **Feature-dump homepages** — 12 feature cards in a grid with identical icons and two-line descriptions; nobody reads it and it signals no clear differentiation.
- **Pricing pages with plan names like "Starter / Growth / Enterprise"** where all the compelling features are on the Enterprise tier with "Contact us" instead of a price.
- **Dark-mode-only SaaS sites** — alienates users who access in bright environments and signals design-over-function.

Strict NOs:
- NO vague hero tagline — the first line must name what the product does or who it is for; "The operating system for your team" is not a value prop.
- NO hero CTA that says "Learn more" — it is the lowest-converting button text; use a specific action.
- NO pricing table with hidden asterisks or footnotes that change the effective price.
- NO auto-play hero video with sound.
- NO 12-column feature grid as the second section — prioritise 3–4 differentiating features, not a complete product catalogue.
- NO "Request a demo" form that requires company size, industry, and use-case before a human responds — respect the visitor's time.
- NO signup wall on the docs — public documentation is a conversion tool, not a product gate.

## Emphasize in the brief
1. **Hero copy test:** apply the "5-second rule" — remove all visual design and read only the headline and subheadline in isolation. Do they tell a cold visitor what the product does, who it is for, and why they should care? If not, the hero rewrite is the single highest-leverage change.
2. **Pricing page conversion audit:** trace the journey from clicking "Pricing" to completing a trial signup or demo request — identify every decision point where the visitor can bounce and what information would resolve each hesitation.
3. **Social proof specificity:** audit every testimonial and customer logo for verifiability — each one that cannot be confirmed by a quick web search is doing zero trust work and should be replaced or removed.
