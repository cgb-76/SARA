# Phase 10: refine-actions - Research

**Researched:** 2026-04-29
**Domain:** SARA skill files — sara-extract action pass, sara-update action write branch, sara-init action template and CLAUDE.md schema block
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Extraction signal is any passage implying work needs to happen — broadest possible net. No explicit exclusion list; existing sorter handles cross-type deduplication.

**D-02:** Due dates extracted as raw string when mentioned (e.g. "by Friday", "EOW"). No normalisation to ISO 8601 at extraction time.

**D-03:** Actions without a resolvable owner are not blocked at extraction time. Flagged during Step 4 approval loop with warning: "Owner not resolved — assign manually after /sara-update, or run /sara-add-stakeholder first."

**D-04:** `act_type` field: `deliverable` (concrete output or artefact to produce) or `follow-up` (check-in, response, or update required from someone).

**D-05:** `owner` captured as distinct field from `raised_by`. `raised_by` = who surfaced the action; `owner` = who is assigned to do the work. Both STK-NNN if resolvable, raw name string if not yet registered.

**D-06:** sara-update writes `owner` from `artifact.owner` (not `artifact.raised_by`). STK ID written as-is; raw name written as-is; empty writes `owner: ""`.

**D-07:** `schema_version: '2.0'` — single-quoted, consistent with requirement and decision convention.

**D-08:** New frontmatter field `type` (maps from `artifact.act_type`).

**D-09:** `owner` frontmatter field written from `artifact.owner`.

**D-10:** New frontmatter field `due-date` written from `artifact.due_date` (raw string or empty).

**D-11:** Six-section body structure: Source Quote, Description, Context, Owner, Due Date, Cross Links.

**D-12:** sara-update synthesises Description and Context from source doc + discussion notes. Owner and Due Date sections written from extracted artifact fields, not synthesised.

**D-13:** Approval loop prepends warning when `artifact.owner` is empty or unresolved raw string:
```
⚠ Owner not resolved — assign manually after /sara-update, or run /sara-add-stakeholder first.
```

Full v2.0 frontmatter shape:
```yaml
---
id: ACT-NNN
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""   # ACT: owner, due-date, type, status
type: deliverable  # deliverable | follow-up
owner: ""     # STK-NNN or raw name string
due-date: ""  # raw string from source (e.g. "by Friday") or ISO date once resolved
source: []    # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---
```

### Claude's Discretion

- Exact wording of the updated extraction prompt — must include a clear positive definition and examples of action items (with and without owners, with and without due dates)
- Whether to add negative examples to the extraction prompt (e.g., background context that implies work but is not a task, risk mitigations that are already captured by the risks pass)
- Summary generation wording for `deliverable` vs `follow-up` actions

### Deferred Ideas (OUT OF SCOPE)

- Refine risk artifact (extraction signal, schema) — subsequent phase
- sara-lint backfill: existing ACT pages predate v2.0 schema
</user_constraints>

---

## Summary

Phase 10 is the third iteration of the two-track refinement pattern established in Phase 8 (requirements) and Phase 9 (decisions). It applies the same discipline to the action artifact: rewrite the extraction pass with a clear signal definition, add three new extracted fields (`act_type`, `owner`, `due_date`), bump the wiki page schema to v2.0, and replace the flat Description + Notes body with a six-section structured body.

All implementation decisions are locked in CONTEXT.md. The phase touches exactly three skill files: `sara-extract` (action pass only), `sara-update` (action write branch only), and `sara-init` (action template + CLAUDE.md action schema block). The sorter agent is explicitly out of scope and must not be modified.

The critical new behaviour in this phase — not present in Phases 8 or 9 — is the `owner` field as a distinct extracted field separate from `raised_by`, and the approval loop warning for unresolved owners. These require coordinated changes across sara-extract (add `owner` to the artifact schema), sara-update (write `owner` from `artifact.owner`, inject warning before artifact presentation), and sara-init (update template and CLAUDE.md schema block).

