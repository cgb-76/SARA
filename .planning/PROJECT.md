# SARA — Solution Architecture Recall Assistant

## What This Is

SARA is a personal, git-backed LLM knowledgebase for solution design, operated entirely through Claude Code slash commands. It draws on Andrej Karpathy's llm-wiki pattern: instead of one-shot RAG (rediscovering knowledge each query), SARA maintains a persistent, compounding wiki — structured markdown files that get richer with every source ingested. One SARA repo per project; domain-agnostic (adapts to software architecture, enterprise architecture, or anything in between).

## Core Value

Every meeting, email thread, Slack conversation, and document gets permanently integrated into a structured wiki — knowledge compounds across sessions instead of disappearing into chat history.

## Requirements

### Validated

- [x] `/sara-init` sets up a new SARA wiki (directory structure, schema, vertical list and department list — separate axes) — Phase 1
- [x] `/sara-ingest <type> <filename>` registers a raw input item (meeting, email, slack, document) from `/raw/input/`, assigns ingest ID N — Phase 2
- [x] `/sara-discuss N` guides a human-in-the-loop discussion of source N, agreeing on extraction intent — Phase 2
- [x] `/sara-extract N` presents the extraction plan (artifacts to create/update) for user approval before any wiki changes — Phase 2
- [x] `/sara-update N` writes approved artifacts to the wiki, commits, moves source file to processed subfolder with numeric prefix — Phase 2
- [x] Five wiki entity types with structured fields: Requirements, Decisions, Actions, Risks, Stakeholders — Phase 1
- [x] Stakeholders tracked with name, nickname, department, vertical, email; linked to all artifact types — Phase 2
- [x] SARA maintains pipeline state per input item (stage, discussion context) — resumable across sessions — Phase 1
- [x] Processed sources renamed with numeric prefix and archived to type subfolder (`/raw/meetings/`, `/raw/emails/`, etc.) — Phase 2
- [x] `/sara-minutes N` generates plain-text meeting minutes output to terminal only — wiki is the data source, not the destination — Phase 3
- [x] `/sara-agenda` generates a throw-away plain-text agenda draft from user input — not stored in the wiki — Phase 3

### Active

- [ ] `/sara-query` answers questions synthesised from wiki content — v2
- [ ] `/sara-lint` health-checks the wiki (orphans, contradictions, stale content, missing cross-references) — v2

### Out of Scope

- Real-time multi-user collaboration — multi-user via separate repos, not shared state
- Agenda linked to ingest item — throw-away in v1; natural v2 enhancement
- Embedding-based search — `index.md` sufficient at v1 scale; `qmd` or similar is v2
- External integrations (Jira, Linear, email send) — v2

## Context

**Inspiration:** Andrej Karpathy's llm-wiki pattern — the insight that LLMs maintaining a persistent wiki outperforms RAG because knowledge is compiled once and kept current, not re-derived on every query. Obsidian as the IDE, LLM as the programmer, wiki as the codebase.

**GSD influence:** SARA's slash command structure mirrors Get Shit Done (GSD). The ingest pipeline phases (ingest → discuss → extract → update) map directly to GSD's phase lifecycle (discuss → plan → execute → verify). Each input item is stateful, human-gated, and resumable — not a one-shot orchestrator.

**Target user:** George (personal use). Clone-able — others can run their own SARA instance per project. Not designed for concurrent multi-user access to the same repo (git conflicts).

**Runtime:** Claude Code (skills/slash commands).

## Directory Structure

```
/raw/
  input/          ← staging bucket — drop files here before ingesting
  meetings/       ← processed transcripts, prefixed by ingest ID (e.g. 003-standup-2026-04-27.md)
  emails/
  slack/
  documents/
/wiki/
  index.md        ← catalog of all wiki pages (LLM updates on every ingest)
  log.md          ← append-only chronological record of ingests, queries, lints
  requirements/   ← requirement pages
  decisions/      ← decision pages (ADR-style)
  actions/        ← action item pages (tracked open/closed, assigned to stakeholder)
  risks/          ← risk pages
  stakeholders/   ← stakeholder pages (name, department, email)
```

