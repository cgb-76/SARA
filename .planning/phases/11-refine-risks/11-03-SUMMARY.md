---
phase: 11-refine-risks
plan: "03"
subsystem: sara-update
tags: [sara-update, risk-artifacts, v2.0-schema, skill-md, if-then-format]

# Dependency graph
requires:
  - phase: 11-refine-risks
    provides: "D-05, D-07 through D-15 locked decisions for v2.0 risk frontmatter and body"
  - phase: 11-01
    provides: "risk artifact fields: risk_type, owner, likelihood, impact, status extracted by sara-extract"
  - phase: 11-02
    provides: "v2.0 risk schema shape confirmed in sara-init template"
provides:
  - "sara-update risk create branch: type from artifact.risk_type, owner from artifact.owner, likelihood/impact/status from artifact fields, schema_version '2.0' (single-quoted), mitigation frontmatter field absent, four-section body (Source Quote, Risk IF/THEN, Mitigation, Cross Links)"
  - "sara-update risk update branch: all eight v2.0 frontmatter migrations, mitigation field removal instruction, body rewrites to four-section format, IF/THEN and Mitigation synthesis reference artifact.change_summary"
  - "RSK summary generation rule updated to: likelihood, impact, type, status, mitigation approach"
affects: [sara-update runtime, wiki/risks/ pages written by future sara-update runs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Risk create/update branch parallel structure: both branches specify same v2.0 frontmatter fields and four-section body — consistent with requirement/decision/action precedent"
    - "IF/THEN risk statement format: IF and THEN in caps, trigger condition + adverse event, with example — synthesised by sara-update at write time, not extracted inline"
    - "Mitigation fallback text: 'No mitigation discussed — define action items to address this risk.' — used identically in both create and update branches"
    - "Schema_version single-quoted '2.0' for all four artifact types: requirement, decision, action, risk — completes the full v2.0 convention"

key-files:
  created: []
  modified:
    - .claude/skills/sara-update/SKILL.md

key-decisions:
  - "Followed D-05 through D-15 exactly: type from risk_type, owner from artifact.owner (not raised_by), schema_version single-quoted '2.0', mitigation removed from frontmatter, four-section body"
  - "Risk update branch: eight explicit field operations listed (type add-if-absent, owner REPLACE, raised-by add-if-absent, likelihood add-or-replace, impact add-or-replace, status replace, schema_version set, mitigation remove)"
  - "RSK summary generation rule in update branch regeneration changed from slash-delimited 'likelihood/impact/mitigation/status' to comma-separated 'likelihood, impact, type, status, mitigation approach' — consistent with v2.0 field set"
  - "Notes section updated: schema_version is now '2.0' single-quoted for all four artifact types (was 'risk → 1.0 double-quoted')"

patterns-established:
  - "V2.0 risk write pattern: four-section body (Source Quote / Risk IF/THEN / Mitigation / Cross Links) for both create and update branches"
  - "Mitigation fallback text pattern: explicit 'No mitigation discussed — define action items' when no mitigation in source/notes"

requirements-completed: [WIKI-04]

# Metrics
duration: 5min
completed: 2026-04-29
---

# Phase 11 Plan 03: sara-update risk create and update branches rewritten to v2.0 with IF/THEN body format and eight-field frontmatter migration

**sara-update risk create and update branches rewritten to v2.0: artifact.risk_type → type, artifact.owner → owner, likelihood/impact/status from artifact fields, schema_version single-quoted '2.0', mitigation frontmatter removed, four-section body (Source Quote, Risk IF/THEN, Mitigation, Cross Links)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-29T13:30:00Z
- **Completed:** 2026-04-29T13:34:24Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Risk create branch: replaced v1.0 frontmatter mapping (schema_version "1.0", owner from raised_by, no type/likelihood/impact fields) with full v2.0 mapping (schema_version '2.0' single-quoted, type from risk_type, owner from artifact.owner, raised-by, likelihood, impact, status from artifact fields, Do NOT write mitigation frontmatter)
- Risk create branch: replaced v1.0 body (Description/Mitigation/Notes) with four-section body — Source Quote, Risk (IF/THEN synthesis instruction with caps rule and example), Mitigation (with fallback text), Cross Links
- Risk update branch: replaced stub one-liner (schema_version "1.0" unchanged) with eight explicit v2.0 frontmatter field operations including Remove mitigation field instruction, plus body rewrite to four-section format with IF/THEN synthesis referencing artifact.change_summary
- RSK summary generation rule in update branch regeneration updated to reflect v2.0 field set
- Notes section updated: schema_version is now single-quoted '2.0' for all four artifact types

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite risk create branch in sara-update** - `bc70d39` (feat)
2. **Task 2: Rewrite risk update branch in sara-update** - `918eefe` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `.claude/skills/sara-update/SKILL.md` — Risk create branch v2.0 frontmatter mapping and four-section body; risk update branch v2.0 eight-field migration and four-section body rewrite; RSK summary rule updated; notes schema_version note updated

## Decisions Made

None — followed locked decisions D-05 through D-15 from 11-CONTEXT.md exactly as specified. No implementation choices required beyond selecting edit boundaries.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed "No mitigation discussed" split across two lines in update branch**
- **Found during:** Task 2 acceptance criteria verification
- **Issue:** The mitigation fallback text in the update branch was wrapped across two lines ("No mitigation\n     discussed — ...") causing `grep -c "No mitigation discussed"` to return 1 instead of >=2
- **Fix:** Joined the two-line wrap into a single line so the exact phrase appears on one line — matches the acceptance criteria grep pattern and is identical in form to the create branch
- **Files modified:** `.claude/skills/sara-update/SKILL.md`
- **Verification:** `grep -c "No mitigation discussed" .claude/skills/sara-update/SKILL.md` returns 2
- **Committed in:** `918eefe` (Task 2 commit)

**2. [Rule 2 - Missing Critical] Updated notes section schema_version reference**
- **Found during:** Task 2 (noticed old "risk → 1.0 double-quoted" note in <notes> section)
- **Issue:** The <notes> section still said "risk → `\"1.0\"` (double-quoted)" which contradicts the v2.0 migration and would confuse future implementors
- **Fix:** Updated notes entry to say all four artifact types use `'2.0'` single-quoted
- **Files modified:** `.claude/skills/sara-update/SKILL.md`
- **Verification:** `grep -n "schema_version.*\"1.0\"" .claude/skills/sara-update/SKILL.md` returns 0 matches
- **Committed in:** `918eefe` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both fixes necessary for correctness — the bug would have caused acceptance criteria grep failure; the notes fix ensures the skill's own documentation is self-consistent.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 11 (refine-risks) is now complete — all three plans delivered:
  - Plan 01: sara-extract risk pass rewritten (D-01–D-06, D-16)
  - Plan 02: sara-init risk template and schema block updated to v2.0
  - Plan 03: sara-update risk create and update branches rewritten to v2.0
- The full v2.0 risk artifact pipeline is consistent end-to-end: extraction (plan 01) → writing (plan 03) → template/schema (plan 02)
- No blockers for v2.0 milestone completion

## Known Stubs

None — all changes are to skill/prompt files. The synthesised body sections (IF/THEN risk statement, Mitigation narrative) are intentionally runtime-generated by sara-update from source documents, not stubs.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. Both T-11-03-01 and T-11-03-02 dispositions confirmed:
- T-11-03-01 (Tampering, markdown edit): accepted — changes are review-visible in git diff
- T-11-03-02 (schema_version float risk): mitigated — single-quoted '2.0' verified present; no double-quoted "1.0" remains for risk artifacts

## Self-Check: PASSED

- `.claude/skills/sara-update/SKILL.md` exists and contains all required changes
- Task 1 commit `bc70d39` confirmed in git log
- Task 2 commit `918eefe` confirmed in git log
- All 9 plan verification checks passed:
  1. `grep -c "artifact.risk_type"` = 2 (PASS)
  2. `grep -c "No mitigation discussed"` = 2 (PASS)
  3. `grep -n "schema_version.*\"1.0\""` = 0 matches (PASS)
  4. `grep -c "Remove.*mitigation.*frontmatter"` = 1 (PASS)
  5. `grep -c "^    ## Risk$"` = 2 (PASS)
  6. `grep -c "IF and THEN.*caps"` = 2 (PASS)
  7. `grep -c "RSK:.*likelihood.*impact.*type"` = 1 (PASS)
  8. `grep -n "^    ## Description$"` = lines 269, 419 (action body blocks only, not risk — PASS)
  9. `grep -n "^    ## Notes$"` = 0 matches (PASS)

---
*Phase: 11-refine-risks*
*Completed: 2026-04-29*
