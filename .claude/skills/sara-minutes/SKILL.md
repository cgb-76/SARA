---
name: sara-minutes
description: "Generate plain-text meeting minutes from a completed meeting item"
argument-hint: "<ID>"
allowed-tools:
  - Read
version: 1.0.0
---

<objective>
Reads pipeline state and wiki artifacts for a completed meeting item, then outputs structured
meeting minutes as plain text. Nothing is written to disk or committed to git.

The minutes are structured around wiki entities actually created or updated for this meeting
item (per extraction_plan) — not a generic summary of the transcript.
</objective>

<process>

**Step 1 — Item lookup and guards (type first, then stage)**

Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: must be a non-empty pipeline item ID. If empty:
  Output: `"Usage: /sara-minutes <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Find the item with key `"{N}"` in the `items` object (N is the full ID argument — for `/sara-minutes MTG-001`, N = `"MTG-001"`).

If no item exists with key `"{N}"`:
  Output: `"No pipeline item {N} found. Run /sara-ingest with no arguments to see the pipeline status."` and STOP.

**Type guard (D-02, D-03 — type check FIRST):**
Check `items["{N}"].type`. Expected value: `"meeting"` (lowercase, as stored by `/sara-ingest`).
If `items["{N}"].type != "meeting"`:
  Output: `"{N} is a {item.type} item. /sara-minutes only works on meeting items (MTG-NNN)."` and STOP.

**Stage guard (D-01 — stage check SECOND):**
Check `items["{N}"].stage`. Expected value: `"complete"`.
If `items["{N}"].stage != "complete"`:
  Output: `"Item {N} is in stage '{item.stage}'. Run /sara-update {N} first to complete the extraction pipeline before generating minutes."` and STOP.

Store `{item}` = `items["{N}"]`.
Store `{extraction_plan}` = `items["{N}"].extraction_plan`.

**Step 2 — Aggregate wiki entities from extraction_plan (D-04, D-05)**

Initialize four lists: `{decisions}`, `{actions}`, `{risks}`, `{requirements}` — all empty.
Also initialize `{stakeholder_ids}` = [] — list of STK IDs encountered in extraction_plan.

If `{extraction_plan}` is empty:
  Set `{no_entities}` = true. Skip to Step 3.

For each artifact in `{extraction_plan}` (aggregate BOTH `create` and `update` actions — both represent what this meeting did to the wiki):

  Determine the entity ID:
  - If `artifact.action == "create"`: use `artifact.assigned_id`
  - If `artifact.action == "update"`: use `artifact.existing_id`
  Store as `{entity_id}`.

  Determine `{wiki_path}` from `artifact.type`:
  - `requirement` → `wiki/requirements/{entity_id}.md`
  - `decision`    → `wiki/decisions/{entity_id}.md`
  - `action`      → `wiki/actions/{entity_id}.md`
  - `risk`        → `wiki/risks/{entity_id}.md`
  - `stakeholder` → skip (collect IDs separately — see below)

  Read `{wiki_path}` using the Read tool.
  Extract frontmatter fields and body section relevant to that type:
  - **decision:**     id, title, status, date; ## Decision body section text
  - **action:**       id, title, status, owner, due-date
  - **risk:**         id, title, status, likelihood, impact
  - **requirement:**  id, title, status

  Append the extracted record to the appropriate list (`{decisions}`, `{actions}`, `{risks}`, `{requirements}`).

  Collect stakeholder IDs: if `artifact.type == "action"` and `owner` field contains an STK-NNN ID, add to `{stakeholder_ids}` if not already present. Similarly collect STK IDs from `raised-by` fields of any entity type.

**Step 3 — Resolve attendees (D-04)**

For each STK-NNN ID in `{stakeholder_ids}`:
  Read `wiki/stakeholders/{stk_id}.md` using the Read tool.
  Extract `name` and `role` from frontmatter.
  Append `{name} ({role})` to `{attendees_from_stk}`.

Determine `{archive_path}`: `raw/meetings/{item.id}-{item.filename}` (the archived transcript path after sara-update ran).
Also check `raw/input/{item.filename}` as fallback if archive path does not exist.

Read the transcript file using the Read tool. Scan the transcript for attendee names, speaker labels, or participant list sections not already covered by `{attendees_from_stk}`. Add any additional names found to `{attendees_extra}`.

`{attendees}` = merge of `{attendees_from_stk}` and `{attendees_extra}`, deduplicating by name.

If no attendees can be resolved from either source, `{attendees}` = ["(attendees not recorded)"].

**Step 4 — Determine meeting date and source reference**

`{meeting_date}` = check transcript header or filename for a date. If not found, use today's ISO date (YYYY-MM-DD).
`{source_ref}` = `{item.id}` — `{item.filename}`.

**Step 5 — Compose and output plain-text minutes**

Compose plain-text output. Omit any section that has zero entries — do not print a section label with no content.

Use CAPS for section labels. No `#` headings, no `**bold**`, no markdown formatting.

```
MEETING MINUTES — {item.id}
Date: {meeting_date}
Source: {source_ref}

ATTENDEES
{for each attendee: - {name} ({role})}

DECISIONS
{for each decision: - {id} ({title}) — {status}: {decision body text, condensed to 1 sentence}}

ACTIONS
{for each action: - {id} ({title}) — Owner: {owner}, Due: {due-date}, Status: {status}}

RISKS
{for each risk: - {id} ({title}) — {status}, Likelihood: {likelihood}, Impact: {impact}}

REQUIREMENTS
{for each requirement: - {id} ({title}) — Status: {status}}
```

If `{no_entities}` is true, include the ATTENDEES section (from transcript) and add after the date/source lines:
`No wiki entities were recorded for this meeting.`
Still omit empty entity sections.

Output the plain-text block to the terminal.

STOP — do NOT write any file, do NOT run any git command.

</process>

<notes>

- CRITICAL — GUARD ORDER: Type check (`item.type == "meeting"`) MUST run before stage check (`item.stage == "complete"`). A non-meeting item must never reach the extraction_plan traversal. (D-03)
- CRITICAL — NO WRITES: This skill is read-only. Do NOT use the Write tool. Do NOT run git commands. `allowed-tools: [Read]` is intentional and must not be changed.
- `{N}` is the full pipeline item ID (e.g. `MTG-001`). The JSON key in `items` is that same string. For `/sara-minutes MTG-001`, look up `items["MTG-001"]`.
- `item.type` is stored as lowercase `"meeting"` by `/sara-ingest`. Check `item.type == "meeting"`, not `"MTG"`.
- Aggregate BOTH `create` and `update` actions from extraction_plan — both represent what this meeting did to the wiki.
- For `action == "create"` artifacts: use `artifact.assigned_id` as the entity ID. For `action == "update"` artifacts: use `artifact.existing_id`.
- Transcript archive path after `/sara-update` ran: `raw/meetings/{item.id}-{item.filename}`. If that path does not resolve (e.g. item was complete before archive ran), fall back to `raw/input/{item.filename}`.
- Attendee resolution is best-effort. If neither STK pages nor transcript yield attendees, output `(attendees not recorded)` rather than an error.
- PLAIN TEXT ONLY: Output uses CAPS section labels. No `#` headings, no `**bold**`, no markdown formatting.
- Empty sections are silently omitted — never print a section label with no content.
- `schema_version` in wiki frontmatter is always the string `"1.0"` — treat as string, not float.
- `vertical` and `department` are always separate fields in STK pages — never merged.
- `related` fields in wiki pages use plain entity IDs. When displaying in minutes body, render as-is (no wikilinks needed in terminal output).

</notes>
