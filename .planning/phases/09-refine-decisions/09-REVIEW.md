---
phase: 09-refine-decisions
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .claude/skills/sara-extract/SKILL.md
  - .claude/agents/sara-artifact-sorter.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-update/SKILL.md
findings:
  critical: 4
  warning: 9
  info: 6
  total: 19
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

These four files implement the SARA wiki pipeline with a v2.0 decision schema introducing two-signal detection (COMMITMENT/MISALIGNMENT language), a six-type `dec_type` taxonomy, and a five-section decision body structure. The core logic is well-structured and internally coherent. However, several critical issues exist: a schema version inconsistency between `sara-init` and `sara-update` for requirement artifacts; a missing field in the sorter's output schema example; an ambiguous cross-reference question template that has only A/B options but the resolution handler expects A/B/C; and a state machine gap where an empty `extraction_plan` bypasses the stage-advance write. There are also nine warnings covering ambiguous detection rules, missing edge-case handling, and contradictions across files.

---

## Critical Issues

### CR-01: Cross-reference question template has only A/B options but resolution logic expects A/B/C

**File:** `.claude/agents/sara-artifact-sorter.md:66-69` and `.claude/skills/sara-extract/SKILL.md:200-203`

**Issue:** The sorter's cross-reference question template provides only two choices (A: confirm link, B: not related). However, the resolution handler in sara-extract uses a three-branch A/B/C logic block for every question type. The cross-reference branch reads:
```
A: add the referenced entity ID to the artifact's related array
B: no change to the artifact's related array
```
There is no C option. If the user replies "C" to a cross-reference question (e.g. by mistake, or by pattern from having just answered a type-ambiguity question), the resolution handler falls through to the "re-present with note" path because no C branch is defined. The re-present prompt says "Please reply A, B, or C." — which incorrectly implies C is valid for cross-reference questions. This is a contradiction between the question template and the resolution handler.

**Fix:** Either add a C option to the cross-reference template ("C) Skip — remove this artifact from the list") to make all three question types uniformly A/B/C, or change the re-present fallback to be type-aware:
```
# In the re-present path, include type check:
- If the question contains "appears to relate to": re-present with "Please reply A or B."
- All other question types: re-present with "Please reply A, B, or C."
```

---

### CR-02: `sara-init` writes requirement schema_version `'2.0'` but action/risk templates write `"1.0"` — inconsistency between CLAUDE.md inline schema and template files

**File:** `.claude/skills/sara-init/SKILL.md:379` (requirement template) vs `.claude/skills/sara-init/SKILL.md:474,505` (action/risk templates)

**Issue:** This inconsistency is correct by design (requirements are v2.0, actions/risks remain v1.0). However, the CLAUDE.md schema section in sara-init (written to the project root) shows `schema_version: '2.0'` for Requirements and Decisions, but `schema_version: "1.0"` for Actions and Risks. The stakeholder template written in Step 12 also uses `"1.0"`. sara-update's notes (line 87) say `schema_version = '2.0'` for decision artifacts and `schema_version = "1.0"` for action and risk artifacts — consistent. But the CLAUDE.md inline schema stub for Requirement at line 199 says `schema_version: '2.0'`, whereas the sara-update create branch at line 87 says:

> `schema_version` = `'2.0'` for decision artifacts (single-quoted — prevents YAML float parsing; consistent with requirement schema established in Phase 8)

The phrasing "consistent with requirement schema established in Phase 8" confirms both are `'2.0'`. However, sara-update line 87 says `schema_version = '2.0'` only when describing decision artifacts — the requirement bullet at line 86 only lists `type`, `priority`, and the `raised-by` mapping, and does NOT explicitly mention setting `schema_version = '2.0'` for new requirement creates. This omission means an LLM executing sara-update might leave `schema_version` as the template default (`'2.0'` from the template — fine) but could also misread the note as decision-only.

