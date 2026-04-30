# Phase 10: refine-actions - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 3 modified skill files
**Analogs found:** 3 / 3 (exact matches from Phase 8 and Phase 9 implementations)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.claude/skills/sara-extract/SKILL.md` | skill/prompt | transform (extraction pass + approval loop) | Same file — Phase 8 requirements pass (lines 54–88) and Phase 9 decisions pass (lines 90–136) | exact |
| `.claude/skills/sara-update/SKILL.md` | skill/prompt | transform (wiki write branch) | Same file — decision write branch (lines 220–259) and requirement write branch (lines 163–218) | exact |
| `.claude/skills/sara-init/SKILL.md` | skill/config | config write (template + CLAUDE.md schema block) | Same file — decision template (lines 434–470) and requirement template (lines 368–432) | exact |

---

## Pattern Assignments

### `.claude/skills/sara-extract/SKILL.md` — Action pass rewrite (Step 3)

**Analog:** Same file, decisions pass (lines 90–136) and requirements pass (lines 54–88).

**Current action pass to replace** (lines 138–146):
```
**Actions pass**

Extract every passage that describes an action item — a concrete task or follow-up with an
implied or explicit owner (something that must be done, not a general statement of intent). For each action found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY)
- Write a short (≤10 words) imperative-phrase `title` (e.g. "Send updated proposal to client")
- Set `raised_by` to the STK-NNN ID of the person who will own the action if identifiable; otherwise `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"action"`, `id_to_assign` = `"ACT-NNN"`, `related` = `[]`, `change_summary` = `""`

Collect results as `{act_artifacts}` (JSON array; empty array if none found).
```

**Pattern to copy: positive signal definition block** (from decisions pass, lines 95–115):
```
A passage IS a decision if it contains commitment language OR misalignment language from the
signal lists below. Passages lacking both signals are NOT decisions regardless of topic.

  COMMITMENT language — these passages ARE decisions → status: accepted
  - "we decided to", "we decided on"
  ...

  EXCLUDE — these passages are NOT decisions (do NOT extract them):
  - Option exploration: "we could use X or Y" (exploring options, not choosing)
  - Aspiration/wish: "it would be good to have Z" (desire, no concluded choice or tension)
  - Requirement/obligation: "the system must support A" (system obligation, not a team choice)
```
Adapt for actions: replace "A passage IS a decision if..." with "A passage IS an action if it describes any work that needs to happen..." and supply INCLUDE/EXCLUDE examples matching D-01.

**Pattern to copy: inline type classification** (from decisions pass, lines 117–123):
```
For each decision found, classify it into one of six types inline based on what the decision is about:
  - `architectural`   — system structure, technology choices, component relationships
  - `process`         — how the team works, workflow, ceremonies, practices
  ...
```
Adapt for actions: replace with `act_type` two-value taxonomy:
```
For each action found, classify it into one of two types inline:
  - `deliverable` — a concrete output or artefact to produce (report, document, implementation, fix)
  - `follow-up`   — a check-in, response, or update required from someone (confirm, reply, chase, update)
```

**Pattern to copy: per-artifact field extraction list** (from decisions pass, lines 125–134):
```
For each decision found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any decision without a quotable passage)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable from the source or discussion_notes; otherwise use `"STK-NNN"` placeholder
- Set `status` to `"accepted"` if commitment language was detected; `"open"` if misalignment language was detected
- Set `dec_type` to one of the six types above ...
- Set `action` = `"create"`, `type` = `"decision"`, `id_to_assign` = `"DEC-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT extract `context` or `rationale` — these are synthesised by sara-update from the full source document, not extracted here
```
Adapt for actions: change `dec_type` → `act_type`, add `owner` and `due_date` fields per D-05 and D-02. The "Do NOT extract" note becomes: "Do NOT extract Description or Context — synthesised by sara-update."

**New fields to add to the per-artifact field list:**
```
- Set `act_type` to `"deliverable"` or `"follow-up"` (see classification above)
- Set `owner` to the STK-NNN ID of the person assigned to do the work if identifiable; otherwise the raw name string if a name is mentioned but not yet registered; otherwise `""`
- Set `raised_by` to the STK-NNN ID of the person who surfaced the action (may be the same as owner); otherwise `"STK-NNN"` placeholder
- Set `due_date` to the raw string from the source if a due date is mentioned (e.g. "by Friday", "EOW"); otherwise `""`
```

