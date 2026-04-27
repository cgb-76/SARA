---
name: sara-init
description: "Initialise a new SARA wiki in the current directory"
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

<objective>
Initialise a new SARA wiki in the current directory. Creates the full /raw/ and /wiki/ directory
tree, captures project configuration (name, verticals, departments), writes .sara/config.json and
pipeline-state.json, creates the wiki/CLAUDE.md schema contract, wiki/index.md and wiki/log.md
catalog stubs, and five entity page templates in .sara/templates/.

Run this skill once per project in an empty directory before using any other SARA commands.
</objective>

<process>

**Step 1 — Guard clause**

Run the following Bash command. If it exits non-zero (wiki/ already exists), report the error to
the user and STOP — do not proceed to any further steps.

```bash
if [ -d "wiki" ]; then
  echo "Error: A SARA wiki already exists in this directory (wiki/ found). Aborting — no changes made."
  exit 1
fi
```

If the command succeeds (no wiki/ directory), continue to Step 2.

**Step 2 — Collect project name**

Use AskUserQuestion to ask for the project name:
- header: "Project name"  (12 chars exactly — acceptable)
- question: "What is the name of this project? (used in wiki/CLAUDE.md header)"
- options: []

Capture whatever the user types as `{project_name}`.

**Step 3 — Collect verticals**

Use AskUserQuestion to collect market verticals:
- header: "Verticals"     (9 chars — acceptable)
- question: "List the market verticals for this project, separated by commas (e.g. Residential, Enterprise, Wholesale)"
- options: ["Residential, Enterprise, Wholesale"]

The user may select the preset option or type their own comma-separated list directly. Parse the
response by splitting on commas, trimming whitespace from each item, and filtering empty strings.
Store the result as `{verticals_array}` (e.g. ["Residential", "Enterprise", "Wholesale"]).

**Step 4 — Collect departments**

Use AskUserQuestion to collect functional departments:
- header: "Departments"   (11 chars — acceptable)
- question: "List the functional departments for this project, separated by commas (e.g. Sales, Operations, Finance)"
- options: ["Sales, Operations, Finance"]

The user may select the preset option or type their own comma-separated list directly. Parse the
response by splitting on commas, trimming whitespace from each item, and filtering empty strings.
Store the result as `{departments_array}`.

**Step 5 — Create directory tree**

Run the following Bash command to create the full directory structure in a single call:

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

**Step 7 — Write pipeline-state.json**

Use the Write tool to create `pipeline-state.json` at the project root with the following exact
content (no variable substitution needed — all counters start at zero):

```json
{
  "counters": {
    "ingest": { "MTG": 0, "EML": 0, "SLK": 0, "DOC": 0 },
    "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RISK": 0, "STK": 0 }
  },
  "items": {}
}
```

**Step 8 — Write wiki/CLAUDE.md**

Use the Write tool to create `wiki/CLAUDE.md` with the following content. Substitute
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
   `pipeline-state.json`. Read the post-increment value and use it as the new ID (e.g. REQ-001).
5. **Cross-references:** `related` fields must use entity IDs only (e.g. `REQ-001`, `DEC-003`) —
   never file paths, relative links, or Obsidian wiki-links.

## Entity Schemas

### Requirement

```yaml
---
id: REQ-000
title: ""
status: open  # open | accepted | rejected | superseded
description: ""
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

### Decision

```yaml
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
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
description: ""
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: ""     # ingest ID (e.g. MTG-001)
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
id: RISK-000
title: ""
status: open  # open | mitigated | accepted | closed
description: ""
likelihood: ""  # low | medium | high
impact: ""      # low | medium | high
owner: ""       # stakeholder ID (e.g. STK-001)
mitigation: ""
source: ""      # ingest ID (e.g. MTG-001)
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
vertical: ""    # from project config verticals list
department: ""  # from project config departments list
email: ""
role: ""
schema_version: "1.0"
related: []
---
```
```

**Step 9 — Write wiki/index.md**

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

**Step 10 — Write wiki/log.md**

Use the Write tool to create `wiki/log.md` with the following exact content:

```markdown
---
maintained-by: sara
last-updated: ""
---

# Wiki Log

<!-- Append-only. Each entry: ingest ID, date, type, filename, entities created/updated -->
```

**Step 11 — Write entity templates**

Use the Write tool to create each of the five template files in `.sara/templates/`. Write each
file as a separate Write call.

`.sara/templates/requirement.md`:

```markdown
---
id: REQ-000
title: ""
status: open  # open | accepted | rejected | superseded
description: ""
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

`.sara/templates/decision.md`:

```markdown
---
id: DEC-000
title: ""
status: proposed  # proposed | accepted | rejected | superseded
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
description: ""
owner: ""      # stakeholder ID (e.g. STK-001)
due-date: ""   # ISO 8601
source: ""     # ingest ID (e.g. MTG-001)
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
id: RISK-000
title: ""
status: open  # open | mitigated | accepted | closed
description: ""
likelihood: ""  # low | medium | high
impact: ""      # low | medium | high
owner: ""       # stakeholder ID (e.g. STK-001)
mitigation: ""
source: ""      # ingest ID (e.g. MTG-001)
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
vertical: ""    # from project config verticals list
department: ""  # from project config departments list
email: ""
role: ""
schema_version: "1.0"
related: []
---
```

CRITICAL: `vertical` and `department` MUST be two separate fields. Never merge them into a
combined field. Do not add body section headings to `stakeholder.md`.

**Step 12 — Report success**

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
  - `.sara/config.json`
  - `pipeline-state.json`
  - `wiki/CLAUDE.md`
  - `wiki/index.md`
  - `wiki/log.md`
  - `.sara/templates/requirement.md`
  - `.sara/templates/decision.md`
  - `.sara/templates/action.md`
  - `.sara/templates/risk.md`
  - `.sara/templates/stakeholder.md`
- **Next step:** Run `/sara-ingest` to register your first input document.
- **Note:** `/sara-init` does not commit files to git. Use `git add . && git commit` when ready.

</process>

<notes>
- wiki/CLAUDE.md is only automatically loaded by Claude Code when the active file is within the
  wiki/ subtree. Skills operating on files outside wiki/ will not inherit the schema context
  automatically.
- If /sara-init fails partway through (e.g. a permission error after the guard clause passed),
  the wiki/ directory may exist but be incomplete. Recovery: delete the partial output
  (rm -rf wiki/ raw/ .sara/ pipeline-state.json) and re-run /sara-init. The guard clause
  prevents re-init on a live repo but will also block recovery of an incomplete init that left
  wiki/ behind.
- /sara-init does not run git init or commit files. The initialised structure is ready to commit
  but the user must do so. Suggested commit: git add .sara/ pipeline-state.json wiki/ raw/ &&
  git commit -m "chore: initialise SARA wiki structure"
- Ingest types (meeting, email, slack, document) are hardcoded in SARA skill logic. They are NOT
  stored in .sara/config.json. Do not add an ingest-types key to config (per D-05).
- Vertical and department are always separate fields in both .sara/config.json and entity templates.
  Never merge them into a single field (domain constraint — see project memory).
</notes>
