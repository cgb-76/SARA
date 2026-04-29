# SARA — Roadmap

**Milestone:** v1 — Core Knowledge Pipeline
**Requirements:** 20 v1 requirements
**Generated:** 2008-04-27

---

## Phase Summary

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|-----------------|
| 1 | Foundation & Schema | User can initialise a new SARA wiki with locked schemas and a working `/sara-init` command | FOUND-01, FOUND-02, FOUND-03, FOUND-04, WIKI-01, WIKI-02, WIKI-03, WIKI-04, WIKI-05, WIKI-06, WIKI-07 | 4 |
| 2 | Ingest Pipeline | User can take any source document through the full ingest pipeline — ingest, discuss, extract, update — and have structured artifacts committed to the wiki | PIPE-01, PIPE-02, PIPE-03, PIPE-04, PIPE-05, PIPE-06, PIPE-07 | 5 |
| 3 | Meeting Specialisation | User can generate meeting minutes and a pre-meeting agenda from meeting-specific commands | MEET-01, MEET-02 | 3 |
| 4 | Make Installable | Any user can install SARA skills into their project with a single shell command | — | 3 |
| 5 | Artifact Summaries | All wiki artifact types carry a compact summary field; sara-extract and sara-discuss use grep-extract for context-efficient cross-referencing; /sara-lint back-fills existing artifacts | — | 4 |
| 6 | Refine Entity Extraction | sara-extract dispatches to specialist agents per entity type; a sorter agent deduplicates and resolves ambiguities; sara-discuss is narrowed to source comprehension and stakeholder surfacing only | — | 3 |

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
- MEET-01: `/sara-minutes N` generates structured meeting minutes (markdown block + email-ready plain-text) output to screen only — wiki is the data source, not the destination (revised from original spec)
- MEET-02: `/sara-agenda` generates an email-friendly agenda from user-provided attendees, topics, and goals — output is a draft only, not stored in the wiki

**Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md — /sara-minutes skill: type + stage guards, extraction_plan aggregation, plain-text terminal output (MEET-01)
- [x] 03-02-PLAN.md — /sara-agenda skill: freeform prompt, stateless plain-text agenda generation (MEET-02)
- [x] 03-03-PLAN.md — End-to-end verification checkpoint and planning doc updates

**Success Criteria:**
1. User runs `/sara-minutes N` on a meeting ingest item and receives a markdown minutes block and a plain-text email-ready block in the same terminal response — nothing is written to the wiki
2. User runs `/sara-agenda` with attendee names and topic inputs and receives a formatted plain-text agenda draft — the wiki directory contains no new files after the command completes
3. `/sara-minutes N` run on a non-meeting ingest type returns a clear error rather than generating a nonsensical output

**Dependencies:** Phase 2

---

### Phase 4: Make Installable

**Goal:** Any user can install SARA skills into their own Claude Code project with a single shell command — skills are versioned, overwrite-safe, and self-documenting via README

**Requirements:** No formal requirement IDs — this phase adds distribution infrastructure outside the v1 numbered requirement set

**Depends on:** Phase 3
**Plans:** 3 plans

Plans:
- [ ] 04-01-PLAN.md — Add `version: 1.0.0` to YAML frontmatter of all 8 existing SKILL.md files
- [ ] 04-02-PLAN.md — Write install.sh: git guard, dynamic sara-* glob, --backup, downgrade protection, next-step message
- [ ] 04-03-PLAN.md — Create README.md with Installation section + human end-to-end verification checkpoint

**Success Criteria:**
1. User runs `./install.sh --target /path/to/project` and all 8 sara-* skill directories are copied into the target's `.claude/skills/`
2. Running install.sh outside a git repo produces a plain-English error and exits non-zero
3. Running install.sh with `--backup` preserves an existing SKILL.md as SKILL.md.bak before overwriting

### Phase 5: Artifact Summaries