**Fix:** In sara-update Step 2 create branch, add an explicit bullet for requirement artifacts alongside the `type`/`priority` bullets:
```
- For requirement artifacts: set `schema_version` = `'2.0'` (single-quoted)
```

---

### CR-03: Empty `extraction_plan` early-exit in sara-update Step 1 does not advance stage to `"complete"`

**File:** `.claude/skills/sara-update/SKILL.md:41-44`

**Issue:** Step 1 says: "If `{extraction_plan}` is empty or null: Output message. Proceed directly to Step 4 (commit pipeline-state.json stage advance only)." Step 4 says the commit block includes `pipeline-state.json` and only writes `stage = "complete"` after a successful commit. However, if the extraction_plan is empty and we skip to Step 4, the pipeline-state.json has not yet been modified (stage is still `"approved"`) — so the commit in Step 4 has nothing meaningful to commit except the unchanged pipeline-state.json. More critically, if Step 4's git add + commit is the standard block (`git add wiki/requirements/ wiki/decisions/ ...`), those directories may have no changed files, causing the commit to fail (empty commit). If the commit fails because there are no changed files, stage never advances to `"complete"`, and the item is permanently stuck in `"approved"` with an empty plan.

**Fix:** When `extraction_plan` is empty or null, explicitly update `stage = "complete"` in memory and write `pipeline-state.json` before proceeding to the commit step. Or instruct using `git commit --allow-empty` for this specific case. Or add a guard: if extraction_plan is empty, skip the wiki file writes AND skip the commit, directly write `stage = "complete"` to pipeline-state.json and report done.

---

### CR-04: Sorter output schema example is missing `dec_type` field for `action=create` decision artifact

**File:** `.claude/agents/sara-artifact-sorter.md:116-128`

**Issue:** The `output_format` example shows a `create` decision artifact at lines 116–128. That object contains `status`, `dec_type`, `chosen_option`, and `alternatives` — correctly. However, the rules section at line 153 says:

> For decision artifacts, preserve `status`, `dec_type`, `chosen_option`, and `alternatives` exactly as received from the extraction pass.

The pass-through rule is stated. But the example `create` decision object at lines 116–128 has `dec_type: "architectural"` populated. The rules section at line 154 specifically calls out update artifacts for mandatory field presence. There is no explicit rule that a create decision artifact MUST have all four fields populated before being returned. An LLM executing the sorter may read the rules as "preserve what you receive" but then silently drop `dec_type` if it was somehow absent in the incoming merged artifact (e.g., due to an extraction pass bug). sara-update would then fail to set the `type` frontmatter field.

More concretely: the output rules say "preserve... exactly as received" but do NOT say "validate that these fields are present; if absent, raise an error or surface a question." This creates a silent pass-through of a corrupt artifact.

**Fix:** Add a validation rule in the sorter's process or output rules:
```
- For decision artifacts in cleaned_artifacts: if any of `status`, `dec_type`,
  `chosen_option`, or `alternatives` is absent or null, surface a question:
  "Decision artifact '{title}' is missing required field '{field}'. The extraction
  pass may have failed. Skip this artifact (C) or accept as-is with empty value (A/B)?"
```

---

## Warnings

### WR-01: "will" as COMMITMENT language — detection rule is ambiguous between requirement and decision passes

**File:** `.claude/skills/sara-extract/SKILL.md:59` (requirements pass) and line 99 (decisions pass)

**Issue:** The requirements pass includes `"will" (as a commitment to future behaviour, not narrating past events) → priority: must-have`. The decisions pass includes `"we will use" (as a settled commitment, not hypothetical)`. The phrase "we will use React" is simultaneously a future-behaviour commitment (matching the requirement INCLUDE rule) AND commitment language in the decisions pass. No guidance exists to prevent double-extraction of the same "we will use X" passage as both a requirement and a decision. The sorter would flag it as a type-ambiguity question, but it would be better to address the ambiguity at the detection rule level with a clearer disambiguation signal.

