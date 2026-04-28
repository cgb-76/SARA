# Phase 5: artifact-summaries - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 9 (7 modified, 1 new skill, 1 state file)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.sara/templates/requirement.md` | template | transform | `.sara/templates/decision.md` (same group) | exact |
| `.sara/templates/decision.md` | template | transform | `.sara/templates/requirement.md` (same group) | exact |
| `.sara/templates/action.md` | template | transform | `.sara/templates/requirement.md` (same group) | exact |
| `.sara/templates/risk.md` | template | transform | `.sara/templates/requirement.md` (same group) | exact |
| `.sara/templates/stakeholder.md` | template | transform | `.sara/templates/requirement.md` (same group) | exact |
| `.sara/pipeline-state.json` | config | CRUD | `.sara/pipeline-state.json` itself | exact |
| `.claude/skills/sara-extract/SKILL.md` | skill | request-response | `.claude/skills/sara-discuss/SKILL.md` | role-match |
| `.claude/skills/sara-discuss/SKILL.md` | skill | request-response | `.claude/skills/sara-extract/SKILL.md` | role-match |
| `.claude/skills/sara-update/SKILL.md` | skill | CRUD | `.claude/skills/sara-update/SKILL.md` itself | exact |
| `wiki/CLAUDE.md` (= project `CLAUDE.md`) | config | request-response | `CLAUDE.md` (written by sara-init) | exact |
| `.claude/skills/sara-lint/SKILL.md` | skill | batch | `.claude/skills/sara-update/SKILL.md` | role-match |

---

## Pattern Assignments

### `.sara/templates/requirement.md` (template, transform)

**Analog:** `sara-init/SKILL.md` Step 12 — current template written verbatim at init time

**Current frontmatter** (sara-init Step 12, lines 349–360):
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