## Command Taxonomy

| Category | Commands | Description |
|----------|----------|-------------|
| **Generate** | `/sara-agenda` | Produce output from user input; throw-away |
| **Initialize** | `/sara-init` | Set up wiki, config, directory structure |
| **Process** | `/sara-ingest`, `/sara-discuss N`, `/sara-extract N`, `/sara-update N`, `/sara-minutes N` | Stateful ingest pipeline |
| **Query** | `/sara-query` | Synthesise answers from wiki |
| **Maintain** | `/sara-lint` | Wiki health checks |

## Ingest Pipeline

All input types follow: **ingest → discuss → extract → update**

Meetings also include: **→ minutes**

| Step | Command | Who acts | Output |
|------|---------|----------|--------|
| Register | `/sara-ingest meeting transcript.md` | Human drops file + runs command | Input item N created, pending |
| Discuss | `/sara-discuss N` | Human + LLM together | Agreed extraction intent |
| Extract | `/sara-extract N` | LLM proposes, human approves | Approved artifact list |
| Update | `/sara-update N` | LLM writes, human confirms | Wiki updated, source archived |
| Minutes | `/sara-minutes N` | LLM generates | Markdown + email draft |

## Constraints

- **Runtime**: Claude Code — SARA is a set of skills/slash commands, not a standalone app
- **Single-user per repo**: by design; multi-user via separate clones
- **Git-backed**: all wiki changes are committed; full history, branching for free
- **Project-scoped**: one SARA repo per project; vertical list and department list configured separately at init time

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| One repo per project | Each project has its own stakeholder set, department config, and artifact space | Validated — Phase 1 |
| Stateful, human-gated pipeline | User said "stay involved" — not a one-shot processor | Validated — Phase 2 |
| `/sara-agenda` is throw-away in v1 | Can't cleanly fit pre-ingest state into ingest pipeline without complicating `/sara-ingest` | Validated — Phase 3 pending |
| Five entity types (incl. Stakeholders) | Stakeholders are reference data that enable named entity linking and email automation | Validated — Phase 1 |
| Processed files renamed + archived by type | Numeric prefix links archive to state; subfolder makes raw archive browsable | Validated — Phase 2 |
| Departments are project-specific config | Domain-agnostic — the department list is defined at `/sara-init` time per project | Validated — Phase 1 |
| Stakeholder schema includes nickname field | Dual-field matching in `/sara-discuss` requires a short-form alias alongside full name | Validated — Phase 2 |
| `schema_version` quoted as string '1.0' | Prevents Obsidian YAML float parse of bare 1.0 | Validated — Phase 1 |
| `stage=complete` written only after git commit | Prevents permanent item strand on commit failure | Validated — Phase 2 |
| Extraction uses four inline passes, not specialist agents | Token efficiency: source document stays in context; only small merged artifact array passed to sorter | Validated — Phase 7 |
| Requirements extraction anchored on modal verbs (must/shall/should/could/won't) | Eliminates false positives (observations, aspirations, background context) that the old catch-all pass produced | Validated — Phase 8 |
| Requirement pages use v2.0 schema (7-section body, section matrix, type + priority fields) | Structured sections enable consistent cross-requirement comparison; section matrix keeps pages lean by type | Validated — Phase 8 |
| schema_version '2.0' uses single quotes | Prevents YAML float parse of "2.0" across all parsers (Obsidian, Python, etc.) | Validated — Phase 8 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-29 after Phase 8 completion — modal-verb anchored requirement extraction, MoSCoW priority + six-type classification inline, v2.0 requirement schema (7-section body, section matrix), sara-init templates updated, sara-update writes v2.0 pages. All v2.0 milestone phases complete.*
