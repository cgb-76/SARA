# Phase 8: refine-requirements — Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 4 (3 modified skill files + 1 agent verified for compatibility)
**Analogs found:** 4 / 4 — all files are modifications of existing files; no new files created

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-extract/SKILL.md` (Step 3 requirements pass) | skill / LLM prompt | transform (document → artifact JSON) | `.claude/skills/sara-extract/SKILL.md` decisions/actions/risks passes (Steps 3b–3d) | exact — same file, parallel passes |
| `.claude/skills/sara-init/SKILL.md` (Step 9 CLAUDE.md block + Step 12 template) | skill / template writer | config / template emit | `.claude/skills/sara-init/SKILL.md` decision.md and risk.md templates in Step 12 | exact — same file, sibling templates |
| `.claude/skills/sara-update/SKILL.md` (Step 2 requirement create + update branches) | skill / wiki writer | CRUD (write + append) | `.claude/skills/sara-update/SKILL.md` Step 2 decision/action/risk branches | exact — same file, sibling branches |
| `.claude/agents/sara-artifact-sorter.md` (`<output_format>` section) | agent / passthrough | transform (JSON → JSON) | `.claude/agents/sara-artifact-sorter.md` existing output schema | exact — same file, field addition only |

---

## Pattern Assignments

### `.claude/skills/sara-extract/SKILL.md` — Step 3 Requirements Pass Rewrite

**What changes:** Replace the current requirements pass prose (lines 53–61) with a new prompt that:
1. Anchors on modal verbs as the primary extraction signal (D-01)
2. Includes negative examples for exclusion (D-02)
3. Maps modal verbs to MoSCoW priority inline (D-03)
4. Classifies each requirement into one of six types inline (D-05)
5. Adds `priority` and `req_type` fields to the output JSON per artifact (D-04)

**Analog — current requirements pass** (lines 52–61 of `sara-extract/SKILL.md`):

```
**Requirements pass**

Extract every passage that describes a requirement — a capability, constraint, or rule that the
system or project must satisfy. For each requirement found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any requirement without a quotable passage)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable from the source or discussion_notes; otherwise use `"STK-NNN"` placeholder
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT resolve create-vs-update — that is the sorter's job

Collect results as `{req_artifacts}` (JSON array; empty array if none found).
```

**Analog — parallel decisions pass** (lines 65–71 of `sara-extract/SKILL.md`) — use as structural model for the opening framing sentence:

```
**Decisions pass**

Extract every passage that describes a decision — a deliberate choice made by the team that was
concluded, not just discussed ("we will use X" is a decision; "we could use X" is not). For each
decision found:
```

**New requirements pass structure to write** (from D-01 through D-05 and RESEARCH.md Pattern 1):

```
**Requirements pass**

A passage IS a requirement if and only if it contains a commitment modal verb or imperative phrase
from the INCLUDE list below. Passages lacking these signals are NOT requirements regardless of topic.

  INCLUDE — these passages ARE requirements (extract them):
  - "must", "shall", "has to", "required to", "need to" → priority: must-have
  - "will" (as commitment, not future tense narration) → priority: must-have
  - "should" → priority: should-have
  - "could", "may" → priority: could-have
  - "will not", "won't", "out of scope", "we won't" → priority: wont-have

  EXCLUDE — these passages are NOT requirements (do NOT extract them):
  - Observation: "Users are currently frustrated with slow load times" (describes a situation, no commitment)
  - Aspiration/wish: "It would be great if the system handled more users" (desire, no modal commitment)
  - Background context: "The company processes approximately 10,000 invoices per month" (descriptive fact only)

For each requirement found, assign one of six types inline based on what the requirement describes:
  - `functional`     — capability the system performs
  - `non-functional` — quality attributes and design constraints (performance, reliability, usability, security, scalability)
  - `regulatory`     — external law, standards, or mandates (GDPR, PCI-DSS, etc.) — external only, not internal policy
  - `integration`    — how the system connects to external systems, APIs, or people
  - `business-rule`  — domain logic or process policy
  - `data`           — structure, retention, quality, or ownership rules for data

For each requirement found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — skip any requirement without a quotable passage)
- Write a short (≤10 words) noun-phrase `title`
- Set `raised_by` to the STK-NNN ID if identifiable from the source or discussion_notes; otherwise use `"STK-NNN"` placeholder
- Set `priority` to the MoSCoW value derived from the commitment modal (see INCLUDE list above)
- Set `req_type` to one of the six types above
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`, `related` = `[]`, `change_summary` = `""`
- Do NOT resolve create-vs-update — that is the sorter's job

Collect results as `{req_artifacts}` (JSON array; empty array if none found).
```

**Output JSON schema** (new — two fields added, from RESEARCH.md Pattern 1):

