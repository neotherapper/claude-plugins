# Layout Templates

Section templates and wireframe editor rules. Load this file during Step 3 of the draft skill.

## Standard section types

| Section | Purpose | Typical word range |
|---------|---------|-------------------|
| Hook | Bold claim + surprising stat or provocative question | 80–150w |
| Problem setup | Agitate the pain — make the reader feel it | 150–250w |
| Core insight | The non-obvious perspective or key thesis | 250–500w |
| Evidence | Stories, data, code examples, case studies | 200–400w |
| How-to / Steps | Numbered actionable steps (if applicable) | 100–200w per step |
| Counterpoint | Address the obvious objection | 100–200w |
| Backstory | Personal narrative or context | 100–200w |
| CTA | One clear ask — subscribe, follow, share, contact | 60–120w |

## Default wireframes by length

### Short (~500w)
```
① Hook           ~100w
② Core insight   ~250w
③ CTA            ~80w
```

### Medium (~1000w)
```
① Hook           ~120w
② Problem setup  ~200w
③ Core insight   ~350w
④ Evidence       ~250w
⑤ CTA            ~80w
```

### Long (~2000w)
```
① Hook           ~150w
② Problem setup  ~200w
③ Core insight   ~400w
④ Evidence       ~500w
⑤ How-to         ~400w
⑥ Counterpoint   ~200w
⑦ CTA            ~100w
```

## Parse-able wireframe edit commands

Accept these natural language commands during wireframe review:

| Command pattern | Example | Effect |
|----------------|---------|--------|
| "change {N} to {X}w" | "change 3 to 500w" | Update section N word count |
| "add {name} between {N} and {M}: {X}w" | "add backstory between 1 and 2: 150w" | Insert section |
| "remove {N}" | "remove 4" | Delete section N |
| "rename {N} to {name}" | "rename 3 to Framework" | Rename section |
| "swap {N} and {M}" | "swap 2 and 3" | Reorder sections |

After each edit command: recompute total word count, renumber sections, display updated wireframe.

## Word count validation

| Length target | Acceptable range |
|--------------|-----------------|
| short (~500w) | 300–700w |
| medium (~1000w) | 700–1500w |
| long (~2000w+) | 1500–3000w |

If total falls outside the range, warn: "This wireframe totals ~{X}w — {above/below} your {length} target. Continue anyway? (y/n)"
