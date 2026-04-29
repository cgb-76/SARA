---
phase: 08-refine-requirements
fixed_at: 2026-04-29T00:00:00Z
review_path: .planning/phases/08-refine-requirements/08-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 11
fixed: 11
skipped: 0
status: all_fixed
---

# Phase 08: Code Review Fix Report

**Fixed at:** 2026-04-29
**Source review:** .planning/phases/08-refine-requirements/08-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11 (3 Critical + 8 Warning; Info findings excluded per fix_scope)
- Fixed: 11
- Skipped: 0

## Fixed Issues

### CR-01: sara-update STOPs on a valid empty extraction plan

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 81143d2
**Applied fix:** Changed the empty-plan guard in Step 1 from a STOP with a re-run message to a no-op path that outputs an informational message and proceeds directly to Step 4 (stage advance commit). The item no longer gets stuck when all artifacts were rejected during sara-extract.

---

### CR-02: Stale architecture note contradicts current inline-extraction design

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** c7f79d5
**Applied fix:** Removed the stale note (formerly last bullet in `<notes>`) that instructed passing `discussion_notes` explicitly to each specialist Task() prompt. The current architecture uses no specialist Task() agents for extraction — the contradictory note that could cause spurious Task() calls is gone. The correct note (inline passes, no Task() agents) was already present and remains.

---

### CR-03: `source` field update behaviour undefined for multi-ingest updates

**Files modified:** `.claude/skills/sara-update/SKILL.md`, `.claude/skills/sara-init/SKILL.md`
**Commit:** b1d1296
**Applied fix:** Defined the exact merge strategy for the `source` field in sara-update's update branch: scalar strings are converted to single-element YAML lists, and the new ingest ID is appended if not already present (result: `source: [MTG-001, MTG-003]`). Updated the create branch to write `source` as a single-element list from the start (`[{item.id}]`). Updated all `source` fields in sara-init's Step 9 CLAUDE.md schema block (requirement, action, risk schemas) and Step 12 templates (requirement, action, risk templates) from scalar `""` to list `[]` with updated comments.

---

### WR-01: Sorter resolution logic description is wrong for cross-reference questions

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** e2fc87e
**Applied fix:** Replaced the generic A/B/C resolution block with a type-branching dispatch that first determines the question type from its text content ("extracted as both" → type-ambiguity; "looks similar to" → likely-duplicate; "appears to relate to" → cross-reference) and then applies the correct resolution action for each type. Cross-reference questions now correctly add to `artifact.related` rather than attempting to remove duplicates.

---

### WR-02: Sorter create-vs-update and question-generation ordering allows double-processing

**Files modified:** `.claude/agents/sara-artifact-sorter.md`
**Commit:** ff530a8
**Applied fix:** Added an explicit ordering rule at the top of Step 5 (question generation) prohibiting "likely duplicate" questions for any artifact already resolved to `action="update"` by Step 3. The rule clarifies that likely-duplicate questions are only generated when confidence was insufficient to assert update in Step 3.

---

### WR-03: Sorter grep search includes `wiki/stakeholders/` — risk of spurious update matches

**Files modified:** `.claude/agents/sara-artifact-sorter.md`, `.claude/skills/sara-extract/SKILL.md`
**Commit:** 021a414
**Applied fix:** Removed `wiki/stakeholders/` from the grep command in both sara-extract Step 3 and the sara-artifact-sorter `<input>` description. The grep now only searches `wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/` — the four entity types that the extract pipeline can actually produce.

---

### WR-04: sara-update notes contradict the process on what is passed to the sorter

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** e57d74c
**Applied fix:** Updated the note in sara-extract `<notes>` to accurately state that the merged artifact array, grep summaries, and wiki/index.md are all passed to the sorter Task(). The source document is explicitly called out as NOT passed to the sorter — it remains in context for the four inline extraction passes only.

---

### WR-05: Decision initial `status` instruction is ambiguous

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 0682273
**Applied fix:** Replaced the indirect "see template — the first valid status value" instruction with the explicit value: `status` = `"proposed"`. This matches the explicit treatment of all other entity types (requirement, action, risk all state their initial status directly).

---

### WR-06: `owner` field for action/risk artifacts is not in the extraction schema

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** dceabe6
**Applied fix:** Added an explicit fallback instruction for both action and risk create branches: `owner` is set to `artifact.raised_by` only if it is a resolved STK ID (e.g. `"STK-001"`); otherwise `owner` is set to `""` (empty string, unassigned). This prevents placeholder IDs like `"STK-NNN"` from being written to wiki page frontmatter.

---

### WR-07: Index `Type` column populated with entity type, not `req_type` — undocumented

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 3f4e2ce
**Applied fix:** Added an explicit note immediately after the CREATE index row bash command in Step 3 clarifying that the `Type` column always holds the entity class (`requirement`, `decision`, `action`, or `risk`) — never the `req_type` sub-classification (e.g. `functional`).

---

### WR-08: `req_type` and `priority` missing from sorter output_format for `action=update` requirement artifacts

**Files modified:** `.claude/agents/sara-artifact-sorter.md`
**Commit:** 6e500e3
**Applied fix:** Added a complete requirement update example to the `<output_format>` JSON (alongside the existing decision update example), including `priority` and `req_type` fields. Added an explicit rule stating that for requirement update artifacts, `priority` and `req_type` MUST be present and copied from the incoming create artifact unchanged.

---

_Fixed: 2026-04-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
