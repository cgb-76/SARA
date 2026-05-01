---
phase: 17-document-based-statefulness
fixed_at: 2026-05-01T00:00:00Z
review_path: .planning/phases/17-document-based-statefulness/17-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 17: Code Review Fix Report

**Fixed at:** 2026-05-01T00:00:00Z
**Source review:** .planning/phases/17-document-based-statefulness/17-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-01, CR-02, WR-01, WR-02, WR-03, WR-04)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: ID counter derivation silently matches wrong type's directories

**Files modified:** `.claude/skills/sara-ingest/SKILL.md`, `.claude/skills/sara-update/SKILL.md`
**Commit:** d048cf2
**Applied fix:** Replaced bare `grep "^{type_key}-"` with `grep -E "^{type_key}-[0-9]{3}$"` in `sara-ingest` Step 3 (pipeline directory counter). Replaced bare `grep "^{entity_type_key}-"` with `grep -E "^{entity_type_key}-[0-9]{3}\.md$"` in `sara-update` Step 2 (wiki entity counter). Both patterns now anchor the suffix to exactly three digits, preventing non-numeric directory names from corrupting the counter arithmetic.

---

### CR-02: sara-update empty-plan fast-path advances stage without a prior commit

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 22c746c
**Applied fix:** Made the success output conditional on commit exit code. The fast-path now checks `echo "EXIT:$?"` output: if commit succeeds (exit code 0) it outputs the success message and STOPs; if commit fails (exit code != 0) it outputs an actionable retry message and STOPs without outputting the false success line. This also resolves WR-03 (see below).
**Status:** fixed: requires human verification (logic condition — reviewer should confirm the branch ordering matches intent)

---

### WR-01: Path-traversal check does not cover null bytes or encoded separators

**Files modified:** `.claude/skills/sara-ingest/SKILL.md`
**Commit:** 93fe8ce
**Applied fix:** Extended the Step 1 filename validation description to reject: empty filenames, backslash (`\`), null bytes (`\0`), and filenames beginning with a dot — in addition to the existing `/` and `..` guards. Updated the companion note in `<notes>` to reference the Step 2 filesystem check as a defense-in-depth guard. Updated error message to match the expanded validation criteria.

---

### WR-02: sara-discuss stage-advance commit missing exit-code capture

**Files modified:** `.claude/skills/sara-discuss/SKILL.md`, `.claude/skills/sara-extract/SKILL.md`
**Commit:** 9a593e2
**Applied fix:** Added `echo "EXIT:$?"` to the stage-advance commit bash block in both skills. Added a failure check block immediately after: if exit code is non-zero, outputs an actionable retry message (with the exact git commands to re-run) and STOPs. This prevents silent unversioned stage advances when the commit fails. Applied to `sara-discuss` (stage → extracting) and `sara-extract` (stage → approved) as directed by the review.

---

### WR-03: sara-update empty-plan branch produces misleading success output on commit failure

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 22c746c
**Applied fix:** Resolved together with CR-02 in the same commit. The success output line is now inside the `If commit SUCCEEDS` branch and the `If commit FAILS` branch outputs a retry message instead. No separate commit was needed as both issues were in the same code block.

---

### WR-04: sara-ingest STATUS mode grep may return fields out of frontmatter order

**Files modified:** `.claude/skills/sara-ingest/SKILL.md`
**Commit:** b110947
**Applied fix:** Replaced `grep -rh` with `grep -H` in Step 6 STATUS mode. Updated the parsing instruction to group lines by the filename prefix that `grep -H` provides on every output line (e.g. `.sara/pipeline/MTG-001/state.md:id: MTG-001`), making grouping deterministic regardless of filesystem ordering. Updated the `<notes>` STATUS mode bullet to describe the `-H` flag behaviour.

---

_Fixed: 2026-05-01T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
