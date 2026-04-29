# Phase 11: refine-risks - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the **risk artifact** across two tracks — completing the four-artifact refinement cycle started in Phase 8:

1. **Extraction** — Rewrite the sara-extract risk extraction pass with a clear signal definition, `risk_type` classification, `owner` as a distinct extracted field, `likelihood`/`impact` extracted inline when signals are present, and signal-based initial status assignment.

2. **Writing** — Restructure the wiki risk page: bump schema to v2.0, remove `mitigation` from frontmatter (move fully to body), add `type` and `owner` frontmatter fields, replace the flat body with a four-section structured body (Source Quote / Risk / Mitigation / Cross Links).

Scope: risk artifact only.

No changes to: the sorter agent, per-artifact approval loop mechanics, sara-discuss, sara-ingest, pipeline-state.json structure, requirement/decision/action artifact types.

</domain>

<decisions>
## Implementation Decisions

### Extraction — signal for "this is a risk"

- **D-01:** The existing signal is retained and tightened: a risk is an **uncertain future event or condition with a potential negative effect**. A confirmed problem already happening is an action item, not a risk.
- **D-02:** The extraction pass also captures `likelihood` and `impact` inline **when signals are present in the source**. If the source says "very likely", "significant concern", "minor risk", "low probability" — map to `high`/`medium`/`low` respectively. If no signal, leave both fields as `""`. Same pattern as `due_date` in actions: capture what's there, don't invent.

### Extraction — type classification

- **D-03:** The extraction pass classifies each risk into one of six `risk_type` values inline:
  - `technical` — system, architecture, technology, integration risks
  - `financial` — budget, cost, funding, pricing risks
  - `schedule` — timeline, deadline, dependency, sequencing risks
  - `quality` — accuracy, completeness, reliability, performance risks
  - `compliance` — regulatory, legal, policy, contractual risks
  - `people` — staffing, skills, availability, stakeholder engagement risks

### Extraction — owner vs raised_by

- **D-04:** The extraction pass captures `owner` as a **distinct field** from `raised_by`:
  - `raised_by` — who surfaced or raised the risk in the source (existing field, unchanged)
  - `owner` — who is responsible for tracking and mitigating the risk (new field)
  - Both fields: STK-NNN if already in the stakeholder registry; raw name string if not yet registered; empty string if unidentifiable.
- **D-05:** sara-update writes `owner` from `artifact.owner` to the wiki page frontmatter. If `artifact.owner` is a resolved STK ID, write it as-is. If a raw name string, write it as-is. If empty, write `owner: ""`.

### Extraction — initial status assignment

- **D-06:** Default initial status is `open`. The extraction pass assigns a different status only when the source contains explicit language:
  - `mitigated` — source says "controls already in place", "this is being handled by X", "we've addressed this with Y"
  - `accepted` — source says "we've accepted this risk", "we're comfortable with this", "no action needed, we'll live with it"
  - All other risks default to `open`.

### Extraction — artifact schema additions

The risk artifact JSON produced by the extraction pass gains these new fields:
- `risk_type` — one of the six values above
- `owner` — STK-NNN or raw name string or `""`
- `likelihood` — `"high"`, `"medium"`, `"low"`, or `""` (extracted from source signal, or empty)
- `impact` — `"high"`, `"medium"`, `"low"`, or `""` (extracted from source signal, or empty)
- `status` — `"open"`, `"mitigated"`, or `"accepted"` (signal-based; default `"open"`)

### Wiki page — frontmatter schema (v2.0)

- **D-07:** `schema_version` bumped to `'2.0'` (single-quoted — consistent with requirement, decision, action convention; prevents YAML float parse).
- **D-08:** `mitigation` frontmatter field **removed** — narrative content moves fully to the `## Mitigation` body section. Consistent with Phase 9 (removed context/rationale/decision from frontmatter).
- **D-09:** New frontmatter field: `type` (one of the six `risk_type` values). Maps from `artifact.risk_type`.
- **D-10:** `owner` remains a frontmatter field; now written from `artifact.owner` (see D-05).
- **D-11:** `likelihood` and `impact` remain as frontmatter fields; now written from `artifact.likelihood` and `artifact.impact` (raw string from extraction, or `""`).
- **D-12:** Status lifecycle is **three values**: `open` / `mitigated` / `accepted`. `closed` is removed — once a risk is tracked, it resolves to either mitigated or accepted, never simply closed.
- **D-13:** `status` written from `artifact.status` (signal-based; see D-06).

Full v2.0 frontmatter shape:
```yaml
---
id: RSK-NNN
title: ""
status: open  # open | mitigated | accepted
summary: ""   # RSK: likelihood, impact, type, status, mitigation approach
type: technical  # technical | financial | schedule | quality | compliance | people
likelihood: ""   # low | medium | high (extracted from source, or empty)
impact: ""       # low | medium | high (extracted from source, or empty)
owner: ""        # STK-NNN or raw name string
raised-by: ""    # STK-NNN or raw name string
source: []       # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---
```

### Wiki page — markdown body structure

- **D-14:** The body follows this four-section structure:

