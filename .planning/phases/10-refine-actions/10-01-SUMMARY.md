---
phase: 10-refine-actions
plan: "01"
subsystem: extraction
tags: [sara-extract, action-extraction, skill-file, prompt-engineering]

# Dependency graph
requires:
  - phase: 09-refine-decisions
    provides: two-signal decision detection pattern and decisions pass structure (direct analog for action pass replacement)
provides:
  - "Rewritten action extraction pass (Step 3) with positive signal definition, INCLUDE/EXCLUDE examples, act_type classification, owner/due_date/raised_by fields"
  - "Owner-not-resolved warning in Step 4 approval loop (D-13), injected once before artifact block"
affects:
  - 10-02 (sara-update action write branch uses act_type, owner, due_date from this pass)
  - 10-03 (sara-init action template must match schema produced here)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Positive signal extraction: 'A passage IS an action if it describes any work that needs to happen' — broadest-net approach with INCLUDE/EXCLUDE examples"
    - "Two-type inline classification: act_type (deliverable/follow-up) set inline during extraction pass"
    - "Owner-not-resolved warning pattern: conditional plain-text output before AskUserQuestion, not inside Discuss loop"

key-files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md

key-decisions:
  - "Action extraction signal is any passage implying work needs to happen (D-01) — broadest net, sorter handles disambiguation"
  - "act_type classifies each action as deliverable or follow-up inline during extraction (D-04)"
  - "owner is a distinct field from raised_by — owner=who does the work, raised_by=who surfaced it (D-05)"
  - "due_date extracted as raw string from source, no normalisation at extraction time (D-02)"
  - "Owner-not-resolved warning appears once before artifact block in Step 4, conditional on action type and STK-NNN pattern check (D-13)"

patterns-established:
  - "action pass structure mirrors decisions pass: positive signal definition → INCLUDE/EXCLUDE → inline type classification → per-artifact field list → collect line"
  - "owner warning injection: check artifact.type == action AND owner empty or not STK-\\d{3} BEFORE presenting artifact, NOT inside Discuss loop"

requirements-completed:
  - WIKI-03

# Metrics
duration: 2min
completed: "2026-04-29"
---

# Phase 10 Plan 01: Refine-actions sara-extract action pass Summary

**Rewrote sara-extract action extraction pass with broadest-net positive signal definition, deliverable/follow-up act_type classification, distinct owner/due_date fields, and D-13 owner-not-resolved warning in approval loop**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-29T12:15:46Z
- **Completed:** 2026-04-29T12:17:53Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Replaced the vague single-paragraph action pass ("a concrete task or follow-up with an implied or explicit owner") with a structured pass mirroring the Phase 9 decisions pass pattern
- Added positive signal definition (D-01), INCLUDE/EXCLUDE examples covering unowned tasks, background context, risks, requirements, and decisions
- Added `act_type` (deliverable/follow-up), `owner` (distinct from raised_by), and `due_date` (raw string) fields to the artifact schema per D-02, D-04, D-05
- Injected owner-not-resolved warning (D-13) in Step 4 approval loop, exactly once before the artifact presentation block, with `STK-\d{3}` pattern check and action-type guard

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite sara-extract action pass (Step 3)** - `abe93df` (feat)
2. **Task 2: Add owner-not-resolved warning to Step 4 approval loop** - `d71dc20` (feat)

**Plan metadata:** (committed with SUMMARY below)

## Files Created/Modified

- `.claude/skills/sara-extract/SKILL.md` - Action extraction pass (lines 138-172) replaced with structured pass; owner-not-resolved warning added before Step 4 artifact presentation block

## Decisions Made

- Added `act_type` to the classification block header line ("classify it into one of two `act_type` values inline") in addition to the field extraction list, satisfying the >= 2 occurrence acceptance criterion while staying true to the plan's intent
- Followed plan replacement text verbatim; no architectural changes required

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added `act_type` to classification block header for acceptance criterion compliance**
- **Found during:** Task 1 (post-edit verification)
- **Issue:** Plan replacement text produced only 1 occurrence of `act_type` (in field list only), but acceptance criterion requires >= 2 (in "classification block and in field extraction list")
- **Fix:** Changed "For each action found, classify it into one of two types inline:" to "For each action found, classify it into one of two `act_type` values inline:" — one-word addition making the classification block explicitly name the field
- **Files modified:** .claude/skills/sara-extract/SKILL.md
- **Verification:** `grep -c "act_type" .claude/skills/sara-extract/SKILL.md` returns 2
- **Committed in:** abe93df (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — acceptance criterion compliance)
**Impact on plan:** Minimal one-word fix to satisfy stated acceptance criterion; no semantic change to extraction behaviour.

## Issues Encountered

None — plan executed cleanly. Both tasks completed in the expected order with all acceptance criteria passing.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 10-01 complete: sara-extract now produces action artifacts with `act_type`, `owner`, `due_date`, `raised_by`, `source_quote` fields
- Plan 10-02 (sara-update action write branch) can now map `artifact.act_type` → `type`, `artifact.owner` → `owner`, `artifact.due_date` → `due-date` from the artifact schema
- Plan 10-03 (sara-init action template and CLAUDE.md schema block) should match the v2.0 frontmatter shape produced by 10-02

---
*Phase: 10-refine-actions*
*Completed: 2026-04-29*
