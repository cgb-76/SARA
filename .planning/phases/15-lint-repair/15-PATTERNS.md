# Phase 15: Lint Repair - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 3 (skill files to be modified)
**Analogs found:** 3 / 3 (all are self-referential — the files being modified ARE the analogs)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-extract/SKILL.md` | skill / pipeline-step | batch transform | self (current version) | exact — targeted removal |
| `.claude/skills/sara-update/SKILL.md` | skill / pipeline-step | CRUD + transform | self (current version) | exact — targeted removal + additive step |
| `.claude/skills/sara-lint/SKILL.md` | skill / scan-and-repair | event-driven (per-finding loop) | self (current version) | exact — additive check + D-06 extension |

---

## Pattern Assignments

### `.claude/skills/sara-extract/SKILL.md` (skill, batch transform)

**Change type:** Removal (D-01 and D-02)

**Analog:** Current file (self). Phase 14 added the patterns being removed. Phase 15 reverts them.

---

#### D-01 removal target — temp_id assignment in Step 3 (four inline passes)

Each of the four extraction passes (Requirements, Decisions, Actions, Risks) contains a block in this form. ALL FOUR must have the `temp_id` line block removed. The `related = []` initialization line STAYS.

**Requirements pass removal target** (lines 98–103):
```
- Set `temp_id` = result of Bash: `python3 -c "import secrets; print(secrets.token_hex(4))"`
  MANDATORY: use the Bash tool to generate this value. Do NOT generate inline — inline
  generation is not random and risks collisions. Each artifact gets a unique temp_id.
  After all four passes complete, verify all temp_ids in `{merged}` are unique. If any
  duplicates are found, regenerate the duplicate temp_id(s) with a new Bash call.
- Set `action` = `"create"`, `type` = `"requirement"`, ...
```

Remove the `temp_id` bullet block from all four passes. The pattern is identical in each. After removal, each pass's field-initialization ends at the single `action`/`type`/`id_to_assign`/`related`/`change_summary` line.

**Decisions pass removal target** (lines 163–168): same temp_id block pattern as Requirements.

**Actions pass removal target** (lines 216–221): same temp_id block pattern as Requirements.

**Risks pass removal target** (lines 276–281): same temp_id block pattern as Requirements.

**Line retained in all four passes** (must NOT be removed):
```
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`, `related` = `[]`, `change_summary` = `""`
```

---

#### D-02 removal target — full-mesh related[] linking block in Step 5

The entire "Full-mesh related[] linking" block must be removed from Step 5 (lines 408–431). Remove from the `**Full-mesh related[] linking**` subheading through the blank line before `Read \`.sara/pipeline-state.json\``.

**Block to remove** (lines 408–431):
```
**Full-mesh related[] linking**

After all artifacts are resolved to "Accept" or "Reject":

Build the full-mesh related[] for all approved artifacts:
  For each artifact `A` in `approved_artifacts`:
    # Preserve any real IDs injected by sorter cross-reference resolutions (Step 3 option A answers)
    existing_real_ids = [entry for entry in A.related if entry does NOT match /^[a-f0-9]{8}$/]
    new_temp_ids = [B.temp_id for B in approved_artifacts if B.temp_id != A.temp_id]
    Set `A.related` = deduplicate(existing_real_ids + new_temp_ids)

For a single-artifact batch: `A.related` = `[]` (the other-artifacts set is empty — no special case needed)
For a zero-artifact batch: skip this step entirely (approved_artifacts is empty)

After the full-mesh step, strip any stale temp_id values from related[] that do not
correspond to an approved artifact (e.g. a sorter-injected cross-reference to an artifact
that was subsequently rejected in Step 4):
  approved_temp_ids = set of all A.temp_id for A in approved_artifacts
  For each artifact A in approved_artifacts:
    A.related = [t for t in A.related if t is in approved_temp_ids OR t does NOT match /^[a-f0-9]{8}$/]

This replaces the `related: []` that was set during Step 3. The temp_id values are stable
cross-reference keys — they persist in extraction_plan until sara-update resolves them to
real IDs at the start of Step 2.
```

After removal, Step 5 must read:
```
**Step 5 — Write extraction plan and advance stage**

Read `.sara/pipeline-state.json` using the Read tool.
...
```

---

### `.claude/skills/sara-update/SKILL.md` (skill, CRUD + transform)

**Change type:** Removal (D-03) + Additive final step (D-10)

**Analog:** Current file (self).

---

#### D-03 removal target — temp_id→real_id resolution block in Step 2

