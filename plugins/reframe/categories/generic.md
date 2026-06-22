---
category: generic
display_name: Generic
detect_signals: []
---

# Generic — Redesign Pack

## Redesign priorities
1. Establish a clear single purpose above the fold — a visitor must understand what this site does within 5 seconds of arriving.
2. Define one primary conversion action and make it unmissable; remove or demote all competing CTAs on the homepage.
3. Reduce navigation depth: if a visitor needs more than 2 clicks to reach any primary goal, flatten the IA.
4. Replace vague adjectives ("innovative", "world-class", "seamless") with concrete specifics — numbers, outcomes, named features.
5. Ensure every page has exactly one job; consolidate pages that do the same job.

## Conversion patterns
- Single hero CTA — one button, one destination, benefit-led copy (not "Learn more").
- Progressive disclosure: lead with the answer, follow with the evidence (inverted pyramid).
- Anchor contact/action above the fold on mobile; do not hide it below a scroll or in a hamburger.
- Social proof near the CTA — a brief quote or stat directly adjacent to the conversion trigger, not on a separate testimonials page.
- Friction reduction: minimise form fields to the fewest needed; show inline validation.

## Trust signals
- Specificity over claims: named clients/customers, exact numbers, dated outcomes.
- Authorship and accountability: a real name, face, and credentials for the person behind the product or service.
- Transparency: clear pricing (or a clear reason why pricing is contact-based), shipping or service terms, return/cancellation policy.
- Third-party validation: verifiable logos, certifications, or review-platform links (not screenshots of stars).

## IA conventions
- Homepage / About / Services or Products / Contact — the minimal viable structure.
- Footer: full NAP (name, address, phone), legal links, and a second chance at the primary CTA.
- Every top-nav item should represent a distinct audience goal, not a company department.
- Blog or Resources is optional at launch; add it only if the team can sustain it.

## Design-system seed (opinionated)
- Palette: #0F172A (near-black, primary text), #FFFFFF (background), #2563EB (action/CTA), #F1F5F9 (surface/card), #64748B (secondary text). Ratio: white dominates, one accent, one dark.
- Type: body — Inter or Source Sans 3 (both system-fallback-friendly); UI — same family at a slightly heavier weight; headings — cap the size at 3rem desktop; min 16px body.
- Spacing/radius/motion: 8-point base grid; radius 6–8px (rounded but not pill); transitions 150ms ease-out; no parallax, no scroll-jacking.
- Borders vs shadows: prefer 1px border at low-opacity over drop shadows for cards; reserve shadow for floating elements (modals, tooltips).

## Reference sites
- **Stripe.com** — specificity in hero copy, clean information hierarchy, one dominant CTA per scroll section.
- **Linear.app** — minimal, purposeful motion, confident typography, no noise.
- **Notion.so** — layered proof: claim → concrete example → social proof, predictable rhythm.
- **Buttondown.com** — small product, maximum clarity; shows you can say everything on one scrolling page without confusion.

## Anti-references & strict NOs
- **Wix ADI defaults** — generic stock imagery + centre-aligned everything = visual mud.
- **GoDaddy template sites** — three competing CTAs on the hero, six nav items, widget chaos.
- **Any site with a cookie banner that fills 40% of mobile viewport on arrival.**
- **Stock-photo hero of a smiling businessperson shaking hands** — instant credibility loss.

Strict NOs:
- NO gradient meshes or blobs that exist purely as decoration (use space and type instead).
- NO carousels on the hero — they hide the message from 80% of visitors.
- NO generic AI aesthetic: no floating 3-D orbs, no gradient-stroke sans-serif, no neon-on-dark "AI glow".
- NO hamburger menus on desktop.
- NO lorem ipsum shipped in a deliverable.
- NO full-viewport auto-play video as the first content element.
- NO sticky headers taller than 64px.

## Emphasize in the brief
1. **The single job of the homepage:** what specific action should a first-time visitor take, and where does the current design bury or obscure it?
2. **Credibility via specificity:** identify the three vaguest claims on the site and replace each with a concrete, verifiable alternative.
3. **Mobile-first conversion path:** trace the primary conversion from a cold phone visit — every friction point must surface as a discrete fix.
