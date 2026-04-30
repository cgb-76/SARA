---
phase: 14-extraction-pipeline-fix
reviewed: 2026-04-30T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-update/SKILL.md
findings:
  critical: 2
  warning: 6
  info: 4
  total: 12
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-04-30
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Both skill files describe multi-step LLM-orchestrated workflows for extracting structured wiki artifacts from meeting notes and writing them to disk. The Phase 14 additions — `temp_id` assignment during extraction passes and the `temp_id → real_id` resolution block in sara-update — are mechanically correct in their happy paths. However, several logic errors and ambiguities were found that could cause an LLM executing these skills to produce silent data corruption, duplicate IDs, or broken `related[]` links. Two critical issues relate to sorter-injected real IDs being corrupted by the full-mesh linking step, and the `preview_counters` simulation diverging from the real write-loop when mixed-type plans are present. Six warnings cover unhandled edge cases around `temp_id` uniqueness, rejected artifacts carrying stale `temp_id` values in the sorter question resolution path, and update-action skipping logic gaps. Four info items cover naming inconsistencies and minor ambiguities.

---

## Critical Issues

### CR-01: Full-mesh step overwrites sorter-injected real IDs in `related[]`

**File:** `.claude/skills/sara-extract/SKILL.md:394-408`

**Issue:** The full-mesh step in Step 5 sets `A.related` = all OTHER `temp_id` values unconditionally. But during Step 3 sorter question resolution, an "appears to relate to" answer (option A) adds a real entity ID (e.g. `DEC-003`) directly into an artifact's `related[]` array (line 324). The full-mesh step then overwrites `A.related` entirely with a fresh array of `temp_id` strings, discarding the sorter-resolved real ID. When sara-update later runs the substitution pass, `DEC-003` is no longer in `related[]` and the cross-link is silently lost.

**Fix:** Change the full-mesh step to merge rather than replace: start with the existing `A.related` entries (which may contain sorter-injected real IDs), then add the `temp_id` values of all other approved artifacts that are not already in the array. Deduplicate the result.

```
For each artifact `A` in `approved_artifacts`:
  # Preserve any real IDs injected by sorter cross-reference resolutions
  existing_real_ids = [entry for entry in A.related if entry does not match /^[a-f0-9]{8}$/]
  new_temp_ids = [B.temp_id for B in approved_artifacts if B.temp_id != A.temp_id]
  A.related = deduplicate(existing_real_ids + new_temp_ids)
```

---

### CR-02: `preview_counters` simulation diverges when plan contains mixed create/update order

**File:** `.claude/skills/sara-update/SKILL.md:68-86`

**Issue:** The Temp ID resolution block iterates `{extraction_plan}` in order and increments `preview_counters` only for `action == "create"` artifacts. The write loop also iterates in the same order, skipping update artifacts for counter purposes. These should stay in sync. However, the instruction says "skip artifacts where `artifact.action == 'update'` — they have no temp_id" (line 83), which is the correct intent. The flaw is that the text never states the write loop iterates in the same order as `{extraction_plan}`. If an LLM executing this skill processes the two loops in different orderings (e.g., processes all creates first then updates in the write loop, but processes the plan in declaration order in the preview loop), the ID assignment sequence will diverge. There is also no guard against a create artifact that has a missing or empty `temp_id` field — the skill says "leave `t` unchanged" for unknown entries (line 93) but does not warn the LLM that an unresolvable `temp_id` will silently write a raw hex string into the `related[]` frontmatter of the wiki page, breaking wikilink parsing in Obsidian.

**Fix (two parts):**

Part 1 — Make the iteration order constraint explicit in both the preview loop and the write loop:

```
IMPORTANT: Both the preview loop (above) and the write loop (below) iterate
{extraction_plan} in the same declared order. Do NOT reorder artifacts between
these two loops. The preview counter sequence MUST match the real counter sequence.
```

Part 2 — Add an unresolvable `temp_id` warning:

```
After the substitution pass, scan each artifact.related array for any entries
that still match the pattern /^[a-f0-9]{8}$/ (i.e. were not resolved).
For each such entry, output a warning:
  "WARNING: temp_id '{entry}' in artifact '{artifact.title}' could not be
   resolved to a real ID. It will be written as-is. Investigate whether
   the corresponding artifact was rejected or is missing a temp_id."
```

---

## Warnings

### WR-01: `temp_id` uniqueness is not enforced — collision risk on large batches

**File:** `.claude/skills/sara-extract/SKILL.md:96-99` (and identically at lines 158-161, 208-211, 265-268)

**Issue:** The instruction offers the LLM a choice: run the Bash one-liner or "generate inline as a random 8-hex string (e.g. `a3f2b901`)". An LLM generating inline will not have true randomness — it may produce the same value for multiple artifacts (e.g., repeating the example `a3f2b901` literally, or generating low-entropy variants). Two artifacts with the same `temp_id` will cause the full-mesh step to link an artifact to itself (since `B.temp_id != A.temp_id` would not exclude the duplicate), and the `id_map` in sara-update will silently overwrite the first entry with the second. The result is one artifact getting linked to the wrong real ID with no error signal.

