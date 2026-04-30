# Phase 12: vertical-awareness - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 6 (all modified, none created)
**Analogs found:** 6 / 6 (all files are their own best analog — modifications are incremental additions to existing patterns)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-extract/SKILL.md` | skill/prompt | transform (extraction pass → JSON artifact) | `.claude/skills/sara-extract/SKILL.md` itself — Phase 10/11 field addition pattern | exact |
| `.claude/skills/sara-update/SKILL.md` | skill/prompt | CRUD (frontmatter write branches) | `.claude/skills/sara-update/SKILL.md` itself — Phase 10/11 field addition pattern | exact |
| `.claude/skills/sara-init/SKILL.md` | skill/prompt | config + template write | `.claude/skills/sara-init/SKILL.md` itself — Phase 10/11 template extension pattern | exact |
| `.claude/skills/sara-add-stakeholder/SKILL.md` | skill/prompt | CRUD (STK page write + config sync) | `.claude/skills/sara-add-stakeholder/SKILL.md` itself — rename `vertical` → `segment` | exact |
| `.claude/skills/sara-lint/SKILL.md` | skill/prompt | batch scan + fix | `.claude/skills/sara-lint/SKILL.md` itself — STK summary rule rename only | exact |
| `.claude/agents/sara-artifact-sorter.md` | agent/prompt | transform (passthrough + question gen) | `.claude/agents/sara-artifact-sorter.md` itself — Phase 11 passthrough field pattern | exact |

---

## Pattern Assignments

### `.claude/skills/sara-extract/SKILL.md` — Track 2: add `segments` to all four extraction passes

**What changes:** Each of the four inline passes (Requirements, Decisions, Actions, Risks) gains a `segments` field in the per-artifact field list. A config.json read is added before the passes begin.

**Analog pattern — field addition per extraction pass** (from the existing risk pass, lines 202–215):
```
For each risk found:
- Extract the exact verbatim passage as `source_quote` (MANDATORY — ...)
- Write a short (≤10 words) noun-phrase `title` ...
- Set `risk_type` to one of the six values above ...
- Set `owner` to the STK-NNN ID ...
- Set `raised_by` to the STK-NNN ID ...
- Set `likelihood` to `"high"`, `"medium"`, or `"low"` ...
- Set `impact` to `"high"`, `"medium"`, or `"low"` ...
- Set `status` based on explicit source language only ...
- Set `action` = `"create"`, `type` = `"risk"`, `id_to_assign` = `"RSK-NNN"`, `related` = `[]`, `change_summary` = `""`
```

**Pattern to copy — `segments` field addition (add this bullet to all four pass field lists):**
```
- Set `segments` to an array of segment name strings (zero or more):
    1. STK attribution: if `source_quote` ends with `— [[STK-NNN|…]]`, read that STK page's
       `segment:` field and add it as the first entry.
    2. Keyword matching: scan the source passage for case-insensitive substrings matching any
       name in `config.segments`; add each match (deduplicated).
    3. Empty fallback: if neither resolves, set `segments` = `[]`.
```

**Analog pattern — config.json read (from sara-add-stakeholder SKILL.md Step 2, line 38–39):**
```
Read `.sara/config.json` using the Read tool. Store the `verticals` array for the Vertical prompt
and the `departments` array for the Dept prompt below.
```

**Pattern to copy — config.json read before Step 3 passes:**
```
Read `.sara/config.json` using the Read tool. Store `config.segments` for use in the `segments`
inference step of each extraction pass below.
```

**Placement:** Insert the config read at the top of Step 3 (before "Requirements pass"). Add the `segments` bullet to the field list in all four passes (Requirements, Decisions, Actions, Risks), immediately before the `action`/`type`/`id_to_assign` line (which always comes last in each field list).

---

### `.claude/skills/sara-update/SKILL.md` — Track 2: write `segments:` frontmatter to all four entity types

**What changes:** Both create and update branches for REQ, DEC, ACT, RSK gain a `segments:` frontmatter write line.

**Analog pattern — adding a new frontmatter field to the create branch** (from Phase 10 addition of `type` and `due-date` to action artifacts, lines 108–109 of current file):
```
- For action artifacts: set `status` = `"open"`, `type` = `artifact.act_type` (one of: `deliverable`,
  `follow-up`), `owner` = `artifact.owner` (STK-NNN or raw name string or `""`), `due-date` =
  `artifact.due_date` (raw string or `""`)
