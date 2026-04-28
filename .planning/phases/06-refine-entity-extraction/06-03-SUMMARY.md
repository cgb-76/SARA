---
plan: 06-03
phase: 06-refine-entity-extraction
status: complete
executed_inline: true
---

## Summary

Rewrote `sara-extract` SKILL.md Steps 2 and 3 to replace the monolithic single-agent extraction with a multi-agent dispatch pipeline.

## What Was Built

- **Objective block** updated to describe the new pipeline: specialist dispatch → sorter → question resolution → approval loop
- **Step 2** heading updated from "Load source, discussion notes, and dedup context" to "Load source, discussion notes, and wiki index"
- **Step 3** replaced: old monolithic "For each extractable topic" loop removed; new Step 3 dispatches four specialist agents (`sara-requirement-extractor`, `sara-decision-extractor`, `sara-action-extractor`, `sara-risk-extractor`) via Task() in parallel, merges output, runs grep summaries, dispatches `sara-artifact-sorter`, presents sorter questions to human, then feeds `cleaned_artifacts` to Step 4
- **Steps 1, 4, 5** preserved verbatim
- **Notes block** extended with 4 new bullets: agent dispatch summary, sorter questions before loop guard (Pitfall 4), empty array handling, discussion_notes explicit pass guard (Pitfall 1)

## Acceptance Criteria

- [x] `sara-requirement-extractor` referenced in SKILL.md
- [x] `sara-decision-extractor` referenced in SKILL.md
- [x] `sara-action-extractor` referenced in SKILL.md
- [x] `sara-risk-extractor` referenced in SKILL.md
- [x] `sara-artifact-sorter` referenced in SKILL.md
- [x] `sorter_questions` referenced in SKILL.md
- [x] `cleaned_artifacts` referenced in SKILL.md
- [x] Step 4 preserved verbatim
- [x] Step 5 preserved verbatim
- [x] `version: 1.0.0` frontmatter unchanged
- [x] Old monolithic Step 3 ("For each extractable topic") removed
- [x] Pitfall 1 and Pitfall 4 guards in notes

## Commits

- `dacd5eb` feat(06-03): rewrite sara-extract Steps 2-3 with multi-agent dispatch pipeline

## Self-Check: PASSED