**Collect line pattern** (lines 146, 136):
```
Collect results as `{act_artifacts}` (JSON array; empty array if none found).
```
Keep unchanged.

---

### `.claude/skills/sara-extract/SKILL.md` — Owner warning in Step 4 approval loop

**Analog:** Step 4 approval loop, lines 217–257. The loop currently presents artifacts as plain text before `AskUserQuestion`. The warning is injected as an additional plain-text line before the `--- Artifact {N} ---` block, conditional on action type and unresolved owner.

**Pattern to copy: plain-text output before AskUserQuestion** (lines 219–227):
```
  Present the artifact as plain text before the AskUserQuestion call:
  ```
  --- Artifact {artifact_index} ---
  Type:   {type}
  Title:  {title}
  Action: CREATE new {TYPE}-NNN  /  UPDATE {existing_id}
  Source: "{source_quote}"
  [If update] Change: {change_summary}
  ```
```

**New pattern: owner warning injection (insert immediately before the plain-text block above)**:
```
  If `artifact.type == "action"` AND (`artifact.owner == ""` OR `artifact.owner` does not match
  the pattern `STK-\d{3}`):
    Output as plain text:
    ⚠ Owner not resolved — assign manually after /sara-update, or run /sara-add-stakeholder first.
```

**Placement rule (D-13 / RESEARCH Pitfall 3):** The warning is output ONCE, before the `--- Artifact {N} ---` block. It is NOT inside the Discuss retry loop. It does NOT repeat on subsequent Discuss cycles for the same artifact.

---

### `.claude/skills/sara-update/SKILL.md` — Action create branch rewrite

**Analog:** Same file, decision create branch (lines 220–259) and requirement create branch (lines 163–218).

**Current action create branch to replace** (lines 262–281):
```
**action:**
## Description
> "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

{synthesised summary of what needs to be done, who is responsible, and any relevant
 deadlines or dependencies resolved during /sara-discuss}

## Notes
{synthesised blockers, dependencies, follow-up context, or related items from discussion
 notes — leave empty if none available}

## Cross Links
{...}
```

**Pattern to copy: six-section body structure** (modelled on decisions five-section body, lines 220–259):
```
    **decision:**
    ```
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Context
    {Synthesised from {source_doc} and {discussion_notes}: why this decision was needed...}

    ## Decision
    {If artifact.status == "accepted": write artifact.chosen_option content...}

    ## Alternatives Considered
    {...}

    ## Rationale
    {...}

    ## Cross Links
    {Generate one wiki link per entry in artifact.related...}
    ```
```

**New action body structure (v2.0 replacement)**:
```
    **action:**
    ```
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Description
    [Synthesised by sara-update: 2–4 sentences describing what needs to be done, grounded in
     source quote and discussion notes]

    ## Context
    [Synthesised by sara-update: why this action was raised — triggering event, dependency, or
     decision it relates to. Leave empty (heading only) if nothing relevant — never fabricate.]

    ## Owner
    [Written from artifact.owner:
     - If artifact.owner is a valid STK-NNN ID: write "[[STK-NNN|Stakeholder Name]]" (resolve name from wiki)
     - If artifact.owner is a raw name string: write it as-is, with note "(not yet registered — run /sara-add-stakeholder)"
     - If artifact.owner is empty: write "Not assigned — set manually."]

    ## Due Date
    [Written from artifact.due_date:
     - If artifact.due_date is non-empty: write the raw string as-is (e.g. "by Friday", "EOW")
     - If artifact.due_date is empty: write "Not specified — set manually."]

    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
    ```
```

**Synthesis rule (from D-12):** Description and Context are synthesised from `{source_doc}` and `{discussion_notes}`. Owner and Due Date are written from extracted artifact fields — NOT synthesised.

**Pattern to copy: Cross Links generation** (identical pattern across requirement and decision branches, lines 212–218 and 253–259):
```
    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
```
Copy verbatim into the action create branch — this section is identical across all artifact types.

