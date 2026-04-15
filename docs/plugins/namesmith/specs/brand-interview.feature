Feature: Brand interview
  The brand interview collects 6 structured answers before any name generation begins.
  Answers lock the generation matrix: archetype weights, TLD set, character count cap.

  Background:
    Given the user has described a project requiring domain naming
    And no personal brand signals were detected in the description

  Scenario: Interview asks exactly one question per message
    When the skill enters Step 3
    Then it asks Q1 ("What are you building?")
    And it waits for a user reply
    And it does not proceed to Q2 in the same message

  Scenario: Full interview completes in 6 messages
    Given the user answers Q1 through Q5 in turn
    When the user answers Q6
    Then the skill outputs a brand profile summary
    And the summary contains exactly 6 labelled fields:
      | Field       | Source |
      | Building    | Q1     |
      | Tone        | Q2     |
      | Direction   | Q3     |
      | Mode        | Q4     |
      | Length      | Q5     |
      | Constraints | Q6     |
    And the skill proceeds to Step 4 (Wave 1 generation) without prompting the user

  Scenario: Q6 accepts "none" as a valid constraint answer
    When the user answers Q6 with "none" or "no constraints"
    Then the brand profile summary shows Constraints: none
    And name generation proceeds without filtering any archetype

  Scenario: Q5 length preference caps Short & Punchy archetype
    Given the user answers Q5 with A (6 chars or fewer)
    When Wave 1 names are generated
    Then all Short & Punchy candidates have at most 6 characters (excluding TLD)

  Scenario: Q2 + Q3 weighting biases archetype counts
    Given the user answers Q2 with B (authoritative) and Q3 with A (functional)
    When Wave 1 names are generated
    Then the Descriptive archetype has more candidates than any other single archetype
    And the Compound/Mashup archetype has more candidates than Abstract/Brandable

  Scenario: Q4 budget mode A biases toward budget TLDs
    Given the user answers Q4 with A (budget)
    When Wave 1 names are generated
    Then the TLD set checked includes at least 3 entries from the budget TLD list
    And .com is not the exclusive or primary TLD tested

  Scenario: Q4 budget mode C biases toward .com
    Given the user answers Q4 with C (premium .com)
    When Wave 1 names are generated
    Then .com is the first TLD checked for every candidate
    And budget TLDs are not the primary recommendation

  Scenario: Generation does not start before Q6 is answered
    Given the user has answered Q1 through Q5
    When the user has not yet answered Q6
    Then no name candidates are generated or displayed
    And the skill only asks Q6
