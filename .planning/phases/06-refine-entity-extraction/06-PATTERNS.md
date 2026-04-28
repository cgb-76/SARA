# Phase 6: refine-entity-extraction - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 7 (5 new agent files, 2 modified SKILL.md files, 1 modified install.sh)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.claude/agents/sara-requirement-extractor.md` | agent (specialist) | transform (source → JSON array) | `/home/george/.claude/agents/gsd-advisor-researcher.md` | role-match |
| `.claude/agents/sara-decision-extractor.md` | agent (specialist) | transform (source → JSON array) | `/home/george/.claude/agents/gsd-advisor-researcher.md` | role-match |
| `.claude/agents/sara-action-extractor.md` | agent (specialist) | transform (source → JSON array) | `/home/george/.claude/agents/gsd-advisor-researcher.md` | role-match |
| `.claude/agents/sara-risk-extractor.md` | agent (specialist) | transform (source → JSON array) | `/home/george/.claude/agents/gsd-advisor-researcher.md` | role-match |
| `.claude/agents/sara-artifact-sorter.md` | agent (aggregator) | transform (merged arrays + wiki state → cleaned list + questions) | `/home/george/.claude/agents/gsd-codebase-mapper.md` | role-match |
| `.claude/skills/sara-extract/SKILL.md` | skill (orchestrator) | request-response, multi-agent dispatch | `.claude/skills/sara-extract/SKILL.md` (self — Steps 4–5 preserved) | exact (partial rewrite) |
| `.claude/skills/sara-discuss/SKILL.md` | skill (discussion) | request-response | `.claude/skills/sara-discuss/SKILL.md` (self — scope narrowed) | exact (partial rewrite) |
| `install.sh` | config/distribution | batch | `install.sh` (self — agent block added) | exact (additive) |

---

## Pattern Assignments

### `.claude/agents/sara-requirement-extractor.md` (specialist agent, transform)

**Analog:** `/home/george/.claude/agents/gsd-advisor-researcher.md` (lines 1–18)

**Frontmatter pattern** (lines 1–6 of analog):
```yaml
---
name: sara-requirement-extractor
description: Extract requirement artifacts from a source document and discussion notes
tools: Read, Bash
color: cyan
---
```

Key rules verified against the analog:
- `tools:` is a comma-separated string on ONE line — NOT a YAML list
- No `version:` field — that is SKILL.md format only
- No `allowed-tools:` key — agent files do not use it
- `description:` is action-oriented, task-specific (shows what the agent returns/does)

**Role block pattern** (lines 8–18 of analog):
```markdown
<role>
You are sara-requirement-extractor. You extract requirement artifacts only from a
source document and discussion notes.
Spawned by `/sara-extract` via Task(). Return a JSON array only — no prose, no
markdown fences.
</role>
```

**Input declaration pattern** (lines 43–49 of analog):
```markdown
<input>
Agent receives via prompt:

- `<source_document>` — full content of the source file
- `<discussion_notes>` — discussion_notes string from pipeline-state.json
</input>
```

**Output format block pattern** — concrete JSON schema with all required fields must appear in `<output_format>`:
```markdown
<output_format>
Return a raw JSON array (no markdown fences, no prose):

[
  {
    "action": "create",
    "type": "requirement",
    "id_to_assign": "REQ-NNN",
    "title": "...",
    "source_quote": "exact verbatim text from source document",
    "raised_by": "STK-NNN",
    "related": [],
    "change_summary": ""
  }
]

Rules:
- `action` is always "create" — never "update"
- `id_to_assign` is always "REQ-NNN" placeholder — never a real ID
- `source_quote` is MANDATORY — every artifact must include verbatim text from the source
- If no requirement artifacts are found, return an empty array: []
</output_format>
```

**Notes / pitfalls block pattern** (lines 43–60 of `gsd-codebase-mapper.md`):
```markdown
<notes>
- discussion_notes are passed explicitly in the prompt — agents start cold and have
  no implicit access to pipeline-state.json or prior discuss phase context
- Do NOT access the wiki, wiki/index.md, or grep summaries — those belong to the sorter
- Do NOT produce "update" actions — create-vs-update resolution is the sorter's job
- source_quote must be verbatim — copy the exact passage, do not paraphrase
</notes>
```

