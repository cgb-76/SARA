---
name: sara-extract
description: "Extract wiki artifacts from the source document via inline sequential passes, resolve with sorter, then run the per-artifact approval loop"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 2.0.0
---

<objective>
This skill reads the source document and discussion notes for pipeline item N, runs four sequential inline extraction passes (requirement → decision → action → risk) against the already-in-context source document, passes the merged output to a sorter agent that deduplicates and resolves create-vs-update decisions, presents the sorter's ambiguity questions to the user, and then runs the per-artifact Accept/Reject/Discuss loop on the cleaned artifact list. Approved artifacts are written as a headed markdown body to `.sara/pipeline/{N}/plan.md` and the item stage advances to `approved` in `.sara/pipeline/{N}/state.md`; no wiki files are created or modified by this skill.
</objective>

<process>

**Step 1 — Stage guard and item lookup**

Validate `$ARGUMENTS`: it must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
Output: `"Usage: /sara-extract <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Check if `.sara/pipeline/{N}/state.md` exists by attempting to read it with the Read tool.

If the file cannot be read (does not exist):
  Output: `"No pipeline item {N} found. Run /sara-ingest to register a new item, or run /sara-ingest with no arguments to see the full pipeline status."`
  STOP.

Parse the YAML frontmatter from state.md. Extract:
- `id` → store as `{item.id}`
- `type` → store as `{item.type}`
- `filename` → store as `{item.filename}`
- `source_path` → store as `{item.source_path}`
- `stage` → store as `{item.stage}`
- `created` → store as `{item.created}`

Check `{item.stage}`. Expected stage: `"extracting"`.

If `{item.stage}` != `"extracting"`:
  Output: `"Item {N} is in stage '{item.stage}'. Run /sara-extract <ID> only when stage is 'extracting'. Re-run /sara-discuss {N} if you need to revisit the discussion."`
  STOP.

**Step 2 — Load source, discussion notes, and wiki index**

Read `{item.source_path}` using the Read tool. This is the source document.

Attempt to read `.sara/pipeline/{N}/discuss.md` using the Read tool.
- If the file is present: set `{discussion_notes}` = the markdown body content of discuss.md.
- If the file is absent (Read returns an error): set `{discussion_notes}` = `""` (empty string). Continue — do not STOP. An absent discuss.md is valid if sara-discuss found no blockers or if discuss.md was not committed due to an earlier failure. The extraction proceeds without discussion context.

Read `wiki/index.md` HERE using the Read tool. Reading the index at this step (not at skill entry) ensures it is fresh — it may have been updated by `/sara-add-stakeholder` during the preceding `/sara-discuss` session. (See notes — Pitfall 4 guard.)

**Step 3 — Inline extraction passes and sorter**

The source document is already in context from Step 2. Run four sequential extraction passes — one per artifact type. Do NOT use Task() for extraction; each pass is an inline LLM prompt against the already-in-context source.

Read `.sara/config.json` using the Read tool. Store `config.segments` for use in the `segments`
inference step of each extraction pass below.

**Requirements pass**

A passage IS a requirement if and only if it contains a commitment modal verb or imperative phrase
from the INCLUDE list below. Passages lacking these signals are NOT requirements regardless of topic.

  INCLUDE — these passages ARE requirements (extract them):
  - "must", "shall", "has to", "required to", "need to" → priority: must-have
  - "will" (as a commitment to future behaviour, not narrating past events) → priority: must-have
    NOTE: "we will use [technology]" is more naturally a DECISION (technology choice) than a requirement. If the passage names a specific tool or platform, prefer the decisions pass. Only extract as a requirement if the passage describes a system behaviour obligation.
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
- Set `segments` to an array of segment name strings (zero or more):
    1. STK attribution: if `source_quote` ends with `— [[STK-NNN|…]]`, parse the STK-NNN ID
       from the attribution, read `wiki/stakeholders/{STK-NNN}.md`, extract the `segment:` field
       value, and add it as the first entry in the array. If no STK-NNN is found in
       `source_quote`, also check `discussion_notes` — if it identifies the speaker for this
       passage and contains a `[[STK-NNN|…]]` reference, extract the STK-NNN ID from there.
    2. Keyword matching: scan the source passage for case-insensitive substrings matching any
       name in `config.segments`; add each matching segment name (deduplicated).
    3. All-segments fallback: if neither attribution nor keyword matching resolves any segment name, add all segment names from config.segments.
    Deduplication: each segment name appears at most once in the array.
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
- Set `segments` to an array of segment name strings (zero or more):
    1. STK attribution: if `source_quote` ends with `— [[STK-NNN|…]]`, parse the STK-NNN ID
       from the attribution, read `wiki/stakeholders/{STK-NNN}.md`, extract the `segment:` field
       value, and add it as the first entry in the array. If no STK-NNN is found in
       `source_quote`, also check `discussion_notes` — if it identifies the speaker for this
       passage and contains a `[[STK-NNN|…]]` reference, extract the STK-NNN ID from there.
    2. Keyword matching: scan the source passage for case-insensitive substrings matching any
       name in `config.segments`; add each matching segment name (deduplicated).
    3. All-segments fallback: if neither attribution nor keyword matching resolves any segment name, add all segment names from config.segments.
    Deduplication: each segment name appears at most once in the array.
- Set `action` = `"create"`, `type` = `"decision"`, `id_to_assign` = `"DEC-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT extract `context` or `rationale` — these are synthesised by sara-update from the full source document, not extracted here
- Do NOT set a `deciders` field — the `deciders` frontmatter field on decision pages is intentionally left as `[]` by the pipeline and must be filled in manually after wiki pages are created

