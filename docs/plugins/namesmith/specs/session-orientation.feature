Feature: Session orientation (Step 0)
  When the site-naming skill starts, it checks for an existing names.md in the
  current directory to determine whether to resume a previous session or begin
  a new one. This gate prevents re-interviewing users who have already completed
  the brand interview in a prior session.

  Background:
    Given the user has invoked the site-naming skill

  # --- No prior session ---

  Scenario: No names.md — skill proceeds directly to Step 1
    Given names.md does not exist in the current directory
    When the skill runs Step 0
    Then it proceeds directly to Step 1 (project file detection)
    And it does not display a session brief
    And it does not ask the user to choose a path

  # --- Prior session exists ---

  Scenario: names.md exists — skill displays session brief before acting
    Given names.md exists with a brand profile and at least one shortlisted name
    When the skill runs Step 0
    Then it outputs a session brief before any other action
    And the brief contains the previous session project description
    And the brief contains the brand profile (Tone, Direction, Mode, Length)
    And the brief contains the shortlisted name(s)
    And the brief presents exactly three options:
      | Option | Label                                                              |
      | 1      | Continue — run Wave 2 or refine shortlist                          |
      | 2      | Start fresh — new interview, new wave                              |
      | 3      | Track B — all previous picks were taken; run fallback strategies   |
    And it waits for user input before loading any reference files

  Scenario: Session brief matches the exact output format
    Given names.md exists with project "developer productivity SaaS" and shortlist ["codeforge.io", "devpulse.com"]
    And the brand profile is Tone=B, Direction=A, Mode=A, Length=A
    When the skill outputs the session brief
    Then the brief matches:
      """
      Previous session: developer productivity SaaS
      Brand profile: Tone=B | Direction=A | Mode=A | Length=A
      Shortlisted: codeforge.io, devpulse.com
      Options:
        1. Continue — run Wave 2 or refine shortlist
        2. Start fresh — new interview, new wave
        3. Track B — all previous picks were taken; run fallback strategies
      """

  # --- Continue path ---

  Scenario: Continue path loads brand-interview.md and generation-archetypes.md
    Given names.md exists
    And the user chooses option 1 (Continue)
    When Step 0 completes
    Then brand-interview.md is loaded before generating any new candidates
    And generation-archetypes.md is loaded before generating any new candidates
    And the skill skips Steps 1–7 and jumps to Step 8

  Scenario: Continue path does not re-run the brand interview
    Given names.md exists
    And the user chooses option 1 (Continue)
    When Step 0 completes
    Then the skill does not ask Q1 through Q6 again
    And the brand profile from names.md is used as-is for Wave 2 weighting

  # --- Start fresh path ---

  Scenario: Start fresh ignores names.md context and proceeds from Step 1
    Given names.md exists
    And the user chooses option 2 (Start fresh)
    When Step 0 completes
    Then the skill proceeds from Step 1 (project file detection)
    And no brand profile data from the existing names.md is pre-filled
    And the brand interview begins at Q1

  # --- Track B path ---

  Scenario: Track B path loads generation-archetypes.md only
    Given names.md exists
    And the user chooses option 3 (Track B)
    When Step 0 completes
    Then generation-archetypes.md is loaded
    And brand-interview.md is not loaded at Step 0
    And the skill follows the Track B section within Step 8

  Scenario: Track B path does not re-run the brand interview
    Given names.md exists
    And the user chooses option 3 (Track B)
    When Step 0 completes
    Then the skill does not ask Q1 through Q6
    And it proceeds directly to Track B Strategy 1

  # --- Guard: no reference files loaded before user chooses ---

  Scenario: No reference files are loaded before user selects an option
    Given names.md exists
    When the skill displays the session brief
    Then brand-interview.md has not been loaded yet
    And generation-archetypes.md has not been loaded yet
    And tld-catalog.md has not been loaded yet
