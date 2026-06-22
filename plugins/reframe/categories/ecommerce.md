---
category: ecommerce
display_name: E-commerce
detect_signals: ["/products/", "/product/", "/shop/", "/cart", "/checkout", "/collections/", "add to cart", "add-to-cart", "buy now", "add to bag", "product schema", "schema.org/Product", "schema.org/Offer", "out of stock", "in stock", "free shipping", "free returns", "size guide", "SKU", "variant", "Shopify", "WooCommerce", "BigCommerce", "Magento"]
---

# E-commerce — Redesign Pack

## Redesign priorities
1. Product discovery is the primary job of the homepage and category pages — a visitor who cannot find what they are looking for in under 3 interactions will not convert; navigation, search, and filtering must be first-class.
2. Product detail page (PDP) conversion is the revenue lever — the PDP must answer every objection (size, material, shipping cost, returns, social proof) before the visitor reaches the buy button.
3. Remove all friction between "add to cart" and "order confirmed" — the checkout must be short (3 steps maximum), guest checkout must be available, and shipping cost must not appear as a surprise on step 3.
4. Build returns/shipping confidence early and repeat it often — an explicit "free/easy returns" signal on the homepage, category page, and PDP is the single most effective trust mechanism for undecided buyers.
5. Mobile-first product browsing — the majority of discovery happens on mobile even when purchases complete on desktop; PLP thumbnail quality, tap-target size, and filter accessibility on mobile are non-negotiable.

## Conversion patterns
- **Search as primary navigation** — a persistent, visible search bar (not hidden behind an icon) converts exploratory traffic 3–5× better than category navigation alone.
- **PLP → PDP momentum:** quick-view on hover/tap (desktop); swipeable image carousel on mobile; visible price, key variant, and "add to cart" without opening the PDP for known repeat SKUs.
- **PDP layout:** images left/above (60% of viewport); price, size/variant selector, add-to-cart, and delivery/returns line all visible without scrolling on desktop. On mobile: image full-width → price → variant → ATC button as sticky bar.
- **Sticky ATC button on mobile PDP** — the single highest-impact PDP change for mobile conversion.
- **Checkout:** progress indicator, guest checkout first, address autocomplete, inline payment (Stripe/Apple Pay/Google Pay), order summary visible throughout; never hide the cart total.
- **Urgency without manipulation:** real low-stock signals ("3 left") and real delivery estimates ("order by 3pm for next-day") convert; fake countdown timers destroy trust on repeat visits.

## Trust signals
- **Reviews with photos** — user-generated review images on the PDP outperform editorial photography for conversion; Trustpilot, Yotpo, or Okendo integration; minimum displayed rating threshold 4.2.
- **Secure checkout badge and payment logos** — visible on the PDP and at checkout; not just in the footer.
- **Returns policy in plain language** — "Free 30-day returns, no questions asked" as a single line on the PDP above the fold; link to full policy from there; do not hide it in the footer.
- **Real delivery estimates** — a specific date ("Arrives by Thursday") beats a range ("3–5 business days"); show it on the PDP, not just at checkout.
- **Authentic product imagery** — lifestyle photography showing scale and context, multiple angles, zoom capability. Flat white-background only as a secondary shot.

## IA conventions
- **Nav:** Home / Categories (or Shop) / (Sale or New In) / (Brand or About) / Contact
- **Home:** Hero (brand or promotional) → bestsellers or curated collection → category entry points → social proof strip (reviews/UGC) → editorial/brand story (optional) → footer with policy links.
- **PLP (Product Listing Page):** sort/filter controls persistent (sidebar desktop, bottom-sheet mobile); product cards with hover second image, price, star rating, quick-add; pagination vs infinite scroll — pagination for SEO-driven catalogues, infinite scroll for discovery-driven ones (choose one, not both).
- **PDP (Product Detail Page):** image gallery → name, price, reviews count, variant selectors → ATC → delivery/returns line → description accordion → reviews section → cross-sell/upsell block.
- **Cart:** mini-cart sidebar preferred over separate cart page for mid-funnel saves; upsell at cart stage max 1 suggestion; guest checkout entry option.
- **Checkout:** address → shipping options → payment — 3 steps maximum; order confirmation page with social share and cross-sell.
- **Account:** order history, returns, saved addresses, wishlist — accessible but not required for purchase.