**Fix:** Remove the "generate inline" option. Require the Bash one-liner exclusively. Add a post-generation uniqueness check:

```
- Set `temp_id` = result of Bash: `python3 -c "import secrets; print(secrets.token_hex(4))"`
  MANDATORY: use the Bash tool. Do NOT generate inline — inline generation is not random.
  After all four passes complete, verify all temp_ids in {merged} are unique.
  If any duplicates are found, regenerate the duplicate temp_id(s) with a new Bash call.
```

---

### WR-02: Sorter `questions` field absence is not guarded — KeyError risk

**File:** `.claude/skills/sara-extract/SKILL.md:300`

**Issue:** Line 300 assigns `{sorter_questions}` = `sorter_output.questions` immediately after the sorter output is parsed. The guard at line 294 only checks that the output is valid JSON and that `cleaned_artifacts` is present. If the sorter agent omits the `questions` field entirely (returns `{"cleaned_artifacts": [...]}` with no `questions` key), the LLM will encounter a missing-field access. The condition at line 302 ("if `{sorter_questions}` is non-empty") provides implicit protection only if the LLM treats an absent field as an empty array — which is not stated.

**Fix:** Explicitly default `questions` to `[]` when absent:

```
- {cleaned_artifacts} = sorter_output.cleaned_artifacts
- {sorter_questions} = sorter_output.questions if "questions" key exists, else []
```

---

### WR-03: Rejected artifacts retain stale `temp_id` values that pollute `id_map` in sara-update

**File:** `.claude/skills/sara-extract/SKILL.md:371-372` / `.claude/skills/sara-update/SKILL.md:74-83`

**Issue:** The full-mesh step in Step 5 operates only on `approved_artifacts`. Rejected artifacts are never added to `approved_artifacts`. However, the sorter may have already injected a rejected artifact's `temp_id` as a cross-reference entry in another artifact's `related[]` array (via the "appears to relate to" question, option A). If the user later rejects the referenced artifact in Step 4, the temp_id remains in the approved artifact's `related[]`. In Step 5, the full-mesh step adds temp_ids of approved artifacts — it does not remove stale temp_ids of rejected artifacts from existing `related[]` entries. The `id_map` in sara-update will not contain the rejected artifact's `temp_id` (it has no `action == "create"` entry), so the substitution pass will leave it as a raw hex string in the frontmatter.

**Fix:** Add a cleanup pass in Step 5 after the full-mesh step:

```
After the full-mesh step, strip any temp_id values from artifact.related[] that do not
correspond to an artifact in approved_artifacts:
  approved_temp_ids = set of all A.temp_id for A in approved_artifacts
  For each artifact A in approved_artifacts:
    A.related = [t for t in A.related if t in approved_temp_ids OR t matches a real entity ID pattern]
```

---

### WR-04: Update artifacts with `action == "update"` skip the approval display line for `existing_id`

**File:** `.claude/skills/sara-extract/SKILL.md:350-355`

**Issue:** The Step 4 display template shows:
```
Action: CREATE new {TYPE}-NNN  /  UPDATE {existing_id}
```
This is presented as a single line covering both cases. The instruction does not tell the LLM to conditionally display one or the other — it should show "CREATE new {TYPE}-NNN" for create actions and "UPDATE {existing_id}" for update actions, not both simultaneously. An LLM may literally render both halves of the slash-separated string for every artifact, which is confusing and potentially misleading for the user reviewing a CREATE artifact.

**Fix:** Split into explicit conditional branches:

```
Action: CREATE new {id_to_assign}    ← if artifact.action == "create"
Action: UPDATE {artifact.existing_id}  ← if artifact.action == "update"
```

---

### WR-05: `update` artifacts in sara-update have no `temp_id` but the substitution pass does not explicitly skip them

**File:** `.claude/skills/sara-update/SKILL.md:90-97`

**Issue:** The substitution pass (lines 90-97) iterates `{extraction_plan}` and walks each `artifact.related` array. For update artifacts, `artifact.related` may contain temp_ids (from the full-mesh step in sara-extract Step 5, which only runs on `approved_artifacts` but update artifacts are also approved). The pass correctly replaces resolved temp_ids, but the prose at line 83 states "skip artifacts where `artifact.action == 'update'` — they have no temp_id" in the context of the preview loop. This comment could mislead an LLM into also skipping the substitution pass for update artifacts' `related[]` arrays, leaving temp_ids unresolved in update artifact `related[]` entries.

**Fix:** Add an explicit clarification:

```
NOTE: The "skip update artifacts" instruction above applies ONLY to the id_map
construction loop (update artifacts contribute no temp_id key to id_map).
The substitution pass below applies to ALL artifacts — both create and update.
Update artifacts may have temp_ids in their related[] arrays (from the full-mesh
step in sara-extract) and those must also be resolved.
```

