---
phase: 7
plan: "01"
title: "Rewrite sara-extract Step 3 with sequential inline extraction passes"
subsystem: sara-extract
tags: [skill, extraction, architecture, refactor]
dependency_graph:
  requires: []
  provides: [sara-extract-inline-passes]
  affects: [sara-extract]
tech_stack:
  added: []
  patterns: [inline-sequential-passes, no-specialist-agents]
key_files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md
decisions:
  - "Extraction runs as four sequential inline passes against the already-in-context source document rather than dispatching specialist Task() agents — source document is read once in Step 2 and stays in context; only the small merged artifact array is passed to the sorter"
  - "Stale agent-dispatch note in notes section updated to describe inline pass architecture"
metrics:
  duration: "~21 minutes"
  completed: "2026-04-29T04:27:57Z"
  tasks_completed: 5
  tasks_total: 5
  files_changed: 1
---

# Phase 7 Plan 01: Rewrite sara-extract Step 3 with sequential inline extraction passes — Summary

## One-liner

Replaced four specialist Task() agent dispatches in sara-extract Step 3 with four sequential inline extraction passes (requirement → decision → action → risk) keeping the sorter Task() unchanged.

## What Was Built

The `sara-extract` SKILL.md was updated to remove the parallel specialist agent dispatch pattern (Task() calls to `sara-requirement-extractor`, `sara-decision-extractor`, `sara-action-extractor`, `sara-risk-extractor`) and replace it with four sequential inline LLM extraction passes against the source document already in context from Step 2.

Changes made:
1. **Frontmatter description** updated from "Present planned wiki artifacts for per-artifact approval before any wiki writes" to the new inline architecture description.
2. **Objective block** updated to replace "dispatches four specialist extraction agents via Task() in parallel" with "runs four sequential inline extraction passes (requirement → decision → action → risk)".
3. **Step 3 heading** changed from "Dispatch specialist agents and sorter" to "Inline extraction passes and sorter".
4. **Step 3 body** replaced: removed Task() calls for four specialist agents, added four named pass sections (Requirements pass, Decisions pass, Actions pass, Risks pass) each with inline extraction instructions and MANDATORY source_quote requirement. Merge and sorter dispatch logic preserved unchanged.
5. **Notes section**: added new bullet documenting inline pass architecture; updated stale bullet that still described specialist agent dispatch.

The sorter Task() call, Steps 1, 2, 4, 5, and all other notes are intact and unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed stale agent-dispatch note in notes section**
- **Found during:** Post-edit verification (V3)
- **Issue:** The notes section contained a bullet beginning "Agent dispatch: sara-extract spawns four specialist agents..." which still described the old Task()-based architecture and would have contradicted the new inline pass approach.
- **Fix:** Updated the note to describe the inline extraction architecture, matching the new Step 3 implementation.
- **Files modified:** `.claude/skills/sara-extract/SKILL.md`
- **Commit:** 19c12ef (included in same commit)

## Verification Results

All five plan verification checks passed:
1. No old Task() specialist agent references (`Dispatch specialist agents`, `Task.*sara-requirement`, etc.) — 0 matches
2. New inline pass headings present — 5 matches (Step 3 heading + 4 pass headings)
3. Sorter Task() retained — exactly 1 match
4. `source_quote` MANDATORY language in each of the 4 pass sections — lines 55, 66, 76, 86
5. Step 4 heading `**Step 4 — Per-artifact approval loop**` present and unchanged

## Known Stubs

None.

## Threat Flags

None — this is a skill documentation refactor with no new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- File `.claude/skills/sara-extract/SKILL.md` exists and contains new Step 3 content
- Commit 19c12ef exists in git log
