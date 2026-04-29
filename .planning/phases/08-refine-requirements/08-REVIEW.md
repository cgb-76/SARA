---
phase: 08-refine-requirements
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .claude/agents/sara-artifact-sorter.md
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-update/SKILL.md
findings:
  critical: 3
  warning: 8
  info: 4
  total: 15
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed four SARA skill/agent files: `sara-artifact-sorter` (agent), `sara-extract` (skill), `sara-init` (skill), and `sara-update` (skill). These form the core extract-sort-write pipeline for a wiki management system built on LLM prompt engineering.

The pipeline has solid foundations: the `raised_by` → `raised-by` mapping is documented, `req_type`/`priority` passthrough is consistent end-to-end, and the counter-before-write ordering for ID assignment is correctly specified. However, three critical issues were found: a logic contradiction where sara-update STOPs on a legitimately empty extraction plan, a stale note in sara-extract that references a deleted specialist-Task() architecture, and an under-specified `source` field update behaviour (scalar vs list) that will produce inconsistent wiki pages. Eight warnings cover instruction ambiguities that will produce incorrect or unpredictable LLM output in specific edge cases.

---

## Critical Issues

### CR-01: sara-update STOPs on a valid empty extraction plan

**File:** `.claude/skills/sara-update/SKILL.md:41-42`
**Issue:** Step 1 says: "If `{extraction_plan}` is empty or null: … Output re-run message and STOP." sara-extract Step 5 explicitly states that zero accepted artifacts is a valid outcome — it advances stage to `"approved"` with `extraction_plan: []`. When the user deliberately rejects all artifacts, sara-update will refuse to process the item and tell the user to re-run sara-extract. This traps the item: sara-update won't proceed (empty plan), but sara-extract won't re-run (stage is already `"approved"`). The item becomes stuck.

**Fix:** Change the empty-plan guard to a no-op path rather than a STOP:

```
If {extraction_plan} is empty or null:
  Output: "Extraction plan for item {N} is empty — no wiki files to write."
  Proceed directly to Step 4 (commit pipeline-state.json stage advance only).
```

Step 4 should still commit `pipeline-state.json` (to advance stage to `"complete"`) even with zero artifacts, consistent with sara-extract's stated behaviour: "You can still run /sara-update {N} (it will be a no-op)."

---

### CR-02: Stale architecture note contradicts current inline-extraction design

**File:** `.claude/skills/sara-extract/SKILL.md:259`
**Issue:** The notes section says: "The `discussion_notes` string MUST be passed explicitly in each specialist Task() prompt. Agents start cold and have no implicit access to pipeline-state.json." But the process (Step 3) explicitly states "Do NOT use Task() for extraction; each pass is an inline LLM prompt against the already-in-context source document." There are no specialist Task() agents in the current architecture — the four extraction passes are inline. An LLM executing this skill will encounter a direct contradiction: the process says don't use Task(), but a prominent "MUST" note says to pass discussion_notes to each specialist Task() prompt. This could cause the LLM to spawn unwanted Task() calls or become confused about the architecture.

**Fix:** Remove the stale specialist-agent note (lines 259–260). The correct note is already present at line 246: "Extraction runs as four sequential inline passes against the already-in-context source document — no specialist Task() agents are used." The stale note is a duplicate from an earlier architecture that has since been superseded.

---

### CR-03: `source` field update behaviour is undefined for multi-ingest updates

**File:** `.claude/skills/sara-update/SKILL.md:266`
**Issue:** The update branch says: "Update the `source` field to include `{item.id}` in addition to any existing source value." The wiki entity templates define `source` as a scalar string field (e.g. `source: "MTG-001"`). There is no instruction for how to combine a new ingest ID with an existing value — should it become a YAML list (`[MTG-001, MTG-003]`)? A comma-separated string (`"MTG-001, MTG-003"`)? An LLM will invent a format, producing inconsistent wiki pages across runs. The `grep -rh "^summary:"` in sara-extract only targets `^summary:` lines, so this won't break dedup — but Obsidian display and any future tooling consuming `source:` will see heterogeneous types.

