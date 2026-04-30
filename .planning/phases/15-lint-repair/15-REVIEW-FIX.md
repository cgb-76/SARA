---
phase: 15-lint-repair
fixed_at: 2026-05-01T00:00:00Z
review_path: .planning/phases/15-lint-repair/15-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 15: Code Review Fix Report

**Fixed at:** 2026-05-01
**Source review:** .planning/phases/15-lint-repair/15-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (WR-01 through WR-06; Info findings excluded per fix_scope=critical_warning)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### WR-01: D-07 LLM inference executes after the user approves, not before

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 0906a3b
**Applied fix:** Restructured Step 5 loop to add a D-07 pre-processing block that runs before the generic AskUserQuestion call. The block (1) re-reads the target file, (2) collects all other artifact pages, (3) runs LLM inference, and (4) updates `finding.proposed_fix` with the concrete proposed IDs. The AskUserQuestion now fires after inference, so the user always sees specific IDs before approving. The old D-07 "Apply" sub-steps 1-4 were removed from inside the "If Apply" branch and replaced with a streamlined write-only block (steps a-d) that uses the already-inferred `proposed_related` list. Note: WR-05 fix (large-wiki wording) was incorporated into this same block since both touched the D-07 context-collection step — see WR-05 entry below.

---

### WR-02: D-07 has no protection against infinite re-curation loop

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 04a77f2
**Applied fix:** Replaced the single-line generic commit-failure message for D-07 with an explicit multi-line warning block that: (a) confirms the file on disk has the `related:` field written, (b) provides the exact manual git commands to stage and commit, and (c) explicitly warns "Do NOT run git restore — that would remove the related: field and cause this file to be re-flagged on the next lint run."

---

### WR-03: D-06 Pass 2 grep will match files inside frontmatter if `related: []` appears in body prose

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 6b58209
**Applied fix:** Added a Note paragraph after the D-06 Pass 2 finding block (consistent with D-03 pattern): "The `^related: \[\]` grep is a frontmatter scan. Wiki pages follow the convention that `related:` appears only in the YAML frontmatter block. If the Read step confirms the grep match is in body prose rather than frontmatter, skip the finding (false positive)."

---

### WR-04: sara-update auto-invocation of `/sara-lint` has no guard against lint failure propagating as update failure

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 281636b
**Applied fix:** Added an explicit paragraph immediately after the `Then invoke /sara-lint.` line stating that if `/sara-lint` exits with an error or the wiki guard fires, the agent should output the lint error and STOP — and that the sara-update is already complete, stage=complete is final, and the user can re-run `/sara-lint` independently. Explicitly prohibits re-running sara-update or reversing state changes.

---

### WR-05: D-07 large-wiki context strategy is ambiguous — "extract only frontmatter fields" has no Read tool mechanism

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 0906a3b (same commit as WR-01)
**Applied fix:** The old wording "Read the file using the Read tool but extract only the frontmatter fields `id`, `title`, and `summary`" was replaced as part of the WR-01 restructure. The new wording in the D-07 pre-processing block reads: "Read the full file using the Read tool, but when reasoning about relationships use only the `id`, `title`, and `summary` frontmatter fields as context — do not consider body section content for non-target pages. This limits reasoning scope to stay within the effective context window for large wikis." This correctly frames the constraint as an LLM attention directive, not a tool filter.

---

### WR-06: Step 5 D-06 fix handler does not differentiate Pass 1 vs Pass 2 by finding structure — ambiguous dispatch

**Files modified:** `.claude/skills/sara-lint/SKILL.md`
**Commit:** 1df0d95
**Applied fix:** Two changes applied atomically: (1) In Step 3 D-06 Pass 1 finding: added `pass: 1` field to the finding structure bullet list. In Step 3 D-06 Pass 2 finding: added `pass: 2` field (also added the missing `check_id: D-06` line to Pass 1 for consistency). (2) In Step 5 Apply handlers: renamed `**D-06 — Cross Links mismatch (Pass 1 — non-empty related[]):**` to `**D-06, finding.pass == 1 — Cross Links mismatch (non-empty related[]):**` and similarly renamed the Pass 2 handler. The dispatch now unambiguously keys on `finding.pass` rather than requiring the agent to parse the issue description string.

---

_Fixed: 2026-05-01_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
