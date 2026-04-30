---
name: sara-lint
description: "Scan wiki artifact pages for schema gaps against v2.0 schemas and fix them"
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 2.0.0
---

<objective>
sara-lint v2.0 scans all wiki artifact pages across six checks: (1) missing v2.0 frontmatter fields, (2) broken related[] IDs, (3) orphaned wiki pages, (4) index↔disk bidirectional sync, (5) Cross Links↔related[] divergence, (6) missing/empty related[] curation. Every finding is presented individually for approval. Every accepted fix is committed atomically.
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

**Step 2 — Load config**

Read `.sara/config.json` using the Read tool. Store `config.segments` as `{config_segments}` (a list of segment strings). If the file is absent or the field is missing, set `{config_segments}` to [].

**Step 3 — Run all six checks and collect findings**

Execute all grep scans and file checks upfront. Collect ALL findings from all six checks into a single `{all_findings}` list before presenting any to the user. Each finding in the list has: check_id (D-02 through D-07), file, field_or_id (where applicable), issue description, proposed_fix description.

---

**Check D-02 — Missing v2.0 frontmatter fields**

Run one grep per field per applicable entity directory using the `-rL` flag to find files MISSING the pattern. After each grep, pipe through `grep "\.md$" | grep -v "\.gitkeep"`. Collect all results as missing-field findings.

Field/directory matrix:

- `^schema_version:` — wiki/requirements/, wiki/decisions/, wiki/actions/, wiki/risks/, wiki/stakeholders/
- `^type:` — wiki/requirements/, wiki/decisions/, wiki/actions/, wiki/risks/
- `^priority:` — wiki/requirements/
- `^due-date:` — wiki/actions/
- `^owner:` — wiki/actions/, wiki/risks/
- `^likelihood:` — wiki/risks/
- `^impact:` — wiki/risks/
- `^segment:` — wiki/stakeholders/ (singular — renamed from vertical)
- `^segments:` — wiki/requirements/, wiki/decisions/, wiki/actions/, wiki/risks/

Example grep invocations:

```bash
# schema_version missing — all five artifact dirs
grep -rL "^schema_version:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# type missing — four artifact dirs (not STK)
grep -rL "^type:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# priority missing — requirements only
grep -rL "^priority:" wiki/requirements/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# due-date missing — actions only
grep -rL "^due-date:" wiki/actions/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# owner missing — actions and risks
grep -rL "^owner:" wiki/actions/ wiki/risks/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# likelihood missing — risks only
grep -rL "^likelihood:" wiki/risks/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# impact missing — risks only
grep -rL "^impact:" wiki/risks/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# segment missing — stakeholders only (singular)
grep -rL "^segment:" wiki/stakeholders/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"

# segments missing — four artifact dirs (not STK)
grep -rL "^segments:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"
```

For each missing-field finding: issue = "{field} field missing from {file}". proposed_fix = "Read page, infer value, insert {field} into frontmatter, commit."

---

**Check D-03 — Broken related[] IDs**

Run:

```bash
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null | grep -v "related: \[\]" | grep "\.md:" | grep -v "\.gitkeep"
```

For each file with a non-empty related: list: Read the file using the Read tool, parse the YAML list. For each ID in the list, run:

```bash
ls wiki/requirements/{ID}.md wiki/decisions/{ID}.md wiki/actions/{ID}.md wiki/risks/{ID}.md wiki/stakeholders/{ID}.md 2>/dev/null | wc -l
```

If output is 0: add a finding. issue = "related[] contains broken ID {broken_id} in {file}". proposed_fix = "Remove {broken_id} from related: list."

---

**Check D-04 — Orphaned pages**

Run:

```bash
find wiki/requirements wiki/decisions wiki/actions wiki/risks wiki/stakeholders -name "*.md" ! -name ".gitkeep" 2>/dev/null
```

Store the result as `{disk_files}`.

Read wiki/index.md using the Read tool. Store the full content as `{index_content}`. For each disk file, Read the file using the Read tool to extract its ID from the frontmatter `id:` field. Check if the ID string appears anywhere in `{index_content}`. If not found: add a finding. issue = "{ID} ({file}) is not listed in wiki/index.md". proposed_fix = "Add index row for {ID} to wiki/index.md."

---

**Check D-05 — Index↔disk sync**

Using the same `{disk_files}` list from D-04 and the same `{index_content}` already read:

Extract all entity IDs referenced in wiki/index.md rows. For each index ID that has no corresponding file in `{disk_files}`: add a finding. issue = "wiki/index.md references {ID} but no file found on disk". proposed_fix = "Remove stale row for {ID} from wiki/index.md."

