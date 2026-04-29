---
name: sara-init
description: "Initialise a new SARA wiki in the current directory"
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---

<objective>
Initialise a new SARA wiki in the current directory. Creates the full /raw/ and /wiki/ directory
tree, captures project configuration (name, verticals, departments), writes .sara/config.json and
.sara/pipeline-state.json, creates the CLAUDE.md schema contract, wiki/index.md and wiki/log.md
catalog stubs, and five entity page templates in .sara/templates/.

Run this skill once per project in an empty directory before using any other SARA commands.
</objective>

<process>

**Step 0 — Output banner**

Output the following as plain text before doing anything else:

```
   ███████╗ █████╗ ██████╗  █████╗
   ██╔════╝██╔══██╗██╔══██╗██╔══██╗
   ███████╗███████║██████╔╝███████║
   ╚════██║██╔══██║██╔══██╗██╔══██║
   ███████║██║  ██║██║  ██║██║  ██║
   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
   Solution Architecture Recall Assistant

   [Wiki Initialisation...]
```

**Step 1 — Guard clause**

Run the following Bash command silently. If it exits non-zero (wiki/ already exists), report the error to
the user and STOP — do not proceed to any further steps.

```bash
if [ -d "wiki" ]; then
  echo "Error: A SARA wiki already exists in this directory (wiki/ found). Aborting — no changes made."
  exit 1
fi
```

If the command succeeds (no wiki/ directory), continue to Step 2.

**Step 2 — Collect project name**

Output the following question as plain text and wait for the user's reply:

> What is the name of this project?

Capture the user's reply as `{project_name}`.

**Step 3 — Collect verticals**

Output the following question as plain text and wait for the user's reply:

> Provide all market verticals that apply? (eg. Residential, BE\&G, Wholesale)

Capture the user's reply, split on commas, trim whitespace, and store as `{verticals_array}`.

**Step 4 — Collect departments**

Output the following question as plain text and wait for the user's reply:

> What departments are involved in this project? (eg. Sales, Operations, Finance)

Capture the user's reply, split on commas, trim whitespace, and store as `{departments_array}`.

**Step 5 — Create directory tree**

Run the following Bash commands to create the full directory structure and add `.gitkeep` files
so all empty directories are tracked in git:

```bash
mkdir -p \
  raw/input \
  raw/meetings \
  raw/emails \
  raw/slack \
  raw/documents \
  wiki/requirements \
  wiki/decisions \
  wiki/actions \
  wiki/risks \
  wiki/stakeholders \
  .sara/templates

touch \
  raw/input/.gitkeep \
  raw/meetings/.gitkeep \
  raw/emails/.gitkeep \
  raw/slack/.gitkeep \
  raw/documents/.gitkeep \
  wiki/requirements/.gitkeep \
  wiki/decisions/.gitkeep \
  wiki/actions/.gitkeep \
  wiki/risks/.gitkeep \
  wiki/stakeholders/.gitkeep
```

**Step 6 — Write .sara/config.json**

Use the Write tool to create `.sara/config.json` with the following content, substituting
`{project_name}`, `{verticals_array}`, and `{departments_array}` with the values collected in
Steps 2–4. Format the arrays as valid JSON arrays (e.g. ["Residential", "Enterprise"]).

```json
{
  "project": "{project_name}",
  "verticals": {verticals_array},
  "departments": {departments_array},
  "schema_version": "1.0"
}
```

**Step 7 — Write .sara/pipeline-state.json**

Use the Write tool to create `.sara/pipeline-state.json` with the following exact content (no
variable substitution needed — all counters start at zero):

```json
{
  "summary_max_words": 50,
  "counters": {
    "ingest": { "MTG": 0, "EML": 0, "SLK": 0, "DOC": 0 },
    "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RSK": 0, "STK": 0 }
  },
  "items": {}
}
```

**Step 8 — Write .gitignore**

Use the Write tool to create `.gitignore` with the following exact content:

```
# ignore Claude's local settings file
.claude/settings.local.json
```

**Step 9 — Write CLAUDE.md**

Use the Write tool to create `CLAUDE.md` with the following content. Substitute
`{project_name}` with the project name collected in Step 2.

