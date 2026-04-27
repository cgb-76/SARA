---
name: sara-ingest
description: "Register a source file in the SARA ingest pipeline, or show pipeline status"
argument-hint: "[<type> <filename>]  — items are keyed by full ID (e.g. MTG-001)"
allowed-tools:
  - Read
  - Write
  - Bash
version: 1.0.0
---

<objective>
Register a source file from `raw/input/` as a new pipeline item in `pipeline-state.json` with
stage `pending`, or display a table of all current pipeline items when called with no arguments.

INGEST mode (with arguments): validates the type and filename, checks the file exists in
`raw/input/`, increments the appropriate ingest counter, assigns a type-prefixed ID (e.g.
MTG-001), and adds a new item entry keyed by that ID. Outputs a confirmation with the
next-step command to run.

STATUS mode (no arguments): reads `pipeline-state.json` and displays all pipeline items in a
markdown table showing the item ID, type, current stage, and filename.
If no items exist, outputs a plain message.

Run this skill to register each source document before running any other pipeline command.
</objective>

<process>

**Step 1 — Input validation and mode detection**

Examine `$ARGUMENTS`:

- If `$ARGUMENTS` is empty or blank: execute STATUS mode (Step 5), then STOP.
- If `$ARGUMENTS` contains exactly two words separated by whitespace (`<type> <filename>`):
  extract `{type}` (first word) and `{filename}` (second word). Proceed to INGEST mode (Step 2).
- Otherwise (wrong number of words): output the following and STOP:
  ```
  Usage: /sara-ingest <type> <filename>  Valid types: meeting, email, slack, document
  ```

Validate `{type}`: must be exactly one of `meeting`, `email`, `slack`, `document`
(case-sensitive). If not: output the following and STOP:
```
Invalid type '{type}'. Valid types: meeting, email, slack, document
```
This validation is hardcoded — do not read the type list from `.sara/config.json`.

Validate `{filename}`: must not contain `/` or `..` (path traversal guard). If it does:
output the following and STOP:
```
Invalid filename '{filename}'. Filename must not contain path separators or '..'.
```

**Step 2 — File existence check (INGEST mode)**

Run the following Bash command:

```bash
if [ ! -f "raw/input/{filename}" ]; then
  echo "File not found: raw/input/{filename}"
  echo "Files currently in raw/input/:"
  ls raw/input/ 2>/dev/null || echo "(empty)"
  exit 1
fi
```

If the command exits non-zero: STOP. Do NOT read or modify `pipeline-state.json`.

**Step 3 — Read and update pipeline-state.json (INGEST mode)**

Read `.sara/pipeline-state.json` using the Read tool.

Determine `{type_key}` from `{type}`:
- `meeting` → `MTG`
- `email` → `EML`
- `slack` → `SLK`
- `document` → `DOC`

Increment `counters.ingest.{type_key}` by 1. The new value is `{counter_value}`.

Compute `{new_id}` = `{type_key}` + `-` + zero-padded 3-digit counter value.
Example: counter=1 → `MTG-001`, counter=12 → `MTG-012`.

Add a new entry to `items` with key `"{new_id}"`:
```json
{
  "id": "{new_id}",
  "type": "{type}",
  "filename": "{filename}",
  "stage": "pending",
  "created": "{today ISO date YYYY-MM-DD}",
  "discussion_notes": "",
  "extraction_plan": []
}
```

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.
Use only the Read tool and Write tool for this JSON operation — no shell text-processing tools.

**Step 4 — Report success (INGEST mode)**

Output the following (substituting all values):

```
{new_id} registered. Stage: pending.
Type: {type}  |  Filename: {filename}
Run /sara-discuss {new_id} to begin the discussion phase.
```

STOP.

**Step 5 — STATUS mode (no-args branch)**

Read `.sara/pipeline-state.json` using the Read tool.

If `items` is empty (`{}` with no keys): output the following and STOP:
```
No pipeline items registered. Run /sara-ingest <type> <filename> to add one.
```

Otherwise, output a markdown table with a header row and separator row:
```
| ID      | Type     | Stage     | Filename                 |
|---------|----------|-----------|--------------------------|
```

For each key in `items` (sorted lexicographically by key), append one row:
```
| {key} | {item.type} | {item.stage} | {item.filename} |
```

STOP.

</process>

<notes>

- **Item keys are the type-prefixed ID:** Item keys in `pipeline-state.json items` are the
  same as the type-prefixed IDs (`"MTG-001"`, `"EML-001"`, etc.). A project with 2 meetings
  and 1 email has item keys `"MTG-001"`, `"MTG-002"`, `"EML-001"` and `counters.ingest.MTG=2`,
  `counters.ingest.EML=1`. All downstream skills (`/sara-discuss`, `/sara-extract`,
  `/sara-update`) accept the full ID as their argument.

- **Filename validation prevents path traversal:** Always validate `{filename}` for `/` and
  `..` before constructing any file path. This check must run in Step 1, before any file
  operation.

- **Type list is hardcoded:** Do NOT read the valid type list from `.sara/config.json`. The
  four types — `meeting`, `email`, `slack`, `document` — are fixed and must be validated
  against this hardcoded list only.

- **pipeline-state.json read-modify-write is atomic:** Always read the full JSON with the
  Read tool, modify in memory, and write it back with the Write tool in one operation. Never
  use shell text-processing tools for JSON edits — Read + Write only.

- **Missing file hard stop (D-11):** If the file is not found in `raw/input/`, STOP
  immediately after listing the directory contents. Do NOT read or modify
  `pipeline-state.json`. This is the intended behavior — the state file must remain
  unchanged on a failed ingest.

- **STATUS mode shows all items:** The no-args table lists every item regardless of stage.
  Items in `pending`, `extracting`, `approved`, and `complete` stages all appear in the
  table. Sort by integer key ascending.

</notes>
