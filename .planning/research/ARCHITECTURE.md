# Architecture Research — SARA

**Researched:** 2026-04-27
**Confidence:** MEDIUM — Claude Code internals from training data (August 2025 cutoff); external tools unavailable in this research session. Flag for validation against current Claude Code docs before implementation.

---

## Component Map

### Components and Boundaries

| Component | Type | Responsibility | Owns |
|-----------|------|---------------|------|
| `CLAUDE.md` | Config/Prompt | Defines SARA's behaviour, schemas, and vocabulary for all sessions | Rules, schema definitions, entity type specs |
| `.claude/commands/` | Skills | One `.md` file per slash command; each is a self-contained prompt with instructions and tool use | Command logic, per-command behaviour |
| `/raw/input/` | Staging bucket | Drop zone for unprocessed source files | Nothing — files pass through |
| `/raw/<type>/` | Archive | Processed sources, renamed with numeric ingest ID prefix | Archived source files |
| `/wiki/` | Knowledge store | Persistent, structured markdown; the "compiled" output of all ingests | Artifact pages, index, log |
| `pipeline-state.json` | State file | Tracks every ingest item: ID, filename, type, stage, discussion notes, extraction plan | Ingest pipeline state |
| `wiki/index.md` | Catalog | LLM-maintained catalog of every wiki page with one-line summary; enables scoped reads | Page registry |
| `wiki/log.md` | Audit log | Append-only chronological record of ingest/query/lint events | Activity history |
| `wiki/<type>/` | Artifact stores | One directory per entity type (requirements, decisions, actions, risks, stakeholders) | Entity markdown files |

### Component Boundaries

**Claude Code session boundary** is the critical constraint. Claude Code does not persist in-process state between slash command invocations — each `/sara-*` call is a new session context. All state that must survive session boundaries must live in files. This is the foundational architectural constraint.

**CLAUDE.md is the contract.** It is read at session start (highest-priority context). It must define: schema for each entity type, file naming conventions, pipeline stage names, and behavioural rules. Commands rely on CLAUDE.md for shared vocabulary. If CLAUDE.md drifts from command implementations, behaviour becomes inconsistent.

**Commands are thin wrappers.** Each `.claude/commands/sara-*.md` file contains: argument parsing, a read instruction set (what files to load), operation logic, and write instructions. Commands must not encode schema — schema lives in CLAUDE.md.

**`pipeline-state.json` is the session bridge.** It carries everything that `/sara-discuss`, `/sara-extract`, and `/sara-update` need to resume where the previous session left off. Without it, each command would re-read all raw files to reconstruct context — fragile and slow.

---

## Data Flow

### Ingest Pipeline Flow

```
Human drops file → /raw/input/transcript.md

/sara-ingest meeting transcript.md
  → Reads: /raw/input/transcript.md (existence check)
  → Reads: pipeline-state.json (to assign next ID)
  → Writes: pipeline-state.json (new entry, stage: "pending")
  → Writes: wiki/log.md (append ingest event)
  → Outputs: "Item 007 registered — run /sara-discuss 7"

/sara-discuss 7
  → Reads: pipeline-state.json (loads item 7 metadata)
  → Reads: /raw/input/<filename> (source content)
  → Reads: wiki/index.md (existing pages for context)
  → Interactive: human + LLM discuss extraction intent
  → Writes: pipeline-state.json (stage: "discussed", discussion_notes: "...")
  → Writes: wiki/log.md (append discuss event)

/sara-extract 7
  → Reads: pipeline-state.json (item 7, discussion_notes)
  → Reads: /raw/input/<filename> (source content)
  → Reads: wiki/index.md (existing pages to identify updates vs creates)
  → Reads: affected wiki pages (for merge planning)
  → Outputs: proposed artifact list for human approval (CREATE REQ-042, UPDATE DEC-007, ...)
  → Writes: pipeline-state.json (stage: "extracted", extraction_plan: [...])

/sara-update 7
  → Reads: pipeline-state.json (item 7, extraction_plan)
  → Reads: /raw/input/<filename> (source for content)
  → Reads: affected wiki pages (for merge)
  → Writes: wiki/<type>/<artifact>.md (creates/updates each artifact)
  → Writes: wiki/index.md (updated catalog)
  → Writes: pipeline-state.json (stage: "complete")
  → Moves: /raw/input/<filename> → /raw/meetings/007-transcript.md
  → Writes: wiki/log.md (append update event)
  → Outputs: "Commit ready — review with git diff, then git commit"

/sara-minutes 7  (meetings only, after update)
  → Reads: pipeline-state.json (item 7 metadata)
  → Reads: /raw/meetings/007-<filename> (archived transcript)
  → Reads: wiki/<artifacts created in update> (for accurate cross-refs)
  → Writes: wiki/meetings/007-minutes.md (meeting minutes)
  → Outputs: email-ready draft to stdout
```

