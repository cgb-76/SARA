# Phase 1: Foundation & Schema - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers the `/sara-init` Claude Code skill. When run in an empty directory, it:
- Collects project name, vertical list, and department list from the user
- Creates the full `/raw/` and `/wiki/` directory tree
- Writes `.sara/config.json` with project configuration
- Writes `pipeline-state.json` with initial counters and empty item registry
- Creates entity page templates in `.sara/templates/` for all five entity types
- Writes `wiki/CLAUDE.md` with entity schema definitions and core behavioral rules
- Creates `wiki/index.md` and `wiki/log.md` as empty catalogs

No pipeline processing, no ingest commands, no wiki content — init only.

</domain>

<decisions>
## Implementation Decisions

### Init Interaction Pattern
- **D-01:** `/sara-init` collects project name, vertical list, and department list using AskUserQuestion TUI prompts. Verticals and departments are prompted separately (two distinct questions).
- **D-02:** If run in a directory that already has a `/wiki/` tree, `/sara-init` aborts with a clear error message. No overwrite, no partial re-init.
- **D-03:** Project name is always collected during init. It is stored in `.sara/config.json` and referenced in `wiki/CLAUDE.md` header.

### Project Configuration
- **D-04:** Project config lives at `.sara/config.json`. Templates also live in `.sara/templates/`. The `.sara/` directory groups all SARA operational files.
- **D-05:** `.sara/config.json` initial structure:
  ```json
  {
    "project": "<project name>",
    "verticals": ["<vertical1>", "<vertical2>"],
    "departments": ["<dept1>", "<dept2>"],
    "schema_version": "1.0"
  }
  ```
  Ingest types are hardcoded in skill logic, not stored in config.

### Ingest Item ID Format
- **D-06:** Ingest items use type-prefixed IDs: `MTG-NNN`, `EML-NNN`, `SLK-NNN`, `DOC-NNN`. Each type has its own counter. This maps directly to the `/sara-ingest <type>` argument.

### `pipeline-state.json` Structure
- **D-07:** `pipeline-state.json` lives at the project root. Initial structure:
  ```json
  {
    "counters": {
      "ingest": { "MTG": 0, "EML": 0, "SLK": 0, "DOC": 0 },
      "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RISK": 0, "STK": 0 }
    },
    "items": {}
  }
  ```
- **D-08:** Each item entry in `pipeline-state.json` stores: `id`, `type`, `filename`, `stage` (pending/discussing/extracting/complete), `created` date, `discussion_notes` (empty string), `extraction_plan` (empty array). Discussion notes and extraction plan are embedded inline — no separate files.

### Entity Templates
- **D-09:** Templates live in `.sara/templates/` — one file per entity type: `requirement.md`, `decision.md`, `action.md`, `risk.md`, `stakeholder.md`.
- **D-10:** Templates use **annotated frontmatter** — YAML fields with inline comments showing allowed values (e.g. `status: open  # open | accepted | rejected | superseded`). Obsidian Properties panel shows clean values; source view shows hints.
- **D-11:** Body sections per entity type:
  - **Requirements:** `## Description` / `## Acceptance Criteria` / `## Notes`
  - **Decisions:** `## Context` / `## Decision` / `## Rationale` / `## Alternatives Considered` (ADR-style)
  - **Actions:** `## Description` / `## Notes`
  - **Risks:** `## Description` / `## Mitigation` / `## Notes`
  - **Stakeholders:** No body sections — frontmatter only.

### Schema Location & Format
- **D-12:** Entity schemas live in `wiki/CLAUDE.md`. This file is automatically loaded by Claude Code whenever working in the wiki subtree, ensuring all pipeline commands have schema context.
- **D-13:** `wiki/CLAUDE.md` uses **template skeleton format** per entity type: a fenced code block showing the full annotated frontmatter + body section headings. The same structure the templates use.
- **D-14:** `wiki/CLAUDE.md` contains both schema definitions AND core behavioral rules that every wiki-touching command must follow:
  - Check `wiki/index.md` before creating a new entity (never duplicate)
  - Always update `wiki/index.md` and `wiki/log.md` as part of every entity write
  - Always increment the relevant counter in `pipeline-state.json` before assigning a new ID
  - Cross-references in `related` fields use entity IDs (REQ-NNN, DEC-NNN, etc.), not file paths

### Claude's Discretion
- Exact wording and structure of the `wiki/CLAUDE.md` behavioral rules section
- File naming convention for archived source files (e.g. zero-padded NNN vs plain integer prefix) — this is Phase 2 scope but the counter format (integer) is set by Phase 1
- Whether `wiki/index.md` and `wiki/log.md` are created with stub headers or fully empty

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Requirements
- `.planning/REQUIREMENTS.md` — Full v1 requirement list. Phase 1 covers: FOUND-01, FOUND-02, FOUND-03, FOUND-04, WIKI-01, WIKI-02, WIKI-03, WIKI-04, WIKI-05, WIKI-06, WIKI-07

### Project Context
- `.planning/PROJECT.md` — Vision, directory structure, command taxonomy, ingest pipeline overview, constraints

No external specs or ADRs — all requirements are captured in REQUIREMENTS.md and decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — this is a greenfield project. No existing components, utilities, or hooks.

### Established Patterns
- SARA is implemented as Claude Code skills (`.claude/skills/`). The `/sara-init` skill will be a SKILL.md file in that directory.
- `.claude/settings.local.json` exists — skill permissions may need entries there.

### Integration Points
- All future pipeline skills (`/sara-ingest`, `/sara-discuss`, `/sara-extract`, `/sara-update`) will read `.sara/config.json` and `pipeline-state.json` created by Phase 1.
- `wiki/CLAUDE.md` is the schema contract that all wiki-touching skills inherit automatically via Claude Code's directory-scoped CLAUDE.md loading.

</code_context>

<specifics>
## Specific Ideas

- Obsidian compatibility is a hard requirement: wiki pages must render cleanly in Obsidian. This means standard CommonMark markdown, YAML frontmatter (not wiki-links), and no Obsidian-specific syntax.
- Vertical and department are distinct stakeholder axes — never interchangeable. A stakeholder has one vertical AND one department. This is a named constraint from the domain (see memory: project_sara_domain.md).
- The ingest ID prefix design (MTG/EML/SLK/DOC) was explicitly chosen over a generic INP-NNN format to map cleanly to `/sara-ingest <type>` arguments.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within Phase 1 scope.

</deferred>

---

*Phase: 01-foundation-schema*
*Context gathered: 2026-04-27*
