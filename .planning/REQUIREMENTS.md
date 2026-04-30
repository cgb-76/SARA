# Requirements: SARA v2.0

**Defined:** 2026-04-30
**Core Value:** Every meeting, email thread, Slack conversation, and document gets permanently integrated into a structured wiki — knowledge compounds across sessions instead of disappearing into chat history.

## v2.0 Requirements

### Cross-Reference Pipeline

- [x] **XREF-01**: sara-extract infers related[] links between artifacts in the same extraction batch
- [x] **XREF-02**: sara-update writes related[] to artifact frontmatter on every page it creates or updates

### sara-lint Repair

- [ ] **XREF-03**: sara-lint detects artifacts with missing or empty related[] frontmatter
- [ ] **XREF-04**: sara-lint detects artifacts with missing or stale Cross Links body sections
- [ ] **XREF-05**: sara-lint repairs related[] and Cross Links on existing wiki pages (not just flags them)

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
| XREF-03 | Phase 15 | Pending |
| XREF-04 | Phase 15 | Pending |
| XREF-05 | Phase 15 | Pending |

**Coverage:**
- v2.0 requirements: 5 total
- Mapped to phases: 5 (100%) ✓
- Unmapped: 0

---
*Requirements defined: 2026-04-30*
*Last updated: 2026-04-30 — traceability mapped after roadmap creation*
