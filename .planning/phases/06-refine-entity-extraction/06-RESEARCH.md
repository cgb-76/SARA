# Phase 6: refine-entity-extraction - Research

**Researched:** 2026-04-28
**Domain:** Claude Code agent files, skill orchestration, multi-agent dispatch via Task()
**Confidence:** HIGH

## Summary

Phase 6 refactors `sara-extract` from a monolithic LLM-driven skill into a multi-agent pipeline. The orchestrator (`sara-extract` SKILL.md) spawns four specialist agent files (one per entity type) in parallel via Task(), collects their outputs, passes the merged array to a sorter agent, and then runs the existing per-artifact approval loop on the sorter's cleaned output. Classification, dedup, and cross-reference reasoning move from `sara-discuss` into the sorter agent. `sara-discuss` is narrowed to source comprehension and unknown-stakeholder surfacing only.

The implementation has two distinct artifact classes: (1) five `.claude/agents/*.md` files — these are Claude Code sub-agent definitions consumed by Task() calls, and (2) two modified SKILL.md files (`sara-extract`, `sara-discuss`). The artifact schema and the per-artifact approval loop are explicitly frozen — no changes touch `sara-update`, pipeline-state.json structure, or wiki schemas.

The install.sh currently only distributes `.claude/skills/` content. Because the new agent files live in `.claude/agents/`, the install script will need updating to also copy those files — this is a dependency the planner must account for if Phase 4 installability is in scope.

**Primary recommendation:** Author the five agent files first, then rewrite the `sara-extract` Steps 2–3 to dispatch to them, then narrow `sara-discuss`. Validate the artifact schema passthrough end-to-end before touching the approval loop.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Five agent files in `.claude/agents/`: `sara-requirement-extractor.md`, `sara-decision-extractor.md`, `sara-action-extractor.md`, `sara-risk-extractor.md`, `sara-artifact-sorter.md`
- **D-02:** `sara-extract` SKILL.md is the orchestrator — it spawns all agents via Task() and sequences the flow. No additional orchestrator agent.
- **D-03:** Each specialist agent receives: raw source document content + `discussion_notes` string from `pipeline-state.json`. Nothing else. Agents start cold.
- **D-04:** Specialist agents do NOT receive grep summaries or the wiki index. Dedup and cross-ref is the sorter's responsibility.
- **D-05:** Each specialist returns `[{action, type, title, source_quote, raised_by, related, change_summary}]` matching the existing artifact schema. No new fields.
- **D-06:** `action` returned by specialist agents is always `"create"` with `id_to_assign: "{TYPE}-NNN"` placeholder — the sorter resolves update vs create against the wiki index and grep summaries.
- **D-07:** Sorter receives: merged specialist output array + grep-extract summaries (all `summary:` fields) + `wiki/index.md` content.
- **D-08:** Sorter produces: (1) cleaned, deduplicated artifact list, and (2) questions for the human covering type ambiguities, likely duplicates, and cross-reference opportunities.
- **D-09:** Human resolves sorter questions before the per-artifact approval loop. Sorter's cleaned list feeds into the existing Accept/Reject/Discuss loop unchanged.
- **D-10:** Existing per-artifact AskUserQuestion loop (Accept / Reject / Discuss) preserved as-is.
- **D-11:** `sara-discuss` narrowed to: (1) source comprehension — clarifying ambiguous passages and agreeing on extraction intent, and (2) surfacing unknown stakeholder names for STK creation via `sara-add-stakeholder`. Classification, dedup, and cross-reference reasoning removed from `sara-discuss`.

### Claude's Discretion

- Whether specialist agents run in parallel (all 4 Task() calls at once) or sequentially
- Exact prompt structure within each agent file
- How the sorter presents its questions (AskUserQuestion calls vs plain-text list)
- What the sorter does when a specialist returns zero artifacts (skip silently)
- Order in which sorter questions are presented when multiple ambiguities exist

### Deferred Ideas (OUT OF SCOPE)

