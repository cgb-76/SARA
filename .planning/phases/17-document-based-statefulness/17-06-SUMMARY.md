---
phase: 17-document-based-statefulness
plan: "06"
subsystem: skills
tags: [sara-minutes, pipeline-state, state.md, log.md, skill-rewrite]

requires:
  - phase: 17-03
    provides: sara-discuss rewritten with state.md guards (confirms state.md frontmatter schema)
  - phase: 17-04
    provides: sara-extract rewritten with plan.md output (confirms log.md as authoritative ID source)

provides:
  - "sara-minutes SKILL.md rewritten: reads .sara/pipeline/{N}/state.md for type+stage guards"
  - "sara-minutes discovers actual entity IDs from wiki/log.md wikilinks (not plan.md placeholders)"
  - "No pipeline-state.json, extraction_plan, or assigned_id references remain in sara-minutes"

affects: [17-document-based-statefulness, sara-minutes-usage]

tech-stack:
  added: []
  patterns:
    - "state.md type guard BEFORE stage guard: item.type == meeting checked first, item.stage == complete checked second"
    - "wiki/log.md entity ID discovery: parse [[REQ-001]] wikilinks from log row for ingest item {N}"
    - "Pitfall 7 avoidance: plan.md contains placeholder IDs at write time; log.md has actual committed IDs"

key-files:
  created: []
  modified:
    - ".claude/skills/sara-minutes/SKILL.md"

key-decisions:
  - "Use wiki/log.md (not plan.md) as authoritative source of committed entity IDs for sara-minutes"
  - "TYPE guard runs before STAGE guard: non-meeting items must never reach log.md traversal"

patterns-established:
  - "Pattern 6: sara-minutes reads wiki/log.md log row wikilinks to discover entity IDs written for ingest item"
  - "Pattern 5 (applied): state.md frontmatter type+stage guards replace pipeline-state.json items lookup"

requirements-completed: [STF-06]

duration: 2min
completed: 2026-05-01
---

# Phase 17 Plan 06: sara-minutes SKILL.md Summary

**sara-minutes rewritten to read `.sara/pipeline/{N}/state.md` for type/stage guards and `wiki/log.md` for actual committed entity IDs, removing all pipeline-state.json and extraction_plan dependencies**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-01T04:21:20Z
- **Completed:** 2026-05-01T04:23:10Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Replaced pipeline-state.json item lookup with Read `.sara/pipeline/{N}/state.md` + YAML frontmatter parsing
- Type guard (`item.type == "meeting"`) now runs BEFORE stage guard (`item.stage == "complete"`) — enforces D-02, D-03 ordering
- Replaced extraction_plan traversal (with assigned_id/existing_id) with wiki/log.md entity ID discovery: reads log row wikilinks `[[REQ-001]]`, `[[DEC-002]]` etc. for the matching ingest item
- Added notes documenting Pitfall 7 (plan.md placeholder IDs) and the mandatory TYPE-then-STAGE guard order

## Task Commits

1. **Task 1: Rewrite sara-minutes SKILL.md with state.md guards and log.md entity discovery** — `05ecf34` (feat)

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `.claude/skills/sara-minutes/SKILL.md` — Full rewrite: removed pipeline-state.json, extraction_plan, assigned_id; added state.md guards (type first, stage second) and log.md entity ID discovery

## Decisions Made

- Followed plan exactly: wiki/log.md is the authoritative source of committed entity IDs because plan.md contains placeholder IDs (REQ-NNN) at write time; by stage=complete the actual IDs are in the log
- Guard order preserved: TYPE check must run before STAGE check — a non-meeting item must never reach log.md traversal

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. The only verification anomaly was the initial grep running in the wrong working directory (worktree vs repo root) — resolved by using absolute paths. The file content itself passed all acceptance criteria on first write.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- sara-minutes is now fully aligned with the document-based-statefulness schema
- All six pipeline skills (sara-init, sara-ingest, sara-discuss, sara-extract, sara-update, sara-minutes) have been rewritten for Phase 17
- Phase 17 wave 3 complete; ready for orchestrator merge

## Self-Check

- `.claude/skills/sara-minutes/SKILL.md` exists and was modified: VERIFIED
- `grep -c "pipeline-state.json"` returns 0: VERIFIED
- `grep -c "extraction_plan"` returns 0: VERIFIED
- `grep -c "assigned_id"` returns 0: VERIFIED
- `grep -q "log.md"` matches: VERIFIED (8 occurrences)
- `grep -q "state.md"` matches: VERIFIED (5 occurrences)
- `grep -q "TYPE then STAGE"` matches: VERIFIED
- `grep -q "plan.md contains placeholder"` matches: VERIFIED
- Commit `05ecf34` exists: VERIFIED

## Self-Check: PASSED

---
*Phase: 17-document-based-statefulness*
*Completed: 2026-05-01*
