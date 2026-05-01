---
phase: 17
plan: "02"
subsystem: sara-ingest
tags: [statefulness, filesystem, pipeline, skill-rewrite]
dependency_graph:
  requires: []
  provides: [sara-ingest-filesystem-state]
  affects: [sara-ingest]
tech_stack:
  added: []
  patterns: [filesystem-counter-derivation, state-md-write, grep-bulk-extract]
key_files:
  created: []
  modified:
    - .claude/skills/sara-ingest/SKILL.md
decisions:
  - "STATUS mode uses grep -rh for bulk frontmatter extraction (no per-file Read calls) — avoids context exhaustion for large pipelines"
  - "mkdir -p used for item directory creation — handles missing parent .sara/pipeline/ dir automatically (Pitfall 4)"
  - "Counter derivation uses ls | grep | sort | tail -1 pattern — always correct, no counter drift"
metrics:
  duration: "2m"
  completed: "2026-05-01T04:02:06Z"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
requirements: [STF-02]
---

# Phase 17 Plan 02: sara-ingest Filesystem-Based State Summary

## One-liner

Rewrote sara-ingest SKILL.md to replace pipeline-state.json read/write with filesystem counter derivation, item directory creation, state.md write pattern, and bulk grep STATUS mode.

## What Was Built

`sara-ingest` SKILL.md was completely rewritten to implement the document-based statefulness pattern (D-01 through D-06) for the ingest command:

- **INGEST mode:** Derives the next type-prefixed ID by globbing `.sara/pipeline/` at runtime (`ls | grep "^{type_key}-" | sort | tail -1`), creates `.sara/pipeline/{new_id}/` with `mkdir -p`, and writes `.sara/pipeline/{new_id}/state.md` with YAML frontmatter (id, type, filename, source_path, stage, created) using the Write tool only.
- **Step 4 (commit):** `git add` now stages `{source_path}` and `.sara/pipeline/{new_id}/state.md` — no pipeline-state.json reference.
- **STATUS mode:** Uses `grep -rh "^\(id\|type\|stage\|source_path\):" .sara/pipeline/*/state.md` to extract all frontmatter fields in one Bash call, building the table without individual Read tool calls per file.
- **Notes section:** Fully updated — removed all pipeline-state.json references, added notes for mkdir -p, Write-tool-only markdown writes, bulk grep pattern, and filesystem counter derivation.

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite sara-ingest SKILL.md with filesystem-based state | 440a516 | .claude/skills/sara-ingest/SKILL.md |

## Deviations from Plan

None — plan executed exactly as written. All 6 changes (objective text, Step 3 filesystem counter + state.md write, Step 4 git add, Step 6 STATUS mode grep, notes section) applied exactly as specified.

## Known Stubs

None.

## Self-Check

- [x] `.claude/skills/sara-ingest/SKILL.md` exists and was modified
- [x] Commit 440a516 exists
- [x] `grep -c "pipeline-state.json" .claude/skills/sara-ingest/SKILL.md` returns 0
- [x] `grep -q "grep -rh"` matches
- [x] `grep -q "sort | tail -1"` matches
- [x] `grep -q "state.md"` matches
- [x] `grep -q "path traversal"` matches
- [x] `grep -q "mkdir -p"` matches

## Self-Check: PASSED
