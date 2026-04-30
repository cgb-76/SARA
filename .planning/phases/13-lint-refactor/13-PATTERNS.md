# Phase 13: lint-refactor - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 1 (sara-lint/SKILL.md — full rewrite)
**Analogs found:** 4 / 1 (multiple analogs for the single target file)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-lint/SKILL.md` | skill (maintenance/lint) | batch scan → per-finding event-driven | `.claude/skills/sara-lint/SKILL.md` (v1) | exact role; v2 extends all stub checks |

Supporting analogs (patterns extracted from these for use in the rewrite):

| Analog File | Role | Pattern Contributed |
|-------------|------|---------------------|
| `.claude/skills/sara-lint/SKILL.md` (v1, lines 1–167) | skill | Skill header, wiki-exists guard, `grep -rL` scan, dry-run confirm, write-back, commit |
| `.claude/skills/sara-update/SKILL.md` (lines 556–598) | skill | Per-artifact atomic commit pattern (`git add` explicit paths → `git commit` → exit-code check) |
| `.claude/skills/sara-extract/SKILL.md` (lines 1–60) | skill | Stage guard structure, config.json read pattern |

---

## Pattern Assignments

### `.claude/skills/sara-lint/SKILL.md` (skill, batch→event-driven)

This file is a **full rewrite**. The v1 file is the primary structural template; patterns from sara-update and the canonical CONTEXT.md files supply the new check logic.

---

#### SKILL header (from v1, lines 1–11)

Copy the YAML frontmatter block exactly, updating `description` and `version`:

```yaml
---
name: sara-lint
description: "Scan wiki artifact pages for schema gaps against v2.0 schemas and fix them"
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 2.0.0
---
```

---

#### Wiki-exists guard (from v1, lines 19–29)

Reuse verbatim as Step 1:

```bash
if [ ! -d "wiki" ]; then
  echo "No wiki found. Run /sara-init first."
  exit 1
fi
```

If the directory exists, continue.

---

#### Grep scan pattern — the master template for every mechanical check (from v1, lines 44–54)

Every check in v2 follows this identical structure. The `-L` flag finds files **without** the pattern; `-l` finds files **with** it. Adapt the grep pattern and directories per check:

```bash
# Template: find files MISSING a field
grep -rL "^field_name:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null \
  | grep "\.md$" | grep -v "\.gitkeep"

# Template: find files with a field present (for cross-reference checks)
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep "\.md$" | grep -v "\.gitkeep"
```

Store results as `{missing_files}` or `{findings}` (a list of file paths or path:line pairs).

If `{findings}` is empty: output a "nothing to do" line for that check and proceed to the next check.

---

#### Per-finding approval loop (from 13-CONTEXT.md D-08 and v1 lines 78–90)

**Critical difference from v1:** v2 does NOT do a single batch confirm for all findings. Each finding gets its own `AskUserQuestion`. The structure is:

```
For each finding in {all_findings}:
  Present plain-text description of the issue and proposed change.
  Ask:
    header: "Lint finding [N of M]"
    question: "<description of issue>\n\nProposed fix: <proposed change>\n\nApply this fix?"
    options: ["Apply", "Skip"]
  If "Skip": output "Skipped." and continue to next finding.
  If "Apply":
    Read the file using the Read tool.
    Apply the fix using the Write tool.
    Commit immediately (see atomic commit pattern below).
