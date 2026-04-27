# Features Research — SARA

**Domain:** LLM-powered personal knowledge management / solution architecture wiki
**Researched:** 2026-04-27
**Confidence:** MEDIUM — competitive landscape drawn from training knowledge (tools last verified ~Aug 2025); SARA-specific recommendations are HIGH confidence from first-principles analysis of the stated design.

---

## Competitive Landscape

Brief survey of tools whose feature sets inform what "table stakes" means in this domain.

### Obsidian + LLM Plugins (Copilot, Smart Connections, Local GPT)

Obsidian is the closest spiritual ancestor: local-first, markdown, git-compatible, link graph. LLM plugins layer on top as optional add-ons.

**What it does well:** Bidirectional linking, graph view, community plugin ecosystem, full local ownership, flexible folder/tag taxonomy, daily notes, canvas mode for spatial thinking.

**LLM integration reality:** Plugins (Obsidian Copilot, Smart Connections) add semantic search, chat-over-vault, and inline generation. They are *additive* — the user still owns the ingest and organisation loop. No structured pipeline, no entity schema, no state machine.

**Gap vs SARA:** Zero pipeline discipline. Users spend enormous time deciding what to capture and how to structure it. The LLM answers questions but does not maintain the graph — it re-reads on every query (one-shot RAG). Cross-linking is manual. There is no concept of an "ingest ID" or processing stage.

### NotebookLM (Google)

Source-grounded Q&A: you add PDFs/docs, it answers from those sources only. Audio Overview (podcast-style synthesis) is a standout UX.

**What it does well:** Stays strictly grounded in sources (no hallucination outside them), source citations on every claim, excellent for document-heavy research.

**Gap vs SARA:** Read-only knowledge — it never writes a wiki. No persistent accumulation; knowledge resets when you start a new notebook. No meeting intelligence, no entity extraction, no structured artifact types. Cannot track decisions or actions.

### Mem.ai

Automatic tagging and semantic linking of every note captured. "Smart" inbox that surfaces related past notes when writing new ones. AI search across all mems.

**What it does well:** Zero-friction capture (email, browser extension, mobile), automatic organisation, good surface-level connections.

**Gap vs SARA:** No structure enforcement. Everything is a "mem" — undifferentiated blob. No pipeline for deliberate extraction. No git backing. No entity schema. Knowledge quality degrades if you never curate, and Mem does not force curation.

### Notion AI

AI generation and summarisation inside Notion's block-based workspace. Can draft pages, summarise databases, answer questions across a workspace.

**What it does well:** Deep workspace integration, database views (kanban, calendar, table), real-time collaboration, templates.

**Gap vs SARA:** AI is a generator/summariser, not a knowledge maintainer. No structured ingest pipeline. Multi-user collaboration is a feature, not a design constraint — brings all the attendant conflicts. Not git-backed; proprietary data store.

### Otter.ai

Real-time meeting transcription, speaker diarisation, AI meeting summary, action item extraction from meetings.

**What it does well:** Live transcription (joins calls automatically), highlights, searching across transcripts, integrates with Zoom/Teams/Meet.

**Gap vs SARA:** Siloed to meetings — no general knowledge accumulation. Action items are ephemeral (no wiki persistence, no cross-linking to requirements or decisions). No git backing. Subscription SaaS.

### Fireflies.ai

Similar to Otter but with stronger CRM and workspace integrations. "AI filters" to extract action items, questions, metrics, decisions from transcripts.

**What it does well:** Broad integration surface (50+ apps), team sharing of transcripts, searchable meeting library.

**Gap vs SARA:** Same fundamental gap as Otter — meeting-scoped, not project-scoped knowledge accumulation. Extracted items are not linked to a broader artifact graph. No structured wiki. No human-in-the-loop extraction approval.

### Granola (AI notepad for meetings)

Human-assisted meeting notes: you jot sparse notes during the meeting, Granola enhances them post-call using the transcript. Output is a polished meeting note.

**What it does well:** The "sparse notes → polished doc" UX is elegant. Very low friction. Notes are yours (not SaaS-locked).

**Gap vs SARA:** Still meeting-scoped, single-document output. No persistent wiki. No artifact typing. No extraction pipeline. No git backing.

### Personal Knowledge Graphs (Roam Research, Logseq)

Outliner-based, block-level bidirectional linking. Logseq is local-first and open-source.

**What it do well:** Granular block-level linking, daily note workflow, query language (Datalog in Logseq), plugin APIs.

**Gap vs SARA:** Same gap as Obsidian — no structured ingest pipeline, no entity schema, no LLM-maintained state. LLM plugins exist but are additive.

---

## Table Stakes

Features users expect from any LLM knowledge tool. Absence creates immediate friction or disqualification.