---

### `.claude/skills/sara-update/SKILL.md` — Action frontmatter field mapping (create branch)

**Analog:** Same file, lines 96–107 (current field mapping block for all artifact types).

**Current action-specific mapping** (line 99 and lines 106–107):
```
    - `schema_version` = `"1.0"` for action and risk artifacts (always double-quoted)
    ...
    - For action artifacts: set `status` = `"open"`, `owner` = `artifact.raised_by` if it is a resolved STK ID (e.g. `"STK-001"`); otherwise set `owner` = `""` (empty — leave unassigned; do not write a placeholder ID)
```

**Replacement field mapping for action artifacts (v2.0)**:
```
    - `schema_version` = `'2.0'` for action artifacts (single-quoted — matches requirement and decision convention; prevents YAML float parsing)
    - `type` = `artifact.act_type` (one of: `deliverable`, `follow-up`) — NEW
    - `owner` = `artifact.owner` (STK-NNN or raw name string or `""`) — CHANGED from `artifact.raised_by`
    - `due-date` = `artifact.due_date` (raw string or `""`) — NEW
    - For action artifacts: set `status` = `"open"`
```

**Critical change (RESEARCH Pitfall 1):** `owner` must be set from `artifact.owner`, NOT `artifact.raised_by`. The current code at line 106 uses `artifact.raised_by` — this must be explicitly changed.

**Pattern to copy: summary content rule for actions** (line 114, existing):
```
      - ACT: owner, due-date, status (open/in-progress/done/cancelled)
```
Update to include `type`: `ACT: owner, due-date, type, status` (matching D-10 summary comment).

---

### `.claude/skills/sara-update/SKILL.md` — Action update branch rewrite

**Analog:** Same file, requirement update branch (lines 321–339) and decision update branch (lines 341–376).

**Pattern to copy: update branch upgrade to v2.0** (requirement update branch, lines 321–339):
```
    For requirement artifacts (`artifact.type == "requirement"`): after applying the change_summary
    to frontmatter fields and regenerating the summary, also update the frontmatter to include
    the v2.0 fields from the artifact object:
    - Set `type` = `artifact.req_type` ...
    - Set `priority` = `artifact.priority` ...
    - Set `schema_version` = `'2.0'` (single-quoted string — prevents YAML float parsing)
    - Remove the `description` field from the frontmatter if present (it is a v1.0 field)

    Then rewrite the full body to the v2.0 structured section format ...
```

**Replacement block for action update branch**:
```
    For action artifacts (`artifact.type == "action"`): after applying the change_summary
    to frontmatter fields and regenerating the summary, also update the frontmatter to include
    the v2.0 fields from the artifact object:
    - Set `type` = `artifact.act_type` (one of: `deliverable`, `follow-up`) — add if absent
    - Set `owner` = `artifact.owner` (STK-NNN or raw name string or `""`) — REPLACE any existing value; do NOT use `artifact.raised_by`
    - Set `due-date` = `artifact.due_date` (raw string or `""`) — add if absent
    - Set `schema_version` = `'2.0'` (single-quoted string — prevents YAML float parsing)

    Then rewrite the full body to the v2.0 structured section format (Source Quote, Description,
    Context, Owner, Due Date, Cross Links) using the same synthesis rules as the create branch.
    Synthesise Description and Context from the updated frontmatter, artifact.source_quote,
    artifact.change_summary, and {discussion_notes}. Write Owner and Due Date from artifact
    fields — do NOT synthesise these sections.
```

**Pattern to copy: summary regeneration rule** (line 320, existing update branch):
```
    Regenerate the `summary` field: ... ACT: owner/due-date/status ...
```
Update to `ACT: owner/due-date/type/status` to match the new summary content rule.

---

### `.claude/skills/sara-init/SKILL.md` — CLAUDE.md action schema block (Step 9)

**Analog:** Same file, decision schema block (lines 212–248) and requirement schema block (lines 187–210).

**Current action schema block to replace** (lines 255–272):
```yaml
### Action

```yaml
---
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""  # ACT: owner, due-date, status (open/in-progress/done/cancelled)
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
schema_version: "1.0"
tags: []
related: []
---