**Change required:** Insert `summary: ""  # REQ: title, status, one-line description of what is required` after the `related:` field (or at a consistent position among all five templates — end of frontmatter before `---` close is acceptable per Claude's Discretion).

**CRITICAL:** The template in `.sara/templates/requirement.md` AND the inline schema copy in `CLAUDE.md` (the `## Entity Schemas` section, written at sara-init Step 9) MUST both be updated to match. They are kept in sync manually — there is no auto-generation.

---

### `.sara/templates/decision.md` (template, transform)

**Analog:** sara-init Step 12, lines 371–395

**Current frontmatter:**
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
```

**Change required:** Add `summary: ""  # DEC: options considered, chosen option/recommendation, status, decision date` after `related:`.

---

### `.sara/templates/action.md` (template, transform)

**Analog:** sara-init Step 12, lines 398–415

**Current frontmatter:**
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
```

**Change required:** Add `summary: ""  # ACT: owner, due-date, status (open/in-progress/done/cancelled)` after `related:`.

---

### `.sara/templates/risk.md` (template, transform)

**Analog:** sara-init Step 12, lines 419–435

**Current frontmatter:**
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
```

**Change required:** Add `summary: ""  # RISK: likelihood, impact, mitigation approach, status` after `related:`.

---

### `.sara/templates/stakeholder.md` (template, transform)

**Analog:** sara-init Step 12, lines 444–457

**Current frontmatter (frontmatter only — no body sections):**
```markdown
---
id: STK-000
name: ""
nickname: ""  # colloquial name used in transcript body text (e.g. "Raj" for "Rajiwath")
vertical: ""    # from project config verticals list
department: ""  # from project config departments list
email: ""
role: ""
schema_version: "1.0"
related: []
---
```

**CRITICAL constraint:** `vertical` and `department` MUST remain separate fields. No body section headings. These are domain-locked per project memory.

**Change required:** Add `summary: ""  # STK: vertical, department, role — enough to distinguish from other stakeholders` after `related:`.

---

### `.sara/pipeline-state.json` (config, CRUD)

**Analog:** sara-init Step 7 — canonical structure written at init time (lines 131–138 of sara-init):

**Current structure:**
```json
{
  "counters": {
    "ingest": { "MTG": 0, "EML": 0, "SLK": 0, "DOC": 0 },
    "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RISK": 0, "STK": 0 }
  },
  "items": {}
}
```

**Change required:** Add `"summary_max_words": 50` as a top-level key. Placement: alongside `counters` and `items` at the root object level. Default fallback: if absent from a live file, skills treat it as 50 (D-07).

**Read/write rule (from sara-update notes):** pipeline-state.json is ALWAYS read and written using the Read and Write tools only — never Bash shell text-processing tools (jq, sed, awk). This constraint applies to the update step here too.

---

### `.claude/skills/sara-extract/SKILL.md` (skill, request-response)

**Analog:** The file itself — only Step 3 changes.

**Current Step 3 read pattern** (lines 48–57):

```markdown
**Step 3 — Generate artifact list with dedup check**

Using the source document, `{discussion_notes}`, and the current `wiki/index.md`:

For each extractable topic in the source:
  Search `wiki/index.md` for an existing entity with a matching or similar title/description. The index format is: `| ID | Title | Status | Type | Tags | Last Updated |` — match on the Title and description columns.
  If a matching entity is found in the index:
    → Set action: `"update"`, set `existing_id` to the matching entity's ID, set `change_summary` to what needs to change.
  If no matching entity is found:
    → Set action: `"create"`, set `id_to_assign` to `"{TYPE}-NNN"` (placeholder; real ID assigned at update time by `/sara-update`).
```

**Current approach:** The dedup check reads only `wiki/index.md` (already loaded in Step 2). Full artifact pages are not currently read in Step 3 — the index Title/description columns are the signal.

**Change required (D-08):** Replace the `wiki/index.md`-only dedup signal with a grep-extract across all wiki artifact subdirectories. New pattern reads all `summary:` fields via grep to give richer semantic signal:

```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
```

This returns compact `summary: "..."` lines (one per artifact). Use these summaries — alongside `wiki/index.md` — to decide create-vs-update and spot cross-link opportunities.

**Fallback rule (D-10):** If an artifact has no `summary` field (pre-existing), the grep omits it. In that case, fall back to reading the full page for that artifact only.

**Step guard pattern to preserve** (lines 20–38): The Stage guard in Step 1 uses the pattern: read pipeline-state, validate ID argument, check stage, STOP with actionable message if wrong stage. This is unchanged.

---

### `.claude/skills/sara-discuss/SKILL.md` (skill, request-response)

**Analog:** The file itself — only the cross-link surfacing sub-pattern changes.

**Existing grep pattern for stakeholders** (lines 48–54 — reuse this pattern shape):
```markdown
Build `known_names` by running a Bash grep across all STK page frontmatter — do NOT read individual stakeholder pages into context:

```bash
grep -rh "^\(name\|nickname\):" wiki/stakeholders/ 2>/dev/null
```
```

**Current cross-link read pattern** (Priority 4, lines 70–73):
```markdown
**Priority 4 — Cross-link candidates:** Identify topics in the source that clearly relate to an existing wiki entity (by matching title or description in `wiki/index.md`). List each candidate with the wiki entity ID.
```

The current Priority 4 relies only on `wiki/index.md` (loaded in Step 2 line 46). There are no full-page reads of wiki artifacts in the current sara-discuss flow.

**Change required (D-09):** In Step 2 (or as a new sub-step within Step 3 Priority 4), add the grep-extract pattern to load summaries:

```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
```

Use these summaries to supplement `wiki/index.md` when identifying cross-link candidates (Priority 4). Do NOT read full wiki pages — the grep-extract output is the signal. Fallback for summary-less artifacts: fall back to the index Title column only (consistent with D-10).

**Existing pattern to preserve:** The `known_names` grep already established the "grep frontmatter fields, do NOT read individual pages" pattern — the new summary grep follows the same shape.

---

### `.claude/skills/sara-update/SKILL.md` (skill, CRUD)

**Analog:** The file itself — summary generation slots into Step 2's create loop.

**Current Step 2 create loop frontmatter substitution** (lines 79–92):
```markdown
Construct the wiki page content by substituting all fields from the artifact into the template frontmatter and body:
- `id` = `{assigned_id}`
- `title` = `artifact.title`
- `description` = `artifact.title` (frontmatter one-liner...)
- `source` = `{item.id}`
- `raised-by` = `artifact.raised_by`
- `related` = `artifact.related`
- `schema_version` = `"1.0"` (always quoted)
- For decision artifacts: set `status` = ..., `date` = today's ISO date
- For requirement artifacts: set `status` = `"open"`
- For action artifacts: set `status` = `"open"`, `owner` = `artifact.raised_by`
- For risk artifacts: set `status` = `"open"`, `owner` = `artifact.raised_by`
- All other fields not supplied by the artifact: use the template default value
```

**Change required (D-06):** Add `summary` generation to this substitution list. After all other fields are set:

```
- `summary` = LLM-generated prose string, type-appropriate content per D-03, within
  `summary_max_words` limit from `pipeline-state.json` (default 50 if absent).
  Content rules by type:
  - REQ: title, status, one-line description of what is required
  - DEC: options considered, chosen option/recommendation, status, decision date
  - ACT: owner, due-date, status (open/in-progress/done/cancelled)
  - RISK: likelihood, impact, mitigation approach, status
  - STK: vertical, department, role — enough to distinguish from other stakeholders
```

**Also applies to update actions** (D-06 covers both create and update). In the update branch (lines 212–218), after applying `artifact.change_summary`, also regenerate/refresh the `summary` field using the same type-specific rules.

**Step guard pattern** (lines 20–42): unchanged — same structure as other skills.

**Commit pattern** (lines 273–280): unchanged.

---

### `wiki/CLAUDE.md` (= project-root `CLAUDE.md`, config)

**Analog:** `CLAUDE.md` written by sara-init Step 9 — the `## Behavioral Rules` section

**Current Behavioral Rules** (sara-init Step 9, lines 165–177):
```markdown
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
5. **Cross-references:** `related` fields must use entity IDs only...
```

**Change required (D-16):** Append rule 6 to the numbered list:

```markdown
6. **Summary field:** When writing or updating any wiki artifact, always generate or refresh the
   `summary` field using the type-specific content rules (REQ: title/status/description;
   DEC: options/chosen option/status/date; ACT: owner/due-date/status;
   RISK: likelihood/impact/mitigation/status; STK: vertical/department/role) and the
   `summary_max_words` limit from `.sara/pipeline-state.json` (default: 50 words if absent).
```

**Note:** The `## Entity Schemas` section in CLAUDE.md (lines 181–292 of sara-init) embeds inline schema copies. Each schema block must also have `summary: ""` added, consistent with the template changes above.

---

### `.claude/skills/sara-lint/SKILL.md` (skill, batch) — NEW

**Analog:** `.claude/skills/sara-update/SKILL.md` — closest existing skill with a write-and-commit pattern. Also `.claude/skills/sara-ingest/SKILL.md` for STATUS-mode output table format.

**Stage guard pattern to copy** (sara-update Step 1, lines 20–42): All skills begin with a guard. For sara-lint, guard on wiki existence rather than pipeline stage:
```bash
if [ ! -d "wiki" ]; then
  echo "No wiki found. Run /sara-init first."
  exit 1
fi
```

**Scan-then-confirm UX pattern (D-13):** Dry-run-first. Present count + one preview, ask user to confirm before writing. This is a new pattern — no existing analog — but the AskUserQuestion pattern from sara-extract Step 4 provides the confirmation call shape:

```markdown
header: "Confirm lint"
question: "Back-fill summaries for {count} artifacts?"
options: ["Proceed", "Cancel"]
```

**Commit pattern to copy** (sara-update Step 5, lines 273–282):
```bash
git add wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/
git commit -m "fix(wiki): back-fill artifact summaries via sara-lint"
echo "EXIT:$?"
```
Check exit code; advance to "done" only after commit succeeds.

**Extensibility stub pattern (D-15):** Structure the SKILL.md with explicit future-check sections stubbed out:
```markdown
**Check 1 — Missing summaries** (v1 — implemented)
...

**Check 2 — Orphaned pages** (v2 — stub, not implemented)
<!-- Future: scan wiki pages not referenced in wiki/index.md -->

**Check 3 — Broken cross-references** (v2 — stub, not implemented)
<!-- Future: verify all IDs in `related:` fields resolve to existing pages -->
```

**Read pattern for scan:** Use Bash grep to find artifacts missing `summary:`:
```bash
grep -rL "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null | grep "\.md$" | grep -v "\.gitkeep"
```
`-L` prints filenames that do NOT match — i.e., pages lacking a `summary:` field. This drives the back-fill loop.

**Write pattern:** For each file to back-fill — Read the file (to parse frontmatter and body for context), generate `summary` value using type-specific rules + `summary_max_words` limit, insert `summary:` field into frontmatter, Write the file back. Use Read + Write tools only — no Bash text-processing.

---

## Shared Patterns

### Stage guard (Step 1) — all skills
**Source:** `.claude/skills/sara-update/SKILL.md` lines 20–42, `.claude/skills/sara-extract/SKILL.md` lines 20–38
**Apply to:** sara-lint (adapted for wiki-existence guard rather than pipeline stage)
```markdown
Read `.sara/pipeline-state.json` using the Read tool.
[Validate argument, find item, check stage]
If actual stage != "{expected}":
  Output: "Item {N} is in stage '{actual_stage}'. Run /sara-{skill} <ID> only when stage is '{expected}'."
  STOP.
```
For sara-lint: replace pipeline-state check with `[ -d "wiki" ]` bash guard.

### Grep-extract read pattern — sara-extract and sara-discuss
**Source:** `.claude/skills/sara-discuss/SKILL.md` lines 48–54 (existing `known_names` grep)
**Apply to:** sara-extract Step 3, sara-discuss Step 3 Priority 4, sara-lint Check 1
```bash
# Load all summaries (grep-extract pattern)
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null

# Find artifacts missing summary (lint scan pattern)
grep -rL "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null | grep "\.md$"
```

### pipeline-state.json read/write — all skills
**Source:** `.claude/skills/sara-update/SKILL.md` notes (lines 335–336)
**Apply to:** All skills that touch pipeline-state.json
```
pipeline-state.json is read and written using Read and Write tools only — never Bash shell
text-processing tools (jq, sed, awk).
```

### Commit pattern — sara-update (unchanged), sara-lint (new)
**Source:** `.claude/skills/sara-update/SKILL.md` lines 272–282
**Apply to:** sara-lint Step (commit + stage advance)
```bash
git add {files...}
git commit -m "{commit message}"
echo "EXIT:$?"
# Check exit code — only advance stage / report success after exit 0
git log --oneline -1  # capture commit hash for output
```

### summary_max_words fallback — sara-update and sara-lint
**Source:** D-07 (CONTEXT.md)
**Apply to:** sara-update Step 2 (create + update branches), sara-lint Check 1
```
Read `summary_max_words` from `.sara/pipeline-state.json`.
If the key is absent, default to 50.
```

---

## No Analog Found

All files have analogs within the project. The sara-lint SKILL.md is the only truly new file; it borrows patterns from sara-update (commit, write loop, stage guard), sara-extract (approval/confirmation flow), and sara-discuss (grep frontmatter pattern).

---

## Metadata

**Analog search scope:** `.claude/skills/`, `.sara/` (via sara-init SKILL.md), project CLAUDE.md (via sara-init)
**Files scanned:** 5 SKILL.md files (sara-init, sara-update, sara-extract, sara-discuss, sara-ingest)
**Pattern extraction date:** 2026-04-28

**Key finding — templates do not exist at dev time:** The `.sara/templates/` files and `wiki/CLAUDE.md` are generated at runtime by `/sara-init`. Their canonical source-of-truth for the current schema is the literal content embedded in `.claude/skills/sara-init/SKILL.md` Steps 9 and 12. Any planner editing these templates must also update the corresponding inline copies in sara-init Step 9 (CLAUDE.md entity schema section) and sara-init Step 12 (template write calls), or the schema will diverge for new wiki inits.
