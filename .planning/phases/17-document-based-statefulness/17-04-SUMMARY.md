---
phase: 17-document-based-statefulness
plan: "04"
subsystem: sara-extract
tags: [skill-rewrite, pipeline-state, document-based, sara-extract]
dependency_graph:
  requires: [17-01, 17-02]
  provides: [sara-extract-state-md-guard, sara-extract-plan-md-write]
  affects: [sara-update]
tech_stack:
  added: []
  patterns: [state.md-stage-guard, discuss.md-graceful-fallback, plan.md-headed-sections, atomic-commit-ordering]
key_files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md
decisions:
  - "plan.md uses headed-section-per-artifact format (one ## per artifact) — Claude's Discretion resolution from RESEARCH.md Pattern 4"
  - "Stage advance to approved happens ONLY after git commit of plan.md succeeds (Pitfall 1 guard)"
  - "discuss.md absent is not an error — empty-string fallback preserves extraction continuity"
metrics:
  duration: "3m 39s"
  completed: "2026-05-01T04:10:49Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 17 Plan 04: Sara-Extract State.md/Discuss.md/Plan.md Rewrite Summary

**One-liner:** Replaced pipeline-state.json read/write in sara-extract with state.md stage guard (extracting), discuss.md read with graceful empty-string fallback, and plan.md headed-section write with atomic commit ordering before stage advance.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite sara-extract SKILL.md with state.md guard, discuss.md read, and plan.md write | 124e99d | .claude/skills/sara-extract/SKILL.md |

## What Was Built

Updated `.claude/skills/sara-extract/SKILL.md` (v1.0.0 → v2.0.0) with six targeted changes:

**CHANGE 1 — Objective text:** Updated to describe plan.md output instead of pipeline-state.json extraction_plan field.

**CHANGE 2 — Step 1 (Stage guard):** Replaced pipeline-state.json read + items["{N}"] lookup with Read tool on `.sara/pipeline/{N}/state.md`. If file is absent → item-not-found error. Parses frontmatter fields (id, type, filename, source_path, stage, created). Guards on `stage: extracting`.

**CHANGE 3 — Step 2 (Discussion notes):** Replaced `items["{N}"].discussion_notes` JSON field access with Read tool on `.sara/pipeline/{N}/discuss.md`. If file absent → `{discussion_notes} = ""`, continue without error (Pitfall 6 guard). If present → use markdown body as discussion context.

**CHANGE 4 — Step 3 (Extraction passes):** Confirmed no pipeline-state.json references existed here. Four inline passes (requirements, decisions, actions, risks), sorter dispatch, and sorter question loop preserved verbatim.

**CHANGE 5 — Step 5 (Write plan and advance stage):** Removed pipeline-state.json read/write block. Replaced with:
- Compose plan.md with one `##` section per approved artifact (headed-section-per-artifact format)
- Write `.sara/pipeline/{N}/plan.md` using Write tool
- `git add plan.md && git commit` — check exit code
- If commit FAILS: output error, STOP, leave state.md unchanged (stage: extracting)
- If commit SUCCEEDS: Read state.md, reconstruct frontmatter with `stage: approved`, Write state.md, `git add state.md && git commit`

**CHANGE 6 — Notes section:** Removed pipeline-state.json/extraction_plan references. Added:
- "plan.md is written using the Write tool only — no Bash text-processing on markdown files."
- CRITICAL Pitfall 1 note: stage advance to 'approved' ONLY after git commit of plan.md succeeds
- discuss.md graceful fallback note
- N argument format note updated for directory-based lookup

## Verification

All acceptance criteria passed:
- `grep -c "pipeline-state.json" .claude/skills/sara-extract/SKILL.md` → 0
- `grep -c "extraction_plan" .claude/skills/sara-extract/SKILL.md` → 0
- Step 1 reads `.sara/pipeline/{N}/state.md` and checks `stage: extracting` — confirmed
- Step 2 reads `.sara/pipeline/{N}/discuss.md` with graceful empty fallback — confirmed
- Step 5 writes `.sara/pipeline/{N}/plan.md` using Write tool — confirmed
- Step 5 writes state.md with `stage: approved` ONLY after git commit succeeds — confirmed
- Notes contain "Stage advance to 'approved' happens ONLY after the git commit" — confirmed
- Notes contain "discuss.md graceful fallback" — confirmed

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no stub patterns introduced. The skill is a complete behavioural specification.

## Threat Flags

No new security surface introduced. This plan modifies an internal skill file (markdown instruction document). No new network endpoints, auth paths, or trust boundaries added.

Threat mitigations from plan's threat model confirmed implemented:
- T-17-04-01 (Stage advance before commit): Mitigated — Step 5 explicitly sequences write plan.md → git commit → only if success write state.md stage: approved. Notes CRITICAL Pitfall 1 note enforces this.
- T-17-04-03 (discuss.md absent): Mitigated — Graceful empty-string fallback explicitly implemented in Step 2 and documented in Notes.

## Self-Check: PASSED

- File exists: `/home/george/Projects/sara/.claude/skills/sara-extract/SKILL.md` — FOUND
- Commit exists: `124e99d` — FOUND (git log --oneline -1 confirms)
- No pipeline-state.json references: grep -c returns 0 — CONFIRMED
- No extraction_plan references: grep -c returns 0 — CONFIRMED
- plan.md write present: grep -n returns matches — CONFIRMED
- Stage ordering note present: grep -n "ONLY after" returns match — CONFIRMED
- discuss.md graceful fallback note present: grep -n "graceful" returns match — CONFIRMED
