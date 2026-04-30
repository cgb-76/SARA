---
phase: 12-vertical-awareness
plan: "02"
subsystem: extraction-pipeline
tags: [segments, sara-extract, sara-artifact-sorter, vertical-awareness]
one_liner: "Segments field added to all four sara-extract passes with STK-attribution/keyword/empty-fallback inference; sara-artifact-sorter passes segments through unchanged"
dependency_graph:
  requires: []
  provides:
    - "sara-extract Step 3 reads config.segments before extraction passes"
    - "All four extraction passes produce a segments field in artifact JSON"
    - "sara-artifact-sorter segments passthrough rule for all artifact types"
  affects:
    - ".claude/skills/sara-extract/SKILL.md"
    - ".claude/agents/sara-artifact-sorter.md"
tech_stack:
  added: []
  patterns:
    - "STK-attribution → keyword matching → empty fallback inference chain"
    - "Passthrough rule pattern (matching existing act_type/owner/due_date pattern)"
key_files:
  created: []
  modified:
    - ".claude/skills/sara-extract/SKILL.md"
    - ".claude/agents/sara-artifact-sorter.md"
decisions:
  - "segments inference uses three-tier fallback: STK page segment field, then config.segments keyword scan, then empty array"
  - "config.json read once before all four passes (not once per pass) for efficiency"
  - "sorter passthrough rule mirrors existing field passthrough pattern for req/dec/action fields"
metrics:
  duration_seconds: 126
  completed_date: "2026-04-30"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 12 Plan 02: Segments Field on Extraction Passes Summary

## One-liner

Segments field added to all four sara-extract passes with STK-attribution/keyword/empty-fallback inference; sara-artifact-sorter passes segments through unchanged.

## What Was Built

### Task 1: sara-extract config read + segments field (commit caecef3)

Two additions to `.claude/skills/sara-extract/SKILL.md`:

**Config read at top of Step 3** — Before `**Requirements pass**`, inserted a directive to read `.sara/config.json` and store `config.segments` for use in all four passes.

**Segments inference bullet in all four passes** — Inserted the segments bullet immediately before the final `action`/`type`/`id_to_assign` line in each of the four extraction passes. The inference chain is:
1. STK attribution: parse STK-NNN from source_quote attribution, read stakeholder wiki page, extract `segment:` field
2. Keyword matching: scan source passage for case-insensitive matches against `config.segments` names
3. Empty fallback: `segments = []` if neither resolves

### Task 2: sara-artifact-sorter segments passthrough (commit d4c3faf)

Two bullets appended to the Rules section of `<output_format>` in `.claude/agents/sara-artifact-sorter.md`, after the existing action artifact passthrough rules:

- Preserve `segments` unchanged for all artifact types in `cleaned_artifacts`
- For update artifacts of any type, `segments` MUST be present (copied from incoming artifact)

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| `grep -c "Set \`segments\`" sara-extract/SKILL.md` | 4 | 4 |
| `grep -c "config\.segments" sara-extract/SKILL.md` | ≥1 | 5 |
| `grep -c "STK attribution" sara-extract/SKILL.md` | 4 | 4 |
| `grep -c "Keyword matching" sara-extract/SKILL.md` | 4 | 4 |
| `grep -c "Empty fallback" sara-extract/SKILL.md` | 4 | 4 |
| `grep -c "preserve \`segments\`" sara-artifact-sorter.md` | 1 | 1 |
| `grep "segments.*MUST be present" sara-artifact-sorter.md` | 1 line | 1 line |
| `grep "For all artifact types" sara-artifact-sorter.md` | 1 line | 1 line |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — segments inference logic is fully specified. Actual segment resolution happens at runtime when sara-extract runs against a source document with a populated config.segments array.

## Threat Flags

No new threat surface introduced. The config.json read and STK wiki page read are both existing read patterns already present in sara-extract. The threat model dispositions (T-12-02 accept, T-12-03 accept) are consistent with the implementation: config.segments is project-internal, and missing STK pages degrade gracefully to keyword matching or empty fallback without halting the skill.

## Self-Check: PASSED

- `.claude/skills/sara-extract/SKILL.md` — modified, committed caecef3
- `.claude/agents/sara-artifact-sorter.md` — modified, committed d4c3faf
- Both commits confirmed in git log
