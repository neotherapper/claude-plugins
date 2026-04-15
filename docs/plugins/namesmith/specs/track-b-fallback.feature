Feature: Track B fallback
  When all top picks from a wave are taken, Track B activates and runs 4 strategies
  in sequence until 5 or more available options are found.

  Background:
    Given Wave 1 has completed
    And all top picks (domain check) returned ❌ taken or ⚠️ redemption

  Scenario: Track B activates only when all top picks are taken
    Given at least one top pick is available
    When results are displayed
    Then Track B does not activate
    And the standard wave prompt is shown

  Scenario: Track B runs Strategy 1 first — close variations
    When Track B activates
    Then Strategy 1 runs: close variations
    And it generates names with prefixes get-, try- and suffixes -hq, -labs, -app on the same .com and .io TLDs
    And it checks availability for all variations

  Scenario: Track B stops at Strategy 1 if 5+ available found
    Given Strategy 1 generates 7 available close variations
    When Track B evaluates results
    Then Strategies 2, 3, and 4 do not run
    And the 7 available variations are shown as results

  Scenario: Track B advances to Strategy 2 when Strategy 1 finds fewer than 5
    Given Strategy 1 finds only 3 available close variations
    When Track B evaluates Strategy 1 results
    Then Strategy 2 runs: synonym exploration
    And it finds meaning-equivalent words for the taken base names
    And it checks availability for the synonym-based candidates

  Scenario: Track B advances to Strategy 3 when cumulative results still under 5
    Given Strategies 1 and 2 found a total of 4 available options
    When Track B evaluates cumulative results
    Then Strategy 3 runs: creative reconstruction
    And it generates 10 new names using only metaphor mining and abstract archetypes
    And it checks availability for the new candidates

  Scenario: Track B advances to Strategy 4 when cumulative results still under 5
    Given Strategies 1 through 3 found a total of 4 available options
    When Track B evaluates cumulative results
    Then Strategy 4 runs: domain hacks
    And it scans tld-catalog.md domain hack catalog for base word fragments
    And it checks availability for domain hack candidates

  Scenario: Track B reports all found results even if 5 is never reached
    Given all 4 strategies completed
    And only 3 available options were found in total
    When Track B finishes
    Then the 3 available options are displayed
    And a note informs the user that Track B exhausted all strategies
    And the user is offered options to broaden constraints or start fresh

  Scenario: Track B results do not duplicate Wave N candidates
    When Track B runs any strategy
    Then no candidate generated is identical to a candidate shown in any previous wave
