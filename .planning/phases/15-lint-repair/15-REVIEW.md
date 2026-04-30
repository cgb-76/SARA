---
phase: 15-lint-repair
reviewed: 2026-05-01T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-update/SKILL.md
  - .claude/skills/sara-lint/SKILL.md
findings:
  critical: 0
  warning: 6
  info: 3
  total: 9
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-05-01
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

These are LLM-agent skill files: markdown prose instructions that an agent executes step-by-step. "Bugs" in this domain are ambiguous or contradictory instructions, missing guard clauses, flawed grep patterns, and logic flows that could trap an agent in an infinite loop or produce incorrect state. Performance and style issues are out of scope; correctness, logical consistency, and edge-case handling are the primary concerns.

Phase 15 changes are: (1) sara-extract — temp_id and full-mesh related[] blocks removed cleanly; (2) sara-update — Temp ID resolution block removed, sara-lint auto-invocation added after success path; (3) sara-lint — D-06 extended to two-pass logic, new D-07 semantic related[] curation check added.

The revert changes in sara-extract and sara-update look correct. The most substantive issues are in the new sara-lint D-07 flow: the AskUserQuestion timing is structurally ambiguous (LLM inference happens after the user already approved the fix), the proposed_fix shown to the user may not yet contain the actual inferred IDs, and the D-07 loop has no bound against infinite re-curation of the same file on repeated lint runs for a subset of edge cases. Several grep patterns and prose cross-references also carry minor accuracy issues.

---

## Warnings

### WR-01: D-07 LLM inference executes after the user approves, not before

**File:** `.claude/skills/sara-lint/SKILL.md:256-279`
**Issue:** The D-07 "Apply" handler is described in the wrong order. Step 3 (Check D-07) collects findings and adds them to `{all_findings}` with a generic proposed_fix description. Step 5 then presents each finding using AskUserQuestion — but the AskUserQuestion call fires immediately when "Apply" is selected. The LLM inference (reading all other artifact pages, reasoning about relationships, building the proposed `related:` list) is described in the Step 5 D-07 branch *after* the AskUserQuestion has already been answered. The agent cannot show the user the specific proposed IDs ("Proposed: related: [ACT-003, RSK-001]") until it has done the inference, but the inference is supposed to happen on "Apply" — i.e., after the user already said yes.

Two sub-issues:
1. The Step 3 proposed_fix text is generic ("LLM reads this page...") — it cannot include specific IDs because inference has not happened yet. Step 5 D-07 bullet 4 says "The proposed_fix shown in the AskUserQuestion must include the specific IDs proposed" — but this contradicts the flow because the AskUserQuestion is the *approval gate*, not a post-approval display.
2. If the proposed_fix does not yet contain the real IDs, the user approves a fix without seeing what will actually be written. That is an authorization gap.

**Fix:** Move the LLM inference (steps 1–4 of D-07) to *before* the AskUserQuestion presentation. The Step 5 loop should: (a) detect a D-07 finding, (b) run inference immediately to produce the concrete proposed list, (c) update the finding's proposed_fix string with the actual IDs, (d) then call AskUserQuestion. Only on "Apply" should it write and commit. Revise the prose ordering to reflect this:

```
For each D-07 finding in {all_findings}:
  1. Re-read the target file using the Read tool.
  2. Collect all other wiki artifact pages for context (find + Read loop).
  3. LLM inference: reason about semantic relationships; produce proposed_related list.
  4. Update finding.proposed_fix to include specific IDs:
       "Proposed: related: [ACT-003, RSK-001]" or "Proposed: related: [] (no relationships found)"
  5. Present to user via AskUserQuestion (now the proposed_fix contains real IDs).
  6. On "Apply": write related: field + Cross Links; commit.
```

---

### WR-02: D-07 has no protection against infinite re-curation loop