- None — discussion stayed within phase scope
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Orchestrate extraction flow | sara-extract SKILL.md | — | Existing orchestrator; Steps 2–3 replaced, Steps 4–5 unchanged |
| Type-specific entity extraction | Specialist agent files (.claude/agents/) | — | One agent per type — isolation by design for future refinement |
| Dedup, create-vs-update, cross-ref | sara-artifact-sorter agent | — | Sorter owns all wiki-state reasoning; specialists stay stateless |
| Human question resolution (pre-loop) | sara-artifact-sorter agent | sara-extract (host) | Sorter generates questions; sara-extract presents them and collects answers |
| Per-artifact approval loop | sara-extract SKILL.md (Step 4) | — | Preserved verbatim — feeds on sorter's resolved, cleaned list |
| Write extraction_plan + advance stage | sara-extract SKILL.md (Step 5) | — | Unchanged |
| Source comprehension, STK surfacing | sara-discuss SKILL.md | — | Narrowed scope; classification/dedup language removed |
| Wiki writes, atomic commit | sara-update SKILL.md | — | Unchanged; reads extraction_plan as before |

## Standard Stack

### Core

This phase is pure markdown authoring — no new libraries or dependencies.

| Artifact | Format | Purpose |
|----------|--------|---------|
| `.claude/agents/*.md` | Markdown with YAML frontmatter | Claude Code sub-agent definition — loaded by Task() |
| `.claude/skills/sara-extract/SKILL.md` | Markdown with YAML frontmatter | Slash-command skill definition — orchestrator |
| `.claude/skills/sara-discuss/SKILL.md` | Markdown with YAML frontmatter | Slash-command skill definition — narrowed scope |

### Agent File Frontmatter (`.claude/agents/`)

```yaml
---
name: sara-requirement-extractor
description: "Extract requirement artifacts from a source document and discussion notes"
tools: Read, Bash
color: cyan
---
```

Key observations [VERIFIED: reading /home/george/.claude/agents/gsd-codebase-mapper.md]:
- Field name is `tools:` (comma-separated string), NOT `allowed-tools:` (which is the SKILL.md format)
- `color:` is optional metadata for UI display
- No `version:` field — that is a SKILL.md convention, not an agent file convention
- `description:` is what Claude Code shows when selecting agents; keep it task-specific and action-oriented

### Skill File Frontmatter (`.claude/skills/*/SKILL.md`)

```yaml
---
name: sara-extract
description: "Present planned wiki artifacts for per-artifact approval before any wiki writes"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---
```

Key observation [VERIFIED: reading sara-extract SKILL.md]: SKILL.md files use `allowed-tools:` as a YAML list. This is a distinct format from agent files.

### Grep-Extract Pattern (Sorter uses this — from Phase 5 D-08)

```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
```

[VERIFIED: confirmed in both sara-extract SKILL.md Step 3 and sara-discuss SKILL.md Step 5]

## Architecture Patterns

### System Architecture Diagram

```
/sara-extract N invoked
        │
        ▼
Step 1 — Stage guard (extracting), item lookup
        │
        ▼
Step 2 — Load source doc, discussion_notes, wiki/index.md
        │
        ├─── Task(sara-requirement-extractor, prompt=source+notes) ─┐
        ├─── Task(sara-decision-extractor, prompt=source+notes)    ─┤  parallel
        ├─── Task(sara-action-extractor, prompt=source+notes)      ─┤  (all 4)
        └─── Task(sara-risk-extractor, prompt=source+notes)        ─┘
                                                                    │
                                        merge all JSON arrays       │
                                                                    ▼
        Task(sara-artifact-sorter, prompt=merged_array+summaries+index)
                │                                          │
                ▼                                          ▼
        cleaned artifact list              questions for human
                │                          (ambiguities, dupes,
                │                           cross-refs)
                │                                │
                ▼                                ▼
        Step 4 — Per-artifact loop    Human resolves sorter Qs
        (Accept/Reject/Discuss)       BEFORE loop starts
                │
                ▼
        Step 5 — Write extraction_plan, advance stage to "approved"
```

### Agent File Structure Pattern

Each specialist agent file follows the pattern established by GSD agents [VERIFIED: reading /home/george/.claude/agents/gsd-codebase-mapper.md]:

```markdown
---
name: sara-{type}-extractor
description: "{action-oriented description}"
tools: Read, Bash
color: cyan
---

<role>
You are sara-{type}-extractor. You extract {type} artifacts from a source document.
Spawned by `/sara-extract` via Task(). Return JSON array only — no prose.
</role>

<process>
[numbered steps]
</process>

<output_format>
[JSON schema example]
</output_format>

<notes>
[pitfalls and constraints]
</notes>
```

