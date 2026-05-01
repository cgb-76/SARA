---
phase: 17-document-based-statefulness
reviewed: 2026-05-01T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .claude/skills/sara-discuss/SKILL.md
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-ingest/SKILL.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-minutes/SKILL.md
  - .claude/skills/sara-update/SKILL.md
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-05-01T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Six SARA pipeline skill files were reviewed for correctness of the Phase 17 document-based
state backend. The migration from `pipeline-state.json` to per-item `.sara/pipeline/{ID}/`
directories is structurally sound: stage guards read `state.md` before any writes, the
commit-ordering invariant (content before stage advance) is correctly enforced in all four
pipeline skills, `discuss.md` absent-file fallback is documented and handled, and no
stray `pipeline-state.json` references remain (only the correct "Do NOT create" note in
`sara-init`).

Two critical issues were found: one logic bug in the `sara-ingest` ID-counter derivation
that will produce wrong IDs when a `{type_key}` prefix appears as a substring of another
type's entries, and one commit-ordering gap in `sara-update`'s empty-plan fast-path that
advances the stage before a commit rather than after. Four warnings cover incomplete
path-traversal protection, a silent failure mode in `sara-update`'s empty-plan branch, a
missing `echo "EXIT:$?"` capture in `sara-discuss`'s stage-advance commit, and an
inconsistency in `sara-ingest`'s STATUS-mode output ordering. Three info items flag minor
dead-code and style issues.

---

## Critical Issues

### CR-01: ID counter derivation silently matches wrong type's directories

**File:** `.claude/skills/sara-ingest/SKILL.md:88`

**Issue:** The counter derivation script uses:
```bash
ls .sara/pipeline/ 2>/dev/null | grep "^{type_key}-" | sort | tail -1
```
This pattern is correct for the directory names that `sara-ingest` itself creates (e.g.
`MTG-001`, `EML-001`). However, `{type_key}` is a literal shell variable expansion that
is substituted by the LLM before the bash command runs. If the LLM ever expands
`{type_key}` to `SLK` but a directory named `SLK-meeting-001` (or any manually created
directory whose name begins with `SLK-`) exists, the grep will include it. More
concretely, the pattern `grep "^MTG-"` will also match a hypothetical `MTG-DRAFT` or
any hand-created directory. This is a latent but real risk: the grep anchor `^{type_key}-`
does not restrict the suffix to digits, so a non-numeric last entry makes the subsequent
`$((10#$NUM + 1))` arithmetic fail with a bash error, producing an empty `{new_id}` and
causing `mkdir` and `Write` to run against a blank path.

A more robust pattern would anchor on the full three-digit numeric suffix:
```bash
LAST=$(ls .sara/pipeline/ 2>/dev/null | grep -E "^{type_key}-[0-9]{3}$" | sort | tail -1)
```
This ensures only legitimately formatted pipeline directories are counted and that a
non-conforming directory name cannot corrupt the counter.

**Fix:**
```bash
LAST=$(ls .sara/pipeline/ 2>/dev/null | grep -E "^{type_key}-[0-9]{3}$" | sort | tail -1)
if [ -z "$LAST" ]; then
  NEXT="{type_key}-001"
else
  NUM=$(echo "$LAST" | sed 's/{type_key}-//')
  NEXT="{type_key}-$(printf '%03d' $((10#$NUM + 1)))"
fi
echo "$NEXT"
```

The same fix applies to the entity ID counter in `sara-update` (line 107) and the
`CLAUDE.md` behavioral rule 4 (which also prescribes a `grep "^{TYPE_KEY}-"` pattern):
all three should use the anchored `-E "^{TYPE_KEY}-[0-9]{3}$"` form (adjusted to strip
`.md` for the wiki directory globs).

---

### CR-02: sara-update empty-plan fast-path advances stage without a prior commit

**File:** `.claude/skills/sara-update/SKILL.md:48-68`