**Primary recommendation:** Implement as three plans mirroring the Phase 8/9 task structure — (1) sara-extract action pass rewrite, (2) sara-update action write branch update plus approval loop warning, (3) sara-init action template and CLAUDE.md schema block update.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Action extraction signal definition | sara-extract (Step 3 action pass) | — | Extraction is entirely inline in sara-extract; sorter receives the output but does not define the signal |
| act_type / owner / due_date field production | sara-extract (Step 3 action pass) | sara-artifact-sorter (pass-through) | Fields produced inline; sorter passes them through unchanged per Phase 8/9 precedent |
| Owner-not-resolved warning | sara-extract (Step 4 approval loop) | — | Warning is injected before AskUserQuestion in the approval loop, not in sara-update |
| Action wiki page write (v2.0 frontmatter + body) | sara-update (action write branch) | — | sara-update owns all wiki file writes |
| Action template and schema reference | sara-init | — | sara-init writes the canonical template and CLAUDE.md schema block at project init time |
| Sorter pass-through of new fields | sara-artifact-sorter | — | No code change needed; follows established pattern |

---

## Standard Stack

This phase has no external library dependencies. The implementation is pure skill file text editing — markdown and YAML within `.claude/skills/` files.

### Files Modified

| File | Change Type | Scope |
|------|-------------|-------|
| `.claude/skills/sara-extract/SKILL.md` | Targeted rewrite | Action pass only (Step 3, actions section) + Step 4 approval loop owner warning |
| `.claude/skills/sara-update/SKILL.md` | Targeted rewrite | Action write branch only (create + update sub-branches) |
| `.claude/skills/sara-init/SKILL.md` | Targeted rewrite | CLAUDE.md action schema block (Step 9) + action template (Step 12) |
| `.claude/agents/sara-artifact-sorter.md` | Read-only | Verify new fields do not break input contract; no modification |

---

## Architecture Patterns

### Phase 8/9/10 Two-Track Pattern

Every refinement phase applies the same two-track discipline:

```
Track 1 — Extraction (sara-extract):
  Source document
      |
      v
  [Action pass] ——> artifact JSON:
                     { act_type, owner, due_date, source_quote, raised_by, title }
      |
      v
  [Sorter] ——> passes new fields through unchanged
      |
      v
  [Step 4 approval loop] ——> owner warning if unresolved

Track 2 — Writing (sara-update):
  artifact JSON
      |
      v
  [Action write branch] ——> v2.0 wiki page:
                              frontmatter: type, owner, due-date, schema_version: '2.0'
                              body: 6 sections
```

The sorter is the firewall between tracks: it passes type-specific fields through without interpreting them. This was validated in Phase 8 (`req_type`, `priority`) and Phase 9 (`dec_type`, `status`, `chosen_option`, `alternatives`).

### Recommended Project Structure (unchanged)

```
.claude/skills/
├── sara-extract/SKILL.md    # action pass rewritten
├── sara-update/SKILL.md     # action write branch rewritten
├── sara-init/SKILL.md       # action template + CLAUDE.md schema block updated
.claude/agents/
└── sara-artifact-sorter.md  # read-only — no changes
```

### Pattern: Action Pass Replacement (sara-extract Step 3)

The existing action pass (lines 139–146 of sara-extract/SKILL.md) is a single-paragraph prompt producing a minimal artifact. The replacement must:

1. Open with a positive definitional statement (D-01 signal)
2. Classify `act_type` inline using the deliverable/follow-up taxonomy (D-04)
3. Extract `owner` as a distinct field separate from `raised_by` (D-05)
4. Extract `due_date` as a raw string (D-02)
5. Keep all existing mandatory fields: `source_quote`, `title` (imperative phrase), `raised_by`, `action`, `type`, `id_to_assign`, `related`, `change_summary`

**Existing action pass (to be replaced):**
```
Extract every passage that describes an action item — a concrete task or follow-up with an
implied or explicit owner (something that must be done, not a general statement of intent). For each action found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY)
- Write a short (≤10 words) imperative-phrase `title` (e.g. "Send updated proposal to client")
- Set `raised_by` to the STK-NNN ID of the person who will own the action if identifiable; otherwise `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"action"`, `id_to_assign` = `"ACT-NNN"`, `related` = `[]`, `change_summary` = `""`
```

**New artifact schema output by the pass:**
```json
{
  "action": "create",
  "type": "action",
  "id_to_assign": "ACT-NNN",
  "title": "short imperative-phrase title",
  "source_quote": "exact verbatim passage",
  "raised_by": "STK-NNN or placeholder",
  "owner": "STK-NNN or raw name string or ''",
  "act_type": "deliverable or follow-up",
  "due_date": "raw string or ''",
  "related": [],
  "change_summary": ""
}
```

