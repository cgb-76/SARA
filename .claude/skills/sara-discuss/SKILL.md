---
name: sara-discuss
description: "Run LLM-driven blocker-clearing session for a pipeline item before extraction"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

<objective>
This skill reads the source document for pipeline item N and generates a structured blocker list — everything that would cause `/sara-extract` to fail or produce wrong output. It works through blockers in priority order: unknown stakeholders first (resolved via inline `/sara-add-stakeholder`), then entity type ambiguities, context gaps, and cross-link candidates. The skill declares done objectively when the blocker list is empty; it then writes the resolved context to `discussion_notes` in `pipeline-state.json` and advances the item stage to `extracting`.

Note: `AskUserQuestion` is required in `allowed-tools` because `/sara-add-stakeholder` (invoked inline during stakeholder resolution) uses it for structured field collection.
</objective>

<process>

**Step 1 — Stage guard and item lookup**

Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: it must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
Output: `"Usage: /sara-discuss <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Find the item with key `"{N}"` in the `items` object (N is the full ID argument — for `/sara-discuss MTG-001`, N = `"MTG-001"`).

If no item exists with key `"{N}"`:
  Output: `"No pipeline item {N} found. Run /sara-ingest to register a new item, or run /sara-ingest with no arguments to see the full pipeline status."`
  STOP.

Check `items["{N}"].stage`. Expected stage: `"pending"`.

If actual stage != `"pending"`:
  Output: `"Item {N} is currently in stage '{actual_stage}'. Run /sara-discuss <ID> only when stage is 'pending'. If the item is 'extracting', run /sara-extract {N}."`
  STOP.

Store `{item}` = `items["{N}"]` for use in subsequent steps.

**Step 2 — Load source and context**

Read `raw/input/{item.filename}` using the Read tool. This is the source document.

Read `wiki/index.md` using the Read tool. This is the existing entity catalog for cross-link identification.

Read all files in `wiki/stakeholders/` using the Read tool. For each STK page found, extract both the `name` field and the `nickname` field from the frontmatter. Build a lookup `known_names` = the set of all `name` values AND all non-empty `nickname` values across all STK pages.

  Example: if STK-001 has `name: "Rajiwath Patel"` and `nickname: "Raj"`, then both `"Rajiwath Patel"` and `"Raj"` are in `known_names`. A source reference to "Raj" is NOT unknown.

Read `.sara/config.json` using the Read tool. This is needed by `/sara-add-stakeholder` when invoked inline in Step 4.

**Step 3 — Generate blocker list**

Using the source document and existing wiki context, identify all blockers in priority order. Present the full blocker list to the user as a structured summary before resolving anything.

**Priority 1 — Unknown stakeholders:** Scan the full source for every person mentioned by name (including informal references, initials, and nicknames). For each person found, check if their name appears in `known_names` (checking both `name` AND `nickname` fields — dual-field matching is required). Collect ALL unknown persons before proceeding. Do not process any Priority 2, 3, or 4 blockers until the complete list of unknown persons is identified.

**Priority 2 — Ambiguous entity type:** Identify any passage that could be classified as multiple entity types (for example: a statement that could be REQ or DEC, or a concern that could be RISK or REQ). List each ambiguity with the source passage and the candidate types.

**Priority 3 — Missing context gaps:** Identify references to concepts, systems, decisions, or terms mentioned in the source that are not present in `wiki/index.md` and whose meaning is unclear from the source alone. List each gap with the source reference.

**Priority 4 — Cross-link candidates:** Identify topics in the source that clearly relate to an existing wiki entity (by matching title or description in `wiki/index.md`). List each candidate with the wiki entity ID.

Present a structured blocker summary to the user before proceeding. Example format:

```
Blocker analysis for item {N} ({item.id}):

Priority 1 — Unknown stakeholders (N found):
  - [name A]
  - [name B]

Priority 2 — Ambiguous entity type (N found):
  - [description of passage + candidate types]

Priority 3 — Missing context gaps (N found):
  - [term or reference with source excerpt]

Priority 4 — Cross-link candidates (N found):
  - [topic in source → existing entity ID]

