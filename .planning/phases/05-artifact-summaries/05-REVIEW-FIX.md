---
phase: 05-artifact-summaries
fixed_at: 2026-04-28T00:00:00Z
review_path: .planning/phases/05-artifact-summaries/05-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 05: Code Review Fix Report

**Fixed at:** 2026-04-28
**Source review:** .planning/phases/05-artifact-summaries/05-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Edit tool used in sara-update but not declared in allowed-tools

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 3b0a6d7
**Applied fix:** Added `Edit` to the `allowed-tools` frontmatter list (between `Write` and `Bash`). The skill's index-update path for UPDATE artifacts explicitly instructs using the Edit tool; the missing declaration would have caused a runtime refusal when updating `Last Updated` column cells in `wiki/index.md`.

### WR-01: sara-lint back-fill commit stages entire wiki directories, not just modified files

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 12cd205
**Applied fix:** Changed the back-fill loop to initialise a `written_files` list before the loop and append each successfully written file path to it. The `git add` command in the commit block now stages `{written_files...}` (the explicit list of written paths) instead of the directory globs `wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/`. Added a comment to the bash block making the intent explicit. Also added an "if write succeeds: append to written_files" step consistent with the partial-failure tracking pattern already present in sara-update.

---

_Fixed: 2026-04-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
