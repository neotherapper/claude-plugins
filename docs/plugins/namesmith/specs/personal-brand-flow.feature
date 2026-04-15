Feature: Personal brand flow
  When the user's description contains personal brand signals, the skill routes to a
  dedicated flow that checks name patterns before (and optionally instead of) the
  standard 6-question interview.

  Background:
    Given the user describes a project

  Scenario Outline: Personal brand signals are detected correctly
    When the user's description contains "<signal>"
    Then the skill activates the personal brand flow
    And it does not start the standard interview immediately

    Examples:
      | signal           |
      | portfolio        |
      | personal website |
      | freelance        |
      | my name          |
      | John Smith       |
      | Sarah Connor     |

  Scenario: Non-personal descriptions do not trigger the flow
    When the user says "find me a domain for my SaaS product"
    Then the skill does not activate the personal brand flow
    And it proceeds directly to the standard 6-question interview

  Scenario: Personal brand flow checks name-pattern domains first
    Given personal brand signals are detected with name "John Smith"
    When the skill runs the personal brand flow
    Then it checks at minimum the following patterns:
      | Pattern          |
      | johnsmith.com    |
      | johnsmith.io     |
      | johnsmith.dev    |
      | john.studio      |
      | jsmith.com       |
    And it presents availability results before asking any interview question

  Scenario: User declines branded alternatives — availability check still runs
    Given the personal brand flow has presented name patterns
    When the user declines the offer for creative branded alternatives
    Then the skill proceeds to Step 5 (availability check) for the personal brand patterns
    And it does not skip to Step 6 (format output) without running availability checks

  Scenario: User accepts branded alternatives — standard interview starts at Q2
    Given the personal brand flow has presented name patterns
    And Q1 has been pre-filled with the detected founder name
    When the user accepts the offer for creative branded alternatives
    Then the skill starts the standard interview at Q2
    And it does not re-ask Q1

  Scenario: Personal brand signal with product name in same message
    Given the user says "I need a domain for my freelance studio — it's called Salt & Stone"
    Then the skill detects the personal brand signal ("freelance")
    And it also records "Salt & Stone" as a product/studio name candidate
    And it checks both personal name patterns and the studio name for availability
