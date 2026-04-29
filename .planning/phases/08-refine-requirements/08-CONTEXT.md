# Phase 8: refine-requirements - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the **requirements artifact** across two tracks:

1. **Extraction** — Rewrite the sara-extract requirements extraction pass with precise linguistic markers, MoSCoW priority mapping, and type classification inline. The current prompt ("Extract every passage that describes a requirement — a capability, constraint, or rule…") is too vague; the new prompt anchors on modal verbs as the primary signal.

2. **Writing** — Restructure the wiki requirement page: bump schema to v2.0, remove the `description` field, replace the entire markdown body with a structured multi-section format, add `type` and `priority` frontmatter fields, and wire sara-update to write `## Cross Links` from `related[]`.

Scope: requirements only. Decisions, risks, and actions are refined in subsequent phases.

No changes to: the sorter agent, per-artifact approval loop, sara-discuss, sara-ingest, pipeline-state.json structure, other artifact types.

</domain>

<decisions>
## Implementation Decisions

### Extraction — signal for "this is a requirement"

- **D-01:** Primary extraction signal is **linguistic markers** — modal verbs and imperative language: `must`, `shall`, `should`, `will`, `need to`, `required to`, `has to`. Passages that contain none of these signals are not requirements, regardless of topic.
- **D-02:** Vague wishes, observations, aspirational statements, and background context without a commitment modal are explicitly excluded. The extraction prompt must include negative examples of these.

### Extraction — MoSCoW priority

- **D-03:** The extraction pass maps modal verbs to MoSCoW priority and stores it in the `priority` field:
  - `must` / `shall` / `will` → `must-have`
  - `should` → `should-have`
  - `could` / `may` → `could-have`
  - Explicit "we won't" / "out of scope" language → `wont-have`
- **D-04:** Priority is assigned in the same inline extraction pass as identification and type classification — no separate round-trip.

### Extraction — type classification

- **D-05:** The extraction pass classifies each requirement into one of six types (inline, same pass):
  - `functional` — capability the system performs
  - `non-functional` — quality attributes and design constraints (performance, reliability, usability, security, scalability)
  - `regulatory` — external law, standards, or mandates (GDPR, PCI-DSS, etc.) — external only, not internal policy
  - `integration` — how the system connects to external systems, APIs, or people
  - `business-rule` — domain logic or process policy
  - `data` — structure, retention, quality, or ownership rules for data

### Wiki page — frontmatter schema (v2.0)

- **D-06:** `schema_version` bumped to `'2.0'` on all requirement pages written or updated after this phase.
- **D-07:** `description` field **removed**. Its content is replaced by the structured markdown body sections (Statement + Source Quote).
- **D-08:** `summary` field moves under `title` (filling the gap left by removing `description`).
- **D-09:** Two new frontmatter fields added: `type` (one of the six types above) and `priority` (MoSCoW value).

Full frontmatter shape:
```yaml
---
id: REQ-NNN
title: ...
summary: <50-word summary>
status: open|accepted|rejected|superseded
type: functional|non-functional|regulatory|integration|business-rule|data
priority: must-have|should-have|could-have|wont-have
source: <ingest ID>
raised-by: <STK-NNN>
owner: <STK-NNN>
schema_version: '2.0'
tags: []
related: []
---
```

### Wiki page — markdown body structure

- **D-10:** The **entire** markdown body is replaced by the following section structure. Sections present for a given requirement depend on its type (see matrix in D-11).

```markdown
## Source Quote
> [exact stakeholder words from source document]

## Statement
The [subject] shall [verb phrase].

## User Story
As a [role], I want [capability], so that [benefit].

## Acceptance Criteria
- [ ] [plain language condition]
- [ ] [plain language condition]

## BDD Criteria
**Scenario: [name]**
Given [context]
When [action]
Then [outcome]

## Context
[Rationale, background, constraints not captured elsewhere]

## Cross Links
[One wiki link per related[] entry, following link conventions]
```

### Wiki page — section matrix

- **D-11:** Which sections are required (✓), optional (opt), or omitted (—) per type. **This matrix and its rationale must be embedded in the sara-init requirement template and referenced in sara-extract's requirements pass.**