**Full file structure template** (copy for all 4 specialist agents, substituting type):
```markdown
---
name: sara-{type}-extractor
description: Extract {type} artifacts from a source document and discussion notes
tools: Read, Bash
color: cyan
---

<role>
...
</role>

<input>
...
</input>

<process>
...
</process>

<output_format>
...
</output_format>

<notes>
...
</notes>
```

---

### `.claude/agents/sara-decision-extractor.md` (specialist agent, transform)

**Analog:** Same as sara-requirement-extractor — identical structure, substituting:
- `name: sara-decision-extractor`
- `type: "decision"`
- `id_to_assign: "DEC-NNN"`
- Decision-specific extraction guidance in `<process>`

Copy the full structure from the requirement extractor pattern above.

---

### `.claude/agents/sara-action-extractor.md` (specialist agent, transform)

**Analog:** Same structure as requirement extractor, substituting:
- `name: sara-action-extractor`
- `type: "action"`
- `id_to_assign: "ACT-NNN"`

---

### `.claude/agents/sara-risk-extractor.md` (specialist agent, transform)

**Analog:** Same structure as requirement extractor, substituting:
- `name: sara-risk-extractor`
- `type: "risk"`
- `id_to_assign: "RSK-NNN"`

---

### `.claude/agents/sara-artifact-sorter.md` (aggregator agent, transform)

**Analog:** `/home/george/.claude/agents/gsd-codebase-mapper.md` (lines 1–12, 87–170)

**Frontmatter pattern**:
```yaml
---
name: sara-artifact-sorter
description: Deduplicate, resolve create-vs-update, and surface ambiguities from merged specialist extraction output
tools: Read, Bash
color: cyan
---
```

**Role block pattern** (model from gsd-codebase-mapper lines 14–23):
```markdown
<role>
You are sara-artifact-sorter. You receive the merged output of four specialist
extraction agents, the existing wiki grep summaries, and wiki/index.md. You produce:
1. A cleaned, deduplicated artifact list with create-vs-update resolved
2. A set of questions for the human covering type ambiguities, likely duplicates,
   and cross-reference opportunities

Spawned by `/sara-extract` via Task(). Do not write any files — return structured
output only.
</role>
```

**Input declaration**:
```markdown
<input>
Agent receives via prompt:

- `<merged_artifacts>` — JSON array: concatenation of all four specialist agent outputs
- `<grep_summaries>` — output of:
  grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
- `<wiki_index>` — full content of wiki/index.md
</input>
```

**Dual output format block** (sorter-specific — no analog, derived from D-08):
```markdown
<output_format>
Return a JSON object with two keys:

{
  "cleaned_artifacts": [
    {
      "action": "create",
      "type": "requirement",
      "id_to_assign": "REQ-NNN",
      "title": "...",
      "source_quote": "...",
      "raised_by": "STK-NNN",
      "related": [],
      "change_summary": ""
    },
    {
      "action": "update",
      "type": "decision",
      "existing_id": "DEC-003",
      "title": "...",
      "source_quote": "...",
      "raised_by": "STK-NNN",
      "related": [],
      "change_summary": "What should be added or changed"
    }
  ],
  "questions": [
    "Is the passage '...' a requirement or a decision? (candidates: REQ or DEC)",
    "The artifact 'API rate limiting' looks similar to DEC-003 '...'. Is this a duplicate?"
  ]
}

If no questions exist (clean source, no ambiguities): set "questions" to []
id_to_assign and existing_id are mutually exclusive per artifact — use id_to_assign
for action=create, existing_id for action=update. Omit or set the inapplicable field to "".
</output_format>
```

---

### `.claude/skills/sara-extract/SKILL.md` (skill orchestrator, partial rewrite)

