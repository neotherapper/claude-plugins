Feature: Post-shortlist checklist
  After the user confirms a final name choice, the skill runs a 5-section checklist
  covering pronunciation, social handles, trademark, registration strategy, and
  names.md update.

  Background:
    Given the user has said "I'll go with [name]" or confirmed a shortlist

  Scenario: post-shortlist.md loads after shortlist confirmation
    When the user confirms a final shortlist
    Then the skill loads post-shortlist.md from the references/ directory

  Scenario: Post-shortlist checklist covers all 5 sections
    When the post-shortlist checklist runs
    Then it contains exactly these sections in order:
      | Section                  |
      | Pronunciation test       |
      | Social handle check      |
      | Trademark screening      |
      | Registration strategy    |
      | names.md update          |

  Scenario: Pronunciation test includes the phone and Starbucks rule
    When the pronunciation section runs
    Then it instructs the user to test pronunciation with these rules:
      | Rule                                                             |
      | Say the name out loud as if on a phone call                     |
      | Starbucks rule: can a barista spell it after hearing it once?    |

  Scenario: Trademark section names all three search registries
    When the trademark section runs
    Then it references USPTO search
    And it references EUIPO search
    And it references WIPO search
    And it names at least Nice Classes 42, 9, and 35 as relevant

  Scenario: names.md is updated with handle and trademark findings
    When the post-shortlist checklist completes
    Then names.md is updated (not replaced)
    And any social handle availability is appended to the relevant row
    And any trademark findings are appended to the relevant row

  Scenario: Post-shortlist checklist does not load before shortlist is confirmed
    Given the user is still browsing wave results
    When no shortlist confirmation has been given
    Then post-shortlist.md is not loaded
    And no checklist instructions appear in the conversation
