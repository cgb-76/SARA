---
plan: 06-04
phase: 06-refine-entity-extraction
status: complete
executed_inline: true
---

## Summary

Two independent changes: narrowed sara-discuss scope and added agent distribution to install.sh.

## What Was Built

**Task 1 — sara-discuss SKILL.md:**
- Objective updated: "Classification, deduplication, and cross-reference reasoning now belong to the sorter agent in `/sara-extract`"
- Step 3: removed Priority 2 (entity type), Priority 3 (context gaps), Priority 4 (cross-links); replaced with Priority 2 "Source comprehension blockers"
- Step 5: replaced with source comprehension blocker resolution only
- Step 6 discussion_notes compile list: removed entity type decisions and cross-link confirmations bullets
- Notes: updated to remove P2-4 references; added sorter handoff note

**Task 2 — install.sh:**
- Added AGENTS array listing all 5 agent files
- Added TARGET_AGENTS_DIR loop after skills loop, before post-install output
- Reuses INSTALLED array and --backup flag; no downgrade check (agents have no version field)
- bash -n syntax validation passed

## Acceptance Criteria

- [x] "Classification, deduplication, and cross-reference reasoning now belong to the sorter" in sara-discuss
- [x] Old Priority 2 (entity type), Priority 3, Priority 4 removed
- [x] New Priority 2 (source comprehension) added
- [x] Steps 1, 2, 4, 6 preserved; frontmatter unchanged
- [x] TARGET_AGENTS_DIR in install.sh
- [x] All 5 agent names in install.sh
- [x] bash -n install.sh exits 0

## Commits

- `da49d7c` feat(06-04): narrow sara-discuss to source comprehension + STK surfacing only
- `e69d231` feat(06-04): add agent distribution loop to install.sh

## Self-Check: PASSED
