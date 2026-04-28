---
name: sara-extract
description: "Present planned wiki artifacts for per-artifact approval before any wiki writes"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---

<objective>
This skill reads the source document and discussion notes for pipeline item N, dispatches four specialist extraction agents (one per entity type) via Task() in parallel, passes their merged output to a sorter agent that deduplicates and resolves create-vs-update decisions, presents the sorter's ambiguity questions to the user, and then runs the per-artifact Accept/Reject/Discuss loop on the cleaned artifact list. Approved artifacts are written to `extraction_plan` in `pipeline-state.json` and the item stage advances to `approved`; no wiki files are created or modified by this skill.
</objective>

<process>

**Step 1 — Stage guard and item lookup**

Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: it must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
Output: `"Usage: /sara-extract <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Find the item with key `"{N}"` in the `items` object (N is the full ID argument — for `/sara-extract MTG-001`, N = `"MTG-001"`).

If no item exists with key `"{N}"`:
  Output: `"No pipeline item {N} found. Run /sara-ingest to register a new item, or run /sara-ingest with no arguments to see the full pipeline status."`
  STOP.

Check `items["{N}"].stage`. Expected stage: `"extracting"`.

If actual stage != `"extracting"`:
  Output: `"Item {N} is in stage '{actual_stage}'. Run /sara-extract <ID> only when stage is 'extracting'. Re-run /sara-discuss {N} if you need to revisit the discussion."`
  STOP.

Store `{item}` = `items["{N}"]` for use in subsequent steps.

**Step 2 — Load source, discussion notes, and wiki index**

Read `{item.source_path}` using the Read tool. This is the source document.

`{discussion_notes}` = `items["{N}"].discussion_notes` (already in memory from the Step 1 read of pipeline-state.json).

Read `wiki/index.md` HERE using the Read tool. Reading the index at this step (not at skill entry) ensures it is fresh — it may have been updated by `/sara-add-stakeholder` during the preceding `/sara-discuss` session. (See notes — Pitfall 4 guard.)

**Step 3 — Dispatch specialist agents and sorter**

Spawn four specialist agents via Task() in parallel, passing the source document content and discussion_notes string explicitly in each prompt. Agents start cold and have no implicit access to pipeline-state.json or the wiki.

Task prompt template for each specialist:
```
You are {agent-name}. Extract {type} artifacts only.

<source_document>
{full content of source file read in Step 2}
</source_document>

<discussion_notes>
{discussion_notes string from pipeline-state.json, or empty string if not set}
</discussion_notes>

Return a JSON array of {type} artifacts. Each artifact must include a source_quote.
```

Spawn all four in parallel (or sequentially if context window is a concern):
- Task(`sara-requirement-extractor`, prompt=source+discussion_notes) → `{req_artifacts}` (JSON array)
- Task(`sara-decision-extractor`, prompt=source+discussion_notes) → `{dec_artifacts}` (JSON array)
- Task(`sara-action-extractor`, prompt=source+discussion_notes) → `{act_artifacts}` (JSON array)
- Task(`sara-risk-extractor`, prompt=source+discussion_notes) → `{risk_artifacts}` (JSON array)

Merge all four arrays:
`{merged}` = req_artifacts + dec_artifacts + act_artifacts + risk_artifacts

Load grep summaries using the Bash tool:
```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
```

Spawn sorter:
- Task(`sara-artifact-sorter`, prompt=merged+grep_summaries+wiki_index) → `{sorter_output}` (JSON object)

Parse `{sorter_output}`:
- `{cleaned_artifacts}` = sorter_output.cleaned_artifacts
- `{sorter_questions}` = sorter_output.questions

If `{sorter_questions}` is non-empty:
  For each question in `{sorter_questions}`, one at a time:
    Present the question as plain text:
    ```
    Sorter question {i} of {total}: {question}
    ```
    Wait for the user's reply using a plain-text wait (freeform — do NOT use AskUserQuestion here).
    Apply the user's resolution to `{cleaned_artifacts}` before moving to the next question.

Proceed to Step 4 with `{cleaned_artifacts}` as the artifact list. All sorter questions are now resolved.

**Step 4 — Per-artifact approval loop**

Initialize `approved_artifacts = []`.

For each artifact in the list, at index `{artifact_index}` (starting at 1):

  Present the artifact as plain text before the AskUserQuestion call:
  ```
  --- Artifact {artifact_index} ---
  Type:   {type}
  Title:  {title}
  Action: CREATE new {TYPE}-NNN  /  UPDATE {existing_id}
  Source: "{source_quote}"
  [If update] Change: {change_summary}
  ```

  Then call AskUserQuestion:
  - For `artifact_index` 1–9: use header `"Artifact {artifact_index}"` (10 chars — safe within 12-char hard limit)
  - For `artifact_index` 10 or more: use header `"Item {artifact_index}"` (7 chars — safe within 12-char hard limit)

  ```
  header: "Artifact {N}"   (or "Item {N}" for N >= 10)
  question: "Accept, reject, or discuss artifact {artifact_index}?"
  options: ["Accept", "Reject", "Discuss"]
  ```

  If user selects **"Accept"**:
    Append the artifact object to `approved_artifacts`.
    Continue to the next artifact.

  If user selects **"Reject"**:
    Skip this artifact (do not add to `approved_artifacts`).
    Continue to the next artifact.

  If user selects **"Discuss"**:
    Output as plain text: `"What would you like to change about this artifact?"`
    Wait for the user's reply using a plain-text wait — do NOT use another AskUserQuestion here. The freeform rule applies: the user wants to explain freely, so structured options are not appropriate.
    Incorporate the user's correction into the artifact object (update title, source_quote, type, change_summary, or the raised_by field as directed by the user).
    Re-present the updated artifact as plain text using the same format shown above.
    Loop back to the AskUserQuestion call for this artifact.
    Repeat the Accept/Reject/Discuss cycle for this artifact until the user selects "Accept" or "Reject".

After all artifacts have been resolved to "Accept" or "Reject": proceed to Step 5.

If `/sara-extract N` is re-run on an item that is still in `extracting` stage (possible if a previous session was interrupted): re-run the full loop with freshly generated artifacts. The wiki has not been written yet; it is safe to re-run the full extraction loop.

**Step 5 — Write extraction plan and advance stage**

Read `.sara/pipeline-state.json` using the Read tool.

Update `items["{N}"]` in memory:
  - Set `stage` = `"approved"`
  - Set `extraction_plan` = the `approved_artifacts` array (may be empty if all artifacts were rejected)

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.

Do NOT use Bash shell text-processing tools — use Read and Write tools only.

Output a summary table:

```
## Extraction Plan — Item {N}