### Query Flow

```
/sara-query "What decisions have we made about authentication?"
  → Reads: wiki/index.md (find relevant pages)
  → Reads: wiki/decisions/*.md (targeted by index)
  → Reads: wiki/requirements/*.md (if relevant)
  → Synthesises: answer grounded in wiki content
  → Writes: wiki/log.md (append query event with question)
  → Outputs: answer with wiki page citations
```

### Lint Flow

```
/sara-lint
  → Reads: wiki/index.md (full catalog)
  → Reads: all wiki/**/*.md (full scan)
  → Checks: orphan pages (in index but no file, or file but not in index)
  → Checks: broken cross-references ([[Page]] links that don't resolve)
  → Checks: stale content (actions open > N days, risks unreviewed > N days)
  → Checks: missing required frontmatter fields
  → Writes: wiki/log.md (append lint event with issue count)
  → Outputs: issue report
```

---

## Artifact Schemas

All wiki pages use YAML frontmatter followed by freeform markdown body. Frontmatter is machine-readable; body is human-readable and LLM-synthesised.

### Requirement

```yaml
---
id: REQ-001
title: "Short imperative statement of the requirement"
status: active          # active | deferred | invalidated | validated
priority: high          # high | medium | low
type: functional        # functional | non-functional | constraint
stakeholders:           # list of stakeholder IDs
  - STK-003
  - STK-007
source_ingest: 007      # ingest ID that created or last updated this
created: 2026-04-27
updated: 2026-04-27
tags: []
---

## Description

[Full description of the requirement]

## Acceptance Criteria

- [Criterion 1]
- [Criterion 2]

## Related

- [[DEC-005]] — Decision that satisfies this requirement
- [[RISK-002]] — Risk to this requirement being met
```

### Decision (ADR-style)

```yaml
---
id: DEC-001
title: "Short noun phrase describing the decision"
status: accepted        # proposed | accepted | superseded | deprecated
date: 2026-04-27
deciders:               # stakeholder IDs
  - STK-003
supersedes: null        # DEC-NNN if this replaces a prior decision
source_ingest: 007
created: 2026-04-27
updated: 2026-04-27
tags: []
---

## Context

[Why this decision was needed]

## Decision

[What was decided — the actual choice made]

## Rationale

[Why this option over alternatives]

## Consequences

**Positive:**
- [outcome]

**Negative / Trade-offs:**
- [outcome]

## Related

- [[REQ-004]] — Requirement this addresses
- [[RISK-003]] — Risk this decision introduces or mitigates
```

### Action

```yaml
---
id: ACT-001
title: "Short imperative describing the action"
status: open            # open | in-progress | done | cancelled
owner:                  # stakeholder ID
  - STK-005
due: 2026-05-15         # ISO date or null
priority: medium        # high | medium | low
source_ingest: 007
created: 2026-04-27
updated: 2026-04-27
tags: []
---

## Description

[What needs to be done and why]

## Context

[Background / decisions that triggered this action]

## Related

- [[DEC-002]] — Decision this action implements
- [[REQ-008]] — Requirement this action serves

## Updates

<!-- Append-only status notes; newest first -->
- 2026-04-27: Action created
```