**Fix:** Add a disambiguation note to the requirements pass INCLUDE rule:
```
- "will" (as a commitment to future behaviour, not narrating past events) → priority: must-have
  NOTE: "we will use [technology]" is more naturally a DECISION (technology choice) than a
  requirement. If the passage names a specific tool or platform, prefer the decisions pass.
  Only extract as a requirement if the passage describes a system behaviour obligation.
```

---

### WR-02: Missing edge case — what happens when `artifact.chosen_option` is empty for an accepted decision

**File:** `.claude/skills/sara-update/SKILL.md:219-222`

**Issue:** The decision body section instructions say:
> If artifact.status == "accepted": write artifact.chosen_option content — the option or approach the team selected. If artifact.chosen_option is an empty string, synthesise the decision from artifact.title and {discussion_notes}.

The extraction pass sets `chosen_option` to `""` only for open/misalignment decisions (line 131 in sara-extract). However, the sorter may produce a commit decision whose `chosen_option` was poorly extracted as an empty string (e.g., the source said "we agreed to proceed" without naming the option explicitly). The instruction says "synthesise from title and discussion_notes" — but this is synthesis without a grounded source passage, which contradicts the "never fabricate" principle stated elsewhere. There is no instruction to flag this as a gap or leave a placeholder.

**Fix:** Replace the synthesis fallback with a placeholder instruction:
```
If artifact.chosen_option is an empty string for an accepted decision:
  Write: "[Option not captured — review source document and update manually.]"
  Do not synthesise a decision that is not grounded in source_doc or discussion_notes.
```

---

### WR-03: Sorter process step 6 says "exclude duplicates that the human will resolve via questions" — but no re-insertion logic is defined

**File:** `.claude/agents/sara-artifact-sorter.md:79`

**Issue:** Step 6 says: "Exclude duplicates that the human will resolve via questions — those will be re-added after resolution." However, the resolution logic is in sara-extract (Step 3 question loop), not in the sorter. The sorter never re-adds anything. What actually happens after the human answers the type-ambiguity question in sara-extract is that sara-extract removes one of the two artifacts from `cleaned_artifacts`. But if both artifacts were excluded from `cleaned_artifacts` by the sorter (per step 6), neither is available to keep — the resolution logic in sara-extract operates on the `cleaned_artifacts` array by removing one, which requires both to already be present.

The actual intended behavior seems to be: the sorter includes BOTH conflicting artifacts in `cleaned_artifacts`, the question asks which to keep, and sara-extract removes the rejected one. But step 6 says to exclude them. This is contradictory.

**Fix:** Clarify step 6:
```
For type-ambiguity pairs: include BOTH artifacts in cleaned_artifacts (do not exclude them).
The resolution question tells sara-extract which one to remove. Without both present, the
removal logic cannot operate.
```
Or alternatively, define that only one artifact is included and the question result either retains or replaces it.

---

### WR-04: `sara-init` CLAUDE.md template uses `type:` for decisions but extraction/update use `dec_type:`

**File:** `.claude/skills/sara-init/SKILL.md:219`

**Issue:** In the CLAUDE.md schema section written by sara-init (Step 9), the Decision schema shows:
```yaml
type: architectural  # architectural | process | tooling | data | business-rule | organisational
```
But the extraction pass (sara-extract line 129) and sara-update (line 89) both use `dec_type` in the artifact schema, and sara-update maps `artifact.dec_type` to the `type` field in the wiki page frontmatter. The CLAUDE.md description is correct for the on-disk wiki page format (frontmatter field is `type`), but the inline comment at line 219 is the only place this field appears in context, and the juxtaposition with the artifact-level `dec_type` naming is a potential source of confusion. More critically, the CLAUDE.md Decision template in sara-init at line 437 (the `.sara/templates/decision.md` write) correctly uses `type:` — consistent with wiki page format.