Collect results as `{dec_artifacts}` (JSON array; empty array if none found).

**Actions pass**

A passage IS an action if it describes any work that needs to happen — a concrete task,
follow-up, or deliverable that someone is expected to do. Cast the broadest possible net:
extract passages with or without a named owner, with or without a due date, with or without
explicit assignment language. The existing sorter handles cross-type disambiguation.

  INCLUDE — these passages ARE actions (extract them):
  - Explicit assignment: "Alice will send the updated proposal by Friday"
  - Implicit task: "someone needs to chase the sign-off on this"
  - Deliverable commitment: "we need a revised spec before next sprint"
  - Follow-up required: "Bob to confirm the budget allocation"
  - Unowned task: "this needs to be documented" (no owner named — still an action)

  EXCLUDE — these passages are NOT actions (do NOT extract them):
  - Background context: "historically we have used vendor X" (describes past, not future work)
  - Risk mitigations: passages that describe a contingency plan — these are captured by the Risks pass
  - Requirements: passages with modal verbs describing system capabilities ("the system must support…") — captured by the Requirements pass
  - Decisions: passages describing a concluded choice — captured by the Decisions pass

For each action found, classify it into one of two `act_type` values inline:
  - `deliverable` — a concrete output or artefact to produce (report, document, implementation, fix)
  - `follow-up`   — a check-in, response, or update required from someone (confirm, reply, chase, update)

For each action found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any action without a quotable passage)
- Write a short (≤10 words) imperative-phrase `title` (e.g. "Send updated proposal to client", "Confirm budget allocation with finance")
- Set `act_type` to `"deliverable"` or `"follow-up"` (see classification above)
- Set `owner` to the STK-NNN ID of the person assigned to do the work if identifiable from source or discussion_notes; if a name is mentioned but not yet in the stakeholder registry, write the raw name string (e.g. `"Alice"`); if no person is identified, set to `""`
- Set `raised_by` to the STK-NNN ID of the person who surfaced or mentioned this action (may be the same as owner); otherwise use `"STK-NNN"` placeholder
- Set `due_date` to the raw string from the source if a due date or deadline is mentioned (e.g. `"by Friday"`, `"EOW"`, `"before next sprint"`); otherwise set to `""`
- Set `segments` to an array of segment name strings (zero or more):
    1. STK attribution: if `source_quote` ends with `— [[STK-NNN|…]]`, parse the STK-NNN ID
       from the attribution, read `wiki/stakeholders/{STK-NNN}.md`, extract the `segment:` field
       value, and add it as the first entry in the array. If no STK-NNN is found in
       `source_quote`, also check `discussion_notes` — if it identifies the speaker for this
       passage and contains a `[[STK-NNN|…]]` reference, extract the STK-NNN ID from there.
    2. Keyword matching: scan the source passage for case-insensitive substrings matching any
       name in `config.segments`; add each matching segment name (deduplicated).
    3. All-segments fallback: if neither attribution nor keyword matching resolves any segment name, add all segment names from config.segments.
    Deduplication: each segment name appears at most once in the array.