### Risk

```yaml
---
id: RISK-001
title: "Short noun phrase describing the risk"
status: open            # open | mitigated | accepted | closed
probability: medium     # high | medium | low
impact: high            # high | medium | low
rating: high            # computed: high/medium/low from prob × impact
owner:                  # stakeholder ID
  - STK-003
source_ingest: 007
created: 2026-04-27
updated: 2026-04-27
last_reviewed: 2026-04-27
tags: []
---

## Description

[What could go wrong and why it matters]

## Mitigation

[What is being done or should be done to reduce probability or impact]

## Contingency

[What happens if the risk materialises]

## Related

- [[DEC-005]] — Decision that introduces this risk
- [[ACT-007]] — Mitigation action
```

### Stakeholder

```yaml
---
id: STK-001
name: "Full Name"
role: "Job title / role in project"
department: "Department or vertical"    # from project config in CLAUDE.md
email: "name@domain.com"
status: active          # active | inactive
source_ingest: 007      # first ingest that introduced this stakeholder
created: 2026-04-27
updated: 2026-04-27
tags: []
---

## Notes

[Relevant context: communication preferences, decision authority, areas of concern]

## Involvement

<!-- LLM maintains this list -->
- [[REQ-003]] — Stakeholder requirement
- [[DEC-001]] — Decision they made
- [[ACT-004]] — Action assigned to them
```

### Index Entry Format (wiki/index.md)

The index is a structured catalog, not freeform prose. LLM updates it on every `/sara-update` run.

```markdown
# SARA Wiki Index

_Last updated: 2026-04-27 (ingest 007)_

## Requirements

| ID | Title | Status | Updated |
|----|-------|--------|---------|
| REQ-001 | [title] | active | 2026-04-27 |

## Decisions

| ID | Title | Status | Updated |
|----|-------|--------|---------|
| DEC-001 | [title] | accepted | 2026-04-27 |

## Actions

| ID | Title | Status | Owner | Due |
|----|-------|--------|-------|-----|
| ACT-001 | [title] | open | STK-003 | 2026-05-15 |

## Risks

| ID | Title | Rating | Status | Last Reviewed |
|----|-------|--------|--------|---------------|
| RISK-001 | [title] | high | open | 2026-04-27 |

## Stakeholders

| ID | Name | Role | Department |
|----|------|------|------------|
| STK-001 | Full Name | Role | Department |
```

### Log Entry Format (wiki/log.md)

```markdown
# SARA Activity Log

<!-- Append-only. Do not edit existing entries. -->

---

## 2026-04-27T14:32:00 — INGEST

**Item:** 007
**Type:** meeting
**File:** standup-2026-04-27.md
**Stage:** pending

---

## 2026-04-27T15:10:00 — UPDATE

**Item:** 007
**Artifacts created:** REQ-042, ACT-018
**Artifacts updated:** DEC-007, STK-003
**Source archived:** /raw/meetings/007-standup-2026-04-27.md

---
```

---

## State Management

### The Core Problem

Claude Code slash commands do not persist in-process state between invocations. Each `/sara-discuss 7`, `/sara-extract 7`, `/sara-update 7` is a fresh Claude Code session that must reconstruct context from files. The pipeline state file is the only mechanism for one command to communicate context to the next.

### Recommended: `pipeline-state.json`

A single JSON file at the repo root (or `/wiki/pipeline-state.json` — wiki root keeps it within the tracked knowledge store).

**Location rationale:** Place at `pipeline-state.json` in the repo root. This is the first file commands read and write. Keeping it at root avoids ambiguity.

**Schema:**

