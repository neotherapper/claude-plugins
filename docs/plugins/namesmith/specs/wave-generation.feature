Feature: Wave generation
  Names are generated in waves. Each wave produces a batch of candidates across
  7 archetypes using 10 techniques, weighted by brand interview answers.

  Background:
    Given the brand interview has been completed
    And the brand profile is locked

  Scenario: Wave 1 produces 25–35 candidates
    When Wave 1 generation runs
    Then the total candidate count is between 25 and 35 inclusive

  Scenario: Wave 1 covers all 7 archetypes
    When Wave 1 generation runs
    Then there is at least one candidate for each archetype:
      | Archetype              | Minimum |
      | Short & Punchy         | 3       |
      | Descriptive            | 3       |
      | Abstract/Brandable     | 3       |
      | Playful/Clever         | 3       |
      | Domain Hacks           | 2       |
      | Compound/Mashup        | 3       |
      | Thematic TLD Play      | 2       |

  Scenario: Wave 2 generates at least 20 new candidates
    Given Wave 1 has completed and results shown to the user
    When the user requests Wave 2
    Then Wave 2 generates at least 20 candidates
    And no candidate from Wave 2 repeats a name from Wave 1

  Scenario: Wave 2 respects archetype feedback
    Given Wave 1 has completed
    When the user says "I want more abstract names, fewer compound names"
    Then Wave 2 has more Abstract/Brandable candidates than Wave 1
    And Wave 2 has fewer Compound/Mashup candidates than Wave 1

  Scenario: Wave 3 requires explicit confirmation before scanning
    Given at least Wave 1 has completed
    And Wave 2 may or may not have run
    When the user says "deep scan" or "check more TLDs" or "Wave 3"
    Then the skill outputs a scope warning before loading anything:
      """
      Wave 3 will scan 1,441+ TLDs for your top 5 base words — this may take several minutes. Proceed?
      """
    And the scan does not start until the user confirms

  Scenario: Wave 3 deep scan runs after confirmation
    Given at least Wave 1 has completed
    And the user has confirmed the Wave 3 scope warning
    Then the skill loads generation-archetypes.md Wave 3 section
    And it attempts to scan multiple TLDs for the top base words identified in earlier waves

  Scenario: Wave output heading is parameterized
    When any wave completes
    Then the output heading reads "Wave [N] Results — [project description]"
    And [N] matches the actual wave number (1, 2, or 3)

  Scenario: Wave output includes TLD summary line
    When any wave completes
    Then the output contains a TLD summary line in the format:
      """
      TLD summary: .com [X available] | .io [X available] | .dev [X available] | hacks [X available]
      """
    And the line reflects actual availability counts from the current wave

  Scenario: Wave output includes offer to continue
    When any wave result is displayed
    Then the last line asks either "Anything catching your eye, or should I run Wave 2?"
    Or (for Wave 2+) "Anything catching your eye, or should I run Wave 3?"

  # --- Wave 2 context compaction safeguard ---

  Scenario: Wave 2 reloads brand-interview.md before generating candidates
    # brand-interview.md holds weighting rules; without it Wave 2 can't apply the correct archetype weights
    Given Wave 1 has completed and names.md has been written
    When the user requests Wave 2
    Then the skill loads brand-interview.md before generating any Wave 2 candidates
    And the skill loads generation-archetypes.md before generating any Wave 2 candidates
    And Wave 2 applies the same brand profile weights derived from the original interview

  # --- Archetype distribution boundaries ---

  Scenario: Wave 1 never produces zero candidates for any required archetype
    When Wave 1 generation runs
    Then no archetype in the following list has zero candidates:
      | Archetype          |
      | Short & Punchy     |
      | Descriptive        |
      | Abstract/Brandable |
      | Compound/Mashup    |
