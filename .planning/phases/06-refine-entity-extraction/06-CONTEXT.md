# Phase 6: refine-entity-extraction - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Refactor `sara-extract` to use specialist sub-agents per entity type and a sorter sub-agent. Each specialist agent handles extraction for one artifact type in isolation; the sorter merges all outputs, deduplicates, surfaces cross-reference opportunities, and resolves type ambiguities by asking the human targeted questions before the existing per-artifact approval loop runs.

Classification, dedup, and cross-reference reasoning moves from `sara-discuss` to `sara-extract`. `sara-discuss` is narrowed to source comprehension and unknown stakeholder surfacing only.

No changes to `sara-update`, wiki schemas, `pipeline-state.json` structure, or the per-artifact approval loop mechanic.

</domain>

<decisions>
## Implementation Decisions

### Agent files

- **D-01:** Five agent files created in `.claude/agents/`:
  - `sara-requirement-extractor.md`
  - `sara-decision-extractor.md`
  - `sara-action-extractor.md`
  - `sara-risk-extractor.md`
  - `sara-artifact-sorter.md`
- **D-02:** `sara-extract` SKILL.md is the orchestrator — it spawns all agents via Task() and sequences the flow. No additional orchestrator agent.

### Specialist agent inputs

- **D-03:** Each type-specialist agent receives: the raw source document content + the `discussion_notes` string from `pipeline-state.json`. Nothing else. Discussion notes are explicitly passed in — agents start cold and have no implicit access to the discuss phase context.
- **D-04:** Specialist agents do NOT receive grep summaries or the wiki index. They focus on extraction from the source only; dedup and cross-ref is the sorter's responsibility.

### Specialist agent output

- **D-05:** Each specialist agent returns a JSON array matching the existing artifact schema used in `extraction_plan`: `[{action, type, title, source_quote, raised_by, related, change_summary}]`. No new fields. Sorter consumes a consistent format from all four agents.
- **D-06:** `action` returned by specialist agents is always `"create"` with `id_to_assign: "{TYPE}-NNN"` placeholder — the sorter resolves update vs create against the wiki index and grep summaries.

### Sorter agent

- **D-07:** The sorter receives: the merged array of all specialist outputs + the grep-extract summaries (all `summary:` fields) + `wiki/index.md` content.
- **D-08:** The sorter produces two outputs: (1) a cleaned, deduplicated artifact list, and (2) a set of questions for the human covering: type ambiguities ("is this a REQ or DEC?"), likely duplicates ("this looks like DEC-003"), and cross-reference opportunities ("this REQ relates to DEC-007").
- **D-09:** The human resolves sorter questions before the per-artifact approval loop starts. After resolution, the sorter's cleaned list feeds into the existing Accept/Reject/Discuss loop unchanged.

### Approval loop

- **D-10:** The existing per-artifact AskUserQuestion loop (Accept / Reject / Discuss) is preserved as-is. It runs on the sorter's resolved, cleaned artifact list. No change to that mechanic.

### sara-discuss scope change

- **D-11:** `sara-discuss` is narrowed to: (1) source comprehension — clarifying ambiguous passages and agreeing on extraction intent, and (2) surfacing unknown stakeholder names for STK creation via `sara-add-stakeholder`. Classification, dedup, and cross-reference reasoning is removed from `sara-discuss` — those concerns now live in the sorter.

### Claude's Discretion

- Whether specialist agents run in parallel (all 4 Task() calls at once) or sequentially — parallel is the natural fit but orchestrator can decide based on context window constraints
- Exact prompt structure within each agent file
- How the sorter presents its questions (AskUserQuestion calls vs plain-text list)
- What the sorter does when a specialist returns zero artifacts (skip silently)
- Order in which sorter questions are presented when multiple ambiguities exist

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing skills being modified
- `.claude/skills/sara-extract/SKILL.md` — Current orchestration and approval loop; Steps 2–4 are replaced by agent dispatch; approval loop (Step 4) is preserved
- `.claude/skills/sara-discuss/SKILL.md` — Scope narrowed: classification/dedup/cross-ref language removed; source comprehension + STK surfacing retained

### Existing skills for reference (unchanged)
- `.claude/skills/sara-update/SKILL.md` — Reads `extraction_plan` from pipeline-state.json; artifact schema must remain compatible
- `.claude/skills/sara-add-stakeholder/SKILL.md` — Called inline from sara-discuss for unknown stakeholders; unchanged

### Artifact schema (must match in agent output)
- `.claude/skills/sara-extract/SKILL.md` §Step 3 — Canonical artifact object schema (`action`, `type`, `title`, `source_quote`, `raised_by`, `related`, `change_summary`, `id_to_assign`/`existing_id`)

### Grep-extract pattern (sorter uses this)
- `.planning/phases/05-artifact-summaries/05-CONTEXT.md` §D-08 — Grep-extract pattern: `grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/`

### Agent file format
- `.claude/agents/` — Target directory for all 5 new agent files

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-extract` Step 4 (per-artifact approval loop): preserved verbatim — sorter feeds into it, it does not change
- `sara-extract` Step 5 (write extraction_plan + advance stage): unchanged
- Grep-extract pattern from Phase 5: sorter uses this exact command to get existing artifact summaries

### Established Patterns
- All pipeline-state reads/writes use Read + Write tools only — no shell text processing
- Stage guards are Step 1 in all process skills — sara-extract's guard is unchanged
- `source_quote` is mandatory for every artifact — specialist agents must enforce this
- Agents spawned via Task() start cold — all required context must be passed explicitly in the prompt

### Integration Points
- `sara-extract` SKILL.md: Steps 2–3 (load + generate artifact list) replaced by 4 parallel specialist Task() calls + 1 sorter Task() call; Step 4 (approval loop) and Step 5 (write plan) unchanged
- `sara-discuss` SKILL.md: remove classification/dedup/cross-ref language; retain source comprehension + STK surfacing
- `.claude/agents/` directory: 5 new agent files created here

</code_context>

<specifics>
## Specific Ideas

- Specialist agents are isolated by design — future refinement of how decisions are discovered/classified means editing only `sara-extract-decision.md`, not touching the other agents
- Discussion notes must be passed explicitly to each specialist agent in the Task() prompt — this is a known pitfall; agents have no implicit access to the discuss phase context
- Sorter resolves create-vs-update (using grep summaries + index) so specialist agents never need the wiki state — clean separation of concerns

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-refine-entity-extraction*
*Context gathered: 2026-04-28*
