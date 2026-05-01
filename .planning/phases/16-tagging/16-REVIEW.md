---
phase: 16-tagging
reviewed: 2026-05-01T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - .claude/skills/sara-lint/SKILL.md
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-05-01
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

The review covers `.claude/skills/sara-lint/SKILL.md` in its entirety, with focus on the newly added Step 6 (D-08 whole-wiki tag curation). The file is a skill prompt — prose instructions for an LLM agent — so "bugs" are logic errors in the described algorithm that would produce incorrect agent behaviour.

The overall structure of Step 6 is sound: the empty-wiki guard, two-phase vocabulary derivation and assignment, AskUserQuestion vocabulary gate, and atomic commit all follow established sara-lint patterns. Three logic issues need attention before the step runs in production:

1. The `{written_files}` empty-check guard has incorrect semantics — it will almost never trigger in the case it is described to cover (all-zero-tag assignment), because the write loop iterates unconditionally over all files in `{assignment_map}`, and `{assignment_map}` records every artifact page regardless of whether it received zero or more tags.
2. The notes section contains a rule ("one commit per accepted fix") that directly contradicts D-08's intentional single-atomic-commit design. An agent reading the notes section could misapply this rule to D-08.
3. The "Edit" branch in the vocabulary approval gate does not specify which tool to use to collect the user's edited input, leaving the agent to improvise.

All three are warnings — no critical issues found. Four informational items are also recorded.

## Warnings

### WR-01: `{written_files}` empty-check guard has incorrect semantics

**File:** `.claude/skills/sara-lint/SKILL.md:443-479`

**Issue:** The assignment pass (line 443) records every artifact page in `{assignment_map}`, including pages that receive zero tags (recorded as an empty list). The write loop condition on line 465 says "for each file in `{artifact_pages}` that has an entry in `{assignment_map}`" — but because every page has an entry (including zero-tag pages), every page is iterated, every page is written (even if writing `tags: []` unchanged), and every page path is appended to `{written_files}`. The consequence: the guard at line 479 ("if `{written_files}` is empty") will never be true as long as any artifact pages exist, because all pages are written regardless of tag count. The guard and its output message ("D-08: No tags assigned — nothing to commit.") are therefore unreachable in normal operation. The intent — avoid committing when there are no meaningful changes — is not achieved. Additionally, writing `tags: []` to a file that already contained `tags: []` produces a spurious write and a commit that changes nothing on disk (or produces an identical file), which is noisy.

**Fix:** Separate the "all-zero assignment" case from the "no artifact pages" case. Change the write loop to only write files where the assigned tag list is non-empty. Change the `{assignment_map}` recording or the write-loop filter accordingly:

```
# Phase 2: Assignment pass — record for every page
Record the assignment as {assignment_map}: a mapping from {file_path} to [list of assigned tags] (may be empty list).

# Write tag updates — filter to non-empty assignments only
For each file in {artifact_pages}:
  If {assignment_map}[file_path] is non-empty:
    Re-read the file immediately before writing using the Read tool.
    Replace the tags: line with: tags: [tag1, tag2, ...]
    Use the Write tool to write the full file back.
    Append {file_path} to {written_files}.
  Else:
    # Zero tags assigned — leave the file unchanged (tags: [] is already the default)
    Skip write for this file.
```

This makes the `{written_files}` empty-check meaningful (fires when all pages were assigned zero tags) and avoids committing no-op writes.

---

### WR-02: Notes section contradicts D-08's single-atomic-commit design

**File:** `.claude/skills/sara-lint/SKILL.md:507`

**Issue:** The notes section at line 507 states: "One commit per accepted fix — never batch multiple fixes into one commit." D-08 (Step 6) explicitly uses a single atomic commit for all tag writes across all artifact pages — this is an intentional design choice documented in the research and locked decisions. The note was written for D-02–D-07 per-finding behaviour and was not updated to carve out the D-08 exception. An executing agent that reads the notes section holistically before running Step 6 could incorrectly apply the one-commit-per-fix rule to D-08 — either refusing to proceed with the batch commit, or introducing per-page commits that violate the full-replacement semantics.

**Fix:** Append a D-08 exception to the note:

```
- One commit per accepted fix — never batch multiple fixes into one commit
  (exception: D-08 tag curation uses one atomic commit for all tag writes — this is
  intentional; do not apply the per-fix rule to Step 6)
```

---

### WR-03: "Edit" branch does not specify the tool for collecting user input

**File:** `.claude/skills/sara-lint/SKILL.md:429`