## Description

## Notes
```
```

**Pattern to copy: v2.0 frontmatter block with comments** (from decision schema block, lines 212–248):
```yaml
### Decision

```yaml
---
id: DEC-000
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""  # DEC: options considered, chosen option, status, decision date
type: architectural  # wiki page field; artifact schema uses dec_type to avoid collision ...
                     # valid values: architectural | process | tooling | data | business-rule | organisational
date: ""          # ISO 8601 (e.g. 2026-04-29)
...
schema_version: '2.0'
...
```
```

**v2.0 replacement for action schema block in CLAUDE.md**:
```yaml
### Action

```yaml
---
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""   # ACT: owner, due-date, type, status
type: deliverable  # deliverable | follow-up
owner: ""     # STK-NNN or raw name string
due-date: ""  # raw string from source (e.g. "by Friday") or ISO date once resolved
source: []    # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---
```

Body follows the v2.0 structured section format (Source Quote, Description, Context, Owner,
Due Date, Cross Links). Description and Context are synthesised by sara-update; Owner and Due
Date are written from extracted artifact fields.
```

**Key changes from v1.0:**
- `summary` comment: add `type` before `status` (Pitfall 5 guard)
- `type` field: new, values `deliverable` or `follow-up`
- `owner` comment: changed from `# stakeholder ID (e.g. STK-001)` to `# STK-NNN or raw name string`
- `due-date` comment: changed from `# ISO 8601` to `# raw string from source...`
- `schema_version`: `"1.0"` → `'2.0'` (single quotes — Pitfall 2 guard)
- Body: `## Description` + `## Notes` → six-section structured body description

---

### `.claude/skills/sara-init/SKILL.md` — Action template (Step 12)

**Analog:** Same file, decision template (lines 434–470) and requirement template (lines 368–432).

**Current action template to replace** (lines 472–491):
```markdown
`.sara/templates/action.md`:

```markdown
---
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""  # ACT: owner, due-date, status (open/in-progress/done/cancelled)
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
schema_version: "1.0"
tags: []
related: []
---

## Description

## Notes
```
```

**Pattern to copy: template style** (from decision template, lines 434–470):
```markdown
`.sara/templates/decision.md`:

```markdown
---
id: DEC-000
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""  # DEC: options considered, chosen option, status, decision date
type: architectural  # architectural | process | tooling | data | business-rule | organisational
...
schema_version: '2.0'
...
---

## Source Quote
> [exact verbatim passage from source document] — [[STK-NNN|Stakeholder Name]]

## Context

[Synthesised by sara-update: why this decision was needed, background]

## Decision

[The chosen option — or "No decision reached — alignment required." for open decisions]

## Alternatives Considered

[List of alternatives; for open decisions, list competing positions]

## Rationale

[Synthesised by sara-update: why this option was chosen]
```
```

**v2.0 replacement for action template**:
```markdown
`.sara/templates/action.md`:

```markdown
---
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""   # ACT: owner, due-date, type, status
type: deliverable  # deliverable | follow-up
owner: ""     # STK-NNN or raw name string
due-date: ""  # raw string from source (e.g. "by Friday") or ISO date once resolved
source: []    # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---

## Source Quote
> [exact verbatim passage from source document] — [[STK-NNN|Stakeholder Name]]

## Description

[Synthesised by sara-update: 2–4 sentences describing what needs to be done, grounded in
 source quote and discussion notes]

## Context

[Synthesised by sara-update: why this action was raised — triggering event, dependency, or
 decision it relates to]

## Owner

[Written from artifact.owner — who is responsible. If empty: "Not assigned — set manually."]

## Due Date

[Raw due date string from extraction, or "Not specified — set manually." if empty]

## Cross Links
[One wiki link per related[] entry — see wikilink rule in sara-update SKILL.md]
```
```

---

## Shared Patterns

