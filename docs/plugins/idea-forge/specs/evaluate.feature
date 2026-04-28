Feature: idea-forge evaluate skill

  # Happy path

  Scenario: evaluates a seed from a seeds file and produces a scored card with verdict
    Given a seeds file "idea-seeds-fintech-2026-04-18-run-1.md" containing at least one idea seed
    When the user runs /idea-forge:evaluate referencing that seed
    And completes the 5 intake questions
    Then all 5 Stage 1 research agents run in parallel
    And the competitor deep-dive agent runs after Stage 1 completes
    And the scoring agent produces scores.json with 13 criteria scores
    And the critic agent produces critic-review.json
    And the orchestrator produces idea-card.md with a verdict
    And the verdict is one of BET, BUILD, PIVOT, or KILL

  # Inline idea input

  Scenario: evaluates an inline idea description without a seeds file
    Given no seeds file exists in "ideas/_registry/"
    When the user runs /idea-forge:evaluate and provides an idea description inline
    Then the skill proceeds through all pipeline stages using the inline description
    And produces idea-card.md with a verdict
    And does not error due to the absence of a seeds file

  # Lens selection

  Scenario: loads the saas lens when the business model is inferred as SaaS
    Given an idea description indicating a recurring subscription revenue model
    And the founder does not specify a business model explicitly
    When the scoring agent infers the business model
    Then it selects "saas.md" as the lens
    And scores.json records lens_used as "saas"

  Scenario: loads the directory lens when the founder explicitly states a directory model
    Given an idea description with an ambiguous revenue model
    And the founder states "this is a directory business" during the intake interview
    When the scoring agent selects the lens
    Then it selects "directory.md" as the lens regardless of inferred signals

  Scenario: defaults to tool-site lens and flags assumption when model is ambiguous
    Given an idea description with no clear revenue model signals
    And the founder does not specify a business model during intake
    When the scoring agent cannot determine the lens after all three inference passes
    Then it selects "tool-site.md" as the default lens
    And idea-card.md includes a note flagging the lens assumption

  # Critic pass

  Scenario: critic-adjusted scores are reflected in the final card
    Given scores.json contains a market score of 8.5 with weak evidence citations
    When the critic agent reviews scores.json
    And flags the market score as over-confident and proposes an adjusted score of 6.0
    Then critic-review.json records the adjustment and the flag reason
    And the orchestrator applies the adjusted score of 6.0 in the final weighted average
    And idea-card.md shows both the original score and the critic-adjusted score

  Scenario: critic pass with no adjustments still produces a valid critic-review.json
    Given scores.json contains well-evidenced scores across all 13 criteria
    When the critic agent reviews scores.json
    And finds no over-confident scores
    Then critic-review.json records zero adjustments
    And the orchestrator uses the original scores.json scores unchanged

  # Verdict mapping

  Scenario: weighted average >= 7.5 maps to BET verdict
    Given the critic-adjusted weighted average across 13 criteria is 7.8
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "BET"

  Scenario: weighted average between 6.0 and 7.4 inclusive maps to BUILD verdict
    Given the critic-adjusted weighted average across 13 criteria is 6.9
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "BUILD"

  Scenario: weighted average between 4.0 and 5.9 inclusive maps to PIVOT verdict
    Given the critic-adjusted weighted average across 13 criteria is 5.2
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "PIVOT"

  Scenario: weighted average below 4.0 maps to KILL verdict
    Given the critic-adjusted weighted average across 13 criteria is 3.1
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "KILL"

  Scenario: verdict boundary at exactly 7.5 maps to BET not BUILD
    Given the critic-adjusted weighted average across 13 criteria is 7.5
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "BET"

  Scenario: verdict boundary at exactly 6.0 maps to BUILD not PIVOT
    Given the critic-adjusted weighted average across 13 criteria is 6.0
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "BUILD"

  Scenario: verdict boundary at exactly 4.0 maps to PIVOT not KILL
    Given the critic-adjusted weighted average across 13 criteria is 4.0
    When the orchestrator computes the verdict
    Then idea-card.md verdict is "PIVOT"
