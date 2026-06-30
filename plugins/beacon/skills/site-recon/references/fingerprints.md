# site-recon — Fingerprint Signal Tables

Load this file before Phase 3 fingerprinting. It contains the full signal tables for HTTP header/path patterns and JS globals/cookies.

**Confidence vocabulary:** Definitive (single signal is sufficient), High (strong indicator, confirm with one more signal), Medium (supporting signal only).

---

## HTTP header / path signals

- `Ghost-Version` → Ghost
- `x-nuxt` → Nuxt
- `X-Inertia` → Laravel/Inertia
- `x-shopify-stage: production` → Shopify (Definitive)
- `X-Powered-By: Strapi` or `X-Strapi-Version` → Strapi (Definitive)
- `server: uvicorn` → FastAPI (combined signal)
- `X-Runtime` → Rails (combined signal — confirm with `csrf-token` meta or `_*_session` cookie before concluding Rails; `X-Runtime` alone is not sufficient)
- `X-Powered-By: Express` → Express (Definitive)
- "Cannot GET /" → Express (High)
- `create-react-app` → React (Definitive)
- `/static/js/main.*.js` → React (High)
- `__REACT_DEVTOOLS_GLOBAL_HOOK__` → React (Definitive)
- `content="Sylius"` → Sylius (Definitive)
- `/admin/` + `sylius` in cookies → Sylius (High)
- `X-Magento-Cache-Debug` → Magento (Definitive)
- `/pub/static/` → Magento (High)
- `content="Magento"` → Magento (Definitive)
- `/woocommerce/` → WooCommerce (High)
- `X-WooCommerce-Version` → WooCommerce (Definitive)
- `window.woocommerce_params` → WooCommerce (Definitive)
- `X-Generator: TYPO3` header → TYPO3 (Definitive)
- `content="TYPO3 CMS"` → TYPO3 (Definitive)
- `/typo3/` → TYPO3 (High)
- `content="PrestaShop"` → PrestaShop (Definitive)
- `/admin[random]/` → PrestaShop (High)
- `/modules/` → PrestaShop/OpenCart (Medium)
- `/catalog/view/theme/default/stylesheet/stylesheet.css` → OpenCart (Definitive)
- `sw-context-token` cookie → Shopware (Definitive)
- `sw-version` header → Shopware (Definitive)
- `X-Bc-Api-Version` header → BigCommerce (Definitive)
- `/api/storefront/cart` → BigCommerce (High)
- `/bc-static/` → BigCommerce (Medium)
- `content="Wix.com Website Builder"` → Wix (Definitive)
- `X-Wix-Request-Id` header → Wix (High)
- `/_api/wix-site/v1/site` → Wix (High)
- `content="Squarespace"` → Squarespace (Definitive)
- `X-Squarespace-Version` header → Squarespace (Definitive)
- `/api/commerce/v1/products` → Squarespace (High)
- `X-Ecwid-Storefront-Id` header → Ecwid (Definitive)
- `app.ecwid.com/script.js` → Ecwid (Definitive)
- `content="Big Cartel"` → Big Cartel (Definitive)
- `X-BigCartel-Version` header → Big Cartel (Definitive)
- `/bigcartel.js` → Big Cartel (High)
- `X-Square-Store-Id` header → Square Online (Definitive)
- `content="Square Online"` → Square Online (Definitive)
- `/api/store/v1/products` → Square Online (High)
- `content="Joomla!"` → Joomla (Definitive)
- `X-Generator: Joomla` header → Joomla (Definitive)
- `/administrator/` → Joomla (High)
- `content="Webflow"` → Webflow (Definitive)
- `X-Webflow-Site` header → Webflow (Definitive)
- `/js/webflow.js` → Webflow (Definitive)
- `content="Drupal"` → Drupal (Definitive)
- `X-Generator: Drupal` header → Drupal (Definitive)
- `/core/` → Drupal (High)
- `_astro/` in asset URLs → Astro (Definitive)
- `astro-island` custom element → Astro (Definitive)
- `cdn.shopify.com` asset URLs → Shopify (High)

---

## JS globals & cookies

   - `__NEXT_DATA__` → Next.js
   - `window.__nuxt` → Nuxt
   - `_shopify_y` or `_shopify_s` cookies → Shopify
   - `_[a-z0-9_]+_session` cookie pattern → Rails
   - `X-Magento-Tags` or `X-Magento-Cache-Id` response headers → Magento 2 (Definitive)
   - `mage-cache-sessid` cookie → Magento 2 (High)
   - `data-mage-init` attribute in HTML → Magento 2 (High)
   - `window.woocommerce_params` or `wc-cart-hash` cookie → WooCommerce (Definitive)
   - `window.wc` JS global present → WooCommerce (High)
   - `__VIEWSTATE` hidden input field → ASP.NET WebForms (Definitive)
   - `.aspx` in URL paths → ASP.NET (High)
   - `ASP.NET_SessionId` cookie → ASP.NET (High)
   - `X-Powered-By: ASP.NET` header → ASP.NET (Definitive)
   - Atom/RSS feed `<generator>` tag → check for framework signal:
     `Zend_Feed_Writer` → Zend Framework 1, `Ghost` → Ghost, etc.
   - `csrfmiddlewaretoken` hidden input → Django (High)
