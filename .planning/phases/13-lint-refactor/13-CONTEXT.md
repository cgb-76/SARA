# Phase 13: lint-refactor - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Rewrite `sara-lint` from a narrow field-presence validator (v1: missing summaries only) into a full LLM-driven wiki health-check consistent with the llm-wiki design intent: periodically ask the LLM to reason over the entire wiki and identify contradictions, stale claims, orphaned pages, missing cross-references, missing concept pages, and data gaps.

The phase also introduces **PGE (Page)** as a new wiki entity type for concept/reference pages created during lint's concept-discovery check.

Two categories of checks:
1. **Mechanical checks** — grep-detectable: missing v2.0 frontmatter fields, broken `related[]` IDs, orphaned pages, index↔disk sync, Cross Links body↔frontmatter sync
2. **Semantic checks** — LLM reasoning: contradictions between pages, stale claims superseded by newer sources, important concepts mentioned but lacking their own page, missing cross-references the LLM can infer

No changes to: sara-extract, sara-update, sara-discuss, sara-ingest, sara-init, pipeline-state.json structure.

</domain>

<decisions>
## Implementation Decisions

### Check scope

- **D-01:** Phase 13 implements ALL checks — both mechanical and semantic. This delivers the full llm-wiki health-check vision in one phase.

### Mechanical checks

- **D-02:** **Missing v2.0 fields** — Check all entity types for fields introduced in phases 8–12:
  - REQ: `type` (functional/non-functional/regulatory/integration/business-rule/data), `priority` (must-have/should-have/could-have/wont-have)
  - DEC: `type` (architectural/process/tooling/data/business-rule/organisational)
  - ACT: `type` (deliverable/follow-up), `due-date`, `owner`
  - RSK: `type` (technical/financial/schedule/quality/compliance/people), `likelihood`, `impact`, `owner`
  - STK: `segment` (renamed from `vertical` in Phase 12)
  - All artifact types: `segments: []` (Phase 12)
  - All artifact types: `schema_version: '2.0'` (Phases 8–11)

- **D-03:** **Broken `related[]` IDs** — For every page, verify each ID in the `related:` frontmatter resolves to an existing wiki page file on disk.

- **D-04:** **Orphaned pages** — Find wiki pages not listed in `wiki/index.md`.

- **D-05:** **Index↔disk sync** — Verify `wiki/index.md` rows match actual files on disk (bidirectional: catch stale rows and missing rows).

- **D-06:** **Cross Links↔`related[]` sync** — Check that the `## Cross Links` body section lists the same IDs as the `related:` frontmatter field. Flag divergence.

### Back-fill for mechanical gaps

- **D-07:** For every mechanical gap, lint offers to infer and back-fill the missing value:
  - Missing `type`/`priority`: inferred by reading the page body content (same LLM reasoning used at extraction time)
  - Missing `segments`: inferred from STK `segment` attribution and keyword matching against `config.segments` — same logic as sara-extract D-05
  - Missing `schema_version`: written as `'2.0'` directly (no inference needed)
  - Missing/inconsistent `## Cross Links`: regenerated from the `related:` frontmatter
  - Orphaned page: added to `wiki/index.md`
  - Stale index row: corrected to match disk state

### Semantic checks

- **D-08:** **Contradictions** — LLM reads all pages of each entity type and identifies pairs or groups of pages with conflicting claims (e.g. two DEC pages asserting incompatible choices, a REQ marked accepted that contradicts a DEC marked rejected).

- **D-09:** **Stale claims** — LLM identifies content that may have been superseded by a more recent ingest. Uses `source:` ingest IDs and `wiki/log.md` chronology to reason about recency.

- **D-10:** **Missing concept pages (PGE)** — LLM scans for concept terms mentioned across multiple pages that have no dedicated wiki entry. Proposes a PGE stub for each.

- **D-11:** **Missing cross-references** — LLM identifies page pairs that clearly relate to each other (same stakeholders, overlapping topics, causal links) but have no `related:` entry connecting them. Proposes adding the link to both pages.

- **D-12:** **Data gaps** — LLM flags fields left empty that could be inferred from body content (e.g. `likelihood: ""` on a RSK page that says "very likely" in the body). These go through the same per-finding approval loop as other back-fills.

### Approval flow

- **D-13:** **Per-finding approval** — Every proposed fix (mechanical or semantic) is presented individually with a plain-text description of the issue and the proposed change. User accepts or rejects each one before anything is written.

- **D-14:** **One commit per fix** — Each accepted fix is committed immediately after writing. Consistent with sara-update's atomic commit pattern. Easy to revert individual fixes via git.

### Concept page creation flow (PGE)

- **D-15:** New entity type: **PGE** (Page). ID format: `PGE-NNN`. For concept/reference entries that don't fit REQ, DEC, ACT, RSK, or STK.

- **D-16:** Frontmatter shape for PGE:
  ```yaml
  ---
  id: PGE-NNN
  title: ""
  summary: ""
  schema_version: '2.0'
  tags: []
  related: []
  ---
  ```

