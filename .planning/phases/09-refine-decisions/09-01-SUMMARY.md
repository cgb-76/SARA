---
phase: 09-refine-decisions
plan: "01"
subsystem: sara-extract, sara-artifact-sorter
tags: [decisions, extraction, artifact-schema, two-signal-detection, dec_type]
dependency_graph:
  requires: []
  provides:
    - Two-signal decision detection (COMMITMENT/MISALIGNMENT) in sara-extract
    - Six-type dec_type taxonomy in sara-extract decisions pass
    - Decision passthrough rule in sara-artifact-sorter
  affects:
    - .claude/skills/sara-extract/SKILL.md
    - .claude/agents/sara-artifact-sorter.md
tech_stack:
  added: []
  patterns:
    - Signal-list detection pattern (same approach as Phase 8 modal-verb anchored requirement extraction)
    - Passthrough rule pattern for sorter (mirrors existing requirement passthrough rule)
key_files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md
    - .claude/agents/sara-artifact-sorter.md
decisions:
  - Two-signal detection (COMMITMENT/MISALIGNMENT) adopted for decisions — mirrors Phase 8 modal-verb approach for requirements
  - dec_type field name (not type) used to avoid collision with envelope type field
  - Three EXCLUDE negative examples added to block false positives (option exploration, aspiration, obligation)
  - British English organisational spelling used throughout per project convention
  - context and rationale excluded from extraction artifact — synthesised by sara-update from full source
metrics:
  duration_minutes: 15
  completed_date: "2026-04-29"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 9 Plan 01: Refine Decisions Summary

## One-liner

Two-signal decision detection (commitment language → accepted, misalignment language → open) with six-type dec_type taxonomy and sorter passthrough for status, dec_type, chosen_option, and alternatives.

## What Was Built

Rewrote the sara-extract decisions pass and extended the sara-artifact-sorter output schema to support richer decision artifacts.

**Task 1 — sara-extract/SKILL.md decisions pass rewrite:**

The old catch-all pass ("a deliberate choice made by the team that was concluded") was replaced with an explicit two-signal detector:

- COMMITMENT language signal list (8 phrases) → `status: accepted`
- MISALIGNMENT language signal list (5 patterns) → `status: open`
- Three EXCLUDE negative examples (option exploration, aspiration/wish, requirement/obligation) to block false positives
- Six-type `dec_type` taxonomy: architectural, process, tooling, data, business-rule, organisational
- Four new artifact fields per decision: `status`, `dec_type`, `chosen_option`, `alternatives`
- `dec_type` field name chosen over `type` to avoid collision with the envelope `type: "decision"` field
- Explicit exclusion of `context` and `rationale` — these are synthesised by sara-update, not extracted inline

**Task 2 — sara-artifact-sorter.md schema extension:**

- Added create decision object example (with all four new fields: status, dec_type, chosen_option, alternatives)
- Extended update decision object example with the same four fields
- Added decision passthrough rule parallel to the existing requirement passthrough rule, ensuring all four fields survive the sorter Task() call unchanged

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite sara-extract Step 3 decisions pass | a4abed9 | .claude/skills/sara-extract/SKILL.md |
| 2 | Fix sara-artifact-sorter decision schema | 4aac094 | .claude/agents/sara-artifact-sorter.md |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no placeholder values or incomplete wiring introduced.

## Threat Flags

No new security-relevant surface introduced. Both files are author-controlled skill/agent markdown; no network endpoints, auth paths, or schema changes at trust boundaries. Threat T-09-03 (over-extraction bloat) mitigated by three EXCLUDE negative examples. Threat T-09-04 (dec_type/type collision) mitigated by explicit `dec_type` field naming.

## Self-Check: PASSED

- `.claude/skills/sara-extract/SKILL.md` — modified and committed (a4abed9)
- `.claude/agents/sara-artifact-sorter.md` — modified and committed (4aac094)
- Commit a4abed9 exists in git log
- Commit 4aac094 exists in git log
