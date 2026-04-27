# Phase 1: Foundation & Schema - Research

**Researched:** 2026-04-27
**Domain:** Claude Code skill authoring, YAML frontmatter schemas, filesystem initialisation, JSON state persistence
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `/sara-init` collects project name, vertical list, and department list using AskUserQuestion TUI prompts. Verticals and departments are prompted separately (two distinct questions).
- **D-02:** If run in a directory that already has a `/wiki/` tree, `/sara-init` aborts with a clear error message. No overwrite, no partial re-init.
- **D-03:** Project name is always collected during init. It is stored in `.sara/config.json` and referenced in `wiki/CLAUDE.md` header.
- **D-04:** Project config lives at `.sara/config.json`. Templates also live in `.sara/templates/`. The `.sara/` directory groups all SARA operational files.
- **D-05:** `.sara/config.json` initial structure: `{"project": "<name>", "verticals": [...], "departments": [...], "schema_version": "1.0"}`. Ingest types are hardcoded in skill logic, not stored in config.
- **D-06:** Ingest items use type-prefixed IDs: `MTG-NNN`, `EML-NNN`, `SLK-NNN`, `DOC-NNN`. Each type has its own counter.
- **D-07:** `pipeline-state.json` lives at the project root with initial structure: `{"counters": {"ingest": {"MTG":0,"EML":0,"SLK":0,"DOC":0}, "entity": {"REQ":0,"DEC":0,"ACT":0,"RISK":0,"STK":0}}, "items": {}}`.
- **D-08:** Each item entry in `pipeline-state.json` stores: `id`, `type`, `filename`, `stage`, `created`, `discussion_notes`, `extraction_plan`.
- **D-09:** Templates live in `.sara/templates/` — one file per entity type: `requirement.md`, `decision.md`, `action.md`, `risk.md`, `stakeholder.md`.
- **D-10:** Templates use annotated frontmatter — YAML fields with inline comments showing allowed values.
- **D-11:** Body sections per entity type are defined (Requirements: Description/Acceptance Criteria/Notes; Decisions: ADR-style; Actions: Description/Notes; Risks: Description/Mitigation/Notes; Stakeholders: frontmatter only).
- **D-12:** Entity schemas live in `wiki/CLAUDE.md`.
- **D-13:** `wiki/CLAUDE.md` uses template skeleton format — fenced code blocks showing full annotated frontmatter + body section headings.
- **D-14:** `wiki/CLAUDE.md` contains schema definitions AND core behavioral rules (dedup check, index/log update, counter increment, cross-reference format).

### Claude's Discretion

- Exact wording and structure of the `wiki/CLAUDE.md` behavioral rules section
- File naming convention for archived source files (Phase 2 scope; Phase 1 sets counter format as integer)
- Whether `wiki/index.md` and `wiki/log.md` are created with stub headers or fully empty

### Deferred Ideas (OUT OF SCOPE)

- None — discussion stayed within Phase 1 scope.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | `/sara-init` creates full directory structure, CLAUDE.md schema, `pipeline-state.json`, and entity page templates | Skill authoring pattern (SKILL.md), Bash mkdir -p, Write tool for file creation |
| FOUND-02 | Separate prompts for vertical list and department list during init | AskUserQuestion TUI with two sequential prompts; lists parsed from comma-separated input |
| FOUND-03 | All wiki entity pages include `schema_version` in YAML frontmatter from creation | Annotated YAML frontmatter pattern; hardcode `"1.0"` in templates |
| FOUND-04 | `pipeline-state.json` persists all pipeline state across session boundaries | Plain JSON file at repo root; structure locked by D-07/D-08 |
| WIKI-01 | Requirements pages: structured YAML frontmatter | Template: `requirement.md` with all fields from WIKI-01 spec |
| WIKI-02 | Decision pages: structured YAML frontmatter | Template: `decision.md` with ADR-style body (D-11) |
| WIKI-03 | Action pages: structured YAML frontmatter | Template: `action.md` with all fields from WIKI-03 spec |
| WIKI-04 | Risk pages: structured YAML frontmatter | Template: `risk.md` with likelihood/impact fields |
| WIKI-05 | Stakeholder pages: vertical + department as separate fields | Template: `stakeholder.md`; vertical and department never merged; drawn from config lists |
| WIKI-06 | `wiki/index.md` LLM-maintained catalog | Created at init as stub (header row only); schema defined in `wiki/CLAUDE.md` |
| WIKI-07 | `wiki/log.md` append-only chronological record | Created at init as stub; format defined in `wiki/CLAUDE.md` |