The entire block from `**Temp ID resolution (before write loop)**` through the unresolved-temp_id warning scan (lines 65–116) must be removed. After removal, Step 2 begins directly with `Initialize \`written_files = []\` and \`failed_files = []\``.

**Block to remove** (lines 65–116 — the "Temp ID resolution" section):
```
**Temp ID resolution (before write loop)**

Build the `temp_id → real_id` map by simulating the ID assignment sequence without
incrementing the counters:

  Initialize `id_map` = {} (empty mapping)
  Initialize `preview_counters` = deep copy of `counters.entity` from the in-memory state
    (do NOT modify the real counters — these are read-only preview increments)

  IMPORTANT: Iterate `{extraction_plan}` in its declared order ...

  For each artifact in `{extraction_plan}` where `artifact.action == "create"`:
    Determine `{entity_type_key}` from `artifact.type`:
    ...
    Set `id_map[artifact.temp_id]` = `{preview_id}`
    (skip artifacts where `artifact.action == "update"` — they have no temp_id)

Do NOT write `preview_counters` to `pipeline-state.json`. ...

**Substitution pass:**

NOTE: The "skip update artifacts" instruction above applies ONLY to the id_map construction
loop ...

  For each artifact in `{extraction_plan}`:
    For each entry `t` in `artifact.related`:
      If `id_map[t]` exists: replace `t` with `id_map[t]`
      If `id_map[t]` does not exist: leave `t` unchanged ...

After the substitution pass, scan each artifact.related array for any entries that still
match the pattern /^[a-f0-9]{8}$/ ...
Then remove that entry from the artifact's related[] array.

After this scan, all `artifact.related` arrays in the in-memory `extraction_plan` contain
real entity IDs only. Proceed to "Initialize `written_files = []`" and the write loop.

Do NOT write the substituted `extraction_plan` back to `pipeline-state.json` at this
point ...
```

After removal, Step 2 structure:
```
**Step 2 — Write wiki artifact files**

Initialize `written_files = []` and `failed_files = []`.

For each artifact in `{extraction_plan}`:
...
```

---

#### D-10 additive target — sara-lint auto-invocation as final step in sara-update

After the "Update Complete" block in Step 4 (after stage advances to `complete`), append a new final action. The pattern for step transitions within sara-update uses plain-text output followed by skill invocation. The pattern for skill-to-skill invocation does not yet exist in this codebase — the planner must define the mechanism.

**Insertion point** — after this block in Step 4 (currently lines 629–642):
```
  Output:
  ```
  ## Update Complete

  Commit: {commit_hash}
  Artifacts written: {count}
  {written_files list}

  Item {N} ({item.id}) is now complete.
  ```
```

**Pattern to add** (new final action after "Update Complete" output, success-path only):
```
After outputting the "Update Complete" block, immediately invoke `/sara-lint` with no
arguments. Do not prompt the user — lint runs automatically as the final action of every
successful sara-update run. The user sees the lint output inline as the last part of the
sara-update session.

Output before invoking:
```
Running /sara-lint to curate related[] and Cross Links...
```

Then invoke `/sara-lint`.
```

**Placement rule:** This auto-invocation only occurs on the SUCCESS path (exit code 0, stage advanced to `complete`). It does NOT occur on the partial failure path or the commit-failure path.

**Mechanism note (planner must confirm):** In this skill system, skill-to-skill invocation is not yet established. The planner should determine whether this is expressed as a direct `/sara-lint` invocation instruction in the skill prose, or as a `Task(sara-lint, ...)` call. The CONTEXT.md notes this as an open integration point.

---

### `.claude/skills/sara-lint/SKILL.md` (skill, scan-and-repair)

**Change type:** Two modifications — (a) add D-07 check, (b) extend D-06 for empty related[]

**Analog:** Current file (self). Existing per-finding approval loop in Step 5 (lines 167–229) is the copy pattern for D-07's repair loop participation.

---

#### D-06 extension target — Cross Links behaviour for empty related[]

**Current D-06 grep** (line 140–141):
```bash
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null | grep -v "related: \[\]" | grep "\.md:" | grep -v "\.gitkeep"
```

The current grep EXCLUDES pages with `related: []`. D-09 changes this: pages with `related: []` must also be checked for an absent `## Cross Links` section header.

**Extended D-06 logic** (replace the current single-grep approach with two passes):

Pass 1 (unchanged — non-empty related, check for divergence):
```bash
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep -v "related: \[\]" | grep "\.md:" | grep -v "\.gitkeep"
```
For each file: Read it, compare `related:` list against `## Cross Links` body IDs. Flag if they differ OR if the section is absent.

