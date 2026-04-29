---
phase: 09-refine-decisions
fixed_at: 2026-04-29T00:00:00Z
review_path: .planning/phases/09-refine-decisions/09-REVIEW.md
iteration: 1
findings_in_scope: 13
fixed: 13
skipped: 0
status: all_fixed
---

# Phase 09: Code Review Fix Report

**Fixed at:** 2026-04-29
**Source review:** .planning/phases/09-refine-decisions/09-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 13
- Fixed: 13
- Skipped: 0

## Fixed Issues

### CR-01: Cross-reference question template has only A/B options but resolution logic expects A/B/C

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 3fa4823
**Applied fix:** Made the re-present fallback type-aware — cross-reference questions ("appears to relate to") now re-present with "Please reply A or B." while all other question types re-present with "Please reply A, B, or C." This eliminates the false implication that C is valid for cross-reference questions.

---

### CR-02: `sara-init` writes requirement schema_version `'2.0'` but create branch omitted explicit bullet for requirements

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 613ca8f
**Applied fix:** Added an explicit bullet in the Step 2 create branch schema_version section: "For requirement artifacts: set `schema_version` = `'2.0'` (single-quoted — same convention as decisions)". This sits between the decision and action/risk bullets, making the requirement case unambiguous.

---

### CR-03: Empty `extraction_plan` early-exit does not advance stage to `"complete"`

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 2686f40
**Applied fix:** Replaced the "Proceed directly to Step 4" instruction with a self-contained early-exit block that: initialises `written_files = []` and `count = 0`, sets `stage = "complete"` in memory, writes `pipeline-state.json`, runs a targeted `git add .sara/pipeline-state.json && git commit` (avoiding the empty-commit problem), and then STOPs. This prevents the item from being permanently stuck in `"approved"`.

---

### CR-04: Sorter output schema example missing validation rule for required decision artifact fields

**Files modified:** `.claude/agents/sara-artifact-sorter.md`
**Commit:** af7b02b
**Applied fix:** Added a validation rule to the output_format rules section: before returning, the sorter must check that `status`, `dec_type`, `chosen_option`, and `alternatives` are all present and non-null for every decision artifact. If any field is absent or null, a question is surfaced asking the human to accept, skip, or flag for manual review. Silent pass-through of corrupt artifacts is explicitly prohibited.

---

### WR-01: "will" detection rule ambiguous between requirement and decision passes

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 19e5c01
**Applied fix:** Added a NOTE directly under the "will" INCLUDE rule in the requirements pass: "we will use [technology]" is more naturally a DECISION (technology choice) than a requirement. If the passage names a specific tool or platform, prefer the decisions pass. Only extract as a requirement if the passage describes a system behaviour obligation.

---

### WR-02: Missing edge case — `chosen_option` empty for accepted decision should use placeholder not synthesis

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** a95a06b
**Applied fix:** Replaced the synthesis fallback ("synthesise the decision from artifact.title and {discussion_notes}") with a placeholder instruction in both the create branch and the update branch Decision section: write "[Option not captured — review source document and update manually.]" with an explicit prohibition against synthesising ungrounded content.

---

### WR-03: Sorter step 6 says "exclude duplicates" but resolution logic requires both artifacts present

**Files modified:** `.claude/agents/sara-artifact-sorter.md`
**Commit:** 6fecdc0
**Applied fix:** Rewrote step 6 to clarify that for type-ambiguity pairs, BOTH artifacts must be included in `cleaned_artifacts`. The resolution question tells sara-extract which one to remove; without both present, the removal logic cannot operate. Removed the incorrect "exclude duplicates... those will be re-added" phrasing.

---

### WR-04: `sara-init` CLAUDE.md Decision schema `type:` field missing dec_type naming rationale

**Files modified:** `.claude/skills/sara-init/SKILL.md`
**Commit:** d719566
**Applied fix:** Expanded the `type:` field comment in the CLAUDE.md Decision schema block (the `yaml` fenced block, not the template) to explain: "wiki page field; artifact schema uses dec_type to avoid collision with envelope type: 'decision' — sara-update maps dec_type → type on write". The template at line 440 was left unchanged (it documents the on-disk format correctly).

---

### WR-05: `sara-update` update branch for decisions does not guard against invalid `artifact.status` values

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 31d125a
**Applied fix:** Replaced the status instruction in the decision update branch with an explicit validation rule: valid values are `"accepted"` or `"open"` only; if `artifact.status` is `"proposed"` or any other unexpected value, default to `"open"` and log a warning identifying the artifact title and the invalid value.

---

### WR-06: No instruction for re-run behaviour when sorter questions are partially answered

**Files modified:** `.claude/skills/sara-extract/SKILL.md`
**Commit:** 5a0fd7f
**Applied fix:** Added a NOTE paragraph immediately after the existing re-run instruction (Step 4) clarifying that re-running always re-runs the full extraction and sorter pipeline from the beginning, previously answered sorter questions are not preserved between sessions, and the user will be asked all sorter questions again — this is by design because a fresh extraction may produce a different artifact set.

---

### WR-07: Index Type column note ambiguous — could suggest using artifact.dec_type

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** 3be2f68
**Applied fix:** Rewrote the Step 3 index note to explicitly state: "The Type column uses `artifact.type` (the entity class: requirement, decision, action, or risk). Never use `artifact.req_type` or `artifact.dec_type` (sub-classifications) in this column." The previous phrasing only gave a negative example; the rewrite gives the positive field name first.

---

### WR-08: Sorter role/input description says "specialist agents" but architecture uses inline passes

**Files modified:** `.claude/agents/sara-artifact-sorter.md`
**Commit:** 5630bc7
**Applied fix:** Updated the `<role>` section to say "four inline extraction passes (run sequentially by sara-extract against the source document)" instead of "four specialist extraction agents". Updated the `<merged_artifacts>` input description to say "concatenation of all four inline extraction pass outputs" instead of "specialist agent outputs".

---

### WR-09: Action and risk body source quote attribution uses plain text instead of wikilink

**Files modified:** `.claude/skills/sara-update/SKILL.md`
**Commit:** c9904bd
**Applied fix:** Updated the action and risk body section templates to use `[[{artifact.raised_by}|{stakeholder_name}]]` wikilink format for the source quote attribution line, consistent with the requirement and decision sections. Plain text `{stakeholder_name}` was the previous (inconsistent) format.

---

_Fixed: 2026-04-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
