# Phase 9: refine-decisions — Research

**Researched:** 2026-04-29
**Domain:** SARA skill modification — decision extraction and wiki page formatting
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Two extraction signals, yielding two distinct initial statuses:
- **Commitment language** — "we decided to", "we chose", "we agreed on", "we went with", "we will use", "the approach is" → `status: accepted`
- **Misalignment language** — disagreement, contested views, unresolved choices, "we need to decide", competing preferences → `status: open`

**D-02:** `proposed` is dropped as an initial status value. New decision artifacts start as either `accepted` or `open`, never `proposed`.

**D-03:** The extraction pass sets `status` in the artifact JSON based on which signal was detected. sara-update writes that status directly to the wiki page frontmatter.

**D-04:** The decision extraction pass captures three structured fields per artifact (in addition to standard fields):
- `source_quote` — exact verbatim passage from the source document (MANDATORY)
- `chosen_option` — option selected for commitment-language decisions; empty string for open/misalignment decisions
- `alternatives` — list of alternatives considered (if present); empty array if not mentioned

**D-05:** sara-update synthesises `## Context` and `## Rationale` body sections from the full source document and discussion notes — NOT extracted in the artifact pass.

**D-06:** The extraction pass classifies each decision into one of six types (inline, same pass):
- `architectural` — system structure, technology choices, component relationships
- `process` — how the team works, workflow, ceremonies, practices
- `tooling` — software tools, libraries, platforms selected
- `data` — data model, storage, retention, ownership rules
- `business-rule` — domain logic, policy decisions
- `organisational` — team structure, ownership, roles, responsibilities

**D-07:** `schema_version` bumped to `'2.0'` (single quotes — prevents YAML float parse, consistent with requirement schema convention).

**D-08:** Narrative frontmatter fields **removed**: `context`, `decision`, `rationale`, `alternatives-considered`. These move fully into the body sections.

**D-09:** New frontmatter field added: `type` (one of the six values from D-06).

**D-10:** `status` initial value changes from `proposed` to either `accepted` or `open` (set by extraction pass).

Full v2.0 frontmatter shape:
```yaml
---
id: DEC-NNN
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""       # DEC: options considered, chosen option, status, decision date
type: architectural  # architectural | process | tooling | data | business-rule | organisational
date: ""          # ISO 8601 (e.g. 2026-04-29)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
source: []        # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---
```

**D-11:** The body follows this section order:
```markdown
## Source Quote
> [exact verbatim passage from source document] — [[STK-NNN|Stakeholder Name]]

## Context

[Synthesised by sara-update: why this decision was needed, background]

## Decision

[The chosen option — from chosen_option extraction field]

## Alternatives Considered

[List of alternatives from alternatives extraction field; expanded with synthesis if present in source]

## Rationale

[Synthesised by sara-update: why this option was chosen over the alternatives]
```

**D-12:** For `status: open` (misalignment) decisions, `## Decision` reads "No decision reached — alignment required." and `## Alternatives Considered` lists the competing positions detected in the source.

**Scope:** Decision artifact only. No changes to: the sorter agent, per-artifact approval loop, sara-discuss, sara-ingest, pipeline-state.json structure, requirement/action/risk artifact types.

### Claude's Discretion

- Exact wording of the extraction prompt (must produce the correct JSON schema including `chosen_option`, `alternatives`, `type`, `status`)
- Whether to add negative examples to the extraction prompt (passages that are NOT decisions — discussions, considerations, aspirations)
- Summary generation wording for `accepted` vs `open` decisions

### Deferred Ideas (OUT OF SCOPE)

- Refine action artifact (extraction signal, schema) — subsequent phase
- Refine risk artifact (extraction signal, schema) — subsequent phase
</user_constraints>

---

## Summary

Phase 9 is a **skill-text editing phase** — there are no library installs, no new external tools, and no architectural changes. The work is rewriting prose and templates inside three existing skill files (`sara-extract/SKILL.md`, `sara-update/SKILL.md`, `sara-init/SKILL.md`) to refine the decision artifact across two tracks, directly mirroring the pattern established in Phase 8 for requirements.

**Track 1 (Extraction):** The decisions pass in sara-extract Step 3 is currently one short block ("a deliberate choice made by the team that was concluded"). It needs to be replaced with a two-signal detector (commitment language → `accepted`; misalignment language → `open`) plus inline `type` classification (six categories), `chosen_option` capture, and `alternatives` capture. The three new artifact fields (`status`, `type`, `chosen_option`, `alternatives`) must be added to the sorter's output schema passthrough rules for decision artifacts — currently the sorter output_format decision object example shows no decision-specific fields beyond standard ones.