```

**Pattern to copy — `segments:` write rule (add to all four type branches):**
```
- Set `segments` = `artifact.segments` (array of segment name strings; write as flow-style YAML:
  `segments: []` for empty, `segments: [Residential]` for one entry, `segments: [Residential, Enterprise]`
  for two; use block style only if the array has 3+ entries — consistent with `tags`, `related`, `source`)
```

**Analog pattern — update branch field addition** (lines 348–350, requirement update branch):
```
For requirement artifacts (`artifact.type == "requirement"`): after applying the change_summary
to frontmatter fields and regenerating the summary, also update the frontmatter to include
the v2.0 fields from the artifact object:
- Set `type` = `artifact.req_type` ...
- Set `priority` = `artifact.priority` ...
- Set `schema_version` = `'2.0'` ...
```

**Pattern to copy — add segments to each update branch (parallel structure):**
```
- Set `segments` = `artifact.segments` (array; replace existing value if present; write in flow style)
```

**YAML serialisation rule (from CONTEXT.md D-09 and code_context):**
- 0 entries: `segments: []`
- 1–2 entries: `segments: [Residential]` or `segments: [Residential, Enterprise]`  (flow style)
- 3+ entries: block style (consistent with how `tags`, `related` work in existing templates)

**Placement:** Add `segments` write line to all eight locations in the file: four create branches (requirement, decision, action, risk) and four update branches (requirement, decision, action, risk).

**STK summary rule fix** (line 118 — also in sara-update):
```
STK: vertical, department, role — enough to distinguish from other stakeholders
```
Rename `vertical` → `segment` in this comment line.

---

### `.claude/skills/sara-init/SKILL.md` — Track 1: rename `vertical` → `segment`; Track 2: add `segments: []` to entity templates and CLAUDE.md schema

**Track 1 — rename pattern**

All occurrences of `vertical`/`verticals` in the skill file. Exact locations:

1. **Step 3 prompt** (lines 63–68):
   ```
   > Provide all market verticals that apply? (eg. Residential, BE\&G, Wholesale)
   ```
   Replace with:
   ```
   > What segments or customer groups does this project cover? (eg. Residential, BE\&G, Wholesale)
   ```
   Variable name: `{verticals_array}` → `{segments_array}`

2. **Step 6 config.json template** (lines 116–124):
   ```json
   {
     "project": "{project_name}",
     "verticals": {verticals_array},
     "departments": {departments_array},
     "schema_version": "1.0"
   }
   ```
   Replace `"verticals"` → `"segments"` and `{verticals_array}` → `{segments_array}`.

3. **Step 9 CLAUDE.md template — STK schema block** (lines 302–315 of current file):
   ```yaml
   vertical: ""    # from project config verticals list
   ```
   Replace with:
   ```yaml
   segment: ""    # from project config segments list
   ```
   Also update the `summary` comment:
   ```yaml
   summary: ""  # STK: vertical, department, role — ...
   ```
   → `summary: ""  # STK: segment, department, role — ...`

4. **Step 12 stakeholder.md template** (lines 556–569):
   ```yaml
   vertical: ""    # from project config verticals list
   ```
   Replace with:
   ```yaml
   segment: ""    # from project config segments list
   ```
   Also update the CRITICAL note (line 571):
   ```
   CRITICAL: `vertical` and `department` MUST be two separate fields.
   ```
   → `CRITICAL: \`segment\` and \`department\` MUST be two separate fields.`

