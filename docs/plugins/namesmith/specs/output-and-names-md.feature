Feature: Output format and names.md
  After availability check, results are formatted with registration links and persisted
  to names.md in the user's current working directory.

  Background:
    Given availability check has completed for Wave N

  # --- Wave output format ---

  Scenario: Wave output follows the defined format
    When wave results are displayed
    Then the output matches:
      """
      ## Wave [N] Results — [project description]

      **Top Picks**
      ✅ [name].[tld]   $[price]/yr  — [one-sentence rationale]
         [[Registrar] →]([registration_url])
      ...

      ---
      TLD summary: .com [X available] | .io [X available] | .dev [X available] | hacks [X available]
      [X] of [Y] checked available. Anything catching your eye, or should I run Wave 2?
      """

  Scenario: Registration links use the correct registrar per TLD
    Given Cloudflare is configured (CF_API_TOKEN and CF_ACCOUNT_ID set)
    When wave results are displayed for a .com domain
    Then the registration link uses the Cloudflare registrar URL pattern
    And it includes the user's actual CF_ACCOUNT_ID in the URL

  Scenario: Registration links use Porkbun for .io when Cloudflare is not configured
    Given CF_API_TOKEN is not set
    When wave results are displayed for an available .io domain
    Then the registration link uses the Porkbun registrar URL pattern

  Scenario: Registration links use Namecheap for .ly
    When wave results include an available .ly domain
    Then the registration link uses the Namecheap URL pattern

  Scenario: Registration links use Porkbun for .gg regardless of CF configuration
    # .gg is CF-unsupported — Porkbun is the fallback in both the CF-configured and no-CF paths
    When wave results include an available .gg domain
    Then the registration link uses the Porkbun URL pattern

  Scenario: Registration links use Dynadot for .st
    # .st is a Dynadot-specific ccTLD not carried by Cloudflare or Porkbun
    When wave results include an available .st domain
    Then the registration link uses the Dynadot URL pattern

  # --- names.md schema ---

  Scenario: names.md is written to the project directory after wave output
    When wave output has been displayed
    Then names.md is written to the current working directory
    And it contains exactly three sections:
      | Section             |
      | Shortlisted         |
      | Considered / Taken  |
      | Brand Interview     |

  Scenario: Shortlisted section contains 3–5 available names
    When names.md is written
    Then the Shortlisted table has between 3 and 5 rows
    And all rows have status ✅ available

  Scenario: names.md rationale column matches conversation output verbatim
    When names.md is written
    Then the Rationale column text in the Shortlisted table
    matches the one-sentence rationale shown in the wave output exactly

  Scenario: Brand Interview section is fully populated
    When names.md is written
    Then the Brand Interview section contains all 6 fields:
      | Field       |
      | Building    |
      | Tone        |
      | Direction   |
      | Mode        |
      | Length      |
      | Constraints |
    And no field is blank or shows "N/A"

  Scenario: names.md header includes generation metadata
    When names.md is written
    Then the second line contains generation date, mode, tone, and direction:
      """
      _Generated: [YYYY-MM-DD] | Mode: [mode] | Tone: [tone] | Direction: [direction]_
      """

  Scenario: names.md is updated (not replaced) when post-shortlist checklist runs
    Given names.md exists from a previous wave
    When the user confirms a final shortlist and post-shortlist checklist runs
    Then names.md is updated to reflect handle and trademark findings
    And the existing Shortlisted section is preserved