**Issue:** When `plan.md` cannot be read or is empty, the fast-path in Step 1 writes
`stage: complete` to `state.md` and then issues a single commit:
```bash
git add ".sara/pipeline/{N}/state.md"
git commit -m "feat(sara): wiki {N} — 0 artifacts (empty plan)"
echo "EXIT:$?"
```
This violates the commit-ordering invariant stated in the `<notes>` section of the same
skill ("Stage advances to 'complete' ONLY after the git commit succeeds"). In the happy
path (Step 4) the skill correctly writes the wiki files, commits them, then writes
`state.md` and commits that separately. In the fast-path, `state.md` is written
unconditionally before the commit. If that single commit fails (network issue, hook
failure, lock file, etc.), the item is permanently stuck at `stage: complete` with no
corresponding wiki commit — the same "Pitfall 1" the notes explicitly warn against.

**Fix:** Mirror the Step 4 ordering in the fast-path:
```
1. Write state.md with stage: complete (as currently written — this is correct).
2. Run git add + commit, capturing echo "EXIT:$?".
3. If commit FAILS (exit code != 0):
     Output error message.
     Do NOT output "Item {N} stage advanced to complete."
     STOP.
4. If commit SUCCEEDS: output the success message. STOP.
```
The write of `state.md` before the commit is acceptable here because there are no wiki
files to atomically group — the key invariant is that the success message is suppressed
if the commit fails, so the user knows to retry rather than believing the item is done.

---

## Warnings

### WR-01: Path-traversal check does not cover null bytes or encoded separators

**File:** `.claude/skills/sara-ingest/SKILL.md:51-55`

**Issue:** The filename validation guards against `/` and `..`:
```
Validate {filename}: must not contain / or .. (path traversal guard).
```
This is necessary but not sufficient. An LLM executing the skill may receive a filename
argument that was URL-encoded (e.g. `%2F` for `/`) or that contains a null byte (`\0`),
which some shell commands treat as a path terminator. More practically, on a case-folding
filesystem a filename like `../etc/passwd` with Unicode look-alike characters could slip
through. The validation description should also explicitly reject filenames that contain
`\0`, are empty after stripping whitespace, or are purely `.` (which would cause
`raw/input/.` to resolve to the directory itself).

**Fix:** Extend the guard condition description to:
```
Validate {filename}: must not be empty, must not contain /, \, .., \0, or begin
with a dot. If invalid: output the error and STOP.
```
And ensure the companion bash check in Step 2 (`if [ ! -f "raw/input/{filename}" ]`)
always runs even if the LLM validation passes, as the filesystem check acts as a
defense-in-depth guard.

---

### WR-02: sara-discuss stage-advance commit missing exit-code capture

**File:** `.claude/skills/sara-discuss/SKILL.md:181-185`

**Issue:** The second git commit (stage advance to `extracting`) does not capture its
exit code:
```bash
git add ".sara/pipeline/{N}/state.md"
git commit -m "feat(sara): stage {N} → extracting"
```
There is no `echo "EXIT:$?"` and no check on the result. By contrast, the first commit
(for `discuss.md`) correctly captures the exit code and STOPs on failure. If the
stage-advance commit fails silently, the item remains in `state.md: stage: extracting`
on disk (because the Write tool already ran) but the git history does not record the
advance. The next pipeline step (`/sara-extract`) will read the on-disk `state.md` and
proceed, but the stage change is unversioned — a `git reset` or `git checkout` would
revert it unexpectedly.

**Fix:**
```bash
git add ".sara/pipeline/{N}/state.md"
git commit -m "feat(sara): stage {N} → extracting"
echo "EXIT:$?"
```
Add a check block:
```
If commit FAILS (exit code != 0):
  Output: "Stage-advance commit failed for {N}. state.md on disk shows stage: extracting
  but the commit did not succeed. Run: git add .sara/pipeline/{N}/state.md &&
  git commit -m 'feat(sara): stage {N} → extracting' to retry."
  STOP.
```
The same pattern is missing from `sara-extract`'s stage-advance commit (line 468-469)
— it also lacks `echo "EXIT:$?"` and a failure check for the second commit. Apply the
same fix there.

---

### WR-03: sara-update empty-plan branch produces misleading success output on commit failure

**File:** `.claude/skills/sara-update/SKILL.md:64-67`

**Issue:** Related to CR-02, but distinct: even if the commit-ordering fix from CR-02 is
applied, the current text says "Output: `Item {N} stage advanced to complete.`" with no
conditional. The skill must make this output conditional on commit success. As written a
reader following the instructions would output the success line regardless of whether the
commit succeeded.

