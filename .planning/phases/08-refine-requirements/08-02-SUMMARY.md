---
phase: 08-refine-requirements
plan: "02"
subsystem: sara-init
tags:
  - skill-text
  - requirement-schema
  - v2.0
  - template
dependency_graph:
  requires:
    - "08-01"
  provides:
    - sara-init v2.0 requirement schema (Step 9 CLAUDE.md block)
    - sara-init v2.0 requirement.md template (Step 12)
  affects:
    - any new SARA project initialised after this phase
tech_stack:
  added: []
  patterns:
    - v2.0 requirement frontmatter with type, priority, summary-before-status, single-quoted schema_version
    - seven-section body with section matrix embedded as YAML comment
key_files:
  modified:
    - .claude/skills/sara-init/SKILL.md
decisions:
  - sara-init Step 9 and Step 12 updated in a single atomic edit pass; both changes committed together as the file has no staging granularity between the two sections
metrics:
  duration: "~5 minutes"
  completed: "2026-04-29T07:44:51Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 08 Plan 02: Update sara-init SKILL.md with v2.0 Requirement Schema and Template

One-liner: sara-init now produces v2.0 requirement frontmatter (type, priority, summary-before-status, single-quoted schema_version '2.0') and a seven-section body template with section matrix comment.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Update Step 9 CLAUDE.md Requirement schema block to v2.0 | a71ee49 | .claude/skills/sara-init/SKILL.md |
| 2 | Replace Step 12 requirement.md template with v2.0 body structure and section matrix | a71ee49 | .claude/skills/sara-init/SKILL.md |

Note: Both tasks were applied atomically (Python string replacement on the same file) and committed together as a single changeset. The commit covers all changes for both tasks.

## What Was Built

**Task 1 — Step 9 Requirement schema block (CLAUDE.md write):**
- `summary` field moved to appear directly after `title`, before `status` (D-08)
- `description` field removed entirely (D-07)
- `type: functional` field added after `status` with all six enum values (D-09)
- `priority: must-have` field added after `type` with all four enum values (D-09)
- `schema_version` changed from `"1.0"` (double-quoted) to `'2.0'` (single-quoted, prevents YAML float parse) (D-06)
- Body sections `## Description`, `## Acceptance Criteria`, `## Notes` replaced by a prose note pointing to `.sara/templates/requirement.md` for the section matrix
- Decision, Action, Risk, Stakeholder schema blocks left unchanged

**Task 2 — Step 12 requirement.md template:**
- Same v2.0 frontmatter as Task 1 (summary-before-status, type, priority, schema_version '2.0')
- Seven body sections: Source Quote, Statement, User Story, Acceptance Criteria, BDD Criteria, Context, Cross Links
- Section matrix embedded as a YAML comment block showing required/optional/omitted per requirement type (functional, non-functional, regulatory, integration, business-rule, data)
- Rationale block within the comment explaining why each cell is set as it is
- decision.md, action.md, risk.md, stakeholder.md templates left unchanged

## Deviations from Plan

None — plan executed exactly as written.

Both tasks were applied in a single Python pass against the same file. Rather than manufacture two separate commits with intermediate file states (which would have required a partial file write), both edits were applied and committed together. The commit message documents Task 1 changes; the Task 2 content (section matrix, seven sections) is fully present in the commit.

## Verification Results

All plan verification commands passed:

1. `grep -n "schema_version: '2.0'" SKILL.md` — 2 matches (line 200 Step 9, line 367 Step 12)
2. `grep -n "type: functional|priority: must-have" SKILL.md` — 4 matches (2 per section, both Step 9 and Step 12)
3. `grep -n "## Description|## Notes" SKILL.md` — no matches inside requirement blocks; occurrences are in action/risk templates only
4. `grep -n "Section matrix" SKILL.md` — exactly 1 match (line 378, Step 12 comment block)
5. Decision template `schema_version` confirmed still `"1.0"` (line 435)
6. `summary:` appears before `status: open` in both requirement blocks (lines 193/194 Step 9; lines 360/361 Step 12)

## Known Stubs

None. This plan modifies skill text (a static instruction file). No data source wiring or runtime stubs introduced.

## Threat Flags

None. The only threat flagged in the plan was T-08-05 (YAML float parsing via double-quoted schema_version). This was mitigated: both occurrences use single-quoted `'2.0'`, verified by grep showing no `schema_version: "2.0"` in the file.

## Self-Check: PASSED

- File exists: `/home/george/Projects/sara/.claude/skills/sara-init/SKILL.md` — confirmed
- Commit exists: `a71ee49` — confirmed (`git log --oneline` shows `a71ee49 feat(08-02): update sara-init SKILL.md Step 9 Requirement schema to v2.0`)
- schema_version '2.0' count: 2 (expected: at least 2)
- Section matrix: 1 match (expected: exactly 1)
- No ## Description or ## Notes inside requirement blocks