</phase_requirements>

---

## Summary

Phase 1 is a pure filesystem initialisation skill — no external dependencies, no libraries, no network calls. The deliverable is a single SKILL.md file at `.claude/skills/sara-init/SKILL.md` that Claude Code executes when the user invokes `/sara-init`.

The skill's job is to: (1) detect an already-initialised directory and abort safely, (2) collect three pieces of user input via AskUserQuestion TUI (project name, verticals, departments), (3) create the full directory tree using Bash `mkdir -p`, (4) write six files using the Write tool (`.sara/config.json`, `pipeline-state.json`, `wiki/CLAUDE.md`, `wiki/index.md`, `wiki/log.md`, and five entity templates in `.sara/templates/`), and (5) report success.

All content — directory names, JSON structures, YAML frontmatter fields, and schema behavioral rules — is fully locked by the CONTEXT.md decisions. The planner's job is to sequence these writes into tasks with clear verification steps. No external tooling, no package installs, no test frameworks needed — this phase is pure structured content authoring delivered as a Claude Code skill.

**Primary recommendation:** Implement `/sara-init` as a self-contained SKILL.md with inline process steps (no external workflow file needed given the linear, non-branching nature of init). Use AskUserQuestion for the three user inputs, Bash for directory creation, and Write for all file creation.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| User input collection | Claude Code skill (runtime) | — | AskUserQuestion TUI is the only interaction mechanism; no UI layer exists |
| Directory tree creation | Claude Code skill → Bash | — | `mkdir -p` is the standard mechanism; skill orchestrates |
| JSON config/state writing | Claude Code skill → Write tool | — | Plain file write; no serialisation library needed |
| YAML frontmatter authoring | Claude Code skill → Write tool | — | Templates are static strings with placeholders; no YAML parser needed |
| Schema contract (wiki/CLAUDE.md) | Claude Code file loading | wiki-touching skills (Phase 2+) | CLAUDE.md is auto-loaded by Claude Code for any session in the wiki subtree |
| Guard clause (abort on re-init) | Claude Code skill → Bash | — | `ls wiki/ 2>/dev/null` check before any writes |

---

## Standard Stack

### Core

There are no library dependencies. This phase uses only Claude Code built-in tools and standard shell utilities. [VERIFIED: codebase inspection]

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Claude Code Write tool | built-in | Create all files | The canonical way skills create files |
| Claude Code Bash tool | built-in | `mkdir -p` directory creation and guard clause check | Standard shell; no install needed |
| AskUserQuestion | built-in | TUI prompts for project name, verticals, departments | Locked by D-01; the only input mechanism |

### Supporting

None — no additional tools required for init-only scope.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline skill process | External workflow file (`@workflow.md`) | Workflow indirection adds complexity with no benefit for a linear init sequence |
| AskUserQuestion for list input | Free-text prompt in skill body | AskUserQuestion is the locked decision (D-01); free-text has no TUI structure |
| Separate template files | Inline template strings in skill | Templates in `.sara/templates/` are locked (D-09); they serve as runtime reference for Phase 2+ skills |

**Installation:** None required — no npm packages, no pip installs.

---

## Architecture Patterns

### System Architecture Diagram

