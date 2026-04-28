---
phase: 06-refine-entity-extraction
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .claude/agents/sara-action-extractor.md
  - .claude/agents/sara-artifact-sorter.md
  - .claude/agents/sara-decision-extractor.md
  - .claude/agents/sara-requirement-extractor.md
  - .claude/agents/sara-risk-extractor.md
  - .claude/skills/sara-discuss/SKILL.md
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-lint/SKILL.md
  - .claude/skills/sara-update/SKILL.md
  - install.sh
findings:
  critical: 0
  warning: 7
  info: 5
  total: 12
status: issues_found
---

# Phase 06: Code Review Report

**Reviewed:** 2026-04-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed five specialist extraction agents, the artifact sorter, four skill definitions (sara-discuss, sara-extract, sara-lint, sara-update, sara-init), and the install.sh script. No critical security vulnerabilities were found. The shell script is generally well-written but has one silent-failure edge case and one missing version-parity guard for agents. Workflow logic issues are concentrated in two areas: (1) a missing guard clause in sara-extract for the case where the sorter returns malformed or non-JSON output, and (2) a contradiction in sara-lint's notes about where the `summary` field is inserted. Several agent schema inconsistencies and a partial-failure atomicity gap in sara-update are also flagged.

---

## Warnings

### WR-01: Agent loop in install.sh has no downgrade protection for agent files

**File:** `install.sh:130-147`
**Issue:** The skills loop (lines 77–116) implements downgrade protection — it reads the installed version and skips if the source is older. The agents loop (lines 130–147) has no equivalent check. An older version of an agent file will silently overwrite a newer locally installed one when `--force` is not set. This is inconsistent with the stated design intent (D-09 referenced on line 94) and could regress agent behaviour after a `curl | bash` reinstall.
**Fix:** Mirror the downgrade check from the skills loop into the agents loop. Before `mv "${tmp_file}" "${dest_file}"` (line 143), add:

```bash
if [[ -f "$dest_file" ]] && [[ "$FORCE" != "true" ]]; then
  inst_ver="$(grep "^version:" "${dest_file}" 2>/dev/null | awk '{print $2}' || true)"
  [[ -z "$inst_ver" ]] && inst_ver="0.0.0"
  src_ver_agent="$(grep "^version:" "${tmp_file}" 2>/dev/null | awk '{print $2}' || true)"
  [[ -z "$src_ver_agent" ]] && src_ver_agent="0.0.0"
  older="$(printf '%s\n%s\n' "${src_ver_agent}" "${inst_ver}" | sort -V | head -1)"
  if [[ "$older" = "$src_ver_agent" ]] && [[ "$src_ver_agent" != "$inst_ver" ]]; then
    echo "Warning: source version (${src_ver_agent}) is older than installed (${inst_ver}) for ${agent_name} — skipping." >&2
    rm -f "${tmp_file}"
    continue
  fi
fi
```

Note: agent frontmatter does not currently carry a `version:` field, so all agents would treat their installed version as `0.0.0` until that field is added. The fix future-proofs the guard once versions are added.

---

### WR-02: install.sh does not clean up tmp_file on unexpected exit

**File:** `install.sh:83-84`
**Issue:** `set -euo pipefail` is active (line 2). If any command after `tmp_file="$(mktemp)"` fails unexpectedly (e.g., `mkdir -p` on line 112), the script exits immediately via `set -e` without reaching the `rm -f "${tmp_file}"` cleanup on line 87. The temp file leaks. This occurs in both the skills loop and the agents loop.
**Fix:** Add a `trap` to clean up the most-recently-created temp file on exit, or use a single fixed temp path per loop iteration that a `trap` can reliably remove:

```bash
trap 'rm -f "${tmp_file:-}"' EXIT
```

Place this once at the top of the script, after the variable declarations. Because `tmp_file` is reassigned each iteration, the trap will always clean up the last created temp on unexpected exit.

---

### WR-03: sara-extract has no guard for non-JSON sorter output

**File:** `.claude/skills/sara-extract/SKILL.md:84-86`
**Issue:** Step 3 says "Parse `{sorter_output}`" and immediately destructures `.cleaned_artifacts` and `.questions` — but provides no instruction for what to do if the sorter returns malformed JSON, an error message, or an empty string (e.g., agent context-window overflow). If the parse silently fails, `{cleaned_artifacts}` will be undefined or null, and the subsequent question loop and approval loop in Step 4 will operate on garbage data or crash.
**Fix:** Add an explicit guard after the sorter Task() returns:

