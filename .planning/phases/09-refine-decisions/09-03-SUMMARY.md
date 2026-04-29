---
phase: 09-refine-decisions
plan: "03"
subsystem: sara-update
tags: [decisions, schema, v2.0, sara-update, create-branch, update-branch, status, dec_type]
dependency_graph:
  requires:
    - 09-01 (sara-extract decision pass — provides artifact.dec_type, artifact.status, artifact.chosen_option, artifact.alternatives)
    - 09-02 (sara-init decision template v2.0 — defines the page shape sara-update now writes)
  provides:
    - sara-update decision create branch writes v2.0 frontmatter and five-section body
    - sara-update decision update branch migrates existing pages to v2.0 structure
  affects:
    - .claude/skills/sara-update/SKILL.md
tech_stack:
  added: []
  patterns:
    - Status-conditional body synthesis (accepted vs open decision variants)
    - Update branch migration pattern (parallel to requirement update branch from Phase 8)
    - Wikilink attribution in Source Quote section ([[raised_by|stakeholder_name]])
key_files:
  created: []
  modified:
    - .claude/skills/sara-update/SKILL.md
decisions:
  - "status written from artifact.status (accepted or open) — never hardcoded 'proposed'"
  - "type written from artifact.dec_type — named field avoids collision with envelope type field"
  - "schema_version written as single-quoted '2.0' for decision artifacts — consistent with requirement convention"
  - "Four v1.0 narrative frontmatter fields not written in create branch; removed in update branch"
  - "Decision body is status-conditional: accepted branch uses chosen_option and alternatives; open branch uses 'No decision reached — alignment required.' and competing positions"
  - "Decision update branch inserted after requirement update branch — parallel structure, same migration pattern"
  - "DEC summary generation split into two status-specific variants (accepted and open)"
metrics:
  duration_minutes: 10
  completed_date: "2026-04-29"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 9 Plan 03: Update sara-update Decision Branches to v2.0 Summary

## One-liner

sara-update decision create and update branches rewritten to v2.0: status from artifact.status (never 'proposed'), type from artifact.dec_type, schema_version '2.0', four v1.0 narrative frontmatter fields removed, and a five-section body (Source Quote, Context, Decision, Alternatives Considered, Rationale) with status-conditional content for accepted vs open decisions.

## What Was Built

Two targeted sets of edits to `.claude/skills/sara-update/SKILL.md` covering the decision create branch (Task 1 — three edits) and the decision update branch (Task 2 — one insertion).

**Task 1 — Decision create branch (three edits):**

Edit A — Frontmatter field mapping block (lines 87–92):
- Replaced: `schema_version = "1.0"` for decision artifacts → `schema_version = '2.0'` (single-quoted, consistent with requirement convention)
- Added: `type = artifact.dec_type` for decision artifacts (six-value taxonomy: architectural, process, tooling, data, business-rule, organisational)
- Replaced: `status = "proposed"` (hardcoded) → `status = artifact.status` (either "accepted" or "open" from extraction pass — NEVER hardcode "proposed")
- Added: explicit rule — do NOT write context, decision, rationale, or alternatives-considered frontmatter fields (v1.0 fields removed in schema v2.0)

Edit B — Decision body block:
- Replaced four-section v1.0 body (Context with embedded source quote, Decision, Rationale, Alternatives Considered) with five-section v2.0 layout:
  - `## Source Quote` — verbatim source_quote with wikilink attribution `[[artifact.raised_by|stakeholder_name]]`
  - `## Context` — synthesised from source_doc and discussion_notes; never fabricate
  - `## Decision` — status-conditional: accepted → artifact.chosen_option content; open → "No decision reached — alignment required."
  - `## Alternatives Considered` — status-conditional: accepted → artifact.alternatives list or heading-only; open → competing positions from source
  - `## Rationale` — synthesised; never fabricate

Edit C — DEC summary generation rule:
- Split single rule into two status-specific variants:
  - `DEC (status=accepted): options considered, chosen option, status: accepted, decision date`
  - `DEC (status=open): competing options/positions, alignment not reached, status: open, decision date`

**Task 2 — Decision update branch (one insertion):**

Inserted a new decision update branch block immediately after the requirement update branch block and before the `Use the Write tool to overwrite` line. The decision update branch:
- Maps type from artifact.dec_type, status from artifact.status (strips any existing "proposed" value), schema_version to '2.0'
- Removes v1.0 frontmatter fields if present: context, decision, rationale, alternatives-considered
- Rewrites the full body to the same v2.0 five-section layout as the create branch
- Follows the identical migration pattern established by the requirement update branch in Phase 8

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Update decision create branch to v2.0 frontmatter and body | 1f6fbb5 | .claude/skills/sara-update/SKILL.md |
| 2 | Add decision update branch with v2.0 field mapping and body rewrite | c9a8c7e | .claude/skills/sara-update/SKILL.md |

## Deviations from Plan

None — plan executed exactly as written. All three edits in Task 1 and the single insertion in Task 2 match the plan's specified text verbatim.

## Known Stubs

None — no placeholder values or incomplete wiring introduced. All five body sections have complete synthesis instructions with explicit fallback rules (heading-only if nothing relevant, never fabricate).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. This plan modifies only skill instruction markdown.

Threat register items addressed:
- T-09-08 (hardcoded `proposed` removed): mitigated — `artifact.status` is now the source; "proposed" does not appear as a value being set anywhere in the decision create or update branches
- T-09-09 (field name collision): mitigated — `type = artifact.dec_type` explicit mapping; `dec_type` field name prevents silent collision with envelope `type` field
- T-09-10 (fabricated synthesis): mitigated — both Context and Rationale sections include "never fabricate" instructions; fallback is heading-only

## Self-Check: PASSED

- FOUND: `.claude/skills/sara-update/SKILL.md` — modified in two commits
- FOUND commit 1f6fbb5 (Task 1): feat(09-03): update decision create branch to v2.0 frontmatter and body
- FOUND commit c9a8c7e (Task 2): feat(09-03): add decision update branch with v2.0 field mapping and body rewrite
- `artifact.dec_type` confirmed at lines 89, 307
- `artifact.status` confirmed at lines 91, 219, 222, 225, 229, 308, 323, 324, 327, 328
- `## Source Quote` confirmed in create branch (line 210) and update branch (line 315)
- `No decision reached — alignment required.` confirmed in create branch (line 222) and update branch (line 324)
- `DEC (status=accepted)` and `DEC (status=open)` confirmed at lines 100–101
- `organisational` (British English) confirmed at lines 89 and 307; `organizational` has zero occurrences
- Requirement create body block (`**requirement:**`) unchanged
- Requirement update branch (`For requirement artifacts`) unchanged at lines 284–302
- Decision update branch follows requirement update branch (line 304), before `Use the Write tool to overwrite` (line 334)