### Pattern: Approval Loop Owner Warning (sara-extract Step 4)

The warning is injected as plain text output immediately before the AskUserQuestion call, only when `artifact.owner` is empty or a raw (unresolved) name string (i.e., not a valid STK-NNN ID).

Detection logic: `artifact.owner` is considered "unresolved" if it is empty (`""`) OR if it does not match the pattern `STK-\d{3}` (a raw name like "Alice" or "alice" was captured).

**Insertion point in Step 4:** Before the `--- Artifact {N} ---` block when `artifact.type == "action"` and owner is unresolved.

### Pattern: sara-update Action Write Branch

The current action write branch (sara-update SKILL.md lines ~262–281) produces:
```
## Description
> "{source_quote}" — [[raised_by|name]]
{synthesised summary}

## Notes
{synthesised blockers}

## Cross Links
```

The v2.0 replacement produces:
```
## Source Quote
> "[exact verbatim passage]" — [[STK-NNN|Stakeholder Name]]

## Description
[2–4 sentences: what needs to be done, grounded in source quote and discussion notes]

## Context
[why this action was raised — triggering event, dependency, or decision it relates to]

## Owner
[who is responsible — from artifact.owner. If STK-NNN, resolved name. If raw string, as-is. If empty: "Not assigned — set manually."]

## Due Date
[raw due date string from artifact.due_date, or "Not specified — set manually." if empty]

## Cross Links
[one wiki link per entry in artifact.related]
```

**Frontmatter mapping (create branch):**

| Wiki frontmatter field | Source | Notes |
|------------------------|--------|-------|
| `id` | counter | ACT-NNN |
| `title` | `artifact.title` | |
| `status` | hardcoded | `"open"` |
| `summary` | generated | owner, due-date, type, status (updated content rule) |
| `type` | `artifact.act_type` | `deliverable` or `follow-up` — NEW |
| `owner` | `artifact.owner` | STK-NNN or raw name or `""` — CHANGED from `artifact.raised_by` |
| `due-date` | `artifact.due_date` | raw string or `""` — NEW |
| `source` | `[{item.id}]` | |
| `schema_version` | hardcoded | `'2.0'` (single-quoted) — CHANGED from `"1.0"` |
| `tags` | default | `[]` |
| `related` | `artifact.related` | |

**Critical change from current code:** The current sara-update sets `owner = artifact.raised_by` for action artifacts (line ~106). The v2.0 branch sets `owner = artifact.owner`. This is a non-trivial mapping change — the planner must include this explicitly in the task.

**Update branch:** The update branch must also apply the same v2.0 field upgrades: add `type`, change `owner` source, add `due-date`, update `schema_version` to `'2.0'`, rewrite body to six-section format. This mirrors the requirement and decision update branch patterns from Phases 8 and 9.

### Pattern: sara-init Action Template and CLAUDE.md Schema Block

**CLAUDE.md action schema block (Step 9, current):**
```yaml
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""  # ACT: owner, due-date, status (open/in-progress/done/cancelled)
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
schema_version: "1.0"
tags: []
related: []
```
Body: `## Description`, `## Notes`

**Replacement (v2.0):** Must match D-07 through D-11 exactly, including the `summary` comment update to include `type`.

**`.sara/templates/action.md` (Step 12, current):** Same outdated schema. Replacement must include the v2.0 frontmatter and the six-section body structure with instructional comments (matching the style of the requirement template — see sara-init Step 12 for comparison).

### Anti-Patterns to Avoid