- **D-17:** When lint proposes a concept page and the user accepts:
  1. Lint asks for more information about the concept (a short interview — what is it, why it matters, how it relates to the project)
  2. User's answers become the page body content
  3. Page is created with frontmatter + body, committed atomically
  4. `wiki/index.md` updated and committed in the same batch

- **D-18:** PGE pages live in a new `wiki/pages/` subdirectory (consistent with other entity type directories). sara-init should add this directory in a follow-up phase; for now lint creates it if absent.

### Semantic fix proposals

- **D-19:** For semantic findings (contradictions, stale claims, missing cross-refs):
  - Lint presents the finding with the relevant page IDs and a plain-English description of the issue
  - Lint proposes a specific concrete change (e.g. "update REQ-003 `status` to `superseded`, add `related: [REQ-007]`" or "add `related: [DEC-002]` to ACT-005 and vice versa")
  - User accepts or rejects
  - On accept: lint writes the change and commits
  - **Lint never rewrites narrative body content unilaterally** — it can update frontmatter fields, add/remove IDs from `related:`, and update `status` values, but proposing a body-text rewrite requires the user to provide the new text

### Claude's Discretion

- Exact grouping and ordering of checks within the lint run (mechanical checks first, then semantic is the natural order)
- Whether to show a summary count ("12 findings") before starting the per-finding loop or jump straight in
- Exact wording of the per-finding prompts
- How to handle the case where a concept term appears on only two pages — threshold for proposing a PGE is Claude's call

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing sara-lint skill
- `.claude/skills/sara-lint/SKILL.md` — Current v1 implementation (Check 1 only, Checks 2/3 stubbed). Phase 13 rewrites this file entirely.

### v2.0 frontmatter schemas (per entity type)
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — REQ v2.0 schema: `type`, `priority` fields, removed `description`
- `.planning/phases/09-refine-decisions/09-CONTEXT.md` — DEC v2.0 schema: `type` field, removed narrative frontmatter
- `.planning/phases/10-refine-actions/10-CONTEXT.md` — ACT v2.0 schema: `type`, `due-date`, `owner` fields
- `.planning/phases/11-refine-risks/11-CONTEXT.md` — RSK v2.0 schema: `type`, `likelihood`, `impact`, `owner` fields
- `.planning/phases/12-vertical-awareness/12-CONTEXT.md` — `segments: []` on all artifact types; STK `segment` rename

### llm-wiki design intent
- `.ideation/personal-knowledgebase/llm-wiki.md` — Source document defining the health-check vision that sara-lint implements

### Prior pipeline patterns
- `.planning/phases/05-artifact-summaries/05-CONTEXT.md` — Summary back-fill pattern (grep -rL scan, dry-run confirm, batch write) — mechanical back-fill model for this phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-lint/SKILL.md` Check 1: grep-based scan pattern (`grep -rL`) and confirm-then-commit loop — reuse for all mechanical back-fills
- `wiki/index.md`: LLM-maintained catalog — reference for orphaned page and index sync checks
- `wiki/log.md`: append-only ingest chronology — reference for stale claims check
- `.sara/config.json` `segments` array — required for `segments` field inference (same as sara-extract D-06)
- `.sara/pipeline-state.json` `id_counters` — PGE IDs must use the same counter pattern as REQ/DEC/ACT/RSK/STK

### Established Patterns
- Read/Write tools only for wiki files — no Bash text-processing (sed, awk, jq) on markdown files
- Per-artifact commit pattern from sara-update: write file → git add explicit paths → git commit
- `AskUserQuestion` with "Proceed"/"Cancel" options for user-gated operations

### Integration Points
- `wiki/pages/` — new subdirectory; lint creates it if absent (`mkdir -p`)
- `pipeline-state.json` `id_counters.PGE` — lint must initialise this counter if not present, increment on each PGE creation
- `wiki/index.md` — updated when orphaned pages are fixed or PGE pages are created

</code_context>

<specifics>
## Specific Ideas

- The concept-page mini-interview (D-17) should feel like a lightweight `/sara-discuss` — lint asks what the concept is, why it matters, and how it relates to the project; user's answers fill the body. Not a full discussion, just enough for a useful page.
- Lint should read `wiki/log.md` to understand ingest chronology when reasoning about stale claims — newer ingests take precedence over older ones on the same topic.
- The PGE entity type is intentionally minimal — no `status`, no `source`, no `owner`. It's a reference page, not a tracked artifact.

</specifics>

<deferred>
## Deferred Ideas

- `--fix` flag for non-interactive batch apply of all mechanical fixes — a natural v2 enhancement once the per-finding loop is proven
- sara-init update to include `wiki/pages/` directory and PGE template in fresh wiki setup — belongs in a follow-up phase
- REQUIREMENTS.md update to add PGE entity type — bookkeeping for a follow-up
- Full body-text rewrite proposals (e.g. updating stale narrative sections) — lint currently proposes only frontmatter and `related[]` changes; body rewrites require user-supplied text

</deferred>

---

*Phase: 13-lint-refactor*
*Context gathered: 2026-04-30*
