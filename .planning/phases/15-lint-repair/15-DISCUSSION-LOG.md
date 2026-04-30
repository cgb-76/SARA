# Phase 15: Lint Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 15-lint-repair
**Areas discussed:** Phase 14 revert, Semantic related[] repair strategy, Pipeline integration, Cross Links behaviour

---

## Phase 14 Revert

| Option | Description | Selected |
|--------|-------------|----------|
| Fix sara-extract in Phase 15 | Remove full-mesh temp_id logic, add LLM inference | ✓ |
| Leave Phase 14 as-is | Keep batch-mate linking, lint cleans up | |
| Fix Phase 14 as separate hotfix | Revert first, then Phase 15 | |

**User's choice:** Fix sara-extract and sara-update in Phase 15.
**Notes:** User clarified that batch co-extraction does not imply semantic relatedness. RSK-001 and ACT-003 are related because the action addresses the risk — not because they were extracted from the same meeting. Both sara-lint and sara-extract were supposed to use LLM-driven semantic inference, not mechanical batch-mate linking.

---

## Repair Strategy for related[]

| Option | Description | Selected |
|--------|-------------|----------|
| pipeline-state.json batch lookup | Find batch-mates by source_id | |
| Git history co-commit scan | Find co-committed files | |
| LLM semantic inference | LLM reads artifact + entire wiki, infers relationships | ✓ |
| User-specified each time | Manual per-artifact | |

**User's choice:** LLM reads the artifact and the entire wiki, infers related[], proposes list for user approval.
**Notes:** User rejected batch-mate approaches. Semantic relatedness is the criterion, not co-extraction. User's exact framing: "just because they're imported together doesn't count as being related."

---

## Architecture — Centralise in sara-lint

| Option | Description | Selected |
|--------|-------------|----------|
| Keep related[] in extract pipeline | Each command manages its own related[] | |
| Centralise in sara-lint | Remove from pipeline, all curation via sara-lint | ✓ |

**User's choice:** Remove related[] logic from sara-extract and sara-update entirely. sara-lint is the single place for all related[] curation.
**Notes:** User's framing: "why not just run /sara-lint at the end of the pipeline? Centralising all our curation stuff in a single command."

---

## Pipeline Hook

| Option | Description | Selected |
|--------|-------------|----------|
| sara-update prompts user to run lint | Manual follow-up | |
| sara-update auto-invokes sara-lint | Automatic, inline | ✓ |
| Separate — user runs lint whenever | Standalone only | |

**User's choice:** sara-update auto-invokes sara-lint as its final step.

---

## D-07 Scope

| Option | Description | Selected |
|--------|-------------|----------|
| All wiki pages missing/empty related[] | Full wiki scan every run | ✓ |
| Only newly-written pages from current run | Scoped to current pipeline batch | |

**User's choice:** All wiki pages — full scan every time.

---

## Cross Links for empty related[]

| Option | Description | Selected |
|--------|-------------|----------|
| Absent — remove or don't add section | No Cross Links when related: [] | |
| Keep empty section header | ## Cross Links present but empty | ✓ |

**User's choice:** Keep the `## Cross Links` section header even when related: [].

---

## Claude's Discretion

- Exact mechanism to distinguish "LLM-confirmed empty related[]" from "default empty related[] never curated" — to avoid re-flagging the same pages on every re-run
- Ordering of D-07 within the lint check sequence
- Context window strategy for LLM inference pass on large wikis