**File:** `.claude/skills/sara-lint/SKILL.md:168-188`
**Issue:** D-07 flags pages where `related:` is *absent*. After a successful D-07 fix, the page gains `related: []` or `related: [IDs]`. On the next lint run, these pages are correctly excluded (the grep uses `-rL "^related:"`, which skips files that *have* the field). However, there is a failure mode: if the Write tool call in the D-07 Apply branch fails silently (Write succeeds at the tool level but the file reverts, is corrupted, or the commit fails and the file is then reverted manually), the `related:` field may disappear again, causing the same file to surface in every subsequent lint run. No guidance is given to the agent on what to do if a D-07 fix was previously committed but the field is now absent again — the agent will re-infer and re-propose with no warning to the user that this file was already curated. This is not catastrophic but could produce confusing repeated prompts with different inferred results.

More concretely: the commit-failure path (exit code != 0) says "write the warning and continue" but does NOT revert the Write. After commit failure, the file on disk has `related:` written but is unstaged. On re-run of lint, the grep `-rL "^related:"` would NOT flag it (the field is present on disk). This path is actually safe. But if the user manually runs `git restore` to undo the uncommitted write, the field disappears and the cycle repeats.

**Fix:** Add a note to the D-07 commit-failure path that the written file (with `related:` field present) should be staged and committed manually before any `git restore`. This prevents re-flagging. Example note:

```
If exit code != 0: output "Fix written but commit failed — the file has been updated
on disk (related: field is present). Stage and commit it manually with:
  git add {exact_file_path}
  git commit -m 'fix(wiki): curate related[] on {ID} via sara-lint D-07'
Do NOT run git restore — that would remove the related: field and trigger re-flagging."
```

---

### WR-03: D-06 Pass 2 grep will match files inside frontmatter if `related: []` appears in body prose

**File:** `.claude/skills/sara-lint/SKILL.md:154-161`
**Issue:** The Pass 2 grep is:
```bash
grep -rn "^related: \[\]" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep "\.md:" | grep -v "\.gitkeep"
```
The `^related: \[\]` pattern anchors on the start of a line, which correctly matches frontmatter. However, if an agent writes a body section that literally contains the text `related: []` at the start of a line (e.g., in a note or a quoted code block), this grep would produce a false positive. In practice this is unlikely, but the D-03 grep for broken related[] IDs has the same structure and is explicitly noted in the notes section. D-06 Pass 2 has no equivalent caveat.

The analogous issue also exists in Pass 1's grep, which uses `grep -rn "^related:"` — same potential for false positives in body prose.

**Fix:** Add a note to the D-06 block (consistent with the existing D-03 note) clarifying that the grep targets frontmatter-only because wiki pages follow the convention that `related:` appears only in the YAML frontmatter block. The Read-then-verify step (reading the file and checking the frontmatter) already provides a practical guard, but the caveat should be explicit:

```
Note: The ^related: grep is a frontmatter scan. If the file Read confirms the match is
in body prose rather than frontmatter, skip the finding.
```

---

### WR-04: sara-update auto-invocation of `/sara-lint` has no guard against lint failure propagating as update failure

**File:** `.claude/skills/sara-update/SKILL.md:588-598`
**Issue:** The new final step in sara-update invokes `/sara-lint` with no arguments after the "Update Complete" block. The instruction reads "Do not prompt the user — lint runs automatically." No guidance is given on what happens if `/sara-lint` fails (e.g., the wiki directory is corrupt, or a prior git state prevents lint from running). The user would see the sara-update "complete" message followed by a lint error, with no clarity on whether the update itself succeeded.

More importantly, if the agent treats lint failure as a reason to re-run or escalate, it could undo the stage=complete write or otherwise damage state — but nothing in the prose prevents this because the error handling for lint is not mentioned.

**Fix:** Add an explicit statement that lint failure does not affect the update result:

```
If /sara-lint exits with an error or the wiki guard (Step 1) fires: output the lint error
message and STOP. The sara-update is already complete — the wiki commit and stage=complete
write are final. The user can re-run /sara-lint independently to address any lint issues.
Do NOT re-run sara-update or reverse any state changes.
```

---

### WR-05: D-07 large-wiki context strategy is ambiguous — "extract only frontmatter fields" has no Read tool mechanism

**File:** `.claude/skills/sara-lint/SKILL.md:263-267`
**Issue:** For wikis with more than 20 artifact pages, the instruction says:
> "Read the file using the Read tool but extract only the frontmatter fields `id`, `title`, and `summary` — use only those fields as context"

