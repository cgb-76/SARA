---
name: sara-ingest
description: "Register a source file in the SARA ingest pipeline, or show pipeline status"
argument-hint: "[<type> <filename>]  — items are keyed by full ID (e.g. MTG-001)"
allowed-tools:
  - Read
  - Write
  - Bash
version: 2.0.0
---

<objective>
Register a source file from `raw/input/` as a new pipeline item by creating `.sara/pipeline/{ID}/`
directory and writing `state.md`, or display a table of all current pipeline items when called
with no arguments.

INGEST mode (with arguments): validates the type and filename, checks the file exists in
`raw/input/`, derives the next type-prefixed ID from the filesystem (e.g. MTG-001), moves the
source file to its permanent numbered path (e.g. `raw/meetings/MTG-001-transcript.md`), and
commits the new state.md in a single git commit. Outputs a confirmation with the
next-step command to run.

STATUS mode (no arguments): globs `.sara/pipeline/*/state.md` and displays all pipeline items
in a markdown table showing the item ID, type, current stage, and source path.
If no items exist, outputs a plain message.

Run this skill to register each source document before running any other pipeline command.
</objective>

<process>

**Step 1 — Input validation and mode detection**

Examine `$ARGUMENTS`:

- If `$ARGUMENTS` is empty or blank: execute STATUS mode (Step 6), then STOP.
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

If the command exits non-zero: STOP. Do NOT create any pipeline directory or write any file.

**Step 3 — Derive next ID and create item directory (INGEST mode)**

Determine `{type_key}` from `{type}`:
- `meeting` → `MTG`
- `email` → `EML`
- `slack` → `SLK`
- `document` → `DOC`

Determine `{type_dir}` from `{type}`:
- `meeting`  → `raw/meetings/`
- `email`    → `raw/emails/`
- `slack`    → `raw/slack/`
- `document` → `raw/documents/`

Derive the next ID by running:
```bash
LAST=$(ls .sara/pipeline/ 2>/dev/null | grep "^{type_key}-" | sort | tail -1)
if [ -z "$LAST" ]; then
  NEXT="{type_key}-001"
else
  NUM=$(echo "$LAST" | sed 's/{type_key}-//')
  NEXT="{type_key}-$(printf '%03d' $((10#$NUM + 1)))"
fi
echo "$NEXT"
```
Capture the output as `{new_id}`.

Compute `{source_path}` = `{type_dir}` + `{new_id}` + `-` + `{filename}`.
Example: `raw/meetings/MTG-001-transcript-2026-04-27.md`

Create the item directory:
```bash
mkdir -p ".sara/pipeline/{new_id}/"
```

Write `.sara/pipeline/{new_id}/state.md` using the Write tool with the following exact content
(substituting values):
```markdown
---
id: {new_id}
type: {type}
filename: {filename}
source_path: {source_path}
stage: pending
created: {today ISO date YYYY-MM-DD}
---
```

Do NOT use Bash shell text-processing tools to write the markdown file — use the Write tool only.

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
git add "{source_path}" ".sara/pipeline/{new_id}/state.md"
git commit -m "feat(sara): ingest {new_id} — {filename}"
echo "EXIT:$?"
```

If the commit exits non-zero: output the following and STOP:
```
Commit failed for {new_id}. The source file has been moved to {source_path} but the commit
did not succeed. Resolve the git issue and run:
  git add "{source_path}" ".sara/pipeline/{new_id}/state.md"
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

Check if any pipeline items exist:
```bash
ls .sara/pipeline/ 2>/dev/null | grep -v "^\.gitkeep$"
```
If the output is empty: output the following and STOP:
```
No pipeline items registered. Run /sara-ingest <type> <filename> to add one.
```

Extract fields from all state.md files efficiently using a single grep (no per-file Read tool
calls):
```bash
grep -rh "^\(id\|type\|stage\|source_path\):" .sara/pipeline/*/state.md 2>/dev/null
```

Parse the grep output: for each state.md file, the grep returns lines in the order they appear
in the frontmatter. Group lines by file (they appear sequentially). Extract `id:`, `type:`,
`stage:`, `source_path:` values from each group by stripping the key prefix and trimming
whitespace.

Output a markdown table with a header row and separator row:
```
| ID      | Type     | Stage     | Source                              |
|---------|----------|-----------|-------------------------------------|
```

For each item (sorted lexicographically by ID), append one row:
```
| {id} | {type} | {stage} | {source_path} |
```

STOP.

</process>

<notes>

- **Filename validation prevents path traversal:** Always validate `{filename}` for `/` and
  `..` before constructing any file path. This check must run in Step 1, before any file
  operation.

- **Type list is hardcoded:** Do NOT read the valid type list from `.sara/config.json`. The
  four types — `meeting`, `email`, `slack`, `document` — are fixed and must be validated
  against this hardcoded list only.

- **Item directories use mkdir -p:** `sara-ingest` uses `mkdir -p .sara/pipeline/{new_id}/` —
  the `-p` flag creates all parent directories. If `.sara/pipeline/` was not created by
  `sara-init` or was deleted, it is created automatically on first ingest.

- **state.md is written with the Write tool:** No Bash shell text-processing tools are used
  for markdown writes. Read + Write tools only.

- **STATUS mode uses bulk grep:** STATUS mode runs `grep -rh` across all state.md files to
  extract frontmatter fields without reading each file individually with the Read tool. This
  avoids context exhaustion for large pipelines.

- **Counter derivation uses filesystem glob:** No counter file exists. The next ID is derived
  at runtime from the existing item directories. This ensures the counter is always correct
  even if pipeline directories are manually added or removed.

- **Missing file hard stop (D-11):** If the file is not found in `raw/input/`, STOP
  immediately after listing the directory contents. Do NOT create any pipeline directory or
  write any file. This is the intended behavior — the pipeline state must remain unchanged on
  a failed ingest.

- **Source path construction:** `{source_path}` = `{type_dir}` + `{new_id}` + `-` + `{filename}`.
  Type → directory mapping: `meeting→raw/meetings/`, `email→raw/emails/`, `slack→raw/slack/`,
  `document→raw/documents/`. Example: `raw/meetings/MTG-001-transcript-2026-04-27.md`. The
  `source_path` is stored in the state.md frontmatter and is the authoritative file location
  used by all downstream skills.

- **Commit-on-ingest:** The git commit in Step 4 is required. If it fails, output the recovery
  message and STOP — do not output the success confirmation. The state.md has already been
  written and the file moved, so the user can re-run the commit manually using the commands
  shown in the error output.

- **Source file tracking:** Files dropped manually into `raw/input/` are untracked by git.
  Use `git ls-files --error-unmatch` to check before moving. If tracked: use `git mv` (git
  handles both the rename and the stage). If untracked: use `mv` and then include the
  destination path in `git add`.

- **STATUS mode shows all items:** The no-args table lists every item regardless of stage.
  Items in `pending`, `extracting`, `approved`, and `complete` stages all appear in the
  table. Sort lexicographically by ID. Show `source_path` in the Source column.

</notes>
