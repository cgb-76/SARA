# Phase 17: document-based-statefulness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 17-document-based-statefulness
**Areas discussed:** Item structure, Counter handling, Migration scope, File naming, Extraction plan format

---

## Intent clarification

**User's direction (verbatim):** Refactor pipeline-state.json into document-based state mirroring GSD's pattern. sara-ingest creates a folder for NTG-NNN in `.sara/pipeline`, each ingest run stores statefulness in `.sara/pipeline/MTG-NNN` or `.sara/pipeline/EML-NNN` etc. Reference: `.ideation/get-shit-done`.

---

## Item document format

| Option | Description | Selected |
|--------|-------------|----------|
| Single state.md | One file with YAML frontmatter + body sections that grow per stage | |
| One file per stage | state.md + discuss.md + plan.md — mirrors GSD's CONTEXT/PLAN/SUMMARY split | ✓ |

**User's choice:** One file per stage
**Notes:** Mirrors GSD's multi-file phase directory pattern more closely.

---

## Counter handling

| Option | Description | Selected |
|--------|-------------|----------|
| Derive from filesystem | Count max ID prefix in .sara/pipeline/ and wiki/* dirs at runtime | ✓ |
| Minimal counters.json | Small .sara/pipeline/counters.json for just counters | |
| Keep pipeline-state.json for counters only | Hollow out JSON to just the counters object | |

**User's choice:** Derive from filesystem
**Notes:** No counter file needed — ingest counters from .sara/pipeline/ directory names, entity counters from wiki page filenames.

---

## Migration scope

| Option | Description | Selected |
|--------|-------------|----------|
| New repos only | sara-init creates .sara/pipeline/; existing repos not migrated | ✓ |
| Include migration step | /sara-migrate command to convert existing pipeline-state.json | |

**User's choice:** New repos only
**Notes:** Existing repos document migration as manual.

---

## File naming inside item directory

| Option | Description | Selected |
|--------|-------------|----------|
| state.md / discuss.md / plan.md | Generic names inside the ID-named directory | ✓ |
| MTG-001-state.md / MTG-001-discuss.md / MTG-001-plan.md | ID-prefixed — redundant given directory name | |

**User's choice:** state.md / discuss.md / plan.md
**Notes:** Cleaner — the directory already carries the ID.

---

## Extraction plan format

| Option | Description | Selected |
|--------|-------------|----------|
| YAML frontmatter array | plan.md with artifacts: [] frontmatter — same structure as current JSON | |
| Markdown-only body | plan.md is pure markdown — sara-update parses with LLM | ✓ |

**User's choice:** Markdown-only body
**Notes:** Claude-native; more readable; sara-update is already an LLM reader. No structured schema needed.

---

## Claude's Discretion

- Exact markdown structure for plan.md and discuss.md
- Whether state.md has a body below the frontmatter
- Whether .sara/pipeline-state.json is explicitly deleted or simply not created

## Deferred Ideas

None.
