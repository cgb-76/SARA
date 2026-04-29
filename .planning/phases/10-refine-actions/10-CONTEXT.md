# Phase 10: refine-actions - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the **action artifact** across two tracks — mirroring what Phase 8 did for requirements and Phase 9 did for decisions:

1. **Extraction** — Rewrite the sara-extract action extraction pass with a clear positive definition, `act_type` classification, `owner` as a distinct extracted field, and `due_date` capture. The current prompt ("a concrete task or follow-up with an implied or explicit owner") is too vague.

2. **Writing** — Restructure the wiki action page: bump schema to v2.0, replace `## Description` + `## Notes` body with a six-section structured body, add `type` and `owner` frontmatter fields.

Scope: action artifact only. Risk artifact is refined in a subsequent phase.

No changes to: the sorter agent, per-artifact approval loop mechanics, sara-discuss, sara-ingest, pipeline-state.json structure, requirement/decision/risk artifact types.

</domain>

<decisions>
## Implementation Decisions

### Extraction — signal for "this is an action item"

- **D-01:** The extraction signal is **any passage implying work needs to happen** — the broadest possible net. This includes passages with or without a named owner. There is no explicit exclusion list in the pass; the existing sorter already handles cross-type deduplication and ambiguity resolution (e.g., a passage that reads as both a decision and an action is flagged by the sorter).
- **D-02:** Due dates are extracted as a **raw string** when mentioned in the source (e.g., "by Friday", "EOW", "before next sprint"). No normalisation to ISO 8601 at extraction time — the user resolves the actual date manually.
- **D-03:** Actions without a resolvable owner are **not blocked at extraction time**. They are flagged during the Step 4 accept/reject/discuss approval loop with a warning: "Owner not resolved — assign manually after update." The user can still accept the artifact; the wiki page writes `owner` as the raw name string (or empty if no name was mentioned).

### Extraction — type classification

- **D-04:** The extraction pass classifies each action into one of two types (`act_type`) inline:
  - `deliverable` — a concrete output or artefact to produce (report, document, implementation, fix)
  - `follow-up` — a check-in, response, or update required from someone (confirm, reply, chase, update)

### Extraction — owner vs raised_by

- **D-05:** The extraction pass captures `owner` as a **distinct field** from `raised_by`:
  - `raised_by` — who surfaced or raised the action item in the source (existing field, unchanged)
  - `owner` — who is assigned to do the work (new field). Often the same person; sometimes different.
  - Both fields: STK-NNN if the person is already in the stakeholder registry; raw name string if not yet registered.
- **D-06:** sara-update writes `owner` from `artifact.owner` (not `artifact.raised_by`) to the wiki page frontmatter. If `artifact.owner` is a resolved STK ID, write it as-is. If it is a raw name string, write it as-is (the user will reconcile later). If empty, write `owner: ""`.

### Extraction — artifact schema additions

The action artifact JSON produced by the extraction pass gains these new fields:
- `act_type` — `"deliverable"` or `"follow-up"`
- `owner` — STK-NNN or raw name string or `""`
- `due_date` — raw string from source (e.g. `"by Friday"`) or `""` if not mentioned

### Wiki page — frontmatter schema (v2.0)

- **D-07:** `schema_version` bumped to `'2.0'` (single-quoted — consistent with requirement and decision convention; prevents YAML float parse).
- **D-08:** New frontmatter field: `type` (one of: `deliverable`, `follow-up`). Maps from `artifact.act_type`.
- **D-09:** `owner` remains a frontmatter field; now written from `artifact.owner` (see D-06).
- **D-10:** New frontmatter field: `due-date` — written from `artifact.due_date` (raw string or empty).

Full v2.0 frontmatter shape:
```yaml
---
id: ACT-NNN
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

### Wiki page — markdown body structure

- **D-11:** The body follows this six-section structure:

```markdown
## Source Quote
> "[exact verbatim passage from source document]" — [[STK-NNN|Stakeholder Name]]

## Description

[Synthesised by sara-update: 2–4 sentences describing what needs to be done, grounded in source quote and discussion notes]

## Context

[Synthesised by sara-update: why this action was raised — triggering event, dependency, or decision it relates to]

## Owner

[Synthesised from artifact.owner — who is responsible and, if known, why they are the right person]