- Set `action` = `"create"`, `type` = `"action"`, `id_to_assign` = `"ACT-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT extract Description or Context — these are synthesised by sara-update from the full source document, not extracted here

Collect results as `{act_artifacts}` (JSON array; empty array if none found).

**Risks pass**

A passage IS a risk if it describes an **uncertain future event or condition with a potential
negative effect** — a threat, concern, "what if" scenario, or exposure that has not yet
materialised. A confirmed problem already happening is an action item, not a risk.

  INCLUDE — these passages ARE risks (extract them):
  - Future uncertainty: "we might not get budget approval for the second phase"
  - Concern or exposure: "there's a risk the integration vendor won't hit the API delivery date"
  - What-if scenario: "if the key architect leaves, we'd have no one to maintain this"
  - Dependency risk: "we're dependent on the client's data team being available for testing"
  - Regulatory exposure: "we haven't confirmed GDPR compliance for the new data store"

  EXCLUDE — these passages are NOT risks (do NOT extract them):
  - Confirmed problem already happening: "the build pipeline is broken right now" (→ action item)
  - Background context: "historically the vendor has been slow" (descriptive fact, not an uncertain future event)
  - Aspiration: "it would be great if the system could handle more load" (desire, not a risk event)
  - Mitigation or contingency already captured as an action: "Alice will set up redundancy this week"

For each risk found, classify it into one of six `risk_type` values inline:
  - `technical`    — system, architecture, technology, integration risks
  - `financial`    — budget, cost, funding, pricing risks
  - `schedule`     — timeline, deadline, dependency, sequencing risks
  - `quality`      — accuracy, completeness, reliability, performance risks
  - `compliance`   — regulatory, legal, policy, contractual risks
  - `people`       — staffing, skills, availability, stakeholder engagement risks

For each risk found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any risk without a quotable passage)
- Write a short (≤10 words) noun-phrase `title` (e.g. "Budget overrun on infrastructure phase", "Vendor API delivery delay")
- Set `risk_type` to one of the six values above (use `risk_type` — not `type` — to avoid collision with the envelope `type: "risk"` field)
- Set `owner` to the STK-NNN ID of the person responsible for tracking and mitigating this risk if identifiable from source or discussion_notes; if a name is mentioned but not yet in the stakeholder registry, write the raw name string (e.g. `"Alice"`); if no person is identified, set to `""`
- Set `raised_by` to the STK-NNN ID of the person who surfaced or raised this risk in the source (may be the same as owner); otherwise use `"STK-NNN"` placeholder
- Set `likelihood` to `"high"`, `"medium"`, or `"low"` if the source contains an explicit signal (e.g. "very likely", "low probability", "significant concern", "minor risk"); otherwise set to `""`. Do not invent a likelihood value if none is stated.
- Set `impact` to `"high"`, `"medium"`, or `"low"` if the source contains an explicit signal (e.g. "catastrophic if it happens", "minor inconvenience", "could derail the project"); otherwise set to `""`. Do not invent an impact value if none is stated.
- Set `status` based on explicit source language only:
  - `"mitigated"` — source says "controls already in place", "this is being handled by X", "we've addressed this with Y"
  - `"accepted"`  — source says "we've accepted this risk", "we're comfortable with this", "no action needed, we'll live with it"
  - `"open"`      — all other risks (default; do not require explicit language for open)
- Set `segments` to an array of segment name strings (zero or more):
    1. STK attribution: if `source_quote` ends with `— [[STK-NNN|…]]`, parse the STK-NNN ID
       from the attribution, read `wiki/stakeholders/{STK-NNN}.md`, extract the `segment:` field
       value, and add it as the first entry in the array. If no STK-NNN is found in
       `source_quote`, also check `discussion_notes` — if it identifies the speaker for this
       passage and contains a `[[STK-NNN|…]]` reference, extract the STK-NNN ID from there.
    2. Keyword matching: scan the source passage for case-insensitive substrings matching any
       name in `config.segments`; add each matching segment name (deduplicated).
    3. All-segments fallback: if neither attribution nor keyword matching resolves any segment name, add all segment names from config.segments.
    Deduplication: each segment name appears at most once in the array.
- Set `action` = `"create"`, `type` = `"risk"`, `id_to_assign` = `"RSK-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT extract IF/THEN statement or Mitigation — these are synthesised by sara-update from the full source document, not extracted here

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
- `{sorter_questions}` = sorter_output.questions if the "questions" key exists, else `[]`

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
      - If the question contains "both want to update": duplicate-update resolution
          A: keep artifact A; remove artifact B from cleaned_artifacts
          B: keep artifact B; remove artifact A from cleaned_artifacts
          C: keep both artifacts in cleaned_artifacts (both updates will be applied)
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

  If (`artifact.type == "action"` OR `artifact.type == "risk"`) AND `artifact.owner == ""`:
    Output as plain text:
    ⚠ Owner not set — assign manually after /sara-update, or run /sara-add-stakeholder first.

  If (`artifact.type == "action"` OR `artifact.type == "risk"`) AND `artifact.owner` is a non-empty string that does not match the pattern `STK-\d{3}`:
    Output as plain text:
    ⚠ Owner '{artifact.owner}' is a raw name — run /sara-add-stakeholder to register them before or after /sara-update.

  Present the artifact as plain text before the AskUserQuestion call:
  ```
  --- Artifact {artifact_index} ---
  Type:   {type}
  Title:  {title}
  Action: CREATE new {id_to_assign}        ← if artifact.action == "create"
  Action: UPDATE {artifact.existing_id}    ← if artifact.action == "update"
  Source: "{source_quote}"
  [If update] Change: {change_summary}
  ```
  (Show only the applicable Action line — do not display both.)

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