### Recommended Project Structure

```
.claude/
├── agents/                          # New directory (does not exist yet)
│   ├── sara-requirement-extractor.md
│   ├── sara-decision-extractor.md
│   ├── sara-action-extractor.md
│   ├── sara-risk-extractor.md
│   └── sara-artifact-sorter.md
└── skills/
    ├── sara-extract/
    │   └── SKILL.md                 # Modified: Steps 2–3 replaced
    └── sara-discuss/
        └── SKILL.md                 # Modified: Steps 3–5 narrowed
```

### Pattern 1: Specialist Agent Returns JSON Array

Specialist agents return a raw JSON array — no prose, no markdown fences. The orchestrator (sara-extract) collects these via Task() return values and merges them before passing to the sorter.

```json
[
  {
    "action": "create",
    "type": "requirement",
    "id_to_assign": "REQ-NNN",
    "title": "API rate limiting per tenant",
    "source_quote": "Each tenant will be limited to 1000 API calls per hour",
    "raised_by": "STK-002",
    "related": [],
    "change_summary": ""
  }
]
```

Key constraint [VERIFIED: D-05, D-06 from CONTEXT.md]: `action` is always `"create"`, `id_to_assign` is always `"{TYPE}-NNN"` placeholder. Specialist agents never produce `"update"` actions — that resolution belongs to the sorter.

### Pattern 2: Sorter Produces Dual Output

The sorter agent produces two distinct outputs in a single response:

1. A `cleaned_artifacts` JSON array — the deduplicated, type-resolved list with `action` now correctly set to `"create"` or `"update"` and real `existing_id` populated where appropriate
2. A `questions` block — human-readable questions about ambiguities, likely duplicates, and cross-reference opportunities

The orchestrator presents questions first, collects human answers, then feeds the cleaned list (with resolutions applied) into the approval loop.

### Pattern 3: Explicit Context Passing to Cold Agents

Agents start cold — they have no implicit access to discuss phase context, pipeline-state.json, or the wiki. All required context must be passed explicitly in the Task() prompt string. [VERIFIED: D-03 from CONTEXT.md]

Example prompt structure for specialist agents:
```
You are sara-requirement-extractor. Extract requirement artifacts only.

<source_document>
{full content of source file}
</source_document>

<discussion_notes>
{discussion_notes string from pipeline-state.json}
</discussion_notes>

Return a JSON array of requirement artifacts. Each artifact must include a source_quote.
```

### Anti-Patterns to Avoid

