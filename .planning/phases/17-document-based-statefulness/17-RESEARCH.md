# Phase 17: document-based-statefulness - Research

**Researched:** 2026-05-01
**Domain:** Claude Code skill authoring, document-based pipeline state, filesystem-derived counters
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Directory structure: one folder per pipeline item**

`sara-ingest` creates `.sara/pipeline/{ID}/` for every new item. Example: `.sara/pipeline/MTG-001/`, `.sara/pipeline/EML-002/`.

The `.sara/pipeline/` directory replaces `.sara/pipeline-state.json` as the pipeline store. `sara-init` creates the directory; it does NOT create `pipeline-state.json`.

**D-02 — Three files per item directory**

Each item directory holds exactly three files, written progressively as the item advances:

| File | Written by | Contains |
|------|-----------|----------|
| `state.md` | `sara-ingest` | YAML frontmatter: id, type, filename, source_path, stage, created |
| `discuss.md` | `sara-discuss` | Markdown body: resolved blockers, stakeholder resolutions, discussion context |
| `plan.md` | `sara-extract` | Markdown body: proposed artifacts to create/update (human-readable, LLM-parsed) |

`state.md` frontmatter tracks the current stage field through its lifecycle:
`pending` → `extracting` → `approved` → `complete`

Stage advances are written to `state.md` by each command (same ordering constraint as the old JSON write: stage only advances AFTER the git commit succeeds).

**D-03 — Counters derived from filesystem at runtime**

No counter file. Commands that need the next ID derive it by:
- **Ingest counters (MTG, EML, SLK, DOC):** `ls .sara/pipeline/ | grep "^{TYPE_KEY}-" | sort | tail -1` — parse the numeric suffix from the last directory name, increment by 1.
- **Entity counters (REQ, DEC, ACT, RSK, STK):** `ls wiki/{type_dir}/ | sort | tail -1` — parse the numeric suffix from the last wiki page filename, increment by 1.

If no directories exist yet, start at 001.

**D-04 — Extraction plan: markdown body in plan.md**

`sara-extract` writes the approved plan as a human-readable markdown body in `plan.md`. No YAML frontmatter in plan.md — the markdown body is the artifact list. `sara-update` reads `plan.md` via the Read tool and uses LLM parsing to execute the plan.

`plan.md` describes each proposed artifact in enough detail for `sara-update` to act: entity type, action (create/update), title, field values. The markdown format is Claude-native — no additional structured format needed.

**D-05 — Migration: new repos only**

`sara-init` creates `.sara/pipeline/` (no `pipeline-state.json`). Existing repos with a `pipeline-state.json` are not automatically migrated — this phase documents the new schema in CLAUDE.md. Existing users would need to re-ingest pending items or manually create item directories from their JSON data.

MEET-01 (assigned_id not persisted in pipeline-state.json) is naturally rendered moot: `plan.md`'s markdown body describes the entities to create with their proposed IDs; `sara-minutes` reads `plan.md` directly to find the entity IDs, so no write-back is needed.

**D-06 — STATUS mode: glob .sara/pipeline/*/state.md**

`sara-ingest` with no arguments (STATUS mode) now globs `.sara/pipeline/*/state.md`, reads frontmatter from each, and renders the same table as before (ID, type, stage, source path). Empty pipeline directory = same "no items" message.

### Claude's Discretion

- Exact markdown structure for plan.md — how each artifact entry is formatted (table vs bullet list vs headed sections). Pick whatever is most reliably parseable by sara-update.
- Exact markdown structure for discuss.md — how stakeholder resolutions and comprehension blockers are presented. Consistent with existing sara-discuss output prose.
- Whether state.md has a minimal markdown body below the frontmatter (e.g. a `# {ID}` heading) or is frontmatter-only.
- Whether `.sara/pipeline-state.json` is explicitly deleted by sara-init or simply not created (preferred: not created — clean start).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

---

## Summary

Phase 17 is a pure internal refactor: six Claude Code SKILL.md files are rewritten to swap a monolithic `pipeline-state.json` for a directory-per-item structure at `.sara/pipeline/{ID}/`. Every external behaviour is preserved — same commands, same arguments, same output tables — but the state backend changes from a single JSON document to a set of markdown files on the filesystem.

The work is a straightforward mechanical edit of six skill files. There are no new external dependencies, no new algorithms, and no changes to the wiki, entity schemas, or lint checks. The difficulty is precision: each skill currently reads and writes `pipeline-state.json` in several places, and each of those sites must be replaced with a correct filesystem or markdown equivalent. The atomic-commit ordering invariant (stage only advances AFTER commit succeeds) must be preserved exactly.