**Track 2 (Writing):** sara-update currently writes decision artifacts with `status: proposed` and four narrative frontmatter fields (`context`, `decision`, `rationale`, `alternatives-considered`). Post-phase: status comes from the extraction field; the four narrative fields are removed from frontmatter; `type` and `schema_version: '2.0'` are added; and the body structure changes to a five-section layout (Source Quote, Context, Decision, Alternatives Considered, Rationale). sara-init's decision template (Step 12) and CLAUDE.md decision schema block (Step 9) must be updated to match.

The critical difference from Phase 8: the decisions pass adds MORE extraction fields (status, type, chosen_option, alternatives) than the requirements pass added (priority, req_type). The sorter currently shows a decision update example with NO type-specific fields. This must be fixed.

**Primary recommendation:** Plan three sequential plans: (1) sara-extract decisions pass rewrite + sorter decision schema passthrough fix, (2) sara-init decision template + CLAUDE.md schema block, (3) sara-update decision create/update branches. This mirrors the three-plan structure of Phase 8.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Decision signal detection (commitment vs misalignment) | `sara-extract` SKILL.md Step 3 decisions pass | — | Extraction is a single inline pass; signal detection, status, type, chosen_option, and alternatives all assigned together |
| Decision artifact type classification (six-type taxonomy) | `sara-extract` SKILL.md Step 3 decisions pass | — | Inline with signal detection — same pass |
| Sorter passthrough of new decision fields | `sara-artifact-sorter` agent | — | Sorter receives extracted decision objects; must pass `status`, `type`, `chosen_option`, `alternatives` through unchanged |
| Decision wiki page template (schema v2.0) | `sara-init` SKILL.md Step 12 | `sara-init` SKILL.md Step 9 (CLAUDE.md block) | Template is the canonical shape; CLAUDE.md block is the auto-loaded schema reference |
| Writing decision wiki pages with new body structure | `sara-update` SKILL.md Step 2 | — | sara-update owns all wiki artifact writes |
| `## Decision` body section (chosen_option → body) | `sara-update` SKILL.md Step 2 decision create branch | — | Reads `chosen_option` from extraction artifact, writes the Decision section |
| `## Context` and `## Rationale` synthesis | `sara-update` SKILL.md Step 2 decision create branch | — | Synthesised from source doc + discussion notes — not extracted inline (D-05) |

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
┌───────────────────────────────────────────────────────────────────┐
│  sara-extract Step 3 — Decisions pass (REWRITTEN)                 │
│                                                                   │
│  Signal A — Commitment language:                                  │
│    "we decided to", "we chose", "we agreed on", "we will use"     │
│    → status: accepted                                             │
│                                                                   │
│  Signal B — Misalignment language:                                │
│    disagreement, "we need to decide", competing preferences       │
│    → status: open                                                 │
│                                                                   │
│  Inline classification (six types):                               │
│    architectural | process | tooling | data |                     │
│    business-rule | organisational                                 │
│                                                                   │
│  Output per decision:                                             │
│    source_quote (MANDATORY), title, raised_by,                    │
│    status (accepted|open), type (six-type taxonomy),              │
│    chosen_option (or ""), alternatives (or []),                   │
│    action=create, id_to_assign=DEC-NNN                           │
└───────────────────────┬───────────────────────────────────────────┘
                        │  dec_artifacts (JSON array)
                        ▼
┌───────────────────────────────────────────────────────────────────┐
│  Merge (req + dec + act + risk)                                   │
│  → sara-artifact-sorter Task()                                    │
│    Must pass status, type, chosen_option, alternatives through    │
│    (new passthrough rules needed for decision artifacts)          │
│  → cleaned_artifacts with decision fields intact                  │
└───────────────────────┬───────────────────────────────────────────┘
                        │  approved_artifacts (after user loop)
                        ▼
┌───────────────────────────────────────────────────────────────────┐
│  sara-update Step 2 — decision create branch (REWRITTEN)          │
│                                                                   │
│  Reads .sara/templates/decision.md (v2.0)                        │
│  Writes frontmatter:                                              │
│    id, title, status (from extraction), summary, type,            │
│    date, deciders, supersedes, source, schema_version='2.0',     │
│    tags, related                                                  │
│  Removes: context, decision, rationale, alternatives-considered   │
│                                                                   │
│  Writes body (five sections):                                     │
│    ## Source Quote  (verbatim + stakeholder attribution)         │
│    ## Context       (synthesised from source + discussion_notes) │
│    ## Decision      (from chosen_option; or "No decision reached" │
│                      if status=open)                              │
│    ## Alternatives Considered (from alternatives field; expanded) │
│    ## Rationale     (synthesised from source + discussion_notes) │
└───────────────────────────────────────────────────────────────────┘
```

### Recommended File Edit Scope

```
.claude/skills/
├── sara-extract/SKILL.md     # Step 3 decisions pass block ONLY — replaced in full
├── sara-update/SKILL.md      # Step 2 decision create branch + update branch (body + frontmatter)
└── sara-init/SKILL.md        # Step 12 decision.md template (full replace) + Step 9 CLAUDE.md schema block