This is not a data integrity bug (on-disk format is correct) but it is a documentation inconsistency: CLAUDE.md describes wiki page frontmatter while sara-extract uses `dec_type` in the in-flight artifact JSON. A developer or LLM reading CLAUDE.md without sara-extract context would not know why the extraction artifact uses a different field name. The renaming rationale (avoid collision with envelope `type: "decision"` field) is documented in sara-extract line 129 but not in CLAUDE.md.

**Fix:** Add a comment in the CLAUDE.md Decision schema block:
```yaml
type: architectural  # wiki page field; artifact schema uses dec_type to avoid collision with
                     # envelope type: "decision" — sara-update maps dec_type → type on write
```

---

### WR-05: `sara-update` update branch for decisions does not handle `status: "proposed"` → `"open"` migration

**File:** `.claude/skills/sara-update/SKILL.md:308`

**Issue:** The update branch for decision artifacts says:
> Set `status` = `artifact.status` (either "accepted" or "open" from the artifact — do NOT keep any existing "proposed" value if present in the existing page)

This correctly instructs the LLM to overwrite a v1.0 "proposed" status. However, the instruction only mentions "do NOT keep any existing 'proposed' value" — it does not instruct what to do if the artifact's own `status` field is somehow "proposed" (which could happen if the sorter or extraction pass produced a corrupt artifact). An artifact with `status: "proposed"` would be written as-is, creating a v1.0 value in a v2.0 page.

**Fix:** Add a guard in the update branch:
```
- Set `status` = `artifact.status`. Valid values: "accepted" or "open" only.
  If artifact.status is "proposed" or any other value, default to "open" and log a warning:
  "Artifact {title} had invalid status '{value}' — defaulted to 'open'."
```

---

### WR-06: No instruction for handling an interrupted approval loop when sorter questions are partially answered

**File:** `.claude/skills/sara-extract/SKILL.md:256-257`

**Issue:** The note at line 256 says: "If `/sara-extract N` is re-run on an item that is still in `extracting` stage... re-run the full loop with freshly generated artifacts." This covers session interruption during the approval loop (Step 4). However, it does not cover interruption mid-sorter-question (Step 3 question loop). If a session resets after the user has answered 2 of 5 sorter questions, re-running `/sara-extract N` discards all sorter question answers and restarts from fresh extraction. The user must re-answer all sorter questions. This is noted nowhere, and the user may be confused about why previously answered questions reappear.

**Fix:** Add a note clarifying the re-run behaviour for sorter question interruption:
```
NOTE: Re-running /sara-extract {N} always re-runs the full extraction + sorter pipeline.
Previously answered sorter questions are not preserved. The user will be asked all sorter
questions again on re-run. This is by design — the fresh extraction may produce a different
artifact set.
```

---

### WR-07: `sara-update` Step 3 index append uses entity `type` for the Type column but should use `artifact.req_type` / `artifact.dec_type` per the note — contradiction

**File:** `.claude/skills/sara-update/SKILL.md:358-363`

**Issue:** The index update instruction says:
> Note: The `Type` column always holds the entity class (`requirement`, `decision`, `action`, or `risk`) — never the `req_type` sub-classification (e.g. `functional`). This ensures homogeneity across all entity types in the index.

This is explicit and correct. However, the printf template at line 361 uses `{artifact.type}` for the Type column. For decision artifacts, `artifact.type` is `"decision"` (the envelope type) — correct. But the note's parenthetical example specifically calls out not writing `functional` (which is `req_type`, not `artifact.type`). The instruction is consistent with the template in practice, but the note is potentially misleading: an LLM reading it might wonder whether `artifact.type` is the right field or whether it should look up `artifact.dec_type` for decisions. The note could be tightened to remove ambiguity.

