---
phase: 11-refine-risks
fixed_at: 2026-04-29T00:00:00Z
review_path: .planning/phases/11-refine-risks/11-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 3
skipped: 1
status: partial
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-04-29
**Source review:** .planning/phases/11-refine-risks/11-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 3
- Skipped: 1

## Fixed Issues

### WR-01: Decision update branch missing Cross Links section

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** f2a9865
**Applied fix:** Added a `## Cross Links` section to the decision update branch body instructions, immediately after the Rationale block and before the `Use the Write tool` line (~line 398). The section instruction mirrors the create branch pattern but references `artifact.related` after merging with the existing related array, as appropriate for an update operation. This prevents Cross Links from being silently dropped when a decision artifact is processed via `action == "update"`.

Note: This finding was pre-existing (not introduced by Phase 11), but the fix was safe and clear-cut — a real correctness bug with precise, unambiguous fix text that matched the established create-branch pattern.

---

### WR-02: RSK summary rule omits `type` in create branch but includes it in update branch

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 26ffc3d
**Applied fix:** Updated the create branch RSK summary rule at line 117 from `RSK: likelihood, impact, mitigation approach, status` to `RSK: likelihood, impact, type, status, mitigation approach` — matching the update branch rule at line 344. This ensures newly created risk pages and updated risk pages produce consistent wiki summaries that include the risk type field.

---

### WR-03: Generated CLAUDE.md declares `Schema version: 1.0` but embeds v2.0 entity schemas

**Files modified:** `.claude/skills/sara-init/SKILL.md`
**Commit:** ec75353
**Applied fix:** Updated the CLAUDE.md template header in sara-init Step 9 (line 159) from `**Schema version:** 1.0` to `**Schema version:** 2.0`. Projects initialised after this fix will have a CLAUDE.md whose version header is consistent with the v2.0 entity schema blocks embedded below it.

---

## Skipped Issues

### WR-04: Action artifact `raised-by` absent from action frontmatter template but present in create branch field mapping

**File:** `.claude/skills/sara-update/SKILL.md:95` vs `.claude/skills/sara-init/SKILL.md:471-488`
**Reason:** Ambiguous intent — the reviewer explicitly flags that it is unclear whether `raised-by` is intentionally absent from action frontmatter or was omitted by oversight. Two fix options are offered: Option A (clarify that raised-by is NOT written to action frontmatter) and Option B (add raised-by to the action template and schema). Applying Option A would add a constraint that may be wrong if the intent was B. Applying Option B would change the schema contract without certainty that was the design intent. Skipped pending explicit product/design decision on whether action artifacts should carry a `raised-by` frontmatter field.
**Original issue:** The sara-update create branch general field mapping at line 95 includes `raised-by = artifact.raised_by` for all artifact types, but the action frontmatter template and action schema in CLAUDE.md both omit the `raised-by` field entirely, creating an inconsistency between the mapping instruction and the template contract.

---

_Fixed: 2026-04-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
