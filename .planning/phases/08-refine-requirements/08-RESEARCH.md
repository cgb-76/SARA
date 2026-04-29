# Phase 8: refine-requirements — Research

**Researched:** 2026-04-29
**Domain:** SARA skill modification — requirements extraction and wiki page formatting
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Primary extraction signal is **linguistic markers** — modal verbs and imperative language: `must`, `shall`, `should`, `will`, `need to`, `required to`, `has to`. Passages containing none of these are not requirements regardless of topic.

**D-02:** Vague wishes, observations, aspirational statements, and background context without a commitment modal are explicitly excluded. The extraction prompt must include negative examples of these.

**D-03:** MoSCoW priority mapped from modal verb in the same inline extraction pass:
- `must` / `shall` / `will` → `must-have`
- `should` → `should-have`
- `could` / `may` → `could-have`
- Explicit "we won't" / "out of scope" language → `wont-have`

**D-04:** Priority is assigned in the same inline extraction pass as identification and type classification — no separate round-trip.

**D-05:** Extraction pass classifies each requirement into one of six types inline:
- `functional`, `non-functional`, `regulatory`, `integration`, `business-rule`, `data`

**D-06:** `schema_version` bumped to `'2.0'` on all requirement pages written or updated after this phase.

**D-07:** `description` field **removed** from requirement frontmatter. Content replaced by structured body sections.

**D-08:** `summary` field moves under `title` in frontmatter.

**D-09:** Two new frontmatter fields added: `type` and `priority`.

**D-10:** Entire markdown body replaced by: Source Quote, Statement, User Story, Acceptance Criteria, BDD Criteria, Context, Cross Links.

**D-11:** Section matrix (required/optional/omitted per type) is embedded in the sara-init template and referenced in sara-extract's requirements pass.

**D-12:** sara-update writes `## Cross Links` section from `related[]` frontmatter. Each entry becomes one wiki link per line.

**Scope:** Requirements only. No changes to sorter agent, approval loop, sara-discuss, sara-ingest, pipeline-state.json structure, or other artifact types.

### Claude's Discretion

- Number of BDD scenarios per requirement: one happy-path scenario is the default; add additional scenarios only when the requirement explicitly has distinct, named edge cases.
- Whether to add a `## Cross Links` back-fill step to sara-lint for existing requirement pages that predate this phase.
- Exact wording of the updated extraction prompt — must include at least three negative examples (wish, observation, aspiration) alongside the positive modal-verb signal list.

### Deferred Ideas (OUT OF SCOPE)

- Apply same two-track refinement to decisions, risks, and actions — subsequent phases
- REQUIREMENTS.md documentation gap (MEET-01, MEET-02, sara-lint, sara-add-stakeholder mismarked) — documentation reconciliation not scoped
- sara-lint backfill: existing REQ pages predate v2.0 schema; migration pass discussed but not scoped into this phase
</user_constraints>

---

## Summary

Phase 8 is a **skill-text editing phase** — there are no library installs, no new external tools, and no architectural changes. The work is rewriting prose and templates inside three existing skill files: `sara-extract/SKILL.md`, `sara-init/SKILL.md`, and `sara-update/SKILL.md`, plus verifying compatibility with the `sara-artifact-sorter` agent.

The two tracks map cleanly to distinct files. Track 1 (Extraction) touches only `sara-extract/SKILL.md` Step 3's requirements pass prompt — a single targeted rewrite of approximately 8 lines of prose. Track 2 (Writing) touches `sara-init/SKILL.md` Step 12 (the `requirement.md` template) and Step 9 (the CLAUDE.md schema block for requirements), plus `sara-update/SKILL.md` Step 2's requirement create branch (new body structure) and a new Cross Links write step.

The main engineering challenge is the section matrix: the planner must embed the full matrix and its rationale into both the sara-init template (as comments) and the sara-extract requirements pass (as a decision rule). The sorter agent (`sara-artifact-sorter.md`) receives the new `priority` and `req_type` fields through — its input contract must be verified to ensure it passes them through without stripping them.

