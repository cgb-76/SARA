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
MTG-001), moves the source file to its permanent numbered path (e.g.
`raw/meetings/MTG-001-transcript.md`), and commits both the moved file and updated state in a
single git commit. Outputs a confirmation with the next-step command to run.

STATUS mode (no arguments): reads `pipeline-state.json` and displays all pipeline items in a
markdown table showing the item ID, type, current stage, and source path.
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

Determine `{type_dir}` from `{type}`:
- `meeting`  → `raw/meetings/`
- `email`    → `raw/emails/`
- `slack`    → `raw/slack/`
- `document` → `raw/documents/`

Compute `{source_path}` = `{type_dir}` + `{new_id}` + `-` + `{filename}`.
Example: `raw/meetings/MTG-001-transcript-2026-04-27.md`

Add a new entry to `items` with key `"{new_id}"`:
```json
{
  "id": "{new_id}",
  "type": "{type}",
  "filename": "{filename}",
  "source_path": "{source_path}",
  "stage": "pending",
  "created": "{today ISO date YYYY-MM-DD}",
  "discussion_notes": "",
  "extraction_plan": []
}
```

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.
Use only the Read tool and Write tool for this JSON operation — no shell text-processing tools.

**Step 4 — Move source file and commit (INGEST mode)**

Check whether the source file is git-tracked:
```bash
git ls-files --error-unmatch "raw/input/{filename}" 2>/dev/null && echo "tracked" || echo "untracked"
```

Ensure the destination directory exists:
```bash
mkdir -p "{type_dir}"
```

If tracked: run `git mv "raw/input/{filename}" "{source_path}"`
If untracked: run `mv "raw/input/{filename}" "{source_path}"`

Stage and commit:
```bash
git add "{source_path}" .sara/pipeline-state.json
git commit -m "feat(sara): ingest {new_id} — {filename}"
echo "EXIT:$?"
```

If the commit exits non-zero: output the following and STOP:
```
Commit failed for {new_id}. The source file has been moved to {source_path} but the commit
did not succeed. Resolve the git issue and run:
  git add "{source_path}" .sara/pipeline-state.json
  git commit -m "feat(sara): ingest {new_id} — {filename}"
```

Capture `{commit_hash}` by running: `git log --oneline -1`

**Step 5 — Report success (INGEST mode)**

Output the following (substituting all values):

```
{new_id} registered. Stage: pending.
Type: {type}  |  Source: {source_path}
Commit: {commit_hash}
Run /sara-discuss {new_id} to begin the discussion phase.
```

STOP.

**Step 6 — STATUS mode (no-args branch)**

Read `.sara/pipeline-state.json` using the Read tool.

If `items` is empty (`{}` with no keys): output the following and STOP:
```
No pipeline items registered. Run /sara-ingest <type> <filename> to add one.
```

Otherwise, output a markdown table with a header row and separator row:
```
| ID      | Type     | Stage     | Source                              |
|---------|----------|-----------|-------------------------------------|
```

For each key in `items` (sorted lexicographically by key), append one row.
Use `{item.source_path}` as the source value; fall back to `raw/input/{item.filename}` for legacy
items that pre-date this change and have no `source_path` field:
```
| {key} | {item.type} | {item.stage} | {item.source_path or fallback} |
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

- **Source path construction:** `{source_path}` = `{type_dir}` + `{new_id}` + `-` + `{filename}`.
  Type → directory mapping: `meeting→raw/meetings/`, `email→raw/emails/`, `slack→raw/slack/`,
  `document→raw/documents/`. The `source_path` is stored in the pipeline item and is the
  authoritative file location used by all downstream skills.

- **Commit-on-ingest:** The git commit in Step 4 is required. If it fails, output the recovery
  message and STOP — do not output the success confirmation. The state file has already been
  written and the file moved, so the user can re-run the commit manually using the commands
  shown in the error output.

- **Source file tracking:** Files dropped manually into `raw/input/` are untracked by git.
  Use `git ls-files --error-unmatch` to check before moving. If tracked: use `git mv` (git
  handles both the rename and the stage). If untracked: use `mv` and then include the
  destination path in `git add`.

- **STATUS mode shows all items:** The no-args table lists every item regardless of stage.
  Items in `pending`, `extracting`, `approved`, and `complete` stages all appear in the
  table. Sort lexicographically by key. Show `source_path` in the Source column; fall back
  to `raw/input/{item.filename}` for legacy items missing the `source_path` field.

</notes>