```

The optional dry-run preview from v1 (showing a count and a sample fix before the loop) is still appropriate to retain — show the total finding count before starting the per-finding loop. This is left to Claude's discretion per 13-CONTEXT.md.

---

#### Atomic commit pattern — one commit per accepted fix (from sara-update SKILL.md, lines 556–598, and 13-CONTEXT.md D-09)

**Every accepted fix is committed immediately after the write.** Do NOT batch. Copy this structure for each fix:

```bash
git add {exact_file_path}   # never stage by directory glob
git commit -m "fix(wiki): <description> via sara-lint [{ID}]"
echo "EXIT:$?"
```

Check the exit code from `"EXIT:$?"`.

If exit code 0: run `git log --oneline -1` to capture `{commit_hash}`. Output: `"Fixed. Commit: {commit_hash}"`.
If exit code != 0: output `"Fix written but commit failed — resolve git issue and commit manually."`. Continue to the next finding.

The commit message per finding type:
- Missing frontmatter field: `fix(wiki): back-fill {field} on {ID} via sara-lint`
- Broken related[] ID: `fix(wiki): remove broken related ID {broken_id} from {ID} via sara-lint`
- Orphaned page: `fix(wiki): add {ID} to wiki/index.md via sara-lint`
- Stale index row: `fix(wiki): correct index row for {ID} via sara-lint`
- Cross Links body mismatch: `fix(wiki): regenerate Cross Links on {ID} via sara-lint`

---

#### Read/Write-only rule (from v1 notes, line 105, and 13-CONTEXT.md code_context)

Applies to all wiki file operations:

```
Do NOT use Bash text-processing tools (jq, sed, awk) on markdown files.
Use Read tool to load a wiki page, modify the content in memory, and Write tool to write it back.
Bash is only acceptable for grep (read-only scan) and git operations.
```

---

### Check-by-check implementation patterns

#### Check D-02 — Missing v2.0 frontmatter fields

**Analog:** v1 Check 1 (missing `summary:`), lines 44–54 and 91–113.

Run one grep per missing field per applicable entity type. Fields and their applicable directories:

| Field | Applicable entity dirs | grep pattern |
|-------|------------------------|--------------|
| `schema_version` | all five | `^schema_version:` |
| `type` | requirements, decisions, actions, risks | `^type:` |
| `priority` | requirements only | `^priority:` |
| `due-date` | actions only | `^due-date:` |
| `owner` | actions, risks | `^owner:` |
| `likelihood` | risks only | `^likelihood:` |
| `impact` | risks only | `^impact:` |
| `segment` | stakeholders only | `^segment:` |
| `segments` | all four artifact types (not STK) | `^segments:` |

For **back-fill inference** per 13-CONTEXT.md D-07:
- `schema_version`: write `'2.0'` directly — no inference.
- `type` / `priority`: read the page body and apply the same classification logic used at extraction time (described in 08-CONTEXT.md D-05, 09-CONTEXT.md D-06, 10-CONTEXT.md D-04, 11-CONTEXT.md D-03).
- `segments`: read `.sara/config.json` `segments` array; infer via STK attribution from `related:` or keyword matching (same as sara-extract D-05 in 12-CONTEXT.md).
- `likelihood` / `impact`: infer from page body text signals (`high`/`medium`/`low`); if no signal, propose `""`.
- `due-date` / `owner`: infer from body text; if no signal, propose `""`.

#### Check D-03 — Broken `related[]` IDs

**Analog:** No direct v1 analog. Closest structural analog is the grep scan pattern.

```bash
# Collect all related: field values
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null \
  | grep -v "related: \[\]" | grep "\.md$" | grep -v "\.gitkeep"
```

For each file with a non-empty `related:` field: Read the file. Parse the `related:` YAML list. For each ID in the list, check whether `wiki/{entity_dir}/{ID}.md` exists on disk:

```bash
ls wiki/requirements/{ID}.md wiki/decisions/{ID}.md wiki/actions/{ID}.md \
   wiki/risks/{ID}.md wiki/stakeholders/{ID}.md 2>/dev/null | wc -l
```

If result is 0: the ID is broken — report it as a finding. Proposed fix: remove the broken ID from the `related:` list and rewrite the file.

#### Check D-04 — Orphaned pages

**Analog:** Stub comment in v1 Check 2 (line 139).

```bash
# Find all .md wiki artifact files on disk
find wiki/requirements wiki/decisions wiki/actions wiki/risks wiki/stakeholders \
  -name "*.md" ! -name ".gitkeep" 2>/dev/null
```

Read `wiki/index.md` using the Read tool. For each file found on disk, check if its ID appears anywhere in the index content. If not found: report as orphaned. Proposed fix: add an appropriate row to `wiki/index.md` and commit both the index and the page's commit.

**Note:** `wiki/index.md` is an LLM-maintained catalog — use Read tool, not grep, to load it for ID lookup.

#### Check D-05 — Index↔disk sync (bidirectional)

**Analog:** No direct v1 analog.

Two sub-checks:
1. Stale rows: IDs in `wiki/index.md` that have no corresponding file on disk.
2. Missing rows: files on disk (from `find` above) not listed in the index. (Overlaps with D-04.)

Read `wiki/index.md` once. Extract all IDs referenced. Cross-reference against disk file list. Stale rows: report each. Proposed fix: remove the stale row from the index and rewrite `wiki/index.md`.

#### Check D-06 — Cross Links↔`related[]` sync

**Analog:** No direct v1 analog.

```bash
# Find files with a non-empty related: field
grep -rn "^related:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ 2>/dev/null \
  | grep -v "related: \[\]" | grep "\.md$" | grep -v "\.gitkeep"
```

For each such file: Read the file. Compare the IDs in `related:` frontmatter against IDs linked in the `## Cross Links` body section. If they differ: report divergence. Proposed fix: regenerate the `## Cross Links` section from the `related:` frontmatter (one wiki link per entry, per the wikilink rule: `[[STK-NNN|Name]]`, `[[REQ-NNN|Title]]`, etc.). Write the file back and commit.