```markdown
# SARA Wiki — Schema & Behavioral Rules

**Project:** {project_name}
**Schema version:** 1.0

This file is automatically loaded by Claude Code when working in any file under `wiki/`.
All SARA pipeline commands that read or write wiki pages must follow the rules below.

## Behavioral Rules

1. **Deduplication:** Before creating any new entity, search `wiki/index.md` for an existing entity
   with the same title or similar description. Propose an update to the existing page rather than
   creating a duplicate.
2. **Index maintenance:** Every entity write (create or update) must also update `wiki/index.md`
   with the new or changed row (ID, title, status, type, tags, last-updated).
3. **Log maintenance:** Every entity write must append an entry to `wiki/log.md` recording the
   ingest ID, date, entity IDs created/updated, and source filename.
4. **ID assignment:** Before assigning a new entity ID, increment the relevant counter in
   `.sara/pipeline-state.json`. Read the post-increment value and use it as the new ID (e.g. REQ-001).
5. **Cross-references:** `related` fields must use entity IDs only (e.g. `REQ-001`, `DEC-003`) —
   never file paths, relative links, or Obsidian wiki-links. In body prose, always use
   `[[ID|ID Title]]` (ID prefix + title or name, e.g. `[[DEC-007|DEC-007 Defer SSO to Phase 3]]`) —
   never a bare `[[ID]]` or raw ID string. Frontmatter fields remain plain IDs.
6. **Summary field:** When writing or updating any wiki artifact, always generate or refresh the
   `summary` field using the type-specific content rules (REQ: title/status/description;
   DEC: options considered/chosen option/status/date; ACT: owner/due-date/status;
   RSK: likelihood/impact/mitigation/status; STK: vertical/department/role) and the
   `summary_max_words` limit from `.sara/pipeline-state.json` (default: 50 words if absent).

## Entity Schemas

### Requirement

```yaml
---
id: REQ-000
title: ""
summary: ""  # REQ: title, status, one-line description of what is required
status: open  # open | accepted | rejected | superseded
type: functional  # functional | non-functional | regulatory | integration | business-rule | data
priority: must-have  # must-have | should-have | could-have | wont-have
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
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

### Decision

```yaml
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
summary: ""  # DEC: options considered, chosen option/recommendation, status, decision date
context: ""
decision: ""
rationale: ""
alternatives-considered: ""
date: ""          # ISO 8601 (e.g. 2026-04-27)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
schema_version: "1.0"
tags: []
related: []
---

## Context

## Decision

## Rationale

## Alternatives Considered
```

### Action

```yaml
---
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

### Risk

```yaml
---
id: RSK-000
title: ""
status: open  # open | mitigated | accepted | closed
summary: ""  # RSK: likelihood, impact, mitigation approach, status
likelihood: ""  # low | medium | high
impact: ""      # low | medium | high
owner: ""       # stakeholder ID (e.g. STK-001)
mitigation: ""
source: []      # list of ingest IDs (e.g. [MTG-001, MTG-003])
schema_version: "1.0"
tags: []
related: []
---

## Description

## Mitigation

## Notes
```

### Stakeholder

```yaml
---
id: STK-000
name: ""
nickname: ""  # colloquial name used in transcript body text (e.g. "Raj" for "Rajiwath")
vertical: ""    # from project config verticals list
department: ""  # from project config departments list
email: ""
role: ""
summary: ""  # STK: vertical, department, role — enough to distinguish from other stakeholders
schema_version: "1.0"
related: []
---
```
```

## GSD Phase Completion

When all plans in a GSD phase have SUMMARY.md files, update these planning docs before moving on — even if execution was interrupted and resumed manually:

1. **ROADMAP.md** — mark all phase plans as `[x]`, update Progress table row to Done
2. **STATE.md** — update `stopped_at`, `completed_phases`, `completed_plans`, `percent`, phase progress table, and current focus
3. **PROJECT.md** — move validated requirements from Active → Validated with phase reference, update Key Decisions outcomes, update `Last updated` footer

These are the steps the GSD `transition.md` workflow would run automatically (`evolve_project` and `update_roadmap_and_state`). If execution was interrupted before reaching them, run them inline before starting the next phase.

```bash
gsd-sdk query commit "docs(phase-{X}): update planning docs after phase completion" .planning/STATE.md .planning/ROADMAP.md .planning/PROJECT.md
```
```

**Step 10 — Write wiki/index.md**

Use the Write tool to create `wiki/index.md` with the following exact content:

```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Index

| ID | Title | Status | Type | Tags | Last Updated |
|----|-------|--------|------|------|--------------|
```

**Step 11 — Write wiki/log.md**

Use the Write tool to create `wiki/log.md` with the following exact content:

```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Log

<!-- Append-only. Each entry: ingest ID, date, type, filename, entities created/updated -->
```

**Step 12 — Write entity templates**

Use the Write tool to create each of the five template files in `.sara/templates/`. Write each
file as a separate Write call.

`.sara/templates/requirement.md`:

```markdown
---
id: REQ-000
title: ""
summary: ""  # REQ: title, status, one-line description of what is required
status: open  # open | accepted | rejected | superseded
type: functional  # functional | non-functional | regulatory | integration | business-rule | data
priority: must-have  # must-have | should-have | could-have | wont-have
source: []     # list of ingest IDs (e.g. [MTG-001, MTG-003])
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