Note: Do NOT re-add orphaned-page findings already captured in D-04 as separate D-05 findings — they overlap. D-04 handles "missing from index" (add row); D-05 handles "in index but no disk file" (remove stale row).

---

**Check D-06 — Cross Links↔related[] sync**

**Pass 1 — Non-empty related[], check for divergence (existing behaviour):**

Run:

```bash
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep -v "related: \[\]" | grep "\.md:" | grep -v "\.gitkeep"
```

For each file with a non-empty related: field: Read the file using the Read tool. Compare IDs in the `related:` frontmatter list against the IDs linked under the `## Cross Links` body section. If they differ (any ID present in one but not the other, or the section is absent): add a finding.
- issue: "Cross Links section in {file} diverges from related[] frontmatter"
- proposed_fix: "Regenerate ## Cross Links section from related: list."

**Pass 2 — Empty related[] (`related: []`), check for absent Cross Links header:**

Run:

```bash
grep -rn "^related: \[\]" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep "\.md:" | grep -v "\.gitkeep"
```

For each file returned: Read the file using the Read tool. Check whether a `## Cross Links` section header exists anywhere in the file body. If absent: add a finding.
- check_id: D-06
- issue: "`## Cross Links` section absent from {file} (related: [] but section header missing)"
- proposed_fix: "Add empty `## Cross Links` section header at end of file body."

---

**Check D-07 — Semantic related[] curation**

Find all wiki artifact pages where `related:` is absent from frontmatter. Pages with `related: []` (explicitly empty list) are treated as already curated and are NOT flagged.