```json
{
  "version": 1,
  "next_id": 8,
  "items": {
    "007": {
      "id": 7,
      "type": "meeting",
      "filename": "standup-2026-04-27.md",
      "raw_path": "raw/input/standup-2026-04-27.md",
      "archived_path": "raw/meetings/007-standup-2026-04-27.md",
      "stage": "complete",
      "created": "2026-04-27T14:32:00Z",
      "discussed_at": "2026-04-27T15:00:00Z",
      "extracted_at": "2026-04-27T15:05:00Z",
      "updated_at": "2026-04-27T15:10:00Z",
      "discussion_notes": "Meeting covered Q2 budget approval. Key stakeholders: STK-003 (CFO), STK-007 (CTO). Two new requirements surfaced around API rate limits. One decision made to defer SSO.",
      "extraction_plan": [
        {"action": "create", "type": "requirement", "id": "REQ-042", "summary": "API rate limit cap at 1000 req/min"},
        {"action": "update", "type": "decision", "id": "DEC-007", "summary": "Defer SSO to Phase 3"},
        {"action": "create", "type": "action", "id": "ACT-018", "summary": "George to spec rate limiting approach by 2026-05-07"}
      ],
      "artifacts": ["REQ-042", "ACT-018", "DEC-007"]
    }
  }
}
```

**Key fields per item:**

| Field | Type | Purpose |
|-------|------|---------|
| `id` | int | Ingest ID (numeric); padded to 3 digits in filenames |
| `type` | enum | `meeting \| email \| slack \| document` |
| `filename` | string | Original filename in `/raw/input/` |
| `raw_path` | string | Full path while in staging |
| `archived_path` | string | Path after archiving (set at update time) |
| `stage` | enum | `pending \| discussed \| extracted \| complete` |
| `discussion_notes` | string | LLM summary of discussion session; feeds `/sara-extract` |
| `extraction_plan` | array | Approved artifact operations; feeds `/sara-update` |
| `artifacts` | array | Final list of artifact IDs created/updated |
| timestamps | ISO string | `created_at`, `discussed_at`, `extracted_at`, `updated_at` |

**Stage machine:**

```
pending → discussed → extracted → complete
```

Each command reads the stage and refuses to proceed if preconditions aren't met:
- `/sara-discuss N` requires `stage == "pending"`
- `/sara-extract N` requires `stage == "discussed"`
- `/sara-update N` requires `stage == "extracted"`
- `/sara-minutes N` requires `stage == "complete"` and `type == "meeting"`

**Why JSON not YAML or markdown:**
- Machine-readable without parsing ambiguity (LLMs write JSON reliably)
- Structured enough for stage validation logic within a prompt
- Easily diffable in git
- Single file means no directory scan needed to find active items

**Handling partial state / crashes:**
If Claude Code is interrupted mid-`/sara-update`, the wiki may be partially written but `stage` not yet set to `"complete"`. The `/sara-update` command should be re-runnable: it checks `extraction_plan` against what artifact files actually exist, writes missing ones, then sets `stage: "complete"`. This makes update idempotent.

### CLAUDE.md as Behavioural State

CLAUDE.md is not session state — it is persistent behavioural configuration. It should define:

1. **Project identity block** — project name, domain, department list (set at `/sara-init` time)
2. **Entity type schemas** — concise field list for each type (not full schemas — those live in individual command files, but the names and required fields belong in CLAUDE.md so every command honours them)
3. **ID counter rules** — how IDs are assigned (REQ-, DEC-, ACT-, RISK-, STK- prefixes, zero-padded)
4. **Cross-linking convention** — `[[ARTIFACT-ID]]` wikilink syntax; always use IDs not titles
5. **Tone and style** — concise, imperative, factual; no padding
6. **Pipeline stage rules** — the valid stage transitions, what each stage means
7. **What SARA does not do** — explicit anti-behaviours (do not make inferences not grounded in source material; do not update wiki without user approval; do not skip discussion phase)

### Cross-Session Context Loading Pattern

Each command `.md` file should begin with an explicit "read these files before proceeding" block:

