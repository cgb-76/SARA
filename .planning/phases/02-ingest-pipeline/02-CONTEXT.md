# Phase 2: Ingest Pipeline - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 delivers five Claude Code skills implementing the full four-stage ingest pipeline, plus a reusable stakeholder sub-skill:

- `/sara-ingest` — register a file from `/raw/input/` as a pipeline item; show pipeline status when called with no args
- `/sara-discuss N` — LLM-driven blocker-clearing session; resolves all unknowns before extraction
- `/sara-extract N` — present per-artifact approval loop with accept/reject/discuss options
- `/sara-update N` — execute approved plan atomically in a single git commit
- `/sara-add-stakeholder` — reusable sub-skill: capture → write STK page → commit; callable from other skills and standalone

No query, lint, or meeting-specific commands — those are Phase 3.

</domain>

<decisions>
## Implementation Decisions

### /sara-discuss — Blocker-Clearing Model
- **D-01:** `/sara-discuss N` is LLM-driven, not a freeform chat. The LLM reads the source, generates a blocker list — things that would cause `/sara-extract` to fail or produce wrong output — and works through it in priority order. Done when all blockers are resolved.
- **D-02:** Blocker priority order: (1) unknown stakeholders, (2) ambiguous entity type decisions, (3) missing context gaps, (4) cross-link candidates needing confirmation.
- **D-03:** Stakeholders are batched at the top. `/sara-discuss` scans the full source for all unknown names upfront, resolves all of them via `/sara-add-stakeholder` before moving to any other blockers.
- **D-04:** "Done" is objective — the LLM declares completion when the blocker list is empty. It writes the resolved context to `discussion_notes` in `pipeline-state.json` and advances the item stage to `extracting`.

### /sara-add-stakeholder — Reusable Sub-Skill
- **D-05:** `/sara-add-stakeholder` is a standalone skill AND callable inline from other skills (e.g. `/sara-discuss`). Closed-loop: capture fields → write STK page → increment counter in pipeline-state → update `wiki/index.md` and `wiki/log.md` → commit. Returns a `STK-NNN` ID immediately usable in the calling skill.
- **D-06:** Required field: `name` only. All other fields (`vertical`, `department`, `email`, `role`, `nickname`) are prompted but can be left blank with a placeholder. SARA still assigns a `STK-NNN` ID so it is immediately referenceable.
- **D-07:** Stakeholder schema gains a `nickname` field — the colloquial name used in transcript body text, vs the formal name in speaker labels (e.g. `name: Rajiwath`, `nickname: Raj`). When checking for unknown stakeholders, `/sara-discuss` matches on **both** `name` and `nickname`.
- **D-08:** Phase 1 artifacts require amendment: `.sara/templates/stakeholder.md` and the stakeholder schema block in `wiki/CLAUDE.md` both need the `nickname` field added. Planner should include this as a task in Phase 2 execution.

### /sara-extract — Per-Artifact Approval Loop
- **D-09:** Approval is per-artifact. Each proposed artifact gets three options: **accept** (include in update plan), **reject** (drop), **discuss** (user provides correction or context inline → SARA revises and re-presents that artifact → loops back to accept/reject/discuss until resolved).
- **D-10:** The `/sara-extract` dedup check (PIPE-06) runs before presenting the artifact list — existing wiki pages are checked and update proposals are shown instead of create proposals where applicable.

### /sara-ingest — Registration and Status
- **D-11:** `/sara-ingest <type> <filename>` with a missing file: hard stop. Report the file wasn't found, list what IS in `/raw/input/`, make no changes to `pipeline-state.json`.
- **D-12:** `/sara-ingest` with no arguments displays pipeline status — all items, type, current stage, filename. Format: table.

### Error & Stage Guard
- **D-13:** Every pipeline skill checks the item's current stage at startup. If the item isn't in the expected stage, abort with a plain-English error naming the current stage and the correct next command. No override path.
- **D-14:** If `/sara-update N` partially fails mid-write, do not auto-rollback. Report exactly which files were written and which weren't. The user has full git history to recover from; they can `git reset` or re-run as appropriate.