- **Modifying the sorter:** The sorter agent must not be changed. New fields flow through unchanged — this is proven from Phases 8 and 9. Do not add action-specific pass-through rules.
- **Writing `owner` from `raised_by`:** The current sara-update code maps `owner = artifact.raised_by` for action artifacts. The v2.0 update must explicitly change this to `artifact.owner`. Forgetting this would silently write the wrong value.
- **Double-quoting schema_version:** Requirements and decisions use single-quoted `'2.0'`. The current action schema uses double-quoted `"1.0"`. The v2.0 action schema must use single-quoted `'2.0'` to match the established convention. Do not use `"2.0"`.
- **Putting the owner warning inside the Discuss loop:** The warning is presented once, before the AskUserQuestion call, not inside the Discuss cycle. Inserting it into the retry loop would produce repeated warnings.
- **Changing other extraction passes:** Only the action pass in Step 3 is rewritten. Requirements, decisions, and risks passes are untouched.
- **Synthesising Owner/Due Date sections:** D-12 is explicit — Description and Context are synthesised; Owner and Due Date are written from extracted fields, not synthesised prose.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| STK ID resolution for owner warning | Custom validator | Pattern already in Step 4 approval loop from Phase 8/9 | Consistent with existing artifact handling |
| Body section synthesis | Extraction-time synthesis | sara-update synthesis from full `{source_doc}` in context | Established pattern — extraction is for signal detection, sara-update is for synthesis |
| Sorter pass-through of new fields | Sorter modification | Trust sorter's existing field pass-through | Phase 8/9 validated this works without sorter changes |

---

## Common Pitfalls

### Pitfall 1: owner vs raised_by mapping in sara-update
**What goes wrong:** The current sara-update code (line ~106) maps `owner = artifact.raised_by` for action artifacts. If the implementer does not explicitly change this to `artifact.owner`, the wrong person is written to the wiki page, and there is no error — it silently passes a wrong value.
**Why it happens:** The old pattern used `raised_by` as a proxy for owner. The new artifact schema has an explicit `owner` field. Two lines in sara-update reference action artifact ownership and both must be updated.
**How to avoid:** Task must name `artifact.owner` explicitly as the source, and must reference the current code location (create branch ~line 106, update branch equivalent).
**Warning signs:** After execution, new ACT pages show `owner` matching the person who surfaced the item, not the person assigned to do it.

### Pitfall 2: schema_version quoting inconsistency
**What goes wrong:** Current action template uses `"1.0"` (double-quoted). If implementer writes `"2.0"` instead of `'2.0'`, it looks correct but breaks the YAML float-parse safety convention established in Phase 8.
**Why it happens:** The distinction between single and double quoting in YAML is subtle and easy to overlook when copying existing patterns.
**How to avoid:** Tasks must explicitly state: `schema_version: '2.0'` — single quotes, matching requirement and decision convention.
**Warning signs:** The written value is `schema_version: "2.0"` or `schema_version: 2.0` in any output file.

### Pitfall 3: Owner warning placement
**What goes wrong:** The owner-not-resolved warning (D-13) is added inside the Discuss loop rather than before the initial AskUserQuestion, causing it to repeat on every Discuss cycle.
**Why it happens:** The Step 4 loop has multiple presentation points; the warning is easy to insert at the wrong level.
**How to avoid:** Warning is output once, as a plain-text line immediately before the `--- Artifact {N} ---` block, conditional on `artifact.type == "action"` and owner being unresolved. It does not repeat.

### Pitfall 4: Incomplete update branch upgrade
**What goes wrong:** The create branch is updated but the update branch (`artifact.action == "update"`) is not updated to add `type`, `due-date`, and the `owner` source change.
**Why it happens:** The update branch is longer and less obvious; implementers may update the create branch and miss the update branch.
**How to avoid:** Explicitly include update branch changes in the sara-update task. Reference Phase 8 precedent (requirement update branch also upgraded to v2.0 in that phase).

### Pitfall 5: Summary comment not updated in CLAUDE.md and template
**What goes wrong:** The `summary` comment in the action schema block still reads `# ACT: owner, due-date, status` after Phase 10, without the new `type` field.
**Why it happens:** Small comment updates are easy to miss.
**How to avoid:** Task for sara-init explicitly updates summary comment to `# ACT: owner, due-date, type, status` (matching D-10 context).

### Pitfall 6: Sorter output format not updated for new action fields
**What goes wrong:** The sorter's output_format example JSON does not include `act_type`, `owner`, or `due_date` in the action artifact example, leading to ambiguity about whether these fields should be preserved.
**Why it happens:** The sorter's output format section shows example artifacts but may not include all type-specific fields.
**How to avoid:** Check the sorter's output_format after the action pass is rewritten. If action artifacts appear in the sorter's example JSON and are missing the new fields, the sorter's pass-through rules should be checked — though the existing pass-through rule ("preserve fields as received") should cover it without code change.

---

## Code Examples