```
## Context Load

Before taking any action, read:
1. `pipeline-state.json` — full state
2. `wiki/index.md` — current artifact catalog
3. `raw/input/<filename from state[N]>` — source content for item N
```

This pattern ensures commands always work from current state rather than hallucinated state.

---

## Wiki Cross-Linking

### The index.md Approach

At SARA's scale (one project, hundreds not thousands of pages), `wiki/index.md` as a structured catalog is the right choice. It is:
- Readable by humans without tooling
- Loadable by LLM in a single read (even at 500+ pages, an index table is small)
- Automatically maintained by `/sara-update` on every ingest
- Sufficient for `/sara-query` to do targeted page lookups rather than full-wiki scans

The alternative — vector/embedding search — is explicitly deferred to v2 (noted in PROJECT.md Out of Scope). The index approach keeps the system self-contained and git-native.

### Cross-Reference Convention

All cross-references use wikilink syntax with IDs: `[[REQ-001]]`, `[[STK-003]]`. Never use page titles in links — IDs are stable, titles change. CLAUDE.md must enforce this rule.

The `Related` section in each artifact is the canonical cross-reference block. `/sara-lint` validates these references against the index.

### Scale Ceiling

The index approach breaks down when:
- Index table exceeds ~2000 rows (LLM context starts to degrade on pure catalog reads)
- Cross-references become too dense for index-based navigation

At that scale, consider splitting index by entity type (`requirements-index.md`, `decisions-index.md`, etc.) — this is a v2 concern.

---

## Build Order

### Dependency Graph

```
CLAUDE.md (schema + rules)
    └── /sara-init (creates directory structure, writes CLAUDE.md template)
            └── pipeline-state.json (created by sara-init)
                    └── /sara-ingest (registers items, writes state)
                            └── /sara-discuss (reads state, updates stage)
                                    └── /sara-extract (reads state, proposes plan)
                                            └── /sara-update (writes wiki, archives)
                                                    ├── /sara-minutes (reads archive)
                                                    └── wiki/index.md (updated by sara-update)
                                                            └── /sara-query (reads index + pages)
                                                            └── /sara-lint (reads all pages)
wiki/log.md
    └── written by: sara-ingest, sara-discuss, sara-extract, sara-update, sara-query, sara-lint
```

### Phase Sequencing Implications

**Must be built first (Phase 1 — Foundation):**

1. **CLAUDE.md schema** — Every other command depends on it for vocabulary and rules. Cannot write commands without knowing the schema they operate against. Build this first, even before commands.
2. **`/sara-init`** — Creates the directory structure and initial files. All other commands assume this structure exists. Test this before building ingest.
3. **`pipeline-state.json` schema** — Must be finalised before writing any command that reads/writes state. Changes to this schema after `/sara-ingest` and `/sara-update` are built force dual rewrites.

**Build second (Phase 2 — Ingest Pipeline):**

4. **`/sara-ingest`** — Registers items into state. Must work before discuss/extract/update can be tested.
5. **`/sara-discuss`** — Reads state + source. First interactive command; tests the stateful pattern.
6. **`/sara-extract`** — Reads state + discussion notes. First command that proposes structured output (extraction plan).
7. **`/sara-update`** — Writes wiki, archives source, updates index. Most complex command; only buildable after extract works.

**Build third (Phase 3 — Query and Maintenance):**

8. **`/sara-query`** — Requires wiki to have content (from update) to be meaningful. Build after at least one complete ingest cycle is tested end-to-end.
9. **`/sara-lint`** — Requires wiki to have content and cross-references. Low-risk to build alongside query.

**Build last (Phase 4 — Meeting Specialisation):**

10. **`/sara-minutes`** — Depends on a completed meeting ingest (update complete, archived). Narrow scope; build last as a specialisation of the ingest pipeline.
11. **`/sara-agenda`** — Standalone generate command; no dependencies on other commands. Can be built anytime after Phase 1 but is lowest priority (throw-away output, no wiki integration).

### Critical Path