```json
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

**Position in file:** Step 3, between the `**Step 3 — Inline extraction passes and sorter**` header and the `**Decisions pass**` block. The rewrite replaces the `**Requirements pass**` block in its entirety. All other Step 3 content (decisions, actions, risks passes; merge and sorter dispatch) is unchanged.

---

### `.claude/skills/sara-init/SKILL.md` — Step 9 CLAUDE.md Requirement Block + Step 12 Template

**What changes:**

**Edit A — Step 9 CLAUDE.md Requirement schema block** (lines 187–208 of `sara-init/SKILL.md`):

Replace the current `### Requirement` schema block inside the CLAUDE.md write string with the v2.0 shape. The surrounding CLAUDE.md content (Behavioral Rules, other entity schemas, GSD Phase Completion section) is unchanged.

**Current Requirement block in Step 9** (lines 187–208):

```yaml
### Requirement

```yaml
---
id: REQ-000
title: ""
status: open  # open | accepted | rejected | superseded
summary: ""  # REQ: title, status, one-line description of what is required
source: ""     # ingest ID (e.g. MTG-001)
raised-by: ""  # stakeholder ID (e.g. STK-001)
owner: ""      # stakeholder ID (e.g. STK-001)
schema_version: "1.0"
tags: []
related: []    # entity IDs (e.g. [DEC-001, ACT-002])
---

## Description

## Acceptance Criteria

## Notes
```
```

**New Requirement block for Step 9** (v2.0 shape from D-06 through D-09, RESEARCH.md Pattern 2):

```yaml
### Requirement

```yaml
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
```

Body follows the structured section format (Source Quote, Statement, User Story, Acceptance Criteria,
BDD Criteria, Context, Cross Links). Which sections are required/optional/omitted depends on `type` —
see `.sara/templates/requirement.md` for the section matrix and rationale.
```

**Note on `schema_version` quoting:** The Step 9 CLAUDE.md prose block currently uses `"1.0"` (double quotes). The v2.0 template MUST use `'2.0'` (single quotes). The RESEARCH.md Pattern 2 note confirms: single quotes prevent YAML float parsing. Both the Step 9 block and Step 12 template must use `schema_version: '2.0'` with single quotes.

---

**Edit B — Step 12 `.sara/templates/requirement.md`** (lines 354–375 of `sara-init/SKILL.md`):

**Current template** (lines 357–375):

```markdown
---
id: REQ-000
title: ""
status: open  # open | accepted | rejected | superseded
summary: ""  # REQ: title, status, one-line description of what is required
source: ""     # ingest ID (e.g. MTG-001)
raised-by: ""  # stakeholder ID (e.g. STK-001)
owner: ""      # stakeholder ID (e.g. STK-001)
schema_version: "1.0"
tags: []
related: []    # entity IDs (e.g. [DEC-001, ACT-002])
---

## Description

## Acceptance Criteria

## Notes
```

**New template** (v2.0 from D-06 through D-11, RESEARCH.md Code Examples):

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

<!-- Section matrix — which sections are required (✓), optional (opt), or omitted (—) per type:

| Section             | Functional | Non-functional | Regulatory | Integration | Business rule | Data |
|---------------------|:----------:|:--------------:|:----------:|:-----------:|:-------------:|:----:|
| Source Quote        |     ✓      |       ✓        |     ✓      |      ✓      |       ✓       |  ✓   |
| Statement           |     ✓      |       ✓        |     ✓      |      ✓      |       ✓       |  ✓   |
| User Story          |     ✓      |      opt       |     —      |     opt     |       —       |  —   |
| Acceptance Criteria |     ✓      |       ✓        |     ✓      |      ✓      |       ✓       |  ✓   |
| BDD Criteria        |     ✓      |       —        |     —      |     opt     |       ✓       |  —   |
| Context             |    opt     |       ✓        |     ✓      |      ✓      |       ✓       |  ✓   |
| Cross Links         |     ✓      |       ✓        |     ✓      |      ✓      |       ✓       |  ✓   |

