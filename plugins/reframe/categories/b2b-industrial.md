---
category: b2b-industrial
display_name: B2B / Industrial Distributor
detect_signals: ["request a quote", "request quote", "RFQ", "get a quote", "quote", "datasheet", "data sheet", "spec sheet", "technical specifications", "MOQ", "minimum order", "lead time", "bulk pricing", "wholesale", "distributor", "authorized distributor", "OEM", "supplier", "spare parts", "spares", "industrial", "manufacturer", "catalogue", "catalog", "part number", "SKU", "marine", "valves", "bearings", "on-board repair", "after-sales", "B2B"]
---

# B2B / Industrial Distributor — Redesign Pack

## Redesign priorities
1. The primary conversion is **"Request a Quote" / RFQ**, not checkout — even if a WooCommerce/store plugin is installed, do not optimise a cart funnel; optimise the quote/enquiry path and the product-find path that feeds it.
2. Make the catalogue **findable and filterable** — buyers arrive knowing a part number, brand, or spec; surface search, category filters, and part-number lookup before marketing copy.
3. Every product/category page must answer "can they supply *my* exact part, in *my* quantity, in *my* timeframe?" — datasheet, part number, MOQ, lead time, and a quote CTA on every PDP.
4. Establish supplier credibility: years in business, brands/OEMs represented, certifications (ISO, class approvals), and real client/sector logos — B2B trust is institutional, not consumer-emotional.
5. Treat the site as a **sales-enablement tool**: downloadable catalogues/brochures, clear contact routes to a human (phone, email, named reps), and fast response promises.

## Conversion patterns
- **"Request a Quote" as the single primary CTA** — per product, per category, and global. A quote form captures part/brand/quantity/timeframe; never force account creation first.
- **Part-number / brand search** prominent in the header — the fastest path to "do you have it?".
- **Downloadable assets** (catalogue PDF, datasheets, brochures) as a secondary conversion and lead capture.
- **Dead/demo store pages are a liability** — if a checkout exists but is non-functional or unused, remove or convert it to enquiry; a broken cart erodes B2B trust faster than no cart.

## Trust signals
- Years/heritage stated concretely (founding year + "X years supplying Y").
- Brands / OEMs / principals represented (logos, named lines).
- Certifications and class approvals (ISO 9001, marine class societies, industry bodies).
- Sector/client references and case examples; real premises, warehouse, and team photos.
- Named contacts and fast-response commitments (B2B buyers want a human and an SLA).

## IA conventions
- **Nav:** Home / Products (or Catalogue, with categories) / Brands / About / Contact / Request a Quote.
- **Home:** what you supply + to whom → search/part-lookup → product/category cards → brands represented → credibility strip (years, certs) → quote CTA.
- **Products:** category index (filterable) → product/category pages with specs, datasheet, part number, MOQ, lead time, quote CTA.
- **Brands:** the OEMs/principals carried, each linking to its catalogue subset.
- **Journey shape:** technical search → product/category page → spec/datasheet check → Request a Quote → human follow-up.

## Design-system seed (opinionated)
- Palette: #14304F (industrial navy, primary), #0E7C9B (technical cyan, CTA/links), #F4F6F8 (surface/light grey), #FFFFFF (base), #2A2F36 (body text), #E2A100 (caution/accent for badges only). Reads "engineering-grade and dependable", not consumer-retail.
- Type: body — Inter or IBM Plex Sans (technical clarity, good at dense spec tables; IBM Plex if Greek/Cyrillic glyphs needed); headings — same family Bold; mono (IBM Plex Mono / JetBrains Mono) for part numbers and spec values.
- Spacing/radius/motion: dense but scannable spec tables; radius 4–6px (engineered, not playful); minimal motion (120ms ease); no decorative animation.
- Borders vs shadows: 1px borders dominate (tables, cards, spec rows); shadows reserved for dropdowns/overlays. Tables are a first-class component, not an afterthought.

## Reference sites
- **RS Components (rs-online.com)** — part-number search, filterable catalogue, datasheets, technical depth without consumer fluff.
- **Grainger (grainger.com)** — industrial catalogue scale, strong search/filtering, quote/account paths.
- **Misumi (misumi.com)** — configurable parts, spec-first product pages.

## Anti-references & strict NOs
- **Consumer-ecommerce templates** with lifestyle hero imagery and "Add to Cart" emotional copy — wrong register entirely for a quote-driven B2B buyer.
- **Dead WooCommerce/demo store pages** left live (the `amarsolutions` failure) — they make the site score as ecommerce and signal neglect.

Strict NOs:
- NO forced cart/checkout for products that are actually quote-only.
- NO hiding part numbers, datasheets, MOQ, or lead time behind a contact wall.
- NO account-creation gate before a quote request.
- NO stock "handshake / corporate teamwork" imagery in place of real product/warehouse/team photos.
- NO burying the catalogue under marketing pages — search and categories come first.
- NO vague "quality products and solutions" copy — name the brands, specs, and sectors.

## Emphasize in the brief
1. **Quote-path audit:** map the current path from "I know my part" to "I've sent an RFQ" — count clicks and dead ends; any non-functional store pages are removal/convert targets.
2. **Catalogue findability:** is there part-number/brand search and category filtering? If not, that is the priority build.
3. **Credibility surface:** are years-in-business, brands represented, and certifications visible on the homepage and product pages, not just buried in About?