5. **Notes section** (line 653):
   ```
   Vertical and department are always separate fields in both .sara/config.json and entity templates.
   ```
   → `Segment and department are always separate fields in both .sara/config.json and entity templates.`

**Track 2 — `segments: []` addition pattern**

**Analog — adding a field to existing frontmatter templates** (Phase 10: added `type`, `owner`, `due-date` to action.md template, current lines 476–487):
```yaml
---
id: ACT-000
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

**Pattern to copy — add `segments: []` to all four entity templates in Step 12:**

Add after `related: []` in each of the four entity templates (requirement.md, decision.md, action.md, risk.md):
```yaml
segments: []   # segment names from config.segments (e.g. [Residential, Enterprise])
```

**Add to CLAUDE.md schema blocks (Step 9) for all four entity types:**

In the Requirement schema block, after `related: []`:
```yaml
segments: []   # segment names from config.segments (e.g. [Residential, Enterprise])
```

Repeat the same line in the Decision, Action, and Risk schema blocks at the same relative position (after `related: []`).

---

### `.claude/skills/sara-add-stakeholder/SKILL.md` — Track 1: rename `vertical` → `segment`

**What changes:** Pure find-and-replace of `vertical`/`verticals` throughout the file. No logic changes.

**Exact locations:**

1. **Objective line** (line 14):
   ```
   Capture a stakeholder's details — name (required), plus optional fields: nickname, vertical,
   ```
   → Replace `vertical` with `segment`.

2. **Step 2 — Read config and prompt** (lines 38–57):
   - Variable name: `verticals` → `segments`
   - Comment: `Store the \`verticals\` array for the Vertical prompt` → `Store the \`segments\` array for the Segment prompt`
   - AskUserQuestion header: `"Vertical"` → `"Segment"` (still ≤ 12 chars: "Segment" = 7 chars)
   - AskUserQuestion question: `"Which market vertical?"` → `"Which segment?"` (or `"Which segment does this stakeholder belong to?"`)
   - Options comment: `[values from .sara/config.json verticals array]` → `[values from .sara/config.json segments array]`
   - Capture variable: `{vertical}` → `{segment}`

3. **Step 2b — Sync new values to config** (lines 70–74):
   ```
   If `{vertical}` is non-empty and not already present in `config.verticals`: append `{vertical}`
   to the `verticals` array and write...
   ```
   → `If \`{segment}\` is non-empty and not already present in \`config.segments\`: append \`{segment}\` to the \`segments\` array and write...`

4. **Step 4 — STK wiki page template** (lines 110–123):
   ```yaml
   vertical: "{vertical}"    # from project config verticals list
   ```
   → `segment: "{segment}"    # from project config segments list`
   Also update the summary comment:
   ```yaml
   summary: ""  # STK: vertical, department, role — ...
   ```
   → `summary: ""  # STK: segment, department, role — ...`

5. **Notes section** (lines 166–168):
   ```
   `vertical` (market segment) and the functional area field are ALWAYS written as two separate
   YAML fields — never combined. The functional area field name is `department`.
   ```
   → `\`segment\` (market segment) and the functional area field are ALWAYS written as two separate YAML fields — never combined. The functional area field name is \`department\`.`

   Note on line 175:
   ```
   New verticals and departments entered via "New..." are appended to `.sara/config.json` in Step 2b
   ```
   → `New segments and departments entered are appended to \`.sara/config.json\` in Step 2b...`

---

### `.claude/skills/sara-lint/SKILL.md` — Track 1: rename `vertical` → `segment` in STK summary rule

**What changes:** Single occurrence of `vertical` in the STK summary rule (line 100):
```
- STK: vertical, department, role — enough to distinguish from other stakeholders
```
Replace with:
```
- STK: segment, department, role — enough to distinguish from other stakeholders
```

No other occurrences of `vertical` in this file.

---

