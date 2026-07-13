# Trust Your Physio — Content Inventory & Audit

**Pages enumerated:** ~9 (Home, About, Programme, Home Physio, MSK, Sports, Guides, Blog, Contact — inferred from nav)   **Pages audited:** 1 (Homepage — SPA render from prior session)   (additional pages returned near-empty static HTML; /about and /contact SPA text not available — Chrome timed out on second attempt)

| URL | Template | Page type | Purpose | Verdict | ROT/quality flags | Notes |
|-----|----------|-----------|---------|---------|-------------------|-------|
| / (homepage) | homepage | Homepage | Convert cold visitors to "Book Free Call" applicants; present the Active Life Programme; establish practitioner trust | revise | Thin above-fold trust signals; pricing absent; phone buried in footer; hero copy generic; Greek/EN content imbalance below fold | Has authentic testimonials and strong programme structure — good bones, weak first impression |
| /about | solo-bio | About / practitioner bio | Establish personal credibility of Konstantinos Varvagiannis | unknown (SPA not rendered) | — | Infer from homepage footer content: name, city, personal commitment statement present; full credentials unknown |
| /programme | product-detail | Product detail | Detail the 8-week Active Life Programme | unknown (SPA not rendered) | — | Programme structure is on homepage; dedicated page likely exists (footer nav: "Πρόγραμμα") |
| /services/home-visits | service-page | Service | Athens home-visit physiotherapy | unknown | — | Nav item present; content not crawled |
| /services/musculoskeletal | service-page | Service | MSK conditions treatment | unknown | — | Nav item present; content not crawled |
| /services/sports | service-page | Service | Sports physiotherapy | unknown | — | Nav item present; content not crawled |
| /guides | product-listing | Product listing | Sell downloadable PDF guides via Stripe | keep | Low-risk secondary revenue; Stripe already integrated; content thin (2 guides visible on homepage) | Consider expanding to 5–8 guides for SEO breadth |
| /blog | content-hub | Blog | Authority / organic discovery | revise | Currently unknown depth; blog as standalone nav item suggests active use | Ensure each post has: unique meta description, H1, internal link to programme CTA |
| /contact | contact | Contact | Provide full NAP and contact channels | revise | Inferred incomplete: Gmail address visible; street address not found in homepage text; no WhatsApp CTA visible | Add street address (Athens), WhatsApp/Viber button, embed Google Map |

**Verdict legend:** keep / revise / consolidate / remove — each tied to driving applications to the Active Life Programme.

**Listed-not-audited:** /about, /programme, /services/home-visits, /services/musculoskeletal, /services/sports, /blog, /contact — all SPA routes not rendered in this session. Re-audit with a headless render pass in a full production run.
