# Phase 15: Lint Repair - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend sara-lint with semantic related[] curation (D-07), revert Phase 14's mechanical batch-mate linking from sara-extract and sara-update, and wire sara-update to auto-invoke sara-lint on completion.

Deliverable: after sara-update completes, sara-lint runs automatically, curates related[] and Cross Links for all wiki pages that need it via LLM inference, and commits each fix atomically. After a full lint + repair run, re-running sara-lint reports zero related[]/Cross Links findings.

No new entity types. No changes to sara-ingest, sara-discuss, sara-init, sara-minutes, sara-agenda, or the wiki directory layout.

</domain>

<decisions>
## Implementation Decisions

### Phase 14 revert — remove batch-mate linking

- **D-01:** Remove temp_id assignment from sara-extract Step 3 (all four inline extraction passes). Artifacts still produce `related: []` as the default empty field — only the temp_id population and cross-reference logic is removed.

- **D-02:** Remove full-mesh linking from sara-extract Step 5. The step no longer iterates approved_artifacts to set related[] to peer temp_ids.

- **D-03:** Remove the temp_id → real_id resolution block from sara-update Step 2. The substitution pass is deleted entirely. The write loop proceeds with `related: []` as-is from the extraction plan.

**Rationale:** Batch co-extraction does not imply semantic relatedness. Two artifacts extracted from the same meeting are only related if they're actually about the same thing (e.g., RSK-001 and ACT-003 are related because the action is to set up a workshop around the risk — not because they came from the same transcript). LLM semantic inference is the correct mechanism; batch-mate linking was the wrong premise.

### D-07 — Semantic related[] curation (new sara-lint check)

- **D-04:** Add Check D-07 to sara-lint. D-07 detects all wiki artifact pages where the `related:` frontmatter field is absent or contains an empty list (`related: []`). These pages have not been through LLM curation.

- **D-05:** Repair = LLM reads the target artifact in full, plus all other wiki artifact pages (or their summaries). LLM infers which pages are semantically related — shared topic, one addresses the other, one is a consequence of the other, etc. LLM proposes a `related:` list (can be empty if no relationships found). Present to user for approval before writing. One commit per accepted repair.

- **D-06:** D-07 processes ALL wiki artifact pages with missing or empty related[], not just newly-added ones. Full wiki scan on every run. This ensures legacy pages (extracted pre-Phase 14) and any newly-added pages are all curated in one pass.

- **D-07:** After LLM inference and user approval, the related field is always written (populated list OR confirmed `related: []`). On re-run, pages that have been curated to `related: []` (LLM confirmed no relationships) must NOT be re-flagged. Implementation detail left to Claude's Discretion (see below).

### Cross Links behaviour for empty related[]

- **D-08:** When `related: []` (empty, no relationships), the `## Cross Links` section is **kept as an empty section header** — present in the page body but with no content beneath it. This signals the check has run.

- **D-09:** D-06 (Cross Links↔related[] sync check) is updated to treat an absent Cross Links section as a finding even when `related: []`, and to propose adding the empty section header as the fix.

### Pipeline integration — sara-update auto-invokes sara-lint

- **D-10:** sara-update's final step (after committing all written wiki pages) auto-invokes `/sara-lint`. No prompt needed — lint runs immediately. The user sees the lint output inline as the last part of the sara-update session.

### Claude's Discretion

- How to distinguish "LLM-confirmed empty related[]" from "default empty related[] never curated" to avoid re-flagging on re-run. Acceptable approaches: (a) only flag absent related fields, treat `related: []` as curated; (b) add a `related_curated: true` frontmatter marker when LLM runs; (c) accept that LLM proposes the same `related: []` again and the user skips it. Pick the simplest approach that satisfies the zero-findings re-run criterion.
- Ordering of D-07 within the overall lint check sequence (before or after D-02 through D-06)
- How many wiki pages the LLM reads in one pass vs whether it works page-by-page (context window consideration for large wikis)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills to modify
- `.claude/skills/sara-extract/SKILL.md` — Remove temp_id assignment (Step 3) and full-mesh linking (Step 5). D-01 and D-02 above.
- `.claude/skills/sara-update/SKILL.md` — Remove temp_id→real_id resolution block (Step 2). Add sara-lint auto-invocation as final step. D-03 and D-10 above.
- `.claude/skills/sara-lint/SKILL.md` — Add D-07 semantic related[] check. Update D-06 for empty Cross Links behaviour. D-04 through D-09 above.

### Phase 14 changes being reverted
- `.planning/phases/14-extraction-pipeline-fix/14-CONTEXT.md` — D-01/D-02/D-03 describe exactly what was added. Phase 15 removes those specific additions.
- `.planning/phases/14-extraction-pipeline-fix/14-01-PLAN.md` — Details of temp_id and full-mesh linking added to sara-extract. Read to identify precise removal targets.
- `.planning/phases/14-extraction-pipeline-fix/14-02-PLAN.md` — Details of temp_id→real_id resolution added to sara-update. Read to identify precise removal targets.

### Prior sara-lint context
- `.planning/phases/13-lint-refactor/13-CONTEXT.md` — D-08/D-09 (per-finding approval, one commit per fix) carry forward unchanged. D-06 (Cross Links↔related[] sync) is extended, not replaced.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-lint` D-02 through D-06: all five existing checks carry forward unchanged. D-07 is an additive sixth check.
- `sara-lint` per-finding approval loop (Step 5): D-07 findings join the same loop — same AskUserQuestion pattern, same atomic commit pattern.
- `sara-extract` extraction passes: `related: []` default already set in all four passes. Only the temp_id population lines are removed.

### Established Patterns
- Read/Write tools only for wiki files — no Bash text-processing on markdown
- Per-finding approval + one commit per fix (D-08/D-09 from Phase 13)
- AskUserQuestion with "Apply"/"Skip" options
- git add explicit file paths + git commit with templated message

### Integration Points
- `sara-update` final step → invokes sara-lint. Skill-to-skill invocation pattern (not yet established — planner to confirm mechanism)
- `wiki/index.md` and Cross Links body sections — no structural changes
- `.sara/pipeline-state.json` — no new fields; temp_id fields removed from extraction_plan

</code_context>

<specifics>
## Specific Ideas

- The LLM inference pass for D-07 reads artifact content semantically: RSK-001 and ACT-003 are related because the action addresses the risk — not because of co-extraction timing. Downstream planner should use this example in the skill prompt.
- For large wikis, LLM may need to work per-artifact with a summary of all other pages rather than reading every page in full each time.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 15-lint-repair*
*Context gathered: 2026-05-01*
