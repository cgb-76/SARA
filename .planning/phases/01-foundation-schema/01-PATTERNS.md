# Phase 1: Foundation & Schema - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 10 (1 primary skill + 9 content files created by the skill)
**Analogs found:** 8 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-init/SKILL.md` | skill | request-response | `/home/george/.claude/skills/gsd-thread/SKILL.md` | exact — self-contained inline process, Write + Bash, no workflow delegation |
| `.sara/config.json` | config | file-I/O | `/home/george/.claude/get-shit-done/workflows/new-project.md` (config.json creation step) | role-match — JSON config written during project init |
| `pipeline-state.json` | state | file-I/O | no close analog — greenfield JSON state store | none |
| `wiki/CLAUDE.md` | config / schema contract | file-I/O | `/home/george/.claude/get-shit-done/templates/claude-md.md` (if exists) | partial — CLAUDE.md as behavioral ruleset is a Claude Code convention, not a GSD pattern |
| `wiki/index.md` | catalog stub | file-I/O | `/home/george/.claude/skills/gsd-thread/SKILL.md` mode_create step (thread stub creation) | role-match — structured stub file with frontmatter + header |
| `wiki/log.md` | append-only log stub | file-I/O | `/home/george/.claude/skills/gsd-thread/SKILL.md` mode_create step | role-match — stub markdown file with frontmatter |
| `.sara/templates/requirement.md` | template | file-I/O | RESEARCH.md code examples (WIKI-01 spec) | exact spec — no codebase analog; use RESEARCH.md template verbatim |
| `.sara/templates/decision.md` | template | file-I/O | RESEARCH.md code examples (WIKI-02 spec) | exact spec |
| `.sara/templates/action.md` | template | file-I/O | RESEARCH.md code examples (WIKI-03 spec) | exact spec |
| `.sara/templates/risk.md` | template | file-I/O | RESEARCH.md code examples (WIKI-04 spec) | exact spec |
| `.sara/templates/stakeholder.md` | template | file-I/O | RESEARCH.md code examples (WIKI-05 spec) | exact spec |

---

## Pattern Assignments

### `.claude/skills/sara-init/SKILL.md` (skill, request-response)

**Analog:** `/home/george/.claude/skills/gsd-thread/SKILL.md`

**Why this analog:** `gsd-thread` is the strongest match because it is a fully self-contained skill — the `<process>` block contains all logic inline with no `@workflow.md` delegation. It uses Write for file creation, Bash for directory operations and guard-style checks, and has clearly sequenced mode sections. `sara-init` follows the same pattern: one linear sequence with a guard clause at the top, then a series of Write calls.

**Frontmatter pattern** (gsd-thread lines 1–9):
```yaml
---
name: gsd-thread
description: "Manage persistent context threads for cross-session work"
argument-hint: "[list [--open | --resolved] | close <slug> | status <slug> | name | description]"
allowed-tools:
  - Read
  - Write
  - Bash