.claude/agents/
└── sara-artifact-sorter.md   # Minimal edit — add decision-specific fields to output schema +
                              # passthrough rules for status, type, chosen_option, alternatives
```

### Pattern 1: Two-Signal Decision Detection

**What:** The decisions pass uses two disjoint phrase categories to detect decisions and simultaneously assign status. This is the decision-domain equivalent of the modal-verb anchoring used for requirements.

**When to use:** Decision extraction — replaces the vague "deliberate choice concluded" heuristic.

**Extended artifact schema (updated decisions pass output):**
```json
{
  "action": "create",
  "type": "decision",
  "id_to_assign": "DEC-NNN",
  "title": "...",
  "source_quote": "...",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "",
  "status": "accepted",
  "type_classification": "architectural",
  "chosen_option": "Use PostgreSQL for all persistence",
  "alternatives": ["SQLite", "MongoDB"]
}
```

Note: The artifact field name for decision type is **not** `dec_type` — the CONTEXT.md uses `type` throughout. However, `type` is already taken in the artifact envelope to mean the entity class (requirement/decision/action/risk). See Pitfall 1 for the field naming resolution.

[VERIFIED: 09-CONTEXT.md D-04, D-06 — field list and type taxonomy]

### Pattern 2: v2.0 Frontmatter Shape (Decisions)

**What:** The decision wiki page frontmatter removes four narrative fields and adds `type`. `status` shifts from always-`proposed` to extraction-driven.

**Full v2.0 shape (from CONTEXT.md D-07 through D-10):**
```yaml
---
id: DEC-NNN
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""       # DEC: options considered, chosen option, status, decision date
type: architectural  # architectural | process | tooling | data | business-rule | organisational
date: ""
deciders: []
supersedes: ""
source: []
schema_version: '2.0'
tags: []
related: []
---
```

**v1.0 → v2.0 delta:**
- REMOVED: `context`, `decision`, `rationale`, `alternatives-considered` (narrative frontmatter fields)
- ADDED: `type` (six-value taxonomy)
- CHANGED: `status` default from `"proposed"` to `"accepted"` or `"open"` (extraction-driven)
- CHANGED: `schema_version` from `"1.0"` to `'2.0'` (single-quoted, YAML float prevention)

[CITED: 09-CONTEXT.md D-07 through D-10]

### Pattern 3: Open vs Accepted Decision Body Handling

**What:** The two status values drive different content in the `## Decision` and `## Alternatives Considered` body sections.

**Accepted decision:**
- `## Decision`: Write `chosen_option` content (the option that was selected)
- `## Alternatives Considered`: List from `alternatives` extraction field, expanded with synthesis

**Open decision (misalignment):**
- `## Decision`: Write "No decision reached — alignment required."
- `## Alternatives Considered`: List the competing positions detected in the source

**Pattern (D-12):**
```markdown
## Decision

No decision reached — alignment required.

## Alternatives Considered

- Position A: [competing view from source]
- Position B: [competing view from source]
```

[CITED: 09-CONTEXT.md D-12]

### Pattern 4: Source Quote Attribution (Decisions)

**What:** The Source Quote section in decision pages uses the same wikilink attribution pattern as requirements pages — `[[STK-NNN|Stakeholder Name]]`.

**Format (from CONTEXT.md D-11):**
```markdown
## Source Quote
> [exact verbatim passage from source document] — [[STK-NNN|Stakeholder Name]]
```

This differs slightly from the existing sara-update `decision` body pattern which places the source quote inside `## Context` as `> "{artifact.source_quote}" — {stakeholder_name}`. The v2.0 body promotes the source quote to its own top-level section (matching the requirements v2.0 pattern).

[VERIFIED: 09-CONTEXT.md D-11; sara-update SKILL.md lines 205–222 (current v1.0 decision body)]

### Anti-Patterns to Avoid

- **Using `type` for both entity class and decision taxonomy:** The artifact envelope uses `type` to mean the entity class (`decision`, `requirement`, etc.). The decision-specific taxonomy must use a distinct field name in the JSON artifact. See Pitfall 1.
- **Modifying the sorter dedup logic:** The sorter's deduplication and create-vs-update resolution does not change. Only the output schema example and passthrough rules need updating.
- **Setting `status: proposed` in sara-update:** The decision create branch currently hardcodes `status = "proposed"`. Post-phase it must read `artifact.status` (which will be `"accepted"` or `"open"` from the extraction pass).
- **Leaving narrative frontmatter fields in the template:** `context`, `decision`, `rationale`, `alternatives-considered` must be completely removed from `.sara/templates/decision.md` and the CLAUDE.md schema block — not left as empty strings.
- **Bumping schema_version on non-decision templates:** Action, risk, and stakeholder templates are not changed in this phase.
- **Using Bash shell text-processing for wiki page body writes:** All wiki page writes use the Write tool only, as established.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting commitment vs misalignment language | Custom classifier or regex | Inline LLM prompt with explicit phrase lists for each signal | Extraction is already LLM-driven; the prompt is the signal source |
| Synthesising Context and Rationale sections | Separate extraction artifact | sara-update synthesis from source doc + discussion notes (D-05) | Consistent with established synthesis pattern; avoids overfitting extraction to in-document phrasing |
| Writing decision body sections | Shell template fill | In-memory assembly + Write tool | Established pattern: all wiki writes use Write tool only |