NOTE: Re-running `/sara-extract {N}` always re-runs the full extraction and sorter pipeline from the beginning. Previously answered sorter questions are not preserved between sessions. The user will be presented with all sorter questions again on re-run. This is by design — the fresh extraction may produce a different artifact set than the interrupted session.

**Step 5 — Write plan.md, commit, and advance stage**

Step 5 ALWAYS writes the full `approved_artifacts` list to `plan.md`, replacing any previously stored value. Do NOT read or merge a pre-existing `plan.md` — overwrite it unconditionally.

Compose the plan.md content. Write one `##` section per artifact in `approved_artifacts`, in order. Use the following format for each artifact:

For CREATE artifacts:
```markdown
## Artifact {N} — CREATE {artifact.type}

**Type:** {artifact.type}
**Title:** {artifact.title}
**Action:** create
**{type-specific field name}:** {value}    (e.g. "Req type:" for requirements, "Dec type:" for decisions, "Act type:" for actions, "Risk type:" for risks)
**Priority:** {artifact.priority}           (requirements only; omit for other types)
**Status:** {artifact.status}               (decisions and risks only; omit for requirements and actions)
**Chosen option:** {artifact.chosen_option} (decisions only; omit for other types)
**Source quote:** {artifact.source_quote}
**Raised by:** {artifact.raised_by}
**Owner:** {artifact.owner}                 (actions and risks only; omit for other types)
**Due date:** {artifact.due_date}           (actions only; omit for other types)
**Likelihood:** {artifact.likelihood}       (risks only; omit for other types)
**Impact:** {artifact.impact}               (risks only; omit for other types)
**Segments:** {artifact.segments as comma-separated list in brackets}
**Related:** {artifact.related as comma-separated list in brackets}
```
Omit fields that are not applicable to the artifact type (e.g. Priority only on requirements, Status only on decisions/risks). Omit fields with empty string values for optional fields (owner, due_date, likelihood, impact). Always include Type, Title, Action, Source quote, Raised by, Segments, Related.

For UPDATE artifacts, use the same format but with:
```markdown
## Artifact {N} — UPDATE {artifact.type} {artifact.existing_id}

**Type:** {artifact.type}
**Title:** {artifact.title}
**Action:** update
**Existing ID:** {artifact.existing_id}
**Change summary:** {artifact.change_summary}
... (other applicable fields)
```

Separate each artifact section with a `---` horizontal rule.

If `approved_artifacts` is empty: write a minimal plan.md:
```markdown
(No artifacts approved — extraction plan is empty.)
```

Write `.sara/pipeline/{N}/plan.md` using the Write tool with the composed content.

Run git commit:
```bash
git add ".sara/pipeline/{N}/plan.md"
git commit -m "feat(sara): plan {N} — {count_accepted} artifacts"
echo "EXIT:$?"
```

Check the exit code.

If commit FAILS (exit code != 0):
  Output: `"Commit failed for {N}. plan.md has been written but the commit did not succeed. Stage remains 'extracting'. Resolve the git issue and re-run /sara-extract {N}."`
  STOP. Do NOT write state.md with stage: approved.

If commit SUCCEEDS (exit code 0):
  Capture `{commit_hash}` by running: `git log --oneline -1`

  Read `.sara/pipeline/{N}/state.md` using the Read tool.
  Reconstruct frontmatter with `stage: approved` (all other fields unchanged):
  ```markdown
  ---
  id: {item.id}
  type: {item.type}
  filename: {item.filename}
  source_path: {item.source_path}
  stage: approved
  created: {item.created}
  ---
  ```
  Write `.sara/pipeline/{N}/state.md` using the Write tool.

  Run:
  ```bash
  git add ".sara/pipeline/{N}/state.md"
  git commit -m "feat(sara): stage {N} → approved"
  echo "EXIT:$?"
  ```

  If commit FAILS (exit code != 0):
    Output: `"Stage-advance commit failed for {N}. state.md on disk shows stage: approved but the commit did not succeed. Run: git add .sara/pipeline/{N}/state.md && git commit -m 'feat(sara): stage {N} → approved' to retry."`
    STOP.

