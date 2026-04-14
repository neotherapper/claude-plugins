# Post-Shortlist Checklist

Run this checklist after the user confirms their final shortlist. Work through each item in order and update `names.md` with the results.

## 1. Pronunciation Test

For each shortlisted name, verify it passes the phone test:

- Say the name out loud. Does it sound like what you intended?
- Spell it out: "That's V-E-R-C-E-L" — would a listener spell it correctly?
- Test the Starbucks rule: order a coffee under the name. Does the barista write it correctly?

**Flag:** Names that are frequently misspelled or mispronounced. Add a note to the Shortlisted table in names.md under a "Notes" column.

**Common failure patterns:**
- Silent letters: `Knave`, `Wrex` — people will try `Nave`, `Rex`
- Unusual letter combinations: `Qxyr`, `Tzov` — non-English speakers will struggle
- Double meanings when spoken: `Scunthorpe problem` — test for accidental offensive homophones

---

## 2. Social Handle Availability

For each shortlisted name, check handle availability on key platforms:

```
@{name} on: X/Twitter, Instagram, GitHub, LinkedIn, TikTok, YouTube
```

Check manually or use namecheckr.com (no auth required).

**Guidance:**
- Exact match (`@codeforge`) is ideal
- `@codeforgehq` or `@getcodeforge` are acceptable fallbacks
- If a handle is squatted but inactive for 2+ years, Twitter/Instagram have reclaim processes

**Update names.md** — add a "Handles" column to the Shortlisted table:

| Name | Price/yr | Status | Rationale | Handles |
|------|----------|--------|-----------|---------|
| codeforge.io | $35/yr | ✅ available | Clean compound, dev-tool feel | @codeforge ✅ (GH, X) / @codeforgehq (IG) |

---

## 3. Trademark Check

Before registering, do a basic trademark search:

**USPTO (US):** https://tmsearch.uspto.gov — search "Basic Word Mark Search (New User)"
**EUIPO (EU):** https://euipo.europa.eu/eSearch/ — for EU-based businesses
**WIPO Global:** https://branddb.wipo.int — for international coverage

**What to look for:**
- Exact name match in the same or adjacent goods/services class
- Similar-sounding names in the same class (likelihood of confusion)

**Classes most relevant to software/digital products:**
- Class 42: Software as a service, cloud computing, IT services
- Class 9: Software products, apps, downloadable software
- Class 35: Advertising, business services, e-commerce

**Guidance:** A name found in Class 42 in the US does not automatically mean you cannot use it — depends on geographic market, similarity, and whether the mark is live. Flag findings and recommend consulting a trademark attorney for any live marks in the same class.

---

## 4. Registration Strategy

After the name passes checks 1–3, recommend a registration strategy:

### Minimum viable registration
Register the primary domain (e.g., `codeforge.io`) immediately. Do not wait.

### Defensive registrations (optional but recommended)
For names with brand investment potential, also register:
- The `.com` equivalent if available (even to redirect to `.io`)
- The most common misspelling if available (e.g., `codeforj.io`)
- The plural/singular variant if different from primary

### Auto-renewal
Enable auto-renewal on all registered domains. Domains expire silently — a missed renewal can result in domain hijacking within hours.

### DNS configuration
Point the domain to a placeholder page immediately after registration. An unresolved domain looks abandoned and may be targeted by squatters or sedo-crawlers.

---

## 5. Update names.md

After completing the checklist, update the Shortlisted table in `names.md` with:
- Pronunciation verdict (✅ clear / ⚠️ explain risk)
- Social handle status
- Trademark flag (✅ clean / ⚠️ similar mark found in class X)
- Final recommendation: "Register now" / "Register with caveat: [reason]" / "Reconsider: [reason]"