### Current action pass (sara-extract Step 3) — to be replaced

[VERIFIED: read from `.claude/skills/sara-extract/SKILL.md` lines 139–146]

```
**Actions pass**

Extract every passage that describes an action item — a concrete task or follow-up with an
implied or explicit owner (something that must be done, not a general statement of intent). For each action found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY)
- Write a short (≤10 words) imperative-phrase `title` (e.g. "Send updated proposal to client")
- Set `raised_by` to the STK-NNN ID of the person who will own the action if identifiable; otherwise `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"action"`, `id_to_assign` = `"ACT-NNN"`, `related` = `[]`, `change_summary` = `""`

Collect results as `{act_artifacts}` (JSON array; empty array if none found).
```

### Current action write branch (sara-update) — to be replaced

[VERIFIED: read from `.claude/skills/sara-update/SKILL.md` lines 262–281]

```
**action:**
## Description
> "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

{synthesised summary of what needs to be done, who is responsible, and any relevant
 deadlines or dependencies resolved during /sara-discuss}

## Notes
{synthesised blockers, dependencies, follow-up context, or related items from discussion
 notes — leave empty if none available}

## Cross Links
{...}
```

### Current action schema in CLAUDE.md (sara-init Step 9) — to be replaced

[VERIFIED: read from `.claude/skills/sara-init/SKILL.md` lines 255–272]

```yaml
id: ACT-000
title: ""
status: open  # open | in-progress | done | cancelled
summary: ""  # ACT: owner, due-date, status (open/in-progress/done/cancelled)
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
schema_version: "1.0"
tags: []
related: []
---

## Description

## Notes
```

### Current action template file (`.sara/templates/action.md` via sara-init Step 12) — to be replaced

[VERIFIED: read from `.claude/skills/sara-init/SKILL.md` lines 476–491]

Same outdated schema as above. Template and CLAUDE.md schema block must be updated together.

### Phase 8 precedent — sorter pass-through rule for new fields

[VERIFIED: read from `.claude/agents/sara-artifact-sorter.md` lines 151–154]

```
For requirement artifacts, preserve `priority` and `req_type` exactly as received from the
extraction pass. Do not modify, reclassify, or drop these fields. Pass them through unchanged
to `cleaned_artifacts`.
```
Same rule applies for `act_type`, `owner`, `due_date` — but no code change is needed in the sorter since the generic pass-through already handles unknown fields.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `## Description` + `## Notes` body | Six-section structured body (Source Quote, Description, Context, Owner, Due Date, Cross Links) | Phase 10 | Parallel structure with decisions (5 sections); actions are slightly more structured |
| `owner` proxied via `raised_by` | `owner` as distinct extracted field | Phase 10 | Accountability tracking separated from attribution |
| No `act_type` field | `act_type`: `deliverable` or `follow-up` | Phase 10 | Enables filtering and reporting by action type |
| No `due_date` field | `due_date`: raw string from source | Phase 10 | Timing information captured at extraction time |
| `schema_version: "1.0"` | `schema_version: '2.0'` | Phase 10 | Single-quote convention, YAML float-parse safety |
| Action vague extraction signal | Positive definition: any passage implying work needs to happen | Phase 10 | Higher recall; sorter handles disambiguation |

---

## Integration Verification Checklist

The following integration points must be verified after implementation:

1. **Sorter input contract:** Action artifacts from sara-extract now include `act_type`, `owner`, `due_date`. The sorter's pass-through rules preserve any fields not explicitly handled — confirmed from Phase 8/9 precedent. No sorter changes needed, but verify the sorter's output still includes these fields in `cleaned_artifacts`.

2. **Step 4 warning logic:** Owner warning triggers when `artifact.type == "action"` AND (`artifact.owner == ""` OR `artifact.owner` does not match `STK-\d{3}`). Warning is plain text output before the artifact summary block, not inside AskUserQuestion.

3. **sara-update owner mapping:** New action create branch sets `owner = artifact.owner`. New action update branch also sets `owner = artifact.owner`. Neither branch falls back to `artifact.raised_by` for action artifacts.

4. **schema_version single quotes:** All three updated files (sara-extract artifact schema documentation, sara-update write branch, sara-init template and CLAUDE.md block) must write `'2.0'` with single quotes.

