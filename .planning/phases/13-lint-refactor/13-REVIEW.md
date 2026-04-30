---
phase: 13-lint-refactor
reviewed: 2026-04-30T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - .claude/skills/sara-lint/SKILL.md
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-04-30
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `.claude/skills/sara-lint/SKILL.md` — the v2.0 rewrite of the sara-lint skill. The document describes five mechanical checks (D-02 through D-06) with a per-finding approval loop and per-fix atomic commit pattern. The overall structure is sound. No critical security issues were found; the notes section explicitly documents the shell-injection mitigation (T-13-04). Six warnings were identified: four are logic errors in check algorithms that will produce silent incorrect results (wrong grep filter for D-03/D-06, false-positive `ls`-based existence check, D-04 index-ID extraction by string search, and a hardcoded date in the fix handler). Two are missing edge-case guards (empty wiki directories and absent `wiki/index.md`). Four info items cover ambiguity and dead-code-path concerns.

---

## Warnings

### WR-01: D-03 grep filter uses `.md:` but colons appear in Windows paths — use `\.md:` anchor

**File:** `.claude/skills/sara-lint/SKILL.md:98`
**Issue:** The grep pipeline for D-03 filters with `grep "\.md:"` (escaped dot, but no start anchor). A file path such as `wiki/requirements/REQ-01.md:12:related: [...]` matches correctly, but a filename containing `.md.bak:` or a path segment with `.md` followed by a colon would also pass. More importantly the filter `grep "\.md:"` is the only guard preventing directory lines from leaking through — it is not anchored, so it could pass lines for directories named with `.md` in them. The same pattern recurs at line 140 for D-06.

Identical issue on line 140:
```
grep -rn "^related:" ... | grep -v "related: \[\]" | grep "\.md:" | grep -v "\.gitkeep"
```

**Fix:** Anchor the filter to paths: pipe through `grep -E "\.md:[0-9]+"` so only lines whose path ends in `.md` followed by a line number pass through. This is the canonical `grep -n` output format and is unambiguous:
```bash
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ \
  2>/dev/null | grep -v "related: \[\]" | grep -E "\.md:[0-9]+" | grep -v "\.gitkeep"
```

---

### WR-02: `ls` existence check for related IDs is fragile — returns non-zero for a non-existent single argument but counts ALL matches

**File:** `.claude/skills/sara-lint/SKILL.md:103-105`
**Issue:** The existence check for a related ID is:
```bash
ls wiki/requirements/{ID}.md wiki/decisions/{ID}.md wiki/actions/{ID}.md \
   wiki/risks/{ID}.md wiki/stakeholders/{ID}.md 2>/dev/null | wc -l
```
`ls` lists each argument that exists and silently skips those that do not (with stderr suppressed). `wc -l` counts output lines. If the ID matches as both `wiki/risks/REQ-01.md` AND `wiki/requirements/REQ-01.md` (impossible by naming convention but conceivable with unusual naming), the count would be 2 and still be non-zero, which is correct. The actual defect: `ls` output may include two lines for a single existing file if the path contains spaces and `ls` word-wraps. More critically, `ls` exits non-zero even when some arguments are found (because other arguments were not found), but stderr is suppressed so this cannot be detected. If all five paths fail and `ls` exits 1 with no output, `wc -l` returns 0 — correct. If one path succeeds, `wc -l` returns 1 — correct. This is functionally sound for the binary "found / not found" case but is brittle: any filenames with newlines would produce a count > 1 for a single match.

A more robust and idiomatic pattern:
```bash
find wiki/requirements wiki/decisions wiki/actions wiki/risks wiki/stakeholders \
  -maxdepth 1 -name "{ID}.md" 2>/dev/null | wc -l
```
This handles spaces in paths and is explicit about depth.

---

### WR-03: D-04 ID presence check uses full-content string search — will produce false positives for partial ID matches

**File:** `.claude/skills/sara-lint/SKILL.md:121`
**Issue:** The orphan check verifies an ID is in the index with: "Check if the ID string appears anywhere in `{index_content}`." A search for `REQ-1` would spuriously match `REQ-10`, `REQ-11`, `REQ-100`, etc. because it is a substring check. If index rows contain prose referencing other IDs (e.g. a description mentioning a parent requirement), a page that is genuinely orphaned could be incorrectly reported as indexed.

**Fix:** Constrain the search to whole-word/token matching. The index rows follow a fixed table format; check for the ID followed by a non-alphanumeric character (or end of line), e.g. using a word-boundary regex on the extracted ID column rather than an arbitrary string search:
```
Check if the ID appears as a complete token in {index_content}
(i.e., the ID is surrounded by non-alphanumeric characters or
line boundaries — not merely a substring of another ID).
```
In Python-style pseudo-regex: `r'\b{ID}\b'` or, for the table format, match the ID in the first column of a Markdown table row: `| {ID} |`.

---

### WR-04: D-04 fix handler has a hardcoded date — will produce stale `last-updated` values

**File:** `.claude/skills/sara-lint/SKILL.md:197`
**Issue:** The D-04 fix handler specifies:
```
Last-updated: today's date (2026-04-30)
```
The literal date `2026-04-30` is embedded in the instruction text, not computed at runtime. Any execution after 2026-04-30 will write a stale date into the index row. This is a copy-paste artefact from the authoring date.

**Fix:** Replace the hardcoded date with a runtime instruction:
```
Last-updated: the current date in YYYY-MM-DD format (obtain via Bash: date +%Y-%m-%d)
```

