# Phase 16: tagging - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 1 (sole implementation target)
**Analogs found:** 1 / 1 (self-referential — the file being modified IS the primary analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-lint/SKILL.md` | skill / scan-and-enrich | batch transform (corpus-wide vocabulary derivation) + event-driven (AskUserQuestion gate) | self (current version, post-Phase-15) — specifically the D-07 whole-wiki pass | exact — additive post-loop step following the same LLM-over-wiki pattern |

---

## Pattern Assignments

### `.claude/skills/sara-lint/SKILL.md` (skill, batch transform + event-driven gate)

**Change type:** Additive — new Step 6 after the existing per-finding loop. No changes to Steps 1–5.

**Analog:** `.claude/skills/sara-lint/SKILL.md` (self, current version). The D-07 semantic related[] curation check (Step 3 + Step 5 repair branch, added in Phase 15) is the closest structural analog. D-08 extends the same "LLM reads whole wiki, derives structure, writes to frontmatter" pattern to a two-phase vocabulary derivation + assignment model.

---

### Objective line pattern (line 14)

**Current text** (post-Phase-15):
```
sara-lint v2.0 scans all wiki artifact pages across six checks: (1) missing v2.0 frontmatter fields, (2) broken related[] IDs, (3) orphaned wiki pages, (4) index↔disk bidirectional sync, (5) Cross Links↔related[] divergence, (6) missing/empty related[] curation. Every finding is presented individually for approval. Every accepted fix is committed atomically.
```

**Required update:** Append D-08 reference to objective line. Replace with:
```
sara-lint v2.0 scans all wiki artifact pages across six mechanical checks plus whole-wiki tag curation (D-08): (1) missing v2.0 frontmatter fields, (2) broken related[] IDs, (3) orphaned wiki pages, (4) index↔disk bidirectional sync, (5) Cross Links↔related[] divergence, (6) missing/empty related[] curation. Every finding is presented individually for approval. Every accepted fix is committed atomically. After all findings are resolved, D-08 derives an emergent tag vocabulary from the full wiki corpus and assigns tags to all artifact pages.
```

---

### Step insertion pattern — where Step 6 goes

**Established step structure in the file (post-Phase-15):**
```
Step 1 — Wiki existence guard        (line 19)
Step 2 — Load config                 (line 33)
Step 3 — Run all six checks          (line 38)
Step 4 — Present finding count       (line 150)
Step 5 — Per-finding approval loop   (line 167)
[END of file process section]
```

**Insertion point:** Append Step 6 immediately after Step 5 ends (after the `Increment {fix_number}. Continue to next finding.` line and before `</process>`).

---

### AskUserQuestion gate pattern (Step 5, lines 171–176)

**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5, per-finding approval loop.

D-08 uses the SAME `AskUserQuestion` tool already in sara-lint's `allowed-tools`, but with a different options set (vocabulary-level gate, not per-finding). The call structure mirrors the Step 5 pattern:

```
Present using AskUserQuestion:
- header: "D-08: Tag vocabulary derived from {N} artifact pages"
- question: "Derived tags:\n\n  {tag1}, {tag2}, {tag3}, ...\n\nApprove this vocabulary, edit it, or skip tag curation?"
- options: ["Approve", "Edit", "Skip"]
```

**Difference from Step 5 pattern:** Step 5 uses `["Apply", "Skip"]` for individual findings. D-08 uses `["Approve", "Edit", "Skip"]` for the whole vocabulary. This is the only structural difference — the tool call itself is identical.

---

### Atomic commit pattern (Step 5, lines 208–213)

**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5, after Write succeeds.

D-08 uses the SAME atomic commit pattern, but stages an explicit list of files written during the assignment pass (not a single file):

```bash
git add {file_path_1} {file_path_2} ... {file_path_N}
git commit -m "fix(wiki): update tags via sara-lint D-08"
echo "EXIT:$?"
```

**Commit success check (lines 223–226 — reuse verbatim):**
```
If exit code 0: run `git log --oneline -1` to get {commit_hash}. Output: "Fixed. Commit: {commit_hash}"
If exit code != 0: output warning and continue
```

**T-13-04 constraint (notes section, last line):** Build the `git add` file list from the write loop — use exact file paths, never directory globs. Commit message is a fixed template string (`fix(wiki): update tags via sara-lint D-08`) — no user-supplied content interpolated.

---

### Read-before-write rule (notes section)

**Source:** `.claude/skills/sara-lint/SKILL.md` notes, line ~302:
```
Always re-read a file immediately before writing it (another fix in the same loop may have changed it)
```

D-08 MUST follow this rule: the derivation pass reads pages to build the vocabulary, but Step 5 fixes may have modified pages between derivation and the D-08 write pass. Re-read each target page immediately before writing its `tags:` field.

---

### D-07 context window guard pattern (Step 5, D-07 repair branch)

**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5, D-07 repair branch:
```
- If the wiki has 20 or fewer artifact pages total: Read the full file using the Read tool.
- If the wiki has more than 20 artifact pages total: Read the file using the Read tool but
  extract only the frontmatter fields id, title, and summary — use only those fields as
  context (to stay within context window for large wikis).
```

D-08 adapts this threshold for the **vocabulary derivation pass**: read frontmatter (`id`, `title`, `summary`) plus the first substantive body section of each page (richer than D-07's summary-only path but still bounded). For the **assignment pass**: per-page full read (one page at a time, manageable context because vocabulary is already known).

---

### tags: [] field write pattern (frontmatter YAML)

**Source:** Confirmed in sara-init templates (`.claude/skills/sara-init/SKILL.md` lines 197, 228, 268, 290) and CLAUDE.md entity schemas. All four artifact types (REQ, DEC, ACT, RSK) have `tags: []` in their frontmatter.

**Field position in frontmatter (all four types):**
```yaml
schema_version: '2.0'
tags: []        # ← this field, inline YAML array
related: []
segments: []
```

**Write format for D-08:**
- Empty (no tags assigned): `tags: []` — inline, unchanged from template default
- One or more tags: `tags: [authentication, data-governance, infrastructure]` — inline YAML array, lowercase kebab-case strings

**Replacement rule:** Replace the entire `tags:` line (whether `tags: []` or a prior non-empty value) with the new assigned list. Full-replacement semantics per D-06 locked decision.

---

### Article page discovery pattern (Step 3, D-07 check)

**Source:** `.claude/skills/sara-lint/SKILL.md` Step 3, D-07 check:
```bash
find wiki/requirements wiki/decisions wiki/actions wiki/risks -name "*.md" ! -name ".gitkeep" 2>/dev/null
```

D-08 uses the SAME four directories (requirements, decisions, actions, risks). Stakeholders are NOT included — consistent with D-02 through D-07 scope. STK pages have `tags: []` in their schema but are excluded from D-08 scope (per assumption A2 in RESEARCH.md).

**Empty-wiki guard (RESEARCH.md Pitfall 6):** Before running the derivation pass, check if the file count from the find command is zero. If so, output `"D-08: No artifact pages to analyse — tag curation skipped."` and skip D-08 entirely.

---

### Wiki file read/write constraint (notes section)

**Source:** `.claude/skills/sara-lint/SKILL.md` notes:
```
Wiki artifact files are read and written using Read and Write tools only — never Bash
text-processing (sed, awk, jq) on markdown files
Bash is only used for: grep (read-only scan), find (read-only scan), ls (existence check),
git commands
```

D-08 must follow this rule exactly. All frontmatter writes use the Write tool on the full file content. No Bash text-processing for YAML manipulation.

---

## Step 6 Prose Structure (D-08 — to be written into the skill)

The planner should produce Step 6 prose following this exact structure (mirroring how Step 5 is written):

```
**Step 6 — D-08 Tag curation**

[empty-wiki guard clause]

**Phase 1: Vocabulary derivation pass**

Run:
```bash
find wiki/requirements wiki/decisions wiki/actions wiki/risks -name "*.md" ! -name ".gitkeep" 2>/dev/null
```

[context window strategy: frontmatter + first body section for each page]
[LLM derives emergent vocabulary: list of lowercase kebab-case tag strings]
[kebab-case normalisation before presenting to user: lowercase(tag).replace(' ', '-'), strip non [a-z0-9-] chars]

**AskUserQuestion: vocabulary approval gate**
[present normalised vocabulary list]
[options: Approve / Edit / Skip]

[Skip branch: output "Tag curation skipped." STOP D-08.]
[Edit branch: user provides modified list → re-normalise → proceed as Approve]

**Phase 2: Assignment pass**

[for each artifact page: re-read full page, LLM assigns which approved vocabulary tags apply]
[collect assignment map: {file_path → [tags]}]

**Present assignment summary**
[table: ID | Title | Tags assigned]

**Write tag updates**
[for each page with tag assignments: re-read immediately before write, replace tags: line, Write tool]
[build explicit file list during write loop]

**Atomic commit**
```bash
git add {file_1} {file_2} ... {file_N}
git commit -m "fix(wiki): update tags via sara-lint D-08"
echo "EXIT:$?"
```
[commit success check — same pattern as Step 5]
```

---

## Shared Patterns

### AskUserQuestion tool
**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5 (lines 171–176)
**Apply to:** D-08 vocabulary approval gate (Step 6)
```
Present using AskUserQuestion:
- header: "Lint finding [{fix_number} of {total}]"  ← adapt header for D-08
- question: "{issue description}\n\nProposed fix: {proposed_fix}\n\nApply this fix?"
- options: ["Apply", "Skip"]  ← D-08 uses ["Approve", "Edit", "Skip"]
```

### Atomic commit + success check
**Source:** `.claude/skills/sara-lint/SKILL.md` Step 5 (lines 208–226)
**Apply to:** D-08 batch tag write commit
```bash
git add {exact_file_path}
git commit -m "{commit_message}"
echo "EXIT:$?"
# If exit code 0: git log --oneline -1 → output "Fixed. Commit: {commit_hash}"
# If exit code != 0: output warning and continue
```
**D-08 commit message (fixed template):** `fix(wiki): update tags via sara-lint D-08`

### Read-before-write rule
**Source:** `.claude/skills/sara-lint/SKILL.md` notes
**Apply to:** Every wiki artifact page write in D-08 assignment pass
```
Re-read the target file immediately using the Read tool (always re-read before writing —
another fix in the same loop may have modified it).
```

### Four-directory artifact scope
**Source:** `.claude/skills/sara-lint/SKILL.md` Step 3 (D-02 through D-07 grep patterns)
**Apply to:** D-08 `find` command for artifact page discovery
```bash
find wiki/requirements wiki/decisions wiki/actions wiki/risks -name "*.md" ! -name ".gitkeep" 2>/dev/null
```

### T-13-04 commit safety
**Source:** `.claude/skills/sara-lint/SKILL.md` notes (last line)
**Apply to:** D-08 git add staging
```
T-13-04 mitigation: commit only stages explicit file paths (never directory globs);
commit messages are templated strings — no user-supplied strings are interpolated
directly into the commit command
```

---

## No Analog Found

No novel patterns required. D-08 is purely a new step composed entirely from established sara-lint infrastructure.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All D-08 patterns are covered by self-analogs from existing sara-lint Steps 3 and 5 |

The only genuinely new UX pattern is the **vocabulary-first approval gate** (`["Approve", "Edit", "Skip"]` options) — this is a variant of the existing per-finding `["Apply", "Skip"]` AskUserQuestion. No additional infrastructure is needed; the same `AskUserQuestion` tool is used with a different options list.

---

## Key Pattern Differences: D-08 vs D-07

| Dimension | D-07 (Phase 15 analog) | D-08 (Phase 16 new step) |
|-----------|------------------------|--------------------------|
| Placement | Step 3 (check) + Step 5 (repair branch inside per-finding loop) | Step 6 (standalone — outside per-finding loop entirely) |
| Approval granularity | Per-finding (one AskUserQuestion per uncurated page) | Vocabulary-level (one AskUserQuestion for whole corpus) |
| Options | `["Apply", "Skip"]` | `["Approve", "Edit", "Skip"]` |
| LLM passes | One pass per finding (per-artifact inference during Step 5) | Two passes: corpus-wide vocabulary derivation, then per-page assignment |
| Commit | One commit per accepted fix | One atomic commit for all tag writes |
| Finding in `{all_findings}` | Yes — D-07 findings join the per-finding loop | No — D-08 is not a "finding"; it runs unconditionally after Step 5 |
| Re-run behaviour | Pages with `related: []` treated as curated (not re-flagged) | Full replacement — every run re-derives vocabulary and overwrites all tags |

---

## Metadata

**Analog search scope:** `.claude/skills/sara-lint/SKILL.md` (primary), `.claude/skills/sara-init/SKILL.md` (schema reference), `.planning/phases/15-lint-repair/15-PATTERNS.md` (D-07 patterns), `.planning/phases/15-lint-repair/15-03-PLAN.md` (D-07 implementation)
**Files scanned:** 5
**Pattern extraction date:** 2026-05-01