Rationale:
- User Story on Non-functional: optional — usability NFRs have a natural user role, but performance/security/reliability NFRs usually don't map to a role/benefit framing.
- User Story on Integration: optional — integration requirements can have a user-facing perspective (e.g. a developer consuming an API) but often don't.
- User Story omitted on Regulatory/Business rule/Data: compliance mandates and policy rules are not user goals; forcing a user story produces artificial framing.
- BDD on Business rule: required — business rules are where Gherkin is most natural ("Given an invoice is unapproved, When payment is attempted, Then reject with error").
- BDD on Integration: optional — can work well for API contract verification but not always natural (e.g. authentication handshake sequences).
- BDD omitted on Non-functional/Regulatory/Data: non-functionals are measured, not triggered by user actions; regulatory and data requirements are compliance checklists, not behaviour scenarios.
- Context on Functional: optional — usually self-evident from Source Quote + Statement; include only when there is non-obvious rationale or design constraint.
- Context required on all other types: why a quality target, mandate, integration contract, domain rule, or data policy exists is rarely obvious from the statement alone.
-->

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
[One wiki link per related[] entry — see wikilink rule in sara-update SKILL.md]
```

**Analog for template structure:** `.sara/templates/decision.md` (lines 379–404 of sara-init/SKILL.md) — same Write-tool-per-file pattern, same frontmatter conventions (`schema_version`, `tags: []`, `related: []`).

---

### `.claude/skills/sara-update/SKILL.md` — Step 2 Requirement Create + Update Branches

**What changes:**

**Edit A — Requirement create branch body sections** (lines 144–163 of `sara-update/SKILL.md`):

Replace the current `requirement:` body block with the new v2.0 structured sections, written per the section matrix (D-10, D-11).

**Current requirement create branch body** (lines 145–163):

```
**requirement:**
```
## Description
> "{artifact.source_quote}" — {stakeholder_name}

{synthesised summary of what this requirement captures, why it matters, and any constraints
 resolved during /sara-discuss}

## Acceptance Criteria
{REQUIRED — derive at least one testable criterion directly from the requirement text,
 even if the source does not state it explicitly. Infer what "done" looks like for this
 requirement based on its title and source_quote. Format as a markdown checklist:
 - [ ] {criterion}
 Add further criteria for any conditions or constraints found in source or discussion notes.}

## Notes
{synthesised caveats, dependencies, open questions, or related context from discussion
 notes — leave empty if none available}
```
```

**New requirement create branch body** (from D-10, D-11, D-12 and RESEARCH.md Patterns 3 and 4):

```
**requirement:**
```
## Source Quote
> "{artifact.source_quote}" — [[{artifact.raised_by}|{stakeholder_name}]]

## Statement
{synthesise a precise "The [subject] shall [verb phrase]." statement from the source_quote and
 discussion_notes. Use the commitment modal from the source to determine strength.}

## User Story
{Omit if req_type is regulatory, business-rule, or data.
 Write if req_type is functional.
 Write if req_type is non-functional or integration AND a user-facing perspective is natural.
 Format: "As a [role], I want [capability], so that [benefit]."
 If omitting, leave this section header absent entirely — do not write an empty heading.}

## Acceptance Criteria
{REQUIRED for all types — derive at least one testable criterion from the source_quote.
 Infer what "done" looks like from the title and source_quote. Format as markdown checklist:
 - [ ] {criterion}
 Add further criteria for conditions or constraints from source or discussion_notes.}

## BDD Criteria
{Omit if req_type is non-functional, regulatory, or data.
 Write one happy-path Gherkin scenario if req_type is functional or business-rule.
 Write if req_type is integration AND an API contract scenario is natural.
 Add additional scenarios only when the requirement explicitly has distinct named edge cases.
 Format:
 **Scenario: [name]**
 Given [context]
 When [action]
 Then [outcome]
 If omitting, leave this section header absent entirely — do not write an empty heading.}

## Context
{Optional for functional — include only when there is non-obvious rationale or design constraint.
 Required for non-functional, regulatory, integration, business-rule, and data types.
 Write rationale, background, or constraints not captured in Statement or Source Quote.
 Leave empty (heading only) if nothing relevant is available.}

## Cross Links
{One wiki link per entry in artifact.related. Resolve display text per wikilink rule:
 - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name
 - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
 Write heading only (no content) if artifact.related is empty — this is the established heading-only pattern.}
```
```

**Analog — decision create branch body** (lines 165–184 of `sara-update/SKILL.md`) — same structural pattern (section headings, synthesised prose, empty-heading convention):

```
**decision:**
```
## Context
> "{artifact.source_quote}" — {stakeholder_name}

{synthesised summary of the situation or problem that prompted this decision, drawn from
 the source document and discussion notes}

## Decision
{synthesised statement of what was decided...}

## Rationale
{synthesised explanation of why this decision was made...}

## Alternatives Considered
{synthesised list of alternatives...}
```
```

---

**Edit B — Requirement update branch** (lines 220–231 of `sara-update/SKILL.md`):

The update branch currently reads the existing file and applies `change_summary`. Per D-06 ("written or updated after this phase") and RESEARCH.md Pitfall 4 recommendation, the update branch must also rewrite the body to v2.0 structure when updating a requirement.

**Add to the update branch instructions** (after the existing `Apply artifact.change_summary` sentence):

```
For requirement artifacts (artifact.type == "requirement"): after applying change_summary to
frontmatter fields, also rewrite the full body to the v2.0 structured section format (Source Quote,
Statement, User Story, Acceptance Criteria, BDD Criteria, Context, Cross Links) using the same
synthesis rules as the create branch. Synthesise section content from the updated frontmatter,
artifact.source_quote, artifact.change_summary, and {discussion_notes}. Apply the section matrix
(per artifact.req_type) to determine which sections to include. Set schema_version = '2.0' in
frontmatter when rewriting any requirement page (update or create).
```

**Analog — update branch summary regeneration** (lines 228 of `sara-update/SKILL.md`) — same "regenerate on update" pattern already established for the `summary` field.

---

### `.claude/agents/sara-artifact-sorter.md` — `<output_format>` Field Addition

**What changes:** Add `priority` and `req_type` fields to the sorter's output schema example and add a passthrough rule. This is a minimal targeted edit — no sorter logic changes.

**Current `<output_format>` requirement object example** (lines 86–96 of `sara-artifact-sorter.md`):

```json
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "Short title",
  "source_quote": "Exact verbatim text from source document",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": ""
}
```

**New requirement object example** (add two fields; all other artifact types unchanged):

```json
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "Short title",
  "source_quote": "Exact verbatim text from source document",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "",
  "priority": "must-have",
  "req_type": "functional"
}
```

**New rule to add to the `Rules:` section** (after line 111):

```
- For requirement artifacts, preserve `priority` and `req_type` exactly as received from the
  extraction pass. Do not modify, reclassify, or drop these fields. Pass them through unchanged
  to `cleaned_artifacts`.