The Read tool reads the full file; there is no partial-read capability for frontmatter only. The instruction appears to be telling the agent to read the full file but only *attend to* those three fields when reasoning. This is a context-window mitigation strategy, not a tool capability. The prose implies a technical filtering that doesn't exist, which may cause a well-literal agent to attempt and fail to partially read a file.

**Fix:** Rephrase to make clear this is an *attention* constraint on the LLM, not a tool behavior:

```
If the wiki has more than 20 artifact pages total: Read each file using the Read tool
(full content), but when reasoning about relationships, use only the id, title, and
summary frontmatter fields as context — do not consider body section content for non-target
pages. This limits reasoning scope to stay within the effective context window for large wikis.
```

---

### WR-06: Step 5 D-06 fix handler does not differentiate Pass 1 vs Pass 2 by finding structure — ambiguous dispatch

**File:** `.claude/skills/sara-lint/SKILL.md:249-253`
**Issue:** The Step 5 Apply handler for D-06 has two named sub-cases:
- "D-06 — Cross Links mismatch (Pass 1 — non-empty related[])"
- "D-06 — Absent Cross Links header (Pass 2 — empty related[])"

But the `{all_findings}` list entries only carry `check_id: D-06`. No sub-case discriminator is stored in the finding object. When the agent processes a D-06 finding in Step 5, it must determine which branch to take, but the finding structure defined in Step 3 does not include a field to distinguish Pass 1 from Pass 2 findings. The agent must re-derive this from the issue description string, which is fragile.

**Fix:** Either (a) use a distinct check_id for Pass 2 findings (e.g., `D-06b`) so the dispatch is unambiguous, or (b) require the finding object to carry a `pass` field:

```
Each D-06 finding includes: check_id, file, pass (1 or 2), issue, proposed_fix
```

Then the Step 5 handler dispatches on `finding.pass` rather than parsing the issue string.

---

## Info

### IN-01: sara-update Step 4 output block mentions `{item.id}` which duplicates `{N}`

**File:** `.claude/skills/sara-update/SKILL.md:582-586`
**Issue:** The "Update Complete" output template reads `"Item {N} ({item.id}) is now complete."` — since `item.id` == `N` (both are the full pipeline item ID string, e.g. `MTG-001`), this is redundant. It reads as "Item MTG-001 (MTG-001) is now complete." Minor UX confusion.
**Fix:** Use one or the other: `"Item {N} is now complete."` or `"Item {item.id} is now complete."` — not both.

---

### IN-02: sara-lint Step 4 completion message says "all 6 checks" but the clean-exit output line says "/sara-lint complete — no issues found across all 6 checks." while the non-clean path says "{M} check(s)" — count inconsistency if M < 6

**File:** `.claude/skills/sara-lint/SKILL.md:193-205`
**Issue:** The clean exit message hardcodes "all 6 checks". The non-empty findings message uses `{M} check(s)` — a dynamic count of how many checks produced findings. These are intentionally different (one is the total, one is the affected count), but since both appear together in a lint session, a user could read "no issues found across all 6 checks" on one run and "2 issues across 1 check" on another and not know the total is always 6. Not a bug, but slightly inconsistent framing.
**Fix:** Consider standardising the non-empty message: `"/sara-lint found {N} issue(s) across {M} of 6 checks."` to anchor the total.

---

### IN-03: sara-extract notes section references a sorter concern ("Sorter questions presented before the approval loop") that is mislabelled as "Pitfall 4 guard" in two different locations for different pitfalls

**File:** `.claude/skills/sara-extract/SKILL.md:46, 432`
**Issue:** Line 46 uses "(See notes — Pitfall 4 guard.)" in reference to the fresh wiki/index.md read timing. Line 432 in the notes uses "Pitfall 4 guard" in reference to not presenting sorter questions inside the artifact loop. Both references label different behaviours as "Pitfall 4". If a developer searches for Pitfall 4 to understand its meaning, they get two contradictory answers.
**Fix:** Assign distinct pitfall numbers to distinct pitfalls. Renumber one of the two so they are unambiguous, and update the corresponding in-line reference.

---

_Reviewed: 2026-05-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
