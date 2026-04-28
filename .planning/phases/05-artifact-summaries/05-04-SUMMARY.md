---
phase: 05-artifact-summaries
plan: "04"
subsystem: skills
tags: [sara-lint, wiki, maintenance, summary, back-fill]

# Dependency graph
requires: []
provides:
  - "sara-lint skill: scan wiki artifact pages for missing summary fields and back-fill them with type-specific generated summaries"
  - "Extensibility stubs for Check 2 (orphaned pages) and Check 3 (broken cross-refs) ready for v2"
affects:
  - sara-extract
  - sara-discuss
  - 05-artifact-summaries

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "wiki-existence guard before any scan operation"
    - "dry-run preview + explicit AskUserQuestion confirmation before batch writes"
    - "grep -rL pattern for finding pages missing a required frontmatter field"
    - "per-file Read+Write loop without shell text-processing tools"
    - "exit-code gate on git commit before reporting success"

key-files:
  created:
    - ".claude/skills/sara-lint/SKILL.md"
  modified: []

key-decisions:
  - "summary field inserted immediately after related: field for consistent position across all entity types"
  - "summary_max_words defaults to 50 if absent from pipeline-state.json, matching D-07"
  - "git commit issued only after ALL files in {missing_files} are written — no partial commits"
  - "re-run safety: grep -rL only returns files still missing summary, so re-running after partial failure is safe"
  - "Check 2 and Check 3 left as clearly-marked v2 stubs with HTML comments pointing to future implementation"

patterns-established:
  - "sara-lint Check 1 scan: grep -rL across all five wiki subdirectories"
  - "commit message fixed: 'fix(wiki): back-fill artifact summaries via sara-lint'"

requirements-completed: []

# Metrics
duration: 5min
completed: 2026-04-28
---

# Phase 5 Plan 04: sara-lint Skill Summary

**New /sara-lint skill that scans wiki artifact pages for missing summary fields using grep -rL, shows a dry-run preview of one generated summary, asks for confirmation via AskUserQuestion, then back-fills all missing summaries with type-specific prose using Read+Write tools only, and commits with a fixed message.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-28T00:00:00Z
- **Completed:** 2026-04-28T00:05:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `.claude/skills/sara-lint/SKILL.md` implementing the full Check 1 (missing summaries) flow
- Wiki existence guard terminates cleanly if wiki/ directory is absent
- Dry-run preview of one generated summary shown before any writes occur
- AskUserQuestion confirmation gate prevents accidental batch writes
- Per-file back-fill loop reads and writes via Read+Write tools only (no jq/sed/awk)
- Git commit with exact fixed message, exit code checked before success report
- Check 2 (orphaned pages) and Check 3 (broken cross-refs) stubbed and clearly marked v2

## Task Commits

Each task was committed atomically:

1. **Task 1: Create .claude/skills/sara-lint/SKILL.md** - `0b1bdb9` (feat)

**Plan metadata:** (committed with SUMMARY below)

## Files Created/Modified

- `.claude/skills/sara-lint/SKILL.md` - New maintenance skill: wiki summary back-fill with dry-run confirm and commit

## Decisions Made

- summary field inserted immediately after the `related:` field in frontmatter — consistent position across all entity types (REQ, DEC, ACT, RISK, STK)
- summary_max_words defaults to 50 if absent from pipeline-state.json — matches D-07 from phase context
- Git commit issued only after ALL files are written — no partial commits; re-run is safe because grep -rL skips already-summarised files
- Check 2 and Check 3 left as clearly-marked v2 stubs with HTML comments describing future implementation targets

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `/sara-lint` skill is ready to use in any project with a wiki/ directory
- Check 1 (missing summaries) is fully implemented and re-run-safe
- Check 2 and Check 3 stubs are in place and annotated for future implementation
- The grep-extract pattern used by sara-extract and sara-discuss will work correctly for any artifact back-filled by sara-lint

## Known Stubs

None — the stubs in Check 2 and Check 3 are intentional v2 placeholders, not unresolved data gaps. They produce explicit "not implemented in v1" output messages and do not block the plan's primary goal.

## Self-Check

- [x] `.claude/skills/sara-lint/SKILL.md` exists — verified
- [x] Task commit `0b1bdb9` exists — verified
- [x] grep -rL command present in SKILL.md — verified
- [x] "fix(wiki): back-fill artifact summaries via sara-lint" commit message present — verified
- [x] Check 2 and Check 3 stubs present and marked v2 — verified
- [x] summary_max_words present with default-50 fallback — verified

## Self-Check: PASSED

---
*Phase: 05-artifact-summaries*
*Completed: 2026-04-28*
