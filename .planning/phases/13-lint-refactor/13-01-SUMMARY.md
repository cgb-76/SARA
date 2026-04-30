---
phase: 13-lint-refactor
plan: "01"
subsystem: sara-lint
tags: [skill, lint, wiki, v2.0, mechanical-checks]
dependency_graph:
  requires: []
  provides: [sara-lint-v2.0]
  affects: [wiki-artifact-pages, wiki/index.md]
tech_stack:
  added: []
  patterns: [grep-rL-scan, per-finding-askuserquestion, atomic-per-fix-commit, read-write-only-markdown, exit-code-check]
key_files:
  created: []
  modified:
    - .claude/skills/sara-lint/SKILL.md
decisions:
  - Replaced entire v1 stub file with v2.0 full implementation — no stub sections remain
  - All five checks (D-02 through D-06) collect findings upfront before presenting any to user
  - Per-finding AskUserQuestion loop with Apply/Skip per decision D-08
  - One commit per accepted fix per decision D-09
  - segments: (plural) excluded from STK pages — STK gets singular segment: only
  - T-13-04 mitigation applied: commit stages explicit file paths only, commit messages are templated
metrics:
  duration: "127s (~2m)"
  completed_date: "2026-04-30"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 13 Plan 01: sara-lint v2.0 Rewrite Summary

## One-liner

Full rewrite of sara-lint SKILL.md from v1 (single stub-heavy check) to v2.0 with five mechanical checks covering schema_version/field gaps (D-02), broken related[] IDs (D-03), orphaned pages (D-04), index↔disk sync (D-05), and Cross Links divergence (D-06).

## What Was Built

`.claude/skills/sara-lint/SKILL.md` rewritten from version 1.0.0 to version 2.0.0.

**v1 state:** Implemented Check 1 (missing summaries — batch confirm, single commit for all). Checks 2 and 3 were explicit stubs with "not implemented" text.

**v2.0 state:** Five fully implemented mechanical checks, each operating via grep scans collecting all findings upfront, then presenting each finding individually via AskUserQuestion with Apply/Skip options, and committing each accepted fix atomically with exit code validation.

### Checks implemented

| Check | Description | Grep/Tool pattern |
|-------|-------------|-------------------|
| D-02 | Missing v2.0 frontmatter fields (9 fields across 5 entity types) | `grep -rL "^field:"` per field/dir combination |
| D-03 | Broken related[] IDs — IDs that resolve to no file on disk | Read file + `ls wiki/{dir}/{ID}.md ... \| wc -l` |
| D-04 | Orphaned pages not listed in wiki/index.md | `find wiki/...` + Read index + ID lookup |
| D-05 | Stale index rows with no corresponding disk file | Index ID extraction cross-referenced against disk_files |
| D-06 | Cross Links body section diverges from related[] frontmatter | Read file + compare frontmatter list vs body section IDs |

### Back-fill inference rules

All nine v2.0 fields have explicit inference rules:
- `schema_version` — write `'2.0'` directly
- `type` — classify from body sections per entity type (REQ/DEC/ACT/RSK each with specific vocabulary)
- `priority` — classify from modal verbs in REQ Statement section
- `segments` — infer from STK segment attribution + keyword matching against config.segments
- `likelihood` / `impact` — scan body for high/medium/low keywords
- `due-date` / `owner` — scan body sections and related STK pages
- `segment` (STK) — keyword match against config_segments

### Field insertion rules

Each field has a specified insertion position within the YAML frontmatter block (e.g., `schema_version` after `tags:`, `type` after `status:`, `segment` after `role:` for STK).

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite sara-lint/SKILL.md — v2.0 full implementation | 3cc4a4c | .claude/skills/sara-lint/SKILL.md |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The file contains no stub sections. All five checks are fully implemented with complete logic.

## Threat Flags

No new threat surface introduced. The skill operates on local wiki files only (no network, no external APIs). T-13-04 mitigation applied: commit stages explicit file paths, commit messages use templated strings only.

## Self-Check: PASSED

- File exists: `.claude/skills/sara-lint/SKILL.md` — FOUND
- Contains `version: 2.0.0` — VERIFIED
- Contains all 5 checks (D-02 through D-06) — VERIFIED (grep -c "Check D-0" returns 6)
- Contains `AskUserQuestion` — VERIFIED
- Contains `echo "EXIT:$?"` — VERIFIED
- Contains `grep -rL "^schema_version:"` — VERIFIED
- Contains `grep -rL "^segments:"` — VERIFIED
- Contains `grep -rL "^segment:"` — VERIFIED
- Contains `grep -rL "^type:"` — VERIFIED
- Contains `config_segments` — VERIFIED
- Contains `wiki/index.md` — VERIFIED
- Contains `## Cross Links` — VERIFIED
- Contains `find wiki/requirements` — VERIFIED
- Does NOT contain `version: 1.0.0` — VERIFIED
- Does NOT contain "stub, not implemented" — VERIFIED (grep -c "stub" returns 0)
- Frontmatter `---` count ≥ 4 — VERIFIED (returns 11)
- Commit 3cc4a4c exists — VERIFIED
