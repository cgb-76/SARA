# Phase 9: refine-decisions - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 4 modified files
**Analogs found:** 4 / 4 (all are exact same-file modifications — Phase 8 changes to same files are the primary analog)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-extract/SKILL.md` (Step 3 decisions pass) | prompt / extraction-config | transform | Same file, requirements pass (lines 54–87) | exact — same inline extraction pattern, different entity |
| `.claude/skills/sara-update/SKILL.md` (Step 2 decision create + update branch) | prompt / write-config | request-response | Same file, requirement create branch (lines 148–202) and requirement update branch (lines 269–290) | exact — same write pattern, different entity |
| `.claude/skills/sara-init/SKILL.md` (Step 9 CLAUDE.md block + Step 12 template) | config / template | config | Same file, requirement schema block (lines 188–203) and requirement template (lines 355–417) | exact — same schema block + template pattern |
| `.claude/agents/sara-artifact-sorter.md` (output_format decision object + passthrough rule) | agent / config | transform | Same file, requirement passthrough rule (lines 131–134) and requirement object example (lines 96–98) | exact — same passthrough rule pattern |

---

## Pattern Assignments

### `.claude/skills/sara-extract/SKILL.md` — Step 3 Decisions Pass Rewrite

**Analog:** Same file, requirements pass (lines 54–97)

**Current decisions pass (lines 89–97) — the block to REPLACE:**
```
**Decisions pass**

Extract every passage that describes a decision — a deliberate choice made by the team that was
concluded, not just discussed ("we will use X" is a decision; "we could use X" is not). For each
decision found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable; otherwise `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"decision"`, `id_to_assign` = `"DEC-NNN"`, `related` = `[]`,
  `change_summary` = `""`

Collect results as `{dec_artifacts}` (JSON array; empty array if none found).
```

**Pattern to copy from — requirements pass two-signal structure (lines 54–87):**
```
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
  - Observation: "Users are currently frustrated with slow load times" ...
  - Aspiration/wish: "It would be great if the system handled more users" ...
  - Background context: "The company processes approximately 10,000 invoices per month" ...

For each requirement found, classify it into one of six types inline based on what the requirement
describes:
  - `functional`     — a capability the system performs
  ...

For each requirement found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any requirement without
  a quotable passage)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable from the source or discussion_notes; otherwise
  use `"STK-NNN"` placeholder
- Set `priority` to the MoSCoW value derived from the commitment modal (see INCLUDE list above)
- Set `req_type` to one of the six types above
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`, `related` =
  `[]`, `change_summary` = `""`
...

Collect results as `{req_artifacts}` (JSON array; empty array if none found).
```

**Replacement decisions pass — copy this structure, substituting decisions domain:**

Apply the requirements pass pattern exactly, with these substitutions:
- INCLUDE block → two signal groups (commitment language → `status: accepted`; misalignment language → `status: open`)
- EXCLUDE block → three negative examples: option exploration, aspiration/wish, requirement/obligation language
- Inline classification → six `dec_type` values (same six-value list structure as `req_type`)
- Per-artifact fields:
  - `source_quote` (MANDATORY)
  - `title` (≤10 words noun-phrase)
  - `raised_by`
  - `status` (from signal detected: `"accepted"` or `"open"`)
  - `dec_type` (one of six taxonomy values — use `dec_type` not `type` to avoid envelope collision)
  - `chosen_option` (selected option for commitment-language decisions; `""` for open decisions)
  - `alternatives` (array of alternatives if mentioned; `[]` if none)
  - `action` = `"create"`, `type` = `"decision"`, `id_to_assign` = `"DEC-NNN"`, `related` = `[]`, `change_summary` = `""`
- Collect as `{dec_artifacts}` (JSON array; empty array if none found)

**Field naming note:** Use `dec_type` in the artifact JSON (following the `req_type` precedent). sara-update maps `artifact.dec_type` → frontmatter `type`, exactly as it maps `artifact.req_type` → frontmatter `type` for requirements.

---

### `.claude/skills/sara-update/SKILL.md` — Step 2 Decision Create Branch

**Analog:** Same file, requirement create branch (lines 86–91 for frontmatter, lines 148–203 for body)

**Current frontmatter logic for decisions (line 90) — the line to REPLACE:**
```
    - For decision artifacts: set `status` = `"proposed"`, `date` = today's ISO date
```