**Analog:** `.claude/skills/sara-extract/SKILL.md` (self — Steps 4–5 are preserved verbatim)

**Preserved verbatim — Step 4 approval loop** (lines 103–145 of current file):
```markdown
**Step 4 — Per-artifact approval loop**

Initialize `approved_artifacts = []`.

For each artifact in the list, at index `{artifact_index}` (starting at 1):

  Present the artifact as plain text before the AskUserQuestion call:
  ```
  --- Artifact {artifact_index} ---
  Type:   {type}
  Title:  {title}
  Action: CREATE new {TYPE}-NNN  /  UPDATE {existing_id}
  Source: "{source_quote}"
  [If update] Change: {change_summary}
  ```

  Then call AskUserQuestion:
  - For `artifact_index` 1–9: use header `"Artifact {artifact_index}"` (10 chars — safe within 12-char hard limit)
  - For `artifact_index` 10 or more: use header `"Item {artifact_index}"` (7 chars — safe within 12-char hard limit)
  ...
```

**Preserved verbatim — Step 5 write plan** (lines 149–176 of current file):
```markdown
**Step 5 — Write extraction plan and advance stage**

Read `.sara/pipeline-state.json` using the Read tool.

Update `items["{N}"]` in memory:
  - Set `stage` = `"approved"`
  - Set `extraction_plan` = the `approved_artifacts` array (may be empty if all artifacts were rejected)

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.

Do NOT use Bash shell text-processing tools — use Read and Write tools only.
...
```

**Replacement Steps 2–3** (from RESEARCH.md Code Examples section):
```markdown
**Step 2 — Load source, discussion notes, and dedup context**

Read {item.source_path} using the Read tool.
{discussion_notes} = items["{N}"].discussion_notes (already in memory from Step 1 read).
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

**Unchanged sections:**
- Frontmatter (lines 1–11): preserved as-is
- `<objective>` block: update to reflect agent dispatch (minor wording only)
- Step 1 — Stage guard (lines 19–38): preserved verbatim
- `<notes>` block: add note about agent dispatch; preserve all existing notes

---

### `.claude/skills/sara-discuss/SKILL.md` (skill, scope narrowed)

**Analog:** `.claude/skills/sara-discuss/SKILL.md` (self — Step 1, Step 2, Step 4 mostly preserved)

**Preserved sections:**
- Frontmatter (lines 1–11): preserved verbatim
- Step 1 — Stage guard (lines 22–41): preserved verbatim
- Step 2 — Load source and context (lines 43–58): preserved verbatim
- Step 4 — Resolve unknown stakeholders (lines 106–117): preserved verbatim
- Step 6 — Write resolved context and advance stage (lines 154–179): preserved verbatim (but discussion_notes summary items reduced to only P1 + source comprehension)

**Sections to remove** (D-11):
- Step 3 Priority 2 — Ambiguous entity type (lines 66–67 of current file): REMOVE
- Step 3 Priority 3 — Missing context gaps (lines 68–69): REMOVE
- Step 3 Priority 4 — Cross-link candidates including the grep-extract pattern block (lines 70–80): REMOVE
- Step 5 — Work through remaining blockers Priority 2 through 4 (lines 119–152): REMOVE or reduce to source comprehension only

**Narrowed Step 3 blocker list format** (replace Priority 2–4 with source comprehension):
```markdown
**Step 3 — Generate blocker list**

Using the source document and existing wiki context, identify blockers in priority order:

**Priority 1 — Unknown stakeholders:** Scan the full source for every person mentioned
by name. For each person found, check if their name appears in `known_names`. Collect
ALL unknown persons before proceeding.