---

### WR-06: `discussion_notes` note in sara-extract Step 3 claims it is "already in memory" but Step 2 notes do not confirm this for config

**File:** `.claude/skills/sara-extract/SKILL.md:52-53`

**Issue:** Step 3 reads `config.json` with an explicit Read tool call but then says "Store `config.segments` for use in the `segments` inference step". The instruction does not specify where `config.segments` is stored relative to the four passes — only that it is stored after the Read. An LLM could interpret "store for use" as needing to re-read `config.json` inside each pass. More importantly, Step 2 introduces `{discussion_notes}` as a variable but the four passes in Step 3 never reference `{discussion_notes}` explicitly for the `segments` STK attribution sub-step (they reference `source or discussion_notes` only in the prose for `raised_by`). The STK file read for segments inference requires the STK-NNN ID to be parseable from the `source_quote` attribution suffix. If the attribution is in `discussion_notes` rather than `source_quote`, the STK-NNN ID will not be found by the attribution pattern.

**Fix:** Add a clarification to the STK attribution sub-step:

```
1. STK attribution: if `source_quote` ends with `— [[STK-NNN|…]]`, parse the STK-NNN ID
   from the attribution. If not found in source_quote, also check if discussion_notes
   identifies the speaker for this passage and extract STK-NNN from there.
```

---

## Info

### IN-01: `{sorter_questions}` variable naming is inconsistent with `{sorter_output}` naming style

**File:** `.claude/skills/sara-extract/SKILL.md:299-300`

**Issue:** The pattern established throughout the skill uses `{variable}` for intermediate values (e.g., `{merged}`, `{item}`, `{cleaned_artifacts}`). However, `sorter_questions` is introduced on line 300 without curly-brace wrapping in the assignment expression, though it is used with `{sorter_questions}` in the `Task()` prompt. The inconsistency is minor but could confuse an LLM about whether to treat it as a variable reference or a literal string.

**Fix:** Use consistent `{sorter_questions}` notation in the assignment line:

```
- `{cleaned_artifacts}` = sorter_output.cleaned_artifacts
- `{sorter_questions}` = sorter_output.questions (or [] if absent)
```

---

### IN-02: Step 4 Discuss counter warning fires at ">5" but message says "discussed {N} times"

**File:** `.claude/skills/sara-extract/SKILL.md:382-384`

**Issue:** The text says "After 5 Discuss cycles... present a plain-text warning" but the warning message says "This artifact has been discussed {N} times." This means the warning fires exactly at cycle 5 (the fifth Discuss), and the message will say "5 times". However the instruction says "After 5 cycles" which is ambiguous: does it mean after the 5th cycle completes (i.e., at cycle 6), or does it mean once 5 cycles have occurred (i.e., at cycle 5)? If an LLM interprets this as "after completing 5 cycles, on the 6th", the warning is delayed by one cycle.

**Fix:** Replace "After 5 Discuss cycles" with "Once the user has selected Discuss 5 times for the same artifact (i.e., on the 5th Discuss selection)":

```
Once the user has selected Discuss 5 times for the same artifact without an Accept
or Reject, present the warning and continue the AskUserQuestion loop.
```

---

### IN-03: `id_to_assign` placeholder is not updated for `action == "update"` artifacts in Step 4 display

**File:** `.claude/skills/sara-extract/SKILL.md:350-355` and notes at line 449

**Issue:** The notes state "`id_to_assign` and `existing_id` are mutually exclusive." The sorter resolves create-vs-update and sets `action`, `existing_id`, and clears or sets `id_to_assign`. The Step 4 display template always renders both as a slash-separated string. There is no instruction telling the LLM to omit the `id_to_assign` field entirely on update artifacts (it may be `""` or `"REQ-NNN"` — both are confusing to show). This overlaps with WR-04 but the additional info concern is that the note at line 449 does not cross-reference Step 4's display template.

**Fix:** Add a cross-reference note: "See Step 4 display template — for update artifacts, display only `existing_id`; omit `id_to_assign`."

---

### IN-04: `wiki/index.md` is passed to sorter Task() but not explicitly included in the "merge and sorter dispatch" instruction

**File:** `.claude/skills/sara-extract/SKILL.md:289-290`

**Issue:** Line 289 says `Task(sara-artifact-sorter, prompt=merged+grep_summaries+wiki_index)`. The variable `wiki_index` is never declared or assigned in Step 3. It was read in Step 2 (line 46 says "Read `wiki/index.md` HERE using the Read tool") but there is no explicit instruction to assign the result to a variable named `{wiki_index}`. An LLM may not know to pass the already-read index content to the Task() call, or may attempt to re-read it.

**Fix:** Add an explicit assignment in Step 2:

```
Read `wiki/index.md` using the Read tool. Store the result as `{wiki_index}`.
```

---

_Reviewed: 2026-04-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