| Feature | Why Expected | Complexity | SARA Status |
|---------|--------------|------------|-------------|
| **Natural-language query over stored knowledge** | Every competitor offers this; it is the primary value prop of "AI + knowledge" | Low–Med | `/sara-query` — covered |
| **Persistent storage** (not session-scoped) | Knowledge must survive chat sessions to be useful | Low | Git-backed wiki — covered |
| **Source attribution** | Users need to trust answers; citations back to source material | Med | Ingest IDs + source archival — covered structurally, needs query-side implementation |
| **Meeting summary / minutes** | Meeting intelligence is a dominant use-case; all competitors do it | Med | `/sara-minutes` — covered |
| **Action item extraction from meetings** | Universal expectation after Otter/Fireflies established it | Med | Extraction pipeline covers this; Actions entity type |
| **Search / retrieval** | Finding things you've captured | Low–Med | `/sara-query` + `index.md` — covered; embedding search deferred to v2 |
| **Structured capture** (not just dump) | Users quickly learn that unstructured capture degrades quality | Med | Core differentiator — five entity types |
| **Readable, portable output** | Lock-in anxiety; users want to own their data | Low | Markdown + git — covered |

### Table Stakes gaps to watch

- **Source attribution on query answers:** `/sara-query` must cite which wiki pages / ingest IDs support each claim. Without this, users cannot trust synthesised answers. This is not explicitly specified in v1 requirements — it should be.
- **Resumability across sessions:** Pipeline state preservation is specified (`stage`, `discussion context`) — good. Needs to be explicitly surfaced in the UX (e.g. `/sara-ingest` with no args lists pending items).

---

## Differentiators

Where SARA's specific angle creates genuine competitive advantage. These are the things to double down on.

### 1. Process-Gated, Human-in-the-Loop Extraction

**What it is:** Every ingest goes through four explicit human-approved stages (discuss → extract → update). Nothing enters the wiki without the user agreeing on intent first.

**Why it matters:** Every competitor either skips this entirely (Mem, Otter auto-extract) or leaves it entirely to the user (Obsidian). Auto-extraction produces noisy, low-trust outputs. Manual Obsidian organisation requires expertise and discipline. SARA's four-stage gate is the middle path: LLM does the work, human retains control.

**Where to double down:** The discuss stage is the most valuable and least replicable. The LLM should ask targeted clarifying questions at `/sara-discuss N` — not just "what should I extract?" but "I see a tension between this decision and requirement REQ-003 — do you want me to flag that as a risk?" Contextual cross-linking at discussion time is the moat.

### 2. Typed, Cross-Linked Artifact Schema

**What it is:** Five entity types (Requirements, Decisions, Actions, Risks, Stakeholders) with structured fields and bidirectional links.

**Why it matters:** Untyped knowledge degrades — Mem.ai's blob of mems is hard to query precisely. Typed entities enable precise queries ("show me all open actions assigned to this stakeholder", "which decisions are linked to this requirement?"). The schema also makes LLM extraction deterministic and auditable.

**Where to double down:** Cross-linking at extraction time is critical. When `/sara-extract N` proposes artifacts, it should explicitly surface links to existing entities — not just create new ones. "This decision overrides DEC-007" is more valuable than a new DEC-012 that silently contradicts DEC-007.

### 3. Git as the Knowledge Substrate

**What it is:** All wiki changes are git commits. History, diffing, branching, and merging are free.

**Why it matters:** No competitor offers this. Notion, Mem, Otter are proprietary SaaS stores. Obsidian+git is possible but manual — SARA commits automatically at `/sara-update N`. This means: full audit trail of when knowledge changed, ability to diff "what did we know about this requirement before the Tuesday meeting vs after", ability to branch for speculative analysis.

**Where to double down:** The commit message at `/sara-update N` should be rich — include ingest ID, source type, list of artifact IDs created/updated, and summary of changes. This makes `git log` a meaningful knowledge audit trail, not just "update wiki". Lint (`/sara-lint`) should cross-check git history for orphaned pages that were created but never linked.

### 4. Compounding Wiki vs One-Shot RAG