```
If {sorter_output} cannot be parsed as a valid JSON object, or if cleaned_artifacts is absent:
  Output: "Sorter agent returned invalid output. Raw response: {sorter_output}"
  Output: "Re-run /sara-extract {N} to retry. If the error persists, reduce the source document size."
  STOP.
```

---

### WR-04: sara-extract sorter question resolution applies updates to cleaned_artifacts before validation

**File:** `.claude/skills/sara-extract/SKILL.md:89-96`
**Issue:** Step 3 instructs: "Apply the user's resolution to `{cleaned_artifacts}` before moving to the next question." There is no instruction on _how_ to apply a "C) Neither — skip" answer versus an "A) Update" answer, or what to do when the user's answer does not match options A, B, or C. An unexpected reply (e.g., freeform text or "D") has no defined handling, meaning the resolution may be skipped silently or applied incorrectly.
**Fix:** Add explicit resolution logic after the wait:

```
If user replies "A": apply resolution A (keep as type1; remove the type2 duplicate from cleaned_artifacts).
If user replies "B": apply resolution B (keep as type2; remove the type1 duplicate).
If user replies "C": remove both from cleaned_artifacts (skip the passage).
If user replies anything else: re-present the question with: "Please reply A, B, or C." Do not advance.
```

---

### WR-05: sara-lint notes contradict the process for summary field insertion position

**File:** `.claude/skills/sara-lint/SKILL.md:102` vs `line:163`
**Issue:** The process section (line 102) says: "Insert `summary:` into the frontmatter of the file, immediately after the `status:` field (for REQ, DEC, ACT, RSK) or after the `role:` field (for STK)." The notes section (line 163) contradicts this: "The `summary` field is inserted after `related:` in frontmatter — consistent position across all entity types." These two rules cannot both be true: `related:` appears at the end of the frontmatter while `status:` appears near the top. The implementing LLM will receive contradictory instructions and the insertion position will be non-deterministic.
**Fix:** Decide on one canonical position and remove the other. The schema templates in sara-init place `summary:` immediately after `status:` (consistent with the process section). Recommend removing the contradictory notes line and replacing it with: "The `summary` field is inserted immediately after the `status:` field (REQ, DEC, ACT, RSK) or the `role:` field (STK), consistent with the entity schema templates in `.sara/templates/`."

---

### WR-06: sara-update Step 2 "update" branch does not guard against missing existing_id file

**File:** `.claude/skills/sara-update/SKILL.md:222-227`
**Issue:** The update branch reads `{wiki_dir}{artifact.existing_id}.md` but provides no handling if the file does not exist (e.g., the wiki page was manually deleted after extraction). If the Read tool returns an error, the skill's behaviour is undefined — it may attempt to apply `change_summary` to empty content and write garbage, or silently continue and produce a corrupted wiki page.
**Fix:** Add a guard after the Read:

```
If the Read tool returns an error or empty content for {wiki_dir}{artifact.existing_id}.md:
  Output: "Cannot update {artifact.existing_id}: file not found at {wiki_dir}{artifact.existing_id}.md"
  Append the file path to failed_files.
  Output the partial failure report and STOP.
```

---

### WR-07: sara-artifact-sorter has no handling for an empty merged_artifacts input

**File:** `.claude/agents/sara-artifact-sorter.md:28`
**Issue:** The process starts with "Parse `<merged_artifacts>` as a JSON array" but has no guard for the case where the merged array is empty (all four specialists returned `[]`). The downstream `cleaned_artifacts` would correctly be `[]` and `questions` would be `[]`, which is valid — but Steps 3 (create-vs-update) and 4 (cross-reference detection) would still iterate over nothing with no explicit early-exit. More importantly, sara-extract's Step 3 notes say "When a specialist returns [], skip silently" but does not define what happens when ALL four specialists return `[]`. The approval loop in Step 4 would then iterate over zero artifacts and immediately proceed to Step 5, writing an empty `extraction_plan`. This is likely the correct behaviour, but neither skill nor agent says so explicitly, leaving ambiguity about whether the zero-artifact path is expected or an error.
**Fix:** Add an explicit early-exit in sara-artifact-sorter:

```
If merged_artifacts is empty ([]):
  Return: {"cleaned_artifacts": [], "questions": []}
```

And in sara-extract Step 3, after merging, add:

```
If {merged} is empty (all four specialists returned []):
  Output: "No artifacts found in source document. All specialist agents returned empty results."
  Output: "Proceeding to Step 4 with empty artifact list. You may reject this result or re-run /sara-discuss {N} to add discussion notes."
```

---

## Info

### IN-01: Specialist agents declare `tools: Read, Bash` but the process prohibits using them