**Fix:** Define the exact merge strategy and update the template comment to match:

```yaml
source: []  # list of ingest IDs (e.g. [MTG-001, MTG-003])
```

And in sara-update update branch:
```
Update the `source` field: if it is currently a scalar string, convert it to a single-element
YAML list. Append {item.id} to the list if not already present.
Result: source: [MTG-001, MTG-003]
```

Update all five templates in sara-init Step 12 and the CLAUDE.md schema block accordingly.

---

## Warnings

### WR-01: Sorter resolution logic description is wrong for cross-reference questions

**File:** `.claude/skills/sara-extract/SKILL.md:155-158`
**Issue:** The sorter question resolution block handles three question types (type-ambiguity, likely-duplicate, cross-reference). The A/B/C dispatch says: "If user replies 'A': apply resolution A (keep as type1; remove the type2 duplicate from cleaned_artifacts). If user replies 'B': apply resolution B (keep as type2; remove the type1 duplicate)." This description is only correct for type-ambiguity questions. For cross-reference questions (A=yes, add cross-link; B=no, not related), there is no "type1/type2 duplicate" to remove — the action is to add or skip a `related` field entry. An LLM following these instructions will incorrectly attempt to remove an artifact from `cleaned_artifacts` when the user answers a cross-reference question.

**Fix:** Expand the resolution logic to branch by question type:

```
Determine the question type from its text:
  - If the question contains "extracted as both": type-ambiguity resolution
    A: keep type1, remove the type2 duplicate from cleaned_artifacts
    B: keep type2, remove the type1 duplicate from cleaned_artifacts
    C: remove both from cleaned_artifacts
  - If the question contains "looks similar to": likely-duplicate resolution
    A: keep action=update for the matched existing entity; remove create duplicate
    B: keep action=create (separate new artifact)
    C: remove from cleaned_artifacts
  - If the question contains "appears to relate to": cross-reference resolution
    A: add the referenced entity ID to artifact.related
    B: no change to artifact.related
```

---

### WR-02: Sorter create-vs-update and question-generation ordering allows double-processing

**File:** `.claude/agents/sara-artifact-sorter.md:33-68`
**Issue:** Step 3c says: "If a match is found: change `action` to 'update'." Step 5 says: for "likely duplicates" generate a question. There is no instruction preventing the sorter from both changing an artifact to `action=update` AND generating a "likely duplicate" question for the same artifact. An uncertain or moderate-confidence match could trigger both paths. The human would be asked to decide on a duplicate that the sorter has already resolved to `update`.

**Fix:** Add an explicit ordering rule in Step 5:

```
Do NOT generate a "likely duplicate" question for any artifact that was already resolved
to action="update" by the create-vs-update pass in Step 3. Only generate a likely-duplicate
question when a semantic match was found but confidence is insufficient to assert action=update
(i.e. the sorter chose not to flip the artifact in Step 3 due to uncertainty).
```

---

### WR-03: Sorter grep search includes `wiki/stakeholders/` — risk of spurious update matches

**File:** `.claude/agents/sara-artifact-sorter.md:31` and `.claude/skills/sara-extract/SKILL.md:130-132`
**Issue:** The grep command passed to the sorter searches `wiki/stakeholders/` for `^summary:` lines. Stakeholder summaries (e.g. "STK: Sales, Senior Account Executive, Rajiwath Patel") could semantically match a risk or action artifact that mentions a person's name or department. The sorter would then mark an artifact as `action=update` against a STK entity, but the sorter only produces `REQ/DEC/ACT/RSK` artifact types — it cannot update a stakeholder page. sara-update has no `wiki_dir` mapping for `stakeholder` type and no update logic for STK entities. An update artifact with `existing_id: "STK-006"` would reach sara-update with no handling.

**Fix:** Remove `wiki/stakeholders/` from the grep command, as stakeholder entities cannot be produced by the extract pipeline:

```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null
```

Apply this change in both sara-extract (Step 3, grep command) and in the `<input>` description of sara-artifact-sorter.

