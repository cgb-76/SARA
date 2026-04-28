---
name: sara-update
description: "Execute approved extraction plan — write wiki artifacts and commit atomically"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
version: 1.0.0
---

<objective>
Reads the approved extraction plan from `pipeline-state.json` and writes all wiki artifacts (create or update) plus `wiki/index.md` and `wiki/log.md` in a single atomic git commit. The source file is archived to the type-specific `/raw/` subdirectory in the same commit; stage advances to `complete` only after the commit succeeds.
</objective>

<process>

**Step 1 — Stage guard and item lookup**

Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: it must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
  Output: `"Usage: /sara-update <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Find the item with key `"{N}"` in the `items` object (N is the full ID argument — for `/sara-update MTG-001`, N = `"MTG-001"`).

If no item exists with key `"{N}"`:
  Output: `"No pipeline item {N} found. Run /sara-ingest to register a new item, or run /sara-ingest with no arguments to see the full pipeline status."`
  STOP.

Check `items["{N}"].stage`. Expected stage: `"approved"`.

If actual stage != `"approved"`:
  Output: `"Item {N} is in stage '{actual_stage}'. Run /sara-update <ID> only when stage is 'approved'. Re-run /sara-extract {N} if you need to revise the plan."`
  STOP.

Store `{item}` = `items["{N}"]`.
Store `{extraction_plan}` = `items["{N}"].extraction_plan`.

If `{extraction_plan}` is empty or null:
  Output: `"Extraction plan for item {N} is empty. Re-run /sara-extract {N} to generate an approved plan."` and STOP.

**Step 1b — Load source document and discussion notes**

Read `raw/input/{item.filename}` using the Read tool. Store as `{source_doc}`.

`{discussion_notes}` = `items["{N}"].discussion_notes` (already in memory from Step 1).

These are used in Step 2 to synthesise body section content for each created artifact.

**Step 2 — Write wiki artifact files**

Initialize `written_files = []` and `failed_files = []`.

For each artifact in `{extraction_plan}`:

  Determine `{wiki_dir}` from `artifact.type`:
  - `requirement` → `wiki/requirements/`
  - `decision`    → `wiki/decisions/`
  - `action`      → `wiki/actions/`
  - `risk`        → `wiki/risks/`

  **If `artifact.action == "create"`:**

    Determine `{entity_type_key}` from `artifact.type`:
    - `requirement` → `REQ`
    - `decision`    → `DEC`
    - `action`      → `ACT`
    - `risk`        → `RISK`

    Re-read `.sara/pipeline-state.json` using the Read tool (re-read to get current counter values — a previous artifact in this loop may have incremented the counter already).

    Increment `counters.entity.{entity_type_key}` by 1.

    Write the updated `pipeline-state.json` immediately using the Write tool (the counter increment MUST be persisted before the page is written — this prevents duplicate ID assignment if a page write fails and the skill is re-run).

    Compute `{assigned_id}` = `"{entity_type_key}-"` + zero-padded 3-digit counter (e.g. counter = 1 → `"REQ-001"`).

    Read `.sara/templates/{artifact.type}.md` using the Read tool to get the template structure.

    Construct the wiki page content by substituting all fields from the artifact into the template frontmatter and body:
    - `id` = `{assigned_id}`
    - `title` = `artifact.title`
    - `description` = `artifact.title` (frontmatter one-liner — the source quote is preserved in the body callout instead)
    - `source` = `{item.id}` (e.g. `MTG-001`)
    - `raised-by` = `artifact.raised_by` (note: template field is `raised-by`; artifact schema field is `raised_by`)
    - `related` = `artifact.related` (array of entity IDs)
    - `schema_version` = `"1.0"` (always quoted)
    - For decision artifacts: set `status` = the initial decision status (see template — the first valid status value), `date` = today's ISO date
    - For requirement artifacts: set `status` = `"open"`
    - For action artifacts: set `status` = `"open"`, `owner` = `artifact.raised_by`
    - For risk artifacts: set `status` = `"open"`, `owner` = `artifact.raised_by`
    - All other fields not supplied by the artifact: use the template default value (empty string `""` or empty array `[]`)

    Populate the body sections below the frontmatter. For each section listed below, synthesise
    a concise summary (2–4 sentences) using the artifact's title, `source_quote`, `discussion_notes`,
    and the surrounding context in `{source_doc}`. Ground the primary section with the source quote
    in a markdown callout immediately after the synthesised paragraph. Leave secondary sections
    (Acceptance Criteria, Notes, Rationale, Alternatives Considered, Mitigation) empty — they will
    be filled in manually or by future pipeline runs.

    Before writing the page, resolve the stakeholder name for the attribution line:
    - If `artifact.raised_by` is a valid STK ID (e.g. `STK-001`): read
      `wiki/stakeholders/{artifact.raised_by}.md` and extract the `name` field from frontmatter.
      Use that as `{stakeholder_name}`.
    - If `artifact.raised_by` is empty or the file cannot be read: use `{artifact.raised_by}`
      as the fallback attribution (the ID itself).

    Quote format (standard markdown blockquote, stakeholder linked to their wiki page):
    ```
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]
    ```

    **Wikilink rule:** Never write a bare entity ID in body prose. When referencing any entity
    in body text, always use the `[[ID|display text]]` form:
    - STK entities: display text = name only (e.g. `[[STK-001|Rajiwath Patel]]`).
      Read `wiki/stakeholders/{ID}.md` to resolve the name.
    - REQ / DEC / ACT / RISK entities: display text = `{ID} {title}` (e.g.
      `[[DEC-007|DEC-007 Defer SSO to Phase 3]]`). Read the wiki page or look up `wiki/index.md`.
    - Ingest IDs (MTG, EML, SLK, DOC): display text = `{ID} {title}` (e.g.
      `[[MTG-001|MTG-001 ACME Platform Integration Review]]`). Use the source document title.
    - Frontmatter fields (`raised-by`, `related`, `source`, `owner`) remain plain IDs — this rule
      applies to body text only.
    - `wiki/index.md` and `wiki/log.md` table rows use bare `[[ID]]` — they are structured tables,
      not prose.
    - If a title or name cannot be resolved (page missing), fall back to the bare `[[ID]]`.

    **Prose-first rule:** Write synthesised body sections as natural language. Entity references
    should support the prose, not replace names or become grammatical subjects. Prefer:
    "Rajiwath Patel asked Sarah Chen to update the auth token spec
    ([[ACT-002|ACT-002 Update auth token specification]])."
    Over: "[[STK-001|Rajiwath Patel]] told [[STK-009|Sarah Chen]] to focus on
    [[ACT-002|ACT-002 Update auth token specification]]."

    For every section, synthesise content if the source document or discussion notes contain
    relevant material. If nothing relevant is available for a section, leave it empty (heading
    only). Never fabricate content that is not grounded in {source_doc} or {discussion_notes}.

    **requirement:**
    ```
    ## Description
    > "{artifact.source_quote}" — {stakeholder_name}

    {synthesised summary of what this requirement captures, why it matters, and any constraints
     resolved during /sara-discuss}

    ## Acceptance Criteria
    {REQUIRED — derive at least one testable criterion directly from the requirement text,
     even if the source does not state it explicitly. Infer what "done" looks like for this
     requirement based on its title and source_quote. Format as a markdown checklist:
     - [ ] {criterion}
     Add further criteria for any conditions or constraints found in source or discussion notes.}

    ## Notes
    {synthesised caveats, dependencies, open questions, or related context from discussion
     notes — leave empty if none available}
    ```

    **decision:**
    ```
    ## Context
    > "{artifact.source_quote}" — {stakeholder_name}

    {synthesised summary of the situation or problem that prompted this decision, drawn from
     the source document and discussion notes}

    ## Decision
    {synthesised statement of what was decided, drawn from the artifact title and any
     resolution captured in discussion notes — leave empty if not clearly stated}

    ## Rationale
    {synthesised explanation of why this decision was made, drawn from discussion notes and
     source context — leave empty if not available}

    ## Alternatives Considered
    {synthesised list of alternatives mentioned in the source or discussion notes — leave
     empty if none were discussed}
    ```

    **action:**
    ```
    ## Description
    > "{artifact.source_quote}" — {stakeholder_name}

    {synthesised summary of what needs to be done, who is responsible, and any relevant
     deadlines or dependencies resolved during /sara-discuss}

    ## Notes
    {synthesised blockers, dependencies, follow-up context, or related items from discussion
     notes — leave empty if none available}
    ```

    **risk:**
    ```
    ## Description
    > "{artifact.source_quote}" — {stakeholder_name}

    {synthesised summary of the risk, its likelihood/impact context, and any relevant
     triggers or conditions identified during /sara-discuss}

    ## Mitigation
    {synthesised mitigation approaches or controls mentioned in the source or discussion
     notes — leave empty if none were discussed}

    ## Notes
    {synthesised monitoring notes, triggers, owners, or related context from discussion
     notes — leave empty if none available}
    ```

    Use the Write tool to create `{wiki_dir}{assigned_id}.md`.
    If write succeeds: append `{wiki_dir}{assigned_id}.md` to `written_files`.
    If write fails: append `{wiki_dir}{assigned_id}.md` to `failed_files`. Output the partial failure report (see format below). STOP.

  **If `artifact.action == "update"`:**

    Read the existing file `{wiki_dir}{artifact.existing_id}.md` using the Read tool.
    Apply `artifact.change_summary` to the relevant field(s) in the frontmatter or body. Update the `source` field to include `{item.id}` in addition to any existing source value. Update the `related` field by merging `artifact.related` with the existing related array (deduplicating by entity ID).
    Use the Write tool to overwrite `{wiki_dir}{artifact.existing_id}.md` with the updated content.
    If write succeeds: append `{wiki_dir}{artifact.existing_id}.md` to `written_files`.
    If write fails: append `{wiki_dir}{artifact.existing_id}.md` to `failed_files`. Output the partial failure report (see format below). STOP.

**Partial failure report format** (output and STOP if any write fails before commit):

```
## Update Partial Failure

