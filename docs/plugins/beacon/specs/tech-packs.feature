Feature: Tech pack schema validation and community contribution

  Scenario: Valid tech pack loads without warnings
    Given technologies/wordpress/6.x.md contains all 10 required sections
    And the frontmatter passes tech-pack.schema.json validation
    When the skill loads the tech pack
    Then it loads without any [INVALID-TECH-PACK] warning

  Scenario: Tech pack missing required section is rejected
    Given technologies/wordpress/6.x.md is missing the "## Gotchas" section
    When the skill attempts to load the tech pack
    Then it logs [INVALID-TECH-PACK:technologies/wordpress/6.x.md:missing-section:Gotchas]
    And proceeds with generic heuristics instead

  Scenario: Deprecated tech pack version loads with warning
    Given technologies/nextjs/13.x.md has deprecated: true in frontmatter
    When a Next.js 13 site is detected
    Then the file loads with warning: [TECH-PACK-DEPRECATED:nextjs:13.x]
    And the warning appears in INDEX.md

  Scenario: Tech pack staleness warning after 180 days
    Given technologies/django/5.x.md has last_updated: "2025-01-01"
    And today's date is more than 180 days after 2025-01-01
    When the skill loads the tech pack
    Then it warns: [TECH-PACK-STALE:django:5.x:last-updated-2025-01-01]

  Scenario: Community PR draft follows contribution template
    When a PR is opened for a new tech pack
    Then the PR title matches "feat(tech-packs): add {framework} {version}"
    And the PR body includes: source references, tested sites (redacted), schema validation status
    And the branch name is tech-pack/{framework}-{version}
    And the file is placed at technologies/{framework}/{version}.md