Rationale: `related: []` written by sara-update is the default empty value from extraction. After LLM curation via D-07, pages where LLM confirmed no relationships retain `related: []` and must not be re-flagged. Only pages that have never been through curation (absent field) need this check. (Implementation choice (a) from CONTEXT.md Claude's Discretion: treat `related: []` as curated.)

Run:

```bash
grep -rL "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep "\.md$" | grep -v "\.gitkeep"
```

For each file returned (absent `related:` field): Read the file using the Read tool.

Determine if this is a wiki artifact page (has a valid `id:` frontmatter field matching `REQ-\d{3}`, `DEC-\d{3}`, `ACT-\d{3}`, or `RSK-\d{3}`). If not, skip.

Add a finding per qualifying file:
- check_id: D-07
- file: {path}
- issue: "related[] absent from {ID} ({file}) — not yet curated"
- proposed_fix: "LLM reads this page and all other wiki artifact pages (or their summaries for large wikis) to infer semantic relationships. Proposes a related: list (may be empty if no relationships found). Writes related: field to frontmatter. Regenerates ## Cross Links section."

---

**Step 4 — Present finding count**

If {all_findings} is empty: output a clean summary:

```
/sara-lint complete — no issues found across all 6 checks.
```

STOP.

If {all_findings} is non-empty: output:

```
/sara-lint found {N} issue(s) across {M} check(s). Presenting each for approval.
```

---

**Step 5 — Per-finding approval and fix loop**

Initialise `{fix_number}` = 1. Set `{total}` = total number of findings.

For each finding in {all_findings} in order:

  **If finding.check_id == D-07:** Run inference BEFORE presenting to the user — the user must see specific proposed IDs, not the generic placeholder from Step 3.

    1. Re-read the target file using the Read tool.

    2. Collect all other wiki artifact pages for context:
       Run:
       ```bash
       find wiki/requirements wiki/decisions wiki/actions wiki/risks -name "*.md" ! -name ".gitkeep" 2>/dev/null
       ```
       For each file path returned (excluding the target file itself):
       - If the wiki has 20 or fewer artifact pages total: Read the full file using the Read tool.
       - If the wiki has more than 20 artifact pages total: Read the full file using the Read tool, but when reasoning about relationships use only the `id`, `title`, and `summary` frontmatter fields as context — do not consider body section content for non-target pages. This limits reasoning scope to stay within the effective context window for large wikis.

    3. LLM inference pass:
       Reason semantically about which other artifact pages are related to the target artifact.
       Relationship criteria:
       - Shared topic: both artifacts concern the same subject matter
       - Addressal: one artifact addresses or responds to the other (e.g. an action mitigates a risk)
       - Consequence: one artifact is a consequence or result of the other
       Example: RSK-001 and ACT-003 are related if the action sets up a workshop to address the risk — not merely because they were extracted from the same meeting.

    4. Produce the concrete proposed_related list (may be `[]` if no semantic relationships found).
       Update finding.proposed_fix to include the specific IDs:
       "Proposed: related: [ACT-003, RSK-001]" or "Proposed: related: [] (no relationships found)"

  Present using AskUserQuestion:
  - header: "Lint finding [{fix_number} of {total}]"
  - question: "{issue description}\n\nProposed fix: {proposed_fix}\n\nApply this fix?"
  - options: ["Apply", "Skip"]

  If "Skip": output "Skipped." Increment {fix_number}. Continue to next finding.

  If "Apply":

    Re-read the target file immediately using the Read tool (always re-read before writing — another fix in the same loop may have modified it).

    Apply the fix in memory based on check_id:

    **D-02 — Missing frontmatter field:**
    Infer the value using the back-fill inference rules below. Insert the field into the YAML frontmatter in the correct position using the field insertion rules below. Use the Write tool to write the full file back.

    **D-03 — Broken related[] ID:**
    Remove the broken ID from the `related:` YAML list. If the list becomes empty, write `related: []`. Use the Write tool to write the full file back.

    **D-04 — Orphaned page:**
    Re-read wiki/index.md using the Read tool. Synthesise a new row for the entity:
    - ID: from frontmatter `id:` field
    - Title: from frontmatter `title:` field
    - Status: from frontmatter `status:` field
    - Type: inferred from directory path (requirements → REQ, decisions → DEC, actions → ACT, risks → RSK, stakeholders → STK)
    - Tags: from frontmatter `tags:` field (join as comma-separated if array)
    - Last-updated: today's date (2026-04-30)
    Append the row to the appropriate section of wiki/index.md. Use the Write tool to write wiki/index.md back.
    Set commit target to wiki/index.md.

    **D-05 — Stale index row:**
    Re-read wiki/index.md using the Read tool. Remove the stale row for the orphan ID. Use the Write tool to write wiki/index.md back.
    Set commit target to wiki/index.md.

    **D-06 — Cross Links mismatch (Pass 1 — non-empty related[]):**
    Regenerate the `## Cross Links` body section from the `related:` frontmatter list. For each related ID, look up the page title by reading the corresponding wiki file. Format each link as `[[{ID}|{Title}]]` — one per line. If the `## Cross Links` section exists, replace it. If absent, append it at the end of the file body. Use the Write tool to write the full file back.

    **D-06 — Absent Cross Links header (Pass 2 — empty related[]):**
    The page has `related: []` but is missing the `## Cross Links` section header entirely. Append `\n## Cross Links\n` at the very end of the file body. No link content — heading only. Use the Write tool to write the full file back. This signals the check has run (consistent with the empty-section pattern used across all artifact types when related is empty).

    **D-07 — Semantic related[] curation:**
       a. Write `related: [ID1, ID2, ...]` (or `related: []`) to the frontmatter `related:` field using the proposed_related list already inferred above.
       b. If related is non-empty: regenerate the `## Cross Links` section with wikilinks.
          For each ID in related: look up the page title by reading the corresponding wiki file.
          Format each link as `[[{ID}|{Title}]]` — one per line.
          If the `## Cross Links` section exists, replace it. If absent, append it at the end of the file body.
       c. If related is []: write an empty `## Cross Links` heading only (heading-only, no content beneath it) — same empty-section pattern as all other artifact types when related is empty. If the section exists with stale content, replace it with the heading-only form. If absent, append `\n## Cross Links\n`.
       d. Use the Write tool to write the full file back.

    After Write succeeds, commit immediately:

    ```bash
    git add {exact_file_path}
    git commit -m "{commit_message}"
    echo "EXIT:$?"
    ```

    Where {commit_message} is:
    - D-02 missing field: `fix(wiki): back-fill {field} on {ID} via sara-lint`
    - D-03 broken ID: `fix(wiki): remove broken related ID {broken_id} from {ID} via sara-lint`
    - D-04 orphaned: `fix(wiki): add {ID} to wiki/index.md via sara-lint`
    - D-05 stale row: `fix(wiki): correct index row for {ID} via sara-lint`
    - D-06 cross links (Pass 1): `fix(wiki): regenerate Cross Links on {ID} via sara-lint`
    - D-06 absent header (Pass 2): `fix(wiki): add empty Cross Links header to {ID} via sara-lint`
    - D-07 curation: `fix(wiki): curate related[] on {ID} via sara-lint D-07`

    Check the exit code from "EXIT:$?".

    If exit code 0: run `git log --oneline -1` to get {commit_hash}. Output: "Fixed. Commit: {commit_hash}"

    If exit code != 0: output "Fix written but commit failed — resolve git issue and commit manually." Continue to next finding.

    Increment {fix_number}. Continue to next finding.

---

**Back-fill inference rules (implement exactly — these are not vague):**

- `schema_version`: insert `schema_version: '2.0'` (quoted string). No inference needed.

- `type` for REQ: read `## Statement` and `## Acceptance Criteria` sections; classify as:
  - functional — user-facing behaviour
  - non-functional — quality attribute (performance, reliability, security)
  - regulatory — legal/compliance requirement
  - integration — system-to-system interface
  - business-rule — domain constraint
  - data — data structure or format requirement

- `type` for DEC: read `## Decision` section; classify as:
  - architectural — technology choice or structural decision
  - process — workflow or methodology decision
  - tooling — tool or library selection
  - data — data model or storage decision
  - business-rule — domain rule encoded in the system
  - organisational — team structure or responsibility decision

- `type` for ACT: read `## Description` section; classify as:
  - deliverable — produces an artifact or tangible output
  - follow-up — requires a conversation, review, or approval

- `type` for RSK: read `## Risk IF/THEN` section; classify as:
  - technical — relates to technology stack or implementation
  - financial — relates to budget or cost
  - schedule — relates to timeline or milestones
  - quality — relates to defects, accuracy, or reliability
  - compliance — relates to regulatory or legal requirements
  - people — relates to staffing, skills, or availability

- `priority` for REQ: read `## Statement` section; classify as:
  - must-have — must/shall language
  - should-have — should language
  - could-have — could/may language
  - wont-have — explicitly deferred or out of scope

- `segments`: read {config_segments} (already loaded in Step 2). Check the `related:` frontmatter for STK IDs; for each STK ID found, attempt to Read the STK page and get its `segment:` field. Also scan the page body for keyword matches against {config_segments}. If matches found, propose the matching segment(s) as a YAML list. If no match, propose `[]`.

- `likelihood` / `impact`: scan `## Risk IF/THEN` and `## Mitigation` body sections for the words high, medium, low. If found, use the matching level. If not found, propose `""`.

- `due-date`: scan `## Due Date` body section and `## Description` for date patterns (YYYY-MM-DD or natural language). If found, extract. If not found, propose `""`.

- `owner`: scan `## Owner` body section and `related:` frontmatter for STK IDs. If an STK ID is found and the STK page has a `name:` field, use that name. If not resolved, propose `""`.

- `segment` for STK: scan `## Description` or page body for a segment keyword matching {config_segments}. If found, use it. If not, propose `""`.

---

**Field insertion rules (frontmatter position):**

Insert each field in a consistent location within the YAML frontmatter block (between `---` markers). Use these rules:

- `schema_version`: after `tags:` field (or before the closing `---` if tags absent)
- `type`: after `status:` field
- `priority`: after `type:` field (REQ only)
- `owner`: after `status:` field (ACT and RSK)
- `due-date`: after `owner:` field (ACT)
- `likelihood`: after `type:` field (RSK)
- `impact`: after `likelihood:` field (RSK)
- `segment`: after `role:` field (STK)
- `segments`: after `tags:` field (REQ, DEC, ACT, RSK)

</process>

<notes>
- Wiki artifact files are read and written using Read and Write tools only — never Bash text-processing (sed, awk, jq) on markdown files
- Bash is only used for: grep (read-only scan), find (read-only scan), ls (existence check), git commands
- Always re-read a file immediately before writing it (another fix in the same loop may have changed it)
- One commit per accepted fix — never batch multiple fixes into one commit
- If a commit fails (exit code != 0): write the warning and continue; do not STOP the lint run
- Check D-04 and D-05 share the same disk file list and wiki/index.md read — avoid reading the same file twice; load once and reuse
- The `segments:` (plural) field is NOT added to STK pages — only REQ, DEC, ACT, RSK get it; STK pages get the singular `segment:` field
- For the D-03 grep output: the format is `filepath:N:content` (colon-separated), so extract the file path as the part before the first colon
- For the D-06 grep output: same colon-separated format — extract file path from before the first colon
- When checking for duplicate findings between D-04 and D-05: if a page appears as orphaned in D-04 (not in index), do not also raise it as a missing-row finding in D-05; D-04 already covers adding it
- T-13-04 mitigation: commit only stages explicit file paths (never directory globs); commit messages are templated strings — no user-supplied strings are interpolated directly into the commit command
</notes>
