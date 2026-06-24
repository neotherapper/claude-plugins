# Eval 2 (ecommerce-probe-list) — Old Skill Baseline Run

## Target
`https://woocommerce.com/woocommerce-demo` → resolved to `https://woocommerce.com` (main site)

## Skill Version
Old site-recon skill (v0.5.0 from `site-recon-workspace/old-skill-snapshot/SKILL.md`)

## Session Brief

### Infrastructure
| Property | Value |
|----------|-------|
| Framework | WordPress 6.9.4 |
| WooCommerce | 9.x |
| Platform | WordPress VIP |
| Server | nginx |
| CDN | Cloudflare |

### Tool Availability
- curl: AVAILABLE
- python3: AVAILABLE

### Tech Pack
- [LOADED:wordpress:6.x] — from `plugins/beacon/technologies/wordpress/6.x.md`
- [LOADED:woocommerce:9.x] — from `plugins/beacon/technologies/woocommerce/9.x.md` ✓

### Discovered Endpoints
| Endpoint | Method | Auth | Phase | Notes |
|----------|--------|------|------|-------|-------|
| `/wp-json/` | GET | None | 5 | WP REST root |
| `/wp-json/wc/v3/` | GET | Consumer Key | 5 | WC REST root |
| `/wp-json/wc/v3/products` | GET | Consumer Key | 5 | 401 (auth required) |
| `/wp-json/wc/store/v1/products` | GET | None | 5 | 200 - 100 products |
| `/wp-json/wc/store/v1/categories` | GET | None | 5 | 200 - 95 categories |
| `/?wc-ajax=get_refreshed_fragments` | POST | Cookie | 5 | 200 |

### E-commerce Probe Results
Per WooCommerce 9.x tech pack probe checklist:
- ✓ `/wp-json/wc/v3/` namespace found
- ✓ `/wp-json/wc/store/v1/` namespace found  
- ✓ `/wp-json/wc/store/v1/products` accessible (no auth)
- ✓ `/wp-json/wc/store/v1/products/categories` accessible (95 categories)
- ✓ `/wp-json/wc/v3/products` requires auth (401)
- ✓ `wc-ajax=get_refreshed_fragments` active

## Eval Result
This run successfully loaded the WooCommerce 9.x tech pack and applied the e-commerce probe list. The STORE API (`/wc/store/v1/`) was probed as expected for public access, while the REST API (`/wc/v3/`) was probed and correctly identified as requiring Consumer Key auth.

## Output Location
`/Users/georgiospilitsoglou/Developer/projects/claude-plugins/plugins/beacon/skills/site-recon-workspace/iteration-1/eval-2-ecommerce-probe-list/old_skill/outputs/docs/research/woocommerce-com/`