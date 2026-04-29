---
phase: 10-refine-actions
reviewed: 2026-04-29T12:31:35Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-update/SKILL.md
  - .claude/agents/sara-artifact-sorter.md
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-04-29T12:31:35Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four SARA skill files were reviewed: `sara-extract`, `sara-init`, `sara-update`, and `sara-artifact-sorter`. The skills are largely well-specified with strong internal consistency in the requirements and decisions passes. Five warnings were found: a missing risk update path in `sara-update`, an absent `deciders` field mapping, a stale `schema_version` note, a contradiction in the sorter notes about when questions should be resolved, and an unowned-owner check in `sara-extract` that uses a loose pattern that fails on raw names. Four info items cover minor inconsistencies in field naming commentary, a recovery gap in `sara-init`, a confirmation-question ambiguity in the sorter, and the action `raised_by` field not being noted as optional fallback.

## Warnings

### WR-01: Risk update path has no body-rewrite instructions in sara-update

**File:** `.claude/skills/sara-update/SKILL.md:327`
**Issue:** The `artifact.action == "update"` branch specifies explicit body-rewrite instructions for requirement (line 336), decision (line 356), and action (line 393) artifact types, but has no corresponding block for `type == "risk"`. A risk update artifact falls through to the generic `apply change_summary to relevant field(s)` instruction at line 334 only. This means the body is not rewritten to the v2.0 section format (Description, Mitigation, Notes, Cross Links) on update, and no `source_quote` blockquote attribution is added. This contradicts the create branch, which synthesises all body sections for risks, and will produce inconsistent page structure depending on whether a risk was created or updated.
**Fix:** Add a `For risk artifacts (artifact.type == "risk"):` block inside the update branch, parallel to the requirement/decision/action blocks, that rewrites the full body to the v2.0 format (Description with source_quote blockquote, Mitigation, Notes, Cross Links) using the same synthesis rules as the create branch.

---

### WR-02: `deciders` field is never set for decision artifacts in sara-update

**File:** `.claude/skills/sara-update/SKILL.md:87`
**Issue:** The decision template in `sara-init` (line 222) and the CLAUDE.md schema definition include a `deciders: []` frontmatter field. The extraction pass in `sara-extract` does not extract a `deciders` array — it does not appear in the per-decision field list (lines 126–133). `sara-update` never sets `deciders` when creating or updating decision artifacts (lines 87–109, 356–391). The field will always be written as `[]` from the template default. This means no decision page will ever record who made the decision, defeating the traceability purpose of the field.
**Fix:** Either (a) add `deciders` extraction to the decisions pass in `sara-extract` (e.g., set `deciders` to `[artifact.raised_by]` as the minimum — the person who surfaced the decision — and let users amend), or (b) explicitly document in both skills that `deciders` is always left empty by the pipeline and must be filled manually, making the field's vacancy intentional and visible. If (a), `sara-update` must also map `artifact.deciders` → `deciders` frontmatter field.

---

### WR-03: `schema_version` note in sara-update references outdated value

**File:** `.claude/skills/sara-update/SKILL.md:531`
**Issue:** The notes section says: `` `schema_version` must always be quoted: `"1.0"` (not `1.0`). `` This is misleading because the actual instructions in Step 2 (lines 97–100) correctly set `schema_version = '2.0'` for requirement, decision, and action artifacts. Only risk artifacts remain at `"1.0"`. The note reads as if all artifacts use `"1.0"`, which contradicts the per-type rules and could confuse an LLM executing the skill.
**Fix:** Update the note to reflect the actual values: ``"`schema_version` must be quoted to prevent Obsidian's YAML parser from treating it as a float. Current values: requirement/decision/action → `'2.0'` (single-quoted); risk → `"1.0"` (double-quoted)."``

---

### WR-04: Sorter notes contradicts its own process on question resolution timing

**File:** `.claude/agents/sara-artifact-sorter.md:168`
**Issue:** The sorter notes say: "The human resolves `questions` BEFORE the approval loop starts. Do not include unresolved ambiguities in `cleaned_artifacts` — flag them in `questions` instead." However, Step 6 of the sorter process (line 79) says: "For type-ambiguity pairs: include BOTH artifacts in `cleaned_artifacts` — do not exclude either. The resolution question tells sara-extract which one to remove." These are contradictory: the note says unresolved ambiguities must not be in `cleaned_artifacts`, but Step 6 explicitly requires both ambiguous artifacts to be present in `cleaned_artifacts` so that sara-extract can remove the rejected one after the human answers.

The current design is correct as implemented in Step 6 and sara-extract Step 3 (the sorter questions are resolved before the approval loop, but both type-ambiguous artifacts must still be in `cleaned_artifacts`). The note is wrong.
**Fix:** Revise the note at line 168 to: "The human resolves `questions` BEFORE the approval loop starts. For type-ambiguity pairs, BOTH artifacts remain in `cleaned_artifacts` — sara-extract removes the rejected one after the human answers. For likely-duplicate questions, the unresolved artifact remains in `cleaned_artifacts` with `action=create`; sara-extract changes it to `action=update` after resolution."