**Goal:** All wiki artifact types carry a compact `summary` field; sara-extract and sara-discuss use a grep-extract pattern for context-efficient cross-referencing at scale; /sara-lint back-fills existing artifacts missing the summary field

**Requirements:** No formal requirement IDs — this phase adds schema extensions and context-efficiency improvements

**Depends on:** Phase 4
**Plans:** 4 plans

Plans:
- [x] 05-01-PLAN.md — Add summary field to sara-init SKILL.md (pipeline-state.json template, CLAUDE.md behavioral rule, all 5 entity schema blocks and template writes)
- [x] 05-02-PLAN.md — Add summary generation to sara-update Step 2 (create and update branches, summary_max_words with fallback)
- [x] 05-03-PLAN.md — Switch sara-extract Step 3 and sara-discuss Priority 4 to grep-extract pattern with fallback for summary-less artifacts
- [x] 05-04-PLAN.md — Create /sara-lint skill: wiki guard, grep -rL scan, dry-run confirm, batch write-back, commit, Check 2/3 stubs

**Success Criteria:**
1. Running `/sara-init` in a fresh directory produces pipeline-state.json with `summary_max_words: 50`, CLAUDE.md with rule 6 (Summary field), and five templates each containing a `summary:` field
2. Running `/sara-update N` produces wiki artifact files where every newly created or updated artifact has a non-empty `summary` field in its frontmatter
3. Running `/sara-extract N` on a wiki with 100+ artifacts uses a single grep command rather than reading individual artifact pages for the dedup check
4. Running `/sara-lint` on a wiki with pre-existing summary-less artifacts presents a count + preview, asks for confirmation, back-fills all missing summaries, and commits with message `fix(wiki): back-fill artifact summaries via sara-lint`

### Phase 6: Refine Entity Extraction

**Goal:** sara-extract dispatches to four specialist extraction agents (one per entity type) and a sorter agent via Task(); the sorter deduplicates, resolves create-vs-update, and surfaces ambiguity questions for the human before the per-artifact approval loop; sara-discuss is narrowed to source comprehension and unknown-stakeholder surfacing only; install.sh distributes the new agent files

**Requirements:** No formal requirement IDs — this phase refactors extraction architecture without changing the v1 requirement set

**Depends on:** Phase 5
**Plans:** 5 plans

Plans:
- [x] 06-01-PLAN.md — Create four specialist agent files in .claude/agents/ (requirement, decision, action, risk extractors)
- [x] 06-02-PLAN.md — Create sara-artifact-sorter agent file in .claude/agents/
- [x] 06-03-PLAN.md — Rewrite sara-extract SKILL.md Steps 2-3 with multi-agent dispatch and sorter question resolution
- [x] 06-04-PLAN.md — Narrow sara-discuss SKILL.md scope; update install.sh with agent distribution loop
- [x] 06-05-PLAN.md — Static file audit + end-to-end verification checkpoint

**Success Criteria:**
1. Running `/sara-extract N` dispatches four specialist Task() calls and one sorter Task() call — specialist agents extract only their own artifact type; sorter resolves create-vs-update and presents ambiguity questions before the approval loop starts
2. Running `/sara-discuss N` produces a blocker list with Priority 1 (unknown stakeholders) and Priority 2 (source comprehension) only — no entity type classification questions
3. Running `install.sh` in a target project copies both the nine skill files AND all five agent files to the correct `.claude/` subdirectories

### Phase 7: adjust-agent-workflow

**Goal:** Replace the four specialist Task() extraction agents in sara-extract with sequential inline extraction passes; delete the four agent files; update install.sh to distribute only the sorter agent

**Requirements:** No formal requirement IDs — this phase refactors extraction architecture for token efficiency
**Depends on:** Phase 6
**Plans:** 3 plans

Plans:
- [x] 07-01-PLAN.md — Rewrite sara-extract Step 3 with sequential inline extraction passes
- [x] 07-02-PLAN.md — Delete specialist agent files; update install.sh AGENTS array
- [x] 07-03-PLAN.md — End-to-end verification checkpoint