```
User invokes /sara-init
        │
        ▼
[Guard clause] ─── wiki/ exists? ──► Abort with error message (STOP)
        │ no
        ▼
[AskUserQuestion] ◄── "Project name?"
        │ answer: project_name
        ▼
[AskUserQuestion] ◄── "Verticals? (comma-separated)"
        │ answer: verticals[]
        ▼
[AskUserQuestion] ◄── "Departments? (comma-separated)"
        │ answer: departments[]
        │
        ▼
[Bash: mkdir -p] ── Create all directories in one call:
        │            raw/input, raw/meetings, raw/emails,
        │            raw/slack, raw/documents,
        │            wiki/requirements, wiki/decisions,
        │            wiki/actions, wiki/risks, wiki/stakeholders,
        │            .sara/templates
        ▼
[Write: .sara/config.json]
        ▼
[Write: pipeline-state.json]
        ▼
[Write: wiki/CLAUDE.md] ── schema + behavioral rules
        ▼
[Write: wiki/index.md]  ── stub header
        ▼
[Write: wiki/log.md]    ── stub header
        ▼
[Write: .sara/templates/requirement.md]
[Write: .sara/templates/decision.md]
[Write: .sara/templates/action.md]
[Write: .sara/templates/risk.md]
[Write: .sara/templates/stakeholder.md]
        ▼
[Report success to user]
```

### SKILL.md File Structure

```
.claude/
└── skills/
    └── sara-init/
        └── SKILL.md       ← the deliverable
```

After init runs, the project gains:

```
.sara/
├── config.json
└── templates/
    ├── requirement.md
    ├── decision.md
    ├── action.md
    ├── risk.md
    └── stakeholder.md
pipeline-state.json
raw/
├── input/
├── meetings/
├── emails/
├── slack/
└── documents/
wiki/
├── CLAUDE.md
├── index.md
├── log.md
├── requirements/
├── decisions/
├── actions/
├── risks/
└── stakeholders/
```

### Pattern 1: SKILL.md Frontmatter

All Claude Code skills follow this frontmatter pattern. [VERIFIED: inspection of existing skills at `/home/george/.claude/skills/`]

```yaml
---
name: sara-init
description: "Initialise a new SARA wiki in the current directory"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```

The `allowed-tools` list must explicitly include every tool the skill body uses. AskUserQuestion must be listed for TUI prompts to work. [VERIFIED: `gsd-update/SKILL.md` and `gsd-manager/SKILL.md` show this pattern]

### Pattern 2: AskUserQuestion for Collecting Lists

The SARA init skill needs comma-separated list input for verticals and departments. The standard pattern from GSD skills is: [VERIFIED: `questioning.md` reference document]

```
AskUserQuestion with:
  header: "Verticals"
  question: "List the market verticals for this project, separated by commas"
  options: ["Residential, Enterprise, Wholesale", "Enter your own", "Skip for now"]
```

After the user responds, the skill parses the response string: split on commas, trim whitespace, filter empty strings. The resulting array is written directly into `.sara/config.json`.

For free-form text answers (user selects "Enter your own"), the skill should accept the raw answer string and apply the same split/trim logic. The GSD questioning guide explicitly states: when user signals free-form intent, switch to plain text, not another AskUserQuestion. [CITED: `/home/george/.claude/get-shit-done/references/questioning.md`]

### Pattern 3: Guard Clause — Abort on Re-init

```bash
if [ -d "wiki" ]; then
  echo "SARA wiki already exists in this directory. Aborting."
  exit 1
fi
```

This check runs before any AskUserQuestion calls or writes. If it fails, the skill reports the error and stops immediately (D-02). [ASSUMED: standard shell idiom — no special Claude Code mechanism needed]

### Pattern 4: Annotated YAML Frontmatter in Templates

