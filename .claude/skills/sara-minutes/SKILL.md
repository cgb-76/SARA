---
name: sara-minutes
description: "Generate plain-text meeting minutes from a completed meeting item"
argument-hint: "<ID>"
allowed-tools:
  - Read
version: 2.0.0
---

<objective>
Reads pipeline state from `.sara/pipeline/{N}/state.md` and wiki artifacts for a completed meeting item, then outputs structured meeting minutes as plain text. Nothing is written to disk or committed to git.

The minutes are structured around wiki entities actually created or updated for this meeting
item (per wiki/log.md entity IDs committed for this item) — not a generic summary of the transcript.
</objective>

<process>

**Step 1 — Item lookup and guards (type first, then stage)**

Validate `$ARGUMENTS`: must be a non-empty pipeline item ID. If empty:
  Output: `"Usage: /sara-minutes <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Read `.sara/pipeline/{N}/state.md` using the Read tool.

If the file cannot be read (does not exist):
  Output: `"No pipeline item {N} found. Run /sara-ingest with no arguments to see the pipeline status."` and STOP.

Parse the YAML frontmatter from state.md. Extract:
- `id` → store as `{item.id}`
- `type` → store as `{item.type}`
- `filename` → store as `{item.filename}`
- `source_path` → store as `{item.source_path}`
- `stage` → store as `{item.stage}`

**Type guard (type check FIRST — D-02, D-03):**
Check `{item.type}`. Expected value: `"meeting"` (lowercase, as stored by `/sara-ingest`).
If `{item.type}` != `"meeting"`:
  Output: `"{N} is a {item.type} item. /sara-minutes only works on meeting items (MTG-NNN)."` and STOP.

**Stage guard (stage check SECOND — D-01):**
Check `{item.stage}`. Expected value: `"complete"`.
If `{item.stage}` != `"complete"`:
  Output: `"Item {N} is in stage '{item.stage}'. Run /sara-update {N} first to complete the extraction pipeline before generating minutes."` and STOP.

**Step 2 — Discover entity IDs from wiki/log.md**

Read `wiki/log.md` using the Read tool.

Find the log row(s) where the first column contains `[[{N}]]` (e.g. `[[MTG-001]]`). A single ingest item typically produces one log row but may produce multiple if sara-update was run multiple times.

For each matching row, parse the last column to extract entity IDs. The last column contains wikilinks in the format `[[REQ-001]], [[DEC-002]], [[ACT-003]]`. Extract each entity ID (the text inside `[[` and `]]`).

Collect all unique entity IDs from all matching rows into `{entity_ids}` list.

If no matching rows are found (item has no log entries — extraction plan was empty or log.md is missing/empty):
  Set `{no_entities}` = true. Skip to Step 3.

Initialize four lists: `{decisions}`, `{actions}`, `{risks}`, `{requirements}` — all empty.
Also initialize `{stakeholder_ids}` = [] — list of STK IDs encountered.

For each entity ID in `{entity_ids}`:

  Determine `{wiki_path}` from the ID prefix:
  - ID starts with `REQ-` → `wiki/requirements/{entity_id}.md`
  - ID starts with `DEC-` → `wiki/decisions/{entity_id}.md`
  - ID starts with `ACT-` → `wiki/actions/{entity_id}.md`
  - ID starts with `RSK-` → `wiki/risks/{entity_id}.md`
  - ID starts with `STK-` → skip (collect STK IDs separately into `{stakeholder_ids}`)

  Read `{wiki_path}` using the Read tool.
  Extract frontmatter fields and body section relevant to that type:
  - **decision:**     id, title, status, date; ## Decision body section text
  - **action:**       id, title, status, owner, due-date
  - **risk:**         id, title, status, likelihood, impact
  - **requirement:**  id, title, status

  Append the extracted record to the appropriate list (`{decisions}`, `{actions}`, `{risks}`, `{requirements}`).

  Collect stakeholder IDs: if `owner` field contains an STK-NNN ID, add to `{stakeholder_ids}` if not already present. Similarly collect STK IDs from `raised-by` fields.

**Step 3 — Resolve attendees**

For each STK-NNN ID in `{stakeholder_ids}`:
  Read `wiki/stakeholders/{stk_id}.md` using the Read tool.
  Extract `name` and `role` from frontmatter.
  Append `{name} ({role})` to `{attendees_from_stk}`.

Read `{item.source_path}` using the Read tool. Scan the transcript for attendee names, speaker labels, or participant list sections not already covered by `{attendees_from_stk}`. Add any additional names found to `{attendees_extra}`.

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

- CRITICAL — GUARD ORDER: Type check (`item.type == "meeting"`) MUST run before stage check (`item.stage == "complete"`). A non-meeting item must never reach the log.md traversal. (D-03)
- CRITICAL — NO WRITES: This skill is read-only. Do NOT use the Write tool. Do NOT run git commands. `allowed-tools: [Read]` is intentional and must not be changed.
- Entity IDs are discovered from `wiki/log.md` — not from `plan.md`. plan.md contains placeholder IDs (REQ-NNN) at write time; by the time /sara-minutes runs (stage=complete), the actual committed IDs are in wiki/log.md (Pitfall 7).
- Guard order is TYPE then STAGE: type guard runs first (item.type == 'meeting'), stage guard runs second (item.stage == 'complete'). A non-meeting item must never reach the log.md traversal.
- `{N}` is the full pipeline item ID (e.g. `MTG-001`). The state.md file is at `.sara/pipeline/{N}/state.md`.
- `item.type` is stored as lowercase `"meeting"` by `/sara-ingest`. Check `item.type == "meeting"`, not `"MTG"`.
- A single ingest item typically produces one log row in wiki/log.md but may produce multiple if sara-update was run multiple times. Collect all unique entity IDs from all matching rows.
- Transcript path: use `{item.source_path}` from state.md frontmatter. The source file was moved to this permanent path by `/sara-ingest` — it is never in `raw/input/` for items processed after that change.
- Attendee resolution is best-effort. If neither STK pages nor transcript yield attendees, output `(attendees not recorded)` rather than an error.
- PLAIN TEXT ONLY: Output uses CAPS section labels. No `#` headings, no `**bold**`, no markdown formatting.
- Empty sections are silently omitted — never print a section label with no content.
- `schema_version` in wiki frontmatter is always the string `"1.0"` — treat as string, not float.
- `vertical` and `department` are always separate fields in STK pages — never merged.
- `related` fields in wiki pages use plain entity IDs. When displaying in minutes body, render as-is (no wikilinks needed in terminal output).

</notes>
