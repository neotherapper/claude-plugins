# wordpress.org — Tech Stack

**Analysed:** 2026-04-27
**Target:** https://wordpress.org/news/feed/
**Skill version:** OLD (v0.5.0 baseline — no late-tech-pack-trigger)

| Property | Value | Source |
|----------|-------|--------|
| Framework | WordPress | generator tag in feed XML (`v=7.1-alpha-62259`) |
| Framework version | 7.1-alpha | from generator tag |
| CDN | Unknown | no CDN headers on feed endpoint |
| Auth | None on public endpoints | REST API is public for reading |
| Bot protection | None detected | feed and REST API accessible |
| Hosting | Automattic / WordPress.com infrastructure | `x-nc: HIT` header, nginx server |

## Framework Detection Notes (OLD SKILL BEHAVIOR)

**Phase 3 Fingerprint (OLD skill, ran on feed URL):** No match. The feed URL returned XML, not HTML. Standard Phase 3 HTML pattern match found nothing (`wp-content/` not in feed XML, no `generator` tag rule in OLD Phase 3 detection list).

**Phase 4 Tech Pack (OLD skill):** NOT LOADED. Since Phase 3 returned `[FRAMEWORK-UNKNOWN]`, the OLD skill skips Phase 4. No tech pack was loaded.

**Framework discovered in Phase 6:** The generator tag `<generator>https://wordpress.org/?v=7.1-alpha-62259</generator>` in the RSS feed reveals WordPress 7.1-alpha. However, the OLD skill (v0.5.0) has no mechanism to re-trigger Phase 4 after discovering the framework from a later phase.

**Result:** Tech pack was NOT loaded. This is the baseline bug this eval tests.