**Primary recommendation:** Plan three sequential plans: (1) sara-extract requirements pass rewrite, (2) sara-init requirement template + CLAUDE.md schema block, (3) sara-update requirement write branch + Cross Links. Verify sorter compatibility in plan 1 since it receives extract output.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Requirement extraction signal + MoSCoW + type classification | `sara-extract` SKILL.md Step 3 | — | Extraction is a single inline pass; all three properties assigned together in the requirements pass prompt |
| Requirement wiki page template (schema v2.0) | `sara-init` SKILL.md Step 12 | `sara-init` SKILL.md Step 9 (CLAUDE.md block) | Template is the canonical shape; CLAUDE.md block is the auto-loaded schema reference for wiki-scoped tools |
| Writing wiki pages with new body structure | `sara-update` SKILL.md Step 2 | — | sara-update owns all wiki artifact writes |
| Cross Links section generation from `related[]` | `sara-update` SKILL.md Step 2 (requirement create branch) | sara-update Step 2 (update branch) | sara-update already owns the write step; Cross Links is appended after other body sections |
| Sorter passthrough of `priority` + `req_type` | `sara-artifact-sorter` agent | — | Sorter receives extract output and must not strip new fields; no modification needed but compatibility must be verified |

---

## Standard Stack

This phase has no external library dependencies. All work is editing SKILL.md and agent files.

**Tools used in the skills themselves (unchanged):**
| Tool | Purpose | Pattern |
|------|---------|---------|
| Write | All wiki page writes | Established — Write tool only, never shell text-processing |
| Read | Template and state reads | Established |
| Bash | grep-extract for wiki summaries, git commit | Established |

**Version verification:** Not applicable — no npm packages.

---

## Architecture Patterns

### System Architecture Diagram

```
Source document (in context)
        │
        ▼
┌───────────────────────────────────────────────────────┐
│  sara-extract Step 3 — Requirements pass              │
│                                                       │
│  Signal: modal verbs (must/shall/should/will/...)     │
│  Output per req: source_quote, title, raised_by,      │
│    priority (MoSCoW), req_type (6-type taxonomy),     │
│    action=create, id_to_assign=REQ-NNN               │
└───────────────┬───────────────────────────────────────┘
                │  req_artifacts (JSON array)
                ▼
┌───────────────────────────────────────────────────────┐
│  Merge (req + dec + act + risk)                       │
│  → sara-artifact-sorter Task()                        │
│    Passes new fields through unchanged                │
│  → cleaned_artifacts with priority + req_type intact  │
└───────────────┬───────────────────────────────────────┘
                │  approved_artifacts (after user loop)
                ▼
┌───────────────────────────────────────────────────────┐
│  sara-update Step 2 — requirement create branch       │
│                                                       │
│  Reads .sara/templates/requirement.md (v2.0)         │
│  Writes frontmatter: id, title, summary, status,     │
│    type, priority, source, raised-by, owner,         │
│    schema_version='2.0', tags, related               │
│                                                       │
│  Writes body sections per section matrix:             │
│    ## Source Quote  (all types)                       │
│    ## Statement     (all types)                       │
│    ## User Story    (functional=✓, nonfunc=opt, ...)  │
│    ## Acceptance Criteria (all types)                 │
│    ## BDD Criteria  (functional=✓, biz-rule=✓, ...)  │
│    ## Context       (functional=opt, others=✓)        │
│    ## Cross Links   (all types — from related[])      │
└───────────────────────────────────────────────────────┘
```

### Recommended File Edit Scope

```
.claude/skills/
├── sara-extract/SKILL.md     # Step 3 requirements pass prompt ONLY — 8–15 lines replaced
├── sara-init/SKILL.md        # Step 12 requirement.md template (full replace) + Step 9 CLAUDE.md schema block
└── sara-update/SKILL.md      # Step 2 requirement create branch body structure + Cross Links append step

.claude/agents/
└── sara-artifact-sorter.md   # READ ONLY — verify field passthrough, no edits expected
```