```
CLAUDE.md → /sara-init → /sara-ingest → /sara-discuss → /sara-extract → /sara-update → /sara-query
```

Every step on this path is blocked until the previous step works correctly. The pipeline is a chain; a broken link blocks everything downstream.

---

## Open Questions

### 1. Where does `pipeline-state.json` live?

**Options:**
- Repo root (`pipeline-state.json`) — easy to find, clearly operational
- `wiki/pipeline-state.json` — keeps all SARA state within the `wiki/` tree, git-tracked alongside artifacts

**Recommendation pending:** Repo root is simpler for command argument construction (fewer path segments). But `wiki/` keeps "all managed content" in one tree. Decide at Phase 1 build time and encode in CLAUDE.md.

### 2. How are ID sequences managed without a database?

`pipeline-state.json` holds `next_id` for ingest items. But artifact IDs (REQ-NNN, DEC-NNN, etc.) need their own counters. Options:

- **State file counters** — add `"next_req": 43, "next_dec": 12, ...` to `pipeline-state.json`
- **Scan-and-derive** — LLM scans existing files to find highest ID, increments (fragile if files are renamed)
- **Separate `counters.json`** — dedicated file for ID sequences

**Recommendation:** Add counters to `pipeline-state.json` under a `"counters"` key. Single file to read, single write. LLM cannot safely scan-and-derive under concurrent edits (even single-user, mid-session edits are possible).

### 3. How does `/sara-discuss` handle multi-turn conversation?

`/sara-discuss N` is described as "human + LLM discuss source." Claude Code slash commands invoke a single prompt context — multi-turn is the natural Claude Code conversation within that session. The command prompt should establish the discussion frame, then yield to conversation. The user exits by saying something like "done" or "ready to extract." The command then writes discussion notes to state.

The open question: does the command auto-write to state on exit, or does the user explicitly confirm the summary? Recommendation: LLM summarises the discussion, proposes the `discussion_notes` text, user confirms, then writes. Avoids a hallucinated summary becoming the extraction input.

### 4. What happens when a source spans multiple entity types not anticipated at extract time?

If `/sara-extract` proposes creating 3 artifacts and `/sara-update` runs, but the user later realises a 4th artifact was missed, the pipeline has no "re-open" mechanism. Options:
- Run a new `/sara-ingest` on the same source (duplicating the source file)
- Allow `/sara-update` to accept an amended extraction plan at run time
- Add a `/sara-amend N` command for post-update corrections

**Recommendation:** Document as a known limitation in v1; address in v2. The human-gated extract step should catch most cases. Advise users to be thorough at extract time.

### 5. Should git commits be automated?

`/sara-update` makes wiki changes. The project context says "Commit ready — review with git diff, then git commit" — implying manual commit. This is the right v1 default (human retains git control). But `/sara-update` should output the exact `git add` and `git commit` commands to run, making it frictionless.

### 6. How should CLAUDE.md be structured relative to command files?

Two valid patterns:
- **Monolithic CLAUDE.md** — all rules, schemas, conventions in one file; commands are minimal
- **Thin CLAUDE.md + rich command files** — CLAUDE.md sets project identity and core rules; each command `.md` contains its own detailed instructions

**Recommendation:** Thin CLAUDE.md + rich command files. CLAUDE.md is loaded in every session including non-SARA interactions. Keeping it focused on identity and core rules avoids polluting all Claude Code sessions with SARA-specific schemas. Schema detail belongs in command files where it is actually used.

### 7. How should `/sara-query` scope its wiki reads?

Full wiki scan on every query is expensive in context and slow. The index-first pattern (read index, identify relevant pages, read only those pages) is better. But the index must be well-maintained for this to work — a stale index routes queries to wrong pages.

Open question: should the index include a keywords/tags field per page to improve routing, or is the title + status sufficient? Recommendation: add a `tags: []` field to all artifact frontmatter (already included in schemas above) and surface tags in the index table for query routing.
