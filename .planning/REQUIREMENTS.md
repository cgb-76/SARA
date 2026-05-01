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

**Coverage:**
- v2.0 requirements: 15 total
- Mapped to phases: 15 (100%) ✓
- Unmapped: 0

---
*Requirements defined: 2026-04-30*
*Last updated: 2026-05-01 — TAG-01 through TAG-10 added for Phase 16*