**Priority 2 — Source comprehension blockers:** Identify passages in the source that
are ambiguous, unclear, or reference context that cannot be inferred from the document
alone — and where the ambiguity would prevent accurate extraction (not entity type
classification — that is the sorter's job). List each with the source passage.

Present a structured blocker summary before resolving anything.

If both lists are empty: skip Steps 4 and 5 entirely and proceed to Step 6.
```

**`<objective>` block update** — replace classification/dedup/cross-ref language:
```markdown
This skill reads the source document for pipeline item N and generates a structured
blocker list — things that would cause `/sara-extract` to fail or produce wrong output.
It works through blockers in priority order: unknown stakeholders first (resolved via
inline `/sara-add-stakeholder`), then source comprehension blockers (ambiguous passages
whose meaning is unclear without additional context). Classification, deduplication,
and cross-reference reasoning now belong to the sorter agent in `/sara-extract`.
```

**`<notes>` block** — remove note about Priority 2–4; update to reflect narrowed scope.

---

### `install.sh` (config/distribution, additive)

**Analog:** `install.sh` (self — agent block mirrors the existing skills block)

**Existing skills block pattern** (lines 60–116 of current file):
```bash
# Known skills — fixed set for this release
SKILLS=(
  sara-init
  sara-ingest
  sara-discuss
  sara-extract
  sara-update
  sara-add-stakeholder
  sara-minutes
  sara-agenda
  sara-lint
)

TARGET_SKILLS_DIR="$TARGET_DIR/.claude/skills"
mkdir -p "$TARGET_SKILLS_DIR"

INSTALLED=()

for skill_name in "${SKILLS[@]}"; do
  src_url="${BASE_URL}/.claude/skills/${skill_name}/SKILL.md"
  dest_skill_dir="${TARGET_SKILLS_DIR}/${skill_name}"
  dest_file="${dest_skill_dir}/SKILL.md"
  ...
  mv "${tmp_file}" "${dest_file}"
  INSTALLED+=("${skill_name}")
done
```

**New agent block to add** (copy the loop pattern, adapt for agents — no versioning, no backup needed since agent files have no `version:` field):
```bash
# Known agent files — fixed set for this release
AGENTS=(
  sara-requirement-extractor
  sara-decision-extractor
  sara-action-extractor
  sara-risk-extractor
  sara-artifact-sorter
)

TARGET_AGENTS_DIR="$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_AGENTS_DIR"

for agent_name in "${AGENTS[@]}"; do
  src_url="${BASE_URL}/.claude/agents/${agent_name}.md"
  dest_file="${TARGET_AGENTS_DIR}/${agent_name}.md"

  tmp_file="$(mktemp)"
  if ! curl -fsSL "${src_url}" -o "${tmp_file}" 2>/dev/null; then
    echo "Warning: could not download ${agent_name} from ${src_url} — skipping." >&2
    rm -f "${tmp_file}"
    continue
  fi

  if [[ "$BACKUP" = "true" ]] && [[ -f "$dest_file" ]]; then
    cp "${dest_file}" "${dest_file}.bak"
  fi

  mv "${tmp_file}" "${dest_file}"
  INSTALLED+=("${agent_name}")
done
```

**Placement:** Add the agent loop AFTER the skills loop, BEFORE the post-install output block (line 119 of current file). The `INSTALLED` array is shared — agents appear in the same install summary.

---

## Shared Patterns

### Stage Guard (Step 1)
**Source:** `.claude/skills/sara-extract/SKILL.md` lines 19–38 and `.claude/skills/sara-discuss/SKILL.md` lines 22–41
**Apply to:** All modified SKILL.md files (both sara-extract and sara-discuss)
**Pattern:** Read pipeline-state.json → validate argument → find item by key → check stage → STOP with message if wrong stage

```markdown
Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: it must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
Output: `"Usage: /sara-{skill} <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Find the item with key `"{N}"` in the `items` object.

If no item exists with key `"{N}"`:
  Output: `"No pipeline item {N} found. ..."` STOP.

Check `items["{N}"].stage`. Expected stage: `"{expected}"`.

If actual stage != `"{expected}"`:
  Output: `"Item {N} is in stage '{actual_stage}'. ..."` STOP.
```

### Read/Write Only (no shell text processing)
**Source:** `.claude/skills/sara-extract/SKILL.md` line 159 and `.claude/skills/sara-discuss/SKILL.md` line 168
**Apply to:** All SKILL.md files that write pipeline-state.json
```markdown
Do NOT use Bash shell text-processing tools — use Read and Write tools only.
```

### AskUserQuestion Header Limit
**Source:** `.claude/skills/sara-extract/SKILL.md` lines 120–121 and notes lines 183–184
**Apply to:** sara-extract Step 4 (preserved verbatim) and any AskUserQuestion call in modified skills
```markdown
AskUserQuestion header hard limit is 12 characters.
Use `"Artifact {N}"` for N = 1–9 (10 chars — safe).
Use `"Item {N}"` for N = 10 or more (7 chars — safe).
```

### Grep-Extract Pattern (canonical command)
**Source:** `.claude/skills/sara-extract/SKILL.md` lines 51–53 and `.claude/skills/sara-discuss/SKILL.md` lines 71–73
**Apply to:** sara-extract Step 3 (passed to sorter), sara-artifact-sorter input
```bash
grep -rh "^summary:" wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ wiki/stakeholders/ 2>/dev/null
```

### Artifact Schema (frozen — all fields required)
**Source:** `.claude/skills/sara-extract/SKILL.md` lines 69–99
**Apply to:** All four specialist agent `<output_format>` blocks AND sara-artifact-sorter `<output_format>`
```json
{
  "action": "create",
  "type": "requirement",
  "id_to_assign": "REQ-NNN",
  "title": "Title of the requirement",
  "source_quote": "Exact verbatim text from source document supporting this artifact",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": ""
}
```
For UPDATE (sorter output only):
```json
{
  "action": "update",
  "type": "decision",
  "existing_id": "DEC-001",
  "title": "Title of existing decision",
  "source_quote": "Exact verbatim text from source document motivating this update",
  "raised_by": "STK-NNN",
  "related": [],
  "change_summary": "What should be added or changed in the existing page"
}
```

### Freeform Reply Rule (no AskUserQuestion for open-ended questions)
**Source:** `.claude/skills/sara-discuss/SKILL.md` lines 146 and 185
**Apply to:** sara-discuss Step 4 inline stakeholder work (unchanged) and any new plain-text wait patterns
```markdown
Wait for the user's reply using a plain-text wait — do NOT use AskUserQuestion here.
The freeform rule applies: the user wants to explain freely, so structured options
are not appropriate.
```

### SKILL.md Frontmatter Format
**Source:** `.claude/skills/sara-extract/SKILL.md` lines 1–11
**Apply to:** Both modified SKILL.md files (no format changes to frontmatter)
```yaml
---
name: sara-{name}
description: "..."
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---
```

### Agent File Frontmatter Format
**Source:** `/home/george/.claude/agents/gsd-codebase-mapper.md` lines 1–6 (VERIFIED)
**Apply to:** All five new `.claude/agents/` files
```yaml
---
name: sara-{type}-extractor
description: "..."
tools: Read, Bash
color: cyan
---
```
Critical: `tools:` is comma-separated string, NOT YAML list. No `version:`. No `allowed-tools:`.

---

## No Analog Found

No files in this phase are without analog. All files have at least a role-match analog.

| File | Role | Data Flow | Note |
|---|---|---|---|
| (none) | — | — | All 7 files have analogs |

The dual-output format for `sara-artifact-sorter` (cleaned_artifacts + questions JSON object) has no exact analog in the project — the pattern is derived from locked decisions D-08/D-09. The analog (`gsd-codebase-mapper`) provides the structural template (role, process, output_format, notes blocks) but the output schema itself is phase-specific.

---

## Metadata

**Analog search scope:**
- `/home/george/Projects/sara/.claude/skills/` — all 9 SKILL.md files scanned (sara-extract, sara-discuss, sara-update read in full)
- `/home/george/.claude/agents/` — 33 global agent files; gsd-codebase-mapper and gsd-advisor-researcher read in full as format references
- `/home/george/Projects/sara/install.sh` — read in full

**Files scanned:** 13 files read, 2 directories listed
**Pattern extraction date:** 2026-04-28
