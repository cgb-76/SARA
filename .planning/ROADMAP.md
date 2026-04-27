# SARA — Roadmap

**Milestone:** v1 — Core Knowledge Pipeline
**Requirements:** 20 v1 requirements
**Generated:** 2026-04-27

---

## Phase Summary

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|-----------------|
| 1 | Foundation & Schema | User can initialise a new SARA wiki with locked schemas and a working `/sara-init` command | FOUND-01, FOUND-02, FOUND-03, FOUND-04, WIKI-01, WIKI-02, WIKI-03, WIKI-04, WIKI-05, WIKI-06, WIKI-07 | 4 |
| 2 | Ingest Pipeline | User can take any source document through the full ingest pipeline — ingest, discuss, extract, update — and have structured artifacts committed to the wiki | PIPE-01, PIPE-02, PIPE-03, PIPE-04, PIPE-05, PIPE-06, PIPE-07 | 5 |
| 3 | Meeting Specialisation | User can generate meeting minutes and a pre-meeting agenda from meeting-specific commands | MEET-01, MEET-02 | 3 |

---

## Phase Details

### Phase 1: Foundation & Schema

**Goal:** User can run `/sara-init` to create a fully structured SARA wiki with all entity schemas locked, pipeline state initialised, and project configuration captured — ready to accept its first ingest

**Requirements:**
- FOUND-01: `/sara-init` creates full directory structure, CLAUDE.md schema, `.sara/pipeline-state.json`, and entity page templates
- FOUND-02: `/sara-init` prompts for and stores project-specific vertical list (e.g. Residential, Enterprise, Wholesale) and department list (e.g. Sales, Operations, Finance) as separate axes
- FOUND-03: All wiki entity pages include a `schema_version` field in YAML frontmatter from creation
- FOUND-04: `pipeline-state.json` persists all pipeline state (item registry, stage, ID counters, discussion notes, extraction plan) across Claude Code session boundaries
- WIKI-01: Requirements pages have structured YAML frontmatter (ID, title, status, description, source, raised-by, owner, schema_version, tags, related)
- WIKI-02: Decision pages have structured YAML frontmatter (ID, title, status, context, decision, rationale, alternatives-considered, date, deciders, supersedes, schema_version, tags, related)
- WIKI-03: Action pages have structured YAML frontmatter (ID, title, status, description, owner, due-date, source, schema_version, tags, related)
- WIKI-04: Risk pages have structured YAML frontmatter (ID, title, status, description, likelihood, impact, owner, mitigation, source, schema_version, tags, related)
- WIKI-05: Stakeholder pages have structured YAML frontmatter (ID, name, vertical, department, email, role, schema_version, related) — vertical and department are separate fields from the project config lists
- WIKI-06: `wiki/index.md` is an LLM-maintained catalog with one row per entity (ID, title, status, type, tags, last-updated)
- WIKI-07: `wiki/log.md` is an append-only chronological record of all ingest events

**Plans:** 3 plans

Plans:
- [x] 01-01-PLAN.md — Write sara-init SKILL.md scaffold: guard clause, user input collection, directory creation, .sara/config.json and pipeline-state.json writes
- [x] 01-02-PLAN.md — Complete SKILL.md: wiki/CLAUDE.md schema contract, wiki/index.md and wiki/log.md stubs, five entity templates, success report and notes
- [x] 01-03-PLAN.md — End-to-end verification: run /sara-init in temp directory, verify all outputs, confirm guard clause, human approval checkpoint

**Success Criteria:**
1. User runs `/sara-init` in an empty directory and the complete `/raw/` and `/wiki/` tree is created with no manual steps
2. User is prompted for vertical names (e.g. Residential, Enterprise) and department names (e.g. Sales, Finance) separately during init — both lists appear in the project config and a different project produces different lists
3. A freshly created entity page template (for each of the five types) contains a `schema_version` field and all required YAML frontmatter fields with no omissions
4. `.sara/pipeline-state.json` exists after init with correct structure — reopening a new Claude Code session against the repo allows pipeline commands to read existing state without error

**Dependencies:** None

---

### Phase 2: Ingest Pipeline