D-10 specifies annotated frontmatter — YAML fields with inline comments showing allowed values. This is Obsidian-compatible because Obsidian's Properties panel reads clean YAML values and ignores inline comments; the source view shows the hints. [VERIFIED: Obsidian uses standard YAML 1.1 which permits inline comments after values]

Example for a requirement template:

```yaml
---
id: REQ-000
title: ""
status: open  # open | accepted | rejected | superseded
description: ""
source: ""     # ingest ID (e.g. MTG-001)
raised-by: ""  # stakeholder ID (e.g. STK-001)
owner: ""      # stakeholder ID
schema_version: "1.0"
tags: []
related: []    # entity IDs (e.g. [DEC-001, ACT-002])
---
```

### Pattern 5: wiki/CLAUDE.md as Schema Contract

`wiki/CLAUDE.md` uses template skeleton format (D-13) — each entity type gets a fenced code block showing the full annotated frontmatter plus body section headings. This is the same structure as the templates. The file also contains the four behavioral rules (D-14).

Claude Code auto-loads `CLAUDE.md` files in the directory hierarchy of the current working file. A skill operating on a file under `wiki/` will automatically inherit `wiki/CLAUDE.md` context. [VERIFIED: Claude Code documentation behavior — CLAUDE.md is loaded from current and parent directories]

### Pattern 6: settings.local.json Permissions

The existing `.claude/settings.local.json` grants `Bash(git *)` and `Bash(gsd-sdk query *)`. The `sara-init` skill uses basic Bash (`mkdir`, `ls`) which does not require explicit allowlisting beyond the `Bash(*)` implied by the `allowed-tools: [Bash]` declaration in the skill frontmatter. [VERIFIED: inspection of `.claude/settings.local.json`]

However, if the planner decides to commit the initialised files as part of init, `Bash(git *)` is already allowed.

### Anti-Patterns to Avoid

- **Writing files before guard clause:** Any write before checking for existing `wiki/` directory risks partial init on a live repo. Guard clause must be the first action.
- **Merging vertical and department into one prompt:** D-01 and FOUND-02 explicitly require two separate prompts. Never combine into one "roles" or "org structure" question.
- **Using wiki-links in templates:** Obsidian wiki-links (`[[page-name]]`) are explicitly out of scope (REQUIREMENTS.md Out of Scope section). Use entity IDs in `related` fields only.
- **Storing ingest types in config:** D-05 states ingest types are hardcoded in skill logic, not in `.sara/config.json`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML serialisation | Custom YAML string builder | Inline template strings in skill body | YAML for init is static; no dynamic serialisation needed |
| JSON serialisation | String concatenation | Inline template with variable substitution | Two JSON files; straightforward string templates |
| Directory existence check | Complex file scanning | `ls wiki/ 2>/dev/null` or `[ -d wiki ]` | Single Bash idiom is sufficient |
| Input parsing (comma list) | Regex or library | Split on comma + trim in skill prose | LLM can perform this trivially in skill execution context |

**Key insight:** This phase has zero runtime complexity. Every "hard problem" in init (YAML validity, JSON structure, directory layout) is solved by writing the correct static content. The only dynamic parts are the three user inputs and their interpolation into config and the `wiki/CLAUDE.md` project header.

---

## Common Pitfalls

### Pitfall 1: Partial Init on Failure

**What goes wrong:** Skill creates some directories and files, then fails mid-way (e.g., permission error). Directory exists but is incomplete. Re-running hits the guard clause and aborts, leaving the user stuck.

**Why it happens:** Claude Code Write and Bash calls are not transactional.

**How to avoid:** Order writes so the most critical structural files (config, pipeline-state) come before templates. Document the failure recovery path in skill notes: if init is incomplete, user can manually delete the partial structure and re-run.

**Warning signs:** `wiki/` directory exists but `pipeline-state.json` is missing, or templates directory is empty.

### Pitfall 2: YAML Frontmatter Breaks Obsidian

**What goes wrong:** Obsidian's Properties panel rejects or mangles the frontmatter, causing YAML parse errors in the vault.