- **Passing wiki index/grep summaries to specialist agents:** Violates D-04. Specialist agents are intentionally isolated from wiki state — they extract from source only. Dedup is the sorter's job.
- **Specialist agents producing `"update"` actions:** Violates D-06. The sorter resolves create-vs-update. Specialist agents always return `action: "create"`.
- **Modifying Step 4 (approval loop):** Violates D-10. The per-artifact loop is preserved verbatim. The only change is its input comes from the sorter instead of an inline LLM step.
- **Adding new fields to the artifact schema:** Violates D-05. The schema is frozen to maintain `sara-update` compatibility.
- **Using `allowed-tools:` in agent files:** Agent files use `tools:` (comma-separated). `allowed-tools:` is SKILL.md format only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Agent file format | Custom prompt injection system | `.claude/agents/*.md` standard format | Claude Code natively reads these; custom formats break Task() dispatch |
| Artifact schema validation | JSON schema validator | Inline prompt constraint + note in agent file | No runtime validation infrastructure; schema is stable and small |
| Parallel Task dispatch | Sequential fallback loop | Parallel Task() calls (Claude's discretion per CONTEXT.md) | Parallel is the natural fit — serialize only if context window is a concern |

**Key insight:** The project has no runtime code — it is entirely markdown skill/agent files. All "don't hand-roll" constraints are about following Claude Code conventions rather than choosing libraries.

## Common Pitfalls

### Pitfall 1: Discussion Notes Not Passed to Specialist Agents
**What goes wrong:** Specialist agent extracts artifacts without resolution context — assigns wrong stakeholder IDs, misses entity type decisions made in discuss phase, produces lower quality output.
**Why it happens:** Agents start cold; `discussion_notes` lives in `pipeline-state.json` and is loaded by sara-extract but not automatically available to spawned agents.
**How to avoid:** The Task() prompt for each specialist MUST include the `discussion_notes` string, passed explicitly. This is documented as a known pitfall in CONTEXT.md (Specifics section).
**Warning signs:** Agent output shows `raised_by: ""` or placeholder STK-IDs that don't match any known stakeholder.

### Pitfall 2: Sorter Receives Inconsistent Array Structure
**What goes wrong:** Sorter cannot merge specialist outputs cleanly — JSON parse errors or schema mismatches between agent outputs.
**Why it happens:** Each of four specialists may format slightly differently if prompt constraints are not precise; one returning an object instead of array, another omitting `id_to_assign`.
**How to avoid:** Each specialist agent file must include an explicit output format example with all required fields. The `action: "create"` and `id_to_assign: "{TYPE}-NNN"` constraints must be in the agent's `<output_format>` section, not just in prose.
**Warning signs:** Sorter step fails or produces unexpected results on the first run.

### Pitfall 3: Wrong Frontmatter Format for Agent Files
**What goes wrong:** Agent files are ignored by Claude Code or fail to load correctly.
**Why it happens:** Confusing SKILL.md format (`allowed-tools:` YAML list) with agent file format (`tools:` comma-separated string).
**How to avoid:** Use `tools: Read, Bash` (comma-separated on one line) in `.claude/agents/*.md` files. Do not use the YAML list form.
**Warning signs:** Claude Code does not offer the agent in Task() dispatch; file is not recognized.

### Pitfall 4: Sorter Questions Presented After Approval Loop Starts
**What goes wrong:** Human cannot resolve ambiguities before seeing each artifact — defeats the purpose of the pre-loop sorter phase.
**Why it happens:** Implementation puts sorter question presentation inside the artifact loop rather than before it.
**How to avoid:** Per D-09, all sorter questions must be resolved before the first artifact in the approval loop is presented. The flow is: (1) run sorter, (2) present all questions, (3) collect all resolutions, (4) start loop.
**Warning signs:** User sees `Artifact 1: Accept/Reject/Discuss` before being asked any sorter questions.

### Pitfall 5: sara-discuss Still Performing Classification/Dedup
**What goes wrong:** Entity type ambiguities are resolved twice (once in discuss, once by the sorter), causing inconsistency or redundant work.
**Why it happens:** SKILL.md edit removes the wrong sections, or retains Priority 2 (ambiguous entity type) language.
**How to avoid:** The narrowed sara-discuss removes: Priority 2 (entity type ambiguity), Priority 3 (context gaps treated as classification decisions), Priority 4 (cross-link candidates — now sorter's job). Retain: Priority 1 (unknown stakeholders), source comprehension.
**Warning signs:** sara-discuss produces discussion_notes that include entity type decisions — these should now come from the sorter.

### Pitfall 6: install.sh Does Not Copy Agent Files
**What goes wrong:** A user running install.sh gets the updated sara-extract and sara-discuss SKILL.md files but not the five agent files — the skill runs but Task() dispatch fails because the agent files are missing.
**Why it happens:** install.sh currently only handles `.claude/skills/*/SKILL.md` paths. The new `.claude/agents/` directory is not covered.
**How to avoid:** Update install.sh to also copy `.claude/agents/sara-*.md` files to the target. This is an integration dependency the planner must include.
**Warning signs:** `/sara-extract N` fails when trying to dispatch Task() with `sara-requirement-extractor`.

## Code Examples

### Current sara-extract Step 3 (to be replaced)

```markdown
**Step 3 — Generate artifact list with dedup check**

Load artifact summaries using the grep-extract pattern...
For each extractable topic in the source:
  Search the grep-extract summaries and wiki/index.md...
```

Source: `/home/george/Projects/sara/.claude/skills/sara-extract/SKILL.md` Step 3 [VERIFIED]

### New sara-extract Steps 2–3 (replacement pattern)

```markdown
**Step 2 — Load source, discussion notes, and dedup context**

Read {item.source_path} using the Read tool.
{discussion_notes} = items["{N}"].discussion_notes (from Step 1 read).
Read wiki/index.md using the Read tool.

**Step 3 — Dispatch specialist agents and sorter**

Spawn four specialist agents via Task() with the source document and discussion_notes:
- Task(sara-requirement-extractor, prompt=...)  → {req_artifacts}
- Task(sara-decision-extractor, prompt=...)     → {dec_artifacts}
- Task(sara-action-extractor, prompt=...)       → {act_artifacts}
- Task(sara-risk-extractor, prompt=...)         → {risk_artifacts}

Merge all four arrays: {merged} = req_artifacts + dec_artifacts + act_artifacts + risk_artifacts

Load grep summaries:
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null

Spawn sorter: Task(sara-artifact-sorter, prompt=merged+summaries+index)
→ {cleaned_artifacts}, {sorter_questions}

Present {sorter_questions} to the human. Collect resolutions.
Apply human resolutions to {cleaned_artifacts}.

Proceed to Step 4 with {cleaned_artifacts} as the artifact list.
```

### Artifact Schema (canonical — unchanged)

```json
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "...",
  "source_quote": "exact verbatim text",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": ""
}
```

Source: `/home/george/Projects/sara/.claude/skills/sara-extract/SKILL.md` Step 3 [VERIFIED]

### Current sara-discuss Priority 2–4 (to be removed)

The following sections are removed from sara-discuss (D-11):
- Priority 2: Ambiguous entity type
- Priority 3: Missing context gaps (when treated as classification)
- Priority 4: Cross-link candidates

What remains: Priority 1 (unknown stakeholders) + source comprehension blocker scanning.

Source: `/home/george/Projects/sara/.claude/skills/sara-discuss/SKILL.md` Steps 3–5 [VERIFIED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Monolithic LLM step generates all artifacts | Specialist agents per entity type | Phase 6 | Isolated refinement per type; cleaner context; better extraction quality |
| sara-discuss resolves classification + dedup | Sorter agent resolves post-extraction | Phase 6 | discuss focuses on comprehension; extract focuses on quality |
| Inline dedup check in sara-extract Step 3 | Sorter owns create-vs-update resolution | Phase 6 | Specialist agents are stateless (no wiki access) |

## Runtime State Inventory

> Phase 6 is a refactor of SKILL.md files and creation of new agent files — not a rename or migration. No runtime state is affected.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — pipeline-state.json schema unchanged | None |
| Live service config | None — no external services | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None — markdown files only | None |

## Open Questions (RESOLVED)

1. **Sorter question presentation mechanism** — RESOLVED: Plan 06-03 (sorter agent file) documents the zero-question case; orchestrator silently skips to Step 4 per agent instructions.
   - What we know: D-08 says sorter produces questions; D-09 says human resolves before loop. Claude's discretion covers whether AskUserQuestion or plain-text is used.
   - What's unclear: If there are zero sorter questions (clean source, no ambiguities), what does the sorter emit? Presumably it emits only the cleaned list.
   - Recommendation: Agent file should explicitly document the zero-question case — emit an empty questions array or a "No ambiguities found" signal. The orchestrator silently skips to Step 4.

2. **install.sh agent file distribution** — RESOLVED: Plan 06-04 Task 2 updates install.sh to copy .claude/agents/sara-*.md files to the target directory.
   - What we know: install.sh only copies `.claude/skills/*/SKILL.md` files. Five new agent files live in `.claude/agents/`.
   - What's unclear: Whether this phase should update install.sh, or whether that's out of scope.
   - Recommendation: Include install.sh update as a plan task. A user who installs SARA after Phase 6 must get the agent files; otherwise `/sara-extract` breaks silently.

3. **Parallel vs sequential specialist dispatch** — RESOLVED: Plan 06-02 documents parallel as the default; sequential fallback noted in orchestrator Step 3 per Claude's discretion (D-02).
   - What we know: D-02 says Claude's discretion. Parallel is natural.
   - What's unclear: Context window constraints when source document is large.
   - Recommendation: Default to parallel. Document in the orchestrator's Step 3 that sequential fallback is available if context is a concern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git | Skill commits | Yes | 2.43.0 | — |
| bash | Grep-extract pattern | Yes | (system) | — |
| Claude Code agent dispatch (Task()) | Core orchestration | Yes (assumed) | — | — |

## Validation Architecture

nyquist_validation is enabled in `.planning/config.json`. However, this project has no test framework — it is a pure markdown skill project with no test directory, no package.json, no pytest.ini, no jest config. [VERIFIED: filesystem check]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — project is markdown files only |
| Config file | None |
| Quick run command | Manual: run `/sara-extract` on a test fixture |
| Full suite command | Manual: end-to-end pipeline run with test fixture |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXT-01 | Specialist agents each return JSON arrays matching artifact schema | manual | Run `/sara-extract` on fixture, inspect pipeline-state.json extraction_plan | N/A — no test infra |
| EXT-02 | Sorter receives merged array + grep summaries + index | manual | Read sorter prompt in Task() call during extraction | N/A |
| EXT-03 | Sorter questions presented before approval loop | manual | Observe interaction sequence during `/sara-extract` | N/A |
| EXT-04 | Per-artifact approval loop unchanged | manual | Complete an extraction cycle and accept/reject artifacts | N/A |
| DISC-01 | sara-discuss no longer surfaces entity type ambiguities | manual | Run `/sara-discuss` and verify Priority 2 absent from blocker list | N/A |

### Sampling Rate

- **Per task commit:** Visual inspection of affected SKILL.md/agent file for correctness
- **Per wave merge:** Manual end-to-end `/sara-extract` run on a fixture document
- **Phase gate:** Full pipeline run (ingest → discuss → extract → update) with test fixture before `/gsd-verify-work`

### Wave 0 Gaps

No test infrastructure exists and none is needed — this is a markdown authoring project. The verification approach is manual end-to-end pipeline execution. The final plan should include an end-to-end verification task (as prior phases have: 02-07, 03-03, etc.).

## Security Domain

No security domain applies. This phase creates markdown agent definition files and modifies markdown skill files. There are no network calls, no user data handling, no authentication, no input parsing beyond what Claude Code natively does.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.claude/agents/*.md` files use `tools:` (comma-separated) not `allowed-tools:` (YAML list) | Standard Stack | Agent files not recognized by Claude Code; Task() dispatch fails |
| A2 | Task() dispatch in Claude Code is invoked by the orchestrator's natural language description (e.g. "spawn sara-requirement-extractor") not explicit API calls | Architecture Patterns | Planner may need to specify exact Task() invocation syntax |
| A3 | install.sh must be updated to copy `.claude/agents/` files | Open Questions | Post-install SARA breaks on first `/sara-extract` after Phase 6 |

**A1 note:** The `tools:` vs `allowed-tools:` distinction was VERIFIED by reading an existing `.claude/agents/` file. HIGH confidence.

**A2 note:** Task() invocation mechanism is implicit in how Claude Code works with agent files — the orchestrator skill references agent names and Claude Code handles dispatch. ASSUMED based on how GSD agents work.

## Sources

### Primary (HIGH confidence)
- `/home/george/Projects/sara/.claude/skills/sara-extract/SKILL.md` — Current Steps 2–5 being modified; artifact schema; approval loop
- `/home/george/Projects/sara/.claude/skills/sara-discuss/SKILL.md` — Current steps being narrowed; Priority 1–4 blocker structure
- `/home/george/Projects/sara/.claude/skills/sara-update/SKILL.md` — Downstream consumer; artifact schema compatibility anchor
- `/home/george/Projects/sara/.planning/phases/06-refine-entity-extraction/06-CONTEXT.md` — All locked decisions D-01 through D-11
- `/home/george/.claude/agents/gsd-codebase-mapper.md` — Agent file frontmatter format reference (tools:, color:)

### Secondary (MEDIUM confidence)
- `/home/george/Projects/sara/install.sh` — Current skills-only distribution; agent file gap identified
- `/home/george/Projects/sara/.planning/phases/05-artifact-summaries/05-CONTEXT.md` — D-08 grep-extract pattern (sorter uses this)

## Metadata

**Confidence breakdown:**
- Agent file format: HIGH — verified against existing .claude/agents/ files
- Artifact schema: HIGH — verified against sara-extract and sara-update SKILL.md
- Architecture pattern: HIGH — directly derived from locked decisions D-01 through D-11
- Pitfalls: HIGH — derived from explicit CONTEXT.md warnings and code inspection
- Install.sh gap: HIGH — verified by reading install.sh directly

**Research date:** 2026-04-28
**Valid until:** 2026-05-28 (stable — markdown-only project, no dependency churn)
