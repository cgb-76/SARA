---
phase: 05-artifact-summaries
plan: "03"
subsystem: sara-skills
tags: [sara-extract, sara-discuss, grep-extract, context-efficiency, dedup, cross-links]
dependency_graph:
  requires: []
  provides: [sara-extract-grep-dedup, sara-discuss-grep-crosslinks]
  affects: [sara-extract, sara-discuss]
tech_stack:
  added: []
  patterns: [grep-extract, summary-only-reads, per-artifact-fallback]
key_files:
  created: []
  modified:
    - .claude/skills/sara-extract/SKILL.md
    - .claude/skills/sara-discuss/SKILL.md
decisions:
  - "sara-extract fallback reads the full artifact page (D-10) for summary-less artifacts; sara-discuss falls back to index Title column only — no full-page reads during discuss"
metrics:
  duration: "61s"
  completed: "2026-04-28T00:00:00Z"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 05 Plan 03: Grep-Extract Pattern for sara-extract and sara-discuss Summary

**One-liner:** Both sara-extract Step 3 and sara-discuss Priority 4 now load all artifact summaries via `grep -rh "^summary:"` before dedup/cross-link decisions, with per-artifact fallback for summary-less pre-Phase-5 artifacts.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Update sara-extract Step 3 to use grep-extract dedup pattern | b587fef | .claude/skills/sara-extract/SKILL.md |
| 2 | Update sara-discuss Step 3 Priority 4 to use grep-extract pattern | 2e9c588 | .claude/skills/sara-discuss/SKILL.md |

## What Was Built

### sara-extract Step 3 (Task 1)

Replaced the index-only dedup description with the grep-extract pattern. Step 3 now instructs the executor to run:

```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
```

before the dedup loop. This loads all artifact summaries compactly in one pass, providing richer semantic signal than the index Title column alone. The D-10 fallback is explicit: for any artifact that appears in `wiki/index.md` but is absent from the grep output, read that artifact's full page using the Read tool — one artifact at a time, not all pages.

The `source_quote` requirement and all downstream schema fields are preserved unchanged.

### sara-discuss Step 3 Priority 4 (Task 2)

Replaced the single-line Priority 4 description with an expanded block that runs the same grep-extract command before identifying cross-link candidates. The D-10 fallback for sara-discuss differs deliberately: fall back to the index Title column only — no full-page reads during discuss, consistent with the context-efficiency goal of Phase 5.

The existing known_names grep in Step 2 (`grep -rh "^\(name\|nickname\):"`) is unchanged.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both skills are fully wired to the grep-extract pattern with explicit fallback rules.

## Threat Flags

No new security-relevant surface introduced. The grep reads user-authored private wiki files into LLM context; this was accepted as T-05-05 in the plan's threat register. The summary_max_words: 50 cap (T-05-06) constrains individual field size.

## Self-Check

**Files exist:**
- .claude/skills/sara-extract/SKILL.md — FOUND
- .claude/skills/sara-discuss/SKILL.md — FOUND

**Commits exist:**
- b587fef — FOUND
- 2e9c588 — FOUND

**Verification:**
- `grep -rh` appears in sara-extract (line 53) and sara-discuss (line 73, distinct from known_names grep at line 51)
- `Fallback` rule appears in both files (sara-extract line 58, sara-discuss line 78)
- sara-discuss known_names grep at Step 2 is unchanged

## Self-Check: PASSED