### Pattern 1: Inline Extraction Pass with Multiple Output Fields

**What:** The existing requirements pass returns a JSON array. Phase 8 adds two fields to each object in that array: `priority` (MoSCoW string) and `req_type` (six-type string). These are populated by the same inline LLM reasoning that identifies the passage — no separate step.

**When to use:** Whenever classification can be derived from the same signal used for detection (here: the modal verb determines both that a passage is a requirement and what its priority is).

**Example (updated requirements pass output schema):**
```json
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "...",
  "source_quote": "...",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "",
  "priority": "must-have",
  "req_type": "functional"
}
```
[VERIFIED: sara-extract SKILL.md — existing artifact schema; new fields `priority` and `req_type` added]

### Pattern 2: Frontmatter v2.0 Shape

**What:** Requirement wiki pages use a new frontmatter schema. `description` is removed. `summary` moves directly under `title`. `type` and `priority` are new fields. `schema_version` is `'2.0'`.

**Full shape (from CONTEXT.md D-06 through D-09):**
```yaml
---
id: REQ-NNN
title: ...
summary: <50-word summary>
status: open|accepted|rejected|superseded
type: functional|non-functional|regulatory|integration|business-rule|data
priority: must-have|should-have|could-have|wont-have
source: <ingest ID>
raised-by: <STK-NNN>
owner: <STK-NNN>
schema_version: '2.0'
tags: []
related: []
---
```
[CITED: 08-CONTEXT.md D-06 through D-09]

**YAML quoting rule:** `schema_version: '2.0'` must use single quotes (not `2.0` bare) — established in Phase 1 to prevent YAML float parsing. [VERIFIED: sara-update SKILL.md notes, sara-init SKILL.md Step 9]

### Pattern 3: Section Matrix Decision Rule in Prompt Text

**What:** The sara-extract requirements pass prompt must include the section matrix as a decision table, so the LLM knows which sections to instruct sara-update to populate. This is embedded inline in the prompt text, not as a separate file read.

**Matrix (from CONTEXT.md D-11):**

| Section | Functional | Non-functional | Regulatory | Integration | Business rule | Data |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Source Quote | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Statement | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| User Story | ✓ | opt | — | opt | — | — |
| Acceptance Criteria | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| BDD Criteria | ✓ | — | — | opt | ✓ | — |
| Context | opt | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cross Links | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

[CITED: 08-CONTEXT.md D-11]

### Pattern 4: Cross Links Generation from `related[]`

**What:** sara-update, after writing the page body, appends a `## Cross Links` section. Each entry in `related[]` frontmatter becomes one wiki link on its own line using the existing `[[ID|display text]]` convention.

**Example output:**
```markdown
## Cross Links
[[DEC-003|DEC-003 Defer SSO to Phase 3]]
[[STK-001|Rajiwath Patel]]
```

**Wikilink convention (established):** [VERIFIED: sara-update SKILL.md — wikilink rule section]
- STK entities: `[[STK-NNN|name]]`
- REQ/DEC/ACT/RSK entities: `[[ID|ID Title]]`
- If `related[]` is empty: write `## Cross Links` heading with no content (heading only — consistent with other empty sections)

### Anti-Patterns to Avoid