**Why it happens:** Obsidian uses a YAML 1.1 subset. Common causes: unquoted strings containing colons, tab characters instead of spaces, missing space after colon.

**How to avoid:** Quote all string values that might contain special characters. Use 2-space indentation. Test templates manually in Obsidian before finalising. The `schema_version: "1.0"` field should always be quoted (string, not float). [VERIFIED: Obsidian known behavior — unquoted `1.0` is parsed as float]

**Warning signs:** Obsidian shows "Invalid YAML" banner on a page, or Properties panel shows wrong types.

### Pitfall 3: AskUserQuestion Options Truncated

**What goes wrong:** AskUserQuestion option headers longer than 12 characters are rejected by the TUI validator.

**Why it happens:** Hard limit in GSD's questioning framework. [CITED: `/home/george/.claude/get-shit-done/references/questioning.md` — "Headers longer than 12 characters (hard limit — validation will reject them)"]

**How to avoid:** Keep option headers short. For vertical/department prompts, use options like "Use examples", "My own list", "Skip" rather than full-sentence headers.

**Warning signs:** AskUserQuestion renders incorrectly or validation error is thrown.

### Pitfall 4: Vertical/Department Conflation

**What goes wrong:** Templates or config merge vertical and department into a single "segment" or "team" field.

**Why it happens:** Both are org-structure axes; conflation is a natural simplification mistake.

**How to avoid:** The domain constraint is explicit and named (project memory: `project_sara_domain.md`). Stakeholder template must have two distinct fields: `vertical:` and `department:`. Config must have two distinct arrays: `"verticals"` and `"departments"`. Never use a combined field.

**Warning signs:** Any template or config key named `segment`, `team`, `org`, or `vertical-department`.

### Pitfall 5: wiki/CLAUDE.md Loaded in Wrong Scope

**What goes wrong:** Developer assumes `wiki/CLAUDE.md` is always loaded, but Claude Code only loads it when the working context is within `wiki/` or a subdirectory.

**Why it happens:** CLAUDE.md loading is hierarchical from current file location upward, not global. [ASSUMED: based on Claude Code documentation behavior — flag for user validation if schema contract is critical to Phase 2 design]

**How to avoid:** Phase 2 skills that modify wiki pages must ensure they open or reference a file under `wiki/` so the CLAUDE.md is in scope. Document this in `wiki/CLAUDE.md`'s own header.

---

## Code Examples

### SKILL.md Frontmatter (complete)

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

[VERIFIED: pattern from existing skills at `/home/george/.claude/skills/`]

### Guard Clause (Bash)

```bash
if [ -d "wiki" ]; then
  echo "Error: A SARA wiki already exists in this directory (wiki/ found). Aborting."
  exit 1
fi
```

[ASSUMED: standard POSIX shell — correct for Claude Code Bash tool environment]

### Directory Tree Creation (Bash, single call)

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

[ASSUMED: standard POSIX mkdir -p — no special Claude Code consideration]

### .sara/config.json Content

```json
{
  "project": "{{project_name}}",
  "verticals": {{verticals_json_array}},
  "departments": {{departments_json_array}},
  "schema_version": "1.0"
}
```

Where `{{verticals_json_array}}` is the user's input parsed as a JSON array string (e.g., `["Residential", "Enterprise", "Wholesale"]`). [VERIFIED: structure locked by D-05]

### pipeline-state.json Initial Content

```json
{
  "counters": {
    "ingest": { "MTG": 0, "EML": 0, "SLK": 0, "DOC": 0 },
    "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RISK": 0, "STK": 0 }
  },
  "items": {}
}
```

[VERIFIED: structure locked by D-07]

### Requirement Template (.sara/templates/requirement.md)

