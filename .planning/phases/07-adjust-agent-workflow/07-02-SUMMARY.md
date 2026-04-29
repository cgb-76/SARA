---
phase: 7
plan: 02
title: "Delete specialist agent files and update install.sh distribution"
subsystem: agents
tags: [cleanup, install, agents]
dependency_graph:
  requires: ["07-01"]
  provides: []
  affects: [install.sh, .claude/agents/]
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - install.sh
  deleted:
    - .claude/agents/sara-requirement-extractor.md
    - .claude/agents/sara-decision-extractor.md
    - .claude/agents/sara-action-extractor.md
    - .claude/agents/sara-risk-extractor.md
decisions:
  - Only sara-artifact-sorter.md remains in .claude/agents/ — four specialist extractor agents removed as extraction is now handled inline by sara-extract
metrics:
  duration: "~5 minutes"
  completed: "2026-04-29"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 7 Plan 02: Delete specialist agent files and update install.sh distribution Summary

**One-liner:** Deleted four specialist extractor agent files and trimmed install.sh AGENTS array to retain only sara-artifact-sorter.

## What Was Done

Removed the four specialist extractor agent files that are no longer needed following the Phase 7 Plan 01 rewrite of sara-extract to perform inline extraction passes. Updated install.sh to distribute only the remaining sara-artifact-sorter agent.

## Tasks Completed

| Task | Title | Commit |
|------|-------|--------|
| T01 | Delete four specialist agent files | ace2e15 |
| T02 | Update install.sh AGENTS array | 61f4a9c |

## Files Changed

**Deleted:**
- `.claude/agents/sara-requirement-extractor.md`
- `.claude/agents/sara-decision-extractor.md`
- `.claude/agents/sara-action-extractor.md`
- `.claude/agents/sara-risk-extractor.md`

**Modified:**
- `install.sh` — AGENTS array reduced from 5 entries to 1 (`sara-artifact-sorter` only)

## Verification Results

1. `ls .claude/agents/` — only `sara-artifact-sorter.md` present
2. No specialist extractor references in install.sh
3. `sara-artifact-sorter` appears exactly once in install.sh AGENTS array
4. `bash -n install.sh` exits 0 (syntax valid)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — changes are deletions and array trimming with no new security surface.

## Self-Check: PASSED

- `ace2e15` exists in git log: FOUND
- `61f4a9c` exists in git log: FOUND
- `.claude/agents/sara-artifact-sorter.md` exists: FOUND
- Deleted files absent: VERIFIED
