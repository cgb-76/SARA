# Phase 12: vertical-awareness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 12-vertical-awareness
**Areas discussed:** Goal definition, Inference fallback, Cardinality, Init prompt, Migration scope

---

## Goal definition

| Option | Description | Selected |
|--------|-------------|----------|
| Tag artifacts with vertical | Add a vertical field to artifact types | |
| Validate STK vertical assignment | Validate from configured list | |
| Vertical-scoped views/commands | Filter artifacts by vertical | |
| User-defined | Freeform description | ✓ |

**User's choice:** Freeform — user described two tracks directly:
1. Rename `vertical` → `segment` everywhere
2. Add `segments: []` to all four artifact types; infer from source-quote stakeholder attribution, with context-clue fallback

---

## Inference fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Leave empty (Recommended) | `""` when unresolvable — same as due_date pattern | |
| Fall back to context clues | Keyword match against segments list before leaving empty | ✓ |
| Leave empty + warn at approval | Show warning in Step 4 loop | |

**User's choice:** Fall back to context clues
**Notes:** Inference priority established as: STK-attribution → keyword match → `[]`

---

## Cardinality

| Option | Description | Selected |
|--------|-------------|----------|
| Exactly one (or empty) | Single string field | |
| Array of segments | List field — allows cross-segment artifacts | ✓ |

**User's choice:** Array of segments
**Notes:** An artifact can legitimately affect multiple segments (e.g. a compliance risk spanning Residential and Wholesale)

---

## Init prompt wording

| Option | Description | Selected |
|--------|-------------|----------|
| Provide all segments that apply? | Simple rename | |
| What segments or customer groups does this project cover? | More descriptive | ✓ |

**User's choice:** "What segments or customer groups does this project cover?"

---

## Migration scope

| Option | Description | Selected |
|--------|-------------|----------|
| Skills only — no migration | Update skills; existing wikis keep 'vertical' | ✓ |
| Add a sara-lint check | Flag pages using old 'vertical' field | |
| Out of scope — you decide | Claude chooses approach | |

**User's choice:** Skills only — no migration

---

## Claude's Discretion

- Exact wording of the segment inference prompt in sara-extract
- Whether config.json is read once at skill entry or inline before Step 3
- YAML serialisation style for `segments` array (flow vs block based on entry count)

## Deferred Ideas

- sara-lint migration check for old `vertical:` field name — user chose skills-only scope
- Index grouping by segment — future phase
- Segment filtering command (show all open risks for a segment) — future phase