| Section | Functional | Non-functional | Regulatory | Integration | Business rule | Data |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Source Quote | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Statement | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| User Story | ✓ | opt | — | opt | — | — |
| Acceptance Criteria | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| BDD Criteria | ✓ | — | — | opt | ✓ | — |
| Context | opt | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cross Links | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**Rationale (embed in skill file):**
- **User Story on Non-functional** — optional: usability NFRs have a natural user ("As a reader…"), but performance, security, or reliability NFRs usually don't map to a role/benefit framing.
- **User Story on Integration** — optional: integration requirements can have a user-facing perspective (e.g. a developer consuming an API) but often don't.
- **User Story omitted on Regulatory/Business rule/Data** — these are compliance mandates and policy rules, not user goals. Forcing a user story produces artificial framing.
- **BDD on Business rule** — required: business rules are where Gherkin is most natural ("Given an invoice is unapproved, When payment is attempted, Then reject with error"). Often more precise than functional BDD.
- **BDD on Integration** — optional: can work well for API contract verification but is not always natural (e.g. authentication handshake sequences).
- **BDD omitted on Non-functional/Regulatory/Data** — non-functionals are measured, not triggered by user actions; regulatory and data requirements are compliance checklists, not behaviour scenarios.
- **Context on Functional** — optional: usually self-evident from Source Quote + Statement; include only when there is non-obvious rationale or design constraint.
- **Context required on all other types** — why a quality target, mandate, integration contract, domain rule, or data policy exists is rarely obvious from the statement alone; downstream readers need the rationale.

### sara-update — Cross Links

- **D-12:** sara-update is modified to write the `## Cross Links` section at the end of every requirement page it creates or updates. Each entry in `related[]` frontmatter becomes one wiki link on its own line, following the existing link conventions used elsewhere in the wiki.

### Claude's Discretion

- Number of BDD scenarios per requirement: one happy-path scenario is the default; add additional scenarios only when the requirement explicitly has distinct, named edge cases.
- Whether to add a `## Cross Links` back-fill step to sara-lint for existing requirement pages that predate this phase.
- Exact wording of the updated extraction prompt — must include at least three negative examples (wish, observation, aspiration) alongside the positive modal-verb signal list.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills being modified
- `.claude/skills/sara-extract/SKILL.md` — Step 3 requirements extraction pass: rewrite prompt, add type classification and MoSCoW mapping
- `.claude/skills/sara-init/SKILL.md` — REQ template: new frontmatter shape (v2.0), new body structure, section matrix with rationale embedded
- `.claude/skills/sara-update/SKILL.md` — Add Cross Links writing from `related[]` frontmatter

### Agent files (read for compatibility, do not modify)
- `.claude/agents/sara-artifact-sorter.md` — Sorter consumes the artifact array produced by the extraction pass; verify the new `type` and `priority` fields do not break the sorter's input contract

### Schema reference
- `.planning/REQUIREMENTS.md` §WIKI-01 — Current v1 requirement page schema; v2.0 replaces this
- `.planning/phases/05-artifact-summaries/05-CONTEXT.md` — Established the `summary` field and grep-extract pattern; v2.0 keeps `summary` in frontmatter

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- sara-extract Step 3 requirements extraction pass: targeted rewrite of the prompt text only; JSON output schema (`action`, `type`, `title`, `source_quote`, `raised_by`, `related`, `change_summary`, `id_to_assign`) gains two new fields (`priority`, `req_type`) that flow through to the wiki page
- sara-init REQ template: replace body and frontmatter fields; keep guard clause and directory structure logic
- sara-update write path: add Cross Links generation after wiki page write, before git commit

### Established Patterns
- All wiki page writes use the Write tool only — no shell text-processing
- `summary` is generated by sara-update (Phase 5 pattern) — this continues unchanged
- `related[]` is already populated by the extraction pass — sara-update just needs to render it as wiki links
- schema_version is a quoted string (`'2.0'`) to prevent YAML float parsing (established in Phase 1)

### Integration Points
- sara-extract Step 3 → sara-artifact-sorter: `type` and `priority` are new fields in the artifact object; sorter must pass them through without modification
- sara-init REQ template → all future sara-update writes: the new body structure becomes the canonical template

</code_context>

<specifics>
## Specific Ideas

- The rationale for each cell of the section matrix should appear as a comment block inside the REQ template in sara-init — so future maintainers understand why, e.g., User Story is omitted for Regulatory requirements.
- Phase 9+ will apply the same two-track approach (extraction prompt + wiki page structure) to decisions, risks, and actions — the pattern established here is the model for those phases.

</specifics>

<deferred>
## Deferred Ideas

- Apply same two-track refinement to decisions, risks, and actions — subsequent phases per the user's intent
- REQUIREMENTS.md documentation gap: MEET-01, MEET-02, sara-lint, and sara-add-stakeholder are mismarked (incomplete or listed as v2 despite being built in Phases 2–5) — a documentation reconciliation pass is a natural companion to this phase but was not scoped here
- sara-lint backfill: existing REQ pages predate v2.0 schema; a sara-lint pass to migrate them was discussed informally but not scoped into this phase

</deferred>

---

*Phase: 08-refine-requirements*
*Context gathered: 2026-04-29*
