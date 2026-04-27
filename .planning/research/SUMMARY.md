# Research Summary — SARA

**Project:** SARA — Solution Architecture Recall Assistant
**Domain:** LLM-powered personal knowledge management / solution architecture wiki
**Researched:** 2026-04-27
**Confidence:** MEDIUM-HIGH

## Executive Summary

SARA is a set of Claude Code slash commands implementing Karpathy's llm-wiki pattern: a persistent, git-backed wiki that compounds knowledge across sessions rather than re-deriving it on every query. The correct mental model is "the wiki is code; the LLM is the interpreter." This means zero runtime dependencies — no databases, no vector stores, no templating engines. Markdown and YAML are the stack; bash tool calls handle git and file operations; the LLM reads plain text natively. The decisive architectural call is that SARA is not an application — it is a set of skills operating within Claude Code.

The recommended approach is a four-phase ingest pipeline (ingest → discuss → extract → update) with explicit human approval at each step. This is the core competitive differentiator: every competitor either auto-extracts (Mem, Otter — produces noisy, low-trust output) or leaves all organisation to the user (Obsidian — requires discipline that degrades). SARA's human-in-the-loop gate is not a limitation — it is the product. Five strongly-typed entity types (Requirements, Decisions, Actions, Risks, Stakeholders) with cross-linked YAML frontmatter give the wiki structure that enables precise querying. `pipeline-state.json` at the repo root is the session bridge that makes each pipeline step resumable across Claude Code session boundaries.

The critical risks are structural, not technical. Friction accumulates until personal tools are abandoned — the pipeline must feel worthwhile at every step, not bureaucratic. Wiki drift (LLM creating new pages that silently contradict existing ones) is the second existential risk; it is mitigated by "update, don't duplicate" as a hard rule during extraction, and by `/sara-lint` run as routine hygiene. Schema decisions made in Phase 1 (entity types, state file schema, ID namespacing, `schema_version` fields, atomic commit strategy) cannot be retrofitted later without rewriting every wiki page — they must be correct before the first ingest.

---

## Recommended Stack

SARA's stack is intentionally library-free. The LLM itself is the processor; bash tool calls handle all external operations; the file system is the database.

**Core technologies:**
- Claude Code slash commands (`.claude/commands/*.md`): runtime — the only viable runtime given SARA's definition as a set of skills
- YAML frontmatter + markdown body (one file per artifact): wiki entity format — LLM-native, git-diffable, Obsidian-compatible, zero dependencies
- `pipeline-state.json` at repo root: session bridge — JSON chosen over YAML for state because LLMs write JSON reliably and structured state validation is easier
- `wiki/index.md`: LLM-maintained artifact catalog — sufficient at personal scale (under 200 artifacts); LLM reads it before every query to scope its page reads
- Git CLI via bash tool: version control — raw CLI, no library, fully debuggable
- `ripgrep` (v2 only): full-text search when index approach reaches scale ceiling

**Explicitly not used:** RAG / vector stores, SQLite, Node.js / Python runtime, templating engines, Obsidian wiki-links, TOML frontmatter, email sending libraries, CLAUDE.md as mutable state store.

---

## Table Stakes

Features that must exist for SARA to be usable at all:

- **Natural-language query over stored knowledge** — the primary value proposition; covered by `/sara-query` reading `index.md` then targeted wiki pages
- **Persistent storage across sessions** — git-backed wiki covers this; pipeline state must be resumable across Claude Code session resets
- **Meeting summary and action item extraction** — universal expectation set by Otter/Fireflies/Granola; covered by `/sara-minutes` and the Actions entity type
- **Source attribution on query answers** — `/sara-query` must cite wiki page IDs and ingest IDs for every claim; without this, synthesised answers are untrustworthy; currently underspecified in v1 requirements
- **Readable, portable output** — markdown + git; no proprietary lock-in
- **Status visibility** — user must be able to see pipeline backlog without reading files; currently underspecified

---

## Key Differentiators

Where SARA's approach creates genuine competitive advantage — double down here:

**Process-gated, human-in-the-loop extraction.** The four-stage gate (ingest → discuss → extract → update) is SARA's moat. The discuss stage should be a rich, contextual conversation — the LLM should proactively surface cross-linking opportunities ("I see a tension between this decision and REQ-003 — shall I flag it as a risk?"), not just ask "what should I extract?" This is the least replicable part of the design.

**Typed, cross-linked artifact schema.** Five entity types with bidirectional links enable precise queries that untyped tools (Mem, Notion) cannot match. Cross-linking at extraction time — explicitly surfacing "this decision supersedes DEC-007" rather than silently creating DEC-012 — is the critical quality lever.

