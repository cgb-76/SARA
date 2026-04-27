# Pitfalls Research — SARA

**Domain:** LLM-powered personal knowledgebase, git-backed, human-in-the-loop pipeline
**Researched:** 2026-04-27
**Confidence:** HIGH for personal wiki failure modes and LLM drift patterns; HIGH for stateful CLI pitfalls; MEDIUM for meeting intelligence-specific risks (domain is younger)

---

## Critical Pitfalls

These sink projects — either through abandonment, data corruption, or structural unsalvageability.

---

### C1: Friction Accumulates Until the Tool Gets Abandoned

**What goes wrong:** The four-command pipeline (ingest → discuss → extract → update) feels worthwhile for the first few ingests. After three weeks, a meeting transcript sits in `/raw/input/` for ten days because starting four commands feels heavy. Then another. Then the pipeline is effectively dead and the wiki is stale.

**Why it happens:** Personal tools exist on a frictionless-or-dead spectrum. Unlike team tools where social accountability keeps things going, personal tools die quietly. The pipeline ceremony is highest precisely when the user is busiest (post-meeting), which is when willingness to invest effort is lowest. Each additional command hop is a compounding exit opportunity.

**Warning signs:**
- Raw files accumulate in `/raw/input/` without being progressed
- Days pass between ingest and `/sara-discuss`
- User starts skipping straight to `/sara-update` without discuss/extract approval
- User starts bypassing SARA for "quick things" (note-taking directly in wiki)

