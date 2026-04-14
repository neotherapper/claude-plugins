# Registrar Routing

Route each discovered domain to the best registrar for purchase. Use the primary registrar for each TLD; fall back down the list if the primary does not support it.

## Primary Registrar by TLD

| TLD(s) | Primary Registrar | Registration URL Pattern |
|--------|------------------|--------------------------|
| .com, .net, .org, .info, .biz | Cloudflare Registrar | `https://dash.cloudflare.com/{account_id}/domains/registrations/purchase?domain={domain}` |
| .io, .co, .ai, .app, .dev, .me, .xyz, .online, .site, .fun, .space, .icu, .top | Porkbun | `https://porkbun.com/checkout/search?q={domain}` |
| .ly, .is, .it, .in, .at, .am, .as, .be, .by, .es, .ms | Namecheap | `https://www.namecheap.com/domains/registration/results/?domain={domain}` |
| .gg, .st, .pt, .to, .my | Dynadot | `https://www.dynadot.com/domain/search.html?domain={domain}` |
| .sh, .fm, .fm | Porkbun | `https://porkbun.com/checkout/search?q={domain}` |

## Cloudflare Registrar

Cloudflare sells domains at cost (no markup). Best choice for .com and common TLDs when the user already has a Cloudflare account.

**Registration URL:**
```
https://dash.cloudflare.com/{CF_ACCOUNT_ID}/domains/registrations/purchase?domain={domain}
```

**Supported TLDs (common):** .com, .net, .org, .info, .biz, .us, .eu, .ca, .uk, .de, .fr, .es, .nl, .io, .co, .me, .dev, .app, .xyz, .online, .site, .space, .store, .shop, .studio, .design, .ai (select regions)

**When to use:** User has `CF_API_TOKEN` + `CF_ACCOUNT_ID` set and TLD is in the supported list. Always prefer CF for .com.

## Porkbun

Porkbun offers competitive prices on a wide range of TLDs with clean UX. Good fallback for TLDs Cloudflare does not support.

**Registration URL:**
```
https://porkbun.com/checkout/search?q={domain}
```

**Strengths:** Wide TLD coverage including .io, .ai, .gg, .sh, .fm, .xyz, .icu and many ccTLDs. API available for programmatic checks.

**When to use:** TLD not supported by CF, or no CF account configured.

## Namecheap

Good for ccTLDs with lenient registration policies. Often has promotional pricing.

**Registration URL:**
```
https://www.namecheap.com/domains/registration/results/?domain={domain}
```

**When to use:** ccTLD not available on CF or Porkbun (.ly, .is, .am, .ms, etc.).

## Dynadot

Specialises in ccTLDs that other registrars do not carry.

**Registration URL:**
```
https://www.dynadot.com/domain/search.html?domain={domain}
```

**When to use:** .gg, .st, .pt, .to, .my and other less common ccTLDs.

## Sedo (Aftermarket)

For taken or redemption-status domains, Sedo is the primary aftermarket marketplace.

**Search URL:**
```
https://sedo.com/search/searchresult.php4?sitedesign=sedo&keyword={domain}
```

**When to use:** Domain status is `taken` or `redemption`. Warn user that aftermarket prices vary widely ($100–$50,000+). For redemption domains, note the 30-day redemption grace period and the elevated recovery cost ($80–$200).

---

## Routing Logic

When formatting Wave output (Step 6 of SKILL.md):

1. Determine the TLD of each available domain
2. Look up the primary registrar from the table above
3. Substitute `{domain}` and `{account_id}` (use `CF_ACCOUNT_ID` env var for Cloudflare links) into the URL pattern
4. Present the link inline under each ✅ domain name
5. For taken domains (❌): omit registration link
6. For redemption domains (⚠️): link to Sedo with a warning note

## URL Construction Examples

For `codeforge.io` → Porkbun:
```
https://porkbun.com/checkout/search?q=codeforge.io
```

For `codeforge.com` with CF_ACCOUNT_ID=3b3bb751b739ac06fad21c224fc02da3:
```
https://dash.cloudflare.com/3b3bb751b739ac06fad21c224fc02da3/domains/registrations/purchase?domain=codeforge.com
```

For `code.ly` → Namecheap:
```
https://www.namecheap.com/domains/registration/results/?domain=code.ly
```