**Git as knowledge substrate.** Automatic atomic commits with structured messages make `git log` a meaningful audit trail. No competitor offers this. The commit message format ("Ingest 007: Meeting — Architecture Review. Created: ADR-003, REQ-012. Updated: RISK-004.") must be standardised in the command, not left to LLM improvisation.

**Compounding wiki vs one-shot RAG.** Knowledge compiled once; subsequent queries benefit from all prior ingests. The wiki gets smarter over time. Design `index.md` and entity pages for machine readability (dense, cross-referenced, LLM-scannable), not human aesthetics.

**Ambient operator surface.** SARA lives inside the user's existing Claude Code environment — zero tool-switching cost. Command discoverability and pipeline state visibility matter more than a GUI.

---

## Critical Decisions Before Building

Decisions that must be made before writing a single command. Getting these wrong means rewriting everything:

1. **Pipeline state schema** — fields, structure, and location of `pipeline-state.json` must be finalised before any command is written. Must include: ingest ID counter, per-type artifact ID counters, stage enum, discussion notes, extraction plan, and artifact list per item.

2. **Entity schemas with `schema_version`** — all five entity types must be fully specified including a `schema_version` field on every page from day one. Without it, schema evolution requires bulk-editing every existing page.

3. **CLAUDE.md scope** — thin CLAUDE.md (project identity, core rules, ID conventions, cross-linking rules) plus rich individual command files. Full schemas in CLAUDE.md pollute every Claude Code session in the repo with SARA-specific detail.

4. **Atomic commit strategy** — all wiki writes for a single ingest must land in one git commit, never page-by-page. `/sara-update N` must be idempotent: re-runnable after interruption without duplicating output.

5. **"Update, don't duplicate" as a hard rule** — during `/sara-extract`, the LLM must check existing pages before proposing entity creation. This must be encoded in the command instruction, not left to LLM judgment.

6. **ID namespacing** — entity IDs (REQ-NNN, DEC-NNN, etc.) are scoped to project. `pipeline-state.json` holds per-type ID counters. Scan-and-derive is fragile and must not be used.

---

## Watch Out For

1. **Friction kills adoption (C1)** — every pipeline step must produce something immediately valuable and be resumable mid-session; backlog visibility prevents silent rot.

2. **Wiki drift via silent contradiction (C2)** — "update, don't duplicate" as a hard instruction in `/sara-extract`; `/sara-lint` run routinely to detect conflicting status fields and contradictory pages.

3. **Pipeline state / wiki state desync (C4)** — atomic commits only; idempotent `/sara-update`; stage set to "complete" only after successful commit.

4. **LLM hallucination in extraction proposals (M1)** — `/sara-extract` output must include a "Source quote:" field for every proposed artifact, forcing the LLM to cite its evidence.

5. **Index rot (C5)** — `index.md` must be treated as generated output, regenerable from disk by `/sara-lint --fix`; lint validates it bidirectionally.

---

## Roadmap Implications

Research points to four phases aligned with the architectural dependency graph.

### Phase 1: Foundation and Schema

**Rationale:** Every other command depends on CLAUDE.md for vocabulary, `pipeline-state.json` for state, and `/sara-init` for directory structure. Schema mistakes here cannot be retrofitted.

**Delivers:** Working `/sara-init` command; finalised CLAUDE.md; finalised `pipeline-state.json` schema; entity schemas with `schema_version`; ID counter strategy; atomic commit strategy documented.

**Addresses:** Entity types, project config, stakeholder seed data. Resolves all six "Critical Decisions Before Building."

**Avoids:** Schema rigidity (C3), pipeline state desync (C4), schema version lock (M6), future cross-project silo pain (M8 — ID namespacing only).

**Research flag:** Standard patterns — no deeper research needed.

### Phase 2: Ingest Pipeline

**Rationale:** The core value of SARA is the ingest pipeline. Build in strict dependency order: ingest → discuss → extract → update → minutes. Each command is blocked until the previous one works end-to-end.

**Delivers:** Full working pipeline for all source types. At least one complete end-to-end ingest cycle tested before Phase 3.

**Addresses:** All ingest pipeline requirements; discuss-stage contextual cross-linking; extract source-quote requirement; atomic commit with structured message; pipeline status visibility.

**Avoids:** Friction accumulation (C1 — resumability from the start), context amnesia (M2 — rich discussion notes in state), over-extraction (M4 — discuss protocol addresses scope), transcript quality degradation (M9), git history pollution (M3 — standardised commit message template).

**Research flag:** Validate Claude Code bash tool cwd behaviour before writing commands that use relative paths. Otherwise standard patterns.

