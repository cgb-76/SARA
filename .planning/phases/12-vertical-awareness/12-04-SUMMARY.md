---
phase: 12-vertical-awareness
plan: "04"
subsystem: skills
tags: [rename, terminology, segments, sara-update]
dependency_graph:
  requires: [12-01]
  provides: [sara-update/SKILL.md with segments write rules in all 8 entity branches]
  affects: [sara-update]
tech_stack:
  added: []
  patterns: [find-and-replace rename, field-mapping rule insertion]
key_files:
  created: []
  modified:
    - .claude/skills/sara-update/SKILL.md
decisions:
  - "Added segments write rule to all 4 create branches (requirement, decision, action, risk) as sub-bullets after each type-specific field bullet"
  - "Added segments write rule to all 4 update branches (requirement, decision, action, risk) after the schema_version = '2.0' line"
  - "YAML serialisation rule: flow style for 0-2 entries, block style for 3+ — consistent with tags/related/source"
  - "Update branch rules specify 'replace existing value if present' to handle existing pages"
  - "Normalised update branch STK summary rule from slash-separated to comma-separated format (consistent with create branch)"
  - "schema_version unchanged — all four artifact types remain at '2.0'"
metrics:
  duration: "178s"
  completed_date: "2026-04-30"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 12 Plan 04: Add segments write rule to sara-update (all 8 entity branches) Summary

Updated sara-update/SKILL.md to write `segments: artifact.segments` to wiki page frontmatter for all four artifact types (requirement, decision, action, risk) in both create and update branches — 8 new write rules total — plus the vertical → segment terminology rename in the STK summary rule and notes section.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rename vertical → segment in sara-update STK summary rule and notes | c758d46 | .claude/skills/sara-update/SKILL.md |
| 2 | Add segments write rule to all eight entity branches in sara-update | 144b01a | .claude/skills/sara-update/SKILL.md |

## Verification Results

- `grep -in "vertical" .claude/skills/sara-update/SKILL.md` → zero occurrences (PASS)
- `grep -c "STK: segment, department, role" .claude/skills/sara-update/SKILL.md` → 2 (PASS, expected >=2)
- `grep "segment.*and.*department.*are always separate" .claude/skills/sara-update/SKILL.md` → 1 line (PASS)
- `grep -c "artifact\.segments" .claude/skills/sara-update/SKILL.md` → 8 (PASS, expected 8)
- `grep -c "schema_version.*2\.0" .claude/skills/sara-update/SKILL.md` → 9 (PASS, unchanged)
- Create branch rules (lines 107, 112, 117, 122): requirement, decision, action, risk — all include flow/block YAML style guidance
- Update branch rules (lines 367, 389, 435, 487): requirement, decision, action, risk — all include "replace existing value if present"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalised update branch STK summary rule format**
- **Found during:** Task 1 verification
- **Issue:** The update branch's STK summary rule used slash-separated inline format (`STK: segment/department/role`) within a prose sentence, while the create branch used the comma-separated bullet form (`STK: segment, department, role`). The plan acceptance criterion (`grep -c "STK: segment, department, role"`) required at least 2 occurrences of the comma-separated form, but only 1 existed.
- **Fix:** Changed `STK: segment/department/role` to `STK: segment, department, role` in the update branch prose (line 360), making both branches use consistent comma-separated format and satisfying the acceptance criterion.
- **Files modified:** .claude/skills/sara-update/SKILL.md
- **Commit:** c758d46

**2. [Rule 1 - Bug] Removed accidental duplicate decision deciders bullet**
- **Found during:** Task 2 — first create-branch edit attempt
- **Issue:** The initial create-branch edit accidentally introduced a duplicate `For decision artifacts: leave \`deciders\` = \`[]\`` bullet (one at the original position line 106, one in the newly inserted block). The decision `deciders` bullet was already present in the file before the segments rules were added.
- **Fix:** Removed the duplicate, leaving one `deciders` bullet followed by the segments sub-rule.
- **Files modified:** .claude/skills/sara-update/SKILL.md
- **Commit:** 144b01a (net result correct)

## Known Stubs

None — all 8 write rules reference `artifact.segments` which is the live artifact field produced by sara-extract and passed through by sara-artifact-sorter (completed in plans 12-02 and 12-03).

## Threat Flags

None — changes are instruction-text edits in skill SKILL.md files; no new network endpoints, auth paths, or schema version changes at trust boundaries.

## Self-Check: PASSED

- c758d46 exists: FOUND (git log confirms `feat(12-04): rename vertical → segment in sara-update STK summary rule and notes`)
- 144b01a exists: FOUND (git log confirms `feat(12-04): add segments write rule to all eight entity branches in sara-update`)
- .claude/skills/sara-update/SKILL.md modified: FOUND
- 8 artifact.segments references: CONFIRMED
- 0 vertical occurrences: CONFIRMED
- schema_version count unchanged: CONFIRMED
