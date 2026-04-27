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
- options: ["My Project", "Enter name"]

If user selects an option or answers with their own text, capture the response as `{project_name}`.
If the response was "Enter name" or any free-form signal, ask for the name as plain text (not
another AskUserQuestion): "Type the project name and press Enter."

**Step 3 — Collect verticals**

Use AskUserQuestion to collect market verticals:
- header: "Verticals"     (9 chars — acceptable)
- question: "List the market verticals for this project, separated by commas (e.g. Residential, Enterprise, Wholesale)"
- options: ["Residential, Enterprise, Wholesale", "My own list", "Skip for now"]

If user selects a preset option, use that string as-is. If user selects "My own list" or any
free-form signal, ask as plain text: "Type your verticals separated by commas."

Parse the response by splitting on commas, trimming whitespace from each item, and filtering empty
strings. Store the result as `{verticals_array}` (e.g. ["Residential", "Enterprise", "Wholesale"]).

If user selected "Skip for now", store `{verticals_array}` as an empty array [].

**Step 4 — Collect departments**

Use AskUserQuestion to collect functional departments:
- header: "Departments"   (11 chars — acceptable)
- question: "List the functional departments for this project, separated by commas (e.g. Sales, Operations, Finance)"
- options: ["Sales, Operations, Finance", "My own list", "Skip for now"]

If user selects a preset option, use that string as-is. If user selects "My own list" or any
free-form signal, ask as plain text: "Type your departments separated by commas."

Parse the response by splitting on commas, trimming whitespace from each item, and filtering empty
strings. Store the result as `{departments_array}`.

If user selected "Skip for now", store `{departments_array}` as an empty array [].

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

<!-- Plan 02 will add Steps 8-10: wiki/CLAUDE.md, wiki/index.md, wiki/log.md, five entity templates, and success report -->

</process>

<notes>
- **Partial init recovery:** If the skill fails mid-way (e.g. permission error after directory creation), the wiki/ directory will exist and the guard clause will prevent re-running. To recover: manually delete the partially created directories (`rm -rf wiki/ raw/ .sara/ pipeline-state.json`) and re-run `/sara-init`.
- **Git commit:** This skill does not run `git init` or commit any files. The initialised files are ready to commit — run `git add .sara/ pipeline-state.json wiki/ raw/` and commit manually, or after Phase 2 setup is complete.
- **wiki/CLAUDE.md scope:** `wiki/CLAUDE.md` is automatically loaded by Claude Code only when working on files within the `wiki/` subtree. Pipeline skills that modify wiki pages must reference a file under `wiki/` to ensure the schema contract is in scope.
- **Vertical vs department:** These are distinct stakeholder axes. A stakeholder has one vertical (market segment) AND one department (functional area). Never merge these into a single field.
</notes>
