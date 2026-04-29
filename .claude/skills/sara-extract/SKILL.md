---
name: sara-extract
description: "Extract wiki artifacts from the source document via inline sequential passes, resolve with sorter, then run the per-artifact approval loop"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---

<objective>
This skill reads the source document and discussion notes for pipeline item N, runs four sequential inline extraction passes (requirement → decision → action → risk) against the already-in-context source document, passes the merged output to a sorter agent that deduplicates and resolves create-vs-update decisions, presents the sorter's ambiguity questions to the user, and then runs the per-artifact Accept/Reject/Discuss loop on the cleaned artifact list. Approved artifacts are written to `extraction_plan` in `pipeline-state.json` and the item stage advances to `approved`; no wiki files are created or modified by this skill.
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

**Step 3 — Inline extraction passes and sorter**

The source document is already in context from Step 2. Run four sequential extraction passes — one per artifact type. Do NOT use Task() for extraction; each pass is an inline LLM prompt against the already-in-context source.

**Requirements pass**

A passage IS a requirement if and only if it contains a commitment modal verb or imperative phrase
from the INCLUDE list below. Passages lacking these signals are NOT requirements regardless of topic.

  INCLUDE — these passages ARE requirements (extract them):
  - "must", "shall", "has to", "required to", "need to" → priority: must-have
  - "will" (as a commitment to future behaviour, not narrating past events) → priority: must-have
  - "should" → priority: should-have
  - "could", "may" → priority: could-have
  - "will not", "won't", "out of scope", "we won't" → priority: wont-have

  EXCLUDE — these passages are NOT requirements (do NOT extract them):
  - Observation: "Users are currently frustrated with slow load times" (describes a situation, no commitment modal)
  - Aspiration/wish: "It would be great if the system handled more users" (desire expressed without a modal commitment)
  - Background context: "The company processes approximately 10,000 invoices per month" (descriptive fact only, no system obligation)

For each requirement found, classify it into one of six types inline based on what the requirement describes:
  - `functional`     — a capability the system performs
  - `non-functional` — quality attributes and design constraints (performance, reliability, usability, security, scalability)
  - `regulatory`     — external law, standards, or mandates (GDPR, PCI-DSS, etc.) — external obligations only, not internal policy
  - `integration`    — how the system connects to external systems, APIs, or people
  - `business-rule`  — domain logic or process policy
  - `data`           — structure, retention, quality, or ownership rules for data

For each requirement found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any requirement without a quotable passage)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable from the source or discussion_notes; otherwise use `"STK-NNN"` placeholder
- Set `priority` to the MoSCoW value derived from the commitment modal (see INCLUDE list above)
- Set `req_type` to one of the six types above
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT resolve create-vs-update — that is the sorter's job
- Assign `req_type` so sara-update can apply the section matrix (defined in `.sara/templates/requirement.md`) to determine which body sections are required, optional, or omitted for each requirement type

Collect results as `{req_artifacts}` (JSON array; empty array if none found).

**Decisions pass**

A passage IS a decision if it contains commitment language OR misalignment language from the
signal lists below. Passages lacking both signals are NOT decisions regardless of topic.

  COMMITMENT language — these passages ARE decisions → status: accepted
  - "we decided to", "we decided on"
  - "we chose", "we have chosen"
  - "we agreed on", "we agreed to"
  - "we went with"
  - "we will use" (as a settled commitment, not hypothetical)
  - "the approach is", "our approach is"
  - "we have decided"
  - Similar definitive past- or present-tense alignment phrases where the team is unified

  MISALIGNMENT language — these passages ARE decisions → status: open
  - Explicit disagreement: "Alice prefers X, but Bob argues Y"
  - Unresolved choice: "we need to decide between A and B"
  - Competing preferences: "there are two camps — those who want X vs those who want Y"
  - "we haven't agreed on", "still open", "not yet decided"
  - Documented tension without resolution

  EXCLUDE — these passages are NOT decisions (do NOT extract them):
  - Option exploration: "we could use X or Y" (exploring options, not choosing)
  - Aspiration/wish: "it would be good to have Z" (desire, no concluded choice or tension)
  - Requirement/obligation: "the system must support A" (system obligation, not a team choice)

For each decision found, classify it into one of six types inline based on what the decision is about:
  - `architectural`   — system structure, technology choices, component relationships
  - `process`         — how the team works, workflow, ceremonies, practices
  - `tooling`         — software tools, libraries, platforms selected
  - `data`            — data model, storage, retention, ownership rules
  - `business-rule`   — domain logic, policy decisions
  - `organisational`  — team structure, ownership, roles, responsibilities

