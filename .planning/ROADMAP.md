# SARA — Roadmap

## Milestones

- ✅ **v1.0 Core Knowledge Pipeline** — Phases 1–13 (shipped 2026-04-30) — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 xref-fix** — Phases 14–15 (in progress)

## Phases

<details>
<summary>✅ v1.0 Core Knowledge Pipeline (Phases 1–13) — SHIPPED 2026-04-30</summary>

- [x] Phase 1: Foundation & Schema (3/3 plans) — completed 2026-04-27
- [x] Phase 2: Ingest Pipeline (7/7 plans) — completed 2026-04-27
- [x] Phase 3: Meeting Specialisation (3/3 plans) — completed 2026-04-28
- [x] Phase 4: Make Installable (3/3 plans) — completed 2026-04-28
- [x] Phase 5: Artifact Summaries (4/4 plans) — completed 2026-04-28
- [x] Phase 6: Refine Entity Extraction (5/5 plans) — completed 2026-04-28
- [x] Phase 7: Adjust Agent Workflow (3/3 plans) — completed 2026-04-28
- [x] Phase 8: Refine Requirements (3/3 plans) — completed 2026-04-29
- [x] Phase 9: Refine Decisions (3/3 plans) — completed 2026-04-29
- [x] Phase 10: Refine Actions (3/3 plans) — completed 2026-04-29
- [x] Phase 11: Refine Risks (3/3 plans) — completed 2026-04-29
- [x] Phase 12: Vertical Awareness (4/4 plans) — completed 2026-04-30
- [x] Phase 13: Lint Refactor (2/2 plans) — completed 2026-04-30

</details>

### 🚧 v2.0 xref-fix (In Progress)

**Milestone Goal:** Fix cross-referencing so related[] fields and Cross Links sections are correctly populated on all artifact pages after extraction.

- [x] **Phase 14: Extraction Pipeline Fix** - Infer and write related[] links during sara-extract and sara-update (completed 2026-04-30)
- [x] **Phase 15: Lint Repair** - Detect and repair missing related[] and Cross Links on existing wiki pages (completed 2026-04-30)

## Phase Details

### Phase 14: Extraction Pipeline Fix
**Goal**: sara-extract infers related[] links between co-extracted artifacts and sara-update writes them to frontmatter
**Depends on**: Phase 13
**Requirements**: XREF-01, XREF-02
**Success Criteria** (what must be TRUE):
  1. After sara-extract, the extraction plan includes related[] fields linking co-extracted artifacts to each other
  2. After sara-update, every newly created or updated artifact page has a populated related[] frontmatter field referencing its batch peers
  3. Artifacts extracted in isolation (single-artifact batch) have an empty related[] rather than a missing field
**Plans**: 2 plans

Plans:
- [x] 14-01-PLAN.md — Add temp_id to sara-extract Step 3 passes and full-mesh linking to Step 5
- [x] 14-02-PLAN.md — Add temp_id→real_id resolution block to sara-update Step 2

### Phase 15: Lint Repair
**Goal**: sara-lint detects missing or stale related[] and Cross Links on existing wiki pages and repairs them without user having to re-run the ingest pipeline
**Depends on**: Phase 14
**Requirements**: XREF-03, XREF-04, XREF-05
**Success Criteria** (what must be TRUE):
  1. sara-lint reports each artifact page that has a missing or empty related[] frontmatter field
  2. sara-lint reports each artifact page whose Cross Links body section is missing or does not match the current related[] frontmatter
  3. When the user approves a repair, sara-lint writes the corrected related[] and Cross Links to the page and commits the change
  4. After a full lint + repair run, re-running sara-lint reports zero related[]/Cross Links findings
**Plans**: 3 plans

Plans:
- [x] 15-01-PLAN.md — Revert Phase 14: remove temp_id blocks from sara-extract Step 3 (×4) and Step 5
- [x] 15-02-PLAN.md — Revert Phase 14: remove temp_id resolution from sara-update Step 2; add sara-lint auto-invoke
- [x] 15-03-PLAN.md — Extend sara-lint: D-06 two-pass + D-07 semantic related[] curation check

### Phase 16: tagging
**Goal**: Activate the `tags: []` schema field by implementing sara-lint D-08 — a whole-wiki two-phase LLM pass that derives an emergent tag vocabulary from the corpus and assigns tags to every artifact page
**Depends on**: Phase 15
**Requirements**: TAG-01, TAG-02, TAG-03, TAG-04, TAG-05, TAG-06, TAG-07, TAG-08, TAG-09, TAG-10
**Success Criteria** (what must be TRUE):
  1. sara-lint Step 6 runs D-08 on every invocation (including auto-invoke from sara-update) after the per-finding loop
  2. D-08 derives a whole-wiki emergent tag vocabulary and presents it for user approval before any writes
  3. After vocabulary approval, D-08 assigns tags to all four artifact directories and commits them atomically
  4. Tags are lowercase kebab-case; full replacement semantics on every run
**Plans**: 1 plan

Plans:
- [ ] 16-01-PLAN.md — Add sara-lint objective update + Step 6 D-08 whole-wiki tag curation

### Phase 17: document-based-statefulness

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 16
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 17 to break down)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation & Schema | v1.0 | 3/3 | Complete | 2026-04-27 |
| 2. Ingest Pipeline | v1.0 | 7/7 | Complete | 2026-04-27 |
| 3. Meeting Specialisation | v1.0 | 3/3 | Complete | 2026-04-28 |
| 4. Make Installable | v1.0 | 3/3 | Complete | 2026-04-28 |
| 5. Artifact Summaries | v1.0 | 4/4 | Complete | 2026-04-28 |
| 6. Refine Entity Extraction | v1.0 | 5/5 | Complete | 2026-04-28 |
| 7. Adjust Agent Workflow | v1.0 | 3/3 | Complete | 2026-04-28 |
| 8. Refine Requirements | v1.0 | 3/3 | Complete | 2026-04-29 |
| 9. Refine Decisions | v1.0 | 3/3 | Complete | 2026-04-29 |
| 10. Refine Actions | v1.0 | 3/3 | Complete | 2026-04-29 |
| 11. Refine Risks | v1.0 | 3/3 | Complete | 2026-04-29 |
| 12. Vertical Awareness | v1.0 | 4/4 | Complete | 2026-04-30 |
| 13. Lint Refactor | v1.0 | 2/2 | Complete | 2026-04-30 |
| 14. Extraction Pipeline Fix | v2.0 | 2/2 | Complete    | 2026-04-30 |
| 15. Lint Repair | v2.0 | 3/3 | Complete    | 2026-04-30 |
| 16. Tagging | v2.0 | 0/1 | Planned | — |