<!-- Section matrix — which sections are required (✓), optional (opt), or omitted (—) per requirement type:

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
- Context required on all other types: why a quality target, mandate, integration contract, domain rule, or data policy exists is rarely obvious from the statement alone; downstream readers need the rationale.
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

`.sara/templates/decision.md`:

```markdown
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
summary: ""  # DEC: options considered, chosen option/recommendation, status, decision date
context: ""
decision: ""
rationale: ""
alternatives-considered: ""
date: ""          # ISO 8601 (e.g. 2026-04-27)
deciders: []      # stakeholder IDs (e.g. [STK-001, STK-002])
supersedes: ""    # DEC-NNN or empty
schema_version: "1.0"
tags: []
related: []
---

## Context

## Decision

## Rationale

## Alternatives Considered
```

`.sara/templates/action.md`:

```markdown
---
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

`.sara/templates/risk.md`:

```markdown
---
id: RSK-000
title: ""
status: open  # open | mitigated | accepted | closed
summary: ""  # RSK: likelihood, impact, mitigation approach, status
likelihood: ""  # low | medium | high
impact: ""      # low | medium | high
owner: ""       # stakeholder ID (e.g. STK-001)
mitigation: ""
source: []      # list of ingest IDs (e.g. [MTG-001, MTG-003])
schema_version: "1.0"
tags: []
related: []
---

## Description

## Mitigation

## Notes
```

`.sara/templates/stakeholder.md` (frontmatter ONLY — no body sections):

```markdown
---
id: STK-000
name: ""
nickname: ""  # colloquial name used in transcript body text (e.g. "Raj" for "Rajiwath")
vertical: ""    # from project config verticals list
department: ""  # from project config departments list
email: ""
role: ""
summary: ""  # STK: vertical, department, role — enough to distinguish from other stakeholders
schema_version: "1.0"
related: []
---
```

CRITICAL: `vertical` and `department` MUST be two separate fields. Never merge them into a
combined field. Do not add body section headings to `stakeholder.md`.

**Step 13 — Report success**

Report success to the user with the following information:

- **Project:** {project_name}
- **Directories created (11):**
  - `raw/input/`
  - `raw/meetings/`
  - `raw/emails/`
  - `raw/slack/`
  - `raw/documents/`
  - `wiki/requirements/`
  - `wiki/decisions/`
  - `wiki/actions/`
  - `wiki/risks/`
  - `wiki/stakeholders/`
  - `.sara/templates/`
- **Files created:**
  - `.gitignore`
  - `.sara/config.json`
  - `.sara/pipeline-state.json`
  - `CLAUDE.md`
  - `wiki/index.md`
  - `wiki/log.md`
  - `.sara/templates/requirement.md`
  - `.sara/templates/decision.md`
  - `.sara/templates/action.md`
  - `.sara/templates/risk.md`
  - `.sara/templates/stakeholder.md`
- **Next step:** Run `/sara-ingest` to register your first input document.

**Step 14 — Commit to git**

Run the following Bash commands to initialise a git repository (if one does not already exist) and
commit all created files:

```bash
git rev-parse --git-dir > /dev/null 2>&1 || git init
git add \
  .gitignore \
  .sara/config.json \
  .sara/pipeline-state.json \
  CLAUDE.md \
  wiki/index.md \
  wiki/log.md \
  wiki/requirements/.gitkeep \
  wiki/decisions/.gitkeep \
  wiki/actions/.gitkeep \
  wiki/risks/.gitkeep \
  wiki/stakeholders/.gitkeep \
  raw/input/.gitkeep \
  raw/meetings/.gitkeep \
  raw/emails/.gitkeep \
  raw/slack/.gitkeep \
  raw/documents/.gitkeep \
  .sara/templates/requirement.md \
  .sara/templates/decision.md \
  .sara/templates/action.md \
  .sara/templates/risk.md \
  .sara/templates/stakeholder.md
git commit -m "chore: initialise SARA — {project_name}"
```

</process>

<notes>
- CLAUDE.md at the project root is automatically loaded by Claude Code for all work in the
  project — all SARA skills inherit the schema and behavioral rules.
- If /sara-init fails partway through (e.g. a permission error after the guard clause passed),
  the wiki/ directory may exist but be incomplete. Recovery: delete the partial output
  (rm -rf wiki/ raw/ .sara/ CLAUDE.md .gitignore) and re-run /sara-init. The guard clause
  prevents re-init on a live repo but will also block recovery of an incomplete init that left
  wiki/ behind.
- Git is managed invisibly — /sara-init initialises the repo if needed and commits all created
  files automatically. Users never need to run git commands manually for SARA operations.
- Ingest types (meeting, email, slack, document) are hardcoded in SARA skill logic. They are NOT
  stored in .sara/config.json. Do not add an ingest-types key to config (per D-05).
- Vertical and department are always separate fields in both .sara/config.json and entity templates.
  Never merge them into a single field (domain constraint — see project memory).
</notes>
