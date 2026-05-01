---
phase: 16-tagging
plan: "01"
subsystem: sara-lint
tags: [sara-lint, tags, tag-curation, D-08, kebab-case, vocabulary-derivation]

# Dependency graph
requires:
  - phase: 15-lint-repair
    provides: "D-07 semantic related[] curation, AskUserQuestion gate pattern, atomic commit per finding, T-13-04 explicit file staging"
provides:
  - "D-08 whole-wiki tag curation as Step 6 of sara-lint"
  - "Two-phase vocabulary derivation and assignment pass"
  - "Vocabulary approval gate with Approve/Edit/Skip options"
  - "Kebab-case normalisation enforcement before write"
  - "Full-replacement tag semantics on every run"
  - "Empty-wiki guard (zero artifact pages exits gracefully)"
  - "Atomic commit of all tag writes via explicit file list (T-13-04)"
affects: [sara-query, future-phases-using-tags, sara-lint-extensions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Post-finding-loop step pattern: D-08 runs after Step 5 (not inside per-finding loop)"
    - "Vocabulary-first approval gate: derive corpus vocabulary, present for approval, then batch assign"
    - "Context window strategy: 20-page threshold — full read <= 20, frontmatter+summary > 20"
    - "Full-replacement corpus operation: re-derive from scratch on every invocation, no tag merging"

key-files:
  created: []
  modified:
    - ".claude/skills/sara-lint/SKILL.md"

key-decisions:
  - "D-08 positioned as Step 6 (post-finding loop), not as a per-finding check — vocabulary must precede assignment"
  - "AskUserQuestion options are Approve/Edit/Skip — Edit re-normalises user input before proceeding"
  - "Single atomic commit for all tag writes (full-replacement semantics, T-13-04 explicit paths)"
  - "20-page threshold from D-07 reused for vocabulary derivation context window management"

patterns-established:
  - "Whole-corpus LLM batch operation pattern: derive vocabulary across all pages, approve, assign, write, commit"
  - "Re-read-before-write enforced at assignment pass (Step 5 fixes may have modified pages since Phase 1)"

requirements-completed: [TAG-01, TAG-02, TAG-03, TAG-04, TAG-05, TAG-06, TAG-07, TAG-08, TAG-09, TAG-10]

# Metrics
duration: 15min
completed: 2026-05-01
---

# Phase 16 Plan 01: Sara-lint Step 6 — D-08 Whole-Wiki Tag Curation Summary

**D-08 whole-wiki two-phase tag curation (vocabulary derivation + assignment) added to sara-lint as Step 6, with kebab-case normalisation, vocabulary approval gate, full-replacement semantics, and T-13-04 atomic commit**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-01T00:00:00Z
- **Completed:** 2026-05-01T00:15:00Z
- **Tasks:** 2 (Task 1 in prior agent, Task 2 in this agent)
- **Files modified:** 1

## Accomplishments

- Updated sara-lint objective line to declare "six mechanical checks plus whole-wiki tag curation (D-08)" with trailing sentence describing D-08's behaviour
- Added complete Step 6 block (D-08 Tag curation) after the existing field insertion rules, before `</process>` — 113 lines of new skill prose
- Step 6 implements the full D-08 flow: empty-wiki guard, Phase 1 vocabulary derivation with 20-page context window strategy, AskUserQuestion approval gate (Approve/Edit/Skip), Phase 2 per-page assignment pass, assignment summary table, tag write loop with re-read-before-write, and single atomic commit using explicit file paths (T-13-04)

## Task Commits

Each task was committed atomically:

1. **Task 1: Update sara-lint objective line** - `b6526c6` (feat) — committed by prior agent
2. **Task 2: Add Step 6 — D-08 tag curation** - `135079b` (feat)

**Plan metadata:** (this SUMMARY.md commit)

## Files Created/Modified

- `.claude/skills/sara-lint/SKILL.md` — objective line updated (Task 1), Step 6 block added (Task 2)

## Decisions Made

- Positioned D-08 as Step 6 (post-finding loop) rather than injecting into Step 3/5: vocabulary derivation requires all pages to be read before assignment can occur, and the per-finding loop model cannot accommodate a batch operation
- Reused D-07's 20-page threshold for context window management in the vocabulary derivation pass
- Used single atomic commit for all tag writes: full-replacement semantics means the entire run is one logical operation
- AskUserQuestion "Edit" branch re-normalises user input to kebab-case before storing as approved vocabulary — ensures normalisation applies to both LLM-derived and human-edited tags

## Deviations from Plan

None — plan executed exactly as written. Step 6 block inserted verbatim from Task 2 `<action>` section.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. D-08 uses tools already in sara-lint's `allowed-tools` list (Read, Write, Bash, AskUserQuestion).

## Next Phase Readiness

- Sara-lint now supports D-08 whole-wiki tag curation on every invocation
- Tags written to `tags: []` frontmatter fields already present on all artifact pages (REQ, DEC, ACT, RSK)
- Future `/sara-query` command can use tags as a filter axis
- wiki/index.md Tags column reflects tags via D-04 re-processing on subsequent lint runs

## Self-Check: PASSED

- `.claude/skills/sara-lint/SKILL.md` exists and contains Step 6 block (verified via Read tool)
- `b6526c6` (Task 1 commit) present in git log — `git log --oneline --all | grep b6526c6`
- `135079b` (Task 2 commit) present in git log — `git log --oneline -1` returns `135079b`
- All 12 acceptance criteria grep checks passed (D-08 count: 8, Step 6: present, all TAG-NN requirements satisfied)

---
*Phase: 16-tagging*
*Completed: 2026-05-01*
