---
phase: 06-refine-entity-extraction
fixed_at: 2026-04-28T00:00:00Z
review_path: .planning/phases/06-refine-entity-extraction/06-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 06: Code Review Fix Report

**Fixed at:** 2026-04-28T00:00:00Z
**Source review:** .planning/phases/06-refine-entity-extraction/06-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

## Fixed Issues

### WR-01: Agent loop in install.sh has no downgrade protection for agent files

**Files modified:** `install.sh`
**Commit:** d78dfdb
**Applied fix:** Added a downgrade version check block in the agents loop (mirroring the skills loop) before `mv "${tmp_file}" "${dest_file}"`. Reads `version:` from both source and installed agent files, compares with `sort -V`, and skips with a warning if the source is older (unless `--force` is set). WR-01 and WR-02 were committed together since both touch install.sh.

---

### WR-02: install.sh does not clean up tmp_file on unexpected exit

**Files modified:** `install.sh`
**Commit:** d78dfdb
**Applied fix:** Added `tmp_file=""` initialiser and `trap 'rm -f "${tmp_file:-}"' EXIT` immediately after the variable declarations block at the top of the script. This ensures the last-assigned temp file is always cleaned up on unexpected exit via `set -e`.

---

### WR-03: sara-extract has no guard for non-JSON sorter output

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 51af51c
**Applied fix:** Inserted an explicit parse-failure guard immediately before the `{cleaned_artifacts}` / `{sorter_questions}` destructure in Step 3. If `{sorter_output}` cannot be parsed as a valid JSON object or `cleaned_artifacts` is absent, the skill outputs an error message with the raw response and a retry instruction, then STOPs.

---

### WR-04: sara-extract sorter question resolution applies updates before validating user reply

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** da5b15a
**Applied fix:** Replaced the single-line "Apply the user's resolution" instruction with explicit A/B/C dispatch logic: A keeps type1 and removes the type2 duplicate, B keeps type2 and removes type1, C removes both, and any other reply re-presents the question with "Please reply A, B, or C." without advancing.

---

### WR-05: sara-lint notes contradict the process for summary field insertion position

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 16c7610
**Applied fix:** Removed the contradictory notes line that placed `summary` after `related:` and replaced it with the canonical rule matching both the process section (line 102) and the entity schema templates: insert after `status:` (REQ, DEC, ACT, RSK) or after `role:` (STK).

---

### WR-06: sara-update Step 2 update branch does not guard against missing existing_id file

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** ce913b2
**Applied fix:** Added a guard immediately after the Read call in the update branch. If the Read tool returns an error or empty content, the skill outputs a "cannot update" message, appends the file path to `failed_files`, outputs the partial failure report, and STOPs — instead of silently writing garbage.

---

### WR-07: sara-artifact-sorter has no handling for an empty merged_artifacts input

**Files modified:** `.claude/agents/sara-artifact-sorter.md`, `.claude/skills/sara-extract/SKILL.md`
**Commit:** f0e5c7a
**Applied fix:** In `sara-artifact-sorter`, added an early-exit at the start of Step 1 that returns `{"cleaned_artifacts": [], "questions": []}` immediately when `<merged_artifacts>` is empty. In `sara-extract` Step 3, added an explicit check after merging the four specialist outputs: if `{merged}` is empty, output informational messages, set `{cleaned_artifacts}` to [], skip the sorter dispatch and question loop, and proceed directly to Step 4.

---

_Fixed: 2026-04-28T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
