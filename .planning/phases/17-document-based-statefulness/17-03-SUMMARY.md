---
phase: 17-document-based-statefulness
plan: "03"
subsystem: pipeline-skills
tags: [sara-discuss, state.md, discuss.md, pipeline, skill-rewrite]

requires:
  - phase: 17-document-based-statefulness
    provides: "17-01 sara-ingest writes state.md per item; 17-02 sara-extract reads discuss.md"

provides:
  - "sara-discuss SKILL.md reads .sara/pipeline/{N}/state.md for stage guard and item lookup"
  - "sara-discuss SKILL.md writes .sara/pipeline/{N}/discuss.md with markdown prose resolved context"
  - "sara-discuss SKILL.md advances stage to extracting in state.md ONLY after git commit succeeds"

affects: [sara-extract, sara-update, sara-minutes, 17-04, 17-05, 17-06]

tech-stack:
  added: []
  patterns:
    - "state.md frontmatter as stage guard: Read tool → parse YAML → check stage field"
    - "discuss.md markdown prose: Write tool only, no Bash text-processing"
    - "Pitfall 1 guard: write content → git commit → only if success write state.md stage advance"

key-files:
  created: []
  modified:
    - ".claude/skills/sara-discuss/SKILL.md"

key-decisions:
  - "discuss.md uses headed markdown sections (## Resolved Stakeholders, ## Source Comprehension Clarifications) not plain-text string"
  - "Stage advance to extracting split into two commits: discuss.md commit first, then state.md stage commit"
  - "commit-ordering invariant documented twice in notes (once as CRITICAL note, once inline in step 6) to make Pitfall 1 guard explicit"

patterns-established:
  - "Stage guard pattern: Read state.md → parse frontmatter → check stage field → error if wrong"
  - "Atomic commit ordering for discuss step: Write discuss.md → git commit discuss.md → if success: Write state.md stage: extracting → git commit state.md"

requirements-completed: [STF-03]

duration: 4min
completed: 2026-05-01
---

# Phase 17 Plan 03: sara-discuss Rewrite Summary

**sara-discuss SKILL.md rewritten to read state.md frontmatter for stage guard and write discuss.md markdown prose for resolved context, with stage advance gated on git commit success (Pitfall 1 guard)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T04:07:10Z
- **Completed:** 2026-05-01T04:10:45Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Removed all pipeline-state.json read/write references from sara-discuss (0 occurrences confirmed by grep)
- Step 1 now reads `.sara/pipeline/{N}/state.md` with the Read tool and parses YAML frontmatter for id, type, filename, source_path, stage, created fields
- Step 6 writes `.sara/pipeline/{N}/discuss.md` as structured markdown (## Resolved Stakeholders, ## Source Comprehension Clarifications sections) then git-commits, then ONLY on commit success writes state.md with stage: extracting
- Notes section documents Pitfall 1 guard explicitly: "CRITICAL — Stage advance to 'extracting' happens ONLY after the git commit of discuss.md succeeds"

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite sara-discuss SKILL.md with state.md + discuss.md pattern** - `cecc9a4` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `.claude/skills/sara-discuss/SKILL.md` - Rewritten: state.md stage guard in Step 1, source_path from state.md frontmatter in Step 2, discuss.md markdown write + atomic commit ordering in Step 6, updated notes section

## Decisions Made

- discuss.md uses two headed markdown sections (## Resolved Stakeholders, ## Source Comprehension Clarifications) matching the format from RESEARCH.md Pattern 3 — consistent with what sara-extract will read as `{discussion_notes}` context
- Stage advance split across two separate git commits: first commit contains discuss.md only, second commit contains state.md with stage: extracting — this makes the commit history readable and keeps each commit semantically clean
- The "ONLY after" invariant is documented twice: once as a CRITICAL bullet in the notes section and once inline in the Step 6 flow — redundancy is intentional given the severity of Pitfall 1

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The Write tool initially wrote to `/home/george/Projects/sara/.claude/skills/sara-discuss/SKILL.md` (main project) instead of the worktree path. Detected via `git status` (nothing to commit). Read the worktree file explicitly, then wrote to the correct worktree path `.claude/skills/sara-discuss/SKILL.md`. No content loss — same content applied.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- sara-discuss SKILL.md is fully updated to use document-based state
- sara-extract (17-02, if in wave 2) can now read discuss.md as `{discussion_notes}` context
- Remaining pipeline skills (sara-init, sara-ingest, sara-update, sara-minutes) follow the same pattern

---
*Phase: 17-document-based-statefulness*
*Completed: 2026-05-01*