{count_accepted} artifacts accepted / {count_rejected} rejected.

| # | Action | Type        | Title                              |
|---|--------|-------------|------------------------------------|
| 1 | CREATE | requirement | API rate limiting per tenant       |
| 2 | UPDATE | decision    | Auth token expiry policy           |

Run /sara-update {N} to write approved artifacts to the wiki.
```

If zero artifacts were accepted: still write the empty `extraction_plan: []` and advance stage to `"approved"`. Output: `"0 artifacts accepted. Extraction plan is empty. Stage advanced to approved. You can still run /sara-update {N} (it will be a no-op) or re-run /sara-discuss {N} to revisit the source."`

</process>

<notes>
- `source_quote` is MANDATORY for every artifact. An artifact without a source quote must not be generated or accepted. This is the evidence trail that ensures every wiki change can be traced back to a specific passage in the source document.
- `wiki/index.md` is re-read at Step 2 (the dedup step), not at skill entry. This ensures the index is fresh even if `/sara-add-stakeholder` updated it during the preceding `/sara-discuss` session (Pitfall 4 guard). Reading it at entry would miss any STK pages added to the index mid-session.
- AskUserQuestion header hard limit is 12 characters. Use `"Artifact {N}"` for N = 1–9 (10 chars — safe). Use `"Item {N}"` for N = 10 or more (7 chars — safe). Never exceed 12 chars in the header field.
- When user selects "Discuss": output a plain-text question and wait for the user's freeform reply. Do NOT use another AskUserQuestion call. The freeform rule applies because the user wants to explain the correction in their own words — structured options would constrain that. Resume AskUserQuestion only after incorporating the correction and re-presenting the updated artifact.
- `extraction_plan` is written to `pipeline-state.json` ONLY after the full loop completes. If the session resets mid-loop, the extraction_plan in pipeline-state.json will be empty or absent. Re-run `/sara-extract N` to start a fresh loop — the wiki has not been written yet, so this is safe.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The JSON key in `items` is that same ID string. For `/sara-extract MTG-001`, look up `items["MTG-001"]`.
- `id_to_assign` and `existing_id` are mutually exclusive. For action=create, use `id_to_assign` (placeholder like `"REQ-NNN"`). For action=update, use `existing_id` (the real ID from the wiki index, like `"DEC-001"`). Omit or set the inapplicable field to `""`.
- Topics matching existing wiki entities MUST produce UPDATE artifacts (action=update), not duplicate CREATE artifacts. The dedup check at Step 3 is required for every topic — not optional.
- pipeline-state.json is written using Read + Write tools only — never Bash shell text-processing tools.
- NOTE: The canonical artifact schema field `raised_by` (defined in the plan interfaces) contains the letter sequence "sed" as a substring of "raised". The grep check `grep "jq\|sed\|awk"` will match this field name. This is a false positive — no shell text-processing tools are referenced in this skill. The field name is non-negotiable: it is the canonical schema consumed by `/sara-update`.
- Agent dispatch: sara-extract spawns four specialist agents (sara-requirement-extractor, sara-decision-extractor, sara-action-extractor, sara-risk-extractor) via Task() in parallel. Each receives only the raw source content and discussion_notes — no wiki state (D-03, D-04). The sorter agent (sara-artifact-sorter) receives the merged output plus grep summaries and wiki/index.md (D-07). Specialist agents always return action="create"; the sorter resolves create-vs-update (D-06).
- Sorter questions are presented to the human BEFORE the approval loop starts (Step 4). Never present sorter questions inside the artifact loop (Pitfall 4 guard).
- If a specialist agent returns an empty array [], merge it as zero elements — skip silently, do not generate a question about the absent type.
- The `discussion_notes` string MUST be passed explicitly in each specialist Task() prompt. Agents start cold and have no implicit access to pipeline-state.json. An empty discussion_notes string is valid — pass it as an empty string, not omitted. (Pitfall 1 guard.)
</notes>