**Goal:** User can take any supported source type through the complete four-stage pipeline (ingest → discuss → extract → update), with human approval at each stage, resulting in structured wiki artifacts committed atomically to git

**Requirements:**
- PIPE-01: `/sara-ingest <type> <filename>` registers a file from `/raw/input/` as item N in `pending` state
- PIPE-02: `/sara-discuss N` reads the source, surfaces key takeaways, flags cross-linking opportunities with existing wiki artifacts, and identifies unknown stakeholder names
- PIPE-03: Unknown stakeholders surfaced in `/sara-discuss N` can be confirmed and created as stakeholder pages by the user
- PIPE-04: `/sara-extract N` presents a full artifact list with source-quote citations for every proposed item; user approves, adjusts, or cancels before any wiki changes
- PIPE-05: `/sara-update N` executes the approved plan atomically — all wiki writes, `index.md` and `log.md` updates land in one git commit; source file is archived with numeric prefix; stage advances to `complete` only after successful commit
- PIPE-06: During `/sara-extract N` the LLM checks existing wiki pages and proposes updates rather than duplicate creation
- PIPE-07: `/sara-ingest` with no arguments displays pipeline status (all items, type, stage, filename)

**Plans:** 7 plans

Plans:
- [x] 02-01-PLAN.md — Phase 1 amendments: add nickname field to stakeholder template and CLAUDE.md schema block; create test fixture transcript
- [x] 02-02-PLAN.md — /sara-ingest skill: register file as pipeline item + pipeline status table (PIPE-01, PIPE-07)
- [x] 02-03-PLAN.md — /sara-add-stakeholder skill: capture fields, write STK page, commit atomically (PIPE-03)
- [x] 02-04-PLAN.md — /sara-discuss skill: LLM-driven blocker-clearing session with inline /sara-add-stakeholder (PIPE-02, PIPE-03)
- [x] 02-05-PLAN.md — /sara-extract skill: per-artifact approval loop with source quotes and dedup check (PIPE-04, PIPE-06)
- [x] 02-06-PLAN.md — /sara-update skill: atomic wiki commit, source archiving, stage advance after commit (PIPE-05)
- [x] 02-07-PLAN.md — End-to-end verification: full pipeline run with test fixture, human approval checkpoint

**Success Criteria:**
1. User drops a file in `/raw/input/`, runs `/sara-ingest meeting file.md`, and sees item N created in `pending` state — re-running `/sara-ingest` with no args shows the item in the backlog
2. User runs `/sara-discuss N` and receives a contextual discussion that references existing wiki artifacts by ID, not just a list of possible extractions
3. User runs `/sara-extract N` and every proposed artifact shows a quoted passage from the source document — no artifact is proposed without evidence
4. User runs `/sara-update N` and the result is a single git commit containing all new and updated wiki pages plus `index.md` and `log.md` updates; the source file is renamed and moved to `/raw/<type>/`
5. Running `/sara-extract N` against a source that mentions a topic already covered in the wiki results in an update proposal for the existing page, not creation of a duplicate

**Dependencies:** Phase 1

---

### Phase 3: Meeting Specialisation

**Goal:** User can generate structured meeting minutes from a completed meeting ingest item, and produce a pre-meeting agenda on demand — with no wiki changes required for agenda generation

**Requirements:**
- MEET-01: `/sara-minutes N` generates structured markdown minutes filed in the wiki and an email-ready plain-text version
- MEET-02: `/sara-meeting-agenda` generates an email-friendly agenda from user-provided attendees, topics, and goals — output is a draft only, not stored in the wiki

**Success Criteria:**
1. User runs `/sara-minutes N` on a meeting ingest item and receives both a markdown file committed to the wiki and a plain-text block ready to paste into an email client
2. User runs `/sara-meeting-agenda` with attendee names and topic inputs and receives a formatted agenda draft — the wiki directory contains no new files after the command completes
3. `/sara-minutes N` run on a non-meeting ingest type returns a clear error rather than generating a nonsensical output

**Dependencies:** Phase 2

---

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Foundation & Schema | Done | - |
| 2. Ingest Pipeline | Done | - |
| 3. Meeting Specialisation | Not started | - |