```

**Existing passthrough precedent** (line 114 of `sara-artifact-sorter.md`):

```
- `source_quote` must be preserved verbatim from the specialist agent output — do not modify quotes
```

The pattern is identical: field received from upstream, preserved unchanged, not the sorter's responsibility to validate.

---

## Shared Patterns

### Write Tool — Only Tool for Wiki Page Writes

**Source:** `sara-update/SKILL.md` line 216 + notes line 328
**Apply to:** All requirement page writes in sara-update Step 2 (both create and update branches)

```
Use the Write tool to create {wiki_dir}{assigned_id}.md.
```

Never use Bash shell text-processing (echo, cat, sed, awk) for wiki page content. Cross Links section assembled in-memory as a string and written as part of the full page content via Write tool.

---

### `schema_version` Quoting Rule

**Source:** `sara-update/SKILL.md` notes line 323; `sara-init/SKILL.md` Step 6 (config.json uses `"1.0"` without quotes — note: config.json is not a wiki YAML file)
**Apply to:** All requirement page writes, requirement template (Step 12), CLAUDE.md schema block (Step 9)

```yaml
schema_version: '2.0'
```

Single quotes required. Double quotes are acceptable YAML but single quotes are the established project convention for version strings to prevent YAML float parsing. The current v1.0 uses `"1.0"` in some prose; the new v2.0 must use `'2.0'` with single quotes in all templates and write instructions.

---

### Wikilink Convention

**Source:** `sara-update/SKILL.md` lines 121–132 (Wikilink rule block)
**Apply to:** Cross Links section generation in sara-update Step 2 requirement branch

```
- STK entities: display text = name only → [[STK-001|Rajiwath Patel]]
  Read wiki/stakeholders/{ID}.md to resolve the name.
- REQ / DEC / ACT / RSK entities: display text = {ID} {title} → [[DEC-007|DEC-007 Defer SSO to Phase 3]]
  Read wiki/index.md or the entity page to resolve the title.
- If title/name cannot be resolved: fall back to bare [[ID]]
- Frontmatter fields (raised-by, related, source, owner): plain IDs — wikilink rule applies to body text only
```

---

### Empty Section — Heading-Only Pattern

**Source:** `sara-update/SKILL.md` lines 143–144 ("leave empty if none available")
**Apply to:** Cross Links section when `artifact.related` is empty; Context section for functional requirements when no rationale is available

```
For every section, synthesise content if the source document or discussion notes contain
relevant material. If nothing relevant is available for a section, leave it empty (heading
only). Never fabricate content that is not grounded in {source_doc} or {discussion_notes}.
```

Cross Links with empty `related[]` writes `## Cross Links` heading with no content — consistent with this established pattern.

---

### Prose-First Rule for Body Sections

**Source:** `sara-update/SKILL.md` lines 133–139 (Prose-first rule block)
**Apply to:** All synthesised body sections in the new requirement create/update branch

```
Write synthesised body sections as natural language. Entity references should support the
prose, not replace names or become grammatical subjects.
```

---

## No Analog Found

All files in this phase are modifications of existing files. No new files are created; no analogs are missing.

---

## Metadata

**Analog search scope:** `.claude/skills/`, `.claude/agents/`
**Files read:** 4 (sara-extract/SKILL.md, sara-init/SKILL.md, sara-update/SKILL.md, sara-artifact-sorter.md)
**Pattern extraction date:** 2026-04-29
