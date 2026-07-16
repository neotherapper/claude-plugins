# Trust Your Physio — Information Architecture

## Navigation hierarchy

No persistent nav bar visible in rendered Jina output. Inferred from page links and homepage sections:

```
Top level:
  / (Homepage / Program landing)
  /about
  /book [404]
  /guides (404 — referenced in homepage section heading "Digital Guides" but no live URL)

Footer: Not rendered in crawl — assumed to mirror homepage CTAs
```

Signal: `[NO-SITEMAP]` — sitemap.xml returned empty; no structured nav discovered. Site appears to operate as a single-page application with scroll-based navigation anchors on the homepage, plus a few discrete routes.

## Page purposes

| URL | Intent triplet (subject · audience · page job) |
|-----|------------------------------------------------|
| / | Active Life Program for knee/hip pain · Greek-speaking adults 45+ with chronic OA pain · Capture program enrolment application |
| /about | Solo physiotherapist with 8 years experience · Prospects who want to vet the practitioner · Build trust and qualify the clinician before committing |
| /book | Program booking / enrolment · Warm prospects who clicked the primary CTA · Convert intent to confirmed enrolment [currently 404 — broken] |

## Journeys

**Primary journey — Chronic pain sufferer seeking a non-medication solution:**
1. Lands on homepage (search: "online physiotherapy knee pain" or social referral)
   - Objection: "Is this legitimate / does it actually work?" → Testimonial videos and practitioner bio block
2. Reads program details — 16 sessions, 8 weeks, 4 phases
   - Objection: "Is this right for my condition?" → "Five reasons" section + program phase list
3. Clicks "Book Position Now" → 404 [BROKEN — conversion dead end]
   - Should resolve to: "How do I enrol / what does it cost?" → FAQ or booking form

**Secondary journey — Greek-speaking local patient seeking in-person Konstantinos:**
1. Finds /about via search or referral
   - Objection: "Is he qualified to treat my specific condition?" → 8-year experience claim, specialties named
2. Seeks contact/booking info → No contact details visible on /about; no phone number in crawl

**Secondary journey — Returning or referred patient:**
1. Directed to site by existing patient
   - Objection: "Is the program worth the price?" → Guarantee section ("1 extra month free")
2. Applies via homepage form → Konstantinos contacts them

## Primary conversion path

Cold visit (homepage) → Program detail scroll → "Apply for Active Life Program" form → Konstantinos follow-up call → Enrolment

Note: "Book Position Now" CTA is broken (404). The site has a secondary conversion path via the inline application form at the bottom of the homepage — this is currently the only working conversion route.