---

### WR-04: sara-update notes contradict the process on what is passed to the sorter

**File:** `.claude/skills/sara-extract/SKILL.md:246`
**Issue:** The notes at line 246 say: "Only the merged artifact array (which is small) is passed to the sorter Task()." But the process Step 3 says: `Task(sara-artifact-sorter, prompt=merged+grep_summaries+wiki_index)` — three inputs are passed: merged artifacts, grep summaries, and wiki/index.md. This contradiction will confuse any LLM reading the notes as a summary of what the sorter receives, and could cause it to omit the grep_summaries or wiki_index from the Task() prompt.

**Fix:** Update the note to accurately reflect all three inputs:

```
The merged artifact array, grep summaries, and wiki/index.md are passed to the sorter
Task(). The source document is NOT passed to the sorter — it is read once in Step 2
and remains in context for all four inline extraction passes only.
```

---

### WR-05: Decision initial `status` instruction is ambiguous

**File:** `.claude/skills/sara-update/SKILL.md:89`
**Issue:** The create branch says: "For decision artifacts: set `status` = the initial decision status (see template — the first valid status value)". This requires the LLM to read the template, find the comment `# proposed | accepted | rejected | superseded`, and infer that `proposed` is the initial value. The indirection is unnecessary and introduces a failure mode where the LLM selects a wrong value (e.g. `accepted`). All other entity types have their initial status stated explicitly (`"open"`).

**Fix:** Make it explicit:

```
For decision artifacts: set `status` = "proposed"
```

---

### WR-06: `owner` field for action/risk artifacts is not in the extraction schema

**File:** `.claude/skills/sara-extract/SKILL.md:99-116` and `.claude/skills/sara-update/SKILL.md:91-92`
**Issue:** sara-extract does not produce an `owner` field for action or risk artifacts — the extraction schema only includes `action, type, id_to_assign, title, source_quote, raised_by, related, change_summary`. sara-update silently derives `owner = artifact.raised_by` for action and risk creates. If `raised_by` is the placeholder `"STK-NNN"` (no identified stakeholder in the source), the written page will have `owner: "STK-NNN"` — a non-functional placeholder that wiki/index.md and any downstream tooling cannot resolve. There is no instruction to warn the user or leave `owner` blank in this case.

**Fix:** Add an explicit fallback instruction in sara-update Step 2 (action/risk create branch):

```
- `owner` = `artifact.raised_by` if it is a resolved STK ID (e.g. "STK-001");
  otherwise set `owner` = "" (empty — leave unassigned; do not write a placeholder ID)
```

---

### WR-07: Index `Type` column populated with entity type, not `req_type` — undocumented

**File:** `.claude/skills/sara-update/SKILL.md:311-313`
**Issue:** Step 3 appends index rows using `{artifact.type}` in the Type column. For a requirement artifact, `artifact.type` is `"requirement"` (the entity class), not the `req_type` (e.g. `"functional"`). The wiki/index.md header is `| ID | Title | Status | Type | Tags | Last Updated |`. There is no documentation clarifying whether the Type column should hold entity type (`requirement`) or requirement sub-type (`functional`). An LLM reader could populate the column with `req_type`, breaking the homogeneity of the index across entity types.

**Fix:** Add an explicit note in Step 3:

```
The `Type` column in wiki/index.md always holds the entity class
(requirement | decision | action | risk) — never the req_type sub-classification.
```

---

### WR-08: `req_type` and `priority` missing from sorter output_format for `action=update` requirement artifacts

**File:** `.claude/agents/sara-artifact-sorter.md:78-110`
**Issue:** The sorter's `<output_format>` shows only one example for `action=update` (a decision artifact). There is no example update artifact for a requirement. The rules section says "preserve `priority` and `req_type` exactly as received" but does not show whether these fields appear in the update object's output schema. sara-update's update branch explicitly reads `artifact.req_type` and `artifact.priority` for requirement updates (line 271). If the sorter strips these fields when changing an artifact from create to update (action=update), sara-update will receive `undefined` for both and either skip the field substitution or crash.

