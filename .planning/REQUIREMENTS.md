# SARA — v1 Requirements

## v1 Requirements

### Foundation

- [x] **FOUND-01
**: User can run `/sara-init` to create the full directory structure (`/raw/input/`, `/raw/meetings/`, `/raw/emails/`, `/raw/slack/`, `/raw/documents/`, `/wiki/` and subfolders), CLAUDE.md schema, `pipeline-state.json` with ID counters, and entity page templates
- [x] **FOUND-02
**: User can configure project-specific vertical list (e.g. Residential, Enterprise, Wholesale) and department list (e.g. Sales, Operations, Finance) separately during `/sara-init` — these are distinct axes; a stakeholder belongs to one vertical and one department
- [x] **FOUND-03
**: All wiki entity pages include a `schema_version` field in YAML frontmatter from creation, enabling future schema evolution without bulk rewrites
- [x] **FOUND-04
**: `.sara/pipeline-state.json` persists all ingest pipeline state (item registry, stage per item, ID counters per entity type, discussion notes, extraction plan) across Claude Code session boundaries

### Ingest Pipeline

- [x] **PIPE-01
**: User can run `/sara-ingest <type> <filename>` (types: `meeting`, `email`, `slack`, `document`) to register a file from `/raw/input/` as input item N, creating a pipeline entry in `pending` state
- [x] **PIPE-02
**: User can run `/sara-discuss N` to engage in a human-guided discussion of the source; LLM reads the source, discusses key takeaways, surfaces cross-linking opportunities with existing wiki artifacts ("this decision may relate to DEC-003"), and flags unknown stakeholder names for addition to the registry
- [x] **PIPE-03
**: Stakeholders are added to the wiki registry organically — when `/sara-discuss N` surfaces an unknown name, the user confirms and SARA creates a stakeholder page with name, department/vertical, and email
- [x] **PIPE-04
**: User can run `/sara-extract N` to see the full extraction plan (list of artifacts to create or update, with source quote citations for each) before any wiki changes are made; user approves, adjusts, or cancels
- [x] **PIPE-05
**: User can run `/sara-update N` to execute the approved extraction plan atomically — all wiki page writes and `index.md` / `log.md` updates land in a single git commit; source file is renamed with numeric prefix and archived to `/raw/<type>/`; pipeline stage advances to `complete` only after successful commit
- [x] **PIPE-06
**: During `/sara-extract N`, the LLM checks existing wiki pages before proposing new entity creation — updates existing pages rather than creating duplicates ("update, don't duplicate")
- [x] **PIPE-07
**: User can see pipeline status (list of all input items, their type, stage, and filename) without reading raw files — available via `/sara-ingest` with no arguments or as part of `/sara-update` completion output

### Meeting Specialisation

*(Deferred to backlog at v1.0 close — 2026-04-30. Skills exist but MEET-01 has a known pipeline-state.json write-back bug; moved to v2 backlog for proper fix.)*

### Wiki Entity Types

- [x] **WIKI-01
**: Requirements wiki pages have structured fields: ID (REQ-NNN), title, status (open/accepted/rejected/superseded), description, source (ingest ID), raised-by (stakeholder ID), owner (stakeholder ID), schema_version, tags, related (cross-references)
- [x] **WIKI-02
**: Decision wiki pages have structured fields: ID (DEC-NNN), title, status (proposed/accepted/rejected/superseded), context, decision, rationale, alternatives-considered, date, deciders (stakeholder IDs), supersedes (DEC-NNN), schema_version, tags, related
- [x] **WIKI-03
**: Action wiki pages have structured fields: ID (ACT-NNN), title, status (open/in-progress/done/cancelled), description, owner (stakeholder ID), due-date, source (ingest ID), schema_version, tags, related
- [x] **WIKI-04
**: Risk wiki pages have structured fields: ID (RISK-NNN), title, status (open/mitigated/accepted/closed), description, likelihood, impact, owner (stakeholder ID), mitigation, source (ingest ID), schema_version, tags, related
- [x] **WIKI-05
**: Stakeholder wiki pages have structured fields: ID (STK-NNN), name, vertical (e.g. Residential), department (e.g. Sales), email, role, schema_version, related — vertical and department are separate fields drawn from the project config lists defined at init
- [x] **WIKI-06
**: `wiki/index.md` is an LLM-maintained catalog of all wiki pages — one row per entity with ID, title, status, type, tags, and last-updated; updated atomically as part of every `/sara-update N` commit
- [x] **WIKI-07
**: `wiki/log.md` is an append-only chronological record of all ingest events — each entry records ingest ID, date, source type, source filename, artifacts created/updated

---

## v2 Requirements

- **MEET-01** (deferred from v1): `/sara-minutes N` generates structured meeting minutes — fix `sara-update` to write `assigned_id` back to `extraction_plan` items in `pipeline-state.json` before advancing stage
- **MEET-02** (deferred from v1): `/sara-agenda` generates email-friendly meeting agenda — skill exists and is stateless; add formal verification
- `/sara-query` — natural language query synthesised from wiki with source attribution (wiki page IDs + ingest IDs cited per claim)
- `/sara-lint` — extended health checks: contradicting status fields, stale open Actions
- `/sara-add-stakeholder` — already shipped in v1 (Phase 6)
- Agenda linked to ingest item — `/sara-agenda` optionally creates a pending meeting item; linked when transcript is later ingested
- Full-text search via `ripgrep` — supplement `index.md` routing at scale
- External integrations (Jira, Linear, email send)

---

## Out of Scope

- Real-time multi-user collaboration — one repo per project; multi-user via separate clones, not shared state
- Embedding-based RAG / vector stores — contradicts the llm-wiki premise; `index.md` is sufficient at v1 scale
- Proprietary formats — all output is CommonMark markdown + YAML frontmatter; no Obsidian wiki-links
- Standalone app or web UI — SARA is Claude Code skills only
- Automatic transcript capture — user sources and drops transcripts; SARA does not record meetings

---

## Traceability

| REQ-ID | Phase |
|--------|-------|
| FOUND-01 | Phase 1 — Foundation & Schema |
| FOUND-02 | Phase 1 — Foundation & Schema |
| FOUND-03 | Phase 1 — Foundation & Schema |
| FOUND-04 | Phase 1 — Foundation & Schema |
| WIKI-01 | Phase 1 — Foundation & Schema |
| WIKI-02 | Phase 1 — Foundation & Schema |
| WIKI-03 | Phase 1 — Foundation & Schema |
| WIKI-04 | Phase 1 — Foundation & Schema |
| WIKI-05 | Phase 1 — Foundation & Schema |
| WIKI-06 | Phase 1 — Foundation & Schema |
| WIKI-07 | Phase 1 — Foundation & Schema |
| PIPE-01 | Phase 2 — Ingest Pipeline |
| PIPE-02 | Phase 2 — Ingest Pipeline |
| PIPE-03 | Phase 2 — Ingest Pipeline |
| PIPE-04 | Phase 2 — Ingest Pipeline |
| PIPE-05 | Phase 2 — Ingest Pipeline |
| PIPE-06 | Phase 2 — Ingest Pipeline |
| PIPE-07 | Phase 2 — Ingest Pipeline |
| MEET-01 | Deferred to v2 backlog (2026-04-30) |
| MEET-02 | Deferred to v2 backlog (2026-04-30) |