**Key insight:** This phase is prompt engineering and template editing. The "logic" lives in the LLM instructions inside the skill files — the same architecture as Phase 8.

---

## Sorter Compatibility Analysis

**Current sorter output_format for decisions:**

```json
{
  "action": "update",
  "type": "decision",
  "existing_id": "DEC-003",
  "title": "Title of existing decision",
  "source_quote": "Exact verbatim text...",
  "raised_by": "STK-NNN",
  "related": ["REQ-005"],
  "change_summary": "Add new context from this source document"
}
```

[VERIFIED: sara-artifact-sorter.md output_format — direct file read]

**Problem:** The sorter output_format decision example shows no decision-specific fields. After the decisions pass adds `status`, `type_classification` (or equivalent — see Pitfall 1), `chosen_option`, and `alternatives`, the sorter must pass these through unchanged.

The sorter currently has a passthrough rule only for requirement fields:
> "For requirement artifacts, preserve `priority` and `req_type` exactly as received from the extraction pass."

**Required fix:** Add a parallel rule for decision artifacts. Add the four decision-specific fields to the decision object example in the sorter's `<output_format>` section. The same passthrough-only principle applies — the sorter does not classify or validate decision-specific fields.

**Scope impact:** Minimal edit to `sara-artifact-sorter.md` (add fields to create example object + passthrough rule for decision artifacts).

---

## Field Naming: The `type` Collision

The artifact envelope uses `type` to signal the entity class (`"decision"`, `"requirement"`, etc.). The extraction pass also needs to communicate the *decision taxonomy type* (architectural, process, tooling, etc.).

**Conflict:** Two meanings of `type` in the same JSON object would create ambiguity.

**Resolution from CONTEXT.md code_context:** The CONTEXT.md `code_context` section says sara-update's entity write loop "already handles type-specific field mapping (e.g. `req_type`, `priority` for requirements) — same pattern extended for `type` and `status` on decision artifacts." This implies the decision taxonomy field is named differently from the envelope `type`.

Looking at the Phase 8 precedent: the requirement taxonomy is stored as `req_type` in the artifact JSON (not `type`). Following this exact pattern, the decision taxonomy should be stored as a named field that does not collide with the envelope `type` field. The CONTEXT.md refers to it simply as `type` in the frontmatter schema — but that is the *frontmatter* field, not the artifact JSON field.