**File:** `.claude/agents/sara-action-extractor.md:4`, `.claude/agents/sara-decision-extractor.md:4`, `.claude/agents/sara-requirement-extractor.md:4`, `.claude/agents/sara-risk-extractor.md:4`
**Issue:** All four specialist extractors have `tools: Read, Bash` in their frontmatter. Their process explicitly forbids using these tools: "Do NOT access the wiki, wiki/index.md, or run any grep commands." The presence of these tool grants is misleading — they imply the agent may use filesystem access, when the design intent is a pure text-in/JSON-out transform.
**Fix:** Either remove the `tools:` declaration entirely (if the agent runtime allows prompt-only operation), or restrict it to the minimum needed. If the `tools:` field is required by the Claude Code agent runner for all agent files, add a comment explaining why the tools are declared but not used:

```yaml
tools: Read, Bash
# Note: tools declared for runner compatibility only — this agent operates
# entirely on prompt input and does not access the filesystem.
```

---

### IN-02: sara-artifact-sorter grep_summaries pattern does not include the wiki/stakeholders/ subdirectory consistently

**File:** `.claude/agents/sara-artifact-sorter.md:21-24` vs `.claude/skills/sara-extract/SKILL.md:77-79`
**Issue:** The sorter's `<input>` block describes the grep as running against `wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/`. The sara-extract Step 3 Bash command matches this. This is consistent. However, the description says `grep -rh "^summary:"` — the `-h` flag suppresses filenames, meaning the sorter receives only the summary values with no file path context. If two existing entities have identical summary text, the sorter cannot disambiguate which entity a match belongs to. This is a minor quality issue: the sorter might incorrectly attribute a match to the wrong entity.
**Fix:** Consider using `grep -rn "^summary:"` (with `-n` for line numbers, keeping filenames) and passing the raw grep output with paths, so the sorter can extract the entity ID from the file path. Alternatively, document in the sorter that filename context is intentionally absent and rely solely on `wiki_index` for ID resolution.

---

### IN-03: sara-discuss Step 3 label says "Step 2" in the notes

**File:** `.claude/skills/sara-discuss/SKILL.md:140`
**Issue:** The notes section says "The `known_names` set is built at Step 2 using Bash grep" but the grep is actually in Step 2 of the process (lines 48-54) with `known_names` being used in Step 3. The cross-reference is technically correct (the set _is_ built in Step 2), but the note is placed under a block labeled "Step 2" observations, then refers to "Step 2" when a reader may expect "Step 3" as the consuming step. Minor wording confusion only.
**Fix:** Rephrase the note: "The `known_names` set is built in Step 2 using Bash grep and consumed in Step 3 for unknown-stakeholder detection."

---

### IN-04: sara-init Step 9 CLAUDE.md contains a bash snippet with `gsd-sdk` — external tool dependency not documented

**File:** `.claude/skills/sara-init/SKILL.md:314`
**Issue:** The CLAUDE.md template written by sara-init contains a `gsd-sdk query commit ...` bash command under "GSD Phase Completion". This references an external tool (`gsd-sdk`) that is not part of SARA and is not documented anywhere in the reviewed files. Users of SARA who do not have `gsd-sdk` installed will encounter a confusing error if they attempt to follow the instructions in their own CLAUDE.md.
**Fix:** Either add a comment to the CLAUDE.md template noting that `gsd-sdk` is an optional external dependency, or wrap the command in a guard:

```bash
if command -v gsd-sdk &>/dev/null; then
  gsd-sdk query commit "docs(phase-{X}): ..." ...
else
  git add .planning/STATE.md .planning/ROADMAP.md .planning/PROJECT.md
  git commit -m "docs(phase-{X}): update planning docs after phase completion"
fi
```

---

### IN-05: sara-update partial failure report tells user to use `git reset HEAD` — incorrect syntax for modern git

**File:** `.claude/skills/sara-update/SKILL.md:305`
**Issue:** The commit failure output says: `use 'git reset HEAD {written_files}' to undo the uncommitted writes if needed`. The `git reset HEAD <file>` command unstages files but does not discard working-tree changes — it would not "undo" the writes at all. The correct command to discard uncommitted working-tree changes is `git restore {written_files}` (git 2.23+) or `git checkout -- {written_files}` (older git). The current instruction could mislead a user into thinking they have reverted the changes when they have not.
**Fix:** Replace the recovery suggestion with:

```
To discard the uncommitted writes:
  git restore {written_files}   # git 2.23+
  # or: git checkout -- {written_files}   # older git
```

---

_Reviewed: 2026-04-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