The main design decision left to the implementer (Claude's Discretion) is the exact markdown format for `plan.md`. Research confirms that a headed-section-per-artifact approach — one `##` heading per artifact containing a field list — is the most robust pattern for LLM parsing: it requires no structured parsing, is human-readable, and is tolerant of whitespace variation. The `discuss.md` file follows the same prose-and-headings pattern already used in sara-discuss output.

**Primary recommendation:** Implement as six sequential SKILL.md rewrites. Treat each skill as independent. Preserve every invariant from the existing notes sections verbatim. Use the headed-section-per-artifact format for plan.md.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pipeline item registration | sara-ingest skill | Filesystem (.sara/pipeline/) | Ingest is the sole creator of item directories and state.md |
| Stage tracking | state.md frontmatter | Each pipeline skill (reads/writes) | Single document per item is the authoritative stage record |
| Discussion context storage | discuss.md | sara-discuss skill (writer), sara-extract (reader) | Document-based; passes context forward without loading JSON |
| Artifact plan storage | plan.md | sara-extract (writer), sara-update (reader) | LLM-native markdown avoids structured schema |
| Ingest counter derivation | Filesystem (.sara/pipeline/) | sara-ingest skill (Bash glob) | Runtime glob replaces JSON counter field |
| Entity counter derivation | Filesystem (wiki/{type}/) | sara-update skill (Bash glob) | Runtime glob replaces JSON counter field |
| Pipeline status display | sara-ingest STATUS mode | Filesystem glob of state.md files | Replaces pipeline-state.json items enumeration |
| Initialization | sara-init skill | Filesystem (.sara/pipeline/ dir) | Creates directory instead of pipeline-state.json |

---

## Standard Stack

No new external libraries are introduced. This phase rewrites Claude Code skills only.

### Core Tools (unchanged from existing skills)

| Tool | Purpose | In All Skills |
|------|---------|---------------|
| Read | Read markdown files (state.md, discuss.md, plan.md, source docs) | Yes |
| Write | Write markdown files | Yes |
| Bash | Filesystem glob for counters and STATUS mode; git operations | Yes |
| AskUserQuestion | Bounded choices (sara-discuss, sara-extract) | sara-discuss, sara-extract only |

**Installation:** None required. No new packages.

---

## Architecture Patterns

### System Architecture Diagram

```
/sara-ingest <type> <filename>
        │
        ├── Bash: derive next ID from .sara/pipeline/{TYPE_KEY}-* dirs
        ├── Bash: mv raw/input/{filename} → raw/{type}/{ID}-{filename}
        ├── Write: .sara/pipeline/{ID}/state.md  (stage: pending)
        └── Bash: git commit

/sara-discuss <ID>
        │
        ├── Read: .sara/pipeline/{ID}/state.md  (stage guard: pending)
        ├── Read: source file at state.md[source_path]
        ├── [blocker resolution loop]
        ├── Write: .sara/pipeline/{ID}/discuss.md
        ├── Write: .sara/pipeline/{ID}/state.md  (stage: extracting, AFTER commit)
        └── Bash: git commit

/sara-extract <ID>
        │
        ├── Read: .sara/pipeline/{ID}/state.md  (stage guard: extracting)
        ├── Read: .sara/pipeline/{ID}/discuss.md
        ├── Read: source file
        ├── [four inline extraction passes + sorter + approval loop]
        ├── Write: .sara/pipeline/{ID}/plan.md
        ├── Write: .sara/pipeline/{ID}/state.md  (stage: approved, AFTER commit)
        └── Bash: git commit

/sara-update <ID>
        │
        ├── Read: .sara/pipeline/{ID}/state.md  (stage guard: approved)
        ├── Read: .sara/pipeline/{ID}/plan.md  (LLM parses artifact list)
        ├── [for each artifact: derive entity ID from wiki/{type}/ glob]
        ├── [write wiki pages]
        ├── Bash: git commit
        └── Write: .sara/pipeline/{ID}/state.md  (stage: complete, ONLY after commit)

/sara-ingest (STATUS mode, no args)
        │
        ├── Bash: glob .sara/pipeline/*/state.md
        ├── Read: each state.md
        └── Output table (id, type, stage, source_path)

/sara-minutes <ID>
        │
        ├── Read: .sara/pipeline/{ID}/state.md  (type guard + stage guard)
        ├── Read: .sara/pipeline/{ID}/plan.md  (find entity IDs)
        └── Read: wiki pages for each entity in plan
```

### Recommended Project Structure

```
.sara/
├── config.json            # unchanged
├── templates/             # unchanged
└── pipeline/
    ├── MTG-001/
    │   ├── state.md       # YAML frontmatter: id, type, filename, source_path, stage, created
    │   ├── discuss.md     # written by sara-discuss (may not exist if discuss not yet run)
    │   └── plan.md        # written by sara-extract (may not exist if extract not yet run)
    ├── EML-001/
    │   └── state.md
    └── ...
```

### Pattern 1: state.md Frontmatter Schema

`state.md` is the authoritative record for one pipeline item. It is written by `sara-ingest` and updated (stage field only) by each subsequent command.

```markdown
---
id: MTG-001
type: meeting
filename: transcript-2026-04-27.md
source_path: raw/meetings/MTG-001-transcript-2026-04-27.md
stage: pending
created: 2026-04-27
---
```

Optional body: a single `# MTG-001` heading below the frontmatter is acceptable but not required. All commands read only the frontmatter.

**Stage field values:** `pending` → `extracting` → `approved` → `complete`

Stage is advanced by writing the entire state.md frontmatter block with the new stage value, then committing. The Write tool replaces the file; no in-place YAML editing is needed.

### Pattern 2: Filesystem Counter Derivation

Replacing `counters.ingest.MTG` and `counters.entity.REQ` etc. from JSON with runtime filesystem globs.

**Ingest counter (next MTG ID):**
```bash
# Returns the highest numeric suffix found, or empty if none
ls .sara/pipeline/ 2>/dev/null | grep "^MTG-" | sort | tail -1
# Example output: MTG-003
# Parse: split on "-", take last token "003", increment to 004
# If no output: start at 001
```

**Entity counter (next REQ ID):**
```bash
ls wiki/requirements/ 2>/dev/null | grep "^REQ-" | sort | tail -1
# Example output: REQ-007.md
# Parse: strip extension, split on "-", take last token "007", increment to 008
# If no output: start at 001
```

Zero-pad to 3 digits: `printf "%03d" $((num + 1))`

**Critical:** The entity counter derivation must happen inside `sara-update` before each `create` artifact is written. Since multiple artifacts can be written in a single run, the glob must account for pages written earlier in the same run (already on disk). The glob-then-increment approach naturally handles this because newly written pages appear immediately in the directory.

### Pattern 3: discuss.md Format

`discuss.md` is written by `sara-discuss`. It is a prose markdown document containing the resolved discussion context. No frontmatter. Format example:

```markdown
## Resolved Stakeholders

- Alice Wang → STK-002 (segment: Residential, role: Product Manager)
- Raj Patel → STK-003 (nickname: "Raj", segment: Enterprise)

## Source Comprehension Clarifications

- "SalesForce" refers to the CRM system used by the Sales department, not a vendor contact.
- "the new platform" = the Project Atlas initiative discussed in MTG-001.
```

`sara-extract` reads this file and uses it as the `{discussion_notes}` context, replacing the JSON `discussion_notes` field.

### Pattern 4: plan.md Format (Claude's Discretion Resolution)

`plan.md` is written by `sara-extract` and read by `sara-update` via LLM parsing. The headed-section-per-artifact format is recommended: one `##` heading per artifact, each containing a field list. This is reliably parseable by an LLM reader, human-readable, and tolerant of minor formatting variation.

```markdown
## Artifact 1 — CREATE requirement

**Type:** requirement
**Title:** API rate limiting per tenant
**Action:** create
**Req type:** functional
**Priority:** must-have
**Source quote:** "we must implement rate limiting for each tenant"
**Raised by:** STK-001
**Segments:** [Residential, Enterprise]
**Related:** []

---

## Artifact 2 — UPDATE decision DEC-003

**Type:** decision
**Title:** Auth token expiry policy
**Action:** update
**Existing ID:** DEC-003
**Dec type:** architectural
**Status:** accepted
**Chosen option:** 24-hour expiry with refresh tokens
**Change summary:** Updated to reflect alignment reached in this meeting
**Source quote:** "we agreed on 24-hour token expiry"
**Raised by:** STK-002
**Segments:** [Enterprise]
**Related:** [REQ-005]
```

`sara-update` reads `plan.md` with the Read tool, then uses LLM reasoning to iterate over artifact sections and execute each one. No regex parsing is needed — the LLM reads the document as a human would.

**Note on entity IDs in plan.md:** `sara-extract` writes placeholder IDs (`REQ-NNN`, `DEC-NNN`) for create artifacts in plan.md — the actual IDs are assigned at write time by `sara-update` using the filesystem counter derivation. For update artifacts, the real existing ID (e.g. `DEC-003`) is written directly.

### Pattern 5: Stage Guard (Unchanged Logic, New Read Mechanism)

Every pipeline skill guards its entry by checking the `stage` field in `state.md`. The guard logic is identical to the old JSON check; only the read mechanism changes.

Old (JSON): `items["{N}"].stage`
New (markdown): Read `.sara/pipeline/{ID}/state.md`, parse YAML frontmatter, check `stage:` field

```
Read .sara/pipeline/{ID}/state.md
Parse frontmatter
If stage != "expected_stage":
  Output error with current stage and correct next command
  STOP
```

If `.sara/pipeline/{ID}/state.md` does not exist: output item-not-found error (equivalent to the old "key not in items" path).

### Pattern 6: sara-minutes plan.md Entity ID Discovery

`sara-minutes` previously used `items["{N}"].extraction_plan` to find entity IDs. Under the new schema, it reads `plan.md` and uses LLM parsing to extract the entity IDs listed as artifact sections.

For create artifacts: the ID is the placeholder (`REQ-NNN`) — but by the time `sara-minutes` runs (stage=complete), the plan has been executed. `sara-minutes` should derive actual entity IDs by cross-referencing `wiki/log.md` (which records which IDs were written for each ingest ID) or by reading the plan.md and noting the action=create artifacts, then looking up the actual IDs from wiki/index.md filtered by source=this ingest ID.

**Simpler approach (recommended):** `sara-minutes` reads `plan.md` to understand what was planned, then reads `wiki/log.md` to find the actual entity IDs committed for this ingest ID. The log row format already records `[[{item.id}]] | date | type | filename | [[REQ-001]], [[DEC-002]], ...` — the IDs are directly available there.

### Pattern 7: CLAUDE.md Update (sara-init output)

`sara-init` generates a `CLAUDE.md` for the target project. The behavioral rules section currently references `.sara/pipeline-state.json` for counter management and `summary_max_words`. Under the new schema:

- Rule 4 (ID assignment): replace "increment the relevant counter in `.sara/pipeline-state.json`" with "derive the next ID by listing the relevant wiki directory and incrementing the highest existing numeric suffix".
- `summary_max_words`: this config value currently lives in `pipeline-state.json`. Under the new schema it should move to `.sara/config.json` (or a hardcoded default of 50 if absent). This is a small side concern — the planner should include a task to move this field.

### Anti-Patterns to Avoid

- **Reading discuss.md as JSON:** `discuss.md` is markdown prose. Any attempt to parse it as structured data will fail. `sara-extract` reads it as a plain text document and reasons about it with LLM judgment.
- **Advancing stage before commit:** The atomic-commit invariant from the old pipeline must be preserved. Stage is written to `state.md` only after `git commit` succeeds. Writing state before commit creates an unrecoverable stuck-item scenario (same as the original Pitfall 1).
- **In-place YAML editing with Bash:** The pattern for updating `state.md` is Read → modify frontmatter in LLM memory → Write the full file. Never use `sed` or `awk` on markdown frontmatter. (Same rule as the old JSON: Read+Write tools only for markdown files.)
- **Re-reading state.md inside entity write loop:** During `sara-update`'s entity write loop, do not re-read state.md between artifacts. The stage advance happens once, after all writes succeed and after the commit.
- **Globbing for entity IDs with `.gitkeep` present:** The `ls wiki/requirements/` output may include `.gitkeep` files. The grep filter `grep "^REQ-"` naturally excludes them, but the pattern should be explicit.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML frontmatter parsing | Custom regex/sed | LLM Read-then-reason | The skills are LLM-executed; the LLM parses YAML natively from the Read tool output |
| Structured plan.md schema | JSON-in-markdown hybrid | Headed sections (Claude's Discretion Pattern 4) | LLM parsing is more robust than rigid schema; sara-update is already an LLM |
| Counter persistence file | New counters.json | Filesystem glob (D-03) | No file to get out of sync; derivation is always correct |
| Migration utility | sara-migrate command | Not in scope (D-05) | Deferred — new repos only |

---

## Runtime State Inventory

This phase renames the state backend. Below is the complete runtime state audit.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.sara/pipeline-state.json` — existing SARA project repos carry this file with item state, counter values, and `summary_max_words` | Code edit only (new schema); existing file untouched (D-05: new repos only) |
| Live service config | None — SARA has no external service dependencies | None |
| OS-registered state | None — no cron jobs, task scheduler entries, or daemon registrations | None |
| Secrets/env vars | None — no env vars reference pipeline-state.json by name | None |
| Build artifacts | None — no compiled artifacts; skills are markdown files | None |

**`summary_max_words` field:** Currently stored in `pipeline-state.json` as a top-level key. Under the new schema, this should move to `.sara/config.json`. The planner must include a task to: (1) add `summary_max_words` to the `config.json` template in `sara-init`, (2) update `sara-update` to read from `config.json` instead, (3) update `CLAUDE.md` generation in `sara-init` to reference `config.json`.

**CLAUDE.md behavioral rule 4 (ID assignment):** The CLAUDE.md generated by `sara-init` currently instructs Claude to "increment the relevant counter in `.sara/pipeline-state.json`". This is project-level documentation that will be outdated for new repos. The `sara-init` SKILL.md template must be updated to emit the filesystem-derivation instruction instead.

---

## Common Pitfalls

### Pitfall 1: Stage Advance Before Commit
**What goes wrong:** `state.md` is written with `stage: approved` before the git commit runs. If the commit fails, the item is stuck — sara-extract cannot re-run because the stage guard sees `approved`, not `extracting`.
**Why it happens:** Writing state before committing feels natural; the old JSON had the same trap.
**How to avoid:** Always sequence: (1) do work, (2) git commit, (3) if commit succeeds: write updated state.md, (4) if commit fails: output error, leave state.md unchanged.
**Warning signs:** If stage is written in the same step as the work output, it is in the wrong order.

### Pitfall 2: entity write loop re-reads state.md
**What goes wrong:** `sara-update` re-reads `state.md` inside the per-artifact loop to check something, accidentally overwriting the in-memory artifact list or losing track of written files.
**Why it happens:** Over-caution about reading fresh state.
**How to avoid:** Read state.md once at Step 1. Don't re-read inside the loop. Write state.md (stage=complete) once, after the commit.

### Pitfall 3: Counter Derivation Race on Multi-Artifact Writes
**What goes wrong:** `sara-update` derives entity ID for artifact 1 (REQ-001), writes the page, then derives entity ID for artifact 2 — but the glob runs before the first page is flushed, and returns REQ-001 again.
**Why it happens:** The glob-then-increment assumes the previous page is on disk.
**How to avoid:** The Write tool is synchronous; pages are written immediately. The next glob will see the newly written page. No race exists — the concern is theoretical. Document this explicitly in the notes section of the skill.

### Pitfall 4: Missing .sara/pipeline/ directory at first ingest
**What goes wrong:** The first `sara-ingest` call tries to create `.sara/pipeline/MTG-001/` but `.sara/pipeline/` does not exist.
**Why it happens:** `sara-init` creates the directory, but if a user skips `sara-init` or the dir was deleted, the parent is absent.
**How to avoid:** `sara-ingest` uses `mkdir -p .sara/pipeline/{ID}/` — the `-p` flag creates all parent directories.

### Pitfall 5: STATUS mode reads state.md frontmatter with LLM vs Bash
**What goes wrong:** STATUS mode reads each `state.md` with the Read tool individually in a loop. For large pipelines (50+ items) this exhausts context.
**Why it happens:** Treating each state.md as a full document instead of a small frontmatter block.
**How to avoid:** STATUS mode uses `grep -rh "^stage:\|^type:\|^source_path:\|^id:" .sara/pipeline/*/state.md` to extract all fields efficiently, then formats the table from grep output — no per-file Read tool calls. This is consistent with how `sara-lint` and `sara-discuss` already use grep for bulk field extraction.

### Pitfall 6: discuss.md missing when sara-extract runs
**What goes wrong:** `sara-extract` tries to read `discuss.md` but the file does not exist (user skipped discuss or it was not committed).
**Why it happens:** `discuss.md` is only written by `sara-discuss`; it is not created by `sara-ingest`.
**How to avoid:** `sara-extract` reads `discuss.md` with the Read tool; if the file is absent (Read returns error), treat `{discussion_notes}` as empty string — continue without error. The stage guard (state must be `extracting`) ensures `sara-discuss` ran, but `discuss.md` could still be missing if a previous discuss session failed mid-write. Graceful empty-string fallback is correct behavior.

### Pitfall 7: sara-minutes entity ID discovery from plan.md
**What goes wrong:** `sara-minutes` reads `plan.md` and tries to use the placeholder IDs (`REQ-NNN`) as actual entity IDs. These are not real wiki IDs; they were resolved during `sara-update`.
**Why it happens:** plan.md is written before IDs are assigned; placeholders remain in the file.
**How to avoid:** `sara-minutes` uses `wiki/log.md` as the authoritative source of actual entity IDs written for each ingest item. The log row for `MTG-001` contains the real IDs (`[[REQ-001]]`, `[[DEC-002]]`). Read the log, extract the IDs, then read the corresponding wiki pages.

---

## Code Examples

### Counter Derivation (sara-ingest, new ID)

```bash
# Derive next MTG ID
LAST=$(ls .sara/pipeline/ 2>/dev/null | grep "^MTG-" | sort | tail -1)
if [ -z "$LAST" ]; then
  NEXT="MTG-001"
else
  NUM=$(echo "$LAST" | sed 's/MTG-//')
  NEXT="MTG-$(printf '%03d' $((10#$NUM + 1)))"
fi
echo "$NEXT"
```

### Counter Derivation (sara-update, entity IDs)

```bash
# Derive next REQ ID
LAST=$(ls wiki/requirements/ 2>/dev/null | grep "^REQ-" | sort | tail -1)
if [ -z "$LAST" ]; then
  NEXT="REQ-001"
else
  NUM=$(echo "$LAST" | sed 's/REQ-//' | sed 's/\.md//')
  NEXT="REQ-$(printf '%03d' $((10#$NUM + 1)))"
fi
echo "$NEXT"
```

### STATUS Mode Bulk Grep (sara-ingest, no-args)

```bash
# Extract fields from all state.md files without reading each individually
grep -rh "^\(id\|type\|stage\|source_path\):" .sara/pipeline/*/state.md 2>/dev/null
```

### state.md Write Pattern

```markdown
---
id: MTG-001
type: meeting
filename: transcript-2026-04-27.md
source_path: raw/meetings/MTG-001-transcript-2026-04-27.md
stage: pending
created: 2026-04-27
---
```

The skill writes this complete block with the Write tool. No partial update. When advancing stage, the skill reads the current state.md, modifies `stage:` in LLM memory, and writes the full file back.

### Item Directory Creation (sara-ingest)

```bash
mkdir -p ".sara/pipeline/{new_id}/"
```

### STATUS Mode Guard (no items)

```bash
if [ -z "$(ls .sara/pipeline/ 2>/dev/null)" ]; then
  echo "No pipeline items registered."
  exit 0
fi
```

---

## Skill-by-Skill Change Map

This table maps each SKILL.md to the specific changes required. The planner should create one plan per skill (6 plans total).

### sara-init

| Current Behaviour | New Behaviour |
|-------------------|---------------|
| Step 7: Write `.sara/pipeline-state.json` with counters + empty items | Step 7: Create `.sara/pipeline/` directory with a `.gitkeep`; do NOT write pipeline-state.json |
| Step 9 (CLAUDE.md): Rule 4 says "increment counter in pipeline-state.json" | Update Rule 4 to say "derive next ID by listing the relevant wiki directory and incrementing the highest existing numeric suffix" |
| Step 9 (CLAUDE.md): Rule 6 references `summary_max_words` from pipeline-state.json | Update to reference `summary_max_words` from `.sara/config.json` (default 50 if absent) |
| Step 6: Writes config.json without summary_max_words | Add `"summary_max_words": 50` to config.json template |
| Step 13 (success report): lists `.sara/pipeline-state.json` | Replace with `.sara/pipeline/` |
| Step 14 (git add): includes `.sara/pipeline-state.json` | Replace with `.sara/pipeline/.gitkeep` |

### sara-ingest

| Current Behaviour | New Behaviour |
|-------------------|---------------|
| INGEST Step 3: Read pipeline-state.json, increment counter, add to items{}, Write JSON | Read pipeline-state.json removed. Derive {new_id} via Bash glob of .sara/pipeline/. Create `.sara/pipeline/{new_id}/` directory. Write `.sara/pipeline/{new_id}/state.md` with frontmatter. |
| INGEST Step 4: git add includes `.sara/pipeline-state.json` | git add includes `.sara/pipeline/{new_id}/state.md` and moved source file |
| STATUS Step 6: Read pipeline-state.json, iterate items{} | Bash glob `.sara/pipeline/*/state.md`, extract frontmatter fields, build table |
| Objective text references pipeline-state.json | Update objective text |
| Notes section: pipeline-state.json read-modify-write notes | Replace with state.md write notes |

### sara-discuss

| Current Behaviour | New Behaviour |
|-------------------|---------------|
| Step 1: Read pipeline-state.json, find `items["{N}"]`, check stage | Read `.sara/pipeline/{N}/state.md`, parse frontmatter, check `stage:` field. If file missing: item-not-found error. |
| Step 2: Load source from `item.source_path` (from JSON) | Load source from `state.md` frontmatter `source_path:` field |
| Step 6: Read pipeline-state.json; update `items["{N}"].discussion_notes` and `stage`; Write JSON | Write `.sara/pipeline/{N}/discuss.md` with markdown prose. Then write `.sara/pipeline/{N}/state.md` with `stage: extracting` (AFTER commit). |
| Step 6: Commit includes `.sara/pipeline-state.json` | Commit includes `.sara/pipeline/{N}/discuss.md` and updated `state.md` |
| Notes: references pipeline-state.json | Update to reference state.md and discuss.md |

### sara-extract

| Current Behaviour | New Behaviour |
|-------------------|---------------|
| Step 1: Read pipeline-state.json, find item, check stage `extracting` | Read `.sara/pipeline/{N}/state.md`, check `stage: extracting` |
| Step 2: `{discussion_notes}` = `items["{N}"].discussion_notes` from JSON | Read `.sara/pipeline/{N}/discuss.md`. If absent: `{discussion_notes}` = "" |
| Step 5: Write `extraction_plan` array to pipeline-state.json; set `stage: approved` | Write `.sara/pipeline/{N}/plan.md` (headed markdown body). Write `.sara/pipeline/{N}/state.md` with `stage: approved` (AFTER commit). |
| Step 5: Commit includes pipeline-state.json | Commit includes `.sara/pipeline/{N}/plan.md` and updated `state.md` |
| Notes: references pipeline-state.json | Update to reference plan.md and state.md |

### sara-update

| Current Behaviour | New Behaviour |
|-------------------|---------------|
| Step 1: Read pipeline-state.json, find item, check stage `approved` | Read `.sara/pipeline/{N}/state.md`, check `stage: approved` |
| Step 1: `{extraction_plan}` = `items["{N}"].extraction_plan` (JSON array) | Read `.sara/pipeline/{N}/plan.md`. LLM parses artifact sections from markdown body. |
| Step 1b: `{discussion_notes}` from JSON field | Read `.sara/pipeline/{N}/discuss.md`. If absent: empty string. |
| Step 2 (entity IDs): increment `counters.entity.{type_key}` in JSON; write JSON before each page | Derive entity ID from Bash glob of `wiki/{type_dir}/`; no JSON write between pages |
| Step 2: `summary_max_words` read from pipeline-state.json | Read `summary_max_words` from `.sara/config.json` (default 50 if absent) |
| Step 4: Read pipeline-state.json; write `stage: complete` to JSON | Write `.sara/pipeline/{N}/state.md` with `stage: complete` (ONLY after commit succeeds) |
| Step 4: git add includes pipeline-state.json | git add includes `.sara/pipeline/{N}/state.md` |
| Notes: references pipeline-state.json | Update to reference state.md, discuss.md, plan.md |

### sara-minutes

| Current Behaviour | New Behaviour |
|-------------------|---------------|
| Step 1: Read pipeline-state.json, find item, check type=meeting, check stage=complete | Read `.sara/pipeline/{N}/state.md`. If missing: item-not-found. Check `type: meeting`. Check `stage: complete`. |
| Step 2: `{extraction_plan}` = `items["{N}"].extraction_plan` (JSON array with assigned_id and existing_id) | Read `wiki/log.md` to find actual entity IDs committed for ingest ID `{N}`. Parse the log row for this item. Use those IDs to read wiki pages. |
| Notes: references pipeline-state.json | Update to reference state.md and wiki/log.md |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `pipeline-state.json` single file | `.sara/pipeline/{ID}/` directory-per-item | Phase 17 | Removes JSON parse overhead; makes state human-readable; mirrors GSD pattern |
| JSON counters | Filesystem glob derivation | Phase 17 | No counter drift; no state file to corrupt |
| `discussion_notes` JSON string | `discuss.md` markdown file | Phase 17 | Human-readable; persistent as a real document |
| `extraction_plan` JSON array | `plan.md` markdown document | Phase 17 | LLM-native; MEET-01 bug resolved naturally |

**Resolved technical debt:**
- MEET-01: `assigned_id` not persisted in `extraction_plan` — resolved. `sara-minutes` now reads `wiki/log.md` for actual IDs; no write-back to plan.md needed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `wiki/log.md` rows contain entity IDs in a parseable format (`[[REQ-001]]` wikilinks) for sara-minutes to use | Skill-by-Skill Change Map (sara-minutes) | sara-minutes would need an alternate entity discovery strategy; low risk — log format is confirmed in sara-update Step 3 |
| A2 | The Write tool is synchronous and pages written in the entity loop are immediately visible to subsequent Bash globs in the same skill run | Code Examples (counter derivation) | Counter duplication possible if async; low risk — Write tool is local filesystem write |

**All other claims are VERIFIED by reading the six SKILL.md files directly in this session.**

---

## Open Questions

1. **summary_max_words migration for existing repos**
   - What we know: `summary_max_words` is currently in `pipeline-state.json` (value: 50). sara-update reads it from there. Under the new schema it should move to `config.json`.
   - What's unclear: Should `sara-update` maintain a fallback that reads from `config.json` OR from a top-level `.sara/pipeline-state.json` if it still exists (for compatibility)? D-05 says existing repos are not migrated — so the answer is no. Just read from config.json with a default of 50.
   - Recommendation: Move `summary_max_words` to `config.json` template in `sara-init`. `sara-update` reads from `config.json`, default 50. No backward compatibility needed per D-05.

2. **Whether to keep a .gitkeep inside .sara/pipeline/**
   - What we know: sara-init uses `.gitkeep` files to track empty directories in git. The `.sara/pipeline/` directory is initially empty.
   - What's unclear: Should `.gitkeep` be added inside `.sara/pipeline/`?
   - Recommendation: Yes — add `.sara/pipeline/.gitkeep` so the directory is tracked in git from init. When the first item is ingested, the item directory is created alongside it. git automatically tracks the new subdirectory.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely SKILL.md file edits. No external dependencies beyond the existing Bash, git, Read, Write tools already used by all skills.

---

## Validation Architecture

`nyquist_validation` is enabled (absent from config = enabled).

### Test Framework

No automated test framework exists in this project. SARA skills are Claude Code slash commands — they are markdown instruction files executed by Claude Code, not runnable code. Validation is manual UAT (human-run slash commands against a test repo).

| Property | Value |
|----------|-------|
| Framework | None (manual UAT only) |
| Config file | None |
| Quick run command | Manual: run `/sara-ingest meeting test.md` in a fresh repo |
| Full suite command | Manual: run full pipeline MTG-001 through all stages |

### Phase Requirements → Test Map

Phase 17 has no formal requirement IDs (TBD per objective). Behavioral coverage maps to the six skill rewrites:

| Behaviour | Test Type | Command |
|-----------|-----------|---------|
| sara-init creates .sara/pipeline/ not pipeline-state.json | manual-UAT | `/sara-init` in fresh dir, verify dir created |
| sara-ingest creates item directory + state.md | manual-UAT | `/sara-ingest meeting test.md` |
| sara-ingest STATUS mode reads state.md files | manual-UAT | `/sara-ingest` with no args after ingesting |
| sara-discuss writes discuss.md, advances stage | manual-UAT | `/sara-discuss MTG-001` |
| sara-extract writes plan.md, advances stage | manual-UAT | `/sara-extract MTG-001` |
| sara-update reads plan.md, writes wiki, advances stage | manual-UAT | `/sara-update MTG-001` |
| sara-minutes reads state.md + log.md for entity IDs | manual-UAT | `/sara-minutes MTG-001` |

### Wave 0 Gaps

None — no test framework to create. Validation is manual UAT only.

---

## Security Domain

This phase makes no changes to authentication, access control, input validation, or cryptography. The only changes are to internal file paths and state representation. Security domain: not applicable.

---

## Sources

### Primary (HIGH confidence)

- `.claude/skills/sara-init/SKILL.md` — current Step 7 (pipeline-state.json creation), Step 9 (CLAUDE.md template), Step 14 (git add list) — read in this session
- `.claude/skills/sara-ingest/SKILL.md` — current Steps 3-6 (JSON read/write, STATUS mode) — read in this session
- `.claude/skills/sara-discuss/SKILL.md` — current Steps 1, 2, 6 (JSON stage guard, discussion_notes) — read in this session
- `.claude/skills/sara-extract/SKILL.md` — current Steps 1, 2, 5 (JSON stage guard, extraction_plan write) — read in this session
- `.claude/skills/sara-update/SKILL.md` — current Steps 1, 2, 4 (JSON stage guard, entity counter increment, stage advance) — read in this session
- `.claude/skills/sara-minutes/SKILL.md` — current Steps 1, 2 (JSON lookup, extraction_plan read) — read in this session
- `.planning/phases/17-document-based-statefulness/17-CONTEXT.md` — all locked decisions D-01 through D-06 — read in this session
- `.planning/phases/17-document-based-statefulness/17-DISCUSSION-LOG.md` — decision rationale — read in this session
- `.planning/phases/02-ingest-pipeline/02-RESEARCH.md` — original pipeline design rationale — read in this session

### Secondary (MEDIUM confidence)

- GSD phase directory pattern (`.planning/phases/NN-name/` with multiple files) — observed directly in `.planning/phases/16-tagging/` and `.planning/phases/15-lint-repair/` — read in this session

---

## Metadata

**Confidence breakdown:**
- Change map per skill: HIGH — derived directly from reading each SKILL.md
- plan.md format recommendation: HIGH — based on established LLM-parsing patterns in existing skills
- sara-minutes entity ID strategy: HIGH — wiki/log.md format confirmed in sara-update Step 3
- Pitfalls: HIGH — derived from existing skill notes sections and prior phase research

**Research date:** 2026-05-01
**Valid until:** Stable — no external dependencies; SKILL.md files are the authoritative source
