---
plan: 08-03
phase: 08-refine-requirements
status: complete
completed: 2026-04-29
---

# Plan 08-03 Summary: sara-update v2.0 Requirement Write Paths

## What Was Built

Rewrote the requirement create and update branches in `sara-update/SKILL.md` Step 2 to produce v2.0 wiki pages. This is the only skill that writes wiki artifact files — without this change, the extraction improvements (Plan 01) and template changes (Plan 02) would have had no effect on actually-written `wiki/requirements/*.md` pages.

## Tasks Completed

### Task 1 — Create branch: v2.0 body structure and frontmatter fields

**Frontmatter field list updated:**
- `schema_version` split: `"1.0"` for decision/action/risk artifacts (double-quoted); `'2.0'` for requirement artifacts (single-quoted, prevents YAML float parsing)
- Added `type = artifact.req_type` for requirement artifacts (one of six types from Plan 01)
- Added `priority = artifact.priority` for requirement artifacts (MoSCoW value from Plan 01)
- Added note: do not set `description` field for requirements (v1.0 field removed)

**Requirement body block replaced:** The v1.0 block (`## Description` / `## Acceptance Criteria` / `## Notes`) is replaced with the v2.0 seven-section body:

| Section | Rule |
|---------|------|
| `## Source Quote` | Always required — verbatim quote in blockquote with linked stakeholder |
| `## Statement` | Always required — "The [subject] shall [verb phrase]." synthesis |
| `## User Story` | Section matrix: required for functional, optional for non-functional/integration, omitted for regulatory/business-rule/data |
| `## Acceptance Criteria` | Always required — at least one testable criterion derived from source_quote |
| `## BDD Criteria` | Section matrix: required for functional/business-rule, optional for integration, omitted for non-functional/regulatory/data |
| `## Context` | Section matrix: optional for functional, required for all other types |
| `## Cross Links` | Always required — one wikilink per artifact.related[] entry using established wikilink rule |

### Task 2 — Update branch: v2.0 body migration on update

Inserted a requirement-specific paragraph after the `summary` regeneration instruction in the update branch. When `artifact.type == "requirement"`:

1. Sets v2.0 frontmatter fields: `type`, `priority`, `schema_version = '2.0'`, removes `description` if present
2. Rewrites the full body to v2.0 structured section format using same synthesis rules as the create branch
3. Applies section matrix per `artifact.req_type` to include/omit sections
4. Generates `## Cross Links` from the merged `artifact.related[]` array using established wikilink convention

## Key Files Changed

- `.claude/skills/sara-update/SKILL.md` — +71 / -13 lines

## Self-Check: PASSED

Acceptance criteria verified:

- [x] `## Source Quote` in requirement create branch body block (line 149)
- [x] `## Statement` in requirement create branch body block (line 152)
- [x] `## BDD Criteria` in requirement create branch body block (line 172)
- [x] `## Cross Links` in requirement create branch body block (line 195)
- [x] `artifact.req_type` referenced in section matrix conditions (lines 158, 173, 187)
- [x] `artifact.priority` referenced in frontmatter field list (line 88)
- [x] `type = artifact.req_type` in frontmatter field construction list (line 87)
- [x] `schema_version = '2.0'` for requirement artifacts (line 86)
- [x] `## Description` NOT in requirement create branch body (present only in action/risk blocks — correct)
- [x] `## Notes` NOT in requirement create branch body (present only in action/risk blocks — correct)
- [x] `artifact.type == "requirement"` in update branch (line 268)
- [x] `rewrite the full body to the v2.0 structured section format` in update branch (line 276)
- [x] `Set schema_version = '2.0'` in update branch requirement paragraph (line 273)
- [x] `Remove the description field from the frontmatter if present` in update branch (line 274)
- [x] Decision body block (`## Context` → `## Decision` → `## Rationale` → `## Alternatives Considered`) unchanged
- [x] `Use the Write tool to overwrite` still appears after the new paragraph

## Notes

- No deviations from the plan
- The `## Description` at lines 227/240 of the final file are in the `**action:**` and `**risk:**` blocks respectively — acceptable and expected per acceptance criteria
- Decision, action, risk, and stakeholder write paths are unchanged (scope boundary respected)
