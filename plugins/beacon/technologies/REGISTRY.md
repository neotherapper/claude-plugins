# Beacon Tech Pack Registry

## Purpose
This registry tracks all available tech packs for **Beacon/site-recon**, including frameworks, e-commerce platforms, and CMS systems. Use this file to:
- Identify existing tech packs.
- Track gaps in coverage.
- Document framework-specific probes and OSINT patterns.

---

## Registry

| Framework       | Versions Covered | E-Commerce/CMS | Probes Documented | OSINT Probes Added |
|----------------|------------------|----------------|-------------------|--------------------|
| **WordPress**   | 6.x              | CMS            | ✅                | ❌                 |
| **Shopify**     | 2024-10          | E-Commerce     | ✅                | ❌                 |
| **Magento**     | 2.x              | E-Commerce     | ✅                | ❌                 |
| **WooCommerce** | N/A (WP Plugin)  | E-Commerce     | ✅                | ❌                 |
| **BigCommerce** | N/A              | E-Commerce     | ✅                | ❌                 |
| **PrestaShop**  | 8.x              | E-Commerce     | ✅                | ❌                 |
| **OpenCart**    | 3.x              | E-Commerce     | ✅                | ❌                 |
| **Sylius**      | 2.x              | E-Commerce     | ✅                | ❌                 |
| **Drupal**      | N/A              | CMS            | ✅                | ❌                 |
| **Joomla**      | N/A              | CMS            | ❌                | ❌                 |
| **Webflow**     | 1.x              | CMS            | ✅                | ❌                 |
| **Wix**         | Current          | CMS            | ✅                | ❌                 |
| **Squarespace** | Current          | CMS            | ✅                | ❌                 |
| **React**       | N/A              | Framework      | ✅                | ❌                 |
| **Next.js**     | 15.x             | Framework      | ✅                | ❌                 |
| **Nuxt**        | 3.x              | Framework      | ✅                | ❌                 |
| **Express**     | N/A              | Framework      | ✅                | ❌                 |
| **Django**      | 5.x              | Framework      | ✅                | ❌                 |
| **FastAPI**     | 0.x              | Framework      | ✅                | ❌                 |
| **Laravel**     | 12.x             | Framework      | ✅                | ❌                 |
| **Symfony**     | N/A              | Framework      | ✅                | ❌                 |
| **ASP.NET Core**| N/A              | Framework      | ✅                | ❌                 |
| **Spring Boot** | N/A              | Framework      | ✅                | ❌                 |
| **AEM**         | N/A              | CMS            | ✅                | ❌                 |
| **Sitecore**    | N/A              | CMS            | ✅                | ❌                 |
| **Strapi**      | 5.x              | CMS            | ✅                | ❌                 |
| **Sanity**      | N/A              | CMS            | ✅                | ❌                 |

---

## Gaps and Action Items

### 1. **Missing Tech Packs**
- **Joomla**: No tech pack found.
- **BigCartel**: Fingerprinting exists, but tech pack is minimal.
- **Ecwid**: Tech pack exists, but no version-specific probes.

### 2. **Incomplete Probe Coverage**
- **E-Commerce Frameworks**: Probe checklists lack granularity (e.g., Shopify’s `/cart/add.js` vs BigCommerce’s `/api/storefront/cart`).
- **CMS Frameworks**: Missing probes for admin endpoints (e.g., Drupal’s `/admin/reports`).

### 3. **Missing OSINT Probes**
- **No tech pack includes OSINT probes** (e.g., VirusTotal, `nmap`, carbon footprint).
- **No malware/phishing checks** (VirusTotal, URLScan).
- **No port scanning** (`nmap`).
- **No security header grading** (Mozilla Observatory).

### 4. **Registry Maintenance**
- Update `REGISTRY.md` when new tech packs are added.
- Document framework-specific probes in tech packs.
- Append OSINT probes to relevant tech packs.

---

## Next Steps
1. **Create missing tech packs** (e.g., Joomla, BigCartel).
2. **Expand probe checklists** for e-commerce/CMS frameworks.
3. **Append OSINT probes** to tech packs (e.g., `nmap` for infrastructure-heavy sites).
4. **Integrate OSINT patterns** into **Beacon/site-recon** (e.g., Phase 5, 9).