```markdown
---
id: REQ-000
title: ""
status: open  # open | accepted | rejected | superseded
description: ""
source: ""     # ingest ID (e.g. MTG-001)
raised-by: ""  # stakeholder ID (e.g. STK-001)
owner: ""      # stakeholder ID (e.g. STK-001)
schema_version: "1.0"
tags: []
related: []    # entity IDs (e.g. [DEC-001, ACT-002])
---

## Description

## Acceptance Criteria

## Notes
```

[VERIFIED: fields from WIKI-01; body from D-11]

### Decision Template (.sara/templates/decision.md)

```markdown
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
context: ""
decision: ""
rationale: ""
alternatives-considered: ""
date: ""          # ISO 8601 (e.g. 2026-04-27)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
schema_version: "1.0"
tags: []
related: []
---

## Context

## Decision

## Rationale

## Alternatives Considered
```

[VERIFIED: fields from WIKI-02; body from D-11 (ADR-style)]

### Action Template (.sara/templates/action.md)

```markdown
---
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
description: ""
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: ""     # ingest ID (e.g. MTG-001)
schema_version: "1.0"
tags: []
related: []
---

## Description

## Notes
```

[VERIFIED: fields from WIKI-03; body from D-11]

### Risk Template (.sara/templates/risk.md)

```markdown
---
id: RISK-000
title: ""
status: open  # open | mitigated | accepted | closed
description: ""
likelihood: ""  # low | medium | high
impact: ""      # low | medium | high
owner: ""       # stakeholder ID (e.g. STK-001)
mitigation: ""
source: ""      # ingest ID (e.g. MTG-001)
schema_version: "1.0"
tags: []
related: []
---

## Description

## Mitigation

## Notes
```

[VERIFIED: fields from WIKI-04; body from D-11]

### Stakeholder Template (.sara/templates/stakeholder.md)

```markdown
---
id: STK-000
name: ""
vertical: ""    # from project config verticals list
department: ""  # from project config departments list
email: ""
role: ""
schema_version: "1.0"
related: []
---
```

[VERIFIED: fields from WIKI-05; D-11 states frontmatter only — no body sections]

### wiki/index.md Stub

```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Index

| ID | Title | Status | Type | Tags | Last Updated |
|----|-------|--------|------|------|--------------|
```

