---
phase: 08-refine-requirements
plan: "01"
subsystem: extraction-pipeline
tags: [sara-extract, sara-artifact-sorter, requirements, modal-verb, moscow, req_type]
dependency_graph:
  requires: []
  provides: [modal-verb-anchored-requirements-pass, priority-req_type-passthrough]
  affects: [sara-extract, sara-artifact-sorter, sara-update]
tech_stack:
  added: []
  patterns: [modal-verb-signal, moscow-priority-mapping, six-type-classification, passthrough-rule]
key_files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md
    - .claude/agents/sara-artifact-sorter.md
decisions:
  - Modal-verb anchoring chosen as primary extraction signal to eliminate false positives (observations, aspirations, background context)
  - Six req_type labels added inline in same pass as priority to avoid a second LLM pass
  - Sorter passthrough rule added as explicit prohibition (not just schema) to prevent silent field dropping
metrics:
  duration: ~8 minutes
  completed: "2026-04-29"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 8 Plan 01: Refine Requirements Extraction Summary

Modal-verb-anchored requirements pass with MoSCoW priority mapping, six-type inline classification, and sorter passthrough rule for `priority` and `req_type`.

## What Was Built

**Task 1 — sara-extract/SKILL.md: Requirements pass rewrite**

The Step 3 requirements pass block was fully replaced. The previous prompt ("Extract every passage that describes a requirement — a capability, constraint, or rule…") produced false positives by relying on topic alone. The new prompt anchors extraction on commitment modal verbs:

- INCLUDE list: must/shall/has to/required to/need to (must-have), will-as-commitment (must-have), should (should-have), could/may (could-have), will not/won't/out of scope/we won't (wont-have)
- EXCLUDE list with three named negative examples: Observation, Aspiration/wish, Background context
- Six `req_type` classifications: functional, non-functional, regulatory, integration, business-rule, data
- Two new per-requirement fields: `priority` (MoSCoW from modal) and `req_type` (inline classification)

**Task 2 — sara-artifact-sorter.md: Output schema and passthrough rule**

Two edits made to ensure `priority` and `req_type` survive the sorter Task() call:

- Edit A: Added `"priority": "must-have"` and `"req_type": "functional"` to the requirement object example in `<output_format>` (decision object unchanged)
- Edit B: Added explicit passthrough rule in Rules section: "For requirement artifacts, preserve `priority` and `req_type` exactly as received from the extraction pass. Do not modify, reclassify, or drop these fields."

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 55c7d84 | feat(08-01): rewrite sara-extract Step 3 requirements pass with modal-verb anchoring |
| 2 | 3faf95c | feat(08-01): fix sara-artifact-sorter output schema for priority and req_type passthrough |

## Deviations from Plan

None — plan executed exactly as written.

## Success Criteria Verification

| Criterion | Status |
|-----------|--------|
| sara-extract requirements pass anchored on modal verbs (D-01) | PASS |
| Three explicit negative examples present (D-02) | PASS — Observation, Aspiration/wish, Background context |
| MoSCoW mapping from modal to priority in INCLUDE list (D-03) | PASS |
| `priority` and `req_type` assigned in same inline pass (D-04) | PASS |
| All six type labels present with descriptions (D-05) | PASS |
| sara-artifact-sorter passes `priority` and `req_type` through unchanged | PASS |

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. Changes are skill text (LLM prompt instructions) only.

## Self-Check: PASSED

- `.claude/skills/sara-extract/SKILL.md` — exists, modified, committed at 55c7d84
- `.claude/agents/sara-artifact-sorter.md` — exists, modified, committed at 3faf95c
- Both commit hashes verified in git log