For each decision found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any decision without a quotable passage)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable from the source or discussion_notes; otherwise use `"STK-NNN"` placeholder
- Set `status` to `"accepted"` if commitment language was detected; `"open"` if misalignment language was detected
- Set `dec_type` to one of the six types above (use `dec_type` — not `type` — to avoid collision with the envelope `type: "decision"` field)
- Set `chosen_option` to the selected option text for commitment-language decisions; set to `""` for open/misalignment decisions
- Set `alternatives` to an array of alternatives mentioned in the source (strings); set to `[]` if none are mentioned
- Set `action` = `"create"`, `type` = `"decision"`, `id_to_assign` = `"DEC-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT extract `context` or `rationale` — these are synthesised by sara-update from the full source document, not extracted here

Collect results as `{dec_artifacts}` (JSON array; empty array if none found).

**Actions pass**

Extract every passage that describes an action item — a concrete task or follow-up with an implied or explicit owner (something that must be done, not a general statement of intent). For each action found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY)
- Write a short (≤10 words) imperative-phrase `title` (e.g. "Send updated proposal to client")
- Set `raised_by` to the STK-NNN ID of the person who will own the action if identifiable; otherwise `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"action"`, `id_to_assign` = `"ACT-NNN"`, `related` = `[]`, `change_summary` = `""`

Collect results as `{act_artifacts}` (JSON array; empty array if none found).

**Risks pass**

Extract every passage that describes a risk — an uncertain event or condition with a potential negative effect (threat, concern, or "what if" scenario). A confirmed problem is an action item, not a risk. For each risk found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY)
- Write a short (≤10 words) noun-phrase `title` (e.g. "Budget overrun on infrastructure")
- Set `raised_by` to the STK-NNN ID if identifiable; otherwise `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"risk"`, `id_to_assign` = `"RSK-NNN"`, `related` = `[]`, `change_summary` = `""`

Collect results as `{risk_artifacts}` (JSON array; empty array if none found).

**Merge and sorter dispatch**

Merge all four arrays:
`{merged}` = req_artifacts + dec_artifacts + act_artifacts + risk_artifacts

If `{merged}` is empty (all four passes returned []):
  Output: `"No artifacts found in source document. All extraction passes returned empty results."`
  Output: `"Proceeding to Step 4 with empty artifact list. You may reject this result or re-run /sara-discuss {N} to add discussion notes."`
  Set `{cleaned_artifacts}` = [] and skip the sorter dispatch and sorter question loop. Proceed directly to Step 4.

Load grep summaries using the Bash tool:
```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null
```

Spawn sorter:
- Task(`sara-artifact-sorter`, prompt=merged+grep_summaries+wiki_index) → `{sorter_output}` (JSON object)

Parse `{sorter_output}`:

If `{sorter_output}` cannot be parsed as a valid JSON object, or if `cleaned_artifacts` is absent from the parsed result:
  Output: `"Sorter agent returned invalid output. Raw response: {sorter_output}"`
  Output: `"Re-run /sara-extract {N} to retry. If the error persists, reduce the source document size."`
  STOP.

- `{cleaned_artifacts}` = sorter_output.cleaned_artifacts
- `{sorter_questions}` = sorter_output.questions

If `{sorter_questions}` is non-empty:
  For each question in `{sorter_questions}`, one at a time:
    Present the question as plain text:
    ```
    Sorter question {i} of {total}: {question}
    ```
    Wait for the user's reply using a plain-text wait (freeform — do NOT use AskUserQuestion here).
    Apply the user's resolution to `{cleaned_artifacts}` using the following logic.
    First determine the question type from its text:
      - If the question contains "extracted as both": type-ambiguity resolution
          A: keep type1 artifact; remove the type2 duplicate from cleaned_artifacts
          B: keep type2 artifact; remove the type1 duplicate from cleaned_artifacts
          C: remove both from cleaned_artifacts (skip the passage)
      - If the question contains "looks similar to": likely-duplicate resolution
          A: keep action=update for the matched existing entity; remove create duplicate from cleaned_artifacts
          B: keep action=create (treat as a separate new artifact)
          C: remove from cleaned_artifacts (skip — not relevant)
      - If the question contains "appears to relate to": cross-reference resolution
          A: add the referenced entity ID to the artifact's related array
          B: no change to the artifact's related array
    If user replies anything else:
      - If the question contains "appears to relate to": re-present with the note "Please reply A or B." and wait again.
      - All other question types: re-present with the note "Please reply A, B, or C." and wait again.
      Do not advance to the next question.

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
    After 5 Discuss cycles on the same artifact without an Accept or Reject, present a plain-text warning:
    "This artifact has been discussed {N} times. Please select Accept or Reject to proceed, or Reject to skip it."
    Continue presenting the AskUserQuestion until the user selects "Accept" or "Reject".

After all artifacts have been resolved to "Accept" or "Reject": proceed to Step 5.

If `/sara-extract N` is re-run on an item that is still in `extracting` stage (possible if a previous session was interrupted): re-run the full loop with freshly generated artifacts. The wiki has not been written yet; it is safe to re-run the full extraction loop.

**Step 5 — Write extraction plan and advance stage**

Read `.sara/pipeline-state.json` using the Read tool.

Update `items["{N}"]` in memory:
  - Set `stage` = `"approved"`
  - Set `extraction_plan` = the `approved_artifacts` array (may be empty if all artifacts were rejected)

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.

Step 5 ALWAYS writes the full `approved_artifacts` array to `extraction_plan`, replacing any previously stored value. Do NOT read or merge a pre-existing `extraction_plan` — overwrite it unconditionally.

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
- Extraction runs as four sequential inline passes against the already-in-context source document — no specialist Task() agents are used. The source document is NOT passed to the sorter Task() — it is read once in Step 2 and remains in context for all four inline passes only. The merged artifact array, grep summaries, and wiki/index.md are passed to the sorter Task().
- `wiki/index.md` is re-read at Step 2 (the dedup step), not at skill entry. This ensures the index is fresh even if `/sara-add-stakeholder` updated it during the preceding `/sara-discuss` session (Pitfall 4 guard). Reading it at entry would miss any STK pages added to the index mid-session.
- AskUserQuestion header hard limit is 12 characters. Use `"Artifact {N}"` for N = 1–9 (10 chars — safe). Use `"Item {N}"` for N = 10 or more (7 chars — safe). Never exceed 12 chars in the header field.
- When user selects "Discuss": output a plain-text question and wait for the user's freeform reply. Do NOT use another AskUserQuestion call. The freeform rule applies because the user wants to explain the correction in their own words — structured options would constrain that. Resume AskUserQuestion only after incorporating the correction and re-presenting the updated artifact.
- `extraction_plan` is written to `pipeline-state.json` ONLY after the full loop completes. If the session resets mid-loop, the extraction_plan in pipeline-state.json will be empty or absent. Re-run `/sara-extract N` to start a fresh loop — the wiki has not been written yet, so this is safe.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The JSON key in `items` is that same ID string. For `/sara-extract MTG-001`, look up `items["MTG-001"]`.
- `id_to_assign` and `existing_id` are mutually exclusive. For action=create, use `id_to_assign` (placeholder like `"REQ-NNN"`). For action=update, use `existing_id` (the real ID from the wiki index, like `"DEC-001"`). Omit or set the inapplicable field to `""`.
- Topics matching existing wiki entities MUST produce UPDATE artifacts (action=update), not duplicate CREATE artifacts. The dedup check at Step 3 is required for every topic — not optional.
- pipeline-state.json is written using Read + Write tools only — never Bash shell text-processing tools.
- NOTE: The canonical artifact schema field `raised_by` (defined in the plan interfaces) contains the letter sequence "sed" as a substring of "raised". The grep check `grep "jq\|sed\|awk"` will match this field name. This is a false positive — no shell text-processing tools are referenced in this skill. The field name is non-negotiable: it is the canonical schema consumed by `/sara-update`.
- Extraction architecture: sara-extract runs four inline sequential passes (requirement → decision → action → risk) against the already-in-context source document. No specialist Task() agents are used for extraction. Only the merged artifact array is passed to the sorter Task(). The sorter agent (sara-artifact-sorter) receives the merged output plus grep summaries and wiki/index.md. All extraction passes always return action="create"; the sorter resolves create-vs-update.
- Sorter questions are presented to the human BEFORE the approval loop starts (Step 4). Never present sorter questions inside the artifact loop (Pitfall 4 guard).
- If a specialist agent returns an empty array [], merge it as zero elements — skip silently, do not generate a question about the absent type.
</notes>
