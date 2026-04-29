# Phase 7: adjust-agent-workflow - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the four specialist Task() agents in `sara-extract` with sequential inline extraction passes that run inside the main skill loop. The source document is read once and stays in context; each pass extracts one artifact type using an inline prompt. The sorter agent (Task()) is retained unchanged. The four specialist agent files are deleted and removed from `install.sh` distribution.

No changes to: the sorter agent, the per-artifact approval loop, sara-update, wiki schemas, or pipeline-state.json structure.

</domain>

<decisions>
## Implementation Decisions

### Extraction architecture

- **D-01:** The four specialist Task() agents are eliminated. Their logic moves into sequential inline extraction passes inside `sara-extract` SKILL.md Step 3.
- **D-02:** The source document is read once in Step 2 and stays in the main skill context. It is NOT passed to any Task() call.
- **D-03:** Four sequential extraction passes run inside the main loop — one per artifact type (requirement, decision, action, risk). Each pass issues an inline LLM prompt against the already-in-context source document and collects a JSON array of artifacts.
- **D-04:** Pass order: requirement → decision → action → risk. Sequential, not parallel.
- **D-05:** Each per-type extraction prompt is written inline in Step 3 of SKILL.md (not in a notes section or separate file).

### Sorter agent

- **D-06:** `sara-artifact-sorter.md` stays exactly as-is. Its inputs (merged artifacts + grep summaries + wiki/index.md) are unchanged. No edits required.
- **D-07:** The sorter remains a Task() call. It receives no source document — only the merged artifact array, which is small regardless of source size.

### Deleted files

- **D-08:** Four specialist agent files are deleted:
  - `.claude/agents/sara-requirement-extractor.md`
  - `.claude/agents/sara-decision-extractor.md`
  - `.claude/agents/sara-action-extractor.md`
  - `.claude/agents/sara-risk-extractor.md`
- **D-09:** `install.sh` is updated to remove the specialist agent files from the distribution loop. Only `sara-artifact-sorter.md` remains in the agent distribution.

### Claude's Discretion

- Exact wording of each per-type extraction prompt (must produce the same JSON schema as the deleted specialist agents)
- Whether to add a brief preamble before the extraction passes explaining the overall structure to the reader of SKILL.md
- Error handling if an inline extraction pass returns malformed JSON (retry logic, fallback)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills being modified
- `.claude/skills/sara-extract/SKILL.md` — Steps 2–3 are rewritten; Step 1 (stage guard), Step 4 (approval loop), Step 5 (write plan) are unchanged
- `install.sh` — Agent distribution loop updated to remove the four specialist files

### Agent files being deleted
- `.claude/agents/sara-requirement-extractor.md` — Deleted; its prompt logic moves inline into sara-extract Step 3
- `.claude/agents/sara-decision-extractor.md` — Deleted; same
- `.claude/agents/sara-action-extractor.md` — Deleted; same
- `.claude/agents/sara-risk-extractor.md` — Deleted; same

### Agent file retained (read for reference, do not modify)
- `.claude/agents/sara-artifact-sorter.md` — Unchanged; sorter input format must remain compatible with merged artifact array produced by the new inline passes

### Artifact schema (inline prompts must produce this format)
- `.claude/skills/sara-extract/SKILL.md` §Step 3 — Canonical artifact object schema (`action`, `type`, `title`, `source_quote`, `raised_by`, `related`, `change_summary`, `id_to_assign`) — inline prompts must produce identical output to the deleted specialist agents

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sara-extract` Step 1 (stage guard): unchanged verbatim
- `sara-extract` Step 2 (load source + discussion notes + wiki index): unchanged verbatim
- `sara-extract` Step 4 (per-artifact approval loop): unchanged verbatim
- `sara-extract` Step 5 (write extraction plan + advance stage): unchanged verbatim
- `sara-artifact-sorter.md`: unchanged verbatim

### Established Patterns
- All pipeline-state reads/writes use Read + Write tools only — no shell text-processing
- Agents spawned via Task() start cold — but the sorter only needs small inputs (merged array + grep output + index), so this is fine
- `source_quote` is MANDATORY for every artifact — inline extraction prompts must enforce this
- The specialist agents always returned `action: "create"` with `id_to_assign: "{TYPE}-NNN"` placeholder — inline passes must do the same; create-vs-update resolution stays with the sorter

### Integration Points
- `sara-extract` SKILL.md Step 3: full rewrite — Task() dispatch replaced by sequential inline passes + single sorter Task() call
- `install.sh`: remove 4 agent filenames from distribution loop, keep `sara-artifact-sorter.md`
- `.claude/agents/`: 4 files deleted, 1 file (sorter) retained

</code_context>

<specifics>
## Specific Ideas

- The motivation is token cost: passing the full source document to 4 parallel Task() agents costs ~4x the source document size in tokens. Sequential inline passes eliminate this — the source is read once and stays in context.
- Production SARA sources are expected to be much larger than test fixtures. The current architecture does not scale with document size or number of artifact types.
- Adding a new artifact type in the new architecture: add one more inline extraction pass in Step 3 and update `install.sh` if any agent file is added. No new agent file required for the extraction logic itself.

</specifics>

<deferred>
## Deferred Ideas

- Parallel inline passes (running all four extraction prompts simultaneously without Task()) — not possible with current LLM call patterns; Task() is required for parallelism but reintroduces the doc-passing problem. Sequential is the right call for now.
- Un-typed candidate pre-filtering (Option B) — extract all notable passages once, pass the candidate list to specialists — discussed and set aside in favour of simpler sequential inline passes.

</deferred>

---

*Phase: 07-adjust-agent-workflow*
*Context gathered: 2026-04-29*