```markdown
## Source Quote
> "[exact verbatim passage from source document]" — [[STK-NNN|Stakeholder Name]]

## Risk

IF <trigger condition> THEN <adverse event>

[Synthesised by sara-update: the IF/THEN statement is the primary risk description.
IF and THEN are written in caps. The rest of the statement is sentence case.
Example: IF the integration vendor delays API delivery THEN the go-live milestone slips by 4+ weeks.]

## Mitigation

[Synthesised by sara-update from source doc + discussion notes: controls, contingencies, or
mitigation approaches mentioned. If nothing was discussed: "No mitigation discussed — define
action items to address this risk."]

## Cross Links
[One wiki link per entry in artifact.related, per wikilink rule]
```

- **D-15:** sara-update synthesises the `## Risk` IF/THEN statement and `## Mitigation` from the full source document and discussion notes already in context — these are NOT extracted inline.

### Approval loop — owner warning

- **D-16:** When the Step 4 approval loop presents a risk artifact where `artifact.owner` is empty or a raw (unresolved) name string, it prepends a warning line before the artifact summary:
  ```
  ⚠ Owner not resolved — assign manually after /sara-update, or run /sara-add-stakeholder first.
  ```
  This does not prevent the user from accepting the artifact. (Consistent with action pattern from Phase 10.)

### Claude's Discretion

- Exact wording of the updated extraction prompt — must include the six-type taxonomy, likelihood/impact signal mapping, status signal mapping, and owner extraction instructions
- Whether to add negative examples to the extraction prompt (confirmed problems that are actions, not risks; background context; aspirational statements)
- Summary generation wording for risk artifacts at each status (`open`, `mitigated`, `accepted`)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills being modified
- `.claude/skills/sara-extract/SKILL.md` — Risk extraction pass in Step 3 is rewritten; all other steps unchanged
- `.claude/skills/sara-update/SKILL.md` — Risk artifact writing updated: v2.0 frontmatter, four-section body, owner from artifact.owner, approval loop warning for unresolved owners
- `.claude/skills/sara-init/SKILL.md` — Risk schema block in CLAUDE.md and risk.md template updated to v2.0

### Prior phase context (pattern references)
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — Canonical reference for the two-track pattern (extraction refinement + schema v2.0)
- `.planning/phases/09-refine-decisions/09-CONTEXT.md` — Decision refinement pattern; confirms sorter passes new fields through unchanged
- `.planning/phases/10-refine-actions/10-CONTEXT.md` — Action refinement pattern; owner/raised_by distinction and approval loop warning

### Agent files (read for compatibility, do not modify)
- `.claude/agents/sara-artifact-sorter.md` — Verify `risk_type`, `owner`, `likelihood`, `impact`, `status` new fields do not break sorter input contract (Phase 8 precedent: sorter passed `req_type`/`priority` through unchanged)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-extract` Step 3 risk pass: targeted rewrite of the extraction prompt, signal definition, and artifact schema; surrounding pass structure (collect as `{risk_artifacts}`, merge into `{merged}`) unchanged
- `sara-update` risk write branch: replace flat body (Description + Mitigation) with four-section body; update frontmatter field mapping for `type`, `owner`, `likelihood`, `impact`, `status`, `schema_version`; remove `mitigation` frontmatter field
- `sara-artifact-sorter`: untouched — passes extra fields through unchanged (validated pattern from Phases 8, 9, 10)

### Established Patterns
- Extraction adds type-specific fields to the artifact JSON; sorter ignores them; sara-update maps them to frontmatter — proven pipeline from Phases 8, 9, 10
- `schema_version: '2.0'` with single quotes — established in Phase 8, applied in Phases 9, 10; applies here
- Body sections synthesised by sara-update from full source doc in context — not extracted inline
- `raised_by` proxies attribution; `owner` is a separate responsibility field — pattern from Phase 10 actions
- Signal-based initial status — pattern from Phase 9 decisions

### Integration Points
- `sara-init` CLAUDE.md schema block (Risk section): updated to v2.0 frontmatter with `type`, `owner`, `schema_version: '2.0'`; `mitigation` frontmatter field removed
- `sara-init` template write: `.sara/templates/risk.md` updated to v2.0 frontmatter + four-section body
- `sara-update` entity write loop: `schema_version` written as `'2.0'` for risk artifacts (single quotes)
- `sara-update` approval loop (Step 4): add owner-not-resolved warning before artifact summary (same as action pattern)

</code_context>

<specifics>
## Specific Ideas

- The `## Risk` body section uses an `IF <trigger> THEN <adverse_event>` format with IF and THEN in caps — this makes the risk statement precise and scannable in Obsidian
- Status lifecycle is deliberately three values: `open` → `mitigated` / `accepted`. `closed` is excluded — the user does not see a path from open to closed without taking a position on whether the risk was controlled (mitigated) or tolerated (accepted)
- `risk_type` taxonomy uses six buckets matching common PM risk register categories: technical, financial, schedule, quality, compliance, people

</specifics>

<deferred>
## Deferred Ideas

- sara-lint backfill: existing RSK pages predate v2.0 schema; a lint pass to migrate them was not scoped here

</deferred>

---

*Phase: 11-refine-risks*
*Context gathered: 2026-04-29*