---

### WR-05: Unowned-owner warning in sara-extract uses pattern that misses raw name strings

**File:** `.claude/skills/sara-extract/SKILL.md:245`
**Issue:** Step 4's owner-warning condition is:
```
if artifact.type == "action" AND (artifact.owner == "" OR artifact.owner does not match STK-\d{3})
```
This condition fires for raw name strings (e.g. `"Alice"`), which is correct. However the warning message says "assign manually after /sara-update, or run /sara-add-stakeholder first." For raw name strings specifically, sara-update will write the name as-is with the note "(not yet registered — run /sara-add-stakeholder)", so the warning is accurate but potentially confusing: the user may think the owner is truly missing when it is in fact captured as a raw name. Users who see the warning for a raw-name owner may unnecessarily run `/sara-add-stakeholder` before extract completes.
**Fix:** Split the condition into two distinct cases:
- If `artifact.owner == ""`: warn "Owner not set — assign manually after /sara-update, or run /sara-add-stakeholder first."
- If `artifact.owner` is a non-empty string that does not match `STK-\d{3}`: warn "Owner '{artifact.owner}' is a raw name — run /sara-add-stakeholder to register them before or after /sara-update."

---

## Info

### IN-01: sara-extract notes reference "specialist agents" which no longer exist

**File:** `.claude/skills/sara-extract/SKILL.md:341`
**Issue:** The notes section (line 341) says: "If a specialist agent returns an empty array [], merge it as zero elements — skip silently, do not generate a question about the absent type." The extraction architecture uses four inline passes, not specialist Task() agents. There are no specialist agents to return empty arrays. This note is a stale reference to an earlier architecture.
**Fix:** Remove or reword the note to: "If an extraction pass produces an empty array, merge it as zero elements — skip silently."

---

### IN-02: sara-init guard clause blocks recovery of a partial initialisation

**File:** `.claude/skills/sara-init/SKILL.md:625`
**Issue:** The notes section acknowledges that if `/sara-init` fails partway through (after `wiki/` is created), re-running is blocked by the guard clause. The recovery instruction is to manually delete `wiki/`, `raw/`, `.sara/`, `CLAUDE.md`, and `.gitignore`. This is not surfaced in the guard clause output — users who see the guard error have no instructions on how to recover from a partial init.
**Fix:** Update the guard clause error message to include recovery instructions: `"Error: A SARA wiki already exists in this directory (wiki/ found). If this is a partial init, delete the incomplete files (rm -rf wiki/ raw/ .sara/ CLAUDE.md .gitignore) and re-run /sara-init. Aborting — no changes made."`

---

### IN-03: Sorter cross-reference confirmation question only offers A/B but sara-extract expects A/B handling for a third case

**File:** `.claude/agents/sara-artifact-sorter.md:65`
**Issue:** The cross-reference question template offers only two options (A: yes, B: no). The sara-extract resolution logic at line 231–232 also only handles A and B for cross-reference questions, and re-prompts with "Please reply A or B." if the user replies anything else. This is correct and consistent. However, the likely-duplicate template (line 57) offers A/B/C, and the resolution logic re-prompts non-A/B/C replies for that type with "Please reply A, B, or C." The asymmetry is fine but it is worth noting that the sorter question templates and sara-extract resolution logic are tightly coupled — any change to question wording (e.g. adding "contains") must be mirrored in sara-extract's pattern-matching condition strings ("extracted as both", "looks similar to", "appears to relate to").
**Fix:** Add a note in both the sorter and sara-extract that the question type is detected by substring match on these exact strings, and that the three template phrases are frozen API contracts between the two components.

---

### IN-04: Action artifact schema comment in sara-init CLAUDE.md omits `raised_by`

**File:** `.claude/skills/sara-init/SKILL.md:259`
**Issue:** The Action schema in CLAUDE.md (written by sara-init at line 259) does not include a `raised_by` field in the frontmatter definition, but sara-extract explicitly sets `raised_by` for every action artifact (line 167), and sara-update maps `artifact.raised_by` → `raised-by` frontmatter field (line 95). The action template written by sara-init (line 473) also lacks `raised-by`. The field is present in the requirement, decision, and stakeholder schemas but absent from the action schema. This is an inconsistency in the documented schema, not a bug in runtime behaviour (sara-update writes it regardless of whether the template includes it).
**Fix:** Add `raised-by: ""  # stakeholder ID (e.g. STK-001)` to the Action schema in the CLAUDE.md block (around line 263) and to the `.sara/templates/action.md` content (around line 483), consistent with the requirement template. This ensures the schema documentation matches runtime behaviour.

---

_Reviewed: 2026-04-29T12:31:35Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
