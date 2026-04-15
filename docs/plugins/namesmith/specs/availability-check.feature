Feature: Availability check
  Domain availability is checked via a 3-tier chain: Cloudflare Registrar API first,
  Porkbun API second, whois/DNS fallback third.

  Background:
    Given Wave 1 has generated candidates
    And the skill is at Step 5

  # --- Tier 1: Cloudflare ---

  Scenario: Cloudflare tier runs when CF env vars are set
    Given CF_API_TOKEN and CF_ACCOUNT_ID are set
    When availability check runs
    Then check-domains.sh is invoked with the candidate domains
    And the output shows ✅ available, ❌ taken, or ⚠️ redemption statuses with prices

  Scenario: Cloudflare batching limits to 20 domains per call
    Given CF_API_TOKEN and CF_ACCOUNT_ID are set
    And Wave 1 produced 30 candidates
    When check-domains.sh is invoked
    Then the script is called with at most 20 domains per invocation
    And it is called a second time with the remaining domains

  Scenario: Cloudflare success suppresses Porkbun availability check
    Given CF_API_TOKEN and CF_ACCOUNT_ID are set
    And Cloudflare API responds successfully
    When availability check completes
    Then Porkbun domain-check API is not invoked

  # --- Tier 2: Porkbun ---

  Scenario: Porkbun tier activates when CF vars are absent
    Given CF_API_TOKEN and CF_ACCOUNT_ID are not set
    And PORKBUN_API_KEY and PORKBUN_SECRET are set
    When availability check runs
    Then Porkbun check is invoked per domain

  Scenario: get-prices.sh always runs regardless of tier
    Given any combination of API env vars
    When availability check runs
    Then get-prices.sh is always invoked
    And it returns pricing data from Porkbun's no-auth pricing endpoint

  # --- Tier 3: whois fallback ---

  Scenario: whois fallback activates when no API keys are set
    Given CF_API_TOKEN, CF_ACCOUNT_ID, PORKBUN_API_KEY, and PORKBUN_SECRET are all unset
    When availability check is about to run
    Then the skill loads api-setup.md
    And it displays setup instructions before proceeding with the whois fallback

  Scenario: whois fallback shows unknown status when no match found
    Given the whois fallback is active
    And whois returns no match for a domain
    Then the output shows ❓ unknown status for that domain

  Scenario: whois fallback shows na price for all domains
    Given the whois fallback is active
    When results are displayed
    Then all domains show price: na
    And no price figures are shown

  # --- Env var safety ---

  Scenario: Env var check shows presence only, never values
    When the skill checks for API credentials
    Then it outputs "CF_API_TOKEN: set" or "CF_API_TOKEN: not set"
    And it never echoes the actual token value into the conversation

  # --- Redemption domains ---

  Scenario: Redemption period domains show a warning note
    When a domain is in redemption period
    Then the output shows ⚠️ redemption with a note about elevated recovery cost
    And the domain is not listed as simply ❌ taken

  # --- Batching boundary conditions ---

  Scenario: Exactly 20 candidates — single invocation, no split
    Given CF_API_TOKEN and CF_ACCOUNT_ID are set
    And Wave 1 produced exactly 20 candidates
    When check-domains.sh is invoked
    Then the script is called exactly once with all 20 domains
    And no second invocation occurs

  Scenario: Exactly 21 candidates — splits into 20 + 1
    Given CF_API_TOKEN and CF_ACCOUNT_ID are set
    And Wave 1 produced exactly 21 candidates
    When check-domains.sh is invoked
    Then the first call contains exactly 20 domains
    And the second call contains the remaining 1 domain

  # --- Fallback when both CF and Porkbun keys are absent ---

  Scenario: api-setup.md is loaded before whois runs
    Given CF_API_TOKEN, CF_ACCOUNT_ID, PORKBUN_API_KEY, and PORKBUN_SECRET are all unset
    When availability check is about to run
    Then api-setup.md is loaded first
    And setup instructions are displayed to the user
    And only after showing instructions does the whois fallback proceed