**Recommended naming (Claude's discretion area — must be consistent across extract/sorter/update):**
- In the **artifact JSON**: use `decision_type` or `dec_type` (following the `req_type` precedent)
- In the **wiki page frontmatter**: use `type` (as specified in CONTEXT.md D-09)
- sara-update maps artifact `dec_type` → frontmatter `type`, exactly as it maps artifact `req_type` → frontmatter `type` for requirements

This naming must be consistent across all three modified files: sara-extract (produces the field), sara-artifact-sorter (passes it through), and sara-update (reads it and maps to frontmatter).

[VERIFIED: sara-extract SKILL.md — `req_type` precedent in requirements pass; sara-update SKILL.md — `type` = `artifact.req_type` for requirement artifacts]
[ASSUMED: The planner will use `dec_type` as the artifact JSON field name. If `chosen_option`-style naming is preferred (e.g. `decision_type`), it is equally valid — what matters is consistency across all three files.]

---

## Current Decision Body Structure vs v2.0

The current sara-update decision body (v1.0) places the source quote at the top of `## Context`:

```markdown
## Context
> "{artifact.source_quote}" — {stakeholder_name}

{synthesised context}

## Decision
{synthesised decision}

## Rationale
{synthesised rationale}

## Alternatives Considered
{synthesised alternatives}
```

The v2.0 body (D-11) promotes `## Source Quote` to its own first section:

```markdown
## Source Quote
> [verbatim passage] — [[STK-NNN|Stakeholder Name]]

## Context
[synthesised — NOT extracted]

## Decision
[chosen_option content]

## Alternatives Considered
[alternatives list]

## Rationale
[synthesised — NOT extracted]
```

**Key differences:**
1. Source Quote moves from inside `## Context` to its own top-level `## Source Quote` section
2. `## Context` and `## Rationale` are now pure synthesis (not mixed with source quote)
3. `## Decision` is populated from `chosen_option` extraction field (not fully synthesised)
4. `## Alternatives Considered` is populated from `alternatives` extraction field (then expanded)
5. Section order changes: Context → Decision → Alternatives → Rationale (not Context → Decision → Rationale → Alternatives)

[VERIFIED: sara-update SKILL.md lines 205–222 (current v1.0 body); CITED: 09-CONTEXT.md D-11 (v2.0 body)]

---

## Common Pitfalls

### Pitfall 1: `type` Field Name Collision in Artifact JSON
**What goes wrong:** The decisions pass outputs `"type": "decision"` as the entity class envelope field AND needs to output a decision taxonomy value in the same object. If both use the key `"type"`, the taxonomy value overwrites the entity class.
**Why it happens:** The CONTEXT.md refers to the frontmatter field as `type` throughout, which may be conflated with the artifact envelope field.
**How to avoid:** Use a distinct field name for the taxonomy in the artifact JSON (e.g. `dec_type`), consistent with the `req_type` precedent from Phase 8. sara-update then maps artifact `dec_type` → frontmatter `type`, matching the same mapping it does for `req_type` → frontmatter `type` on requirements. This must be documented explicitly in the extraction prompt and the sorter passthrough rule.
**Warning signs:** If the decisions pass output JSON contains `"type": "architectural"` — that is the collision. The artifact envelope type must remain `"type": "decision"`.

### Pitfall 2: sara-update Still Hardcodes `status: proposed`
**What goes wrong:** sara-update Step 2's decision create branch currently hardcodes `status = "proposed"`. Post-phase, status must be read from `artifact.status` (either `"accepted"` or `"open"`).
**Why it happens:** The current write instruction explicitly says `set status = "proposed"` — it will need to be replaced with `set status = artifact.status`.
**How to avoid:** The task that modifies sara-update must replace the hardcoded status line. Verify with grep: `grep "proposed" /home/george/Projects/sara/.claude/skills/sara-update/SKILL.md` should return zero results after the plan executes.
**Warning signs:** If the decision write instruction still mentions `"proposed"` anywhere in the create branch.

### Pitfall 3: Four Narrative Frontmatter Fields Left in Template
**What goes wrong:** `context`, `decision`, `rationale`, `alternatives-considered` remain in the decision template and/or CLAUDE.md schema block. New projects initialised after this phase would have the wrong frontmatter shape.
**Why it happens:** These fields exist in both sara-init Step 12 (the template) and Step 9 (the CLAUDE.md schema block) — two separate edit locations.
**How to avoid:** Both Step 9 and Step 12 in sara-init/SKILL.md must be updated. These are two separate edits in the same file.

### Pitfall 4: Sorter Strips Decision-Specific Fields
**What goes wrong:** The sorter's output_format decision example contains only standard fields. If the sorter reconstructs decision objects from its schema definition, `status`, `dec_type`, `chosen_option`, and `alternatives` would be stripped before reaching the approval loop.
**Why it happens:** The current passthrough rule only covers requirement artifacts (`priority` and `req_type`).
**How to avoid:** Add decision-specific fields to the sorter output_format decision example AND add a parallel passthrough rule: "For decision artifacts, preserve `status`, `dec_type`, `chosen_option`, and `alternatives` exactly as received from the extraction pass."
**Warning signs:** The sorter's `<output_format>` decision example currently shows no decision-specific fields.

### Pitfall 5: `## Context` Body Section Loses the Source Quote
**What goes wrong:** The v1.0 body puts the source quote inside `## Context`. After the rewrite, `## Context` is a pure synthesis section. If the update branch of sara-update is not also updated, updated decision pages will have the source quote inside `## Context` (v1.0 pattern) instead of in `## Source Quote` (v2.0 pattern).
**Why it happens:** The update branch is a separate code path in sara-update Step 2.
**How to avoid:** The update branch must also be updated to write the v2.0 body structure when updating a decision page (consistent with how Phase 8 handled requirement updates).

### Pitfall 6: `schema_version: '2.0'` Single Quotes Dropped
**What goes wrong:** `schema_version: 2.0` is written without quotes, causing YAML parsers to treat it as the float `2.0`.
**Why it happens:** Same pitfall as Phase 8 Pitfall 3.
**How to avoid:** Embed the single-quoted form `'2.0'` explicitly in both the template and the sara-update write instruction. Note the sara-update note currently says `"1.0"` for decisions uses double quotes — the v2.0 upgrade switches decisions to single-quoted style, consistent with requirement schema established in Phase 8.
**Warning signs:** `schema_version: 2.0` (unquoted) or `schema_version: "2.0"` (double-quoted) instead of `schema_version: '2.0'`.

### Pitfall 7: British English Spelling in Type Taxonomy
**What goes wrong:** Type taxonomy value `organisational` (British English) is accidentally written as `organizational` (American English) in one or more of the modified files, creating an inconsistent enum.
**Why it happens:** `organizational` is the more common spelling in US-centric tech tools.
**How to avoid:** The CONTEXT.md `<specifics>` section explicitly flags this: "Type taxonomy uses British English spelling: `organisational` (not `organizational`)." Verify spelling in all three modified files after editing.

### Pitfall 8: `## Context` and `## Rationale` Marked as Extracted (not synthesised)
**What goes wrong:** The extraction prompt includes instructions for the LLM to extract `context` or `rationale` content from the source, causing the extraction artifact to contain these sections.
**Why it happens:** The v1.0 decision body had Context and Rationale as synthesised sections, but the new extraction pass adds more fields. The boundary between "extracted" and "synthesised" must be crystal clear in the prompt.
**How to avoid:** D-05 is explicit: sara-update synthesises `## Context` and `## Rationale` from the full source doc and discussion notes — they are NOT in the extraction artifact. The extraction prompt must not request these fields. Only `source_quote`, `chosen_option`, `alternatives`, `status`, and `dec_type` are extracted.

---

## Code Examples

### Updated Decisions Pass Output (extended schema)

The decisions pass in sara-extract Step 3 should produce objects in this shape. The sorter receives these and must pass all decision-specific fields through.

```json
// Source: 09-CONTEXT.md D-04, D-06 + req_type precedent from Phase 8
{
  "action": "create",
  "type": "decision",
  "id_to_assign": "DEC-NNN",
  "title": "Use PostgreSQL for persistence layer",
  "source_quote": "We agreed to go with PostgreSQL — it fits our existing ops tooling and the team has experience.",
  "raised_by": "STK-001",
  "related": [],
  "change_summary": "",
  "status": "accepted",
  "dec_type": "architectural",
  "chosen_option": "PostgreSQL",
  "alternatives": ["SQLite", "MongoDB"]
}
```

Open/misalignment decision example:

```json
{
  "action": "create",
  "type": "decision",
  "id_to_assign": "DEC-NNN",
  "title": "Deployment environment selection",
  "source_quote": "We need to decide between AWS and Azure — Alice prefers AWS for the existing tooling, but Bob argues Azure aligns better with the client's enterprise agreement.",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "",
  "status": "open",
  "dec_type": "tooling",
  "chosen_option": "",
  "alternatives": ["AWS", "Azure"]
}
```

### Updated Decision Template (v2.0)

The template written by sara-init Step 12 to `.sara/templates/decision.md`:

```markdown
---
id: DEC-000
title: ""
status: accepted  # accepted | open | rejected | superseded
summary: ""  # DEC: options considered, chosen option, status, decision date
type: architectural  # architectural | process | tooling | data | business-rule | organisational
date: ""          # ISO 8601 (e.g. 2026-04-29)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
source: []        # ingest IDs (e.g. [MTG-001])
schema_version: '2.0'
tags: []
related: []
---

## Source Quote
> [exact verbatim passage from source document] — [[STK-NNN|Stakeholder Name]]

## Context

[Synthesised by sara-update: why this decision was needed, background]

## Decision

[The chosen option — or "No decision reached — alignment required." for open decisions]

## Alternatives Considered

[List of alternatives; for open decisions, list competing positions]

## Rationale

[Synthesised by sara-update: why this option was chosen]
```

[CITED: 09-CONTEXT.md D-07 through D-11]

### Signal Phrase Lists (for extraction prompt)

```
COMMITMENT language — these passages ARE decisions → status: accepted
- "we decided to"
- "we chose"
- "we agreed on"
- "we went with"
- "we will use"
- "the approach is"
- "we have decided"
- [similar definitive past/present-tense alignment phrases]

MISALIGNMENT language — these passages ARE decisions → status: open
- Explicit disagreement: "Alice prefers X, but Bob argues Y"
- Unresolved choice: "we need to decide between A and B"
- Competing preferences: "there are two camps — those who want X vs those who want Y"
- "we haven't agreed on"
- "still open"

EXCLUDE — these passages are NOT decisions (do NOT extract them):
- Considerations: "we could use X or Y" (exploring options, not choosing)
- Aspirations: "it would be good to have Z" (desire, no concluded choice)
- Requirements: "the system must support A" (obligation, not a team choice)
```

[CITED: 09-CONTEXT.md D-01 — commitment and misalignment language lists]

### Updated Sorter Decision Object (with passthrough fields)

```json
// Sorter output_format decision object after Phase 9 update
{
  "action": "create",
  "type": "decision",
  "id_to_assign": "DEC-NNN",
  "title": "Short title",
  "source_quote": "Exact verbatim text from source document",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "",
  "status": "accepted",
  "dec_type": "architectural",
  "chosen_option": "The selected option",
  "alternatives": ["Alternative A", "Alternative B"]
}
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting commitment vs misalignment language | Custom NLP classifier | Inline LLM prompt with explicit phrase lists for each signal | Extraction is already LLM-driven; prompt is the signal source |
| Synthesising Context/Rationale | Separate extraction field | sara-update synthesis from full source + discussion_notes (D-05) | Avoids hallucination; grounded in full document context available in sara-update |
| Writing decision body | Shell template | In-memory assembly + Write tool | Established pattern |

---

## State of the Art

| Old Approach | Current Approach | Changed In | Impact |
|--------------|-----------------|------------|--------|
| Vague decision signal ("deliberate choice concluded") | Two-signal detector (commitment vs misalignment) with explicit phrase lists | Phase 9 | Higher precision; captures open/contested decisions as first-class artifacts |
| `status: proposed` as default for all new decisions | `status: accepted` or `status: open` from extraction pass | Phase 9 | Status reflects the source material; no manual status update needed post-extraction |
| Narrative frontmatter fields (context, decision, rationale, alternatives-considered) | Frontmatter is metadata only; narrative lives in body sections | Phase 9 | Eliminates duplication; frontmatter stays parseable/query-friendly |
| No type taxonomy for decisions | 6-type classification inline | Phase 9 | Enables filtering decisions by category; mirrors requirement type taxonomy pattern |
| Body: Context (with source quote) → Decision → Rationale → Alternatives | Body: Source Quote → Context → Decision → Alternatives Considered → Rationale | Phase 9 | Source quote is first-class; Context and Rationale are clearly synthesis not extraction |
| schema_version: "1.0" | schema_version: '2.0' | Phase 9 | Enables future tooling to distinguish pre/post-Phase-9 decision pages |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The decision taxonomy field in the artifact JSON should be named `dec_type` (following the `req_type` precedent) to avoid collision with the envelope `type` field | Field Naming section, Code Examples | If `decision_type` or another name is preferred, it must be consistent across all three modified files — harmless if renamed uniformly |
| A2 | The update branch of sara-update Step 2 should also rewrite the decision body to v2.0 structure (not just frontmatter fields) | Common Pitfalls (Pitfall 5) | If update branch should preserve existing body structure, the body rewrite only applies to creates |
| A3 | The sorter rebuilds decision artifact objects using only its documented output schema fields, so `status`, `dec_type`, `chosen_option`, and `alternatives` will be dropped unless the sorter schema is updated | Sorter Compatibility Analysis | If sorter passes through unknown fields automatically, the sorter edit is unnecessary but harmless |

---

## Open Questions

1. **`dec_type` vs `decision_type` field naming**
   - What we know: `req_type` was chosen for requirements (not `requirement_type`); CONTEXT.md does not name the artifact JSON field explicitly
   - What's unclear: Whether the executor should follow `req_type` → `dec_type` convention strictly or use a more readable name
   - Recommendation: Use `dec_type` for consistency with `req_type` precedent. Document it in the extraction prompt output schema and sorter rules.

2. **Negative examples in extraction prompt**
   - What we know: Phase 8 required at least three named negative examples in the requirements prompt; CONTEXT.md D-01/D-02 for decisions marks exact wording as Claude's discretion
   - What's unclear: How many negative examples and of what type
   - Recommendation: Include at least three negative examples covering: (a) option exploration without choosing, (b) requirement/obligation language, (c) aspiration/wish. This follows the Phase 8 pattern.

3. **Summary field content for `open` decisions**
   - What we know: `summary` is generated by sara-update with type-specific content rules; DEC summary is "options considered, chosen option/recommendation, status, decision date"
   - What's unclear: The "chosen option" part of the DEC summary rule is N/A for `status: open` decisions
   - Recommendation: For `open` decisions, sara-update generates the summary as: "competing options/positions, alignment not reached, status: open, decision date". The planner should add this variant to the sara-update decision create branch instructions.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely skill-file edits with no external tool dependencies. No npm packages, databases, or CLI tools required beyond what is already established (git, Write/Read/Edit tools).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test suite in this project) |
| Config file | None |
| Quick run command | Read modified SKILL.md files and confirm changes match CONTEXT.md decisions |
| Full suite command | End-to-end verification: run `/sara-extract` against a test fixture containing commitment and misalignment language; inspect approved artifact list for `status`, `dec_type`, `chosen_option`, `alternatives`; run `/sara-update` and inspect the written decision wiki page |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| D-01 | Two-signal detection (commitment → accepted; misalignment → open) | Manual — LLM prompt review | Read sara-extract SKILL.md, confirm both signal lists present in decisions pass | ❌ Wave 0 |
| D-02 | `proposed` removed as initial status value | Manual — file inspection | `grep "proposed" .claude/skills/sara-update/SKILL.md` — should return zero results in decision create branch | ❌ Wave 0 |
| D-03 | Extraction pass sets `status` in artifact JSON | Manual — artifact inspection | Run `/sara-extract` on test fixture; inspect `status` field in approval loop output | ❌ Wave 0 |
| D-04 | `source_quote`, `chosen_option`, `alternatives` captured per artifact | Manual — artifact inspection | Inspect approved artifact display in the loop; confirm three fields present | ❌ Wave 0 |
| D-05 | Context and Rationale are synthesised by sara-update, not extracted | Manual — prompt review | Read decisions pass prompt; confirm no `context` or `rationale` extraction fields |  ❌ Wave 0 |
| D-06 | Six-type classification assigned inline | Manual — artifact inspection | Inspect `dec_type` field in approval loop output | ❌ Wave 0 |
| D-07/D-10 | `schema_version: '2.0'` and `status` from extraction in written pages | Manual — file inspection | Read a written DEC-NNN.md; confirm `schema_version: '2.0'` (single-quoted), `status` is `accepted` or `open` | ❌ Wave 0 |
| D-08 | Narrative frontmatter fields removed | Manual — file inspection | Grep for `context:`, `decision:`, `rationale:`, `alternatives-considered:` in written DEC-NNN.md frontmatter — should return zero results | ❌ Wave 0 |
| D-09 | `type` frontmatter field present with correct taxonomy value | Manual — file inspection | Read written DEC-NNN.md frontmatter; confirm `type:` has one of the six values | ❌ Wave 0 |
| D-11 | Five-section body structure (Source Quote, Context, Decision, Alternatives, Rationale) | Manual — file inspection | Inspect body of written DEC-NNN.md; confirm all five section headings present in correct order | ❌ Wave 0 |
| D-12 | Open decision body: "No decision reached" + competing positions | Manual — file inspection | Write a test fixture with misalignment language; confirm `## Decision` text and `## Alternatives Considered` content | ❌ Wave 0 |
| Sorter | Decision-specific fields survive sorter passthrough | Manual — sorter output inspection | Inspect `cleaned_artifacts` output; confirm `status`, `dec_type`, `chosen_option`, `alternatives` present | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Read the modified skill file; confirm changed section matches the decision from CONTEXT.md
- **Per wave merge:** Not applicable (no automated test runner)
- **Phase gate:** End-to-end run of `/sara-extract` + `/sara-update` on a synthetic source document containing both commitment language (clear decision) and misalignment language (contested decision), before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] Test fixture document: a synthetic meeting transcript containing at least one commitment-language decision and one misalignment-language decision (to verify both status code paths)
- [ ] Verification checklist: document exact inspection steps for each decision (file fields to check, sections to confirm, grep commands)

