---
name: sara-lint
description: "Scan wiki artifact pages for schema issues and fix them — v1: back-fill missing summary fields"
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---

<objective>
sara-lint scans all wiki artifact pages, identifies those missing a `summary` field, generates summaries for them using type-specific content rules, writes them back, and commits. v1 implements Check 1 (missing summaries) only. Future checks (orphaned pages, broken cross-refs) are stubbed.
</objective>

<process>

**Step 1 — Wiki existence guard**

Run the following Bash command. If it exits non-zero (wiki/ does not exist), output a clear message and STOP:

```bash
if [ ! -d "wiki" ]; then
  echo "No wiki found. Run /sara-init first."
  exit 1
fi
```

If the directory exists, continue.

**Step 2 — Load summary_max_words config**

Read `.sara/pipeline-state.json` using the Read tool.

Extract `summary_max_words`. If the field is absent from the JSON, use 50 as the default.

Store as `{summary_max_words}`.

**Check 1 — Missing summaries (v1 — implemented)**

Run the following Bash command to find artifact pages that lack a `summary:` field:

```bash
grep -rL "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"
```

`-L` returns filenames that do NOT contain the pattern — these are the pages to back-fill.

Store the result as `{missing_files}` (a list of file paths).

If `{missing_files}` is empty:
  Output: "Check 1 — Missing summaries: all {total} artifact pages have a summary field. Nothing to do."
  Proceed to Check 2 (stub — output "Check 2 — Orphaned pages: skipped (v2)") and Check 3 (stub) and STOP with success message.

If `{missing_files}` is non-empty:

  Count: `{missing_count}` = number of files in the list.

  Preview: Read the first file in `{missing_files}` using the Read tool. Generate a sample summary for it using the type-specific content rules (determine type from the directory path — `wiki/requirements/` → REQ, `wiki/decisions/` → DEC, `wiki/actions/` → ACT, `wiki/risks/` → RISK, `wiki/stakeholders/` → STK). The preview summary must be within `{summary_max_words}` words.

  Present the dry-run summary to the user as plain text:
  ```
  Check 1 — Missing summaries

  {missing_count} artifact pages are missing a summary field.

  Preview (first artifact):
  File: {first_file}
  Generated summary: "{preview_summary}"

  The full back-fill will:
    - Read each of the {missing_count} files
    - Generate a type-specific summary within {summary_max_words} words
    - Write the summary field into the frontmatter of each file
    - Commit all changes with message: fix(wiki): back-fill artifact summaries via sara-lint
  ```

  Then ask the user to confirm:
  ```
  header: "Confirm lint"
  question: "Back-fill summaries for {missing_count} artifact pages?"
  options: ["Proceed", "Cancel"]
  ```

  If user selects "Cancel":
    Output: "Back-fill cancelled. No files written."
    STOP.

  If user selects "Proceed":
    Initialize `written_files = []`.

    For each file in `{missing_files}`:
      Read the file using the Read tool.
      Determine type from the directory path.
      Generate a `summary` value as a single prose string within `{summary_max_words}` words, using the type-specific content rules:
        - REQ: title, status, one-line description of what is required
        - DEC: options considered, chosen option/recommendation, status, decision date
        - ACT: owner, due-date, status (open/in-progress/done/cancelled)
        - RISK: likelihood, impact, mitigation approach, status
        - STK: vertical, department, role — enough to distinguish from other stakeholders
      Insert `summary: "{generated_summary}"` into the frontmatter of the file, immediately after the `related:` field.
      Write the file back using the Write tool.
      If write succeeds: append the file path to `written_files`.
      Do NOT use Bash text-processing tools (jq, sed, awk) — Read and Write tools only.

    After all files are written, stage only the files that were actually written (not entire directories) and commit:
    ```bash
    git add {written_files...}   # pass each file path explicitly — never stage by directory glob
    git commit -m "fix(wiki): back-fill artifact summaries via sara-lint"
    echo "EXIT:$?"
    ```

    Check the exit code from "EXIT:$?".

    If exit code 0:
      Run `git log --oneline -1` to capture `{commit_hash}`.
      Output:
      ```
      Check 1 complete.

      Back-filled: {missing_count} artifacts
      Commit: {commit_hash}
      ```
      Proceed to Check 2 (stub) and Check 3 (stub).

    If exit code != 0:
      Output:
      ```
      Check 1 — Commit failed. Files written ({missing_count}) but not committed.
      Stage not changed. Re-run /sara-lint after resolving the git issue.
      ```
      STOP.

**Check 2 — Orphaned pages (v2 — stub, not implemented)**

Output: "Check 2 — Orphaned pages: not implemented in v1. Add check here in a future phase."

<!-- Future: scan wiki pages not referenced in wiki/index.md -->

**Check 3 — Broken cross-references (v2 — stub, not implemented)**

Output: "Check 3 — Broken cross-references: not implemented in v1. Add check here in a future phase."

<!-- Future: verify all IDs in `related:` fields resolve to existing pages in the wiki -->

**Success report**

Output:
```
/sara-lint complete.

Check 1 — Missing summaries: {result}
Check 2 — Orphaned pages:     skipped (v2)
Check 3 — Broken cross-refs:  skipped (v2)
```

</process>

<notes>
- pipeline-state.json is read using the Read tool only — never jq/sed/awk
- Wiki artifact files are read and written using Read and Write tools only — never Bash text-processing tools
- The `summary` field is inserted after `related:` in frontmatter — consistent position across all entity types
- If any file write fails mid-loop: output a partial failure report listing written and unwritten files; the git commit has NOT been issued; re-run /sara-lint to retry (it will skip already-summarised files because the grep -rL scan only returns files still missing summary)
- Commit happens only after ALL files in {missing_files} are successfully written
- summary_max_words defaults to 50 if absent from pipeline-state.json (D-07)
</notes>