- **Modifying the sorter agent:** The sorter receives `priority` and `req_type` as new fields in the artifact objects. It should pass them through without touching them. No edits to `sara-artifact-sorter.md` are expected — verify field passthrough only.
- **Adding a description field stub:** The v2.0 schema removes `description` entirely. Do not leave it as an empty field or comment.
- **Putting the section matrix in a separate file:** The matrix must be embedded in the sara-init template (as YAML comments) and in the sara-extract requirements pass prompt text — not referenced via a file read.
- **Using Bash shell text-processing for the wiki page body:** All wiki page writes use the Write tool only. The Cross Links section is assembled in-memory and written as part of the full page content.
- **Bumping schema_version on non-requirement templates:** D-06 applies only to requirement pages. Decision, action, risk, and stakeholder templates are not changed in this phase.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting modal verbs in extraction pass | Custom regex or parser | Inline LLM prompt with explicit verb list | Extraction is already LLM-driven; the prompt is the signal source |
| Generating BDD scenarios | A template engine | LLM synthesis from source_quote + discussion_notes | All body section synthesis is already LLM-driven in sara-update Step 2 |
| Writing Cross Links | Shell script or grep | In-memory assembly + Write tool | Established pattern: all wiki writes use Write tool only |

**Key insight:** This phase is prompt engineering and template editing, not code. The "logic" lives in the LLM instructions inside the skill files.

---

## Common Pitfalls

### Pitfall 1: Sorter Strips New Fields
**What goes wrong:** `sara-artifact-sorter` receives the merged artifact array. If it rebuilds the artifact objects from scratch (rather than passing them through), `priority` and `req_type` would be lost before reaching the approval loop.
**Why it happens:** The sorter's output schema in `sara-artifact-sorter.md` shows a fixed set of fields — the new fields are not listed there.
**How to avoid:** Read the sorter's output_format section carefully. The sorter uses a frozen artifact schema in its output. The new fields must either be added to the sorter's output schema definition, or the sorter must be instructed to pass through unknown fields.
**Warning signs:** If the sorter output schema does not include `priority` and `req_type`, the planner must add them to `sara-artifact-sorter.md` output_format.

### Pitfall 2: CLAUDE.md Schema Block Not Updated
**What goes wrong:** The sara-init SKILL.md Step 9 writes the `CLAUDE.md` file with the entity schemas embedded. The Requirement schema block there still shows the v1.0 shape (`description` field, no `type`, no `priority`). New projects initialised after this phase would get the old schema in their CLAUDE.md, causing confusion.
**Why it happens:** CLAUDE.md is written by sara-init Step 9 as a hardcoded string — it is a separate change from the template in Step 12.
**How to avoid:** Update both Step 9 (CLAUDE.md entity schema block for Requirement) AND Step 12 (`.sara/templates/requirement.md` template). These are two separate edits in sara-init/SKILL.md.

### Pitfall 3: `'2.0'` Quotes Dropped
**What goes wrong:** `schema_version: 2.0` is written without quotes. YAML parsers (especially those used by Obsidian or tools that read these files) interpret this as the float `2.0`, not the string `"2.0"`. This breaks schema version string comparisons.
**Why it happens:** LLM-generated YAML often drops quotes around version-like strings.
**How to avoid:** Embed the quoted form `'2.0'` explicitly in both the template and the sara-update write instruction. Note the established project pattern: `schema_version: "1.0"` uses double quotes in SKILL.md prose but the template must use single quotes (YAML ambiguity prevention).

### Pitfall 4: Body Structure Applied to Update Branch Too
**What goes wrong:** When sara-update updates an existing requirement page (`action=update`), it currently reads the existing file and applies `change_summary`. If the update branch is not also updated to use the v2.0 body structure, updated requirements will have a mix of old and new body sections.
**Why it happens:** The update branch is a separate code path in sara-update Step 2.
**How to avoid:** Determine in planning whether the update branch should also migrate the body to v2.0 structure. Given D-06 scopes v2.0 to pages "written or updated after this phase", the update branch should also write the new body structure when updating a requirement.