Pass 2 (new — empty related, check for absent Cross Links header):
```bash
grep -rn "^related: \[\]" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep "\.md:" | grep -v "\.gitkeep"
```
For each file: Read it, check whether a `## Cross Links` section header exists in the body (regardless of content). If absent: add a finding.

**Finding format for Pass 2:**
- issue: "`## Cross Links` section absent from {file} (related: [] but section header missing)"
- proposed_fix: "Add empty `## Cross Links` section header at end of file body."

**Fix implementation for Pass 2 finding** (in Step 5, D-06 branch):
When `related: []` and section header is absent: append `\n## Cross Links\n` at the end of the file body. No link content — heading only. Use the Write tool.

**Commit message for Pass 2 fix:**
```
fix(wiki): add empty Cross Links header to {ID} via sara-lint
```

**Current D-06 fix prose** (lines 205–206 — retain for Pass 1, extend for Pass 2):
```
**D-06 — Cross Links mismatch:**
Regenerate the `## Cross Links` body section from the `related:` frontmatter list. For each related ID, look up the page title by reading the corresponding wiki file. Format each link as `[[{ID}|{Title}]]` — one per line. If the `## Cross Links` section exists, replace it. If absent, append it at the end of the file body. Use the Write tool to write the full file back.
```

Extended D-06 fix prose must handle both sub-cases:
- Non-empty related[]: regenerate the section with link content (existing behaviour)
- Empty related[]: write heading-only `## Cross Links` with no link content beneath it

---

#### D-07 additive — Semantic related[] curation (new sixth check)

**Where to insert in Step 3:** D-07 is the sixth check. Add it after the D-06 block, before the step boundary. The existing Step 3 comment says "Execute all grep scans and file checks upfront. Collect ALL findings from all five checks into a single `{all_findings}` list before presenting any to the user." — update the count to "all six checks".

**Also update:**
- Step 4 completion message: change "all 5 checks" to "all 6 checks"
- Step 3 intro comment: change "five checks" to "six checks"
- Objective line: change "(1)…(5)" enumeration to include "(6) missing/empty related[] curation"

**D-07 check prose to insert** (new block after D-06 in Step 3):

```
---

**Check D-07 — Semantic related[] curation**

Find all wiki artifact pages where `related:` is absent from frontmatter OR the related
field is absent. Pages with `related: []` (explicitly empty list) are treated as already
curated and are NOT flagged.

Rationale: `related: []` written by sara-update is the default empty value from extraction.
After LLM curation via D-07, pages where LLM confirmed no relationships retain `related: []`
and must not be re-flagged. Only pages that have never been through curation (absent field)
need this check. (Implementation choice (a) from Claude's Discretion: treat `related: []`
as curated.)

Run:

```bash
grep -rL "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep "\.md$" | grep -v "\.gitkeep"
```

For each file returned (absent `related:` field): Read the file using the Read tool.

Determine if this is a wiki artifact page (has a valid `id:` frontmatter field matching
REQ-\d{3}, DEC-\d{3}, ACT-\d{3}, or RSK-\d{3}). If not, skip.

Add a finding per file:
- check_id: D-07
- file: {path}
- issue: "related[] absent from {ID} ({file}) — not yet curated"
- proposed_fix: "LLM reads this page and all other wiki artifact pages (or summaries) to
  infer semantic relationships. Proposes a related: list (may be empty if no relationships).
  Writes related: field to frontmatter. Regenerates ## Cross Links section."

---
```

**D-07 repair implementation** (in Step 5, new D-07 branch):

```
**D-07 — Semantic related[] curation:**

1. Re-read the target file using the Read tool.

2. Collect all other wiki artifact pages for context:
   - Run: find wiki/requirements wiki/decisions wiki/actions wiki/risks -name "*.md" ! -name ".gitkeep"
   - For each file (excluding the target): Read using the Read tool and extract:
     - id, title, summary from frontmatter
     - For large wikis (> 20 artifact pages): use only frontmatter fields (id, title, summary)
       rather than full body to stay within context window. For small wikis (≤ 20 pages):
       read full content.

3. LLM inference pass:
   Reason semantically about which other pages are related to the target artifact.
   Relationship criteria (from CONTEXT.md D-05):
   - Shared topic: both artifacts concern the same subject matter
   - Addressal: one artifact addresses or responds to the other (e.g. an action mitigates a risk)
   - Consequence: one artifact is a consequence or result of the other
   Example: RSK-001 and ACT-003 are related because the action sets up a workshop to
   address the risk — not because they were co-extracted from the same meeting.

4. Propose a `related:` list (may be empty `[]` if no semantic relationships found).
   Present the proposed list as part of the AskUserQuestion (already handled by Step 5 loop).
   The proposed_fix shown to the user must include the specific IDs proposed, e.g.:
   "Proposed: related: [ACT-003, RSK-001]" or "Proposed: related: [] (no relationships found)"

5. On "Apply":
   a. Write `related: [ID1, ID2]` (or `related: []`) to the frontmatter.
   b. If related is non-empty: regenerate `## Cross Links` section with wikilinks.
      If related is []: write empty `## Cross Links` heading (heading-only, no content).
   c. Use the Write tool for the full file write.
   d. Commit:
      git add {exact_file_path}
      git commit -m "fix(wiki): curate related[] on {ID} via sara-lint D-07"
      echo "EXIT:$?"