Total blockers: N. Resolving Priority 1 first.
```

If all four priority lists are empty: skip Steps 4 and 5 entirely and proceed to Step 6.

**Step 4 — Resolve unknown stakeholders (Priority 1)**

For each unknown stakeholder identified in Step 3:

  Output: `"Unknown stakeholder: {name}. Resolving via /sara-add-stakeholder."`

  Read `.claude/skills/sara-add-stakeholder/SKILL.md` using the Read tool.
  Execute the sara-add-stakeholder skill inline for this stakeholder.
  Pass `{name}` as the `$ARGUMENTS` value so the name prompt in sara-add-stakeholder Step 1 is skipped.
  Capture the returned `{STK-NNN}` ID from the skill's output.
  Add `{name} → {STK-NNN}` to the running `discussion_notes` context.

After all unknown stakeholders are resolved, proceed to Step 5.

**Step 5 — Work through remaining blockers (Priority 2 through 4)**

For each remaining blocker from the list (process in priority order: Priority 2, then Priority 3, then Priority 4):

  Present the specific blocker to the user as plain text with context from the source document.
  Where there are discrete options to choose from, label them A / B / C so the user can reply
  with a single letter. Example formats:

  For Priority 2 (ambiguous entity type — always has discrete options):
  ```
  Blocker [entity type ambiguity]: The passage '...' could be classified as:
    A) REQ — {brief reason}
    B) DEC — {brief reason}
  Which is correct? (reply A or B, or describe a different classification)
  ```

  For Priority 3 (context gap — open-ended, no options to label):
  `"Blocker [context gap]: The source references '{term}' but this does not appear in the wiki. What does this mean in context?"`

  For Priority 4 (cross-link candidate — binary confirm/deny):
  ```
  Blocker [cross-link candidate]: The source discusses '{topic}', which appears to relate to:
    A) {entity_ID} — '{entity_title}'
    B) Not a cross-link — treat as a new or unrelated topic
  Confirm? (reply A or B, or describe a different relationship)
  ```

  Wait for the user's reply using a plain-text wait (freeform rule — do NOT use AskUserQuestion for these questions).

  Incorporate the user's response into the running `discussion_notes` string.

  Mark that blocker resolved. Proceed to the next blocker.

Declare completion ONLY when all blockers (Priority 1 through Priority 4) are resolved and the blocker list is empty.

**Step 6 — Write resolved context and advance stage**

Compile `{discussion_notes}` as a single plain-text string summarising all resolved context:
- Resolved stakeholders with their STK-NNN IDs (e.g. "Alice Wang → STK-002")
- Entity type decisions made (e.g. "The budget discussion in paragraph 3 is a DEC, not a REQ")
- Context gaps filled (e.g. "'SalesForce' = the CRM system in use by the Sales department")
- Cross-link confirmations (e.g. "The capacity discussion relates to RISK-003 — confirmed cross-link")

Read `.sara/pipeline-state.json` using the Read tool.

Update `items["{N}"]` in memory:
  - Set `stage` = `"extracting"`
  - Set `discussion_notes` = `"{discussion_notes}"`

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.

Do NOT use Bash shell text-processing tools — use Read and Write tools only.

Output:
```
Discussion complete. All blockers resolved.
Discussion notes saved to pipeline-state.json ({N} stage: extracting).
Run /sara-extract {N} to proceed to extraction.
```

</process>

<notes>
- Stakeholder matching in Step 2 and Step 3 MUST check both the `name` field AND the `nickname` field in every STK page. A source reference to "Raj" is NOT unknown if any STK page has `nickname: "Raj"` — even if the page's `name` field is "Rajiwath Patel". Failure to check both fields causes false unknown-stakeholder blockers.
- The `known_names` set is built at Step 2 from a fresh read of `wiki/stakeholders/`. Do not rely on any cached or earlier-read index — re-read the directory at this point so any STK pages created by prior `/sara-add-stakeholder` runs are included.
- Priority 1 (unknown stakeholders) must be fully cleared before any Priority 2, 3, or 4 blocker is tackled. Batch all unknown stakeholders upfront; do not interleave stakeholder work with other blocker types.
- Blocker Priority 2–4 clarification uses plain-text output and waits for the user's reply. Do NOT use AskUserQuestion for these open-ended questions (freeform rule applies). AskUserQuestion is only invoked within the inline sara-add-stakeholder sub-skill during Priority 1 work.
- Stage advance to `"extracting"` happens ONLY after all blockers across all four priorities are resolved. Do not write `"extracting"` partway through the session.
- The `discussion_notes` string is the key output — it carries resolved context forward into `/sara-extract`. Make it specific: include STK-NNN IDs, entity type decisions, wiki entity IDs for confirmed cross-links. Vague notes reduce the quality of the extraction step.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The JSON key in `items` is that same ID string. For `/sara-discuss MTG-001`, look up `items["MTG-001"]`.
- When invoking `/sara-add-stakeholder` inline: read `.claude/skills/sara-add-stakeholder/SKILL.md` fresh for each stakeholder. Pass the stakeholder name as `$ARGUMENTS`. The sub-skill will collect optional fields (nickname, vertical, department, email, role) via AskUserQuestion before writing the STK page and committing. This is expected — the AskUserQuestion calls originate from the sub-skill, which is why `AskUserQuestion` is in this skill's `allowed-tools`.
- pipeline-state.json is written using Read + Write tools only — never shell text-processing tools.
</notes>