---

### WR-05: No guard for empty wiki artifact directories — grep -rL may behave unexpectedly on missing dirs

**File:** `.claude/skills/sara-lint/SKILL.md:62-87`
**Issue:** Step 1 guards only that `wiki/` exists as a directory. The D-02 greps pass explicit sub-paths (e.g. `wiki/requirements/`, `wiki/risks/`) to `grep -rL`. If a subdirectory does not exist, `grep` exits with status 2 (error), which is suppressed by `2>/dev/null`, so the grep silently returns nothing — as if the directory were empty. This is safe for the common case but means a project that has never created any risks, for example, would not produce an error even if `wiki/risks/` is absent. This is likely intentional (2>/dev/null), but the `find` in D-04 behaves the same way: if `wiki/actions` does not exist, find exits non-zero and produces no output, silently producing an incomplete `{disk_files}` list.

The root issue is that `{disk_files}` may be incomplete without any signal, making D-04 and D-05 blind to all files in that missing directory.

**Fix:** After the wiki-exists guard (Step 1), add a check that the expected subdirectories exist, or document explicitly that missing subdirectories are treated as empty (currently undocumented):
```bash
for dir in wiki/requirements wiki/decisions wiki/actions wiki/risks wiki/stakeholders; do
  [ -d "$dir" ] || echo "Warning: $dir not found — treated as empty for lint purposes."
done
```

---

### WR-06: D-04 and D-05 assume wiki/index.md exists — no guard for absent index file

**File:** `.claude/skills/sara-lint/SKILL.md:121`
**Issue:** Step 3 D-04 instructs: "Read wiki/index.md using the Read tool." The Read tool will return an error if the file does not exist. The skill has no guard for this case and no recovery path. If `wiki/index.md` is absent, the entire D-04 and D-05 check logic fails silently (or throws an error the agent may not handle gracefully). The wiki-exists guard in Step 1 only checks the `wiki/` directory, not the index file.

**Fix:** Before reading `wiki/index.md` in D-04, verify its existence:
```bash
[ -f "wiki/index.md" ] || { echo "wiki/index.md not found — D-04 and D-05 skipped."; }
```
And explicitly skip D-04 and D-05 findings collection if the index is absent, adding the absence itself as a finding if desired.

---

## Info

### IN-01: D-05 note conflates "missing rows" with D-04 but does not say how to extract index IDs

**File:** `.claude/skills/sara-lint/SKILL.md:125-131`
**Issue:** D-05 says "Extract all entity IDs referenced in wiki/index.md rows" but gives no instruction on how to perform this extraction. For D-04, reading each disk file to get its `id:` field is explicit. For D-05 the reverse direction — extracting IDs from the index — is left unspecified. The index format (Markdown table) means the extraction method matters: naive line-splitting may pick up header rows, separator rows (`|---|`), or prose mentions. This ambiguity could lead to false-positive stale-row findings.

**Suggestion:** Add a concrete extraction instruction, e.g.:
```
Parse wiki/index.md for table rows where the first column matches the pattern
[A-Z]{2,3}-[0-9]+. Exclude the header row and separator row.
```

---

### IN-02: `{fix_number}` is not incremented in the "Apply" branch — only on "Skip"

**File:** `.claude/skills/sara-lint/SKILL.md:176,229`
**Issue:** The per-finding loop reads:
```
If "Skip": output "Skipped." Increment {fix_number}. Continue to next finding.
...
Increment {fix_number}. Continue to next finding.  ← line 229
```
Reading the structure carefully, the increment at line 229 is inside the "If Apply" branch and follows the commit block. This is correct — both branches increment. However, the instruction is easy to misread as the increment being only in the Apply branch (it appears after several nested sub-steps). The "Skip" branch explicitly says "Increment {fix_number}" while the Apply branch buries it after the commit section. Recommend promoting the increment to a shared "after each finding, regardless of outcome" statement for clarity.

---

### IN-03: D-06 fix does not re-validate related[] IDs before regenerating Cross Links

**File:** `.claude/skills/sara-lint/SKILL.md:205-206`
**Issue:** The D-06 fix regenerates `## Cross Links` from the `related:` frontmatter list. If D-03 (broken related IDs) and D-06 (cross links mismatch) both fire for the same file, and the user applies D-06 before D-03, the regenerated Cross Links section will include links to broken (non-existent) IDs. The skill collects all findings upfront and presents them in check order (D-02 → D-06), so D-03 findings are presented before D-06 findings for the same file. However, the user may skip D-03 and apply D-06, silently embedding broken wikilinks.

**Suggestion:** Add a note that the D-06 fix should only look up titles for IDs that resolve to real files (i.e. run the same existence check as D-03 per ID before including the link), and omit broken IDs from the regenerated section with a warning rather than embedding them.

---

### IN-04: Commit message for D-05 says "correct index row" but the action is deletion

**File:** `.claude/skills/sara-lint/SKILL.md:220`
**Issue:** The commit message template for D-05 is:
```
fix(wiki): correct index row for {ID} via sara-lint
```
The D-05 fix removes a stale index row (deletion). "Correct" is ambiguous — it could mean correcting a value in the row or removing it entirely. A more descriptive message would be:
```
fix(wiki): remove stale index row for {ID} via sara-lint
```
This matches the D-04 message style ("add {ID} to wiki/index.md") and makes the git log self-documenting.

---

_Reviewed: 2026-04-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