**Prevention:**
- Make `/sara-ingest` brain-dead fast — file drop + one command, zero friction at the entry point
- Design `/sara-discuss`, `/sara-extract`, `/sara-update` so each one can be stopped mid-session and resumed cleanly (resumability is an anti-abandonment mechanism)
- Provide a `/sara-status` or similar that shows the backlog — visibility creates guilt-driven completion better than forcing synchronous completion
- Consider whether discuss + extract can be collapsed for simple source types (a short Slack thread doesn't need the same ceremony as a 60-minute architecture meeting)
- The pipeline should feel like it's doing real work at each step, not bureaucracy — each command must produce something immediately valuable to justify its existence

**SARA phase:** Phase 1 (ingest pipeline design). Get this wrong architecturally and no later phase can fix it.

---

### C2: LLM Wiki Drift — Pages Become Subtly Wrong Over Time

**What goes wrong:** The LLM writes a Decision page for ADR-007. Six ingests later, the context of ADR-007 has evolved — a new constraint was discovered, the rationale shifted. The LLM writes a new page that partially contradicts ADR-007 without explicitly updating it. Neither version is wrong in isolation; together they are inconsistent. The wiki is now a liability: querying it produces answers that blend two contradictory states.

**Why it happens:** LLMs are excellent at creating locally coherent content but poor at maintaining globally consistent state across many documents they didn't write in a single context window. Each ingest presents a partial context (the source + some wiki pages) — the LLM cannot see the full wiki simultaneously. Contradictions emerge in the gaps.

**Warning signs:**
- `/sara-query` produces answers that hedge or contain "on the other hand" clauses not justified by the question
- Two pages for the same stakeholder appear with different email addresses
- A Decision page references an assumption that a Requirements page contradicts
- Cross-references in `index.md` go stale (point to renamed or deleted pages)

**Prevention:**
- `/sara-lint` is not optional — it must be run regularly and must catch semantic contradictions, not just broken links. Design lint to detect: duplicate entity names, contradictory status fields, orphan pages, stale cross-references, stakeholder email mismatches
- Require explicit supersession: when the LLM updates a page, it must mark what changed and why (a mini-changelog per page). "Updated: 2026-04-27 — ADR-007 rationale revised per Ingest 015" makes drift traceable
- During `/sara-extract`, force the LLM to check existing pages for the same entity before creating new ones. "Does a page for this requirement already exist? If yes, update; do not create a duplicate."
- Git history is the ultimate backstop — but only if you commit atomically per ingest (all changes from Ingest N in one commit), so `git log` is readable

**SARA phase:** Phase 1 (page update logic), Phase 2 (lint command design), Phase 3 (supersession protocol).

---

### C3: Schema Rigidity — Five Entity Types Don't Map to Reality

**What goes wrong:** Real project knowledge is messier than five buckets. A "parking lot item" from a meeting is part risk, part action, part decision-pending. A vendor constraint is part requirement, part risk. The user starts forcing artifacts into the wrong type to satisfy the schema, producing pages that are technically valid but semantically wrong. Or they give up and just don't extract that information at all.

**Why it happens:** Five entity types (Requirements, Decisions, Actions, Risks, Stakeholders) are a reasonable starting taxonomy, but they reflect a specific mental model of project work. The real world has: assumptions, constraints, dependencies, open questions, parking lot items, principles, and non-decisions. Forcing these into the five buckets degrades the wiki's usefulness because queries will miss things or mis-categorize them.

**Warning signs:**
- User frequently asks during `/sara-discuss` "what type is this?"
- Many pages accumulate with "type: Risk" but are clearly dependency constraints or assumptions
- "Decisions" folder fills up with things that aren't actually decided yet
- User starts adding free-text notes to override schema fields

**Prevention:**
- Build in explicit escape valves from day one: an "other" or "note" artifact type, or a `tags` free-text field on every entity, allows the schema to flex without breaking
- The five types should be treated as primary shapes, not a closed enum — the LLM's role during `/sara-discuss` is to help map the messy real world to the nearest type, with explicit acknowledgment when the fit is imperfect
- Consider "parking lot" as a first-class concept: things ingested but not yet classified. This prevents the schema from becoming a gatekeeper that causes information to be dropped
- Do not over-engineer the schema at Phase 1 — ship with the minimum viable fields per type and add fields only when a real ingest proves they're needed

**SARA phase:** Phase 1 (entity type definition), ongoing validation in Phase 2+.

---

### C4: State Corruption — Pipeline State Out of Sync With Wiki State

**What goes wrong:** The user runs `/sara-extract N` and approves an artifact list. Then Claude Code crashes, the conversation times out, or the user closes the window. `/sara-update N` is never run. Now the pipeline state says "extraction approved" but the wiki has nothing. Or worse: `/sara-update N` partially writes some pages before failing mid-write. The wiki is now in a partially-updated state with no clean rollback path.

**Why it happens:** SARA maintains pipeline state (stage, discussion context) per input item, but that state is separate from the wiki state (the actual markdown files and git commits). These two state stores can desync. Git makes the wiki recoverable (revert the partial commit), but only if commits are atomic — one commit per `/sara-update` call, not per-page writes.

**Warning signs:**
- Pipeline state shows "update complete" but wiki pages not found
- Pipeline state shows "pending update" but wiki pages already exist
- Git log shows partial commits (some pages from an ingest, not all)
- `index.md` references pages that don't exist

**Prevention:**
- All wiki writes for a single ingest must be an atomic git commit — write all pages, update `index.md`, update `log.md`, then commit. Never commit page-by-page.
- Pipeline state should reflect the last successfully committed ingest, not the last command run. After commit, mark state as "complete". If commit fails, state remains "update in progress" — re-runnable.
- `/sara-lint` should include a state coherence check: does every "complete" ingest in pipeline state have a corresponding git commit? Does `index.md` reflect all actual wiki pages?
- Design `/sara-update N` as idempotent: if run twice for the same N, it detects pages already written and skips or confirms rather than duplicating.

**SARA phase:** Phase 1 (pipeline state design and commit strategy). This cannot be retrofitted.

---

### C5: The Index Rots — `index.md` Becomes the Weakest Link

**What goes wrong:** `index.md` is the catalog of all wiki pages. The LLM updates it on every ingest. Over time, pages get renamed (a stakeholder changes roles, a requirement is superseded), but `index.md` still points to the old filename. Or pages are created during a `/sara-update` but `index.md` update fails (partial write). Or the index becomes so large it exceeds what can be loaded in a single context window, and the LLM starts writing a new section without reading the existing one — producing duplicate index entries.

**Why it happens:** A single file that every ingest must update is a concurrency hazard in multi-user settings and a coherence hazard in single-user settings when updates are partial. `index.md` is also implicitly a growing document with no natural pruning mechanism.

**Warning signs:**
- Dead links in `index.md` (files it references no longer exist)
- Duplicate entries for the same entity
- Pages that exist on disk but have no `index.md` entry
- `index.md` growing to 500+ lines and becoming hard to navigate

**Prevention:**
- `/sara-lint` must validate `index.md` bidirectionally: every entry has a real file, every real file has an entry
- Treat `index.md` as generated, not hand-edited — `/sara-lint --fix` should be able to regenerate it from disk contents
- Design `index.md` structure so sections are addable without requiring a full rewrite (e.g., sectioned by entity type so the LLM only needs to update the relevant section)
- Set a context-window budget for `index.md` — if it grows past ~200 lines, consider splitting by entity type (a `requirements/index.md`, `decisions/index.md`, etc.)

**SARA phase:** Phase 1 (index design), Phase 2 (lint --fix capability).

---

## Moderate Risks

These create real problems but don't immediately kill the project — they accumulate damage over time or create sharp edges discoverable through use.

---

### M1: LLM Hallucination in Wiki Content

**What goes wrong:** During `/sara-extract`, the LLM proposes an artifact that extrapolates beyond what the source actually says. "The stakeholder expressed concern about latency" becomes a Risk page stating "Requirement: sub-100ms latency SLA". The user approves because they were moving fast and the proposal looked reasonable. Now the wiki contains a false requirement that will influence future decisions.

**Prevention:** The `/sara-extract` approval step must show the user the exact source text that justifies each artifact proposal, not just the artifact itself. Forcing the LLM to quote its evidence changes the approval from rubber-stamping to genuine validation. Design the extract output format with "Source quote:" as a required field for every artifact.

**SARA phase:** Phase 1 (extract command output format).

---

### M2: Context Window Amnesia Between Sessions

**What goes wrong:** SARA is designed to be resumable. But "resumable" in Claude Code means the next session must reload state from disk. If the pipeline state files don't capture enough context from the previous `/sara-discuss` session, the LLM starts the next `/sara-discuss` cold — re-asking questions already answered, proposing extractions already rejected, losing the nuance of the previous discussion.

**Why it happens:** Conversation history in Claude Code doesn't persist between sessions. Pipeline state must be rich enough to reconstitute the discussion intent — a bare status flag ("stage: discuss") is insufficient.

**Prevention:** Pipeline state for each ingest item must persist: the agreed extraction intent (as a structured summary), any user overrides or rejections from previous discuss/extract rounds, and any explicit constraints the user set. `/sara-discuss` should write a `discussion-summary` field to the state file at the end of each session — not just update the stage.

**SARA phase:** Phase 1 (pipeline state schema design).

---

### M3: Git History Pollution — Noisy, Unreadable Log

**What goes wrong:** Every ingest produces a git commit. If the commit messages are auto-generated and generic ("Update wiki for ingest 007"), the git log becomes a meaningless scroll. The value of git-backed state (auditability, diffability, rollback) is wasted if the history is unreadable.

**Prevention:** Commit messages should be meaningful and structured: "Ingest 007: Meeting — Architecture Review 2026-04-15. Created: ADR-003, REQ-012. Updated: RISK-004. Stakeholders: 3." This makes `git log --oneline` genuinely useful for audit. The commit message format should be standardized in the command implementation, not left to LLM improvisation.

**SARA phase:** Phase 1 (commit message template).

---

### M4: Over-Extraction — Wiki Grows Faster Than It Can Be Maintained

**What goes wrong:** The LLM is enthusiastic. A 90-minute architecture meeting produces 24 proposed artifacts. The user approves most of them. Three meetings later, there are 70+ wiki pages. Many are thin (one paragraph, minimal content). The wiki starts feeling like a burden rather than an asset — navigating it takes longer than the value it returns.

**Why it happens:** LLMs optimize for completeness when proposing extractions; humans optimize for value when using a wiki. These goals diverge. An LLM that extracts everything produces a comprehensive but unusable wiki. The right extraction is selective.

**Prevention:** During `/sara-discuss`, explicitly discuss extraction scope — "how many artifacts should we extract from this source?" should be part of the discussion protocol. Design the discuss command to push back on over-extraction: "This meeting had 12 potential requirements. Shall we extract all of them, or focus on the 3-4 that are new or substantially changed?" The user should feel empowered to extract less.

**SARA phase:** Phase 1 (discuss command protocol design).

---

### M5: Orphan Pages — Pages That Become Unlinked and Invisible

**What goes wrong:** An Action page is created for "George to follow up with vendor by EOQ." The quarter ends, the action is complete, nobody closes it in SARA. It remains "open" in perpetuity. Or a Stakeholder page is created for a consultant who left the project. The page exists, has cross-references, but the stakeholder is gone. Future queries that include stakeholder context will surface irrelevant people.

**Why it happens:** SARA's ingest pipeline is optimized for creation, not lifecycle management. There's no natural prompt for "close out completed actions" or "mark stakeholders as inactive."

**Prevention:** `/sara-lint` should surface stale open Actions (open for >N days), inactive Stakeholders (no references in recent ingests), and orphan pages (no cross-references from any other page). Staleness detection doesn't require closing the item — just surfacing it for human review. Consider a `sara-review` or periodic `/sara-lint --report` that emails or prints a staleness digest.

**SARA phase:** Phase 2 (lint command design).

---

### M6: Schema Version Lock — Impossible to Evolve the Entity Format

**What goes wrong:** Phase 1 ships with entity schemas (e.g., a Decision page has fields: `id`, `title`, `status`, `rationale`, `date`, `stakeholders`). After three months of real use, you need a new field: `superseded_by`. But 40 existing Decision pages don't have this field. The LLM now reads some pages with the new field and some without, producing inconsistent behavior. `/sara-lint` can't enforce a field that didn't exist when old pages were written.

**Prevention:** Every entity page must include a `schema_version` field from day one. When the schema evolves, `/sara-lint --migrate` can detect pages on old schema versions and prompt for upgrade. Without schema versioning, evolution requires manual bulk editing of all existing pages — a task that never gets done.

**SARA phase:** Phase 1 (entity schema design). One field, major future pain avoided.

---

### M7: `/sara-query` Confidently Wrong Answers

**What goes wrong:** The user asks `/sara-query "What did we decide about the database technology?"` The wiki has ADR-003 (PostgreSQL chosen) and an older conflicting note in an email ingest that was never properly resolved. The LLM synthesizes an answer that sounds authoritative but blends two contradictory states. The user acts on the answer without realizing it's composited from conflicting sources.

**Why it happens:** `/sara-query` reads wiki content and synthesizes answers. If the wiki contains contradictions (see C2), the query command will faithfully reflect those contradictions — but may not surface them clearly. LLMs default toward confident synthesis rather than surfacing uncertainty.

**Prevention:** `/sara-query` should be designed to: (a) cite the specific wiki pages its answer draws from, (b) flag when source pages have conflicting information, and (c) indicate the date of the most recent update for each cited page. Answers without citations are dangerous in a knowledge management context.

**SARA phase:** Phase 2 (query command design). The query command is only safe to use once the wiki has enough content to test contradiction handling.

---

### M8: The One-Repo-Per-Project Silo Problem

**What goes wrong:** SARA is designed with one repo per project. After six months, the user has three SARA repos. A new project starts that's architecturally related to an older one. The user can't query across projects. The architecture decisions from the old project that are directly relevant to the new one are invisible. Cross-project learning — one of the most valuable forms of institutional knowledge — is structurally impossible.

**Why it happens:** The design decision (one repo per project) correctly solves multi-user conflict and namespace pollution. But it has a cost: siloed knowledge.

**Prevention:** This is explicitly deferred (out of scope for v1), but it should be flagged as a design constraint that v2 must address. The wiki format should be designed with portability in mind: entity IDs scoped to project (not global auto-increment integers), page formats that could be merged across repos without collision. A future `/sara-merge-repos` or a shared `decisions/` library becomes feasible if entities are namespaced from the start.

**SARA phase:** Phase 1 (entity ID namespacing). Low cost now, high cost later if ignored.

---

### M9: Meeting Intelligence — Transcript Quality Degrades Everything Downstream

**What goes wrong:** SARA ingests a meeting transcript. The transcript was auto-generated by Teams or Zoom, has speaker errors ("George" and "George B." are two different speakers, neither is correctly identified), missing timestamps, and garbled technical terms. The LLM's extraction is only as good as the source. Bad transcripts produce bad artifacts — requirements that are actually questions, decisions that are actually hypotheticals, action items attributed to the wrong person.

**Warning signs:** Action items assigned to wrong stakeholders; Requirement pages that say "we should consider whether..." (i.e., a question, not a requirement); Decisions that are actually open issues.

**Prevention:** `/sara-discuss` should explicitly surface transcript quality issues. The discussion protocol should include a prompt: "I noticed potential quality issues in the transcript: [list]. Please clarify before we proceed." The user, who was in the meeting, can correct misattributions and garbling before any artifacts are written.

**SARA phase:** Phase 1 (discuss command protocol), particularly the meeting transcript handling branch.

---

## Phase Mapping

Which phase should mitigate which pitfall.

| Pitfall | ID | Phase | How |
|---------|----|-------|-----|
| Friction kills adoption | C1 | Phase 1 | Design ingest pipeline for minimum viable ceremony; resumability as a first-class requirement |
| Wiki drift / contradictions | C2 | Phase 1 + Phase 2 | Page update logic (not create-always), atomic commits; lint detects contradictions |
| Schema rigidity | C3 | Phase 1 | Define entity types with escape valves (tags, "note" type); don't over-enumerate fields |
| Pipeline state / wiki state desync | C4 | Phase 1 | Atomic commit strategy; idempotent `/sara-update`; state coherence in lint |
| Index rot | C5 | Phase 1 + Phase 2 | Index design (regenerable from disk); lint validates bidirectionally |
| Hallucination in extractions | M1 | Phase 1 | Extract output must include source quotes as required field |
| Context amnesia between sessions | M2 | Phase 1 | Pipeline state must store discussion summary, not just stage |
| Git history pollution | M3 | Phase 1 | Standardized commit message template with artifact counts |
| Over-extraction bloat | M4 | Phase 1 | Discuss protocol explicitly addresses extraction scope |
| Orphan pages / lifecycle | M5 | Phase 2 | Lint surfaces stale open Actions, inactive Stakeholders, orphan pages |
| Schema version lock | M6 | Phase 1 | Add `schema_version` field to every entity page from day one |
| Confidently wrong query answers | M7 | Phase 2 | Query command cites sources and flags contradictions |
| Cross-project knowledge silo | M8 | Phase 1 (namespacing only) | Entity IDs namespaced to project; full solution deferred to v2 |
| Transcript quality degradation | M9 | Phase 1 | Discuss protocol surfaces and resolves transcript quality issues before extraction |

---

## Confidence Assessment

| Area | Level | Basis |
|------|-------|-------|
| Personal wiki failure modes (abandonment, friction) | HIGH | Well-documented pattern across Roam, Notion, Obsidian communities; consistent findings |
| LLM knowledge drift mechanisms | HIGH | Mechanistically understood: partial context windows, no global consistency check |
| Stateful CLI / pipeline abandonment | HIGH | Software engineering pattern; applies directly to multi-step workflows |
| Schema rigidity vs real-world messiness | HIGH | Classic information architecture problem; directly applicable |
| Git atomicity pitfalls | HIGH | Well-understood VCS pattern |
| Meeting intelligence transcript quality | MEDIUM | Younger domain; patterns emerging but less codified |
| Cross-project silo impacts over time | MEDIUM | Long-term pattern; depends heavily on project diversity |

---

## Summary: Highest Priority Actions for Phase 1

1. **Resumability is not optional** — every pipeline command must be re-entrant. A command that can't be safely re-run after a crash will cause state corruption.

2. **Atomic commits, every time** — all wiki writes for a single ingest in one commit, with a structured commit message. This is the primary guard against C4.

3. **Extract must cite sources** — the approval step is only meaningful if the user can verify the LLM's evidence. Source quotes in the extract proposal format.

4. **Supersession over creation** — when the LLM encounters an existing entity during extraction, it must update (with change log) rather than create a duplicate. "Update, don't duplicate" should be a core instruction.

5. **`schema_version` from day one** — one field, prevents M6 from becoming catastrophic.

6. **`/sara-lint` as hygiene, not emergency** — design it to run routinely (after every N ingests), not just when something feels wrong.
