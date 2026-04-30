---
phase: 14-extraction-pipeline-fix
fixed_at: 2026-04-30T00:00:00Z
review_path: .planning/phases/14-extraction-pipeline-fix/14-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 14: Code Review Fix Report

**Fixed at:** 2026-04-30
**Source review:** .planning/phases/14-extraction-pipeline-fix/14-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (CR-01, CR-02, WR-01 through WR-06)
- Fixed: 8
- Skipped: 0

## Fixed Issues

### CR-01: Full-mesh step overwrites sorter-injected real IDs in `related[]`

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** fe34452
**Applied fix:** Changed the full-mesh assignment from unconditional overwrite to a merge operation. Now separates existing entries into real IDs (non-8-hex) and builds new_temp_ids from approved artifacts, then deduplicates and assigns the combined result. Sorter-injected real IDs (e.g. `DEC-003`) from Step 3 option-A cross-reference resolutions are preserved.

### CR-02: `preview_counters` simulation diverges when plan contains mixed create/update order

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 53ac6dd
**Applied fix (two parts):**
1. Added an explicit IMPORTANT note before the preview loop requiring iteration of `{extraction_plan}` in its declared order, with a warning that reordering will cause the preview counter sequence to diverge from the real write-loop counter sequence.
2. Added a post-substitution scan that detects any remaining 8-hex entries in artifact.related[] arrays, logs a named warning message identifying the artifact and the unresolved temp_id, then removes the entry to prevent malformed wiki frontmatter.

### WR-01: `temp_id` uniqueness is not enforced — collision risk on large batches

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 515f205
**Applied fix:** Removed the "generate inline" option from all four extraction passes (requirements, decisions, actions, risks). Each now mandates the Bash one-liner exclusively with a MANDATORY label and explicit prohibition against inline generation. Added a post-generation uniqueness check: after all four passes complete, verify all temp_ids in `{merged}` are unique and regenerate any duplicates via a new Bash call.

### WR-02: Sorter `questions` field absence is not guarded — KeyError risk

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 2e9350f
**Applied fix:** Changed the `{sorter_questions}` assignment to include an explicit absent-key default: `sorter_output.questions if the "questions" key exists, else []`. This guards against sorters that return valid JSON with `cleaned_artifacts` but no `questions` field.

### WR-03: Rejected artifacts retain stale `temp_id` values that pollute `id_map` in sara-update

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 63c7089
**Applied fix:** Added a cleanup pass in Step 5 immediately after the full-mesh step. The pass computes `approved_temp_ids` and filters each artifact's `related[]` to retain only entries that are either in `approved_temp_ids` or do not match the 8-hex pattern (i.e. are real entity IDs). This removes stale temp_ids from artifacts that were rejected in Step 4 but whose temp_ids were injected as cross-references during Step 3.

### WR-04: Update artifacts skip the approval display line for `existing_id`

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** bed10fe
**Applied fix:** Replaced the slash-separated `CREATE new {TYPE}-NNN / UPDATE {existing_id}` line with two explicit conditional lines — one for create (showing `{id_to_assign}`) and one for update (showing `{artifact.existing_id}`). Added a parenthetical instruction: "Show only the applicable Action line — do not display both."

### WR-05: `update` artifacts in sara-update have no `temp_id` but the substitution pass does not explicitly skip them

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 7e27633
**Applied fix:** Added a NOTE block immediately before the substitution pass loop clarifying that "skip update artifacts" applies ONLY to the id_map construction loop. The substitution pass applies to ALL artifacts (create and update), because update artifacts may carry temp_ids in their `related[]` arrays from the full-mesh step in sara-extract and those must also be resolved.

### WR-06: `discussion_notes` STK attribution fallback missing in segments inference

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 40faf94
**Applied fix:** Extended the STK attribution sub-step (step 1 of segments inference) in all four extraction passes. When no STK-NNN pattern is found in `source_quote`, the instruction now also directs checking `discussion_notes` — if it identifies the speaker for the passage and contains a `[[STK-NNN|…]]` reference, the STK-NNN ID is extracted from there. Applied identically to all four passes via replace_all.

---

_Fixed: 2026-04-30_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