Files written ({count}):
{written_files list}

Files NOT written ({count}):
{failed_files list}

The git commit has NOT been issued. Stage remains 'approved'.
Resolve the write failure, then re-run /sara-update {N}.
Do NOT use git reset — no commit was made; the written files are uncommitted changes.
```

**Step 3 — Update wiki/index.md and wiki/log.md**

After all artifact files are written successfully:

Read `wiki/index.md` using the Read tool.

For each artifact written in Step 2:
  - `action == "create"`: append a new row to the index table:
    `| [[{assigned_id}]] | {artifact.title} | open | {artifact.type} | [] | {today YYYY-MM-DD} |`
  - `action == "update"`: find the existing row matching `{artifact.existing_id}` in the table and update its `Last Updated` column to today's date.

Write the updated `wiki/index.md` using the Write tool.

Read `wiki/log.md` using the Read tool.

Append the following entry as a new line after the last row (or after the header comment if the log is empty):
`| [[{item.id}]] | {today YYYY-MM-DD} | {item.type} | {item.filename} | {comma-separated list of [[ID]] wikilinks for all artifact IDs written} |`

Write the updated `wiki/log.md` using the Write tool.

**Step 4 — Archive source file**

Determine `{archive_dir}` from `{item.type}`:
- `meeting`  → `raw/meetings/`
- `email`    → `raw/emails/`
- `slack`    → `raw/slack/`
- `document` → `raw/documents/`

Compute `{archive_filename}` = `{item.id}-{item.filename}` (e.g. `MTG-001-transcript-2026-04-27.md`).

Check whether the source file is git-tracked:
```bash
git ls-files --error-unmatch raw/input/{item.filename} 2>/dev/null && echo "tracked" || echo "untracked"
```

If tracked: run `git mv raw/input/{item.filename} {archive_dir}{archive_filename}`
If untracked: run `mv raw/input/{item.filename} {archive_dir}{archive_filename}`

**Step 5 — Commit, advance stage, and report**

Run the git add and commit in a single Bash block. Capture the exit code:

```bash
git add wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ \
        wiki/index.md wiki/log.md \
        .sara/pipeline-state.json \
        {archive_dir}{archive_filename}