---

## Shared Patterns

### Wiki-guard (apply at skill entry)

**Source:** `.claude/skills/sara-lint/SKILL.md` v1, lines 19–29

```bash
if [ ! -d "wiki" ]; then
  echo "No wiki found. Run /sara-init first."
  exit 1
fi
```

### Read/Write tools only for markdown files

**Source:** `.claude/skills/sara-lint/SKILL.md` v1, line 105; 13-CONTEXT.md `code_context`

Apply to: every step that reads or writes a wiki artifact page or `wiki/index.md`.

```
pipeline-state.json → Read tool only (never jq/sed/awk)
wiki/*.md files → Read and Write tools only
Bash is acceptable for: grep (read-only scan), git commands, find, ls
```

### Atomic per-fix commit (apply to every accepted fix)

**Source:** `.claude/skills/sara-update/SKILL.md`, lines 556–598; 13-CONTEXT.md D-09

```bash
git add {exact_file_path}
git commit -m "fix(wiki): {description} via sara-lint"
echo "EXIT:$?"
```

Never stage by directory glob. Never batch multiple fixes into one commit. Each fix is independently revertable.

### Per-finding AskUserQuestion (apply to every finding)

**Source:** 13-CONTEXT.md D-08; v1 lines 78–90

```
AskUserQuestion:
  header: "Lint finding [N of M]"
  question: "<plain-text issue description>\n\nProposed fix: <proposed change>"
  options: ["Apply", "Skip"]
```

### grep -rL / -rn scan

**Source:** `.claude/skills/sara-lint/SKILL.md` v1, lines 44–47

```bash
grep -rL "^field:" wiki/dir1/ wiki/dir2/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"
```

Always: pipe through `grep "\.md$"` and `grep -v "\.gitkeep"` to exclude non-artifact files.

### config.json segments read (for segments back-fill)

**Source:** `.claude/skills/sara-extract/SKILL.md`, lines 52–53

```
Read `.sara/config.json` using the Read tool. Store `config.segments` for use in
segments inference.
```

---

## No Analog Found

| Check | Role | Data Flow | Reason |
|-------|------|-----------|--------|
| Cross Links↔`related[]` sync (D-06) | body-section validator | transform | No existing check compares frontmatter arrays against body sections |
| Index↔disk bidirectional sync (D-05) | catalog validator | batch | No existing check audits the wiki index bidirectionally |
| Broken `related[]` ID resolution (D-03) | cross-reference validator | batch | No existing resolver checks whether related IDs map to real files |

These checks have no codebase analog. The planner should construct them from first principles, using the grep scan + per-finding loop structure as the outer shell, and the specific logic described in D-03/D-05/D-06 of 13-CONTEXT.md for the inner check logic.

---

## v2.0 Schema Reference (embedded for planner use)

Extracted from canonical CONTEXT files — the complete set of fields each entity type must have for a "clean" lint result:

### REQ (08-CONTEXT.md D-06/D-09)
```yaml
schema_version: '2.0'
type: functional|non-functional|regulatory|integration|business-rule|data
priority: must-have|should-have|could-have|wont-have
segments: []
```

### DEC (09-CONTEXT.md D-07/D-09)
```yaml
schema_version: '2.0'
type: architectural|process|tooling|data|business-rule|organisational
segments: []
```
Removed fields (flag if present on old pages): `context`, `decision`, `rationale`, `alternatives-considered`

### ACT (10-CONTEXT.md D-07/D-08/D-09/D-10)
```yaml
schema_version: '2.0'
type: deliverable|follow-up
owner: ""
due-date: ""
segments: []
```

### RSK (11-CONTEXT.md D-07/D-09/D-11)
```yaml
schema_version: '2.0'
type: technical|financial|schedule|quality|compliance|people
likelihood: ""   # low|medium|high or empty
impact: ""       # low|medium|high or empty
owner: ""
segments: []
```
Removed fields (flag if present on old pages): `mitigation` (frontmatter)

### STK (12-CONTEXT.md D-01)
```yaml
segment: ""      # renamed from vertical:
```
Note: `segments:` (plural) is NOT added to STK pages — only REQ/DEC/ACT/RSK get `segments:`. STK pages get the singular `segment:` field.

---

## Metadata

**Analog search scope:** `.claude/skills/` (all nine skills)
**Files scanned:** 4 (sara-lint v1, sara-update, sara-extract, plus canonical CONTEXT files for schema ground truth)
**Pattern extraction date:** 2026-04-30
