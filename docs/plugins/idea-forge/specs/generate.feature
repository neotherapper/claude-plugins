Feature: idea-forge generate skill

  # Happy path

  Scenario: generates idea seeds from an existing vault domain
    Given a vault with a populated master-index.yaml containing domain "productivity-tools"
    When the user runs /idea-forge:generate for domain "productivity-tools"
    Then the skill applies all 5 gap patterns to the domain content
    And produces up to 14 scored candidates
    And fleshes out the top 3 to 5 candidates into idea seeds
    And writes the seeds file to "ideas/_registry/idea-seeds-productivity-tools-{date}-run-1.md"

  # Subsequent run on same domain same day

  Scenario: increments run number when a seeds file already exists for today
    Given a seeds file "idea-seeds-productivity-tools-{date}-run-1.md" already exists
    When the user runs /idea-forge:generate for domain "productivity-tools" again
    Then the new file is written as "idea-seeds-productivity-tools-{date}-run-2.md"
    And the existing run-1 file is not modified

  # No vault data

  Scenario: handles missing master-index.yaml gracefully
    Given no master-index.yaml exists in "ideas/_registry/"
    When the user runs /idea-forge:generate
    Then the skill does not crash
    And outputs a clear message explaining that no vault data was found
    And prompts the user to provide a domain description inline or populate the vault first

  # Evidence floor

  Scenario: drops candidates with zero evidence score regardless of other scores
    Given a domain with 14 scored candidates
    And 3 of those candidates have Evidence score = 0
    When the skill applies the light scoring floor rule
    Then the 3 zero-evidence candidates are excluded from the shortlist
    And the seeds file contains only candidates with Evidence >= 1

  Scenario: promotes a lower-ranked candidate when top candidates fail the evidence floor
    Given the top-ranked candidate by composite score has Evidence = 0
    When the skill applies the evidence floor
    Then the next eligible candidate by composite score takes its place in the top seeds

  # Output format

  Scenario: seeds file written to correct path with correct naming
    Given a successful generate run for domain "fintech" on date "2026-04-18" as the first run
    When the seeds file is written
    Then its path is "ideas/_registry/idea-seeds-fintech-2026-04-18-run-1.md"
    And the file contains the domain name, run number, date, and at least 3 idea seeds
    And each seed includes a title, gap pattern reference, light scores, and a one-paragraph rationale
