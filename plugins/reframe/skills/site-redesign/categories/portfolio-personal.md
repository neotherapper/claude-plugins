---
category: portfolio-personal
display_name: Portfolio / Personal
detect_signals: ["portfolio", "selected work", "selected works", "selected projects", "my work", "recent work", "featured work", "my projects", "case study", "case studies", "view project", "view case study", "about me", "résumé", "resume", "/cv", "freelance", "available for work", "available for freelance", "open to work", "hire me", "work with me", "let's work together", "let’s work together", "say hello", "side projects", "behance.net", "dribbble.com", "now page", "/uses", "personal site", "i'm a designer", "i’m a designer", "i'm a developer", "i’m a developer", "i design and build", "subscribe to my newsletter", "follow me on"]
---

# Portfolio / Personal — Redesign Pack

> Scope: an individual professional — designer, developer, or freelancer — showcasing selected work. Two co-primary goals: **win the next client/role** *and* **grow an audience**. The pack keeps both, but insists on a hierarchy so they don't compete. Per-discipline variations (creative vs developer) are noted inline.

## Redesign priorities
1. The work is the argument — selected projects (not everything) must be the first thing a visitor sees, each framed as evidence of judgment, not just output. A portfolio that opens with a paragraph about the person instead of the work has buried its only proof.
2. Two outcomes, one hierarchy — this site serves both "get hired" and "grow an audience". Make ONE the page's primary CTA (usually contact/availability) and the other a persistent-but-quieter secondary (subscribe/follow). Two equally weighted CTAs compete and convert neither.
3. Establish who-you-are and what-you-do in one line — a cold visitor (recruiter, prospective client, peer) must learn role + discipline + what you're open to within the first screenful: "Product designer. Currently freelance, available for work."
4. Make every project a case study, not a screenshot — problem, your role, what you did, the outcome. For designers this is visual + narrative; for developers it's the technical decisions plus a live link/repo. A grid of pretty thumbnails with no context proves nothing.
5. One frictionless contact path — a real, clickable email (or a 2-field form), not a contact form behind three clicks. Hiring and commissioning decisions are often made in seconds; a hidden or broken contact path kills warm intent.
6. Personality is a feature, not a risk — unlike a corporate site, a personal portfolio is allowed (and expected) to have a point of view, a voice, and a distinctive aesthetic. Generic = forgettable = unhired.

## Conversion patterns
- **Dual-CTA discipline:** primary = availability/contact ("Available for work — get in touch" / "Hire me"); secondary, persistent but lower-weight = audience ("Subscribe" / "Follow"). Put the primary in the hero and footer; place the secondary in the footer and at the *end* of case studies and essays, where intent is highest.
- **Selected, not exhaustive:** 3–6 best projects on the landing, with an optional "all work" archive linked below. Curation IS the skill — showing everything signals you can't tell what's good.
- **Case-study depth gate:** every project link must lead to a real case study (problem → role → process → outcome), not an external link to a live site with no context. Developers: pair the live demo with a short write-up and the repo.
- **Direct contact:** a clickable `mailto:` or a 2-field form (name + message). No "select inquiry type", no required company/budget fields on a personal site — that is an agency pattern, not a portfolio one.
- **Audience capture at the moment of value:** the newsletter prompt belongs at the end of a case study or essay (the reader just got value), not as an entry pop-up (the reader has not yet earned a reason to subscribe).
- **Social proof of demand:** "currently booking [month]", "previously at [companies]", or client logos for freelancers — concrete availability and track record dissolve the "is this person any good, and are they free?" hesitation.

