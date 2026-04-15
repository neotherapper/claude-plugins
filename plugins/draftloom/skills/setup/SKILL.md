---
name: setup
command: /draftloom:setup
description: "This skill should be used when the user asks to create a writing profile, set up their blog voice, create a new blog profile, or run draftloom setup."
version: "0.1.0"
references:
  - references/interview-questions.md
  - references/profile-schema.md
  - references/storage-guide.md
---

# Draftloom Setup Skill

Guides the user through creating or editing a named voice profile for blog post drafting.

## Entry point

On invocation, check `.draftloom/profiles/` for existing profile files.

### If no profiles directory or directory is empty

Proceed directly to Create mode (Step 2 below).

### If profiles exist

Present three options:
1. Create a new profile
2. Edit an existing profile (list profile names)
3. Delete a profile (list profile names, ask for confirmation)

Wait for the user's choice before proceeding.

---

## Edit mode (`/draftloom:setup edit {name}` or user chooses option 2)

Load the profile JSON from `.draftloom/profiles/{name}.json`.

Show current values for all fields. Ask the user which field(s) to update. Apply each change one at a time, confirming the new value before saving.

Save the updated profile to the same path. Confirm: "Profile '{name}' updated."

Load `references/profile-schema.md` to validate field formats before saving.

---

## Create mode (no profiles exist, or user chooses option 1)

Ask the following 3 essential questions **one at a time**. Wait for the answer to each before asking the next.

Load `references/interview-questions.md` for the exact question wording and validation rules.

### Question 1 — Profile name

Ask for a profile name (slug format, e.g. `george-personal`). Validate: lowercase, hyphens only, no spaces, no special characters. If invalid, explain and re-ask.

### Question 2 — Target audience

Ask: "Who is your target reader? (e.g. indie hackers, senior engineers, marketing managers)"

Accept free text. No validation required.

### Question 3 — Tone

Ask: "How would you describe your writing tone? Choose 3–5 adjectives, or pick from these presets:
- authoritative
- conversational
- technical
- witty
- direct
- inspirational

You can mix presets and your own words."

Accept a list of 3–5 adjectives. If fewer than 3, ask for at least one more.

---

## Save profile

Construct the profile JSON using the 3 collected answers. Set all deferred fields to `null`. Load `references/profile-schema.md` for the full schema.

Determine storage path:
- Check if `.draftloom/config.json` exists. If `storage_mode: "global"`, write to `~/.draftloom/profiles/{name}.json`.
- Otherwise write to `.draftloom/profiles/{name}.json`.

Load `references/storage-guide.md` if the user asks about storage options.

Write the profile JSON. Confirm: "Profile '{name}' saved to `.draftloom/profiles/{name}.json`."

---

## Post-save: deferred fields hint

After confirming save, show:

```
Profile created. Optional extras you can add later with `/draftloom:setup edit {name}`:
  • Blog URL
  • Content pillars (topic clusters)
  • Distribution channels
  • Typical post length preference
  • Writing inspiration (authors, publications)
  • CTA goal (newsletter, follow, contact)
  • Brand voice examples (local file, URL, or inline text)
```

---

## Delete mode (user chooses option 3)

List profiles. Ask which to delete. Ask for confirmation: "Delete '{name}'? This cannot be undone. (y/n)". On confirmation, remove the file. Confirm deletion.