### Pitfall 5: Extraction Prompt Negative Examples Too Weak
**What goes wrong:** The prompt includes generic negative examples that LLMs still classify as requirements (e.g. "We want better performance" — still sounds like a requirement).
**Why it happens:** The distinction between aspirational language and committed language is subtle.
**How to avoid (Claude's Discretion):** The prompt must include at least three negative examples that clearly lack a commitment modal. Good negative example types: (a) observation — "Users are currently frustrated with slow load times", (b) aspiration/wish — "It would be great if the system could handle more users", (c) background context — "The company processes approximately 10,000 invoices per month". These all describe situations without committing the system or project to any behaviour.

### Pitfall 6: Cross Links Section Written for Empty `related[]`
**What goes wrong:** If `related[]` is empty and sara-update writes `## Cross Links\n` with no content, the section exists but is empty. This is consistent with other optional sections in the current skill, but could look odd.
**Why it happens:** The matrix says Cross Links is ✓ (required) for all types.
**How to avoid:** Writing the heading with no content when `related[]` is empty is acceptable and consistent with the existing "heading only" pattern for empty sections. The planner should document this as the intended behaviour, not a bug.

---

## Code Examples

### Updated Requirements Pass Output (extended schema)

The requirements pass in sara-extract Step 3 should produce objects in this shape. The sorter receives these and must pass `priority` and `req_type` through.

```json
// Source: 08-CONTEXT.md code_context section
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "API rate limiting per tenant",
  "source_quote": "Each tenant must be limited to 1000 API calls per minute.",
  "raised_by": "STK-001",
  "related": [],
  "change_summary": "",
  "priority": "must-have",
  "req_type": "non-functional"
}
```

### Updated Requirement Template (v2.0)

The template in `.sara/templates/requirement.md` (written by sara-init Step 12):

```markdown
---
id: REQ-000
title: ""
summary: ""  # REQ: title, status, one-line description of what is required
status: open  # open | accepted | rejected | superseded
type: functional  # functional | non-functional | regulatory | integration | business-rule | data
priority: must-have  # must-have | should-have | could-have | wont-have
source: ""     # ingest ID (e.g. MTG-001)
raised-by: ""  # stakeholder ID (e.g. STK-001)
owner: ""      # stakeholder ID (e.g. STK-001)
schema_version: '2.0'
tags: []
related: []    # entity IDs (e.g. [DEC-001, ACT-002])
---

## Source Quote
> [exact stakeholder words from source document]

## Statement
The [subject] shall [verb phrase].

## User Story
As a [role], I want [capability], so that [benefit].

## Acceptance Criteria
- [ ] [plain language condition]

## BDD Criteria
**Scenario: [name]**
Given [context]
When [action]
Then [outcome]

## Context
[Rationale, background, constraints not captured elsewhere]

## Cross Links
[One wiki link per related[] entry]
```

[CITED: 08-CONTEXT.md D-06 through D-11 — template shape and body structure]

### Modal Verb → MoSCoW Mapping (for extraction prompt)

```
Primary signal — modal verbs and imperative phrases:
  INCLUDE (these passages ARE requirements):
  - "must", "shall", "will" → priority: must-have
  - "should" → priority: should-have
  - "could", "may" → priority: could-have
  - "will not", "won't", "out of scope" → priority: wont-have
  - imperative phrases: "need to", "required to", "has to" → priority: must-have

  EXCLUDE (these passages are NOT requirements):
  - Observation: "Users are currently frustrated with slow load times" (no commitment)
  - Aspiration: "It would be great if the system handled more users" (no modal)
  - Background context: "The company processes 10,000 invoices monthly" (descriptive only)
```

[CITED: 08-CONTEXT.md D-01, D-02, D-03]

### Cross Links Section Generation (sara-update)

```python
# Pseudocode for the Cross Links generation step in sara-update Step 2
# Source: 08-CONTEXT.md D-12 and sara-update SKILL.md wikilink rule

cross_links_lines = []
for entity_id in artifact.related:
    if entity_id.startswith("STK-"):
        name = read_stakeholder_name(entity_id)
        cross_links_lines.append(f"[[{entity_id}|{name}]]")
    else:
        title = lookup_title_from_index(entity_id)
        cross_links_lines.append(f"[[{entity_id}|{entity_id} {title}]]")

cross_links_body = "\n".join(cross_links_lines)  # one link per line
```

---

## Sorter Compatibility Analysis

**Current sorter output schema** (from `sara-artifact-sorter.md` output_format):

```json
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "...",
  "source_quote": "...",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": ""
}
```

**Problem:** The sorter output schema does not include `priority` or `req_type`. If the sorter reconstructs artifact objects using only its listed fields, the new fields will be dropped.

**Required fix:** The sorter's `<output_format>` section must be updated to include `priority` and `req_type` in the example output objects and in the rules section. The sorter should be instructed to preserve all fields received from the extraction pass — it is not the sorter's responsibility to validate or classify these fields.

**Scope impact:** `sara-artifact-sorter.md` requires a minimal edit (add two fields to the output schema example + a passthrough rule). This is a read-only compatibility fix — the sorter's dedup/classification logic does not change.

[VERIFIED: sara-artifact-sorter.md output_format section — current schema confirmed by direct file read]

---

## State of the Art

| Old Approach | Current Approach | Changed In | Impact |
|--------------|-----------------|------------|--------|
| Vague extraction prompt ("capability, constraint, or rule") | Modal-verb anchored prompt with negative examples | Phase 8 | Higher precision; fewer false positives (aspirations, observations) |
| `description` field as sole body section | Multi-section structured body (Source Quote, Statement, User Story, etc.) | Phase 8 | Requirements become self-documenting with testable acceptance criteria |
| No priority field | `priority` (MoSCoW) from modal verb mapping | Phase 8 | Requirements can be prioritised without a separate pass |
| No type taxonomy | 6-type classification inline | Phase 8 | Downstream filtering and reporting by requirement type |
| Flat `related[]` in frontmatter (not rendered) | `## Cross Links` section in body | Phase 8 | Cross-references become visible and navigable in the wiki |
| schema_version: '1.0' | schema_version: '2.0' | Phase 8 | Enables future tooling to distinguish pre/post-phase-8 pages |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The sorter rebuilds artifact objects using only its documented output schema fields, meaning `priority` and `req_type` will be dropped unless the sorter schema is updated | Sorter Compatibility Analysis | If sorter passes through unknown fields automatically, the sorter edit is unnecessary but harmless |
| A2 | The update branch of sara-update Step 2 should also write the new v2.0 body structure when updating a requirement page | Common Pitfalls (Pitfall 4) | If update branch should preserve existing body structure, Cross Links and body rewrite only apply to creates |
| A3 | `## Cross Links` with an empty `related[]` should write the heading with no content (heading-only pattern) | Common Pitfalls (Pitfall 6) | If the preference is to omit the heading entirely when empty, the write logic changes slightly |

**Note on A1:** The sorter's output_format section shows a single example object with a fixed field list. The rules section says "every object must conform to the frozen artifact schema" — this strongly implies fields not in the schema will be dropped. Treat as confirmed: sorter schema edit is required.

---

## Open Questions

1. **Update branch body structure**
   - What we know: D-06 says v2.0 applies to pages "written or updated after this phase"
   - What's unclear: Does "updated" mean the body structure is also rewritten, or only the frontmatter gains `type` and `priority`?
   - Recommendation: Rewrite the full body to v2.0 structure on update (consistent with D-06 intent). If the existing page has a v1.0 body, the update replaces it with the structured v2.0 sections, synthesising content from the update's source_quote and change_summary.

2. **CLAUDE.md Requirement schema block in new sara-init projects**
   - What we know: sara-init Step 9 writes CLAUDE.md with hardcoded entity schema blocks
   - What's unclear: The Requirement schema block in Step 9 is a prose display block — it does not need to be a copy of the template, but it should be consistent
   - Recommendation: Update the Requirement schema block in CLAUDE.md (Step 9) to show the v2.0 frontmatter fields and add a note that the body follows the structured section format. Full body sections do not need to be in CLAUDE.md.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely skill-file edits with no external tool dependencies. No npm packages, databases, or CLI tools required beyond what is already established (git, Write/Read tools).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test suite in this project) |