**Issue:** The "Edit" branch (line 429) instructs the agent to "Ask the user to provide the modified vocabulary as a comma-separated list" but specifies no tool for doing so. The prior AskUserQuestion call (vocabulary approval gate) offers only `["Approve", "Edit", "Skip"]` as options — there is no free-text input option. When the user selects "Edit", the agent must make a second call to collect the modified list, but the instruction does not say to use `AskUserQuestion` again, to use a specific tool, or how to structure the prompt. An agent will need to improvise, producing inconsistent behaviour across runs (some agents may use AskUserQuestion with a text-field prompt, others may emit prose and wait for a response, others may omit the confirmation step entirely).

**Fix:** Specify the tool explicitly in the Edit branch:

```
**If "Edit":** Present using AskUserQuestion:
  - header: "D-08: Edit tag vocabulary"
  - question: "Enter your modified vocabulary as a comma-separated list
    (e.g. authentication, data-governance, infrastructure):"
  - options: []   (free-text response — no fixed options)
Re-normalise all entries to lowercase kebab-case (same normalisation rule above).
Then present using AskUserQuestion:
  - header: "D-08: Confirm edited vocabulary"
  - question: "Normalised vocabulary:\n\n  {tag1}, {tag2}, ...\n\nProceed with this vocabulary?"
  - options: ["Confirm", "Cancel"]
If "Cancel": output "Tag curation skipped." STOP Step 6.
If "Confirm": store as {approved_vocabulary} and proceed to Phase 2.
```

---

## Info

### IN-01: Hard-coded date in D-04 fix handler will become stale

**File:** `.claude/skills/sara-lint/SKILL.md:264`

**Issue:** The D-04 orphaned-page fix handler (line 264) specifies `Last-updated: today's date (2026-04-30)`. The date `2026-04-30` is hard-coded and was correct at the time of writing, but will be wrong on every subsequent run. An agent following the instruction literally would write `2026-04-30` to any index row added after that date.

**Fix:** Replace the hard-coded date with an instruction to substitute the actual current date:

```
- Last-updated: today's date in YYYY-MM-DD format (use the current date at time of execution,
  not a fixed value)
```

---

### IN-02: "per D-06" annotation in Step 6 collides with the D-06 check name

**File:** `.claude/skills/sara-lint/SKILL.md:414`

**Issue:** Line 414 reads "Full replacement semantics (per D-06)". In this document's own nomenclature, D-06 is the Cross Links check (lines 140–172). The "D-06" referenced at line 414 is the phase 16 internal locked design decision (from CONTEXT.md), not the sara-lint check. An agent reading the skill may interpret this as a reference to the check named D-06 above, rather than an external design decision. The annotation is therefore ambiguous and potentially misleading.

**Fix:** Clarify the reference:

```
**Full replacement semantics (per phase 16 locked decision D-06):** Every D-08 run re-derives
the vocabulary from scratch and replaces all existing tags. Do not merge with or preserve
previous tag assignments.
```

---

### IN-03: Phase 1 context-window strategy mismatches PATTERNS.md recommendation

**File:** `.claude/skills/sara-lint/SKILL.md:406-407`

**Issue:** The PATTERNS.md (line 117) describes the recommended vocabulary derivation strategy as "read frontmatter (`id`, `title`, `summary`) plus the first substantive body section of each page" for wikis over 20 pages — richer than D-07's frontmatter-only path. The implemented instruction at lines 406-407 says only "extract only the frontmatter fields `id:`, `title:`, and `summary:`" — no mention of the first body section. This is a minor discrepancy from the design intent documented during planning. The implemented version is more conservative (less context), which is safe but may produce a less rich vocabulary for wikis in the 21–100 page range.

**Fix:** Either update Phase 1 to include the first body section (recommended for richer vocabulary), or add a comment acknowledging the conservative choice:

```
- If {artifact_pages} has more than 20 entries: read the file but extract only the frontmatter
  fields id:, title:, and summary: — use only those fields as context for vocabulary derivation.
  (Note: this is intentionally conservative; the summary field is designed as a 50-word digest
  for exactly this use case.)
```

---

### IN-04: Commit failure warning path says "stop" but the behaviour is inconsistent with the per-finding loop pattern

**File:** `.claude/skills/sara-lint/SKILL.md:493`

**Issue:** The D-08 commit failure handler (line 493) says "output the following warning and stop." The per-finding loop (Step 5) notes section (line 508) says "If a commit fails (exit code != 0): write the warning and continue; do not STOP the lint run." For D-08, the lint run is already at its final step (Step 6 is the last step), so stopping vs. continuing makes no practical difference. However, the inconsistent language ("stop" vs. "continue") adds noise when an agent cross-references the notes section. The D-07 commit failure path in Step 5 uses "continue to next finding" to be explicit; D-08 could say "STOP Step 6 (this is the final step — the lint run is complete)."

**Fix:** Clarify the intent:

```
If exit code != 0: output the following warning. STOP Step 6.
(Note: Step 6 is the final step — the lint run is complete at this point.)
```

---

_Reviewed: 2026-05-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