*(If no gaps: "None — existing test infrastructure covers all phase requirements")*

---

## Security Domain

This phase modifies only LLM prompt text and YAML/markdown templates. No authentication, data handling, cryptography, or access control is involved. Security domain: NOT APPLICABLE.

---

## Sources

### Primary (HIGH confidence)

- `.planning/phases/09-refine-decisions/09-CONTEXT.md` — All locked decisions D-01 through D-12
- `.claude/skills/sara-extract/SKILL.md` — Current decisions pass prompt (Step 3); sorter dispatch interface; artifact schema
- `.claude/skills/sara-update/SKILL.md` — Step 2 decision create branch; current body structure; wikilink rule; hardcoded `status: proposed`
- `.claude/skills/sara-init/SKILL.md` — Step 9 (CLAUDE.md decision schema block) and Step 12 (decision.md template) — current v1.0 template shape
- `.claude/agents/sara-artifact-sorter.md` — Current output schema; decision object example; existing passthrough rules
- `.planning/phases/08-refine-requirements/08-RESEARCH.md` — Phase 8 research; canonical reference for the two-track pattern this phase mirrors
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — Phase 8 decisions; sorter fix precedent; `req_type` field naming precedent

### Secondary (MEDIUM confidence)

- `.planning/STATE.md` — YAML quoting rule (`schema_version` as quoted string) — established in Phase 1
- `.planning/phases/08-refine-requirements/08-01-PLAN.md` — Three-plan structure reference; task structure for extraction + sorter fix pattern

### Tertiary (LOW confidence)

None — all findings verified from codebase.

---

## Metadata

**Confidence breakdown:**

- Locked decisions: HIGH — all read from 09-CONTEXT.md
- Current skill file shapes: HIGH — all verified by direct file reads
- Sorter compatibility gap: HIGH — confirmed by reading sorter output_format section (no decision-specific fields present)
- Field naming convention (`dec_type`): MEDIUM — inferred from Phase 8 `req_type` precedent; not explicitly stated in CONTEXT.md
- Validation approach: MEDIUM — no automated test infrastructure exists; manual verification is the established pattern for this project

**Research date:** 2026-04-29
**Valid until:** Stable until any of the three modified SKILL.md files or the sorter agent are edited by another phase