| Config file | None |
| Quick run command | Read modified SKILL.md files and confirm changes match CONTEXT.md decisions |
| Full suite command | End-to-end verification: run `/sara-extract` against a test fixture and inspect the approved artifact list for `priority` and `req_type` fields; run `/sara-update` and inspect the written wiki page |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| D-01/D-02 | Modal verbs are the primary extraction signal; negative examples present in prompt | Manual — LLM prompt review | Read sara-extract SKILL.md, confirm prompt text | ❌ Wave 0 |
| D-03/D-04 | MoSCoW priority assigned inline in same pass | Manual — artifact inspection | Run `/sara-extract` on test fixture; inspect `priority` field in approval loop output | ❌ Wave 0 |
| D-05 | Six-type classification assigned inline | Manual — artifact inspection | Inspect `req_type` field in approval loop output | ❌ Wave 0 |
| D-06 to D-09 | v2.0 frontmatter shape on written pages | Manual — file inspection | Read a written REQ-NNN.md; confirm `schema_version: '2.0'`, `type`, `priority` present, `description` absent | ❌ Wave 0 |
| D-10/D-11 | Structured body sections with section matrix | Manual — file inspection | Inspect body of written REQ-NNN.md; confirm all required sections present for the artifact's type | ❌ Wave 0 |
| D-12 | Cross Links written from `related[]` | Manual — file inspection | Inspect `## Cross Links` section of a REQ page with non-empty `related[]` | ❌ Wave 0 |
| Sorter | `priority` and `req_type` survive sorter passthrough | Manual — sorter output inspection | Inspect cleaned_artifacts output from sorter; confirm new fields present | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Read the modified skill file; confirm changed section matches the decision from CONTEXT.md
- **Per wave merge:** Not applicable (no automated test runner)
- **Phase gate:** End-to-end run of `/sara-extract` + `/sara-update` on a synthetic source document containing modal verbs of different strengths, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Test fixture document: a synthetic meeting transcript containing requirements with `must`, `should`, `could`, and aspirational language (to verify extraction precision)
- [ ] Verification script or checklist: document the exact inspection steps for each decision (file fields to check, sections to confirm)