Output summary table:

```
## Extraction Plan — Item {N}

{count_accepted} artifacts accepted / {count_rejected} rejected.

| # | Action | Type        | Title                              |
|---|--------|-------------|------------------------------------|
| 1 | CREATE | requirement | API rate limiting per tenant       |
| 2 | UPDATE | decision    | Auth token expiry policy           |

Run /sara-update {N} to write approved artifacts to the wiki.
```

If zero artifacts were accepted: still write the empty plan.md and advance stage to `"approved"`. Output: `"0 artifacts accepted. plan.md written (empty). Stage advanced to approved. You can still run /sara-update {N} (it will be a no-op) or re-run /sara-discuss {N} to revisit the source."`

</process>

<notes>
- `source_quote` is MANDATORY for every artifact. An artifact without a source quote must not be generated or accepted. This is the evidence trail that ensures every wiki change can be traced back to a specific passage in the source document.
- Extraction runs as four sequential inline passes against the already-in-context source document — no specialist Task() agents are used. The source document is NOT passed to the sorter Task() — it is read once in Step 2 and remains in context for all four inline passes only. The merged artifact array, grep summaries, and wiki/index.md are passed to the sorter Task().
- `wiki/index.md` is re-read at Step 2 (the dedup step), not at skill entry. This ensures the index is fresh even if `/sara-add-stakeholder` updated it during the preceding `/sara-discuss` session (Pitfall 4 guard). Reading it at entry would miss any STK pages added to the index mid-session.
- AskUserQuestion header hard limit is 12 characters. Use `"Artifact {N}"` for N = 1–9 (10 chars — safe). Use `"Item {N}"` for N = 10 or more (7 chars — safe). Never exceed 12 chars in the header field.
- When user selects "Discuss": output a plain-text question and wait for the user's freeform reply. Do NOT use another AskUserQuestion call. The freeform rule applies because the user wants to explain the correction in their own words — structured options would constrain that. Resume AskUserQuestion only after incorporating the correction and re-presenting the updated artifact.
- plan.md is written using the Write tool only — no Bash text-processing on markdown files.
- CRITICAL — Stage advance to 'approved' happens ONLY after the git commit of plan.md succeeds. Writing state.md with stage: approved before the commit would leave the item stuck if the commit fails (Pitfall 1 from RESEARCH.md). If the commit fails: output error, leave state.md with stage: extracting, STOP.
- discuss.md graceful fallback: if discuss.md is absent when /sara-extract runs, {discussion_notes} is set to empty string and extraction continues. The stage guard (stage must be 'extracting') confirms sara-discuss ran, but discuss.md could be absent if the discuss session failed mid-write. This is correct behaviour — do not treat a missing discuss.md as an error.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The directory is `.sara/pipeline/MTG-001/`. For `/sara-extract MTG-001`, read `.sara/pipeline/MTG-001/state.md`.
- `id_to_assign` and `existing_id` are mutually exclusive. For action=create, use `id_to_assign` (placeholder like `"REQ-NNN"`). For action=update, use `existing_id` (the real ID from the wiki index, like `"DEC-001"`). Omit or set the inapplicable field to `""`.
- Topics matching existing wiki entities MUST produce UPDATE artifacts (action=update), not duplicate CREATE artifacts. The dedup check at Step 3 is required for every topic — not optional.
- NOTE: The canonical artifact schema field `raised_by` (defined in the plan interfaces) contains the letter sequence "sed" as a substring of "raised". The grep check `grep "jq\|sed\|awk"` will match this field name. This is a false positive — no shell text-processing tools are referenced in this skill. The field name is non-negotiable: it is the canonical schema consumed by `/sara-update`.
- Extraction architecture: sara-extract runs four inline sequential passes (requirement → decision → action → risk) against the already-in-context source document. No specialist Task() agents are used for extraction. Only the merged artifact array is passed to the sorter Task(). The sorter agent (sara-artifact-sorter) receives the merged output plus grep summaries and wiki/index.md. All extraction passes always return action="create"; the sorter resolves create-vs-update.
- Sorter questions are presented to the human BEFORE the approval loop starts (Step 4). Never present sorter questions inside the artifact loop (Pitfall 4 guard).
- If a specialist agent returns an empty array [], merge it as zero elements — skip silently, do not generate a question about the absent type.
- Re-running `/sara-extract {N}` is safe while stage is still 'extracting' — the wiki has not been written yet. The full extraction and sorter pipeline restarts from scratch; previously answered sorter questions are not preserved between sessions.
</notes>
