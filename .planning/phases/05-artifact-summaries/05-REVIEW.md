---
phase: 05-artifact-summaries
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .claude/skills/sara-discuss/SKILL.md
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-update/SKILL.md
  - .claude/skills/sara-lint/SKILL.md
findings:
  critical: 1
  warning: 1
  info: 3
  total: 5
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-28
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five SKILL.md files reviewed covering the full SARA pipeline: init, discuss, extract, update, and lint. The skills are generally well-structured with clear stage-guard patterns, consistent tool usage discipline (Read/Write over Bash text-processing), and good defensive notes. One critical bug was found in sara-update: the `Edit` tool is used in the index-update path but is absent from `allowed-tools`, which will cause a runtime refusal. One warning was found in sara-lint: the `git add` in the back-fill commit stages entire wiki directories rather than only the files that were modified, which can accidentally include unrelated uncommitted changes.

---

## Critical Issues

### CR-01: Edit tool used in sara-update but not declared in allowed-tools

**File:** `.claude/skills/sara-update/SKILL.md:254`
**Issue:** Step 3 instructs using the Edit tool to update `Last Updated` column cells in `wiki/index.md` for UPDATE artifacts: "use the Edit tool to update the `Last Updated` column in each affected row". However, the skill's `allowed-tools` frontmatter (lines 6–9) lists only `Read`, `Write`, and `Bash`. The Edit tool is not listed. Claude Code enforces the `allowed-tools` list and will refuse the Edit call at runtime, leaving index rows un-updated for any UPDATE artifact.
**Fix:** Add `Edit` to the `allowed-tools` frontmatter, or rewrite the index-update path to use Read + Write (read the full index, apply the date change in memory, write it back):

```yaml
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
```

Or, alternatively, replace the Edit-tool instruction with a Read+Write pattern consistent with the rest of the skill's approach to pipeline-state.json.

---

## Warnings

### WR-01: sara-lint back-fill commit stages entire wiki directories, not just modified files

**File:** `.claude/skills/sara-lint/SKILL.md:106`
**Issue:** The `git add` command in Check 1 stages entire directory trees:
```bash
git add wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/
```
If a user has any other uncommitted changes in those directories (e.g., a manually edited page, a partially-written update), those changes will be silently swept into the lint commit with the message `fix(wiki): back-fill artifact summaries via sara-lint`. This violates the principle of atomic, scoped commits and can cause data integrity issues that are hard to detect.

**Fix:** Stage only the files that were actually written by the back-fill loop. Build the file list during the loop and use it in the `git add`:

```bash
git add wiki/requirements/REQ-001.md wiki/decisions/DEC-003.md  # (the actual missing_files list)
git commit -m "fix(wiki): back-fill artifact summaries via sara-lint"
```

Concretely, the process should accumulate the written file paths and pass them explicitly to `git add` rather than staging by directory glob.

---

## Info

### IN-01: sara-update — no guard against writing stage=complete if pipeline-state.json write fails

**File:** `.claude/skills/sara-update/SKILL.md:297-302`
**Issue:** Step 5 reads pipeline-state.json, sets `stage=complete` in memory, and writes it back using the Write tool. If the Write tool call fails (disk error, permission issue), the git commit has already succeeded, leaving the item stuck at `approved` with no error message about the state file write failure. The skill has strong handling for commit failures but no explicit failure branch for the post-commit state write.
**Fix:** Add a failure note and recovery instruction after the Write tool call. At minimum, document in the notes that if this write fails the user can manually set `stage: "complete"` in pipeline-state.json to unblock the pipeline. A note in the existing notes section would suffice.

### IN-02: sara-extract — fallback to full page read for pre-Phase-5 artifacts could consume substantial context

**File:** `.claude/skills/sara-extract/SKILL.md:58`
**Issue:** The fallback path for "summary-less artifacts" reads full artifact pages into context via the Read tool. On a wiki with many pre-Phase-5 artifacts (all lacking `summary` fields before sara-lint is run), this could read dozens of full pages during dedup, consuming significant context window. The fallback is documented and correct, but the risk is not mentioned.
**Fix:** Add a note that running `/sara-lint` before the first `/sara-extract` after upgrading to Phase-5 ensures all pre-existing artifacts have summary fields, which eliminates full-page fallback reads. This gives operators a clear mitigation path.

### IN-03: sara-discuss — Priority 4 cross-link grep runs after the blocker list is presented, creating a two-phase load

**File:** `.claude/skills/sara-discuss/SKILL.md:70-76`
**Issue:** Step 3 instructs loading artifact summaries for Priority 4 analysis via grep "before identifying cross-link candidates" — but this grep is nested inside the Step 3 blocker-list generation block. The order implies the grep for summaries is deferred until the Priority 4 analysis phase, after the Priority 1-3 blockers are already written out. If the skill generates the blocker summary before running the grep (a natural LLM ordering error), the Priority 4 section of the presented list could be incomplete.
**Fix:** Clarify the instruction to make it unambiguous that the summary grep runs before the blocker list is presented to the user (not partway through the Priority 4 section analysis). For example: move the grep instruction to a named sub-step at the top of Step 3 with an explicit "run this before starting blocker analysis" directive, matching the pattern already used in sara-extract Step 3.

---

_Reviewed: 2026-04-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