**Pattern to copy from — requirement frontmatter field mapping (lines 87–91):**
```
    - `schema_version` = `"1.0"` for decision, action, and risk artifacts (always double-quoted);
      `schema_version` = `'2.0'` for requirement artifacts (single-quoted — prevents YAML float
      parsing)
    - `type` = `artifact.req_type` for requirement artifacts (one of: functional, non-functional,
      regulatory, integration, business-rule, data)
    - `priority` = `artifact.priority` for requirement artifacts (one of: must-have, should-have,
      could-have, wont-have)
    - For decision artifacts: set `status` = `"proposed"`, `date` = today's ISO date
```

**Replacement frontmatter rules for decision artifacts — apply this pattern:**
```
    - `schema_version` = `'2.0'` for decision artifacts (single-quoted — consistent with
      requirement schema established in Phase 8; prevents YAML float parsing)
    - `type` = `artifact.dec_type` for decision artifacts (one of: architectural, process, tooling,
      data, business-rule, organisational)
    - For decision artifacts: set `status` = `artifact.status` (either `"accepted"` or `"open"` —
      from extraction pass; never hardcode `"proposed"`), `date` = today's ISO date
    - Remove: `context`, `decision`, `rationale`, `alternatives-considered` frontmatter fields
      (do not write these for v2.0 decision artifacts)
```

**Current decision body block (lines 205–224) — the block to REPLACE:**
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
```

**Pattern to copy from — requirement body block (lines 148–203):**

The requirement body shows the model: a Source Quote section first (verbatim blockquote with stakeholder attribution), followed by synthesised sections in a defined order, with conditional section logic. Apply the same pattern to decisions:

```
    **decision:**
    ```
    ## Source Quote
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

    ## Context
    {Synthesised from {source_doc} and {discussion_notes}: why this decision was needed,
     background context. Leave empty (heading only) if nothing relevant is available —
     never fabricate.}

    ## Decision
    {If artifact.status == "accepted": write artifact.chosen_option content.
     If artifact.status == "open": write "No decision reached — alignment required."}

    ## Alternatives Considered
    {If artifact.status == "accepted": list from artifact.alternatives field, expanded
     with synthesis if alternatives are mentioned in source or discussion_notes. Leave
     empty (heading only) if artifact.alternatives is [].
     If artifact.status == "open": list the competing positions detected in the source.}

    ## Rationale
    {Synthesised from {source_doc} and {discussion_notes}: why this option was chosen
     over the alternatives (for accepted decisions), or why alignment has not been
     reached (for open decisions). Leave empty (heading only) if nothing relevant —
     never fabricate.}
    ```
```

**Wikilink attribution pattern (lines 118–120) — copy verbatim for Source Quote:**
```
    Quote format (standard markdown blockquote, stakeholder linked to their wiki page):
    ```
    > "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]
    ```
```

**Decision update branch (lines 260–290) — also requires the body rewrite:**

The requirement update branch (lines 269–290) shows the pattern: after applying change_summary to frontmatter, rewrite the full body to the v2.0 structured section format using the same synthesis rules as the create branch. Apply this same full-body-rewrite pattern to the decision update branch:
- Set `type` = `artifact.dec_type`
- Set `schema_version` = `'2.0'` (single-quoted)
- Remove `context`, `decision`, `rationale`, `alternatives-considered` frontmatter fields
- Rewrite the full body to v2.0 five-section layout (Source Quote, Context, Decision, Alternatives Considered, Rationale)

**Summary field rule for decisions (line 99) — update the variant for `open` decisions:**
```
      - DEC: options considered, chosen option/recommendation, status, decision date
```
For `status: open` decisions, generate the summary as: "competing options/positions, alignment not reached, status: open, decision date" (the "chosen option" part becomes N/A; replace with "alignment not reached").

---

### `.claude/skills/sara-init/SKILL.md` — Step 9 CLAUDE.md Block + Step 12 Decision Template

**Analog:** Same file — requirement schema block in Step 9 (lines 188–203) and requirement template in Step 12 (lines 355–417)

**Current decision schema block in CLAUDE.md (lines 214–237) — the block to REPLACE:**
```yaml
### Decision

```yaml
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
summary: ""  # DEC: options considered, chosen option/recommendation, status, decision date
context: ""
decision: ""
rationale: ""
alternatives-considered: ""
date: ""          # ISO 8601 (e.g. 2026-04-27)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
schema_version: "1.0"
tags: []
related: []
---

## Context

## Decision

## Rationale

## Alternatives Considered
```
```

**Pattern to copy from — requirement schema block (lines 188–203):**
```yaml
### Requirement

