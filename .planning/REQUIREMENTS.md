# Requirements: SARA v2.0

**Defined:** 2026-04-30
**Core Value:** Every meeting, email thread, Slack conversation, and document gets permanently integrated into a structured wiki — knowledge compounds across sessions instead of disappearing into chat history.

## v2.0 Requirements

### Cross-Reference Pipeline

- [x] **XREF-01**: sara-extract infers related[] links between artifacts in the same extraction batch
- [x] **XREF-02**: sara-update writes related[] to artifact frontmatter on every page it creates or updates

### sara-lint Repair

- [x] **XREF-03**: sara-lint detects artifacts with missing or empty related[] frontmatter
- [x] **XREF-04**: sara-lint detects artifacts with missing or stale Cross Links body sections
- [x] **XREF-05**: sara-lint repairs related[] and Cross Links on existing wiki pages (not just flags them)

### Tagging

- [x] **TAG-01**: sara-lint D-08 check exists as Step 6, runs after the per-finding loop on every invocation
- [x] **TAG-02**: D-08 vocabulary derivation pass reads all artifact pages and derives emergent concept-level tags
- [x] **TAG-03**: D-08 presents derived vocabulary to the user via AskUserQuestion (Approve / Edit / Skip) before any writes
- [x] **TAG-04**: D-08 assignment pass fires only after vocabulary is approved (not before)
- [x] **TAG-05**: All tags are normalised to lowercase kebab-case before presentation and before any write
- [x] **TAG-06**: D-08 assignment targets all four artifact directories (requirements, decisions, actions, risks)
- [x] **TAG-07**: All tag writes from a single D-08 run are committed as one atomic commit with message `fix(wiki): update tags via sara-lint D-08`
- [x] **TAG-08**: D-08 runs on every sara-lint invocation — no opt-in flag required
- [x] **TAG-09**: Every D-08 run fully replaces existing tags — no merging with previous assignments
- [x] **TAG-10**: D-08 exits gracefully (without prompting) when no artifact pages exist in the wiki

### Document-Based Statefulness

- [x] **STF-01**: sara-init creates `.sara/pipeline/` directory with `.gitkeep` (not `pipeline-state.json`); adds `summary_max_words: 50` to `config.json`; generated CLAUDE.md uses filesystem-derived ID assignment
- [x] **STF-02**: sara-ingest derives next ingest ID from filesystem glob of `.sara/pipeline/`; creates item directory; writes `state.md` with YAML frontmatter; STATUS mode uses `grep -rh` across `state.md` files
- [x] **STF-03**: sara-discuss reads `state.md` for stage guard; writes `discuss.md` as markdown prose; advances `stage: extracting` in `state.md` ONLY after git commit of `discuss.md` succeeds
- [x] **STF-04**: sara-extract reads `state.md` for stage guard; reads `discuss.md` (empty-string fallback if absent); writes approved artifact list as headed markdown to `plan.md`; advances `stage: approved` in `state.md` ONLY after git commit of `plan.md` succeeds
- [x] **STF-05**: sara-update reads `state.md` for stage guard; LLM-parses `plan.md` for artifact list; derives entity IDs from filesystem glob of `wiki/{type}/`; reads `summary_max_words` from `config.json`; advances `stage: complete` in `state.md` ONLY after wiki commit succeeds
- [x] **STF-06**: sara-minutes reads `state.md` for type guard (meeting) then stage guard (complete); discovers actual entity IDs from `wiki/log.md` log row wikilinks (not plan.md placeholder IDs)

## Future Requirements

- **QUERY-01**: /sara-query answers questions synthesised from wiki content
- **EXT-01**: External integrations (Jira, Linear, email send)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Embedding-based search | index.md sufficient at current scale |
| Real-time multi-user collaboration | Multi-user via separate repos by design |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| XREF-01 | Phase 14 | Complete |
| XREF-02 | Phase 14 | Complete |
| XREF-03 | Phase 15 | Complete |
| XREF-04 | Phase 15 | Complete |
| XREF-05 | Phase 15 | Complete |
| TAG-01 | Phase 16 | Planned |
| TAG-02 | Phase 16 | Planned |
| TAG-03 | Phase 16 | Planned |
| TAG-04 | Phase 16 | Planned |
| TAG-05 | Phase 16 | Planned |
| TAG-06 | Phase 16 | Planned |
| TAG-07 | Phase 16 | Planned |
| TAG-08 | Phase 16 | Planned |
| TAG-09 | Phase 16 | Planned |
| TAG-10 | Phase 16 | Planned |
| STF-01 | Phase 17 | Planned |
| STF-02 | Phase 17 | Planned |
| STF-03 | Phase 17 | Planned |
| STF-04 | Phase 17 | Planned |
| STF-05 | Phase 17 | Planned |
| STF-06 | Phase 17 | Planned |

**Coverage:**
- v2.0 requirements: 21 total
- Mapped to phases: 21 (100%) ✓
- Unmapped: 0

---
*Requirements defined: 2026-04-30*
*Last updated: 2026-05-01 — STF-01 through STF-06 added for Phase 17*
