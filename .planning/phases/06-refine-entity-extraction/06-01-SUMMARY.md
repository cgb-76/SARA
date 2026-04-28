---
phase: 06-refine-entity-extraction
plan: 01
subsystem: agents
tags: [specialist-agents, task-dispatch, entity-extraction, sara-extract]

# Dependency graph
requires:
  - phase: 05-artifact-summaries
    provides: sara-extract skill with Task() dispatch pattern for specialist agents
provides:
  - Four specialist extraction agent files in .claude/agents/ (requirement, decision, action, risk)
  - Isolated per-type extraction with mandatory source_quote and wiki access prohibition
affects: [sara-extract, 06-refine-entity-extraction]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Specialist agent file pattern: name/description/tools/color frontmatter + role/input/process/output_format/notes sections"
    - "tools: comma-separated string (not YAML list) for agent files vs allowed-tools list for SKILL.md files"

key-files:
  created:
    - .claude/agents/sara-requirement-extractor.md
    - .claude/agents/sara-decision-extractor.md
    - .claude/agents/sara-action-extractor.md
    - .claude/agents/sara-risk-extractor.md
  modified: []

key-decisions:
  - "All four specialist agents use tools: Read, Bash (comma-separated string) — not YAML list, not allowed-tools"
  - "action field in output is always 'create' — create-vs-update resolution is the sorter's responsibility"
  - "source_quote is MANDATORY in every specialist agent — no artifact without verbatim text from source"
  - "Specialists explicitly prohibit wiki/index.md access — dedup belongs to the sorter, not the specialists"
  - "discussion_notes passed explicitly via prompt — agents start cold with no implicit pipeline-state.json access"

patterns-established:
  - "Specialist agent isolation pattern: each agent receives source_document + discussion_notes, returns raw JSON array only"
  - "id_to_assign uses type-specific NNN placeholder (REQ-NNN, DEC-NNN, ACT-NNN, RSK-NNN) — real ID assigned by sorter"

requirements-completed: []

# Metrics
duration: 10min
completed: 2026-04-28
---

# Phase 06 Plan 01: Specialist Extraction Agents Summary

**Four isolated specialist agent files created in .claude/agents/ for sara-extract Task() dispatch, each returning raw JSON arrays with mandatory source_quote and wiki access prohibition**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-28T11:00:00Z
- **Completed:** 2026-04-28T11:09:44Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created sara-requirement-extractor.md — extracts REQ-NNN artifacts with verbatim source_quote
- Created sara-decision-extractor.md — extracts DEC-NNN artifacts with verbatim source_quote
- Created sara-action-extractor.md — extracts ACT-NNN artifacts with verbatim source_quote
- Created sara-risk-extractor.md — extracts RSK-NNN artifacts with verbatim source_quote
- All four agents use correct agent frontmatter format (tools: comma-separated, no allowed-tools, no version)
- All four agents prohibit wiki/index.md access (dedup isolation per D-04)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create sara-requirement-extractor and sara-decision-extractor agent files** - `afb2bdc` (feat)
2. **Task 2: Create sara-action-extractor and sara-risk-extractor agent files** - `3d2d30f` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `.claude/agents/sara-requirement-extractor.md` - Specialist agent for requirement artifact extraction via Task() dispatch
- `.claude/agents/sara-decision-extractor.md` - Specialist agent for decision artifact extraction via Task() dispatch
- `.claude/agents/sara-action-extractor.md` - Specialist agent for action artifact extraction via Task() dispatch
- `.claude/agents/sara-risk-extractor.md` - Specialist agent for risk artifact extraction via Task() dispatch

## Decisions Made
- All agents use `tools: Read, Bash` as a comma-separated string (agent file format) not YAML list (SKILL.md format)
- Each specialist outputs `"action": "create"` only — create-vs-update resolution deferred to the sorter/sara-extract
- `source_quote` declared MANDATORY in every output_format block — no artifact without verbatim source evidence
- All four agents explicitly prohibit wiki access in both process and notes sections — isolation is structural

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all four agents are complete and functional. No placeholder or stub content.

## Threat Flags
None - no new network endpoints, auth paths, or trust boundary crossings. Files are git-tracked static markdown. Tools restricted to Read and Bash (no Write) per T-06-03.

## Next Phase Readiness
- All four specialist extraction agent files are ready for Task() dispatch from sara-extract
- sara-extract can now delegate per-type extraction by agent name (sara-requirement-extractor, sara-decision-extractor, etc.)
- Sorter-side dedup and create-vs-update resolution remains to be implemented in sara-extract SKILL.md (subsequent plans)

---
*Phase: 06-refine-entity-extraction*
*Completed: 2026-04-28*