[ASSUMED: stub format with header row — Claude's discretion on whether to include header row or leave fully empty]

### wiki/log.md Stub

```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Log

<!-- Append-only. Each entry: ingest ID, date, type, filename, artifacts created/updated -->
```

[ASSUMED: stub format — Claude's discretion]

### wiki/CLAUDE.md Opening Section

```markdown
# SARA Wiki — Schema & Behavioral Rules

**Project:** {{project_name}}
**Schema version:** 1.0

This file is automatically loaded by Claude Code when working in any file under `wiki/`.
All SARA pipeline commands must follow the rules in this file.

## Behavioral Rules

1. **Deduplication:** Before creating any new entity, search `wiki/index.md` for an existing entity with the same title or similar description. Update existing pages rather than creating duplicates.
2. **Index maintenance:** Every entity write must update `wiki/index.md` with the new or changed row (ID, title, status, type, tags, last-updated).
3. **Log maintenance:** Every entity write must append an entry to `wiki/log.md` recording the ingest ID, date, entity IDs created/updated, and source filename.
4. **ID assignment:** Before assigning a new entity ID, increment the relevant counter in `pipeline-state.json`. Use the post-increment value.
5. **Cross-references:** `related` fields use entity IDs only (e.g. `REQ-001`, `DEC-003`) — never file paths or wiki-links.

## Entity Schemas
```

Followed by one fenced code block per entity type (same content as the templates). [VERIFIED: D-12, D-13, D-14]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Claude Code commands (`.claude/commands/`) | Skills (`.claude/skills/SKILL.md`) | Claude Code evolved past 2024 | New skills must use SKILL.md format with YAML frontmatter, not bare .md command files |

**Deprecated/outdated:**
- `.claude/commands/gsd/` format: Legacy Claude commands location. New SARA skills must go in `.claude/skills/sara-init/SKILL.md`, not `.claude/commands/`. [VERIFIED: discovery-contract.md distinguishes legacy commands from skills]

---

## Runtime State Inventory

> Greenfield project — no existing runtime state to migrate.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — greenfield project | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Claude Code Write tool | File creation | ✓ | built-in | — |
| Claude Code Bash tool | mkdir, guard clause | ✓ | built-in | — |
| AskUserQuestion | User input collection | ✓ | built-in | — |
| `mkdir` (POSIX) | Directory tree creation | ✓ | OS standard | — |

No missing dependencies. All capabilities are built-in to the Claude Code runtime.

---

## Validation Architecture

Nyquist validation is enabled (`nyquist_validation: true` in config.json).

### Test Framework

This phase has no automated test framework — the skill is a SKILL.md prose document executed by Claude Code, not a compiled program. Verification is observational: run `/sara-init`, inspect the created files.

| Property | Value |
|----------|-------|
| Framework | Manual inspection (no automated test runner) |
| Config file | none |
| Quick run command | `/sara-init` in a fresh temp directory |
| Full suite command | Inspect all 11 created files/dirs against requirements |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | Directory tree and all files created | smoke | `ls raw/ wiki/ .sara/ pipeline-state.json` | ❌ Wave 0 (manual) |
| FOUND-02 | Separate vertical/department fields in config | smoke | `cat .sara/config.json` — check both keys present | ❌ Wave 0 (manual) |
| FOUND-03 | `schema_version` in all 5 templates | smoke | `grep schema_version .sara/templates/*.md` | ❌ Wave 0 (manual) |
| FOUND-04 | `pipeline-state.json` has correct structure | smoke | `cat pipeline-state.json` — check counters + items keys | ❌ Wave 0 (manual) |
| WIKI-01 | Requirement template has all WIKI-01 fields | inspection | `cat .sara/templates/requirement.md` | ❌ Wave 0 (manual) |
| WIKI-02 | Decision template has all WIKI-02 fields | inspection | `cat .sara/templates/decision.md` | ❌ Wave 0 (manual) |
| WIKI-03 | Action template has all WIKI-03 fields | inspection | `cat .sara/templates/action.md` | ❌ Wave 0 (manual) |
| WIKI-04 | Risk template has all WIKI-04 fields | inspection | `cat .sara/templates/risk.md` | ❌ Wave 0 (manual) |
| WIKI-05 | Stakeholder template has vertical + department as separate fields | inspection | `cat .sara/templates/stakeholder.md` | ❌ Wave 0 (manual) |
| WIKI-06 | `wiki/index.md` exists with catalog header | smoke | `cat wiki/index.md` | ❌ Wave 0 (manual) |
| WIKI-07 | `wiki/log.md` exists as stub | smoke | `cat wiki/log.md` | ❌ Wave 0 (manual) |

### Sampling Rate

- **Per task commit:** Manual spot-check — inspect the file written in that task
- **Per wave merge:** Run `/sara-init` end-to-end in a temp directory; inspect all outputs
- **Phase gate:** All 11 files exist, all frontmatter fields present, guard clause tested (run init twice — second run must abort)

### Wave 0 Gaps

- No test runner to install — verification is entirely manual inspection
- Planner should include a verification task: "Run `/sara-init` in a temp directory and verify all outputs against the requirements checklist"

---

## Security Domain

Security enforcement applies (not explicitly disabled). This phase has a narrow security surface — it is a local filesystem initialisation tool with no network calls, no authentication, and no external services.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — local tool, single user |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a — no multi-user |
| V5 Input Validation | yes (low risk) | Trim/split user input; no shell injection risk as input goes into JSON, not shell |
| V6 Cryptography | no | n/a |

### Known Threat Patterns for CLI/init skills

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal in project name | Tampering | Project name goes into JSON only, not a file path — low risk |
| Comma-injected list values | Tampering | Split/trim is LLM-prose logic; resulting JSON array contains strings — no eval |
| Overwrite existing files | Tampering | Guard clause (D-02) aborts before any writes if `wiki/` exists |

**Assessment:** Security risk is minimal. The only user-controlled input (project name, verticals, departments) flows into a JSON config file and markdown text — not into shell commands or eval contexts. The guard clause is the most important safety control.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Guard clause `[ -d wiki ]` works correctly in Claude Code Bash environment | Guard Clause pattern | Minor — alternative: `ls wiki 2>/dev/null \| wc -l` |
| A2 | AskUserQuestion header length limit of 12 characters applies to sara-init's prompts | Common Pitfalls #3 | Prompts may render incorrectly or fail if limit differs |
| A3 | wiki/CLAUDE.md is loaded by Claude Code only when working within the wiki/ subtree (hierarchical loading) | Architecture Patterns #5 | Phase 2 skills might not inherit schema context if loading behavior differs |
| A4 | wiki/index.md and wiki/log.md should be created with stub headers (not fully empty) | Code Examples | Fully empty files are also valid — user preference |
| A5 | `schema_version: "1.0"` must be quoted to avoid Obsidian parsing it as float | Common Pitfalls #2 | YAML float `1.0` may behave identically in practice for this field |

---

## Open Questions

1. **wiki/index.md and wiki/log.md: stub headers or fully empty?**
   - What we know: Claude's discretion (CONTEXT.md)
   - What's unclear: Whether stub headers aid Phase 2 skills or are unnecessary noise
   - Recommendation: Create stubs with a markdown heading and a comment explaining format. Costs nothing; helps Phase 2 skills detect the file format immediately.

2. **wiki/CLAUDE.md behavioral rules: exact wording**
   - What we know: Four behavioral rules defined by D-14; exact prose is Claude's discretion
   - What's unclear: How prescriptive vs instructional the language should be
   - Recommendation: Use imperative mood ("Before creating an entity, check..."). Treat this file like a coding standards doc — unambiguous, scannable.

3. **Committing files after init: yes or no?**
   - What we know: `git *` is already allowed in `.claude/settings.local.json`; commit_docs is true
   - What's unclear: Whether `/sara-init` should `git init` + initial commit, or leave that to the user
   - Recommendation: Do not git init or commit as part of the skill. Users may have their own git setup. Document that files are ready to commit.

---

## Sources

### Primary (HIGH confidence)

- Inspected skill files at `/home/george/.claude/skills/` — SKILL.md format, frontmatter schema, allowed-tools pattern
- `/home/george/.claude/get-shit-done/references/questioning.md` — AskUserQuestion usage rules, 12-char header limit
- `.planning/phases/01-foundation-schema/01-CONTEXT.md` — all locked decisions
- `.planning/REQUIREMENTS.md` — complete requirement field lists for all entity types
- `.planning/PROJECT.md` — directory structure, command taxonomy, constraints
- `.claude/settings.local.json` — existing permission grants
- `.ideation/get-shit-done/docs/skills/discovery-contract.md` — skill root locations, SKILL.md format rules

### Secondary (MEDIUM confidence)

- Obsidian YAML 1.1 behavior (inline comments, quoted strings) — [CITED: Obsidian documentation knowledge; standard YAML 1.1 behavior]

### Tertiary (LOW confidence)

- wiki/CLAUDE.md hierarchical loading behavior — [ASSUMED based on Claude Code CLAUDE.md loading documentation; not directly verified in this session]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no external dependencies; all tools are built-in
- Architecture: HIGH — pattern locked by CONTEXT.md decisions; skill structure verified from existing examples
- Pitfalls: MEDIUM — YAML/Obsidian and AskUserQuestion limits verified; CLAUDE.md scoping assumed

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (stable domain — Claude Code SKILL.md format, filesystem operations)
