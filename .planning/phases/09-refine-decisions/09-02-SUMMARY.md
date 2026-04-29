---
phase: 09-refine-decisions
plan: "02"
subsystem: sara-init
tags: [decisions, schema, v2.0, templates]
dependency_graph:
  requires: []
  provides: [sara-init-decision-v2-schema, sara-init-decision-v2-template]
  affects: [sara-update]
tech_stack:
  added: []
  patterns: [v2.0-decision-schema, five-section-body, single-quoted-schema-version]
key_files:
  modified:
    - .claude/skills/sara-init/SKILL.md
decisions:
  - "Decision schema v2.0: four narrative frontmatter fields removed (context, decision, rationale, alternatives-considered) — moved to body sections"
  - "type field added with six-value taxonomy: architectural | process | tooling | data | business-rule | organisational (British English)"
  - "source field added as ingest ID list (mirrors requirement schema)"
  - "status initial value changed from proposed to accepted; proposed removed from status comment"
  - "schema_version uses single-quoted '2.0' (prevents YAML float parse) in both Step 9 schema block and Step 12 template"
  - "Five-section body order: Source Quote -> Context -> Decision -> Alternatives Considered -> Rationale"
metrics:
  duration_minutes: 5
  completed_date: "2026-04-29"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 9 Plan 02: Update sara-init Decision Schema and Template to v2.0 Summary

**One-liner:** Updated sara-init/SKILL.md in two locations — Step 9 CLAUDE.md schema block and Step 12 decision.md template — to v2.0: removed four narrative frontmatter fields, added `type` and `source` fields, changed `schema_version` to single-quoted `'2.0'`, set `accepted` as initial status, and added five-section body (Source Quote, Context, Decision, Alternatives Considered, Rationale).

## What Was Built

Two internal edits to `.claude/skills/sara-init/SKILL.md`:

**Task 1 — Step 9 CLAUDE.md decision schema block (v2.0):**
- Removed: `context`, `decision`, `rationale`, `alternatives-considered` frontmatter fields
- Added: `type` (six-value taxonomy), `source` (ingest ID list)
- Changed: `status` default from `proposed` to `accepted`; removed `proposed` from status comment
- Changed: `schema_version` from `"1.0"` (double-quoted) to `'2.0'` (single-quoted)
- Added: five-section body headings (Source Quote, Context, Decision, Alternatives Considered, Rationale) with sara-update guidance text

**Task 2 — Step 12 decision.md template (v2.0):**
- Same frontmatter changes as Task 1 — both locations now identical in shape
- Same five-section body with guidance text
- `.sara/templates/action.md` template immediately following is untouched

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 3b5fee2 | feat(09-02): update Step 9 decision schema block to v2.0 |
| 2 | bad38dd | feat(09-02): update Step 12 decision.md template to v2.0 |

## Verification Results

All plan verification checks passed:

1. `schema_version` — both decision locations show `'2.0'` (single-quoted); no `"1.0"` in decision blocks
2. `proposed` — zero occurrences anywhere in the file
3. Removed narrative fields (`context:`, `decision:`, `rationale:`, `alternatives-considered:`) — zero occurrences in decision blocks
4. `## Source Quote` — 3 occurrences total: line 228 (Step 9 decision), line 384 (requirement template — pre-existing, correct), line 450 (Step 12 decision template). Plan acceptance criteria expected 2 (decision-only count); the third is the requirement.md template added in Phase 8, which is correct.
5. `organisational` — British English confirmed in both decision locations; `organizational` has zero occurrences
6. `### Action` block in Step 9 still present at line 251; `action.md` template in Step 12 still present at line 470

## Deviations from Plan

### Minor Deviation: Source Quote count is 3, not 2

**Found during:** Task 2 verification
**Issue:** The plan acceptance criteria states `grep -c "## Source Quote"` must return 2 (one in Step 9, one in Step 12). The actual count is 3 because the requirement.md template (line 384) also contains `## Source Quote` — this was added in Phase 8 and is correct behaviour.
**Resolution:** No fix needed. The requirement template's `## Source Quote` is correct and intentional. The two decision-specific occurrences (Step 9 and Step 12) are both present and correct. The plan's acceptance criteria was written before accounting for the Phase 8 requirement template update.
**Classification:** Rule 1 candidate evaluated — not a bug; the third occurrence is correct.

## Known Stubs

None — this plan updates skill instruction text only. No runtime data flows through these templates during this plan's scope.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. This plan modifies only skill instruction markdown. The T-09-06 threat (YAML float parse from unquoted `2.0`) is mitigated by the single-quoted `'2.0'` form confirmed in both locations.

## Self-Check: PASSED

- FOUND: `.claude/skills/sara-init/SKILL.md`
- FOUND: `.planning/phases/09-refine-decisions/09-02-SUMMARY.md`
- FOUND commits: `3b5fee2` (Task 1), `bad38dd` (Task 2)
- No unexpected file deletions in either commit