### `.claude/agents/sara-artifact-sorter.md` — Track 1 (rename in STK rule) + Track 2 (pass `segments` through)

**Track 1 — No direct occurrence of `vertical` found.** The sorter does not contain a STK summary rule by that name. No rename needed in this file for Track 1 beyond verifying no `vertical` string appears. (Confirmed by reading the full file — no occurrences.)

**Track 2 — Pass `segments` through unchanged**

**Analog — existing passthrough field pattern** (from the `output_format` section, lines 175–181):
```
- For action artifacts, preserve `act_type`, `owner`, and `due_date` exactly as received from
  the extraction pass. Do not modify, reclassify, or drop these fields. Pass them through unchanged
  to `cleaned_artifacts`.
- For action update artifacts (`action=update`, `type=action`), `act_type`, `owner`, and `due_date`
  MUST be present — copy them from the incoming create artifact unchanged.
```

**Pattern to copy — add `segments` passthrough rule (append to `output_format` notes):**
```
- For all artifact types, preserve `segments` exactly as received from the extraction pass. Do not
  modify, reclassify, or drop this field. Pass it through unchanged to `cleaned_artifacts`.
- For update artifacts of any type, `segments` MUST be present — copy it from the incoming artifact
  unchanged. sara-update reads this field for all artifact types regardless of action.
```

---

## Shared Patterns

### Rename `vertical` → `segment` — find-and-replace scope

**Source:** All five SKILL.md files + sorter agent
**Apply to:** All six files

The rename is a pure textual substitution. No logic changes accompany it. Exact field-name changes:
- `.sara/config.json` key: `verticals` → `segments`
- STK page frontmatter field name: `vertical:` → `segment:`
- Variable names in skill prose: `{vertical}` → `{segment}`, `{verticals_array}` → `{segments_array}`
- Prompt text: "Which market vertical?" → "Which segment?"
- Step 3 prompt in sara-init: "Provide all market verticals that apply?" → "What segments or customer groups does this project cover?"
- Summary rule comments: `STK: vertical, department, role` → `STK: segment, department, role`
- Notes/constraint text: `vertical and department are always separate` → `segment and department are always separate`
- Config array key in prose references: `config.verticals` → `config.segments`

### `segments: []` field — YAML serialisation rule

**Source:** CONTEXT.md code_context section + D-09 decision
**Apply to:** sara-extract (artifact JSON), sara-update (frontmatter write), sara-init (templates + CLAUDE.md schema)

```yaml
# 0 entries — flow style
segments: []

# 1–2 entries — flow style
segments: [Residential]
segments: [Residential, Enterprise]

# 3+ entries — block style (consistent with tags, related, source in existing templates)
segments:
  - Residential
  - Enterprise
  - Wholesale
```

### `schema_version` — no bump for this phase

**Source:** CONTEXT.md code_context — "this phase does not bump schema_version again (segments is an additive field, not a breaking change)"
**Apply to:** All artifact write operations in sara-update

All four artifact types already write `schema_version: '2.0'` (single-quoted). The `segments` field is additive — do not change the version string.

### Constraint note — `segment` and `department` are always separate fields

**Source:** `.claude/skills/sara-add-stakeholder/SKILL.md` notes section (line 167) + `.claude/skills/sara-init/SKILL.md` notes section (line 653) + `.claude/skills/sara-update/SKILL.md` notes section (line 591)
**Apply to:** All files that contain the locked-constraint note about these fields being separate

The renamed constraint reads:
```
`segment` and `department` are always separate fields in stakeholder pages — never merged.
This is a locked domain constraint.
```

---

## No Analog Found

All six files have direct analogs (themselves, from prior phases). No new file creation required. No files without patterns.

---

## Metadata

**Analog search scope:** `.claude/skills/`, `.claude/agents/`, `.planning/phases/10-refine-actions/`
**Files read:** 8 (6 skill/agent files + 2 prior phase context/research files)
**Pattern extraction date:** 2026-04-30