## Design-system seed (opinionated)
- Palette: #111111 (near-black, primary text), #FFFFFF (background — let the product photography be the color), #E5E7EB (borders, dividers), #F9FAFB (card/surface), #DC2626 (sale/urgency — red, used sparingly for price reduction only). Do not impose a strong brand color on the site chrome; product photography dominates, chrome is neutral.
- Type: body — Inter or DM Sans (clean, versatile); product names — same family at 600 weight; price — same family at 700, numerals prominent; headings — keep restrained; the product image is the hero, not the headline. Min 14px for product metadata; 16px for body copy.
- Spacing/radius/motion: compact 4-point grid for product cards (density matters — more products visible on screen = more discovery); radius 4px on cards (structured, not playful), 0px on product images (full bleed); ATC button 48px height minimum on mobile (tap target); hover transitions 80ms (fast, responsive feel).
- Borders vs shadows: 1px border on product cards (#E5E7EB) rather than shadows — shadows on a grid of 20 product cards creates visual noise; reserve `box-shadow` for the sticky ATC button on mobile to separate it from page content.

## Reference sites
- **Gymshark.com** — mobile-first PLP, clean product cards, reviews integrated on PDP, fast checkout; benchmark for fashion/apparel.
- **Allbirds.com** — sustainability messaging without obscuring product discovery; excellent PDP layout with materials storytelling; returns policy prominent throughout.
- **Ugmonk.com** — small-catalogue e-commerce done right; editorial voice, strong product photography, minimal chrome; shows that a 40-product shop can outperform a 4000-product shop on conversion if design is intentional.
- **COOK (cookfood.net)** — food e-commerce with genuine trust signals; delivery window clarity, strong lifestyle photography, reviews with context; demonstrates that products with complexity (frozen food) can still convert on clean UX.

## Anti-references & strict NOs
- **Sites with pop-ups on first page load** — a newsletter sign-up or discount pop-up firing on arrival before the visitor has seen a single product is the most reliable way to increase bounce rate.
- **PDPs where the "add to cart" button is below the fold on a 1080p desktop** — this single layout failure explains significant revenue loss on otherwise well-run stores.
- **Sites that show shipping cost only on the final checkout step** — the #1 cited reason for cart abandonment; shipping must be visible from the PDP.
- **Amazon-style information density on a small-catalogue brand store** — every element fighting for attention destroys perceived brand value.

Strict NOs:
- NO pop-ups on first visit — exit-intent is the maximum acceptable trigger; arrival pop-ups always lose.
- NO hidden shipping costs — cost (or "free") must appear on the PDP; appearing only at checkout step 3 is a broken pattern.
- NO checkout requiring account creation — guest checkout must be the default path.
- NO fake countdown timers or fabricated "only 2 left" stock signals — trust, once broken by dark patterns, does not recover.
- NO cluttered PDP — a PDP with 12 cross-sell widgets, 4 banners, and a live chat bubble over the ATC button is a conversion killer.
- NO intrusive newsletter pop-ups that block the return button or require a deliberate "No thanks, I hate saving money" dismiss — it is hostile UX.
- NO carousels on the homepage hero for promotional banners — static editorial with one clear CTA outperforms rotating banners every time.

## Emphasize in the brief
1. **PDP conversion checklist:** confirm that price, all variant selectors, the ATC button, delivery estimate, and the returns policy are all visible above the fold (no scroll) on a 390px mobile viewport — this single check identifies the majority of mobile revenue leaks.
2. **Checkout friction audit:** complete a test purchase as a guest, counting every click and form field; every step above 3 between cart and confirmation is a fix; note where shipping cost first appears.
3. **Trust-signal consistency:** confirm that the returns policy and security/payment logos appear on the homepage, the PDP, and the cart — not only in the footer; visitors who never reach the footer are the ones who need them most.
