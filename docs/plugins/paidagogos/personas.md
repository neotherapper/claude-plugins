# Paidagogos — User Personas

## Persona 1: The Junior Developer Filling Gaps

**Name:** Alex · Junior frontend developer, 1 year experience
**Learning:** Concepts heard at work that feel too basic to ask a teammate about
**Use frequency:** Several times a week — whenever a new term surfaces in a PR or standup
**Typical prompt:** "teach me how async/await works" · "explain flexbox" · "what is memoisation"

**Goals:**
- Understand concepts well enough to use them confidently, not just copy-paste
- Stop nodding along in meetings when he doesn't know what's being discussed
- Build mental models fast — no time for 40-minute video tutorials

**Pain points:**
- Feels behind teammates and embarrassed to ask basic questions out loud
- Google results are either too shallow (W3Schools) or too deep (MDN internals)
- Tutorials assume he knows things he doesn't — prerequisite gaps never surfaced

**How Learn helps:**
- Expertise level detection routes him to beginner explanations without him having to ask
- Common mistakes section pre-empts the exact wrong mental models he's forming
- Generate task gives him something concrete to write — not just read and forget
- Micro-lesson format fits the five minutes between a PR review and the next meeting

**Example prompt:** `teach me how CSS specificity works`

---

## Persona 2: The Career Transitioner Finding a Path

**Name:** Maya · UX designer moving into web development, 5 years in her previous field
**Learning:** Web development systematically — HTML, CSS, JavaScript, then React
**Use frequency:** Daily, as part of a structured self-teaching routine
**Typical prompt:** "explain the difference between let and const" · "teach me what the DOM is"

**Goals:**
- Build a mental map of what she needs to learn and in what order
- Understand concepts, not just pass a syntax quiz
- Know what she doesn't know — avoid invisible gaps

**Pain points:**
- Doesn't know what she doesn't know — can't evaluate which resource to trust
- Learning platforms are overwhelming: 200-hour courses she can't commit to
- Paralysed when a topic is broad — "learn JavaScript" is too big, but she doesn't know where to cut

**How Learn helps:**
- Scope classifier surfaces the routing decision when a topic is broad: "Do you want a full roadmap or one focused concept?" — removes the paralysis without making the decision for her
- Single-concept lessons give her a clear unit of progress she can complete in one sitting
- Resources section points to curated, verified next steps — no more drowning in search results
- Common mistakes tell her what wrong turns to avoid before she takes them

**Example prompt:** `teach me what closures are in JavaScript`

---

## Persona 3: The Senior Developer Learning Adjacent Territory

**Name:** George · Principal frontend developer, 10+ years experience
**Learning:** Concepts outside his specialty — ML fundamentals, new languages, infra topics
**Use frequency:** A few times a month — when a project pushes into unfamiliar territory
**Typical prompt:** "teach me how backpropagation works" · "explain Rust ownership" · "what is a vector embedding"

**Goals:**
- Get up to speed on adjacent topics without sitting through beginner content
- Understand things at a level where he can make architectural decisions, not just follow tutorials
- Find the generate task challenging enough to actually test his understanding

**Pain points:**
- Most tutorials start with "what is a variable" — wastes 20 minutes before reaching useful content
- Advanced resources assume deep domain expertise he doesn't have in the adjacent field
- No way to tell from the outside whether an explanation is aimed at the right level

**How Learn helps:**
- Expertise level detection reads his inline signal ("I'm a senior dev but new to ML") and routes to advanced explanations with appropriate vocabulary
- Generate task is calibrated to his level — not "print hello world" but "implement X from scratch using only Y"
- Resources section surfaces documentation and reference material, not introductory tutorials

**Example prompt:** `teach me what attention is in transformers — I understand neural nets but I'm new to NLP`