### Phase 3: Query and Maintenance

**Rationale:** `/sara-query` and `/sara-lint` require wiki content to be meaningful. Only buildable after at least one complete ingest cycle. Source attribution must be added to requirements before this phase.

**Delivers:** `/sara-query` with source attribution and contradiction flagging; `/sara-lint` with bidirectional index validation, orphan detection, stale content surfacing, and state coherence checks.

**Addresses:** Source attribution (table stakes gap); wiki health; compounding value.

**Avoids:** Confidently wrong query answers (M7), orphan pages (M5), index rot (C5 — lint --fix).

**Research flag:** Query contradiction-flagging needs iteration against real wiki content. Otherwise standard patterns.

### Phase 4: Meeting Specialisation and UX Polish

**Rationale:** `/sara-minutes` and `/sara-meeting-agenda` are narrow in scope with the most dependencies. Pipeline status visibility belongs here if not delivered in Phase 2.

**Delivers:** `/sara-minutes N` (markdown minutes + email-ready draft); `/sara-meeting-agenda` (pre-meeting agenda generation); pipeline backlog visibility.

**Avoids:** Silent pipeline rot (C1 — backlog visibility is anti-abandonment).

**Research flag:** Standard patterns throughout.

### Phase Ordering Rationale

- Schema and state decisions must precede commands — every command is a schema consumer. Build the contract before the implementations.
- The ingest pipeline is a strict dependency chain: each step is blocked until the previous one works. Build and test sequentially.
- Query and lint require wiki content — defer until at least one complete ingest cycle exists.
- Meeting specialisation has the most dependencies and narrowest scope; building it last reduces rework risk.

---

## Open Questions

1. **Does Claude Code's bash tool persist cwd between tool calls within a single slash command?** If cwd resets, all bash calls must use absolute paths. Validate empirically before writing the first command.

2. **Where does `pipeline-state.json` live — repo root or `wiki/`?** Repo root is simpler for path construction; `wiki/` keeps all managed state in one git-tracked tree. Decide in Phase 1 and encode in CLAUDE.md.

3. **Source attribution on `/sara-query`** — currently unspecified in PROJECT.md requirements. Must be added as an explicit requirement before Phase 3.

4. **Pipeline status visibility** — `/sara-ingest` with no args showing backlog, or a dedicated `/sara-status` command? Anti-abandonment mechanism; specify before Phase 2 ships.

5. **How should `/sara-discuss` handle discussion summary confirmation?** LLM proposes `discussion_notes` text; user confirms before write. Validate this UX is workable — a hallucinated summary becomes the extraction input.

6. **Re-open mechanism for post-update corrections** — no v1 mechanism to re-open item N after `/sara-update N`. Document as a known limitation; do not block Phase 2 on solving it.

7. **`/sara-query` index routing** — should `index.md` include a `tags` column per entity? Tags are already in frontmatter schemas; surfacing them in the index improves routing at low cost. Recommend adding in Phase 1.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No runtime dependencies; llm-wiki pattern is well-understood; all choices are first-principles from Claude Code constraints |
| Features | MEDIUM-HIGH | Table stakes and differentiators are clear; source attribution gap is a real oversight in current requirements; competitive landscape from training data Aug 2025 |
| Architecture | MEDIUM | Claude Code internals (cwd persistence, CLAUDE.md injection) flagged as unvalidated; component design is sound |
| Pitfalls | HIGH | Personal wiki abandonment, LLM drift, and stateful pipeline failure modes are mechanistically understood patterns |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Claude Code bash cwd behaviour:** Validate empirically before writing any command. Low-risk to test: write a two-tool-call command and check cwd persistence.
- **CLAUDE.md auto-injection mechanism:** Confirm it is loaded at session start before relying on it for schema definitions.
- **Source attribution in `/sara-query`:** Add as an explicit requirement before Phase 3.
- **Pipeline status visibility:** Specify before Phase 2 ships.

---

## Sources

### Primary (HIGH confidence)
- `.planning/PROJECT.md` — definitive requirements, constraints, and design decisions for SARA
- First-principles analysis of Claude Code slash command architecture and the llm-wiki pattern (Karpathy)

### Secondary (MEDIUM confidence)
- Competitive landscape: Obsidian+LLM plugins, NotebookLM, Mem.ai, Notion AI, Otter.ai, Fireflies.ai, Granola, Roam/Logseq — training knowledge through Aug 2025
- Claude Code internals (cwd behaviour, CLAUDE.md injection) — training knowledge; flagged for empirical validation

---
*Research completed: 2026-04-27*
*Ready for roadmap: yes*
