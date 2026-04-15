Feature: learn + learn:micro skills — routing, lesson delivery, quiz, and knowledge vault integration

  Background:
    Given learn v0.1.0 is installed in Claude Code
    And the visual server is running at localhost:7337

  # ── Routing — single concept ──────────────────────────────────────────────

  Scenario: Single concept routes to learn:micro without asking
    When I run /learn with prompt "teach me CSS flexbox"
    Then the scope classifier determines flexbox is a single concept (not > 3 sub-concepts)
    And the router invokes learn:micro with topic="CSS flexbox"
    And the router does NOT ask any clarifying question before routing

  Scenario: Router surfaces its routing decision to the user
    When I run /learn with prompt "teach me CSS flexbox"
    Then the router outputs a visible routing decision before the lesson starts
    And the message identifies the skill selected: "learn:micro"
    And the message identifies the topic: "CSS flexbox"

  # ── Routing — broad topic ─────────────────────────────────────────────────

  Scenario: Broad topic triggers scope classifier clarifying question
    When I run /learn with prompt "teach me React"
    Then the scope classifier determines React has > 3 sub-concepts
    And the router asks exactly one clarifying question: "Full roadmap or one focused concept?"
    And the router does NOT proceed until the user answers

  Scenario: User selects one concept after broad topic prompt
    Given the router has asked "Full roadmap or one focused concept?" for "React"
    When I answer "one concept — React hooks"
    Then the router invokes learn:micro with topic="React hooks"
    And the router does NOT ask any further questions

  Scenario: User selects full roadmap after broad topic prompt — V2 deflection
    Given the router has asked "Full roadmap or one focused concept?" for "React"
    When I answer "full roadmap"
    Then the router responds: "Learning paths and progress tracking are coming soon. What specific concept should we start with?"
    And the router does NOT invoke learn:micro until the user provides a specific concept

  # ── Routing — explicit expertise level inline ─────────────────────────────

  Scenario: Inline expertise level routes to learn:micro with level override
    When I run /learn with prompt "teach me async/await, I'm a beginner"
    Then the scope classifier determines async/await is a single concept
    And the router invokes learn:micro with topic="async/await" and level="beginner"
    And the router does NOT ask the user their expertise level

  Scenario: Inline expertise level advanced overrides stored prefs
    Given the user has stored expertise level "intermediate" in preferences
    When I run /learn with prompt "teach me the event loop, I'm advanced"
    Then the router invokes learn:micro with topic="event loop" and level="advanced"
    And the stored preference is not used for this lesson

  # ── Routing — debug mode ──────────────────────────────────────────────────

  Scenario: LEARN_DEBUG=1 logs routing decision before lesson starts
    Given the environment variable LEARN_DEBUG is set to "1"
    When I run /learn with prompt "teach me CSS flexbox"
    Then the skill logs a routing decision entry before the lesson content appears
    And the log entry includes: topic, scope classifier result, selected skill, and detected level
    And the lesson then proceeds normally

  # ── Expertise level — first use ───────────────────────────────────────────

  Scenario: First use with no stored prefs — skill asks expertise level
    Given no user preferences file exists for the learn plugin
    When I run /learn with prompt "teach me CSS flexbox"
    Then the skill asks: "What's your expertise level? (beginner / intermediate / advanced)"
    And waits for the user's answer before generating the lesson
    And the answer is used for this lesson as the level

  Scenario: First use answer stored as default for future lessons
    Given no user preferences file exists
    When I answer "intermediate" at the first-use expertise prompt
    Then the skill stores "intermediate" as the default expertise level
    And does not ask again on the next lesson invocation

  # ── Lesson generation ─────────────────────────────────────────────────────

  Scenario: learn:micro generates Lesson JSON one-shot
    When learn:micro is invoked with topic="CSS flexbox" and level="intermediate"
    Then the skill generates a single Lesson JSON object in one prompt call
    And the JSON conforms to the Lesson schema: topic, level, concept, why, example, common_mistakes, generate_task, quiz, resources, estimated_minutes
    And the quiz array contains exactly 3 QuizQuestion objects

  Scenario: Lesson HTML written to screen_dir after generation
    When learn:micro generates the Lesson JSON for "CSS flexbox"
    Then the skill writes a lesson HTML file to screen_dir
    And the filename includes the topic slug (e.g. css-flexbox.html)
    And the visual server detects the new file and serves the updated lesson page

  Scenario: Visual server serves lesson at localhost:7337/lesson after learn:micro runs
    When the lesson HTML is written to screen_dir
    Then localhost:7337/lesson serves the updated lesson content
    And the page title reflects the lesson topic

  # ── Lesson template — section order ──────────────────────────────────────

  Scenario: Rendered lesson shows all sections in the correct template order
    When learn:micro generates and renders a lesson for "CSS flexbox"
    Then the lesson page contains all of the following sections in this order:
      | 1 | Concept        |
      | 2 | Why            |
      | 3 | Example        |
      | 4 | Common mistakes|
      | 5 | Generate task  |
      | 6 | Quiz           |
      | 7 | What to explore next |

  Scenario: Lesson concept section is jargon-minimal (beginner level)
    When learn:micro is invoked with topic="CSS flexbox" and level="beginner"
    Then the concept section uses plain language without advanced terminology
    And the example uses simple, annotated code

  Scenario: Lesson concept section uses technical depth (advanced level)
    When learn:micro is invoked with topic="CSS flexbox" and level="advanced"
    Then the concept section includes technical detail appropriate for advanced users
    And the example demonstrates non-obvious or nuanced usage

  # ── Quiz — default ON ─────────────────────────────────────────────────────

  Scenario: Quiz is active by default — user must opt out to skip
    When learn:micro completes the lesson content for "CSS flexbox"
    Then the quiz section is present and active without any user action
    And the first quiz question is displayed automatically
    And no prompt or option to start the quiz is required

  Scenario: Quiz presents exactly 3 questions
    When the quiz section of the lesson is displayed
    Then exactly 3 quiz questions are shown
    And each question is numbered (1 of 3, 2 of 3, 3 of 3)

  # ── Quiz — opt out ───────────────────────────────────────────────────────

  Scenario: User opts out of quiz — lesson ends with what-to-explore-next
    When the quiz section is active
    And I respond "skip quiz"
    Then the skill skips all remaining quiz questions
    And the lesson ends with only the "what to explore next" section visible
    And no quiz score is shown

  # ── Quiz — evaluation with explanation ───────────────────────────────────

  Scenario: Quiz answer evaluated with explanation of why correct
    Given question 1 of the quiz is displayed: a multiple choice question
    When I select the correct answer option
    Then the skill confirms the answer is correct
    And shows the explanation from the QuizQuestion.explanation field
    And proceeds to question 2

  Scenario: Quiz answer evaluated with explanation of why incorrect
    Given question 2 of the quiz is displayed
    When I select an incorrect answer option
    Then the skill indicates the answer is incorrect
    And shows the correct answer
    And shows the explanation of why the correct answer is right
    And proceeds to question 3

  # ── Quiz — question types ─────────────────────────────────────────────────

  Scenario: Quiz contains all three required question types
    When learn:micro generates the quiz for any lesson
    Then the quiz includes at least one "multiple_choice" question
    And at least one "fill_blank" question
    And at least one "explain" (explain-in-your-own-words) question

  # ── What to explore next ──────────────────────────────────────────────────

  Scenario: Every lesson ends with exactly one suggested follow-on concept
    When learn:micro renders any lesson
    Then the "what to explore next" section appears as the final section
    And it contains exactly one follow-on concept suggestion
    And the suggestion is contextually related to the lesson topic

  # ── Knowledge vault — hit ─────────────────────────────────────────────────

  Scenario: Topic matches a detailed vault entry — vault resource appears in lesson
    Given the nikai knowledge vault contains a "detailed" entry for "CSS flexbox" (or its parent category)
    When learn:micro generates resources for "CSS flexbox"
    Then the vault entry's URL and summary are included in the lesson resources section
    And the resource is labelled with its vault-sourced title
    And the resource type reflects the vault entry's classification

  Scenario: Topic matches only a stub vault entry — stub is skipped
    Given the knowledge vault contains only a "stub" entry (not "detailed") for the topic
    When learn:micro generates resources for that topic
    Then the stub entry is not included in lesson resources
    And the skill falls back to LLM-generated links for that resource slot

  # ── Knowledge vault — miss ────────────────────────────────────────────────

  Scenario: Topic has no vault entry — LLM-generated link with AI-suggested label
    Given the knowledge vault has no entry (detailed or stub) for the topic "browser event loop"
    When learn:micro generates resources for "browser event loop"
    Then the lesson resources include at least one LLM-generated link
    And each LLM-generated link is labelled "(AI-suggested, verify link)"
    And no vault-sourced link is shown for this topic

  # ── AI caveat ────────────────────────────────────────────────────────────

  Scenario: Every lesson shows the AI-generated content caveat
    When learn:micro renders any lesson
    Then the lesson page contains the text: "This explanation is AI-generated — verify against official docs"
    And this caveat is visible without scrolling past the concept section
    And it appears on every lesson regardless of whether vault resources were found

  # ── Estimated time ────────────────────────────────────────────────────────

  Scenario: Lesson card shows estimated reading and practice time
    When learn:micro renders a lesson for any topic
    Then the lesson card displays an estimated time in minutes
    And the value is drawn from the Lesson.estimated_minutes field
    And the label clearly indicates it is an estimated read/practice time

  # ── Lesson input contract ─────────────────────────────────────────────────

  Scenario: learn:micro is independently invocable by power users
    When I run /learn:micro with topic="CSS grid" and level="intermediate" directly
    Then learn:micro generates and renders the lesson without routing through the learn skill
    And the full lesson template is produced as normal

  # ── Error — server not running ────────────────────────────────────────────

  Scenario: learn:micro checks state_dir/server-info before writing HTML
    Given the visual server was running but has since stopped
    When learn:micro attempts to write the lesson HTML to screen_dir
    Then the skill reads state_dir/server-info and detects the server is not running
    And the skill does NOT write the lesson HTML
    And the skill outputs an error: "Visual server is not running. Start it with `learn serve`."
    And no lesson is rendered

  # ── R-UX-005 — table of contents ─────────────────────────────────────────

  Scenario: Lesson table of contents shown before teaching begins
    When learn:micro starts delivering a lesson for "CSS flexbox"
    Then the lesson opens with a table of contents listing all sections
    And the table of contents is visible before the concept section content
    And the user can see the full lesson structure before reading begins

  # ── R-SKILL-008 — router extensibility ───────────────────────────────────

  Scenario: New sub-skill added without modifying the router
    Given a new sub-skill "learn:debate" is registered in the plugin manifest
    When I run /learn with a prompt that matches the debate intent
    Then the router dispatches to learn:debate without any change to the router's own code
    And existing routing for learn:micro continues to work correctly

  # ── R-MEM-001 / R-MEM-002 / R-MEM-003 / R-MEM-006 — progress storage ────

  Scenario: Lesson completion recorded to file-based progress store
    Given learn:micro has delivered and completed a lesson for "CSS flexbox"
    When the lesson session ends (quiz complete or skipped)
    Then a progress record is written to the plugin's local progress directory
    And the record is a human-readable markdown or YAML file
    And the record contains: topic, completion_status, quiz_score, last_accessed timestamp

  Scenario: Progress file is readable and editable by the user directly
    Given a progress record exists for "CSS flexbox"
    When I open the progress file in a text editor
    Then the file is valid markdown or YAML (not binary or encoded)
    And I can edit the completion_status manually and the plugin reads the updated value on next run

  Scenario: Progress persists across Claude Code sessions
    Given a lesson for "CSS flexbox" was completed in a previous Claude Code session
    And the progress file still exists on disk
    When I start a new Claude Code session and run /learn
    Then the plugin reads the existing progress file
    And does not present "CSS flexbox" as a topic that has never been studied

  # ── R-CONTENT-002 — resource type categorisation ─────────────────────────

  Scenario: Lesson resource links are visibly categorised by type
    When learn:micro renders a lesson with resources
    Then each resource link is labelled with its type: "Official Docs", "Tutorial", "Video", or "Interactive"
    And the label is visible alongside the resource URL or title in the lesson card

  # ── R-CONTENT-006 — resource quality check ───────────────────────────────

  Scenario: LLM-generated resource links are labelled as unverified
    When learn:micro generates LLM-suggested resource links for a topic with no vault entry
    Then each such link is clearly labelled "(AI-suggested, verify link)"
    And the lesson does not present AI-suggested links as verified or authoritative

  # ── R-UX-003 — English-only at launch ────────────────────────────────────

  Scenario: Plugin responds in English regardless of system locale
    Given the operating system locale is set to a non-English language (e.g. el_GR)
    When I run /learn with prompt "teach me CSS flexbox"
    Then all skill output — routing messages, lesson content, error messages — is in English
    And no localised text is injected from the system locale

  # ── R-PERF-001 — performance bounds ──────────────────────────────────────

  Scenario: Lesson generation completes within 15 seconds
    When learn:micro is invoked with a valid topic and level
    Then the Lesson JSON is fully generated and written to screen_dir within 15 seconds of invocation
    And the skill does not time out or produce a partial lesson within this window

  Scenario: Visual server first paint is under 1 second after lesson is written
    Given the visual server is running and the lesson HTML has been written to screen_dir
    When the browser loads localhost:7337/lesson
    Then the first meaningful paint (lesson card visible) occurs within 1 second
    And the page does not depend on external resources that could delay rendering