```yaml
---
id: REQ-000
title: ""
summary: ""  # REQ: title, status, one-line description of what is required
status: open  # open | accepted | rejected | superseded
type: functional  # functional | non-functional | regulatory | integration | business-rule | data
priority: must-have  # must-have | should-have | could-have | wont-have
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
raised-by: ""  # stakeholder ID (e.g. STK-001)
owner: ""      # stakeholder ID (e.g. STK-001)
schema_version: '2.0'
tags: []
related: []    # entity IDs (e.g. [DEC-001, ACT-002])
---
```

Body follows the structured section format (Source Quote, Statement, ...).
```

**Replacement decision schema block — apply requirement schema pattern:**
```yaml
### Decision

```yaml
---
id: DEC-000
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""  # DEC: options considered, chosen option, status, decision date
type: architectural  # architectural | process | tooling | data | business-rule | organisational
date: ""          # ISO 8601 (e.g. 2026-04-29)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
source: []        # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---
```

Body follows the v2.0 structured section format (Source Quote, Context, Decision, Alternatives
Considered, Rationale).
```

**Current decision.md template in Step 12 (lines 421–447) — the block to REPLACE:**
```markdown
`.sara/templates/decision.md`:

```markdown
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
summary: ""  # DEC: options considered, chosen option/recommendation, status, decision date
context: ""
decision: ""
rationale: ""
alternatives-considered: ""
date: ""          # ISO 8601 (e.g. 2026-04-27)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
schema_version: "1.0"
tags: []
related: []
---

## Context

## Decision

## Rationale

## Alternatives Considered
```
```

**Pattern to copy from — requirement.md template (lines 355–417):**

The requirement template shows: v2.0 single-quoted schema_version, `type` field, body section headings with placeholder comment text. Apply the same structure for decision v2.0 template:

```markdown
`.sara/templates/decision.md`:

```markdown
---
id: DEC-000
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""  # DEC: options considered, chosen option, status, decision date
type: architectural  # architectural | process | tooling | data | business-rule | organisational
date: ""          # ISO 8601 (e.g. 2026-04-29)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
source: []        # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
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

Note: The Step 9 CLAUDE.md block and the Step 12 template are two separate edits in the same `sara-init/SKILL.md` file. Both must be updated.

---

### `.claude/agents/sara-artifact-sorter.md` — Output Format + Passthrough Rule

**Analog:** Same file — requirement passthrough rule (lines 131–134) and requirement object example (lines 88–98, 110–120)

**Current decision object example (lines 100–108) — the block to EXTEND:**
```json
    {
      "action": "update",
      "type": "decision",
      "existing_id": "DEC-003",
      "title": "Title of existing decision",
      "source_quote": "Exact verbatim text from source document motivating this update",
      "raised_by": "STK-NNN",
      "related": ["REQ-005"],
      "change_summary": "Add new context from this source document"
    },
```

**Pattern to copy from — requirement passthrough rule (lines 131–134):**
```
- For requirement artifacts, preserve `priority` and `req_type` exactly as received from the
  extraction pass. Do not modify, reclassify, or drop these fields. Pass them through unchanged
  to `cleaned_artifacts`.
- For requirement update artifacts (`action=update`, `type=requirement`), `priority` and `req_type`
  MUST be present — copy them from the incoming create artifact unchanged. sara-update reads these
  fields for all requirement artifacts regardless of action.
```

**Required additions — apply requirement passthrough pattern to decision artifacts:**

1. Add decision-specific fields to the create decision object example (add after the existing update example):
```json
    {
      "action": "create",
      "type": "decision",
      "id_to_assign": "DEC-NNN",
      "title": "Short title",
      "source_quote": "Exact verbatim text from source document",
      "raised_by": "STK-NNN",
      "related": [],
      "change_summary": "",
      "status": "accepted",
      "dec_type": "architectural",
      "chosen_option": "The selected option",
      "alternatives": ["Alternative A", "Alternative B"]
    },
```

2. Update the existing update decision object example to include decision-specific fields:
```json
    {
      "action": "update",
      "type": "decision",
      "existing_id": "DEC-003",
      "title": "Title of existing decision",
      "source_quote": "Exact verbatim text from source document motivating this update",
      "raised_by": "STK-NNN",
      "related": ["REQ-005"],
      "change_summary": "Add new context from this source document",
      "status": "accepted",
      "dec_type": "tooling",
      "chosen_option": "The selected option",
      "alternatives": []
    },