## Trust signals
- **Real face + real name + plain discipline** — anonymity is fatal for a personal brand. A headshot (or a distinctive self-portrait), your actual name, and "what I do" in plain words.
- **Named context:** "Previously: Stripe, Figma" / "Clients include…" / "Built X (2M users)". Specific affiliations and outcomes outperform adjectives like "passionate" or "creative".
- **Live, working proof:** designers — real shipped work, not only mockups; developers — links to live products and public repos with recent commits; writers — published bylines. The proof must be verifiable in one click.
- **Process visibility:** showing how you think (a case-study process section, a sketch, a decision rationale) builds more trust than polished final shots alone — it proves the outcome wasn't luck.
- **Third-party validation where real:** testimonials from named clients/colleagues (name + role + company), a GitHub contribution graph, conference talks, a genuine subscriber/follower count if impressive — never vanity metrics.
- **Recency:** a visible "currently" / "now" signal (what you're working on, availability this quarter). A portfolio whose newest project is from three years ago reads as inactive regardless of quality.

## IA conventions
- **Nav:** Work (or Projects) / About / Writing (or Notes/Blog, only if they publish) / Contact. Keep it to 3–5 items. A "Now" or "Uses" page is an optional personality bonus, not core structure.
- **Home:** Hero (name + discipline + availability + primary CTA) → selected work (3–6 case-study cards) → short about/credibility strip (previously-at, what you do) → writing teaser (if audience-building) → footer with contact + subscribe.
- **Work:** index of selected projects → individual case-study pages (problem, role, process, outcome, links). Designers: visual-led layout; developers: decision-led with live/repo links.
- **About:** the human story + credibility (experience, clients, skills) + a second contact prompt. This is where personality and voice do the most work.
- **Writing/Blog:** only if they actually publish — it is the engine of the audience-growth goal. End each post with the subscribe prompt. If they do not write, cut it: an empty blog signals abandonment.
- **Contact:** direct email + optional short form + the right professional links per discipline (LinkedIn + GitHub for developers; Dribbble/Behance/Instagram for designers).
- **Journey shape:** cold referral/search/social → Home or a single project → scan the work → About (credibility check) → Contact (hire) OR Subscribe (audience). Design both exits; don't force one.

## Design-system seed (opinionated)
A personal portfolio is the one category where a distinctive — even idiosyncratic — system is correct, because the design itself is a work sample. The seed below is a confident neutral default to depart from, not a safe template to settle on.
- Palette: #111111 (near-black text/primary — high contrast lets the work carry the colour), #FFFFFF or #FAFAF8 (clean or warm off-white background), one owned personal accent used sparingly for links/CTA (#FF5A1F warm, #2563EB cool, or a signature colour), #6B7280 (secondary text). Keep the chrome neutral so project imagery provides the colour. Pick ONE accent and commit.
- Type: this is where personality lives. Body — a readable workhorse (Inter, a Söhne-like grotesk, or a clean serif such as Newsreader for writing-forward portfolios); display/headings — permission to use a characterful face at large size for the name/hero. Developers may add a mono accent (JetBrains Mono) for labels. Min 17px body — writing must be comfortable to read. One personality font + one workhorse, not five.
- Spacing/radius/motion: generous whitespace — portfolios breathe; let work sit in space. Large type-scale jumps (clear hero → body contrast). Radius 0–8px by aesthetic (sharp = editorial/confident; rounded = approachable). Motion: tasteful, purposeful scroll reveals (~300ms ease-out) are on-brand here as a craft signal — but never scroll-jacking, and never motion that delays reading.
- Borders vs shadows: prefer hairline borders, generous margins, and type/space hierarchy over drop shadows. Let work imagery sit cleanly (optional 1px frame or none); avoid heavy card shadows that read as template-y.

## Reference sites
- **Brittany Chiang (brittanychiang.com)** — developer-portfolio benchmark: clear role + availability, projects with real stacks and links, a restrained personal palette; fast and accessible.
- **Tobias van Schneider (vanschneider.com)** — designer + audience hybrid: strong personal brand where work, writing, and newsletter coexist with a clear hierarchy; a model for the "both, balanced" goal.
- **Rauno Freiberg (rauno.me)** — craft-forward developer/designer: minimal, opinionated typography, work/now/craft sections; personality without noise.
- **Maggie Appleton (maggieappleton.com)** — writer/designer audience play: essays as the magnet, a distinctive illustrated voice, subscribe woven in at the point of value — the audience-growth pattern done well.

## Anti-references & strict NOs
- **The exhaustive grid** — 30 thumbnails, no curation, no case studies; proves volume rather than judgment and overwhelms the visitor.
- **The faceless portfolio** — no name, no photo, no "what I do"; a personal brand that hides the person has no brand.
- **The default-template tell** — an unmodified Framer/Webflow/Wix template with the maker's demo copy and stock images still half-present; signals you didn't care enough about your own site.
- **The dead portfolio** — newest project dated three years ago, "available for work" with a bounced email; looks abandoned and kills trust instantly.

Strict NOs:
- NO contact path that is a form behind three clicks or a no-reply address — a clickable email or a 2-field form, reachable from every page.
- NO entry pop-up demanding a newsletter signup before the visitor has seen any work — earn the subscribe with value first.
- NO project that links straight to a live site or repo with zero context — every project needs a case study (problem/role/outcome).
- NO generic AI/template aesthetic (gradient-blob hero, floating 3-D orbs, neon-on-dark glow) — the portfolio IS a design sample; generic is self-defeating.
- NO autoplay audio/video hero or scroll-jacking that delays reaching the work.
- NO "passionate creative who loves clean design" filler bio — replace with concrete discipline, experience, and what you're open to.
- NO lorem ipsum, placeholder project names, or "Project Title" left in a shipped portfolio.
- NO unlabeled social icons that lead to dead or empty accounts — only link profiles that are active and on-brand.
- NO missing alt text or unreadable contrast — accessibility is itself a craft signal a hiring manager will notice.

## Emphasize in the brief
1. **Curation audit:** list every project currently shown and force-rank them — does the landing lead with the 3–6 strongest as full case studies, or dump everything as thumbnails? Cutting the weak work is usually the highest-leverage change.
2. **Dual-goal hierarchy:** confirm there is ONE primary CTA (contact/availability) and ONE quiet secondary (subscribe/follow) — flag any page where they compete as equals, because that is where both conversions leak.
3. **Recency + reachability check:** verify the contact path actually works and that a current "available/now" signal is present — an abandoned-looking, hard-to-contact portfolio fails both goals regardless of the work's quality.