```

**Commit message for D-07:**
```
fix(wiki): curate related[] on {ID} via sara-lint D-07
```

---

#### Existing per-finding approval loop pattern — copy for D-07 integration

D-07 findings join the SAME Step 5 loop as D-02 through D-06. The loop pattern (lines 167–229) is unchanged. D-07 just adds a new branch to the "Apply" handler.

**Existing AskUserQuestion pattern** (lines 171–176):
```
Present using AskUserQuestion:
- header: "Lint finding [{fix_number} of {total}]"
- question: "{issue description}\n\nProposed fix: {proposed_fix}\n\nApply this fix?"
- options: ["Apply", "Skip"]
```

**Existing atomic commit pattern** (lines 208–213):
```bash
git add {exact_file_path}
git commit -m "{commit_message}"
echo "EXIT:$?"
```

**Existing commit success check** (lines 223–226):
```
If exit code 0: run `git log --oneline -1` to get {commit_hash}. Output: "Fixed. Commit: {commit_hash}"
If exit code != 0: output "Fix written but commit failed — resolve git issue and commit manually." Continue to next finding.
```

---

## Shared Patterns

### Per-finding approval loop (D-08/D-09 from Phase 13, carried forward)
**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5 (lines 167–229)
**Apply to:** D-07 findings (new check), D-06 Pass 2 findings (extended check)
```
For each finding in {all_findings} in order:
  AskUserQuestion: header "Lint finding [{fix_number} of {total}]", options ["Apply", "Skip"]
  If Apply: re-read file, apply fix in memory, Write tool, git add {exact_path}, git commit, check exit code
  If Skip: output "Skipped.", increment {fix_number}
  Increment {fix_number}. Continue to next finding.
```

### Atomic commit pattern
**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5 (lines 208–213)
**Apply to:** Every D-07 fix, every D-06 Pass 2 fix
```bash
git add {exact_file_path}
git commit -m "fix(wiki): {action} on {ID} via sara-lint"
echo "EXIT:$?"
```

### Read-before-write rule
**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5, notes (line 302)
**Apply to:** All D-07 repairs, all D-06 Pass 2 repairs
```
Re-read the target file immediately using the Read tool (always re-read before writing — another fix in the same loop may have modified it).
```

### Cross Links empty section pattern
**Source:** `.claude/skills/sara-update/SKILL.md` — all four artifact type write blocks contain:
```
Write each link on its own line. If artifact.related is empty, write this heading with no
content (heading-only — consistent with the established empty-section pattern for this skill).
```
**Apply to:** D-06 Pass 2 fix (add empty heading), D-07 fix when related resolves to []

### related: [] as curated sentinel
**Source:** CONTEXT.md Claude's Discretion, approach (a)
**Apply to:** D-07 check grep — only flag ABSENT `related:` field, never flag `related: []`
```bash
# Correct: flags absent related: field only
grep -rL "^related:" wiki/...

# Do NOT use: would also flag curated-empty pages
grep -rn "^related: \[\]" wiki/...  # ← this is for D-06 Pass 2 only, not D-07
```

---

## No Analog Found

All three skill files are well-established. The only genuinely novel pattern is skill-to-skill invocation (D-10 in sara-update), which has no prior example in this codebase.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| sara-update final step → `/sara-lint` | invocation | request-response | Skill-to-skill invocation pattern not yet established. Planner must define mechanism (inline prose instruction vs Task() call). |

---

## Metadata

**Analog search scope:** `.claude/skills/sara-extract/`, `.claude/skills/sara-update/`, `.claude/skills/sara-lint/`, `.planning/phases/14-extraction-pipeline-fix/`, `.planning/phases/13-lint-refactor/`
**Files scanned:** 5 (3 skill files + 2 phase plan files)
**Pattern extraction date:** 2026-05-01
