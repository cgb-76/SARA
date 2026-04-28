---
phase: 05-artifact-summaries
plan: "02"
subsystem: sara-update
tags: [sara-update, summary-generation, wiki-artifacts, pipeline]
dependency_graph:
  requires: []
  provides: [summary-field-generation-in-sara-update]
  affects: [all wiki artifacts produced by sara-update]
tech_stack:
  added: []
  patterns: [LLM-generated summary prose, type-specific content rules, summary_max_words fallback]
key_files:
  modified:
    - .claude/skills/sara-update/SKILL.md
decisions:
  - summary generated at write time in both create and update branches of Step 2
  - summary_max_words read from pipeline-state.json with default of 50 if absent
  - type-specific rules defined inline: REQ title/status/description; DEC options/chosen/status/date; ACT owner/due-date/status; RISK likelihood/impact/mitigation/status; STK vertical/department/role
metrics:
  duration: ~5 minutes
  completed: "2026-04-28T07:37:34Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 05 Plan 02: sara-update Summary Generation Summary

**One-liner:** Added LLM-generated `summary` field to sara-update Step 2 — create branch generates type-specific prose summary; update branch regenerates it after applying change_summary — both reading `summary_max_words` from pipeline-state.json with fallback 50.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add summary generation to sara-update Step 2 (create and update branches) | 9a191fc | .claude/skills/sara-update/SKILL.md |

## What Was Built

Two targeted edits to `.claude/skills/sara-update/SKILL.md`:

1. **Create branch (Edit 1):** After the field-substitution list in Step 2's create branch, inserted instructions to read `summary_max_words` from the already-loaded pipeline-state.json (default 50 if absent), then generate an LLM prose summary using type-specific content rules. The summary is a single prose string — not a list — derived from artifact fields already set and `{discussion_notes}`.

2. **Update branch (Edit 2):** After the related-field merge and before the Write tool call in Step 2's update branch, inserted instructions to regenerate the `summary` field using the same type-specific rules, replacing the existing frontmatter value.

Type-specific content rules embedded in both branches:
- REQ: title, status, one-line description of what is required
- DEC: options considered, chosen option/recommendation, status, decision date
- ACT: owner, due-date, status (open/in-progress/done/cancelled)
- RISK: likelihood, impact, mitigation approach, status
- STK: vertical, department, role — enough to distinguish from other stakeholders

## Verification

```
summary_max_words appears at:
  line 92  — create branch (read from pipeline-state.json)
  line 224 — update branch (regenerate instruction)

LLM-generated prose at line 93 (create branch)
Regenerate the at line 224 (update branch)
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The summary generation rules are embedded directly in the skill instructions. No placeholder content was added.

## Threat Flags

None. The changes add LLM-generated content to an existing private wiki write path. The threat model accepted T-05-03 (Information Disclosure — wiki is a private repo) and T-05-04 (Tampering — summary_max_words is user-editable by design; no validation in v1). No new trust boundaries were introduced.

## Self-Check: PASSED

- [x] `.claude/skills/sara-update/SKILL.md` modified and committed at 9a191fc
- [x] `summary_max_words` appears in both create branch (line 92) and update branch (line 224)
- [x] "LLM-generated prose" present in create branch
- [x] "Regenerate the" present in update branch
- [x] No file deletions in task commit
