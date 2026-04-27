---
phase: "02-ingest-pipeline"
plan: "01"
subsystem: "schema"
tags: [stakeholder-schema, nickname, test-fixture, sara-init]
dependency_graph:
  requires: []
  provides:
    - "sara-init/SKILL.md nickname-aware stakeholder schema (Step 9 and Step 12)"
    - "raw/input/test-fixture.md mock meeting transcript"
  affects:
    - ".claude/skills/sara-init/SKILL.md"
    - "raw/input/test-fixture.md"
tech_stack:
  added: []
  patterns:
    - "SKILL.md amendment — amend template blocks in existing skill file"
key_files:
  created:
    - raw/input/test-fixture.md
  modified:
    - .claude/skills/sara-init/SKILL.md
decisions:
  - "Amended sara-init SKILL.md (not runtime files) so all future /sara-init runs produce nickname-aware schemas — runtime files (.sara/templates/stakeholder.md, CLAUDE.md) do not yet exist and will be created correctly on first /sara-init run"
metrics:
  duration: "70s"
  completed: "2026-04-27T06:40:00Z"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 2 Plan 01: Amend Stakeholder Schema and Create Test Fixture Summary

**One-liner:** Added nickname field to stakeholder schema in sara-init SKILL.md (Steps 9 and 12) and created a mock meeting transcript exercising all pipeline validation paths including nickname matching.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add nickname field to stakeholder template and CLAUDE.md schema block | 961323b | .claude/skills/sara-init/SKILL.md |
| 2 | Create test fixture transcript in raw/input/ | f99c7a0 | raw/input/test-fixture.md |

## What Was Built

**Task 1 — sara-init SKILL.md amendment:**

The `nickname` field was added to two blocks in `.claude/skills/sara-init/SKILL.md`:
- Step 9 (CLAUDE.md write block, line 281): Stakeholder schema block now includes `nickname: ""` after `name: ""`
- Step 12 (stakeholder template block, line 431): `.sara/templates/stakeholder.md` write block now includes `nickname: ""` after `name: ""`

Field order in both blocks: id, name, nickname, vertical, department, email, role, schema_version, related.

This ensures all future `/sara-init` runs produce nickname-aware schemas. The runtime files (`CLAUDE.md` and `.sara/templates/stakeholder.md`) do not exist yet — they are created by `/sara-init` at project setup time and will include the nickname field when generated.

**Task 2 — Test fixture:**

`raw/input/test-fixture.md` is a 47-line mock meeting transcript covering all pipeline validation paths:
- Known stakeholder by full name: Rajiwath Patel
- Known stakeholder by nickname: Raj (exercises D-07 nickname matching in `/sara-discuss`)
- Unknown stakeholder: Unknown Person (exercises new-stakeholder creation path)
- Extractable requirement: API rate limiting 1000 req/hour per tenant
- Extractable decision: rate limit enforcement supersedes prior informal cap
- Extractable action: Sarah Chen to update auth token spec by 2026-05-10
- Extractable risk: auth token delay blocks rate limiting (high impact, medium likelihood)
- Cross-link topic: authentication token (links to prior architecture sessions)

## Deviations from Plan

**1. [Rule 2 - Scoping note] Runtime files not amended directly**

The plan action for Task 1 listed `.sara/templates/stakeholder.md` and `CLAUDE.md` as files to modify. However, these are runtime artifacts created by `/sara-init` that do not yet exist in the repo. The correct approach — which the plan also specifies — is to amend `sara-init/SKILL.md` so future `/sara-init` runs produce the correct schema. This was done. Amending non-existent runtime files was correctly skipped; only the SKILL.md was modified.

## Known Stubs

None — no placeholder or empty-data stubs introduced.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. Changes are static file amendments and a fixture file with no secrets.

## Self-Check: PASSED

- `.claude/skills/sara-init/SKILL.md` modified: confirmed (2 nickname insertions at lines 281 and 431)
- `raw/input/test-fixture.md` created: confirmed (47 lines, all acceptance criteria pass)
- Commits exist: 961323b (Task 1), f99c7a0 (Task 2)