```

3. Add parallel passthrough rule to the `<output_format>` Rules section (following the requirement passthrough rule at lines 131–134):
```
- For decision artifacts, preserve `status`, `dec_type`, `chosen_option`, and `alternatives`
  exactly as received from the extraction pass. Do not modify, reclassify, or drop these fields.
  Pass them through unchanged to `cleaned_artifacts`.
- For decision update artifacts (`action=update`, `type=decision`), `status`, `dec_type`,
  `chosen_option`, and `alternatives` MUST be present — copy them from the incoming create
  artifact unchanged. sara-update reads these fields for all decision artifacts regardless of
  action.
```

---

## Shared Patterns

### Source Quote Attribution (wikilink form)
**Source:** `.claude/skills/sara-update/SKILL.md` lines 118–120
**Apply to:** Decision create and update branches — the `## Source Quote` section
```
> "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]
```
Note: The v1.0 decision body used `{stakeholder_name}` without a wikilink (bare name). v2.0 uses the full `[[STK-NNN|Name]]` wikilink form matching the requirement pattern.

### `schema_version: '2.0'` Single-Quoted Form
**Source:** `.claude/skills/sara-update/SKILL.md` line 87 (requirement branch)
**Apply to:** All decision artifact writes in sara-update, the decision template in sara-init Step 12, and the decision schema block in sara-init Step 9
```
schema_version: '2.0'
```
Never write `schema_version: 2.0` (unquoted float) or `schema_version: "2.0"` (double-quoted) for decision artifacts.

### Field Mapping Pattern (artifact JSON field → frontmatter field)
**Source:** `.claude/skills/sara-update/SKILL.md` lines 87–89
**Apply to:** Decision create and update branches
```
- `type` = `artifact.req_type` for requirement artifacts
- `priority` = `artifact.priority` for requirement artifacts
```
Mirror pattern for decisions:
```
- `type` = `artifact.dec_type` for decision artifacts
- `status` = `artifact.status` for decision artifacts (never hardcode "proposed")
```

### Inline Extraction — INCLUDE/EXCLUDE Block Structure
**Source:** `.claude/skills/sara-extract/SKILL.md` lines 54–67 (requirements pass)
**Apply to:** Decisions pass rewrite
The two-block (INCLUDE / EXCLUDE) structure with bullet-listed signals and negative examples is the established prompt pattern. The decisions pass must follow the same structure, replacing modal-verb signals with the two commitment/misalignment signal groups.

### Empty Section Pattern
**Source:** `.claude/skills/sara-update/SKILL.md` lines 141–146
**Apply to:** All five decision body sections
```
For every section, synthesise content if the source document or discussion notes contain
relevant material. If nothing relevant is available for a section, leave it empty (heading
only). Never fabricate content that is not grounded in {source_doc} or {discussion_notes}.
```

---

## No Analog Found

No files without analogs — all four modified files have exact in-file analogs from Phase 8 changes to the same files.

---

## Critical Pitfalls for Planner

The following must be explicitly called out in each plan's task instructions:

1. **`dec_type` not `type` in artifact JSON** — The extraction prompt output schema must use `dec_type` (not `type`) to avoid overwriting the envelope `type: "decision"` field. sara-update maps `artifact.dec_type` → frontmatter `type`.

2. **`status: proposed` removal** — grep verification: `grep "proposed" .claude/skills/sara-update/SKILL.md` must return zero results in the decision create branch after editing.

3. **Two edit locations in sara-init** — Step 9 (CLAUDE.md schema block at line ~214) and Step 12 (decision.md template at line ~421) are separate edits. Both must be updated in the same plan.

4. **British English spelling** — `organisational` (not `organizational`) in all four modified files.

5. **Sorter passthrough rule is additive** — Add the decision passthrough rule alongside the existing requirement passthrough rule (lines 131–134). Do not replace the requirement rule.

6. **Update branch also gets body rewrite** — The decision update branch must rewrite the full body to v2.0 format (matching the requirement update branch pattern at lines 269–290), not just update frontmatter fields.

---

## Metadata

**Analog search scope:** `.claude/skills/`, `.claude/agents/`, `.planning/phases/08-refine-requirements/`
**Files read:** 5 (sara-extract SKILL.md, sara-update SKILL.md, sara-init SKILL.md, sara-artifact-sorter.md, 08-CONTEXT.md partial)
**Pattern extraction date:** 2026-04-29
