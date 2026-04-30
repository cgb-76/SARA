# Phase 13: lint-refactor - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Rewrite `sara-lint` to validate and back-fill existing wiki pages against the v2.0 schemas introduced in phases 8–12. The check suite is entirely mechanical — grep-detectable field presence, body section presence, and cross-reference integrity. No semantic/LLM reasoning checks. No new entity types.

Deliverable: a `sara-lint` skill that scans all wiki artifact pages, identifies gaps against the current schema, offers to back-fill each gap per-finding, and commits each accepted fix atomically.

No changes to: sara-extract, sara-update, sara-discuss, sara-ingest, sara-init, pipeline-state.json structure, wiki directory layout.

</domain>

<decisions>
## Implementation Decisions

### Check scope — mechanical only

- **D-01:** Phase 13 implements mechanical checks only. Semantic checks (contradictions, stale claims, missing concept pages, data gaps via LLM reasoning) are deferred.

- **D-02:** **Missing v2.0 frontmatter fields** — Check all entity types for fields introduced in phases 8–12:
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

- **D-07:** For every mechanical gap, lint infers and offers to back-fill the missing value:
  - Missing `type`/`priority`: inferred by reading the page body content (same classification logic used at extraction time)
  - Missing `segments`: inferred from STK `segment` attribution and keyword matching against `config.segments` — same logic as sara-extract D-05
  - Missing `schema_version`: written as `'2.0'` directly (no inference needed)
  - Missing/inconsistent `## Cross Links`: regenerated from the `related:` frontmatter
  - Orphaned page: added to `wiki/index.md`
  - Stale index row: corrected to match disk state

### Approval flow

- **D-08:** **Per-finding approval** — Every proposed fix is presented individually with a plain-text description of the issue and the proposed change. User accepts or rejects each one before anything is written.

- **D-09:** **One commit per fix** — Each accepted fix is committed immediately after writing. Consistent with sara-update's atomic commit pattern. Easy to revert individual fixes via git.

### Claude's Discretion

- Exact grouping and ordering of checks within the lint run (running all checks first to collect findings, then looping through them, is acceptable)
- Whether to show a total finding count before starting the per-finding loop
- Exact wording of per-finding prompts

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing sara-lint skill
- `.claude/skills/sara-lint/SKILL.md` — Current v1 implementation (Check 1: missing summaries; Checks 2/3 stubbed). Phase 13 rewrites this file entirely.

### v2.0 frontmatter schemas (per entity type)
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — REQ v2.0 schema: `type`, `priority` fields, removed `description`
- `.planning/phases/09-refine-decisions/09-CONTEXT.md` — DEC v2.0 schema: `type` field, removed narrative frontmatter
- `.planning/phases/10-refine-actions/10-CONTEXT.md` — ACT v2.0 schema: `type`, `due-date`, `owner` fields
- `.planning/phases/11-refine-risks/11-CONTEXT.md` — RSK v2.0 schema: `type`, `likelihood`, `impact`, `owner` fields
- `.planning/phases/12-vertical-awareness/12-CONTEXT.md` — `segments: []` on all artifact types; STK `segment` rename

### Prior pipeline patterns
- `.planning/phases/05-artifact-summaries/05-CONTEXT.md` — Summary back-fill pattern (grep -rL scan, dry-run confirm, write-back, commit) — model for all mechanical back-fills in this phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-lint/SKILL.md` Check 1: `grep -rL` scan pattern and confirm-then-commit loop — reuse for all mechanical back-fills
- `wiki/index.md`: LLM-maintained catalog — reference for orphaned page and index sync checks
- `.sara/config.json` `segments` array — required for `segments` field inference (same as sara-extract D-06)
- `.sara/pipeline-state.json` `id_counters` — no new counters needed (no new entity type)

### Established Patterns
- Read/Write tools only for wiki files — no Bash text-processing (sed, awk, jq) on markdown files
- Per-artifact commit pattern from sara-update: write file → `git add` explicit paths → `git commit`
- `AskUserQuestion` with "Proceed"/"Cancel" for user-gated operations

### Integration Points
- `wiki/index.md` — updated when orphaned pages are fixed
- No new directories, entity types, or pipeline-state fields required

</code_context>

<specifics>
## Specific Ideas

- Mechanical checks can run via `grep` to collect all findings upfront, then loop through findings one at a time for the approval/back-fill flow.
- For missing `type`/`priority` inference, lint reads the page body — the same classification logic that sara-extract uses at ingest time applies here.

</specifics>

<deferred>
## Deferred Ideas

- Semantic checks (contradictions, stale claims superseded by newer sources, data gaps via LLM reasoning) — out of scope for Phase 13
- PGE entity type (concept/reference pages) — out of scope for Phase 13
- `--fix` flag for non-interactive batch apply of all mechanical fixes
- sara-init update for PGE template and `wiki/pages/` directory

</deferred>

---

*Phase: 13-lint-refactor*
*Context gathered: 2026-04-30*
