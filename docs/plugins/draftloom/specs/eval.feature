Feature: eval skill — score any existing blog post across 4 dimensions

  Background:
    Given Draftloom v0.1.0 is installed in Claude Code

  # ── Invocation ────────────────────────────────────────────────────────────

  Scenario: Eval on an existing markdown file
    Given a file my-post.md exists in the project
    When I run /draftloom:eval and provide the path my-post.md
    Then the skill creates a temporary workspace posts/my-post/
    And copies my-post.md to posts/my-post/draft.md
    And runs all 4 eval agents without running the writer first

  Scenario: Eval with a profile for voice matching
    When I run /draftloom:eval and a profile exists
    Then the skill asks which profile to score voice against
    And voice-eval loads that profile for tone comparison

  Scenario: Eval without a profile uses generic voice scoring
    When I run /draftloom:eval and answer "none" to the profile question
    Then voice-eval scores against general clarity and consistency
    And does not attempt to load a profile JSON

  # ── Scoring output ────────────────────────────────────────────────────────

  Scenario: All 4 dimension scores shown with feedback
    When the eval agents complete
    Then the skill shows a score report with:
      | dimension   | score | status |
      | SEO         | 0-100 | ✓ or ⚠ |
      | Hook        | 0-100 | ✓ or ⚠ |
      | Voice       | 0-100 | ✓ or ⚠ |
      | Readability | 0-100 | ✓ or ⚠ |
    And each failing dimension shows sections_affected and a concrete recommendation

  Scenario: Aggregate score reported as minimum of all dimensions
    Given scores: seo=82, hook=91, voice=68, readability=78
    Then the aggregate_score shown is 68
    And voice is flagged as the weakest dimension to address first

  Scenario: scores.json written to workspace
    When eval completes
    Then posts/my-post/scores.json exists
    And contains schema_version, iteration, timestamp, aggregate_score, and all 4 dimension objects

  # ── Patching offer ────────────────────────────────────────────────────────

  Scenario: Patch offer shown when dimensions fail
    Given any dimension scored below 75
    When eval completes
    Then the skill asks: "Patch failing dimensions? (y/n)"
    When I answer yes
    Then the writer agent reads sections_affected from each failing eval JSON
    And patches only those sections
    And a second eval pass runs to show the improvement

  Scenario: No patch offer when all dimensions pass
    Given all 4 dimension scores are ≥ 75
    When eval completes
    Then the skill shows "All dimensions passing."
    And does not offer to patch

  # ── Eval agent output contract ────────────────────────────────────────────

  Scenario: SEO eval checks keyword density and meta fields
    When seo-eval runs on a post with low keyword density and no meta description
    Then seo-eval.json contains sections_affected: ["meta_description", "intro"]
    And specifics include keyword_coverage percentages for primary and secondary keywords
    And recommend includes a concrete rewrite suggestion

  Scenario: Hook eval scores first sentence and title
    When hook-eval runs on a post with a weak opening line
    Then hook-eval.json score is below 75
    And sections_affected includes "headline" or "intro"
    And specifics describe which hook property is missing (curiosity_gap, specificity, social_proof, etc.)

  Scenario: Voice eval compares against profile tone adjectives
    Given profile george-personal has tone ["direct", "opinionated", "technical"]
    When voice-eval runs on a post that is formal and hedged
    Then voice-eval.json score reflects the mismatch
    And feedback identifies which tone adjectives are absent from the prose

  Scenario: Voice eval loads brand_voice_examples when present
    Given profile has brand_voice_examples with source "local_file"
    When voice-eval runs
    Then it reads the referenced file and compares prose patterns against it

  Scenario: Readability eval checks structural patterns
    When readability-eval runs on a post with long unbroken paragraphs and no subheadings
    Then readability-eval.json score is below 75
    And sections_affected lists the offending sections
    And recommend suggests subheading placement and paragraph breaks

  # ── Eval agent resilience ────────────────────────────────────────────────

  Scenario: Malformed eval JSON aborts aggregation for that dimension
    Given hook-eval.json is written with a missing "score" field
    When the orchestrator validates the file
    Then it logs a validation error for hook dimension
    And reports hook score as "unavailable" in the summary
    And does not crash the other dimension scores

  Scenario: Eval agent fails all retries — dimension skipped gracefully
    Given an eval agent fails 3 consecutive attempts with timeout
    Then that dimension is marked "unavailable" in scores.json
    And the skill continues to show scores for the remaining 3 dimensions
    And warns the user that one dimension could not be evaluated