**Fix:** Tighten the note:
```
Note: The `Type` column uses `artifact.type` (the entity class: requirement, decision,
action, or risk). Never use `artifact.req_type` or `artifact.dec_type` (sub-classifications)
in this column.
```

---

### WR-08: `sara-artifact-sorter` receives `<merged_artifacts>` described as "concatenation of all four specialist agent outputs" but sara-extract uses inline passes, not specialist agents

**File:** `.claude/agents/sara-artifact-sorter.md:9,19`

**Issue:** The sorter's `<role>` section says "You receive the merged output of four specialist extraction agents" and the `<input>` section describes `<merged_artifacts>` as "concatenation of all four specialist agent outputs." However, sara-extract explicitly states (notes, lines 293 and 303) that extraction runs as four sequential inline passes — "No specialist Task() agents are used for extraction." The source description in the sorter does not match the actual architecture. This creates confusion: an LLM that reads the sorter prompt might expect to interact with agent-formatted output when it is actually receiving inline LLM extraction output in the same JSON format.

**Fix:** Update the sorter's role description and input description to match the actual architecture:
```
<role>
You are sara-artifact-sorter. You receive the merged output of four inline extraction passes
(run sequentially by sara-extract against the source document), the existing wiki grep
summaries, and wiki/index.md. ...
</role>
```

---

### WR-09: `sara-update` action and risk body sections use a different quote format than requirement and decision sections

**File:** `.claude/skills/sara-update/SKILL.md:243-244` and `252-253`

**Issue:** For requirement and decision artifacts, the source quote format is:
```
> "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]
```
(stakeholder linked as a wikilink)

For action and risk artifacts, the source quote format is:
```
> "{artifact.source_quote}" — {stakeholder_name}
```
(stakeholder name as plain text, not a wikilink)

This inconsistency means action and risk body sections cannot navigate back to the stakeholder wiki page via click, while requirement and decision sections can. This is either intentional (and should be documented as such) or an oversight from when the action/risk templates were written before the wikilink rule was formalised.

**Fix:** If the inconsistency is unintentional, update action and risk quote format to use the wikilink:
```
> "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]
```
If intentional, add a note explaining why action/risk use plain text attribution.

---

## Info

### IN-01: Magic phrase "Pitfall 4 guard" appears twice in sara-extract with different meanings

**File:** `.claude/skills/sara-extract/SKILL.md:46` and line 304

**Issue:** Line 46 labels the re-read of wiki/index.md as "Pitfall 4 guard." Line 304 notes that "Sorter questions are presented to the human BEFORE the approval loop starts (Step 4). Never present sorter questions inside the artifact loop (Pitfall 4 guard)." These are two different pitfalls both labelled "Pitfall 4." The second note likely refers to a different numbered pitfall in the research document. This creates confusion about which pitfall is being guarded.

**Fix:** Disambiguate the labels:
```
Line 46: (Pitfall 4 guard — stale index)
Line 304: (Pitfall 5 guard — sorter questions inside loop)
```
Or remove the pitfall number references entirely and replace with descriptive labels.

---

### IN-02: `sara-init` CLAUDE.md template Decision schema has no `supersedes` field comment explaining empty vs populated

**File:** `.claude/skills/sara-init/SKILL.md:221`

**Issue:** The Decision schema in CLAUDE.md shows `supersedes: ""  # DEC-NNN or empty`. This is adequate for humans but when sara-update creates a decision artifact (Step 2 create branch), it uses template defaults for fields not set by the artifact. The `supersedes` field is never populated by the extraction or update pipeline — it is manual-only. This should be documented in the template comment to prevent a future LLM pass from attempting to auto-populate it.

**Fix:** Update the comment:
```yaml
supersedes: ""    # DEC-NNN if this decision replaces an older one — set manually only
```

---

### IN-03: `sara-init` report in Step 13 says "Directories created (11)" but only 10 subdirectories are created; `.sara/templates` is the 11th

**File:** `.claude/skills/sara-init/SKILL.md:540-553`