5. **Template file location:** `.sara/templates/action.md` is written by sara-init Step 12. The template is used by sara-update at runtime when creating new action pages. The template and the write branch in sara-update must be consistent with the same v2.0 schema.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — skill file changes are markdown/YAML text edits |
| Config file | None |
| Quick run command | Manual: run `/sara-extract` on a test document and inspect output |
| Full suite command | Manual: run full pipeline (`/sara-ingest`, `/sara-discuss`, `/sara-extract`, `/sara-update`) on a test document |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| — | Action extraction produces `act_type`, `owner`, `due_date` fields | Manual | `/sara-extract MTG-001` inspect JSON in pipeline-state.json | N/A |
| — | Owner warning appears for unresolved owner | Manual | Run extraction on doc with unnamed action owner | N/A |
| — | v2.0 action wiki page has correct frontmatter fields | Manual | Inspect created ACT-NNN.md after `/sara-update` | N/A |
| — | Six-section body written correctly | Manual | Inspect ACT-NNN.md body structure | N/A |
| — | `schema_version: '2.0'` single-quoted in output | Manual | `grep "schema_version" wiki/actions/ACT-*.md` | N/A |

There is no automated test framework for SARA skill files. Validation is by manual pipeline execution.

### Wave 0 Gaps

None — no test infrastructure exists or is expected for SARA skills. Validation is performed by the verifier reading the skill files directly.

---

## Environment Availability

Step 2.6: SKIPPED — phase modifies only markdown skill files. No external tools, runtimes, databases, or services are required.

---

## Open Questions (RESOLVED)

1. RESOLVED: **Sorter output_format action example** — Plan 03 Task 2 adds a documentation-only rule to the sorter's output_format section showing `act_type`, `owner`, `due_date` fields in the action artifact example. This provides clarity without any functional change to the sorter.

2. RESOLVED: **Update branch: existing ACT pages with v1.0 schema** — Plan 03 Task 2 mirrors the Phase 8 pattern: the update branch upgrades the entire action page to v2.0 format (full six-section body + new frontmatter fields) whenever it processes an action artifact, consistent with how requirement and decision update branches work.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The sorter passes `act_type`, `owner`, `due_date` through unchanged without explicit pass-through rules because its generic field preservation handles unknown fields | Integration Verification, Architecture Patterns | Sorter silently drops new fields; action artifacts reach sara-update with missing fields. Mitigation: verify after implementation by inspecting the sorter's cleaned_artifacts output. |
| A2 | The update branch for action artifacts should mirror the Phase 8/9 pattern and upgrade the full page to v2.0 schema when processing any update action | Open Questions #2 | If wrong, existing ACT pages touched by updates get partial v2.0 upgrades (body unchanged, frontmatter changed). Low risk — worst case is inconsistent wiki pages, not data loss. |

---

## Sources

### Primary (HIGH confidence)
- `.claude/skills/sara-extract/SKILL.md` — Current action pass (Step 3, lines 139–146); Step 4 approval loop structure; sorter dispatch pattern
- `.claude/skills/sara-update/SKILL.md` — Current action write branch (lines 262–281); owner mapping logic (line ~106); update branch pattern for v2.0 upgrades
- `.claude/skills/sara-init/SKILL.md` — Current action schema block (Step 9, lines 255–272); current action template (Step 12, lines 476–491)
- `.claude/agents/sara-artifact-sorter.md` — Pass-through rules for type-specific fields; output_format schema
- `.planning/phases/10-refine-actions/10-CONTEXT.md` — All locked decisions D-01 through D-13
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — Two-track pattern reference; schema_version convention
- `.planning/phases/09-refine-decisions/09-CONTEXT.md` — Decision refinement pattern; sorter pass-through confirmation

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — Project history and accumulated decisions
- `.planning/REQUIREMENTS.md` — WIKI-03 action page schema definition

---

## Metadata

**Confidence breakdown:**
- Standard stack (files to modify): HIGH — all files read and verified in this session
- Architecture (pipeline mechanics): HIGH — two-track pattern confirmed from Phase 8/9 implementations
- Pitfalls: HIGH — derived from direct code reading and Phase 8/9 precedent
- Integration points: HIGH — sorter pass-through validated from Phase 8 precedent and code reading

**Research date:** 2026-04-29
**Valid until:** No external dependencies — valid until skill files change