## Due Date

[Raw due date string from extraction, or empty. If empty: "Not specified — set manually."]

## Cross Links
[One wiki link per entry in artifact.related, per wikilink rule]
```

- **D-12:** sara-update synthesises **Description** and **Context** from source doc + discussion notes (same pattern as requirements and decisions). Owner and Due Date sections are written from the extracted artifact fields, not synthesised.

### Approval loop — owner warning

- **D-13:** When the Step 4 approval loop presents an action artifact where `artifact.owner` is empty or a raw (unresolved) name string, it prepends a warning line before the artifact summary:
  ```
  ⚠ Owner not resolved — assign manually after /sara-update, or run /sara-add-stakeholder first.
  ```
  This does not prevent the user from accepting the artifact.

### Claude's Discretion

- Exact wording of the updated extraction prompt — must include a clear positive definition and examples of action items (with and without owners, with and without due dates)
- Whether to add negative examples to the extraction prompt (e.g., background context that implies work but is not a task, risk mitigations that are already captured by the risks pass)
- Summary generation wording for `deliverable` vs `follow-up` actions

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills being modified
- `.claude/skills/sara-extract/SKILL.md` — Action extraction pass in Step 3 is rewritten; all other steps unchanged
- `.claude/skills/sara-update/SKILL.md` — Action artifact writing updated: v2.0 frontmatter, six-section body, owner from artifact.owner, approval loop warning for unresolved owners
- `.claude/skills/sara-init/SKILL.md` — Action schema block in CLAUDE.md and action.md template updated to v2.0

### Prior phase context
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — Canonical reference for the two-track pattern (extraction refinement + schema v2.0) this phase mirrors
- `.planning/phases/09-refine-decisions/09-CONTEXT.md` — Decision refinement pattern; confirms sorter passes new fields through without modification

### Agent files (read for compatibility, do not modify)
- `.claude/agents/sara-artifact-sorter.md` — Sorter consumes the merged artifact array; verify `act_type`, `owner`, `due_date` new fields do not break the sorter's input contract (Phase 8 precedent: sorter passed `req_type`/`priority` through unchanged)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-extract` Step 3 action pass: targeted rewrite of the prompt text and artifact schema; the surrounding pass structure (collect results as `{act_artifacts}`, merge into `{merged}`) is unchanged
- `sara-update` action write branch (lines ~262–281): replace Description + Notes sections with six-section body; update frontmatter field mapping for `type`, `owner`, `due-date`, `schema_version`
- `sara-artifact-sorter`: untouched — passes extra fields through unchanged (validated pattern from Phases 8 and 9)

### Established Patterns
- Extraction adds type-specific fields to the artifact JSON; sorter ignores them; sara-update maps them to frontmatter — proven pipeline from Phases 8 and 9
- `schema_version: '2.0'` with single quotes — established in Phase 8, applied in Phase 9; applies here
- Body sections synthesised by sara-update from full source doc in context — not extracted inline — established pattern for narrative sections
- `raised_by` proxies attribution; `owner` is a separate responsibility field — new for actions

### Integration Points
- `sara-init` CLAUDE.md schema block (Action section): updated to v2.0 frontmatter with `type`, `due-date`, `schema_version: '2.0'`
- `sara-init` template write: `.sara/templates/action.md` updated to v2.0 frontmatter + six-section body
- `sara-update` entity write loop: `schema_version` written as `'2.0'` for action artifacts (single quotes, matching requirement and decision convention)
- `sara-update` approval loop (Step 4): add owner-not-resolved warning before artifact summary

</code_context>

<specifics>
## Specific Ideas

- `act_type` values use the same British English convention as `dec_type` (`organisational`) — but `deliverable` and `follow-up` are already unambiguous
- The six-section body is intentionally parallel to decisions (five sections) — actions are slightly more structured because they carry accountability and timing information
- Owner and Due Date are their own headings (not merged into Description) because they are the primary tracking fields for action management

</specifics>

<deferred>
## Deferred Ideas

- Refine risk artifact (extraction signal, schema) — subsequent phase
- sara-lint backfill: existing ACT pages predate v2.0 schema; a lint pass to migrate them was not scoped here

</deferred>

---

*Phase: 10-refine-actions*
*Context gathered: 2026-04-29*
