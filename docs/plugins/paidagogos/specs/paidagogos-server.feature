Feature: paidagogos visual server — start, serve lessons, UI interactions, and lifecycle

  Background:
    Given paidagogos v0.1.0 is installed in Claude Code

  # ── Server start ──────────────────────────────────────────────────────────

  Scenario: paidagogos serve starts visual server at localhost:7337
    When I run "paidagogos serve"
    Then the server binds to 127.0.0.1 on port 7337
    And the server logs: "Visual server running at http://localhost:7337"
    And the server writes its port to state_dir/server-info
    And the server is accessible at http://localhost:7337

  Scenario: Server binds to localhost only — never 0.0.0.0
    When I run "paidagogos serve"
    Then the server bind address is 127.0.0.1
    And the server is not reachable from any external network interface

  Scenario: Server starts with zero external dependencies at runtime
    Given no npm install has been run since plugin installation
    When I run "paidagogos serve"
    Then the server starts successfully using only bundled dependencies
    And no package download or install step occurs

  # ── Port conflict ─────────────────────────────────────────────────────────

  Scenario: Port 7337 occupied — server auto-increments to next free port
    Given port 7337 is already in use by another process
    When I run "paidagogos serve"
    Then the server auto-increments to port 7338
    And the server logs the actual URL: "Visual server running at http://localhost:7338"
    And the server writes the actual port (7338) to state_dir/server-info

  Scenario: Port 7337 and 7338 both occupied — continues incrementing
    Given ports 7337 and 7338 are both occupied
    When I run "paidagogos serve"
    Then the server finds the next free port (e.g. 7339)
    And logs the actual URL used
    And writes the actual port to state_dir/server-info

  # ── Server not running — lesson blocked ───────────────────────────────────

  Scenario: User runs /paidagogos but server is not running — blocked with clear error
    Given the visual server is not running
    When I run /paidagogos with prompt "teach me CSS flexbox"
    And the skill checks state_dir/server-info and finds the server is not running
    Then the skill does not generate a lesson
    And the skill outputs: "Visual server is not running. Start it with `paidagogos serve`."
    And no lesson HTML is written to screen_dir

  # ── Lesson renders in browser ─────────────────────────────────────────────

  Scenario: Lesson HTML appears in browser after paidagogos:micro runs
    Given the visual server is running at localhost:7337
    When paidagogos:micro generates a lesson for "CSS flexbox" and writes lesson HTML to screen_dir
    Then the visual server detects the new HTML file via file-watcher
    And the browser at localhost:7337/lesson reloads to show the new lesson
    And all lesson sections are visible: concept, why, example, common mistakes, generate task, quiz, what to explore next

  Scenario: Server falls back to terminal-rendered lesson when server fails to start
    Given the visual server fails to start (all ports in auto-increment range are occupied)
    When paidagogos:micro generates a lesson
    Then the skill renders the lesson content in the terminal
    And outputs a warning: "Visual server unavailable — showing lesson in terminal"

  # ── Code copy button ──────────────────────────────────────────────────────

  Scenario: Code example block has a working copy button
    Given a lesson with a code example is rendered in the browser
    When I click the copy button on the code block
    Then the code content is copied to the clipboard
    And the copy button shows a visual confirmation (e.g. "Copied!")
    And the page does not navigate or reload

  # ── Dark mode ────────────────────────────────────────────────────────────

  Scenario: OS dark mode preference — lesson card renders in dark theme
    Given the operating system reports prefers-color-scheme: dark
    When the lesson page loads in the browser
    Then the lesson card background is dark
    And text colours meet contrast requirements for dark backgrounds
    And no explicit user action is required to activate dark mode

  # ── Light mode ───────────────────────────────────────────────────────────

  Scenario: OS light mode preference — lesson card renders in light theme
    Given the operating system reports prefers-color-scheme: light
    When the lesson page loads in the browser
    Then the lesson card background is light
    And text colours meet contrast requirements for light backgrounds

  # ── No external CDN ───────────────────────────────────────────────────────

  Scenario: Lesson page makes zero external network requests
    When the lesson page is loaded in the browser
    Then no requests are made to any external domain (CDN, fonts, analytics, etc.)
    And all CSS, JavaScript, and font assets are served from localhost:7337
    And the browser network log shows zero cross-origin requests

  # ── Quiz interaction in browser ───────────────────────────────────────────

  Scenario: User clicks answer option in browser — selection recorded to state_dir/events
    Given a lesson quiz is rendered in the browser
    When I click an answer option for question 1
    Then the selected option is visually highlighted
    And an event is written to state_dir/events containing: lesson_topic, question_index, selected_answer, timestamp
    And the UI shows the quiz explanation for the selected answer

  Scenario: Quiz shows explanation inline after answer selection in browser
    Given question 2 of the quiz is displayed in the browser
    When I click any answer option
    Then the explanation text appears below the question without a page reload
    And the next question becomes available

  # ── Server auto-exit ─────────────────────────────────────────────────────

  Scenario: No activity for 30 minutes — server exits cleanly
    Given the visual server has been running with no lesson writes and no browser requests for 30 minutes
    When the inactivity timeout is reached
    Then the server exits with code 0
    And logs: "Visual server exited after 30 minutes of inactivity"
    And state_dir/server-info is removed or marked as stopped

  Scenario: Activity resets the inactivity timer
    Given the visual server has been inactive for 25 minutes
    When paidagogos:micro writes a new lesson HTML to screen_dir
    Then the inactivity timer resets to 0
    And the server does not exit at the 30-minute mark

  # ── Server restart detection ──────────────────────────────────────────────

  Scenario: paidagogos:micro checks state_dir/server-info before writing HTML — server stopped
    Given the visual server was running but has since exited
    And state_dir/server-info reflects the stopped state
    When paidagogos:micro attempts to write the lesson HTML
    Then paidagogos:micro reads state_dir/server-info and detects the server is not running
    And paidagogos:micro does NOT write the lesson HTML to screen_dir
    And paidagogos:micro outputs: "Visual server is not running. Start it with `paidagogos serve`."

  Scenario: paidagogos:micro proceeds normally when server-info confirms server is running
    Given the visual server is running at port 7337
    And state_dir/server-info contains the correct port and running status
    When paidagogos:micro generates a lesson
    Then paidagogos:micro writes the lesson HTML to screen_dir without error
    And the lesson is served at the port recorded in server-info

  # ── R-VIS-006 — diagram rendering ─────────────────────────────────────────

  Scenario: Architectural or conceptual topic renders a diagram in the lesson card
    Given paidagogos:micro generates a lesson for a topic with a structural component (e.g. "CSS box model")
    And the Lesson JSON includes a diagram definition in Mermaid syntax
    When the lesson HTML is rendered in the browser
    Then the diagram is rendered visually inside the lesson card
    And the diagram is served from localhost with no external CDN call

  # ── R-ERR-001 — explicit error messages for all error states ──────────────

  Scenario: Bad lesson generation — explicit error message shown
    Given paidagogos:micro fails to generate a valid Lesson JSON (e.g. schema validation fails)
    When the generation error is detected
    Then the skill outputs an explicit user-facing error message describing what went wrong
    And the skill suggests a corrective action (e.g. "Try rephrasing your topic or run /paidagogos again")
    And no partial lesson HTML is written to screen_dir
