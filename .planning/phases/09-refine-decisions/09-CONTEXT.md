# Phase 9: refine-decisions - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the **decision artifact** across two tracks — mirroring what Phase 8 did for requirements:

1. **Extraction** — Rewrite the sara-extract decision extraction pass with precise linguistic markers, status assignment based on alignment vs. misalignment, and type classification inline. The current prompt ("a deliberate choice made by the team that was concluded") is too vague.

2. **Writing** — Restructure the wiki decision page: bump schema to v2.0, remove narrative frontmatter fields (context, decision, rationale, alternatives-considered), replace with a structured body, add `type` frontmatter field, change initial status from `proposed` to either `accepted` or `open` based on what was detected.

Scope: decision artifact only. Actions and risks are refined in subsequent phases.

No changes to: the sorter agent, per-artifact approval loop, sara-discuss, sara-ingest, pipeline-state.json structure, requirement/action/risk artifact types.

</domain>

<decisions>
## Implementation Decisions

### Extraction — signal for "this is a decision"

- **D-01:** Two extraction signals, yielding two distinct initial statuses:
  - **Commitment language** — phrases like "we decided to", "we chose", "we agreed on", "we went with", "we will use", "the approach is" → `status: accepted`. The team is aligned; the decision is done.
  - **Misalignment language** — disagreement, contested views, unresolved choices, "we need to decide", competing preferences → `status: open`. The decision exists as a known issue but needs more work to gain alignment.
- **D-02:** `proposed` is dropped as an initial status value. New decision artifacts written by sara-update start as either `accepted` or `open`, never `proposed`.
- **D-03:** The extraction pass sets `status` in the artifact JSON based on which signal was detected. sara-update writes that status directly to the wiki page frontmatter.

### Extraction — what the pass captures per artifact

- **D-04:** The decision extraction pass captures three structured fields per artifact (in addition to the standard `title`, `raised_by`, `action`, `id_to_assign`, `related`, `change_summary`):
  - `source_quote` — exact verbatim passage from the source document (MANDATORY)
  - `chosen_option` — the option that was selected (for commitment-language decisions); empty string for open/misalignment decisions
  - `alternatives` — list of alternatives that were considered (if present in the source); empty array if not mentioned
- **D-05:** sara-update synthesises `## Context` and `## Rationale` body sections from the full source document and discussion notes already in context — these are NOT extracted in the artifact pass.

### Extraction — type classification

- **D-06:** The extraction pass classifies each decision into one of six types (inline, same pass as signal detection and status assignment):
  - `architectural` — system structure, technology choices, component relationships
  - `process` — how the team works, workflow, ceremonies, practices
  - `tooling` — software tools, libraries, platforms selected
  - `data` — data model, storage, retention, ownership rules
  - `business-rule` — domain logic, policy decisions
  - `organisational` — team structure, ownership, roles, responsibilities

### Wiki page — frontmatter schema (v2.0)

- **D-07:** `schema_version` bumped to `'2.0'` (single quotes — prevents YAML float parse, consistent with requirement schema convention).
- **D-08:** Narrative frontmatter fields **removed**: `context`, `decision`, `rationale`, `alternatives-considered`. These move fully into the body sections. No more duplication between frontmatter and body.
- **D-09:** New frontmatter field added: `type` (one of the six values above).
- **D-10:** `status` initial value changes from `proposed` to either `accepted` or `open` (set by extraction pass).

Full v2.0 frontmatter shape:
```yaml
---
id: DEC-NNN
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""       # DEC: options considered, chosen option, status, decision date
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

### Wiki page — markdown body structure

- **D-11:** The body follows this section order:

```markdown
## Source Quote
> [exact verbatim passage from source document] — [[STK-NNN|Stakeholder Name]]

## Context

[Synthesised by sara-update: why this decision was needed, background]

## Decision

[The chosen option — from chosen_option extraction field]

## Alternatives Considered

[List of alternatives from alternatives extraction field; expanded with synthesis if present in source]

## Rationale

[Synthesised by sara-update: why this option was chosen over the alternatives]
```

- **D-12:** For `status: open` (misalignment) decisions, `## Decision` reads "No decision reached — alignment required." and `## Alternatives Considered` lists the competing positions detected in the source.

### Claude's Discretion

- Exact wording of the extraction prompt (must produce the correct JSON schema including `chosen_option`, `alternatives`, `type`, `status`)
- Whether to add negative examples to the extraction prompt (passages that are NOT decisions — discussions, considerations, aspirations)
- Summary generation wording for `accepted` vs `open` decisions

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills being modified
- `.claude/skills/sara-extract/SKILL.md` — Decision extraction pass in Step 3 is rewritten; all other steps unchanged
- `.claude/skills/sara-update/SKILL.md` — Decision artifact writing updated: v2.0 frontmatter, body sections, status from extraction
- `.claude/skills/sara-init/SKILL.md` — Decision schema block in CLAUDE.md (Step 9) and decision template (Step 12) updated to v2.0
- `install.sh` — No changes required (skill files update in-place)

### Prior phase context
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — Canonical reference for the two-track pattern (extraction refinement + schema v2.0) this phase mirrors

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-extract` Step 3 decision pass: existing inline extraction prompt — the new prompt replaces it directly; JSON schema shape is extended with `chosen_option`, `alternatives`, `type`, `status` fields
- `sara-update` entity write loop: already handles type-specific field mapping (e.g. `req_type`, `priority` for requirements) — same pattern extended for `type` and `status` on decision artifacts
- `sara-artifact-sorter`: untouched — passes extra fields through unchanged (validated pattern from Phase 8 which added `req_type`/`priority` without sorter changes)

### Established Patterns
- Extraction adds type-specific fields to the artifact JSON; sorter ignores them; sara-update maps them to frontmatter — this pipeline is proven from Phase 8
- `schema_version: '2.0'` with single quotes — established in Phase 8 for YAML float-parse safety; applies here too
- Body sections synthesised by sara-update from full source doc in context — not extracted inline — established pattern for narrative sections

### Integration Points
- `sara-init` CLAUDE.md schema block (line ~214 in current SKILL.md): decision schema definition updated to v2.0
- `sara-init` template write (Step 12): `.sara/templates/decision.md` updated to v2.0 frontmatter + body structure
- `sara-update` entity write loop: `schema_version` written as `'2.0'` for decision artifacts (single quotes)

</code_context>

<specifics>
## Specific Ideas

- Type taxonomy uses British English spelling: `organisational` (not `organizational`)
- Status lifecycle for decisions: `open` → `accepted` / `rejected` / `superseded` (no `proposed` step)
- Misalignment decisions (`status: open`) are first-class wiki artifacts — they capture known unresolved choices so they don't disappear into chat history

</specifics>

<deferred>
## Deferred Ideas

- Refine action artifact (extraction signal, schema) — subsequent phase
- Refine risk artifact (extraction signal, schema) — subsequent phase

</deferred>

---

*Phase: 09-refine-decisions*
*Context gathered: 2026-04-29*
