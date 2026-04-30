# Phase 14: Extraction Pipeline Fix - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Modify sara-extract to infer related[] links between co-extracted artifacts and modify sara-update to write those links to wiki page frontmatter. No new entity types, no new pipeline stages, no changes to sara-discuss, sara-ingest, sara-lint, sara-init, or the wiki directory layout.

Deliverable: after /sara-extract, the extraction_plan in pipeline-state.json has populated related[] fields on every approved artifact; after /sara-update, every written wiki page has a populated related[] frontmatter field (or empty [] for single-artifact batches).

</domain>

<decisions>
## Implementation Decisions

### Temp ID scheme (ID placeholder strategy)

- **D-01:** sara-extract assigns an 8-hex random string `temp_id` to each artifact at extraction time (Step 3, during the four inline passes). This temp_id is used as a stable cross-reference key throughout the extract → approval → update flow.

- **D-02:** Full-mesh related[] linking is performed at **Step 5** (after the approval loop, before writing to pipeline-state.json). For each artifact in `approved_artifacts`, set `related` to the `temp_id` values of all other artifacts in `approved_artifacts`. Rejected artifacts are never in `approved_artifacts`, so their temp_ids never enter any related[] — no cleanup step needed.

- **D-03:** sara-update resolves temp IDs to real IDs at the **start of Step 2** (before writing any wiki pages). Build a `temp_id → real_id` map by iterating through the extraction_plan, assigning real IDs using the current id_counters sequence (the same sequence the write loop will use). Then do a substitution pass over all related[] arrays in the extraction_plan, replacing temp_ids with real IDs. Proceed to write pages with related[] already fully resolved.

### Inference scope

- **D-04:** Full mesh — every approved artifact in a batch links to every other approved artifact in the same batch. No topic-based filtering. Simple, consistent, and correct for SARA's extraction model (all artifacts derive from the same source document).

### Single-artifact batches

- **D-05:** A batch that produces exactly one approved artifact gets `related: []` (empty array, not a missing field). This is already the default from the extraction passes; the linking step simply produces an empty mesh for a single-artifact batch. No special case needed.

### Claude's Discretion

- Exact format of temp_id generation (e.g., `crypto.randomBytes(4).toString('hex')` or equivalent inline approach)
- Whether temp_id is stored in the artifact object in pipeline-state.json or discarded after the update substitution pass (can be stripped from pipeline-state.json after resolution to keep the schema clean)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills to modify
- `.claude/skills/sara-extract/SKILL.md` — Current sara-extract implementation: Step 3 (extraction passes + sorter), Step 4 (approval loop), Step 5 (write extraction_plan). temp_id assignment goes in Step 3; full-mesh linking goes in Step 5.
- `.claude/skills/sara-update/SKILL.md` — Current sara-update implementation: Step 2 (write wiki artifact files). temp_id → real_id resolution goes at the start of Step 2, before the write loop.

### Prior pipeline context
- `.planning/phases/07-adjust-agent-workflow/07-CONTEXT.md` — Extraction uses four inline passes, not specialist agents (temp_id must be assigned inline during each pass, not by a separate agent)
- `.planning/phases/13-lint-refactor/13-CONTEXT.md` — D-03 (broken related[] IDs are a lint check), D-06 (Cross Links↔related[] sync check). Phase 14 must produce valid real IDs in related[] so lint passes cleanly.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Each extraction pass already sets `related = []` on every artifact — the field exists in the schema and flows through to sara-update unchanged. Phase 14 replaces the hardcoded `[]` with the temp_id mesh.
- sara-update already reads `artifact.related` and writes it to frontmatter + generates the Cross Links body section. No new write logic needed — just ensure related[] contains real IDs by the time the write loop starts.

### Established Patterns
- Read/Write tools only for pipeline-state.json — no Bash text-processing
- AskUserQuestion with per-artifact Accept/Reject/Discuss loop in sara-extract Step 4 — no changes to this loop
- sara-update's counter increment-before-write pattern (Pitfall 1 guard) must still be respected — the temp_id → real_id resolution peeks at counters without incrementing; the write loop still increments as it creates each artifact

### Integration Points
- `pipeline-state.json` `extraction_plan` array — temp_id fields may be stored here or resolved in-memory before writing. Either works.
- `wiki/index.md` and Cross Links body sections — no change needed; sara-update already writes these from related[]

</code_context>

<specifics>
## Specific Ideas

- temp_id generation: `python3 -c "import secrets; print(secrets.token_hex(4))"` or Node `crypto.randomBytes(4).toString('hex')` — use whatever is simplest inline in the skill (Bash one-liner or inline LLM generation of a random 8-char hex string)
- The substitution pass in sara-update is a simple string replace over the in-memory extraction_plan before the write loop starts — no file reads needed beyond what Step 1 already loads

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 14-extraction-pipeline-fix*
*Context gathered: 2026-04-30*
