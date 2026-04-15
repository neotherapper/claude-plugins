Feature: setup skill — create and manage voice profiles for Draftloom

  Background:
    Given Draftloom v0.1.0 is installed in Claude Code

  # ── First run ─────────────────────────────────────────────────────────────

  Scenario: First-time setup with no existing profiles
    Given no .draftloom/ directory exists in the project
    When I run /draftloom:setup
    Then the skill asks for a profile name (one question at a time)
    And the skill asks for a target audience description
    And the skill asks for tone adjectives or offers presets to pick from
    And .draftloom/profiles/{name}.json is created with the 3 essential fields
    And .draftloom/config.json is created with storage_mode "project"
    And the response confirms the profile was saved
    And the response hints that 6 optional fields are available via /draftloom:setup edit {name}

  Scenario: Setup asks for storage preference on first run
    Given no .draftloom/ directory exists anywhere
    When I run /draftloom:setup
    Then the skill asks "Store profiles in this project only, or globally? (project/global)"
    And .draftloom/config.json records the chosen storage_mode

  # ── Essential fields ──────────────────────────────────────────────────────

  Scenario: Profile is saved with exactly 3 essential fields on create
    When I complete the 3-question create flow
    Then profile JSON contains: id, audience, tone, storage, created_at, updated_at
    And optional fields are absent (blog_url, pillars, channels, typical_length, inspiration, cta_goal)

  Scenario: Tone presets offered when user is unsure
    When I run /draftloom:setup and reach the tone question
    And I respond "not sure" or "give me options"
    Then the skill shows tone presets: authoritative · conversational · technical · witty · direct · inspirational
    And I can pick one or more to form my tone array

  # ── Editing profiles ──────────────────────────────────────────────────────

  Scenario: Edit a single field in an existing profile
    Given .draftloom/profiles/george-personal.json exists
    When I run /draftloom:setup edit george-personal
    Then the skill shows all current field values
    And asks which field to update
    When I choose "tone"
    Then the skill shows the current value and prompts for the new value
    And saves only the changed field
    And updated_at is refreshed in the profile JSON

  Scenario: Edit adds a deferred optional field
    Given .draftloom/profiles/george-personal.json exists with no blog_url
    When I run /draftloom:setup edit george-personal and enter a blog_url
    Then blog_url is added to the profile JSON

  Scenario: Profile edit shows before/after delta
    When I update any field
    Then the response shows: "Before: [old value] → After: [new value]"
    And asks "Edit another field? (y/n)"

  # ── Multiple profiles ─────────────────────────────────────────────────────

  Scenario: Multiple profiles listed with recency on setup open
    Given .draftloom/profiles/ contains george-personal.json and vanguard-corp.json
    When I run /draftloom:setup
    Then the skill shows: "create new / edit existing / delete"
    And edit shows profiles ordered by last-used date with draft count

  Scenario: Delete a profile
    Given .draftloom/profiles/george-personal.json exists
    When I run /draftloom:setup and choose delete → george-personal
    Then the skill asks "Delete george-personal? This cannot be undone. (y/n)"
    And on confirm, the profile file is removed

  # ── Storage portability ───────────────────────────────────────────────────

  Scenario: Global storage stores profiles in home directory
    When I run /draftloom:setup and choose "global" storage
    Then .draftloom/config.json records storage_mode "global"
    And profiles are saved to ~/.draftloom/profiles/

  Scenario: Project without .draftloom falls back to global profiles
    Given ~/.draftloom/profiles/george-personal.json exists
    And no .draftloom/ exists in the current project
    When I run /draftloom:draft
    Then the skill finds and uses the global profile without prompting setup again

  # ── Validation ────────────────────────────────────────────────────────────

  Scenario: Profile name must be slug format
    When I enter "My Personal Blog!" as the profile name
    Then the skill rejects it and asks again
    And explains the name must be lowercase letters, numbers, and hyphens only

  Scenario: Tone array requires at least one adjective
    When I enter an empty tone
    Then the skill rejects it and prompts again