git commit -m "feat(sara): ingest {item.id} — {item.filename}"
echo "EXIT:$?"
```

Check the exit code from the `echo "EXIT:$?"` output.

**If commit SUCCEEDS (exit code 0):**

  Capture `{commit_hash}` by running: `git log --oneline -1`

  Read `.sara/pipeline-state.json` using the Read tool.
  Update `items["{N}"].stage` = `"complete"` in memory.
  Write the updated `pipeline-state.json` using the Write tool.

  Output:
  ```
  ## Update Complete

  Commit: {commit_hash}
  Artifacts written: {count}
  {written_files list}
  Source archived: {archive_dir}{archive_filename}

  Item {N} ({item.id}) is now complete.
  ```

**If commit FAILS (exit code != 0):**

  Output:
  ```
  ## Update Failed — Commit Error

  Files written ({count}):
  {written_files list}

  The git commit failed. Stage remains 'approved'.
  You can re-run /sara-update {N} after resolving the git issue,
  or use `git reset HEAD {written_files}` to undo the uncommitted writes if needed.
  ```

  Do NOT write `stage = "complete"` to `pipeline-state.json`.
  STOP.

</process>

<notes>
- CRITICAL: Stage advances to `"complete"` ONLY after the git commit succeeds (exit code 0). Writing `stage=complete` before the commit is a fatal error — the item would be permanently stuck with no way to re-run `/sara-update` (Pitfall 1 from 02-RESEARCH.md). The correct ordering is: (1) write all wiki files, (2) git add + commit, (3) only then write `stage=complete`.
- CRITICAL: Entity counter increments happen BEFORE each create-action page write, and the updated counter is written to `pipeline-state.json` immediately (as a separate Write call before the page Write call). This prevents duplicate ID assignment if a page write fails and the skill is re-run — the counter stays at its incremented value across re-runs.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The JSON key in `items` is that same ID string. For `/sara-update MTG-001`, look up `items["MTG-001"]`. The `item.id` field equals the key — it appears in the commit message, the `source` field of written pages, and the log entry.
- Source file tracking: files dropped manually into `raw/input/` are untracked by git. Use `git ls-files --error-unmatch` to check before moving. If tracked: use `git mv` (git handles both the rename and the stage). If untracked: use `mv` and then include the archive path in `git add` (the move appears as a new file at the archive path). The `git add` command in Step 5 covers the archive path in both cases. The archived filename is always `{item.id}-{item.filename}` (e.g. `MTG-001-transcript.md`) — never just the numeric portion.
- Do NOT auto-rollback on partial failure (D-14). The user has full git history. Report which files were written and which were not; let the user decide whether to `git reset` or re-run `/sara-update {N}` after fixing the root cause. The written files are uncommitted changes — no commit was made.
- `schema_version` must always be quoted: `"1.0"` (not `1.0`). This prevents Obsidian's YAML parser from treating it as a float.
- `related` fields must use entity IDs only (e.g. `REQ-001`, `DEC-003`) — never file paths, relative links, or Obsidian `[[wiki-links]]`. This is a Phase 1 behavioral rule carried forward.
- The `raised_by` field in the artifact schema (written by `/sara-extract`) maps to the `raised-by` field in wiki page frontmatter (defined in the entity templates). The hyphen vs underscore difference is intentional: `raised_by` is the JSON field name in `pipeline-state.json`; `raised-by` is the YAML field name in wiki pages. Apply the mapping in Step 2 when substituting template fields.
- `vertical` and `department` are always separate fields in stakeholder pages — never merged. This is a locked domain constraint.
- `extraction_plan` may be empty (all artifacts rejected during `/sara-extract`). If non-empty check fails at Step 1, stop early with the re-run message. If it passes but the loop produces no writes, the git commit will still include `pipeline-state.json` (stage advance) and the archived source file.
- pipeline-state.json is read and written using Read and Write tools only — never Bash shell text-processing tools.
- NOTE: The canonical artifact schema field `raised_by` (defined in the plan interfaces and written by `/sara-extract`) contains the letter sequence "sed" as a substring of "raised". Any grep check for `jq\|sed\|awk` will match this field name. This is a false positive — no shell text-processing tools are referenced in this skill. The field name is non-negotiable: it is the canonical schema consumed here from `/sara-extract`.
</notes>
