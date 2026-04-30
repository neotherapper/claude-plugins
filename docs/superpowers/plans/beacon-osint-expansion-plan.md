# Implementation Plan: Add OSINT Patterns to Beacon Registry

## Overview

Add 11 new OSINT source patterns to the beacon Phase 9 workflow. These complement existing sources (Wayback CDX, crt.sh, SecurityTrails, Shodan) with free, low-friction alternatives that don't require API keys.

## Architecture Decisions

1. **Where to add:** Both `plugins/beacon/references/osint-sources.md` (Phase 9 reference) and `plugins/beacon/skills/site-recon/references/osint-sources.md` (skill reference) — these must stay in sync.

2. **Pattern for new sources:** Follow existing format: bash code block + "What to extract/worth noting" section + when to use.

3. **Categorization:**
   - **Subdomain Discovery** (DNS-based): DNSDumpster, VirusTotal, BuiltWith, Censys, ASN
   - **Live Capture** (endpoint discovery): urlscan.io
   - **Infrastructure**: ASN/LIR, S3 bucket enumeration
   - **External References**: Paste sites, NPM/PyPI, HackerOne scope

4. **Priority order:** High → Medium → Lower reflects implementation sequence.

## Task List

### Phase 1: Subdomain Discovery Sources (Top ROI)

#### Task 1: Add DNSDumpster

- [ ] Add "DNSDumpster" section to osint-sources.md
- [ ] Add bash query that calls dnsdumpster.com API
- [ ] Document what subdomain patterns to flag (api, admin, staging, dev, internal)
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:**
- `plugins/beacon/references/osint-sources.md`
- `plugins/beacon/skills/site-recon/references/osint-sources.md`

**Estimated scope:** S (1-2 files)

---

#### Task 2: Add VirusTotal

- [ ] Add "VirusTotal" section with passive DNS query
- [ ] Document free tier limitations (3-5 queries/day)
- [ ] Include subdomain extraction from passive DNS records
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:**
- Same as Task 1

**Estimated scope:** S

---

#### Task 3: Add BuiltWith

- [ ] Add "BuiltWith" section for technology stack lookup
- [ ] Include both website tech detection and regex for patterns
- [ ] Document for validating/complementing Phase 3 fingerprinting
- [ ] Mirror to skills folder version

**Files touched:** Same as Task 1

**Estimated scope:** S

---

### Phase 2: Infrastructure & Live Capture

#### Task 4: Add urlscan.io

- [ ] Add "urlscan.io" section with domain search API
- [ ] Include commands for recent scans + historical retrieval
- [ ] Document what live capture reveals (API keys in JS, hidden params, AJAX endpoints)
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

#### Task 5: Add ASN Lookup

- [ ] Add "ASN/IP Range Lookup" section
- [ ] Include commands for whois.arin.net queries + bgp.he.net
- [ ] Document IP → org mapping for infrastructure correlation
- [ ] Include cloud range detection (AWS, Azure, GCP)
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

#### Task 6: Add Censys

- [ ] Add "Censys" section as Shodan alternative
- [ ] Include free tier query commands (certificates, hosts)
- [ ] Document TLS/cert analysis vs Shodan's port focus
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

### Phase 3: Specialized Sources

#### Task 7: Add S3 Bucket Enumeration

- [ ] Add "S3 Bucket Enumeration" section
- [ ] Include DNS pattern queries + bucket name permutations
- [ ] Document common misconfiguration patterns
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

#### Task 8: Add PassiveTotal/dnsdb

- [ ] Add "Farsight DNSDB (PassiveTotal)" section
- [ ] Include free API query patterns
- [ ] Document coverage differences from crt.sh
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

#### Task 9: Add Paste Sites Search

- [ ] Add "Paste Site Search" section
- [ ] Include Google dork patterns for Pastebin, GitHub Gists
- [ ] Document what to look for (leaked API keys, credentials)
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

#### Task 10: Add NPM/PyPI SDK Search

- [ ] Add "Package Registry Search" section
- [ ] Include npmjs.com and pypi.org search patterns
- [ ] Document for finding official SDK references
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

#### Task 11: Add HackerOne/Bug Bounty Scope

- [ ] Add "Bug Bounty Scope Search" section
- [ ] Include dork patterns for HackerOne, Bugcrowd
- [ ] Document scope data revealing attack surface + documented endpoints
- [ ] Mirror to skills folder version
- [ ] Verify: grep finds new section in both files

**Files touched:** Same as Task 1

**Estimated scope:** S

---

### Phase 4: Integration & Verification

#### Task 12: Update SKILL.md Phase 9 Summary

- [ ] read_file current Phase 9 summary in SKILL.md
- [ ] Update to include new source categories
- [ ] Ensure sync with osint-sources.md reference

**Files touched:**
- `plugins/beacon/skills/site-recon/SKILL.md`

**Estimated scope:** S

---

#### Task 13: Update Phase 9 Session Brief Format

- [ ] read_file current session brief format section
- [ ] Add new fields for each new source category
- [ ] Ensure mirroring in skills folder version

**Files touched:**
- `plugins/beacon/references/osint-sources.md` (both versions)

**Estimated scope:** S

---

#### Task 14: Verification & Testing

- [ ] Run grep across both folders to verify all sections present
- [ ] Check both osint-sources.md files are identical (diff)
- [ ] Test 1-2 bash snippets manually if possible
- [ ] Update CHANGELOG.md with new features

**Files touched:**
- `plugins/beacon/CHANGELOG.md`

**Estimated scope:** XS

---

## Checkpoints

### Checkpoint: After Tasks 1-3 (Phase 1 complete)
- [ ] DNSDumpster, VirusTotal, BuiltWith sections added to both osint-sources.md files
- [ ] New sources follow existing format conventions
- [ ] 3 new bash snippets tested

### Checkpoint: After Tasks 4-6 (Phase 2 complete)
- [ ] urlscan.io, ASN, Censys sections added
- [ ] Infrastructure correlation sources documented

### Checkpoint: After Tasks 7-11 (Phase 3 complete)
- [ ] All 11 new OSINT sources added
- [ ] Both reference files in sync

### Checkpoint: After Tasks 12-14 (Integration complete)
- [ ] SKILL.md updated
- [ ] Session brief format updated
- [ ] CHANGELOG.md updated
- [ ] All files verify via grep

---

## Dependencies

All tasks are independent — they add different sources to the same file. Tasks 1-11 can run in parallel once the format convention is established.

**Cross-file synchronization:** Tasks adding to both folders must sync both files (1:1 mirror).

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Format inconsistency** across new sections | Medium | Re-read existing sections before starting; match style exactly |
| **Both files not in sync** | High | Verify with `diff` after each task pair; Task 14 includes full diff check |
| **API endpoints change** (e.g., DNSDumpster) | Medium | Use web search to verify current endpoint before implementing bash snippets |
| **Rate limiting** on free tiers | Low | Include notes about rate limits in documentation |

---

## Open Questions

None. Format is established, sources are prioritized, both target files are identified.

---

## Implementation Notes

1. **Mirror rule:** Every edit to `plugins/beacon/references/osint-sources.md` must be mirrored to `plugins/beacon/skills/site-recon/references/osint-sources.md` — they must stay in sync.

2. **Bash snippet style:** Match existing format exactly — use `TARGET="example.com"` variable, include output parsing with python3 where needed, comment what to extract.

3. **"When to use" guidance:** Each new source needs a brief "when to use" note explaining why you'd choose this source over existing ones.

4. **Session brief fields:** New sources need corresponding output fields in the session brief format section so analysts know what to document.