---
```

For `sara-init`, the frontmatter must be:
```yaml
---
name: sara-init
description: "Initialise a new SARA wiki in the current directory"
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```

`AskUserQuestion` must appear in `allowed-tools` for TUI prompts to work. `argument-hint` is empty because this skill takes no arguments. Pattern confirmed by `gsd-new-project/SKILL.md` lines 1–11 and `gsd-new-workspace/SKILL.md` lines 1–10.

**Objective block pattern** (gsd-thread lines 11–17):
```
<objective>
Create, list, close, or resume persistent context threads. Threads are lightweight
cross-session knowledge stores for work that spans multiple sessions but
doesn't belong to any specific phase.
</objective>
```

Write a concise `<objective>` that states what the skill creates. No flags, no routing logic needed for `sara-init` (it has no subcommands).

**Guard clause pattern** (gsd-thread `<mode_list>`, ls check at line 38):
```bash
ls .planning/threads/*.md 2>/dev/null
```

For `sara-init`, adapt to directory existence check:
```bash
if [ -d "wiki" ]; then
  echo "Error: A SARA wiki already exists in this directory (wiki/ found). Aborting."
  exit 1
fi
```

Place this as the very first step in `<process>`, before any `AskUserQuestion` calls. RESEARCH.md Pattern 3 confirms this is the correct POSIX idiom.

**Inline process structure** (gsd-thread lines 20–210 — full `<process>` block):

The `<process>` block uses numbered steps (or sequential mode sections) as plain prose with embedded code fences for Bash commands and Write content. For `sara-init`, the structure should be:

```
<process>

**Step 1 — Guard clause**
[bash block: check wiki/ directory]

**Step 2 — Collect user input**
[AskUserQuestion calls for project name, verticals, departments]

**Step 3 — Create directory tree**
[bash block: mkdir -p]

**Step 4 — Write config files**
[Write: .sara/config.json]
[Write: pipeline-state.json]

**Step 5 — Write wiki files**
[Write: wiki/CLAUDE.md]
[Write: wiki/index.md]
[Write: wiki/log.md]

**Step 6 — Write entity templates**
[Write: .sara/templates/requirement.md]
[Write: .sara/templates/decision.md]
[Write: .sara/templates/action.md]
[Write: .sara/templates/risk.md]
[Write: .sara/templates/stakeholder.md]

**Step 7 — Report success**
[plain text output listing all created files]

</process>
```

**File creation pattern** (gsd-thread `<mode_create>` step 3, lines 159–187):

```
3. Use the Write tool to create `.planning/threads/{SLUG}.md` with this content:

```
---
slug: {SLUG}
title: {description}
status: open
...
---
```
```

Adopt this exact pattern: describe the Write call in prose, then include the complete file content as a fenced block. Interpolated values (project name, verticals array, departments array) are noted with `{placeholder}` or `{{placeholder}}` notation in the prose description, then filled at runtime by Claude executing the skill.

**Directory creation pattern** (gsd-thread `<mode_create>` step 2, line 161):
```bash
mkdir -p .planning/threads
```

For `sara-init`, scale to a single multi-target call:
```bash
mkdir -p \
  raw/input \
  raw/meetings \
  raw/emails \
  raw/slack \
  raw/documents \
  wiki/requirements \
  wiki/decisions \
  wiki/actions \
  wiki/risks \
  wiki/stakeholders \
  .sara/templates
```

**Notes block pattern** (gsd-thread lines 212–228):
```
<notes>
- Threads are NOT phase-scoped — they exist independently of the roadmap
- ...
</notes>
```

Include a `<notes>` section at the end of `sara-init` covering: partial-init recovery (delete wiki/ and re-run), that git commit is not performed by the skill, and the CLAUDE.md scoping constraint (only active in wiki/ subtree sessions).

---

### `wiki/index.md` and `wiki/log.md` (catalog stub, file-I/O)

**Analog:** `gsd-thread/SKILL.md` `<mode_create>` section (lines 159–187) for the stub file pattern.

**Stub file pattern with frontmatter** (gsd-thread lines 163–187):
```
---
slug: {SLUG}
title: {description}
status: open
created: {today ISO date}
updated: {today ISO date}
---

# Thread: {description}

## Goal
...

## Next Steps

- *(add links, file paths, or issue numbers)*
```

Apply the same structure to `wiki/index.md`:
```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Index

| ID | Title | Status | Type | Tags | Last Updated |
|----|-------|--------|------|------|--------------|
```

And `wiki/log.md`:
```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Log

<!-- Append-only. Each entry: ingest ID, date, type, filename, entities created/updated -->
```

Rationale: stub headers provide Phase 2 skills a format fingerprint without requiring parsing of an empty file. Matches RESEARCH.md Code Examples for WIKI-06 and WIKI-07.

---

### `.sara/config.json` (config, file-I/O)

**Analog:** `gsd-new-project/SKILL.md` references `@$HOME/.claude/get-shit-done/templates/config.json` (line 42). Content is fully specified by D-05.

**No direct code analog** — the JSON structure is entirely locked by CONTEXT.md D-05. The Write call in the skill body should produce:

```json
{
  "project": "{project_name}",
  "verticals": {verticals_json_array},
  "departments": {departments_json_array},
  "schema_version": "1.0"
}
```

Where `{verticals_json_array}` and `{departments_json_array}` are the user's comma-separated inputs parsed at runtime into JSON arrays (e.g., `["Residential", "Enterprise", "Wholesale"]`).

---

### `.sara/templates/*.md` — Five Entity Templates (template, file-I/O)

**Analog:** RESEARCH.md Code Examples section (lines 429–549) — these are fully specified templates. No closer codebase analog exists.

All five templates follow the **annotated frontmatter pattern** (RESEARCH.md Pattern 4):
- YAML fields with inline comments showing allowed values
- `schema_version: "1.0"` always quoted (avoids Obsidian float parse)
- `related: []` using entity IDs, never file paths or wiki-links
- `tags: []` as empty array

The five templates are written verbatim from RESEARCH.md Code Examples. Each template Write call in the skill body includes the complete file content inline as a fenced block — no variable interpolation needed (templates use `REQ-000`, `DEC-000` etc. as placeholder IDs).

---

### `wiki/CLAUDE.md` (schema contract / behavioral rules, file-I/O)

**Analog:** No direct codebase analog. CLAUDE.md as a behavioral ruleset is a Claude Code convention established by D-12 through D-14.

**Pattern source:** RESEARCH.md Code Examples, "wiki/CLAUDE.md Opening Section" (lines 584–602).

The file has two sections:
1. **Behavioral rules** — five numbered imperative rules (dedup check, index update, log update, counter increment, cross-reference format)
2. **Entity schemas** — one fenced code block per entity type showing complete annotated frontmatter + body section headings (identical content to the templates in `.sara/templates/`)

The project name from user input is interpolated into the file header:
```markdown
# SARA Wiki — Schema & Behavioral Rules

**Project:** {project_name}
**Schema version:** 1.0

This file is automatically loaded by Claude Code when working in any file under `wiki/`.
All SARA pipeline commands must follow the rules in this file.
```

---

## AskUserQuestion Pattern

**Source:** `/home/george/.claude/get-shit-done/references/questioning.md` lines 69–101 and RESEARCH.md Pattern 2.

**Apply to:** The three user input steps in `sara-init`.

**Hard constraint:** Option headers must be 12 characters or fewer (hard limit — validation will reject longer headers). Confirmed at questioning.md line 82.

**Freeform rule:** If user selects an option indicating they want to explain freely ("Let me explain", "My own list", etc.), follow up with plain text — NOT another `AskUserQuestion`. Confirmed at questioning.md lines 103–118.

**Pattern for collecting a list:**
```
AskUserQuestion with:
  header: "Verticals"    ← max 12 chars
  question: "List the market verticals for this project, separated by commas"
  options: ["Residential, Enterprise, Wholesale", "My own list", "Skip for now"]
```

After user responds: split on commas, trim whitespace, filter empty strings, format as JSON array.

**Three prompts for sara-init:**
1. Project name (short free-text — can use AskUserQuestion with placeholder options or plain prose question)
2. Verticals (comma-separated list)
3. Departments (comma-separated list)

These must be three separate interactions — never merged. D-01 and FOUND-02 are explicit.

---

## Shared Patterns

### SKILL.md Frontmatter
**Source:** Multiple skills — gsd-thread (lines 1–9), gsd-new-project (lines 1–11), gsd-new-workspace (lines 1–10), gsd-update (lines 1–7)
**Apply to:** `.claude/skills/sara-init/SKILL.md`

All skills use identical frontmatter structure: `name`, `description`, `argument-hint` (optional), `allowed-tools` list. The `allowed-tools` list is the security boundary — every tool the skill body invokes must appear here. Missing a tool silently prevents it from working.

### Self-Contained Inline Process (no workflow delegation)
**Source:** `/home/george/.claude/skills/gsd-thread/SKILL.md` (full file)
**Apply to:** `.claude/skills/sara-init/SKILL.md`

`sara-init` should embed all logic in `<process>` directly — no `<execution_context>` block referencing an external workflow file. The linear init sequence does not benefit from workflow indirection. Contrast with `gsd-new-project` (delegates to `new-project.md`) — that skill has branching modes and shared references; `sara-init` does not.

### Guard-Before-Write Ordering
**Source:** `gsd-thread/SKILL.md` `<mode_list>` — ls check before all else; RESEARCH.md Pattern 3
**Apply to:** `.claude/skills/sara-init/SKILL.md` step 1

The guard clause (`[ -d wiki ]` check) must be the first action in `<process>`. No AskUserQuestion calls, no directory creation, no file writes before the guard. This prevents partial init on a live repo (RESEARCH.md Pitfall 1).

### Annotated YAML Frontmatter
**Source:** RESEARCH.md Pattern 4 (lines 248–265)
**Apply to:** All five entity templates in `.sara/templates/` and all five entity schema blocks in `wiki/CLAUDE.md`

- Quote `schema_version: "1.0"` — unquoted `1.0` is parsed as float by Obsidian
- Inline comments with `# allowed values` after fields with constrained enumerations
- 2-space indentation throughout
- No tab characters

### Commit Step (optional)
**Source:** `gsd-thread/SKILL.md` `<mode_create>` step 5 (line 204): `gsd-sdk query commit "docs: create thread..."`
**Apply to:** `.claude/skills/sara-init/SKILL.md` — as an optional final step

`.claude/settings.local.json` already grants `Bash(git *)`. If the planner includes a commit step, use:
```bash
git add .sara/ pipeline-state.json wiki/
git commit -m "chore: initialise SARA wiki structure"
```

RESEARCH.md Open Question 3 recommends against git init as part of the skill, but committing the created files is acceptable if the user is already in a git repo.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `pipeline-state.json` | state | file-I/O | No existing counter/state registry pattern in GSD skills — all GSD state files use YAML frontmatter in markdown, not JSON counters |
| `wiki/CLAUDE.md` | schema contract | file-I/O | No existing skill creates a CLAUDE.md behavioral contract — this is a novel pattern for SARA; use RESEARCH.md D-12–D-14 and Code Examples as the spec |

For these files, the planner should use RESEARCH.md Code Examples (lines 404–602) as the authoritative content spec.

---

## Metadata

**Analog search scope:** `/home/george/.claude/skills/` (73 skills scanned), `/home/george/.claude/get-shit-done/references/` (questioning.md), `/home/george/.claude/get-shit-done/workflows/new-project.md`
**Files read:** 8 (gsd-thread/SKILL.md, gsd-new-project/SKILL.md, gsd-update/SKILL.md, gsd-manager/SKILL.md, gsd-new-workspace/SKILL.md, gsd-inbox/SKILL.md, gsd-import/SKILL.md, questioning.md)
**Pattern extraction date:** 2026-04-27