### Claude's Discretion
- Exact wording of blocker-list presentation in `/sara-discuss` (structured list vs narrative)
- Whether `/sara-extract` shows artifacts grouped by type (all REQs, then all DECs, etc.) or in source-document order
- Exact table format for `/sara-ingest` status display

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Requirements
- `.planning/REQUIREMENTS.md` — Full v1 requirement list. Phase 2 covers: PIPE-01, PIPE-02, PIPE-03, PIPE-04, PIPE-05, PIPE-06, PIPE-07

### Project Context
- `.planning/PROJECT.md` — Vision, directory structure, command taxonomy, ingest pipeline overview, constraints

### Prior Phase Decisions
- `.planning/phases/01-foundation-schema/01-CONTEXT.md` — Locked decisions from Phase 1: pipeline-state.json structure (D-07, D-08), entity ID formats (D-06), AskUserQuestion interaction pattern (D-01), wiki/CLAUDE.md behavioral contract (D-12 to D-14), template format (D-09 to D-11)

### Phase 1 Artifacts to Amend
- `.sara/templates/stakeholder.md` — Add `nickname` field (D-07, D-08 above)
- `wiki/CLAUDE.md` — Add `nickname` to stakeholder schema block (D-07, D-08 above)

No external specs or ADRs — all requirements are captured in REQUIREMENTS.md and decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/skills/sara-init/SKILL.md` — The only existing skill. Establishes the SKILL.md pattern: YAML frontmatter with `allowed-tools`, `<objective>` block, `<process>` with numbered steps, plain-text prompts for user input (no AskUserQuestion in sara-init — Phase 2 skills may use AskUserQuestion per Phase 1 D-01 decision).
- `.sara/config.json` — Project config (project name, verticals, departments, schema_version). All Phase 2 skills will read this for vertical/department validation when creating stakeholder pages.
- `.sara/pipeline-state.json` — State store. Phase 2 skills read and write this for stage transitions, counter increments, discussion_notes, and extraction_plan.
- `wiki/CLAUDE.md` — Behavioral contract auto-loaded by Claude Code for all wiki-scoped skills. Phase 2 skills inherit dedup check, index/log update, counter increment, and cross-reference rules automatically.

### Established Patterns
- Skills are SKILL.md files in `.claude/skills/<skill-name>/`. One directory per skill.
- User interaction uses plain-text prompts (wait for next message) in sara-init. Phase 2 may use AskUserQuestion for structured choices (e.g. per-artifact accept/reject/discuss loop in `/sara-extract`).
- All wiki writes land in a single git commit (PIPE-05 requirement) — no incremental commits mid-update.

### Integration Points
- `/sara-add-stakeholder` must be invokeable from `/sara-discuss` mid-session — the skill pattern supports this (Claude reads the target SKILL.md and executes inline).
- `/sara-update N` is the only skill that commits wiki artifact changes. `/sara-add-stakeholder` commits only its own STK page (separate, earlier commit during discuss).
- `wiki/index.md` and `wiki/log.md` are updated by both `/sara-add-stakeholder` (for the STK page) and `/sara-update N` (for all other artifacts).

</code_context>

<specifics>
## Specific Ideas

- The nickname field solves a real transcript problem: speaker labels use formal names, body text uses nicknames. SARA must match both to avoid false "unknown stakeholder" flags.
- `/sara-discuss` should feel like a colleague who has read the document and come prepared with questions — not a generic assistant waiting to be told what to do.
- The per-artifact discuss loop in `/sara-extract` mirrors the `/sara-discuss` blocker model: the LLM takes a specific artifact, incorporates user correction, and re-presents until it's right.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within Phase 2 scope.

</deferred>

---

*Phase: 02-ingest-pipeline*
*Context gathered: 2026-04-27*
