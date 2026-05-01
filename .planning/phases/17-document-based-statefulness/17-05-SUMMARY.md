---
phase: 17-document-based-statefulness
plan: 05
subsystem: sara-update
tags: [sara, pipeline, state-md, plan-md, filesystem-counters, config-json]

requires:
  - phase: 17-document-based-statefulness/17-03
    provides: sara-extract SKILL.md writes plan.md (which sara-update now reads)
  - phase: 17-document-based-statefulness/17-04
    provides: sara-discuss SKILL.md writes discuss.md (which sara-update reads for discussion_notes)

provides:
  - sara-update SKILL.md reads stage guard from .sara/pipeline/{N}/state.md (not pipeline-state.json)
  - sara-update reads artifact list by LLM-parsing .sara/pipeline/{N}/plan.md (not extraction_plan JSON array)
  - sara-update reads discussion_notes from .sara/pipeline/{N}/discuss.md with empty-string fallback
  - sara-update derives entity IDs from ls wiki/{type}/ glob (not counters.entity JSON field)
  - sara-update reads summary_max_words from .sara/config.json (default 50) once before the write loop
  - sara-update writes state.md with stage: complete ONLY after git commit succeeds
  - sara-update git add includes .sara/pipeline/{N}/state.md for stage advance (not pipeline-state.json)

affects:
  - sara-lint (invoked by sara-update on success — unaffected by this change)
  - any SARA project using the update pipeline command

tech-stack:
  added: []
  patterns:
    - "Filesystem glob for entity ID derivation: ls wiki/{type}/ | grep ^{KEY}- | sort | tail -1"
    - "Stage advance in state.md via Write tool ONLY after git commit exit code 0"
    - "plan.md LLM parsing: Read tool + LLM reasoning over headed sections, no regex"
    - "discuss.md graceful fallback: Read returns error → empty string, do not stop"
    - "summary_max_words from config.json read once before artifact loop (not per-artifact)"

key-files:
  created: []
  modified:
    - .claude/skills/sara-update/SKILL.md

key-decisions:
  - "Internal variable {artifact_list} replaces {extraction_plan} — the old JSON field name is gone"
  - "summary_max_words read from .sara/config.json with default 50 — no backward compatibility for pipeline-state.json per D-05"
  - "Stage advance uses two-commit pattern: wiki commit first, then git add state.md + commit stage: complete"

patterns-established:
  - "Stage: complete written to state.md ONLY after wiki git commit succeeds (Pitfall 1 mitigation)"
  - "state.md read once in Step 1, never re-read inside entity write loop (Pitfall 2 mitigation)"
  - "Write tool is synchronous — filesystem glob after each page write sees that page immediately (Pitfall 3 explanation)"

requirements-completed: [STF-05]

duration: 5min
completed: 2026-05-01
---

# Phase 17 Plan 05: sara-update Summary

**sara-update SKILL.md rewritten: reads artifact plan from plan.md via LLM parsing, derives entity IDs from filesystem glob, reads summary_max_words from config.json, and advances stage: complete in state.md only after the wiki git commit succeeds**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-01T04:21:11Z
- **Completed:** 2026-05-01T04:26:08Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Removed all six pipeline-state.json read/write operations from sara-update
- Step 1 now reads .sara/pipeline/{N}/state.md for stage guard and item metadata, and reads .sara/pipeline/{N}/plan.md for the artifact list via LLM parsing
- Step 1b now reads .sara/pipeline/{N}/discuss.md for discussion_notes (empty string fallback if absent)
- Step 2 derives entity IDs from filesystem glob (ls wiki/{type}/ | grep ^{KEY}- | sort | tail -1) instead of incrementing counters.entity in JSON
- summary_max_words read once from .sara/config.json before the artifact loop (default 50)
- Step 4 git add no longer includes pipeline-state.json; writes state.md with stage: complete as a separate commit ONLY after the wiki commit succeeds
- Notes section updated with three CRITICAL pitfall warnings

## Task Commits

1. **Task 1: Rewrite sara-update SKILL.md** - `93be04b` (feat)

## Files Created/Modified

- `.claude/skills/sara-update/SKILL.md` - Full rewrite: pipeline-state.json removed, state.md/plan.md/discuss.md reads added, filesystem entity counter derivation, config.json summary_max_words, stage: complete sequencing enforced

## Decisions Made

- Internal list variable renamed from `{extraction_plan}` to `{artifact_list}` to eliminate the old JSON field name entirely from the skill
- No backward compatibility for pipeline-state.json per locked decision D-05 (new repos only)
- Two-commit pattern for stage advance: (1) wiki artifacts commit, (2) state.md stage: complete commit — preserves the atomic ordering invariant from the original skill

## Deviations from Plan

None — plan executed exactly as written. Minor internal variable rename ({extraction_plan} → {artifact_list}) was required to satisfy the zero-extraction_plan acceptance criterion; this is within the spirit of Change 1 (remove JSON field name references) and was applied inline.

## Issues Encountered

Initial write had two residual references that failed the grep acceptance criteria:
- `extraction_plan` used as the internal variable name (lines 44 and 83) — fixed by renaming to `{artifact_list}`
- `pipeline-state.json` appeared in the notes as a parenthetical "not pipeline-state.json" clarification — removed to satisfy the zero-count requirement

Both were fixed via targeted Edit tool calls before committing.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- sara-update now reads from the document-based pipeline state (.sara/pipeline/{N}/) consistent with the changes made in plans 17-01 through 17-04
- Plan 17-06 (sara-minutes) is the final skill to update and can proceed independently
- All six pipeline skills are now aligned to the new state backend once 17-06 completes

---
*Phase: 17-document-based-statefulness*
*Completed: 2026-05-01*

## Self-Check: PASSED

- `.claude/skills/sara-update/SKILL.md` — FOUND
- `.planning/phases/17-document-based-statefulness/17-05-SUMMARY.md` — FOUND
- Commit `93be04b` — FOUND
- pipeline-state.json count: 0
- extraction_plan count: 0
- counters.entity count: 0
- plan.md reference: PRESENT
- config.json reference: PRESENT
- sort|tail-1 pattern: PRESENT
- stage ONLY after note: PRESENT
- Do NOT re-read note: PRESENT