**Fix:** Add a requirement update example to the sorter output_format, and add an explicit rule:

```json
{
  "action": "update",
  "type": "requirement",
  "existing_id": "REQ-005",
  "title": "Title of existing requirement",
  "source_quote": "Exact verbatim text",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "Add new context from this source document",
  "priority": "must-have",
  "req_type": "functional"
}
```

And add to the rules: "For requirement update artifacts, `priority` and `req_type` MUST be present — copy them from the incoming create artifact unchanged."

---

## Info

### IN-01: `raised_by` → `raised-by` mapping not documented in sorter schema

**File:** `.claude/agents/sara-artifact-sorter.md:78-118`
**Issue:** The sorter output_format uses `raised_by` (underscore, JSON convention). sara-update's notes document the mapping to `raised-by` (hyphen, YAML convention) at line 383. The sorter has no comment or note about this downstream mapping. A future maintainer modifying the sorter schema could change the field name and break the mapping silently.

**Fix:** Add a comment to the sorter output_format rules:

```
- `raised_by` (JSON field, underscore) maps to `raised-by` (YAML frontmatter field, hyphen)
  in wiki pages. This mapping is applied by /sara-update. Do not rename this field.
```

---

### IN-02: `wiki/index.md` wikilink format inconsistency — bare `[[ID]]` vs resolved `[[ID|title]]`

**File:** `.claude/skills/sara-update/SKILL.md:133-134`
**Issue:** The wikilink rule says: "`wiki/index.md` and `wiki/log.md` table rows use bare `[[ID]]` — they are structured tables, not prose." But Step 3 writes index rows using `[[{assigned_id}]]` (bare) for the ID column. The log step also uses bare `[[ID]]` links. This is explicitly stated as intentional, but CLAUDE.md's cross-reference rule (written by sara-init) says "never a bare `[[ID]]`" with no exception for tables. The two rules directly contradict each other for anyone reading CLAUDE.md without sara-update's local clarification.

**Fix:** Add an exception to the CLAUDE.md cross-reference rule (sara-init Step 9):

```
Cross-references in `wiki/index.md` and `wiki/log.md` table rows use bare `[[ID]]` —
structured table cells are exempt from the `[[ID|display text]]` rule.
```

---

### IN-03: `schema_version` quoting rule not mentioned in CLAUDE.md

**File:** `.claude/skills/sara-init/SKILL.md:209-301` and `.claude/skills/sara-update/SKILL.md:381`
**Issue:** sara-update notes (line 381) say: "`schema_version` must always be quoted: `"1.0"` (not `1.0`). This prevents Obsidian's YAML parser from treating it as a float." This rule exists nowhere in CLAUDE.md (the shared schema contract written by sara-init and loaded by all skills). Any skill that writes a wiki page without reading sara-update's notes could produce unquoted `schema_version: 1.0`, breaking Obsidian's YAML parsing.

**Fix:** Add to CLAUDE.md (sara-init Step 9) under Behavioral Rules:

```
7. **schema_version quoting:** Always quote `schema_version` values — use `"1.0"` (double-quoted
   string), never bare `1.0` (YAML float). For requirement pages use single-quoted `'2.0'`
   to prevent float parsing.
```

---

### IN-04: `extraction_plan` re-run safety note is incomplete

**File:** `.claude/skills/sara-extract/SKILL.md:209`
**Issue:** The re-run note says: "If `/sara-extract N` is re-run on an item that is still in `extracting` stage (possible if a previous session was interrupted): re-run the full loop with freshly generated artifacts." This is correct and safe. However, there is no note about what happens to the `extraction_plan` field in pipeline-state.json if the previous interrupted session had already written a partial plan. Step 5 says "overwrite it unconditionally" but the re-run note does not cross-reference this, leaving a gap in the reasoning for a maintainer reviewing the re-run path.

**Fix:** Add to the re-run note:

```
Step 5 always overwrites `extraction_plan` unconditionally — any partial plan from the
interrupted session is discarded and replaced with the freshly approved list.
```

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