### `schema_version: '2.0'` single-quote convention
**Source:** `.claude/skills/sara-update/SKILL.md` lines 97–98 (requirement and decision branches)
**Apply to:** All three files — sara-extract artifact schema documentation, sara-update action write branch, sara-init action template and CLAUDE.md block
```
schema_version: '2.0'
```
**NOT** `"2.0"` (double-quoted) and **NOT** `2.0` (unquoted). The current action schema uses `"1.0"` — this is the v1.0 legacy form. The v2.0 form uses single quotes throughout.

### Source Quote + attribution line
**Source:** `.claude/skills/sara-update/SKILL.md` lines 133–135 (shared across all artifact types)
```
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]
```
Action v2.0 uses this same pattern for `## Source Quote`, unchanged from requirement and decision.

### Cross Links section
**Source:** `.claude/skills/sara-update/SKILL.md` lines 212–218 and 253–259 (identical in both branches)
**Apply to:** Action create and update branches
```
    ## Cross Links
    {Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
     - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
     - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
     - If title/name cannot be resolved: fall back to bare [[ID]]
     Write each link on its own line. If artifact.related is empty, write this heading with no
     content (heading-only — consistent with the established empty-section pattern for this skill).}
```
Copy verbatim — this pattern is frozen and identical across all artifact write branches.

### Sorter pass-through rule for new artifact fields
**Source:** `.claude/agents/sara-artifact-sorter.md` lines 151–154
```
For requirement artifacts, preserve `priority` and `req_type` exactly as received from the
extraction pass. Do not modify, reclassify, or drop these fields. Pass them through unchanged
to `cleaned_artifacts`.
```
Phase 10 needs an analogous rule added to the sorter's `<output_format>` rules section:
```
For action artifacts, preserve `act_type`, `owner`, and `due_date` exactly as received from
the extraction pass. Do not modify, reclassify, or drop these fields. Pass them through unchanged
to `cleaned_artifacts`.
```
**NOTE:** The sorter's generic field pass-through already handles unknown fields without a code change (confirmed from Phase 8/9 precedent). The addition above is a documentation-only update to the output_format rules — it does not change sorter behaviour. The planner should decide whether to include this as an optional sub-task.

### Wikilink rule for body prose
**Source:** `.claude/skills/sara-update/SKILL.md` lines 138–151
**Apply to:** Owner section synthesis in sara-update action branch when owner is a valid STK-NNN
```
    - STK entities: display text = name only (e.g. `[[STK-001|Rajiwath Patel]]`).
      Read `wiki/stakeholders/{ID}.md` to resolve the name.
```

---

## No Analog Found

No files in Phase 10 are entirely new — all three modified files already exist in the codebase. The action-specific owner warning and `owner`/`due_date`/`act_type` fields are new to the action artifact, but their patterns are directly derived from analogous features in requirements (`req_type`, `priority`) and decisions (`dec_type`, `status`).

---

## Critical Anti-Patterns (from RESEARCH.md)

These are load-bearing reminders for the planner — each has a named pitfall in RESEARCH.md:

| Anti-Pattern | File | Location | Fix |
|---|---|---|---|
| `owner = artifact.raised_by` | sara-update | Line 106 (create branch) + update branch equivalent | Change to `owner = artifact.owner` in both branches |
| `schema_version: "2.0"` (double-quoted) | All three files | Any new action schema block | Must be `schema_version: '2.0'` (single-quoted) |
| Owner warning inside Discuss loop | sara-extract | Step 4 approval loop | Warning output ONCE before `--- Artifact {N} ---` block, not inside retry loop |
| Update branch not upgraded | sara-update | action update branch | Must add `type`, `owner` (from `artifact.owner`), `due-date`, `schema_version: '2.0'`, six-section body |
| `summary` comment missing `type` | sara-init + sara-update | CLAUDE.md block + template | `# ACT: owner, due-date, type, status` (not `# ACT: owner, due-date, status`) |

---

## Metadata

**Analog search scope:** `.claude/skills/sara-extract/SKILL.md`, `.claude/skills/sara-update/SKILL.md`, `.claude/skills/sara-init/SKILL.md`, `.claude/agents/sara-artifact-sorter.md`, `.planning/phases/08-refine-requirements/08-CONTEXT.md`, `.planning/phases/09-refine-decisions/09-CONTEXT.md`
**Files scanned:** 6
**Pattern extraction date:** 2026-04-29
