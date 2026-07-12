---
name: beacon:fleet
description: Recon multiple sites sequentially through beacon, tracked in a durable fleet ledger with a completeness gate.
---

Run a beacon fleet over the provided URLs (or a file of URLs, one per line): $ARGUMENTS

Invoke the `site-fleet` skill and follow it exactly — branch on argument presence (URLs → new
fleet; none → resume), recon each source whole, and run the completeness sweep at the end.
