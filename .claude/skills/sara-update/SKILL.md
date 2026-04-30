---
name: sara-update
description: "Execute approved extraction plan — write wiki artifacts and commit atomically"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
version: 1.0.0
---

<objective>
Reads the approved extraction plan from `pipeline-state.json` and writes all wiki artifacts (create or update) plus `wiki/index.md` and `wiki/log.md` in a single atomic git commit. Stage advances to `complete` only after the commit succeeds. The source file is already at its permanent path (`item.source_path`) — it was moved and committed by `/sara-ingest`.
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
  Output: `"Extraction plan for item {N} is empty — no wiki files to write."`
  Set `written_files = []` and `count = 0`.
  Update `items["{N}"].stage` = `"complete"` in memory.
  Write the updated `.sara/pipeline-state.json` using the Write tool.
  Run:
  ```bash
  git add .sara/pipeline-state.json
  git commit -m "feat(sara): wiki {N} — 0 artifacts (empty plan)"
  echo "EXIT:$?"
  ```
  Output: `"Item {N} stage advanced to complete. No artifacts were written."`
  STOP.

**Step 1b — Load source document and discussion notes**

Read `{item.source_path}` using the Read tool. Store as `{source_doc}`.

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
    - `risk`        → `RSK`

    Increment `counters.entity.{entity_type_key}` by 1 in the in-memory JSON state (do NOT re-read `pipeline-state.json` — the counters loaded in Step 1 are kept current in memory across loop iterations; each Write call below persists the latest state).

    Write the updated `pipeline-state.json` immediately using the Write tool (the counter increment MUST be persisted before the page is written — this prevents duplicate ID assignment if a page write fails and the skill is re-run).

    Compute `{assigned_id}` = `"{entity_type_key}-"` + zero-padded 3-digit counter (e.g. counter = 1 → `"REQ-001"`).

    Read `.sara/templates/{artifact.type}.md` using the Read tool to get the template structure.

    Construct the wiki page content by substituting all fields from the artifact into the template frontmatter and body:
    - `id` = `{assigned_id}`
    - `title` = `artifact.title`
    - `source` = `[{item.id}]` (single-element YAML list, e.g. `[MTG-001]`)
    - `raised-by` = `artifact.raised_by` (note: template field is `raised-by`; artifact schema field is `raised_by`)
    - `related` = `artifact.related` (array of entity IDs)
    - `schema_version` = `'2.0'` for decision artifacts (single-quoted — prevents YAML float parsing; consistent with requirement schema established in Phase 8)
    - For requirement artifacts: set `schema_version` = `'2.0'` (single-quoted — same convention as decisions)
    - `schema_version` = `'2.0'` for action artifacts (single-quoted — matches requirement and decision convention; prevents YAML float parsing)
    - `schema_version` = `'2.0'` for risk artifacts (single-quoted — prevents YAML float parsing; consistent with requirement, decision, action convention)
    - `type` = `artifact.req_type` for requirement artifacts (one of: functional, non-functional, regulatory, integration, business-rule, data)
    - `type` = `artifact.dec_type` for decision artifacts (one of: architectural, process, tooling, data, business-rule, organisational)
    - `priority` = `artifact.priority` for requirement artifacts (one of: must-have, should-have, could-have, wont-have)
    - For decision artifacts: set `status` = `artifact.status` (either `"accepted"` or `"open"` from the extraction pass — NEVER hardcode `"proposed"`), `date` = today's ISO date
    - For decision artifacts: do NOT write `context`, `decision`, `rationale`, or `alternatives-considered` frontmatter fields — these are v1.0 fields removed in schema v2.0
    - For requirement artifacts: set `status` = `"open"`; do not set `description` (v1.0 field — not present in v2.0 frontmatter)
      - `segments` = `artifact.segments` (array of segment name strings; write as flow-style YAML:
        `segments: []` for empty, `segments: [Residential]` for one entry,
        `segments: [Residential, Enterprise]` for two; use block style only if the array has 3+
        entries — consistent with `tags`, `related`, `source` in existing templates)
    - For decision artifacts: leave `deciders` = `[]` (the template default) — the pipeline does not populate this field. Users must fill it in manually after the page is created.
      - `segments` = `artifact.segments` (array of segment name strings; write as flow-style YAML:
        `segments: []` for empty, `segments: [Residential]` for one entry,
        `segments: [Residential, Enterprise]` for two; use block style only if the array has 3+
        entries — consistent with `tags`, `related`, `source` in existing templates)
    - For action artifacts: set `status` = `"open"`, `type` = `artifact.act_type` (one of: `deliverable`, `follow-up`), `owner` = `artifact.owner` (STK-NNN or raw name string or `""`), `due-date` = `artifact.due_date` (raw string or `""`)
      - `segments` = `artifact.segments` (array of segment name strings; write as flow-style YAML:
        `segments: []` for empty, `segments: [Residential]` for one entry,
        `segments: [Residential, Enterprise]` for two; use block style only if the array has 3+
        entries — consistent with `tags`, `related`, `source` in existing templates)
    - For risk artifacts: set `type` = `artifact.risk_type` (one of: technical, financial, schedule, quality, compliance, people); set `owner` = `artifact.owner` (STK-NNN or raw name string or `""`); set `raised-by` = `artifact.raised_by` (note: template field is `raised-by`; artifact schema field is `raised_by`); set `likelihood` = `artifact.likelihood` (`"high"`, `"medium"`, `"low"`, or `""`); set `impact` = `artifact.impact` (`"high"`, `"medium"`, `"low"`, or `""`); set `status` = `artifact.status` (`"open"`, `"mitigated"`, or `"accepted"` — signal-based from extraction; default is `"open"`). Do NOT write a `mitigation:` frontmatter field — it is removed in v2.0.
      - `segments` = `artifact.segments` (array of segment name strings; write as flow-style YAML:
        `segments: []` for empty, `segments: [Residential]` for one entry,
        `segments: [Residential, Enterprise]` for two; use block style only if the array has 3+
        entries — consistent with `tags`, `related`, `source` in existing templates)
    - All other fields not supplied by the artifact: use the template default value (empty string `""` or empty array `[]`)
    - Read `summary_max_words` from the already-loaded pipeline-state.json (field: `summary_max_words`). If the field is absent, use 50 as the default.
    - `summary` = LLM-generated prose string within `summary_max_words` words. Write type-appropriate content:
      - REQ: title, status, one-line description of what is required
      - DEC (status=accepted): options considered, chosen option, status: accepted, decision date
      - DEC (status=open): competing options/positions, alignment not reached, status: open, decision date
      - ACT: owner, due-date, type, status
      - RSK: likelihood, impact, type, status, mitigation approach
      - STK: segment, department, role — enough to distinguish from other stakeholders
      Generate the summary from the artifact fields already set (title, status, owner, etc.) and `{discussion_notes}`. Write it as a single prose string — not a list, not bullet points.

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
    - REQ / DEC / ACT / RSK entities: display text = `{ID} {title}` (e.g.
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
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Statement
    {Synthesise a precise "The [subject] shall [verb phrase]." statement from the source_quote and
     discussion_notes. Use the commitment modal from the source to determine the statement's strength.
     Write one sentence in the form: "The [system/role] shall [action/behaviour/constraint]."}

    ## User Story
    {Apply the section matrix for artifact.req_type:
     - functional → REQUIRED: write "As a [role], I want [capability], so that [benefit]."
     - non-functional → OPTIONAL: write only if a user-facing perspective is natural (e.g. usability NFR).
       If not natural, omit this section header entirely — do not write an empty heading.
     - integration → OPTIONAL: write only if a developer or end-user perspective is clear.
       If not natural, omit this section header entirely — do not write an empty heading.
     - regulatory, business-rule, data → OMIT: do not write this section header at all.}

    ## Acceptance Criteria
    {REQUIRED for all types — derive at least one testable criterion directly from the source_quote.
     Infer what "done" looks like from the title and source_quote. Format as a markdown checklist:
     - [ ] {criterion}
     Add further criteria for any conditions or constraints from source or discussion_notes.}

    ## BDD Criteria
    {Apply the section matrix for artifact.req_type:
     - functional → REQUIRED: write one happy-path Gherkin scenario.
     - business-rule → REQUIRED: write one happy-path Gherkin scenario (Gherkin is most natural here).
     - integration → OPTIONAL: write if an API contract scenario is natural for this requirement.
     - non-functional, regulatory, data → OMIT: do not write this section header at all.
     Add additional scenarios ONLY when the requirement explicitly has distinct, named edge cases.
     Format:
     **Scenario: [name]**
     Given [context]
     When [action]
     Then [outcome]
     If omitting, leave this section header absent entirely — do not write an empty heading.}

    ## Context
    {Apply the section matrix for artifact.req_type:
     - functional → OPTIONAL: include only when there is non-obvious rationale or design constraint
       not captured in Statement or Source Quote. If nothing relevant, leave empty (heading only).
     - non-functional, regulatory, integration, business-rule, data → REQUIRED: write rationale,
       background, or constraints not captured in Statement or Source Quote. Why this quality target,
       mandate, integration contract, domain rule, or data policy exists. Leave empty (heading only)
       if nothing is available from source or discussion_notes — never fabricate.}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
    ```

    **decision:**
    ```
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Context
    {Synthesised from {source_doc} and {discussion_notes}: why this decision was needed,
     what problem or situation prompted it, relevant background. Leave empty (heading only)
     if nothing relevant is available — never fabricate.}

    ## Decision
    {If artifact.status == "accepted": write artifact.chosen_option content — the option
     or approach the team selected. If artifact.chosen_option is an empty string, write:
     "[Option not captured — review source document and update manually.]"
     Do not synthesise a decision that is not grounded in source_doc or discussion_notes.
     If artifact.status == "open": write exactly "No decision reached — alignment required."}

    ## Alternatives Considered
    {If artifact.status == "accepted": if artifact.alternatives is a non-empty array, list
     each alternative on its own line with a dash prefix, then expand with synthesis if
     the source document or discussion notes mention why each alternative was not chosen.
     If artifact.alternatives is [], write this heading with no content (heading only).
     If artifact.status == "open": list the competing positions detected in the source.
     Each position on its own line with a dash prefix. Example:
     - Position A: [view expressed by stakeholder or group]
     - Position B: [opposing view]}

    ## Rationale
    {Synthesised from {source_doc} and {discussion_notes}: for accepted decisions, why
     this option was chosen over the alternatives. For open decisions, why alignment has
     not been reached (what is blocking agreement). Leave empty (heading only) if nothing
     relevant is available — never fabricate.}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
    ```

    **action:**
    ```
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Description
    {Synthesised from {source_doc} and {discussion_notes}: 2–4 sentences describing what needs
     to be done. Ground the description in the source quote. Leave empty (heading only) if
     nothing relevant is available — never fabricate.}

    ## Context
    {Synthesised from {source_doc} and {discussion_notes}: why this action was raised —
     triggering event, dependency, or decision it relates to. Leave empty (heading only)
     if nothing relevant is available — never fabricate.}

    ## Owner
    {Written from artifact.owner — NOT synthesised:
     - If artifact.owner is a valid STK-NNN ID (matches pattern STK-\d{3}): write "[[STK-NNN|Stakeholder Name]]" — read wiki/stakeholders/{artifact.owner}.md to resolve the name.
     - If artifact.owner is a raw name string (not empty, not STK-NNN): write it as-is with note "(not yet registered — run /sara-add-stakeholder)"
     - If artifact.owner is empty ("" or absent): write "Not assigned — set manually."}

    ## Due Date
    {Written from artifact.due_date — NOT synthesised:
     - If artifact.due_date is non-empty: write the raw string as-is (e.g. "by Friday", "EOW")
     - If artifact.due_date is empty ("" or absent): write "Not specified — set manually."}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
    ```

    **risk:**
    ```
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Risk

    IF <trigger condition> THEN <adverse event>

    {Synthesised by sara-update from {source_doc} and {discussion_notes}: write the risk as a
     single IF/THEN statement. IF and THEN are written in caps; the rest is sentence case.
     The trigger condition (IF clause) describes what must happen or fail for the risk to
     materialise. The adverse event (THEN clause) describes the negative outcome.
     Example: IF the integration vendor delays API delivery THEN the go-live milestone slips by 4+ weeks.
     Ground the statement in the source_quote and surrounding context. Never fabricate conditions
     not supported by the source.}

    ## Mitigation

    {Synthesised by sara-update from {source_doc} and {discussion_notes}: describe controls,
     contingencies, or mitigation approaches explicitly mentioned. If nothing was discussed,
     write exactly: "No mitigation discussed — define action items to address this risk."
     Never fabricate mitigation that is not grounded in {source_doc} or {discussion_notes}.}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
    ```

    Use the Write tool to create `{wiki_dir}{assigned_id}.md`.
    If write succeeds: append `{wiki_dir}{assigned_id}.md` to `written_files`.
    If write fails: append `{wiki_dir}{assigned_id}.md` to `failed_files`. Output the partial failure report (see format below). STOP.

  **If `artifact.action == "update"`:**

    Read the existing file `{wiki_dir}{artifact.existing_id}.md` using the Read tool.
    If the Read tool returns an error or empty content:
      Output: `"Cannot update {artifact.existing_id}: file not found at {wiki_dir}{artifact.existing_id}.md"`
      Append `{wiki_dir}{artifact.existing_id}.md` to `failed_files`.
      Output the partial failure report and STOP.
    Apply `artifact.change_summary` to the relevant field(s) in the frontmatter or body. Update the `source` field: if it is currently a scalar string, convert it to a single-element YAML list. Append `{item.id}` to the list if not already present. Result format: `source: [MTG-001, MTG-003]`. Update the `related` field by merging `artifact.related` with the existing related array (deduplicating by entity ID).
    Regenerate the `summary` field: read `summary_max_words` from pipeline-state.json (already in memory; default 50 if absent). Generate a fresh summary prose string using the same type-specific content rules as the create branch — REQ: title/status/description; DEC: options/chosen option/status/date; ACT: owner/due-date/type/status; RSK: likelihood, impact, type, status, mitigation approach; STK: segment, department, role. Replace the existing `summary` value in the frontmatter with the newly generated string.
    For requirement artifacts (`artifact.type == "requirement"`): after applying the change_summary
    to frontmatter fields and regenerating the summary, also update the frontmatter to include
    the v2.0 fields from the artifact object:
    - Set `type` = `artifact.req_type` (one of: functional, non-functional, regulatory, integration, business-rule, data)
    - Set `priority` = `artifact.priority` (one of: must-have, should-have, could-have, wont-have)
    - Set `schema_version` = `'2.0'` (single-quoted string — prevents YAML float parsing)
    - Set `segments` = `artifact.segments` (array; replace existing value if present; write in
      flow style for 0–2 entries, block style for 3+ — consistent with `tags`, `related`, `source`)
    - Remove the `description` field from the frontmatter if present (it is a v1.0 field)

    Then rewrite the full body to the v2.0 structured section format (Source Quote, Statement,
    User Story, Acceptance Criteria, BDD Criteria, Context, Cross Links) using the same synthesis
    rules as the create branch. Synthesise section content from the updated frontmatter,
    artifact.source_quote, artifact.change_summary, and {discussion_notes}. Apply the section
    matrix (per artifact.req_type) to determine which sections to include and which to omit.

    The Cross Links section is always written last. Generate one wiki link per entry in
    artifact.related (after merging with the existing related[] array). Use the wikilink rule:
    STK → [[STK-NNN|name]], REQ/DEC/ACT/RSK → [[ID|ID Title]], fallback to [[ID]] if
    title/name cannot be resolved. Write each link on its own line. Write heading only if
    artifact.related is empty after merge.

    For decision artifacts (`artifact.type == "decision"`): after applying the change_summary
    to frontmatter fields and regenerating the summary, also update the frontmatter to include
    the v2.0 fields from the artifact object:
    - Set `type` = `artifact.dec_type` (one of: architectural, process, tooling, data, business-rule, organisational)
    - Set `status` = `artifact.status`. Valid values: `"accepted"` or `"open"` only. Do NOT keep any existing `"proposed"` value from the existing page. If `artifact.status` is `"proposed"` or any other unexpected value, default to `"open"` and log a warning: `"Artifact {title} had invalid status '{value}' — defaulted to 'open'."`
    - Set `schema_version` = `'2.0'` (single-quoted string — prevents YAML float parsing)
    - Set `segments` = `artifact.segments` (array; replace existing value if present; write in
      flow style for 0–2 entries, block style for 3+ — consistent with `tags`, `related`, `source`)
    - Remove the following v1.0 frontmatter fields if present: `context`, `decision`, `rationale`, `alternatives-considered`
    - Add `source: [{item.id}]` if not already present (convert scalar source field to list following existing update branch source-field rule)

    Then rewrite the full body to the v2.0 structured section format using the same synthesis
    rules as the create branch:
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Context
    {Synthesised from {source_doc}, {discussion_notes}, and artifact.change_summary: updated
     background for why this decision exists. Never fabricate.}

    ## Decision
    {If artifact.status == "accepted": write artifact.chosen_option content.
     If artifact.chosen_option is an empty string, write:
     "[Option not captured — review source document and update manually.]"
     Do not synthesise a decision that is not grounded in source_doc or discussion_notes.
     If artifact.status == "open": write "No decision reached — alignment required."}

    ## Alternatives Considered
    {If artifact.status == "accepted": list from artifact.alternatives (non-empty) or heading-only.
     If artifact.status == "open": list competing positions from source.}

    ## Rationale
    {Synthesised from {source_doc} and {discussion_notes}: why this option was chosen or
     why alignment was not reached. Leave empty (heading only) if nothing relevant — never fabricate.}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related (after merging with the existing
     related[] array). Use the wikilink rule: STK → [[STK-NNN|name]], REQ/DEC/ACT/RSK →
     [[ID|ID Title]], fallback to [[ID]] if title/name cannot be resolved.
     Write each link on its own line. Write heading only if artifact.related is empty after merge.}

    Use the Write tool to overwrite `{wiki_dir}{artifact.existing_id}.md` with the updated content.
    If write succeeds: append `{wiki_dir}{artifact.existing_id}.md` to `written_files`.
    If write fails: append `{wiki_dir}{artifact.existing_id}.md` to `failed_files`. Output the partial failure report (see format below). STOP.

    For action artifacts (`artifact.type == "action"`): after applying the change_summary
    to frontmatter fields and regenerating the summary, also update the frontmatter to include
    the v2.0 fields from the artifact object:
    - Set `type` = `artifact.act_type` (one of: `deliverable`, `follow-up`) — add if absent
    - Set `owner` = `artifact.owner` (STK-NNN or raw name string or `""`) — REPLACE any existing value; do NOT use `artifact.raised_by`
    - Set `due-date` = `artifact.due_date` (raw string or `""`) — add if absent
    - Set `schema_version` = `'2.0'` (single-quoted string — prevents YAML float parsing)
    - Set `segments` = `artifact.segments` (array; replace existing value if present; write in
      flow style for 0–2 entries, block style for 3+ — consistent with `tags`, `related`, `source`)

    Then rewrite the full body to the v2.0 structured section format (Source Quote, Description,
    Context, Owner, Due Date, Cross Links) using the same synthesis rules as the create branch.
    Synthesise Description and Context from the updated frontmatter, artifact.source_quote,
    artifact.change_summary, and {discussion_notes}. Write Owner and Due Date from artifact
    fields — do NOT synthesise these sections.

    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Description
    {Synthesised from {source_doc}, {discussion_notes}, and artifact.change_summary: updated
     summary of what needs to be done. Ground in source quote. Never fabricate.}

    ## Context
    {Synthesised from {source_doc}, {discussion_notes}: why this action was raised, including
     any new context from artifact.change_summary. Leave empty (heading only) if nothing
     relevant — never fabricate.}

    ## Owner
    {Written from artifact.owner — NOT synthesised:
     - If valid STK-NNN ID: write "[[STK-NNN|Stakeholder Name]]"
     - If raw name string: write as-is with "(not yet registered — run /sara-add-stakeholder)"
     - If empty: write "Not assigned — set manually."}

    ## Due Date
    {Written from artifact.due_date — NOT synthesised:
     - If non-empty: write the raw string as-is
     - If empty: write "Not specified — set manually."}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related (after merging with the existing
     related[] array). Use the wikilink rule: STK → [[STK-NNN|name]], REQ/DEC/ACT/RSK →
     [[ID|ID Title]], fallback to [[ID]] if title/name cannot be resolved.
     Write each link on its own line. Write heading only if artifact.related is empty after merge.}

    Use the Write tool to overwrite `{wiki_dir}{artifact.existing_id}.md` with the updated content.
    If write succeeds: append `{wiki_dir}{artifact.existing_id}.md` to `written_files`.
    If write fails: append `{wiki_dir}{artifact.existing_id}.md` to `failed_files`. Output the partial failure report (see format below). STOP.

    For risk artifacts (`artifact.type == "risk"`): after applying the change_summary
    to frontmatter fields and regenerating the summary, also update the frontmatter to include
    the v2.0 fields from the artifact object:
    - Set `type` = `artifact.risk_type` (one of: technical, financial, schedule, quality, compliance, people) — add if absent
    - Set `owner` = `artifact.owner` (STK-NNN or raw name string or `""`) — REPLACE any existing value; do NOT use `artifact.raised_by`
    - Set `raised-by` = `artifact.raised_by` — add if absent (note: template field is `raised-by`; artifact field is `raised_by`)
    - Set `likelihood` = `artifact.likelihood` (`"high"`, `"medium"`, `"low"`, or `""`) — add or replace
    - Set `impact` = `artifact.impact` (`"high"`, `"medium"`, `"low"`, or `""`) — add or replace
    - Set `status` = `artifact.status` (`"open"`, `"mitigated"`, or `"accepted"`) — replace any existing value
    - Set `schema_version` = `'2.0'` (single-quoted string — prevents YAML float parsing)
    - Set `segments` = `artifact.segments` (array; replace existing value if present; write in
      flow style for 0–2 entries, block style for 3+ — consistent with `tags`, `related`, `source`)
    - Remove the `mitigation` frontmatter field if present (it is a v1.0 field removed in schema v2.0)

    Then rewrite the full body to the v2.0 structured section format (Source Quote, Risk, Mitigation,
    Cross Links) using the same synthesis rules as the create branch:

    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Risk

    IF <trigger condition> THEN <adverse event>

    {Synthesised from {source_doc}, {discussion_notes}, and artifact.change_summary: updated
     IF/THEN risk statement with IF and THEN in caps. Revise the trigger condition and adverse
     event based on any new information from change_summary. Never fabricate conditions not
     grounded in {source_doc} or {discussion_notes}.}

    ## Mitigation

    {Synthesised from {source_doc}, {discussion_notes}, and artifact.change_summary: updated
     controls, contingencies, or mitigation approaches. If nothing relevant: "No mitigation discussed — define action items to address this risk." Never fabricate.}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related (after merging with the existing
     related[] array). Use the wikilink rule: STK → [[STK-NNN|name]], REQ/DEC/ACT/RSK →
     [[ID|ID Title]], fallback to [[ID]] if title/name cannot be resolved.
     Write each link on its own line. Write heading only if artifact.related is empty after merge.}

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

**Index — CREATE artifacts:** For each artifact with `action == "create"`, append its row directly using Bash (no file read needed):
```bash
printf '%s\n' "| [[{assigned_id}]] | {artifact.title} | open | {artifact.type} | [] | {today YYYY-MM-DD} |" >> wiki/index.md
```
Note: The `Type` column uses `artifact.type` (the entity class: `requirement`, `decision`, `action`, or `risk`). Never use `artifact.req_type` or `artifact.dec_type` (sub-classifications) in this column — they are not appropriate for the index. This ensures homogeneity across all entity types.

**Index — UPDATE artifacts:** If any artifacts have `action == "update"`, read `wiki/index.md` once using the Read tool, then use the Edit tool to update the `Last Updated` column in each affected row (find the row by `{artifact.existing_id}`, replace only the date cell). Perform all UPDATE row edits before proceeding. If no UPDATE artifacts exist, skip this read entirely.

**Log — append entry:** Append the log row using Bash (no file read needed):
```bash
printf '%s\n' "| [[{item.id}]] | {today YYYY-MM-DD} | {item.type} | {item.filename} | {comma-separated [[ID]] wikilinks for all artifact IDs written} |" >> wiki/log.md
```

**Step 4 — Commit, advance stage, and report**

Run the git add and commit in a single Bash block. Capture the exit code:

```bash
git add wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ \
        wiki/index.md wiki/log.md \
        .sara/pipeline-state.json
git commit -m "feat(sara): wiki {item.id} — {count} artifacts"
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

  Item {N} ({item.id}) is now complete.
  ```

After outputting the "Update Complete" block, immediately invoke `/sara-lint` with no
arguments. Do not prompt the user — lint runs automatically as the final action of every
successful sara-update run. The user sees the lint output inline as the last part of the
sara-update session.

Output before invoking:
```
Running /sara-lint to curate related[] and Cross Links...
```

Then invoke `/sara-lint`.

If `/sara-lint` exits with an error or the wiki guard (Step 1 of sara-lint) fires: output
the lint error message and STOP. The sara-update is already complete — the wiki commit and
stage=complete write are final. The user can re-run `/sara-lint` independently to address
any lint issues. Do NOT re-run sara-update or reverse any state changes.

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
- CRITICAL: Entity counter increments happen BEFORE each create-action page write, and the updated counter is written to `pipeline-state.json` immediately (as a separate Write call before the page Write call). This prevents duplicate ID assignment if a page write fails and the skill is re-run. Counters are tracked in-memory across loop iterations — the in-memory state is authoritative after each Write; do NOT re-read `pipeline-state.json` inside the loop.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The JSON key in `items` is that same ID string. For `/sara-update MTG-001`, look up `items["MTG-001"]`. The `item.id` field equals the key — it appears in the commit message, the `source` field of written pages, and the log entry.
- Source file location: the source file was moved to its permanent path by `/sara-ingest` and committed at that time. Use `{item.source_path}` (stored in `pipeline-state.json`) to read it. Do NOT look in `raw/input/` — the file is no longer there.
- Do NOT auto-rollback on partial failure (D-14). The user has full git history. Report which files were written and which were not; let the user decide whether to `git reset` or re-run `/sara-update {N}` after fixing the root cause. The written files are uncommitted changes — no commit was made.
- `schema_version` must be quoted to prevent Obsidian's YAML parser from treating it as a float. All artifact types (requirement, decision, action, risk) → `'2.0'` (single-quoted).
- `related` fields must use entity IDs only (e.g. `REQ-001`, `DEC-003`) — never file paths, relative links, or Obsidian `[[wiki-links]]`. This is a Phase 1 behavioral rule carried forward.
- The `raised_by` field in the artifact schema (written by `/sara-extract`) maps to the `raised-by` field in wiki page frontmatter (defined in the entity templates). The hyphen vs underscore difference is intentional: `raised_by` is the JSON field name in `pipeline-state.json`; `raised-by` is the YAML field name in wiki pages. Apply the mapping in Step 2 when substituting template fields.
- `segment` and `department` are always separate fields in stakeholder pages — never merged. This is a locked domain constraint.
- `extraction_plan` may be empty (all artifacts rejected during `/sara-extract`). If non-empty check fails at Step 1, stop early with the re-run message. If it passes but the loop produces no writes, the git commit will still include `pipeline-state.json` (stage advance).
- pipeline-state.json is read and written using Read and Write tools only — never Bash shell text-processing tools.
- NOTE: The canonical artifact schema field `raised_by` (defined in the plan interfaces and written by `/sara-extract`) contains the letter sequence "sed" as a substring of "raised". Any grep check for `jq\|sed\|awk` will match this field name. This is a false positive — no shell text-processing tools are referenced in this skill. The field name is non-negotiable: it is the canonical schema consumed here from `/sara-extract`.
</notes>
