---
phase: 11-refine-risks
plan: 01
subsystem: extraction
tags: [sara-extract, risk-artifacts, risk_type, owner-warning, skill-md]

# Dependency graph
requires:
  - phase: 10-refine-actions
    provides: "owner/raised_by distinction pattern, Step 4 owner-not-resolved warning for actions"
provides:
  - "sara-extract risk pass rewritten with tightened signal definition, six-type risk_type taxonomy, owner field, likelihood/impact capture, signal-based status"
  - "Step 4 owner warning extended to cover risk artifacts via OR condition"
affects: [11-refine-risks plan-02 (sara-update), 11-refine-risks plan-03 (sara-init)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Risk pass INCLUDE/EXCLUDE pattern: mirrors action pass structure from Phase 10"
    - "Owner warning OR condition: single warning block covers both action and risk types"
    - "Signal-based field capture: likelihood/impact/status left empty when no source signal present"

key-files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md

key-decisions:
  - "risk_type field name (not type) avoids collision with envelope type: risk field — consistent with dec_type/act_type pattern"
  - "owner and raised_by are distinct fields: owner = responsible for tracking/mitigation; raised_by = who surfaced it in source"
  - "likelihood and impact are empty string by default — only populated when source contains explicit signal; no invented values"
  - "status defaults to open; mitigated/accepted only assigned on explicit source language"
  - "IF/THEN and Mitigation are NOT extracted — synthesised by sara-update from full source document in context"
  - "Step 4 owner warning uses OR condition covering both action and risk types in a single block (not duplicate blocks)"

patterns-established:
  - "Extraction-pass INCLUDE/EXCLUDE pattern: use for any future pass refinement"
  - "Owner OR condition pattern: single warning block for all artifact types requiring owner tracking"

requirements-completed:
  - WIKI-04

# Metrics
duration: 8min
completed: 2026-04-29
---

# Phase 11 Plan 01: Refine sara-extract Risk Pass Summary

**sara-extract risk pass rewritten with tightened signal definition, six-type risk_type taxonomy, owner/raised_by distinction, likelihood/impact signal capture, signal-based status — Step 4 owner warning extended to cover risk artifacts**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-29T13:15:00Z
- **Completed:** 2026-04-29T13:23:28Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Replaced the vague four-bullet risk pass with a structured pass including tightened signal definition, INCLUDE/EXCLUDE examples, six-type risk_type taxonomy, and seven per-artifact fields (risk_type, owner, raised_by, likelihood, impact, status, source_quote)
- Extended the Step 4 owner-not-resolved warning from action-only to cover both action and risk artifact types via an OR condition, consistent with D-16

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite sara-extract risk pass (Step 3)** - `0770d6f` (feat)
2. **Task 2: Extend Step 4 owner warning to cover risk artifacts** - `817d988` (feat)

**Plan metadata:** `(pending docs commit)` (docs: complete plan)

## Files Created/Modified
- `.claude/skills/sara-extract/SKILL.md` - Risk pass (Step 3) rewritten; Step 4 owner warning extended to risk artifacts

## Decisions Made
- Followed D-01 through D-06 and D-16 exactly as specified in 11-CONTEXT.md. No implementation choices required beyond selecting the edit boundaries.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 01 complete: sara-extract risk pass is D-01–D-06 and D-16 compliant
- Plan 02 (sara-update) can now consume risk artifacts with the new fields: risk_type, owner, likelihood, impact, status
- Plan 03 (sara-init) can update the risk schema template and CLAUDE.md block to v2.0

## Known Stubs

None - no stubs introduced. The new fields (risk_type, owner, likelihood, impact, status) flow directly from the extraction pass output to the artifact JSON array, consistent with the established pipeline pattern.

## Threat Flags

None - no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. The skill file is markdown prompt content; changes are review-visible in git diff (T-11-01-01 accepted per plan threat model).

## Self-Check: PASSED

- `.claude/skills/sara-extract/SKILL.md` exists and contains all required fields
- Task 1 commit `0770d6f` confirmed in git log
- Task 2 commit `96d470f` confirmed in git log
- All 8 plan verification checks passed

---
*Phase: 11-refine-risks*
*Completed: 2026-04-29*