**Fix:** Make the output explicitly conditional:
```
If commit SUCCEEDS (exit code 0):
  Output: "Item {N} stage advanced to complete. No artifacts were written."
  STOP.
If commit FAILS (exit code != 0):
  Output: "Commit failed for {N}. state.md has been written with stage: complete
  but the commit did not succeed. Run: git add .sara/pipeline/{N}/state.md &&
  git commit -m 'feat(sara): wiki {N} — 0 artifacts (empty plan)' to retry."
  STOP.
```

---

### WR-04: sara-ingest STATUS mode grep may return fields out of frontmatter order

**File:** `.claude/skills/sara-ingest/SKILL.md:181-196`

**Issue:** The STATUS mode uses:
```bash
grep -rh "^\(id\|type\|stage\|source_path\):" .sara/pipeline/*/state.md 2>/dev/null
```
`grep -rh` does not guarantee that lines are returned in their original file order; it
processes files in filesystem order (which is non-deterministic on ext4/btrfs). Within a
single file the lines appear in source order, but across files the ordering is not
guaranteed. The parsing instruction says "group lines by file (they appear sequentially)"
— this is only reliable when `grep` operates on one file at a time. When invoked with a
glob across many files, the multi-file output may interleave lines from different
state.md files without file-boundary markers.

The correct tool for this pattern is:
```bash
grep -rh --include="state.md" "^\(id\|type\|stage\|source_path\):" \
  .sara/pipeline/*/state.md 2>/dev/null
```
…but even with `--include` the interleaving risk remains. A safer alternative is to add
`-l` first to get filenames, then loop — or use `grep -H` (print filename prefix) and
parse the filename as the grouping key.

**Fix:** Replace the STATUS mode grep with a filename-anchored form:
```bash
grep -H "^\(id\|type\|stage\|source_path\):" .sara/pipeline/*/state.md 2>/dev/null
```
Then parse by grouping on the filename prefix (the part before the first `:`), which
`grep -H` provides on every line. This makes grouping deterministic regardless of
filesystem ordering.

---

## Info

### IN-01: sara-init Step 7 is a no-op and creates reader confusion

**File:** `.claude/skills/sara-init/SKILL.md:129-136`

**Issue:** Step 7 says "The `.sara/pipeline/` directory is already created in Step 5.
No additional action is required in this step." This is accurate but the step exists only
to hold the "Do NOT create `.sara/pipeline-state.json`" note. Having a numbered step
that does nothing can confuse an agent following the steps sequentially — it may pause
expecting to take action. The note is valuable but should be folded into Step 5 (where
the directory is actually created) or into the `<notes>` section, and Step 7 removed to
renumber cleanly.

**Fix:** Move the "Do NOT create `.sara/pipeline-state.json`" warning into Step 5 as a
bulleted note immediately after the `mkdir -p` block, then delete Step 7 and renumber
Steps 8-14 accordingly.

---

### IN-02: sara-minutes references "vertical" field that does not exist in STK schema

**File:** `.claude/skills/sara-minutes/SKILL.md:152`

**Issue:** The notes section contains:
```
`vertical` and `department` are always separate fields in STK pages — never merged.
```
The SARA stakeholder schema (as defined in `sara-init` SKILL.md and CLAUDE.md) uses
`segment` and `department` as the two separate fields. The field `vertical` does not
appear in any template or schema definition. This is a stale copy-paste from an earlier
version where `segment` was called `vertical`. The note is misleading — an agent reading
it might create a `vertical` field on STK pages.

**Fix:** Replace `vertical` with `segment`:
```
`segment` and `department` are always separate fields in STK pages — never merged.
```

---

### IN-03: sara-extract Step 4 warning threshold outputs wrong pronoun

**File:** `.claude/skills/sara-extract/SKILL.md:379`

**Issue:** The five-cycle warning message reads:
```
"This artifact has been discussed {N} times. Please select Accept or Reject to proceed,
or Reject to skip it."
```
The phrase "Please select Accept or Reject to proceed, or Reject to skip it" is redundant
— "select Reject to proceed" and "Reject to skip it" are the same instruction repeated.
The intended meaning is "Accept to keep it or Reject to skip it."

**Fix:**
```
"This artifact has been discussed {N} times. Please select Accept to keep it or Reject
to skip it."
```

---

_Reviewed: 2026-05-01T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
