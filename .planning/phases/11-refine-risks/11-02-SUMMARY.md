---
phase: 11-refine-risks
plan: "02"
subsystem: sara-init
tags: [sara-init, risk-schema, v2.0, skill]

# Dependency graph
requires:
  - phase: 11-refine-risks
    provides: D-07 through D-15 locked decisions for v2.0 risk frontmatter and body structure
provides:
  - sara-init Step 9 CLAUDE.md risk schema block updated to v2.0 (type, raised-by, schema_version '2.0', status open/mitigated/accepted, no mitigation field, four-section body description)
  - sara-init Step 12 risk.md template updated to v2.0 (same frontmatter shape plus four-section body: Source Quote, Risk IF/THEN, Mitigation, Cross Links)
affects: [sara-extract, sara-update, 11-refine-risks]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "schema_version: '2.0' single-quoted — prevents YAML float parse, consistent across requirement/decision/action/risk templates"
    - "risk body uses IF <trigger> THEN <adverse event> format with IF/THEN in caps for precision and Obsidian scannability"
    - "mitigation narrative moved fully to body section — no mitigation frontmatter field"
    - "three-value status lifecycle: open | mitigated | accepted (no closed — forces explicit resolution posture)"

key-files:
  created: []
  modified:
    - .claude/skills/sara-init/SKILL.md

key-decisions:
  - "schema_version: '2.0' uses single quotes — consistent with requirement, decision, action convention; prevents YAML float parse"
  - "mitigation frontmatter field removed — narrative moves fully to ## Mitigation body section (same pattern as Phase 9 removed context/rationale/decision from decision frontmatter)"
  - "type field added to risk frontmatter with six-bucket taxonomy (technical/financial/schedule/quality/compliance/people)"
  - "raised-by field added as distinct from owner — raised_by is attribution, owner is responsibility"
  - "status lifecycle is three values only: open/mitigated/accepted — closed excluded to force explicit resolution posture"

patterns-established:
  - "Risk template four-section body: Source Quote / Risk (IF/THEN) / Mitigation / Cross Links"
  - "IF/THEN format for risk statement with IF and THEN in caps — primary risk description"
  - "Fallback text in Mitigation section: 'No mitigation discussed — define action items to address this risk.'"

requirements-completed: [WIKI-04]

# Metrics
duration: 5min
completed: 2026-04-29
---

# Phase 11 Plan 02: sara-init risk schema and template upgraded to v2.0 with type/raised-by fields, IF/THEN body format, and single-quoted schema_version

**sara-init updated to write v2.0 risk schema: Step 9 CLAUDE.md block and Step 12 risk.md template both upgraded with type/raised-by frontmatter, three-value status lifecycle, mitigation field removed, and four-section body (Source Quote, Risk IF/THEN, Mitigation, Cross Links)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-29T13:21:00Z
- **Completed:** 2026-04-29T13:23:25Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Step 9 CLAUDE.md risk schema block: bumped to v2.0, added `type` and `raised-by` fields, removed `mitigation` frontmatter field, changed status to `open | mitigated | accepted` (removed `closed`), updated `schema_version` to single-quoted `'2.0'`, replaced old v1.0 body headings with description of four-section format
- Step 12 risk.md template: same frontmatter upgrade plus full four-section body written — `## Source Quote` with verbatim quote pattern, `## Risk` with IF/THEN format instruction and synthesis note, `## Mitigation` with fallback text, `## Cross Links` with wikilink rule reference
- Both changes are consistent with D-07 through D-15 locked decisions from 11-CONTEXT.md

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Step 9 CLAUDE.md risk schema block to v2.0** - `6aa47b4` (feat)
2. **Task 2: Update Step 12 risk.md template to v2.0** - `96d470f` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `.claude/skills/sara-init/SKILL.md` — Step 9 risk schema block and Step 12 risk.md template both updated to v2.0

## Decisions Made

None - followed locked decisions D-07 through D-15 from 11-CONTEXT.md exactly as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- sara-init now writes v2.0 risk schema at init time — consistent with sara-extract (plan 01) and sara-update (plan 03) v2.0 risk changes
- All three risk-pipeline skill files require plan 01 (sara-extract) and plan 03 (sara-update) to complete the full v2.0 risk artifact cycle

## Known Stubs

None - all changes are to skill/prompt files with intentional template placeholder values (RSK-000, empty strings). These are schema templates, not runtime stubs.

## Threat Flags

None - no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. Both changes write to a markdown skill prompt file only.

---
*Phase: 11-refine-risks*
*Completed: 2026-04-29*
