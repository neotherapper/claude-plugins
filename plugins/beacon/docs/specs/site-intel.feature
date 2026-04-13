Feature: site-intel skill — route questions about a known site to pre-built research docs

  Background:
    Given Beacon v0.1.0 is installed in Claude Code
    And docs/research/example-com/ exists from a prior site-recon run

  Scenario: Question about endpoints routes to api-surfaces file
    When I ask "how do I fetch all products from example.com?"
    Then site-intel opens docs/research/example-com/INDEX.md first
    And routes to docs/research/example-com/api-surfaces/products.md
    And quotes the endpoint URL, auth requirements, and a working curl example

  Scenario: Question about tech stack routes to tech-stack file
    When I ask "what framework does example.com use?"
    Then site-intel opens docs/research/example-com/tech-stack.md
    And quotes the detected framework, version, and detection evidence

  Scenario: Question about available pages routes to site-map file
    When I ask "what pages does example.com have?"
    Then site-intel opens docs/research/example-com/site-map.md
    And lists the public routes table

  Scenario: Question about category IDs routes to constants file
    When I ask "what are the industry filter IDs on example.com?"
    Then site-intel opens docs/research/example-com/constants.md
    And quotes the relevant taxonomy values with their source

  Scenario: OpenAPI spec request routes to specs file
    When I ask "give me the OpenAPI spec for example.com"
    Then site-intel opens docs/research/example-com/specs/example-com.openapi.yaml
    And reports the spec source (auto-downloaded / scaffolded / har-generated)

  Scenario: Cross-surface question opens both relevant files
    When I ask "how does auth work and what endpoints require it on example.com?"
    Then site-intel opens INDEX.md first
    And opens both tech-stack.md (for auth mechanism) and the relevant api-surfaces file
    And quotes from both

  Scenario: No research docs found — user directed to run site-recon
    Given docs/research/unknown-site/ does not exist
    When I ask about unknown-site.com
    Then site-intel responds: "No research found for unknown-site.com. Run /beacon:analyze https://unknown-site.com to generate it."