**What it is:** Knowledge is compiled into structured pages once; subsequent queries read the wiki, not the raw sources. (Karpathy's llm-wiki insight.)

**Why it matters:** RAG re-derives context on every query from raw sources — it does not get smarter over time. SARA's wiki gets richer with every ingest. A query in month 6 benefits from everything ingested in months 1–5. NotebookLM is pure RAG. Obsidian plugins are mostly RAG.

**Where to double down:** The wiki index (`index.md`) and each entity page must be deliberately structured for LLM re-reading — not for human aesthetics. Dense, cross-referenced, machine-scannable. The LLM reading `index.md` before `/sara-query` should be able to determine which pages to read without opening all of them.

### 5. Domain-Agnostic Project Scoping

**What it is:** One repo per project, department/vertical config at init time. The same SARA schema works for software architecture, enterprise architecture, procurement, legal review.

**Why it matters:** Competitors are either meeting-specific (Otter, Fireflies) or general-purpose (Notion, Obsidian) without project-scoped structure. SARA is project-scoped-by-design, which means stakeholder lists, requirement sets, and decision logs are tightly scoped — no pollution from other projects.

**Where to double down:** The `/sara-init` config should capture: project name, vertical/domain, department taxonomy, and stakeholder seed data. The richer the init config, the more precisely the LLM can frame extractions ("for a software architecture project, risks include performance, security, and integration complexity").

### 6. Slash-Command Operator Interface

**What it is:** SARA runs inside Claude Code as slash commands — the user's existing LLM IDE, not a new tool.

**Why it matters:** Zero additional tool tax. The user is already in Claude Code for development work. SARA is ambient — it is in the environment, not a separate app to context-switch to.

**Where to double down:** Command discoverability matters. Claude Code's slash command help text should make the pipeline obvious. Consider a `/sara-status` command (or make `/sara-ingest` with no args show status) so users always know what is pending without reading files.

---

## Anti-Features

Features to deliberately not build, with rationale.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Real-time auto-extraction** (fully autonomous ingest) | Removes human gate; produces low-trust, noisy wiki; errors compound silently | Keep the four-stage gate; make it fast, not bypassed |
| **Embedding-based vector search** (v1) | Adds infra complexity (vector store, embedding model, sync); `index.md` + LLM context window is sufficient at personal scale | Defer to v2; design `index.md` to be LLM-scannable |
| **Multi-user shared repo** | Git conflicts, permissions, merge complexity; breaks the single-user trust model | Multi-user via separate clones; share outputs (minutes, agendas) not the repo |
| **External integrations (Jira, Linear, email send)** | API credentials, auth flows, webhook infra — disproportionate to v1 value | Export-ready markdown (email-draft minutes, copy-paste ready) is sufficient |
| **Real-time transcription / meeting joining** | Requires always-on service, audio infra, calendar integrations — out of scope for a slash command tool | Ingest the transcript after the meeting (file-based) |
| **Rich UI / web app** | SARA's value is in the knowledge model, not a browser UI; Obsidian already exists for wiki browsing | Markdown + git is the UI; Claude Code is the operator surface |
| **Automatic git push** | Pushes user data to remotes without explicit intent; breaks local-first trust model | Commit locally; user controls remotes |
| **Global cross-project wiki** | Pollutes project-scoped knowledge; cross-project queries become ambiguous | One repo per project; cross-project synthesis is a future concern |
| **LLM-chosen entity types** | Unbounded schema degrades over time; LLM creativity is a bug here | Hard-code the five types; use tags/labels for nuance within types |

---

## Feature Dependencies

```
/sara-init
  → Must exist before any other command (creates directory structure, config, entity schema)

/sara-ingest <type> <file>
  → Requires: /sara-init (wiki must exist)
  → Produces: Ingest ID N, pipeline state record

/sara-discuss N
  → Requires: /sara-ingest N (item must be registered)
  → Reads: index.md, relevant wiki pages (for cross-linking context)
  → Produces: Agreed extraction intent (stored in pipeline state)

/sara-extract N
  → Requires: /sara-discuss N (intent must be agreed)
  → Reads: Full wiki pages for cross-link candidates
  → Produces: Approved artifact list (staged, not written)

/sara-update N
  → Requires: /sara-extract N (approved artifact list)
  → Writes: Wiki pages (creates/updates), index.md, log.md
  → Commits: Git commit with structured message
  → Archives: Source file to processed subfolder

/sara-minutes N
  → Requires: /sara-ingest N of type=meeting (source must be a meeting transcript)
  → Best after: /sara-update N (so minutes can reference extracted artifacts)
  → Produces: Markdown minutes + email-ready draft

/sara-query
  → Requires: At least one /sara-update N completed (wiki must have content)
  → Reads: index.md first, then targeted wiki pages
  → Must: Cite ingest IDs and page names for every claim

/sara-lint
  → Requires: At least one /sara-update N completed
  → Reads: Full wiki
  → Checks: Orphaned pages, unresolved action items, stale risk status, missing cross-references, contradicting decisions

/sara-meeting-agenda
  → Requires: Nothing (stateless, throw-away)
  → Optional: /sara-query patterns to pull in open actions / risks for agenda items

Source attribution in /sara-query
  → Requires: index.md to record which ingest IDs contributed to each wiki page
  → Implication: /sara-update N must write ingest ID provenance into each page it touches

Cross-link detection in /sara-discuss and /sara-extract
  → Requires: index.md to be current (updated by /sara-update N)
  → Implication: index.md update must be part of /sara-update N, not a separate step
```

---

## Key Observations for Roadmap

**SARA's core bet is discipline over automation.** Every competitor that auto-extracts produces noise. SARA's human-gated pipeline is a feature, not a limitation — lean into it. The discuss stage in particular should be a rich, contextual conversation, not a rubber stamp.

**The wiki structure is load-bearing for query quality.** A poorly structured wiki makes `/sara-query` useless. The entity page templates (what fields, what cross-link conventions) need to be designed before the pipeline is built, not after.

**Source attribution is unspecified but critical.** `/sara-query` without citations is untrustworthy. Every wiki page should track which ingest IDs contributed to it. This needs to be added to requirements.

**`index.md` is the LLM's map.** Its structure determines whether the LLM can navigate the wiki efficiently. Design it as a machine-readable catalog, not a human-facing table of contents.

**`/sara-lint` is a compounding value feature.** It gets more useful the longer the wiki is maintained. Orphan detection, contradiction detection, and stale content flags are the features that make SARA a living document rather than an archive.
