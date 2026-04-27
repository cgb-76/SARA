# SARA — v1 Requirements

## v1 Requirements

### Foundation

- [ ] **FOUND-01**: User can run `/sara-init` to create the full directory structure (`/raw/input/`, `/raw/meetings/`, `/raw/emails/`, `/raw/slack/`, `/raw/documents/`, `/wiki/` and subfolders), CLAUDE.md schema, `pipeline-state.json` with ID counters, and entity page templates
- [ ] **FOUND-02**: User can configure project-specific department/vertical list during `/sara-init` (e.g. "Residential and Sales", "Wholesale and Finance")
- [ ] **FOUND-03**: All wiki entity pages include a `schema_version` field in YAML frontmatter from creation, enabling future schema evolution without bulk rewrites
- [ ] **FOUND-04**: `pipeline-state.json` at repo root persists all ingest pipeline state (item registry, stage per item, ID counters per entity type, discussion notes, extraction plan) across Claude Code session boundaries

### Ingest Pipeline

- [ ] **PIPE-01**: User can run `/sara-ingest <type> <filename>` (types: `meeting`, `email`, `slack`, `document`) to register a file from `/raw/input/` as input item N, creating a pipeline entry in `pending` state
- [ ] **PIPE-02**: User can run `/sara-discuss N` to engage in a human-guided discussion of the source; LLM reads the source, discusses key takeaways, surfaces cross-linking opportunities with existing wiki artifacts ("this decision may relate to DEC-003"), and flags unknown stakeholder names for addition to the registry
- [ ] **PIPE-03**: Stakeholders are added to the wiki registry organically — when `/sara-discuss N` surfaces an unknown name, the user confirms and SARA creates a stakeholder page with name, department/vertical, and email
- [ ] **PIPE-04**: User can run `/sara-extract N` to see the full extraction plan (list of artifacts to create or update, with source quote citations for each) before any wiki changes are made; user approves, adjusts, or cancels
- [ ] **PIPE-05**: User can run `/sara-update N` to execute the approved extraction plan atomically — all wiki page writes and `index.md` / `log.md` updates land in a single git commit; source file is renamed with numeric prefix and archived to `/raw/<type>/`; pipeline stage advances to `complete` only after successful commit
- [ ] **PIPE-06**: During `/sara-extract N`, the LLM checks existing wiki pages before proposing new entity creation — updates existing pages rather than creating duplicates ("update, don't duplicate")
- [ ] **PIPE-07**: User can see pipeline status (list of all input items, their type, stage, and filename) without reading raw files — available via `/sara-ingest` with no arguments or as part of `/sara-update` completion output

### Meeting Specialisation

- [ ] **MEET-01**: User can run `/sara-minutes N` (where N is a meeting ingest item) to generate structured meeting minutes as a markdown file filed in the wiki, and an email-ready plain-text version suitable for copy-paste into an email client
- [ ] **MEET-02**: User can run `/sara-meeting-agenda` to generate an email-friendly meeting agenda from user-provided information (attendees, topics, goals); output is a draft for review only — not stored in the wiki

### Wiki Entity Types

- [ ] **WIKI-01**: Requirements wiki pages have structured fields: ID (REQ-NNN), title, status (open/accepted/rejected/superseded), description, source (ingest ID), raised-by (stakeholder ID), owner (stakeholder ID), schema_version, tags, related (cross-references)
- [ ] **WIKI-02**: Decision wiki pages have structured fields: ID (DEC-NNN), title, status (proposed/accepted/rejected/superseded), context, decision, rationale, alternatives-considered, date, deciders (stakeholder IDs), supersedes (DEC-NNN), schema_version, tags, related
- [ ] **WIKI-03**: Action wiki pages have structured fields: ID (ACT-NNN), title, status (open/in-progress/done/cancelled), description, owner (stakeholder ID), due-date, source (ingest ID), schema_version, tags, related
- [ ] **WIKI-04**: Risk wiki pages have structured fields: ID (RISK-NNN), title, status (open/mitigated/accepted/closed), description, likelihood, impact, owner (stakeholder ID), mitigation, source (ingest ID), schema_version, tags, related
- [ ] **WIKI-05**: Stakeholder wiki pages have structured fields: ID (STK-NNN), name, department/vertical, email, role, schema_version, related
- [ ] **WIKI-06**: `wiki/index.md` is an LLM-maintained catalog of all wiki pages — one row per entity with ID, title, status, type, tags, and last-updated; updated atomically as part of every `/sara-update N` commit
- [ ] **WIKI-07**: `wiki/log.md` is an append-only chronological record of all ingest events — each entry records ingest ID, date, source type, source filename, artifacts created/updated

---

## v2 Requirements

- `/sara-query` — natural language query synthesised from wiki with source attribution (wiki page IDs + ingest IDs cited per claim)
- `/sara-lint` — wiki health checks: orphaned pages, broken cross-references, contradicting status fields, stale open Actions, index validation (bidirectional), regenerable index via `--fix`
- `/sara-add-stakeholder` — standalone command for manually adding stakeholders outside the discuss flow
- Agenda linked to ingest item — `/sara-meeting-agenda` optionally creates a pending meeting item; linked when transcript is later ingested
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

*(Populated by roadmapper)*

| REQ-ID | Phase |
|--------|-------|
| FOUND-01 | — |
| FOUND-02 | — |
| FOUND-03 | — |
| FOUND-04 | — |
| PIPE-01 | — |
| PIPE-02 | — |
| PIPE-03 | — |
| PIPE-04 | — |
| PIPE-05 | — |
| PIPE-06 | — |
| PIPE-07 | — |
| MEET-01 | — |
| MEET-02 | — |
| WIKI-01 | — |
| WIKI-02 | — |
| WIKI-03 | — |
| WIKI-04 | — |
| WIKI-05 | — |
| WIKI-06 | — |
| WIKI-07 | — |