**Issue:** The success report text at line 540 says "Directories created (11):" and lists 11 entries. Counting the `mkdir -p` targets in Step 5: `raw/input`, `raw/meetings`, `raw/emails`, `raw/slack`, `raw/documents` (5 raw subdirectories), `wiki/requirements`, `wiki/decisions`, `wiki/actions`, `wiki/risks`, `wiki/stakeholders` (5 wiki subdirectories), and `.sara/templates` (1). That is indeed 11 directories. The count is correct. However, the report does not include `.sara/` itself — `mkdir -p .sara/templates` creates both `.sara/` and `.sara/templates/`. The report omits `.sara/` as a created directory, which is a minor documentation gap rather than a bug.

**Fix:** Either note that `.sara/` is also created as a parent, or add it to the list.

---

### IN-04: `sara-update` wikilink rule for `wiki/index.md` and `wiki/log.md` rows uses `[[ID]]` bare links, but cross-reference rule in CLAUDE.md requires `[[ID|display]]`

**File:** `.claude/skills/sara-update/SKILL.md:137-138`

**Issue:** The wikilink rule in sara-update correctly exempts index and log table rows from the `[[ID|display]]` requirement:
> `wiki/index.md` and `wiki/log.md` table rows use bare `[[ID]]` — they are structured tables, not prose.

However, the behavioral rule in CLAUDE.md (written by sara-init) says:
> In body prose, always use `[[ID|ID Title]]` ... never a bare `[[ID]]` or raw ID string. Frontmatter fields remain plain IDs.

CLAUDE.md does not include the exception for index/log table rows. An LLM reading only CLAUDE.md might apply the `[[ID|display]]` rule to index rows, producing ugly or broken table formatting.

**Fix:** Add the table-row exception to CLAUDE.md behavioral rule 5:
```
Exception: wiki/index.md and wiki/log.md table cells use bare [[ID]] — they are
structured lookup tables, not prose.
```

---

### IN-05: `sara-extract` note about `raised_by` containing "sed" as a false-positive grep match is in both sara-extract and sara-update notes — but the grep check it defends against is not described anywhere

**File:** `.claude/skills/sara-extract/SKILL.md:302` and `.claude/skills/sara-update/SKILL.md:435`

**Issue:** Both skills contain an identical defensive note about the `raised_by` field name containing the substring "sed" and being a false positive for any grep check of `jq\|sed\|awk`. However, neither skill references any actual grep check that tests for shell text-processing tool usage. There is no automated linting step in these skills that would trigger this false positive. The note appears to be defending against an external linter or reviewer check (likely in a separate sara-lint skill or CI step), but that context is absent. The note is not harmful, but it adds noise and may confuse future maintainers who cannot find the grep check it references.

**Fix:** Add context to the note:
```
NOTE: The sara-lint skill checks for shell text-processing tool usage via grep for
`jq\|sed\|awk`. The field name `raised_by` contains "sed" as a substring and will
produce a false positive. sara-lint must exclude this match.
```

---

### IN-06: `sara-update` Step 1 empty plan guard says "Proceed directly to Step 4" but Step 4 references `written_files` from Step 2 which was skipped

**File:** `.claude/skills/sara-update/SKILL.md:41-44`

**Issue:** When extraction_plan is empty, the instruction is to skip to Step 4 (commit and report). Step 4's "Update Complete" output block references `{written_files list}`. If Step 2 was skipped, `written_files` was never initialised. The LLM may output an empty list, "N/A", or produce a template error. The `count` variable is similarly undefined.

This overlaps with CR-03 but is a distinct symptom: even if the commit issue is resolved, the output block will reference uninitialised variables.

**Fix:** Add initialisation before the skip:
```
Set written_files = [] and count = 0 before proceeding to Step 4.
```
Or add a separate output block for the empty-plan completion case that does not reference `written_files`.

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
