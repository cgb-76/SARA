# Phase 1: Foundation & Schema - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 01-foundation-schema
**Areas discussed:** Init interaction pattern, Schema location & format, pipeline-state.json structure, Entity template style, Body sections per entity type, Project config file, wiki/CLAUDE.md scope

---

## Init Interaction Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| AskUserQuestion TUI | Collect verticals and departments via interactive TUI prompts | ✓ |
| Prompt for free-text input | Plain-text prompt, user types at next message | |
| Pre-fill a config file | Create stub, user edits and re-runs | |

**User's choice:** AskUserQuestion TUI
**Notes:** Consistent with how GSD skills work.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Abort with clear error | Fail fast if /wiki/ already exists | ✓ |
| Prompt to overwrite | Ask user if they want to re-initialise | |
| Idempotent — add missing only | Only create what doesn't exist | |

**User's choice:** Abort with clear error

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — ask for project name | Collect during init, store in config | ✓ |
| No — derive from directory name | Use folder name automatically | |
| You decide | Leave to Claude | |

**User's choice:** Yes — ask for project name

---

## Schema Location & Format

| Option | Description | Selected |
|--------|-------------|----------|
| wiki/CLAUDE.md | Inside wiki subtree, auto-loaded by Claude Code | ✓ |
| Project-root CLAUDE.md | Always in scope but mixes concerns | |
| sara-schema.md (dedicated file) | Standalone file, requires @-include in CLAUDE.md | |

**User's choice:** wiki/CLAUDE.md

---

| Option | Description | Selected |
|--------|-------------|----------|
| Template skeleton per entity | Full page template: frontmatter + body headings | ✓ |
| Frontmatter spec only | YAML fields only, no body structure | |
| You decide | Leave to Claude | |

**User's choice:** Template skeleton per entity
**Notes:** User clarified they want Obsidian-compatible pages with a Properties panel (YAML frontmatter) plus standard body sections — not just schema field definitions.

---

## Ingest Item ID Format

*(Arose during schema format discussion)*

| Option | Description | Selected |
|--------|-------------|----------|
| INP-NNN (generic prefix) | Single prefix for all ingest types | |
| Plain integer | Item N, no prefix | |
| Type-prefixed (MTG/EML/SLK/DOC) | Prefix maps to /sara-ingest <type> argument | ✓ |

**User's choice:** Type-prefixed IDs
**Notes:** User proposed this — each input type has its own prefix and counter. MTG-NNN for meetings, EML-NNN for emails, SLK-NNN for Slack, DOC-NNN for documents.

---

## pipeline-state.json Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Counter per ingest type + per entity type | Separate counters for MTG/EML/SLK/DOC and REQ/DEC/ACT/RISK/STK | ✓ |
| Single global counter | One counter for all ingest items, one for all entities | |

**User's choice:** Counter per ingest type + per entity type

---

| Option | Description | Selected |
|--------|-------------|----------|
| Stage + metadata only | id, type, filename, stage, created — notes/plan as separate files | |
| Full pipeline context inline | Stage + metadata + discussion_notes + extraction_plan embedded in JSON | ✓ |

**User's choice:** Full pipeline context inline

---

## Entity Template Style

| Option | Description | Selected |
|--------|-------------|----------|
| Annotated with field hints | Inline YAML comments showing allowed values | ✓ |
| Blank skeleton | Empty values, no hints | |

**User's choice:** Annotated with field hints
**Notes:** User questioned why blank was recommended. Switched recommendation to annotated — inline hints are valuable when browsing in Obsidian source view. Properties panel shows clean values regardless.

---

| Option | Description | Selected |
|--------|-------------|----------|
| .sara/templates/ | Hidden directory at project root, groups SARA operational files | ✓ |
| wiki/templates/ subdirectory | Inside wiki tree, Obsidian-browsable | |
| You decide | Leave to Claude | |

**User's choice:** .sara/templates/

---

## Body Sections Per Entity Type

| Option | Description | Selected |
|--------|-------------|----------|
| ADR-style (Context/Decision/Rationale/Alternatives) | Standard Architecture Decision Record format | ✓ |
| Minimal — Decision + Rationale only | Shorter pages | |

**User's choice:** ADR-style for Decisions

---

| Option | Description | Selected |
|--------|-------------|----------|
| Functional sections per type | Requirements: Description/Acceptance Criteria/Notes; Actions: Description/Notes; Risks: Description/Mitigation/Notes; Stakeholders: none | ✓ |
| Uniform: Description + Notes for all | Same sections for every entity | |
| You decide | Leave to Claude | |

**User's choice:** Functional sections per type

---

## Project Config File

| Option | Description | Selected |
|--------|-------------|----------|
| .sara/config.json | Hidden directory, groups SARA operational files, templates alongside | ✓ |
| sara-config.json at project root | Visible at root alongside pipeline-state.json | |
| Embed in pipeline-state.json | Config as top-level key in state file | |

**User's choice:** .sara/config.json

---

| Option | Description | Selected |
|--------|-------------|----------|
| Project name + verticals + departments only | Lean config, other commands add as needed | ✓ |
| Project metadata + ingest type list | Also store valid ingest types for validation | |

**User's choice:** Project name + verticals + departments only

---

## wiki/CLAUDE.md Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Schema + core behavioral rules | Schema definitions plus standing rules all wiki commands must follow | ✓ |
| Schema only | Pure definitions, rules live in individual skills | |
| You decide | Leave to Claude | |

**User's choice:** Schema + core behavioral rules
**Notes:** Centralising rules in wiki/CLAUDE.md prevents them being forgotten in future skills.

---

## Claude's Discretion

- Exact wording and structure of wiki/CLAUDE.md behavioral rules section
- wiki/index.md and wiki/log.md stub headers vs. fully empty on init
- Zero-padded counter format for IDs (e.g. MTG-001 vs MTG-1)

## Deferred Ideas

None — discussion stayed within Phase 1 scope.
