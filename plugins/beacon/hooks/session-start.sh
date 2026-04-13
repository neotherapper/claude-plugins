#!/bin/bash
# Beacon session start hook
# Injects a reminder about available skills into the session context

cat <<'EOF'
=== BEACON PLUGIN ACTIVE ===

Two skills are available:

  site-recon  — Analyse a new site (12-phase investigation)
                Trigger: "analyse https://...", "map API surface of...", /beacon:analyze

  site-intel  — Load existing research for a known site
                Trigger: "tell me about [site]", "load research for...", /beacon:load

Output always goes to: docs/research/{site-name}/
Tech packs available for: WordPress, Next.js, Nuxt, Django, Rails, Astro, Laravel, Shopify, Ghost

============================
EOF