---

## Security Domain

This phase modifies only LLM prompt text and YAML/markdown templates. No authentication, data handling, cryptography, or access control is involved. Security domain: NOT APPLICABLE.

---

## Sources

### Primary (HIGH confidence)
- `.claude/skills/sara-extract/SKILL.md` — Current requirements pass prompt (Step 3); sorter dispatch interface; artifact schema
- `.claude/skills/sara-init/SKILL.md` — Step 9 (CLAUDE.md block) and Step 12 (template writes) — current v1.0 template shape
- `.claude/skills/sara-update/SKILL.md` — Step 2 requirement create/update branches; wikilink rule; write patterns
- `.claude/agents/sara-artifact-sorter.md` — Output schema; passthrough behaviour analysis
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — All locked decisions D-01 through D-12

### Secondary (MEDIUM confidence)
- `.planning/phases/05-artifact-summaries/05-CONTEXT.md` — `summary` field established pattern; grep-extract pattern; Phase 5 decisions carried forward
- `.planning/STATE.md` — YAML quoting rule (`schema_version` as quoted string) — established in Phase 1

### Tertiary (LOW confidence)
None — all findings verified from codebase.

---

## Metadata

**Confidence breakdown:**
- Locked decisions: HIGH — all read from CONTEXT.md
- Current skill file shapes: HIGH — all verified by direct file reads
- Sorter compatibility gap: HIGH — confirmed by reading sorter output_format section
- Validation approach: MEDIUM — no automated test infrastructure exists; manual verification is the established pattern for this project

**Research date:** 2026-04-29
**Valid until:** Stable until any of the three modified SKILL.md files are edited by another phase
