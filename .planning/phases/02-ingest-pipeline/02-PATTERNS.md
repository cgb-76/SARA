# Phase 2: Ingest Pipeline - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 7 (5 new skills + 2 Phase 1 amendments)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.claude/skills/sara-ingest/SKILL.md` | skill | request-response | `.claude/skills/sara-init/SKILL.md` | exact — self-contained SKILL.md, guard clause + Bash file check + state JSON write |
| `.claude/skills/sara-discuss/SKILL.md` | skill | event-driven | `.claude/skills/sara-init/SKILL.md` + `gsd-discuss-phase/SKILL.md` | role-match — LLM-driven interactive loop; closest structural analog is sara-init for format, gsd-discuss-phase for concept |
| `.claude/skills/sara-extract/SKILL.md` | skill | event-driven | `.claude/skills/sara-init/SKILL.md` | role-match — AskUserQuestion per-item loop; sara-init demonstrates AskUserQuestion in allowed-tools + multi-step process |
| `.claude/skills/sara-update/SKILL.md` | skill | batch | `.claude/skills/sara-init/SKILL.md` | role-match — multi-write + git add + single commit pattern; sara-init Step 14 is the closest git commit analog |
| `.claude/skills/sara-add-stakeholder/SKILL.md` | skill | request-response | `.claude/skills/sara-init/SKILL.md` | exact — field collection via AskUserQuestion, Write file, git commit; identical tool set |
| `.sara/templates/stakeholder.md` | template | file-I/O | `.claude/skills/sara-init/SKILL.md` Step 12 (stakeholder template block) | exact — additive YAML field amendment |
| `CLAUDE.md` (project root) | schema contract | file-I/O | `.claude/skills/sara-init/SKILL.md` Step 9 (CLAUDE.md Stakeholder schema block) | exact — additive YAML field amendment to stakeholder schema block |

---

## Pattern Assignments

### `.claude/skills/sara-ingest/SKILL.md` (skill, request-response)

**Analog:** `.claude/skills/sara-init/SKILL.md`

**Why this analog:** `sara-init` is the only existing SARA skill and establishes the canonical SKILL.md pattern for this project. `sara-ingest` has the same tool set (Read, Write, Bash), the same guard-clause-first structure, and the same output reporting pattern. The Step 14 git commit in `sara-init` is not used by `sara-ingest` (ingest does not commit), but the overall shape is identical.

**Frontmatter pattern** (sara-init lines 1–10):
```yaml
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
```

For `sara-ingest`, adapt to:
```yaml
---
name: sara-ingest
description: "Register a source file in the SARA ingest pipeline or show pipeline status"
argument-hint: "[<type> <filename>]"
allowed-tools:
  - Read
  - Write
  - Bash
---
```

Note: `AskUserQuestion` is NOT needed for sara-ingest — it takes arguments, not TUI prompts. `argument-hint` is present because the skill accepts optional arguments.

**Objective block pattern** (sara-init lines 12–19):
```
<objective>
Initialise a new SARA wiki in the current directory. Creates the full /raw/ and /wiki/ directory
tree, captures project configuration...
Run this skill once per project in an empty directory before using any other SARA commands.
</objective>
```

For `sara-ingest`, write a concise `<objective>` covering both modes:
- With arguments: register a file from `raw/input/` as pipeline item N with `stage: pending`
- No arguments: display a table of all current pipeline items (ID, type, stage, filename)

**Guard clause pattern** (sara-init lines 40–51, Step 1):
```bash
if [ -d "wiki" ]; then
  echo "Error: A SARA wiki already exists in this directory (wiki/ found). Aborting — no changes made."
  exit 1
fi
```

For `sara-ingest`, adapt the guard to file-existence check (D-11):
```bash
if [ ! -f "raw/input/{filename}" ]; then
  echo "Error: File not found in raw/input/. Files currently in raw/input/:"
  ls raw/input/
  exit 1
fi
```

Place this as Step 2 after argument detection. Hard stop with no pipeline-state.json changes.

**Argument detection branch** (sara-ingest has no analog in sara-init — pattern from RESEARCH.md):

Step 1 must detect whether arguments were supplied:
```
Step 1 — Detect invocation mode

Examine $ARGUMENTS:
  If $ARGUMENTS is empty or blank:
    → Execute STATUS mode (display pipeline table, then STOP)
  If $ARGUMENTS contains "<type> <filename>":
    → Execute INGEST mode (proceed to Step 2)
  Otherwise:
    → Output usage error: "Usage: /sara-ingest <type> <filename>  OR  /sara-ingest (no args for status)"
    → STOP
```

Valid types (hardcoded, not from config): `meeting`, `email`, `slack`, `document`

Type → counter key mapping:
- `meeting` → `MTG`
- `email` → `EML`
- `slack` → `SLK`
- `document` → `DOC`

**State read/write pattern** (sara-init lines 124–137, Step 7 for write; Read before Write for ingest):

`sara-init` writes the initial pipeline-state.json:
```json
{
  "counters": {
    "ingest": { "MTG": 0, "EML": 0, "SLK": 0, "DOC": 0 },
    "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RISK": 0, "STK": 0 }
  },
  "items": {}
}
```

For `sara-ingest`, the pattern is Read → modify in memory → Write back:
```
Step 3 — Read and update pipeline-state.json

Read `.sara/pipeline-state.json` via the Read tool.
Increment counters.ingest.{TYPE_KEY} by 1.
Assign new_id = "{TYPE_PREFIX}-" + zero-padded 3-digit counter value (e.g. "MTG-001").
Add a new entry to items with key = string(new counter value as integer index, e.g. "1"):
  {
    "id": "{new_id}",
    "type": "{type_argument}",
    "filename": "{filename_argument}",
    "stage": "pending",
    "created": "{today ISO date}",
    "discussion_notes": "",
    "extraction_plan": []
  }
Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.
Do NOT use Bash jq or sed — use Read + Write only.
```

**Report pattern** (sara-init lines 443–471, Step 13):
```
Report success to the user with the following information:

- **Project:** {project_name}
- **Directories created (11):**
  ...
- **Next step:** Run `/sara-ingest` to register your first input document.
```

For `sara-ingest`, adapt to:
```
Output: "{new_id} registered as item {N}.
Type: {type}  |  Filename: {filename}  |  Stage: pending
Run /sara-discuss {N} to begin the discussion phase."
```

**Status display pattern** (no sara-init analog — new pattern; use RESEARCH.md Pattern 1):

For no-args mode, read pipeline-state.json and display a markdown table:
```
| # | ID      | Type     | Stage     | Filename                     |
|---|---------|----------|-----------|------------------------------|
| 1 | MTG-001 | meeting  | pending   | transcript-2026-04-27.md     |
| 2 | EML-001 | email    | approved  | onboarding-notes.md          |
```

If `items` is empty: Output "No pipeline items registered. Run /sara-ingest <type> <filename> to add one."

---

### `.claude/skills/sara-discuss/SKILL.md` (skill, event-driven)

**Analog:** `.claude/skills/sara-init/SKILL.md` (for SKILL.md structure) + `gsd-discuss-phase/SKILL.md` (for LLM-driven discussion concept)

**Why these analogs:** `sara-init` provides the canonical SKILL.md format for SARA skills (frontmatter, `<objective>`, `<process>`, `<notes>`). `gsd-discuss-phase` is conceptually similar: it loads prior context, runs LLM analysis, surfaces discussion areas, and outputs a decisions file. However, `sara-discuss` is self-contained (no `<execution_context>` delegation), so `sara-init`'s inline process pattern takes precedence.

**Frontmatter pattern** (adapt from sara-init lines 1–10):
```yaml
---
name: sara-discuss
description: "Run LLM-driven blocker-clearing session for a pipeline item before extraction"
argument-hint: "<N>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```

`AskUserQuestion` is required because `/sara-add-stakeholder` (invoked inline) uses it for field collection. `/sara-discuss` itself may use plain-text waits for freeform blocker clarification, but the sub-skill needs it in scope.

**Stage guard pattern** (RESEARCH.md Pattern 2; no sara-init analog for stage-keyed guard):
```
Step 1 — Stage guard and item lookup

Read `.sara/pipeline-state.json`.
Find the item with key "{N}" in the `items` object
(N = the integer argument provided by the user — for /sara-discuss 1, N = "1").

If no item exists with key "{N}":
  Output: "No pipeline item {N} found. Run /sara-ingest to register a new item,
  or run /sara-ingest with no arguments to see the full pipeline status."
  STOP.

Check items["{N}"].stage:
  Expected stage: "pending"
  If actual stage != "pending":
    Output: "Item {N} ({id}) is currently in stage '{actual_stage}'.
    Run /sara-discuss N only when stage is 'pending'.
    If the item is 'extracting', run /sara-extract N."
    STOP.
```

**Source file read pattern** (sara-init Read pattern for context files; no exact analog):
```
Step 2 — Load source and context

Read raw/input/{items[N].filename} (the source document).
Read wiki/index.md (existing entity catalog for cross-link identification).
Read wiki/stakeholders/*.md files (to build known-names list for stakeholder matching).
Read .sara/config.json (for valid verticals and departments when creating stakeholders).
```

**LLM blocker analysis pattern** (described in RESEARCH.md Pattern 2; no code analog — LLM inference):
```
Step 3 — Blocker analysis

Using the source document and existing wiki context, identify all blockers in priority order:
  Priority 1: Unknown stakeholders (names in source not matching any known STK page name OR nickname)
  Priority 2: Ambiguous entity type decisions (something that could be REQ, DEC, or RISK)
  Priority 3: Missing context gaps (source references something not in wiki; meaning unclear)
  Priority 4: Cross-link candidates needing confirmation (topic in source matches existing wiki entity)

Batch ALL unknown stakeholders from the entire source before moving to Priority 2.
```

**Inline sub-skill invocation pattern** (RESEARCH.md Pattern 6; sara-init <notes> line 509 confirms inline reading):
```
Step 4 — Resolve unknown stakeholders (if any found in Step 3)

For each unknown stakeholder found:
  Read `.claude/skills/sara-add-stakeholder/SKILL.md`.
  Execute the sara-add-stakeholder skill inline for this stakeholder.
  The skill returns a STK-NNN ID.
  Add the STK-NNN ID to the current discussion context.
  Continue to the next unknown stakeholder.

After all unknown stakeholders are resolved, continue to Step 5.
```

**Blocker resolution loop** (no direct code analog; LLM-driven dialogue):
```
Step 5 — Work through remaining blockers

For each remaining blocker (Priority 2 → 3 → 4 in order):
  Present the blocker to the user with specific context from the source document.
  Wait for the user's response.
  Record the resolution in the running discussion_notes string.
  Mark the blocker resolved.
  Proceed to the next blocker.

Declare completion ONLY when all blockers are resolved (blocker list is empty).
```

**State write and stage advance pattern** (sara-init lines 124–137 for Write pattern):
```
Step 6 — Write resolved context and advance stage

Read `.sara/pipeline-state.json`.
Update items["{N}"]:
  - stage: "extracting"
  - discussion_notes: "{all resolved context as a single plain-text string}"
Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.
Do NOT use Bash jq or sed.

Output: "Discussion complete. All blockers resolved.
Discussion notes saved to pipeline-state.json.
Run /sara-extract {N} to proceed to extraction."
```

**AskUserQuestion usage reference** (questioning.md lines 69–101; RESEARCH.md Pitfall 5):
- Header max 12 characters — hard limit. Headers like "Stakeholder" = 11 chars (safe), "Blocker" = 7 chars (safe).
- For freeform clarifications (Priority 2–4 blockers), use plain-text output + wait for reply, NOT AskUserQuestion. The freeform rule (questioning.md lines 103–118) requires this.
- AskUserQuestion is reserved for structured yes/no/options choices, not open-ended questions.

---

### `.claude/skills/sara-extract/SKILL.md` (skill, event-driven)

**Analog:** `.claude/skills/sara-init/SKILL.md` (for SKILL.md structure and AskUserQuestion in allowed-tools)

**Why this analog:** `sara-init` establishes the AskUserQuestion-in-allowed-tools pattern and shows how to collect structured user input mid-process. The per-artifact approval loop (accept/reject/discuss) is the most novel element but maps directly to one AskUserQuestion call per artifact — the same tool sara-init uses for project name, verticals, departments.

**Frontmatter pattern** (adapt from sara-init lines 1–10):
```yaml
---
name: sara-extract
description: "Present proposed artifacts for per-artifact approval before writing to wiki"
argument-hint: "<N>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```

**Stage guard pattern** (RESEARCH.md Pattern 2 Stage Guard prose):
```
Step 1 — Stage guard and item lookup

Read `.sara/pipeline-state.json`.
Find item with key "{N}".
Expected stage: "extracting"
If actual stage != "extracting":
  Output: "Item {N} ({id}) is in stage '{actual_stage}'.
  Run /sara-extract N only when stage is 'extracting'.
  Re-run /sara-discuss N if you need to revisit the discussion."
  STOP.
```

**Dedup check pattern** (RESEARCH.md Pattern — read wiki/index.md at dedup step, not at skill entry, per Pitfall 4):
```
Step 2 — Load source and dedup context

Read raw/input/{items[N].filename}.
Read items[N].discussion_notes from pipeline-state.json.

[NOTE: Read wiki/index.md HERE, at the dedup step, not cached at skill entry.
This ensures the index is fresh even if /sara-add-stakeholder updated it mid-session.]

Read wiki/index.md.
```

**LLM artifact generation pattern** (RESEARCH.md Pattern 4 and Code Examples — extraction_plan schema):
```
Step 3 — Generate artifact proposals

Using the source document, discussion_notes, and wiki/index.md:
  For each extractable topic in the source:
    Check wiki/index.md for an existing entity with the same title or similar description.
    If match found → propose action: "update", existing_id: "{ID}"
    If no match → propose action: "create", id_to_assign: "{TYPE}-NNN"

  Produce a proposed artifact list. Each artifact object:
    {
      "action": "create" | "update",
      "type": "requirement" | "decision" | "action" | "risk",
      "id_to_assign": "{TYPE}-NNN",   // for create only
      "existing_id": "{ID}",          // for update only
      "title": "{title}",
      "source_quote": "{exact text from source document}",
      "raised_by": "{STK-NNN}",       // stakeholder who raised it
      "related": [],                  // entity IDs for cross-references
      "change_summary": "{text}"      // for update only
    }
```

**Per-artifact approval loop pattern** (RESEARCH.md Pattern 4; questioning.md lines 82–88 for header limit):
```
Step 4 — Per-artifact approval loop

Initialize: approved_artifacts = []

For each proposed artifact (index starting at 1):

  Present artifact to user (as plain text before AskUserQuestion):
    Type: {type}
    Title: {title}
    Action: CREATE new {TYPE}-NNN / UPDATE {existing_id}
    Source: "{source_quote}"

  AskUserQuestion:
    header: "Artifact {N}"     ← "Artifact 1" = 10 chars (safe); for N >= 10 use "Item {N}" = 7 chars
    question: "Accept, reject, or discuss artifact {N}?"
    options: ["Accept", "Reject", "Discuss"]

  If "Accept":
    Append artifact to approved_artifacts.
    Continue to next artifact.

  If "Reject":
    Skip this artifact. Continue to next.

  If "Discuss":
    Output: "What would you like to change about this artifact?"
    [plain text wait — NOT another AskUserQuestion; freeform rule applies]
    Incorporate user's correction into the artifact.
    Re-present revised artifact (plain text summary).
    Loop back to AskUserQuestion for this artifact.
    [Loop until Accept or Reject is selected]

After all artifacts processed:
  → Continue to Step 5.
```

**Header char count reference** (questioning.md line 82 — hard 12-char limit):
- "Artifact 1" = 10 chars — safe for single digits
- "Artifact 9" = 10 chars — safe
- "Item 10" = 7 chars — use for double digits
- "Item 99" = 7 chars — safe

**State write and stage advance pattern** (sara-init Step 7 Write pattern):
```
Step 5 — Write extraction plan and advance stage

Read `.sara/pipeline-state.json`.
Update items["{N}"]:
  - stage: "approved"
  - extraction_plan: [approved_artifacts array]
Write the modified JSON back to `.sara/pipeline-state.json`.
Do NOT use Bash jq or sed.

Output: summary table of approved artifacts:
  "## Extraction Plan — Item {N}
  {count} artifacts approved / {count} rejected.
  | # | Action | Type | Title |
  ...
  Run /sara-update {N} to write approved artifacts to the wiki."
```

---

### `.claude/skills/sara-update/SKILL.md` (skill, batch)

**Analog:** `.claude/skills/sara-init/SKILL.md` Steps 12–14 (multi-write + git commit)

**Why this analog:** `sara-init` Step 12 writes five separate files in sequence (five separate Write calls) and Step 14 stages all of them with `git add` and commits in a single `git commit`. This is exactly the `sara-update` pattern: N wiki file writes followed by a single atomic commit. The error-before-commit → do-not-commit rule is the inverse of sara-init's commit-at-end pattern.

**Frontmatter pattern** (adapt from sara-init lines 1–10):
```yaml
---
name: sara-update
description: "Execute approved extraction plan — write wiki artifacts and commit atomically"
argument-hint: "<N>"
allowed-tools:
  - Read
  - Write
  - Bash
---
```

Note: `AskUserQuestion` is NOT needed — sara-update is fully automatic (no choices to present).

**Stage guard pattern** (RESEARCH.md Pattern 2):
```
Step 1 — Stage guard and item lookup

Read `.sara/pipeline-state.json`.
Find item with key "{N}". Expected stage: "approved".
If actual stage != "approved":
  Output: "Item {N} ({id}) is in stage '{actual_stage}'.
  Run /sara-update N only when stage is 'approved'.
  Re-run /sara-extract N if you need to revise the plan."
  STOP.
```

**Read extraction plan pattern** (RESEARCH.md Pattern 3):
```
Step 2 — Load extraction plan

Read `.sara/pipeline-state.json`.
Extract items["{N}"].extraction_plan (the approved_artifacts array).
Extract items["{N}"].id and items["{N}"].filename for commit message.
```

**Multi-file write pattern** (sara-init lines 326–437, Steps 12 write calls):

sara-init writes each template as a separate Write call:
```
Use the Write tool to create `.sara/templates/requirement.md` with the following content:
[content block]

Use the Write tool to create `.sara/templates/decision.md` with the following content:
[content block]
```

For `sara-update`, adapt to one Write call per approved artifact:
```
Step 3 — Write wiki artifact files

Track written files: written_files = []
Track failed files: failed_files = []

For each artifact in extraction_plan:
  Determine file path:
    - action = "create": wiki/{type}s/{id_to_assign}.md (e.g. wiki/requirements/REQ-001.md)
      Before writing: increment counters.entity.{TYPE_KEY} in pipeline-state.json.
      Read post-increment value as the actual assigned ID.
    - action = "update": wiki/{type}s/{existing_id}.md

  Construct page content using the relevant template from .sara/templates/{type}.md,
  substituting all fields from the artifact object.

  Write the file using the Write tool.
  If write succeeds: append path to written_files.
  If write fails: append path to failed_files.
    Report the failure with list of written/not-written files.
    DO NOT auto-rollback. DO NOT proceed to commit.
    STOP.

Update wiki/index.md — add or update rows for all written artifacts.
Append to wiki/log.md — one ingest event record.
```

**Atomic git commit pattern** (sara-init lines 477–503, Step 14 git commit):

sara-init Step 14:
```bash
git rev-parse --git-dir > /dev/null 2>&1 || git init
git add \
  .gitignore \
  .sara/config.json \
  .sara/pipeline-state.json \
  CLAUDE.md \
  ...
git commit -m "chore: initialise SARA — {project_name}"
```

For `sara-update`, the exact commit pattern from RESEARCH.md Pattern 5:
```bash
# Stage all wiki artifacts + state file + source file move
git add wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ \
        wiki/index.md wiki/log.md \
        .sara/pipeline-state.json \
        raw/input/{filename} raw/{type_archive_dir}/{prefix}-{filename}

# Single commit
git commit -m "feat(sara): ingest {ITEM_ID} — {source_filename}"
```

Only issue this commit AFTER all Write operations succeed. If commit fails:
- Report exactly which files were written and which were not
- Do NOT auto-rollback (D-14)
- Do NOT advance stage to "complete"
- Leave stage at "approved" so user can retry

**Source file archiving pattern** (RESEARCH.md Pattern 7):
```
Step 4 — Archive source file

Determine archive directory:
  meeting → raw/meetings/
  email   → raw/emails/
  slack   → raw/slack/
  document → raw/documents/

Determine archive filename: "{zero-padded-3-digit-counter}-{original_filename}"
  e.g. counter = 1 → prefix = "001"
  e.g. raw/input/transcript.md → raw/meetings/001-transcript.md

Check if source file is git-tracked:
  bash: git status raw/input/{filename}

If tracked: use git mv raw/input/{filename} raw/meetings/{prefix}-{filename}
If untracked: use mv raw/input/{filename} raw/meetings/{prefix}-{filename}
  Then: git add raw/input/{filename} raw/meetings/{prefix}-{filename}

Include this move in the same git commit as wiki writes (Step 5 below).
```

**Stage advance — AFTER commit succeeds** (RESEARCH.md Pitfall 1 guard):
```
Step 5 — Commit and advance stage

[Execute git add + git commit from Step 3 pattern above]

If commit SUCCEEDS:
  Read `.sara/pipeline-state.json`.
  Update items["{N}"].stage = "complete"
  Write pipeline-state.json.
  Output: "## Update Complete
    Commit: {commit_hash}
    Artifacts written: {count}
    Source archived: raw/{type_dir}/{prefix}-{filename}
    Item {N} ({ITEM_ID}) is now complete."

If commit FAILS:
  Output: "## Update Failed
    Files written: {written_files list}
    Files NOT written: {failed_files list}
    The git commit failed. Stage remains 'approved'.
    You can re-run /sara-update {N} after resolving the issue,
    or use git reset to recover from the written files."
  DO NOT write stage = "complete".
  STOP.
```

---

### `.claude/skills/sara-add-stakeholder/SKILL.md` (skill, request-response)

**Analog:** `.claude/skills/sara-init/SKILL.md` Steps 2–4 (AskUserQuestion collection) + Step 12 (single Write call) + Step 14 (git commit)

**Why this analog:** `sara-add-stakeholder` is a closed-loop skill: collect fields via AskUserQuestion, write one page, update index and log, commit. This is structurally identical to one iteration of `sara-init`'s write-and-commit cycle. It is also callable inline from `sara-discuss` — making the standalone + sub-skill dual-mode the only novel element.

**Frontmatter pattern** (adapt from sara-init lines 1–10):
```yaml
---
name: sara-add-stakeholder
description: "Capture stakeholder details, write STK page, and commit — standalone or inline from sara-discuss"
argument-hint: "[<name>]"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```

`argument-hint` is `[<name>]` because when invoked inline from `/sara-discuss`, the calling skill may supply the stakeholder's name as an argument, bypassing the first prompt.

**AskUserQuestion field collection pattern** (sara-init lines 55–75 Steps 2–4; questioning.md lines 82–88):

sara-init Step 2 (project name prompt):
```
Output the following question as plain text and wait for the user's reply:

> What is the name of this project?

Capture the user's reply as {project_name}.
```

For `sara-add-stakeholder`, use AskUserQuestion for structured field collection (D-06 — all fields except name are optional):
```
Step 1 — Collect stakeholder name

If $ARGUMENTS is non-empty: use it as {name}. Skip to Step 2.

Otherwise:
  AskUserQuestion:
    header: "Name"
    question: "What is the stakeholder's full name? (required)"
    options: []
  [Plain text prompt — wait for reply]
  Capture reply as {name}.
```

**Optional field prompts** (sara-init plain-text wait pattern, Steps 2–4):
```
Step 2 — Collect optional fields

For each optional field, use AskUserQuestion:

  AskUserQuestion:
    header: "Nickname"
    question: "Colloquial name used in body text? (e.g. 'Raj' for 'Rajiwath') — or leave blank"
    options: ["Skip"]

  AskUserQuestion:
    header: "Vertical"
    question: "Which market vertical? (from project config) — or skip"
    options: [list from .sara/config.json verticals] + ["Skip"]

  AskUserQuestion:
    header: "Dept"
    question: "Which department? (from project config) — or skip"
    options: [list from .sara/config.json departments] + ["Skip"]

  AskUserQuestion:
    header: "Email"
    question: "Email address? — or skip"
    options: ["Skip"]

  AskUserQuestion:
    header: "Role"
    question: "Role or title? — or skip"
    options: ["Skip"]

Note: headers: "Nickname"=8, "Vertical"=8, "Dept"=4, "Email"=5, "Role"=4 — all within 12 chars.
```

**ID assignment pattern** (RESEARCH.md Pattern 3 — counter increment before write):
```
Step 3 — Assign STK-NNN ID

Read `.sara/pipeline-state.json`.
Increment counters.entity.STK by 1.
new_id = "STK-" + zero-padded 3-digit value (e.g. STK-001).
Write updated counters back to pipeline-state.json immediately.
(Counter increment is separate from the later stage field writes.)
```

**Single file write pattern** (sara-init lines 424–437 Step 12 stakeholder template):

sara-init writes the stakeholder template as:
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

For `sara-add-stakeholder`, write the populated page to `wiki/stakeholders/{new_id}.md`:
```
Step 4 — Write STK page

Use the Write tool to create wiki/stakeholders/{new_id}.md with the following content,
substituting all collected values (use "" for any skipped optional field):

---
id: {new_id}
name: "{name}"
nickname: "{nickname}"  # colloquial name used in transcript body text
vertical: "{vertical}"    # from project config verticals list
department: "{department}"  # from project config departments list
email: "{email}"
role: "{role}"
schema_version: "1.0"
related: []
---
```

**Index and log update pattern** (wiki/CLAUDE.md behavioral rules 2 and 3):
```
Step 5 — Update wiki/index.md and wiki/log.md

Read wiki/index.md.
Append a new row for the new stakeholder:
  | {new_id} | {name} | active | stakeholder | [] | {today ISO date} |

Read wiki/log.md.
Append an entry:
  | — | {today ISO date} | stakeholder | (standalone) | {new_id} created — {name} |
```

**Git commit pattern** (sara-init lines 477–503 Step 14):

sara-init Step 14:
```bash
git add \
  .sara/config.json \
  ...
git commit -m "chore: initialise SARA — {project_name}"
```

For `sara-add-stakeholder`:
```bash
git add wiki/stakeholders/{new_id}.md wiki/index.md wiki/log.md .sara/pipeline-state.json
git commit -m "feat(sara): add stakeholder {new_id} — {name}"
```

**Return value for inline callers** (RESEARCH.md Pattern 6):
```
Step 6 — Report and return ID

Output:
  "{new_id} created — {name}
  STK page: wiki/stakeholders/{new_id}.md
  Committed."

When called inline from /sara-discuss:
  Return {new_id} to the calling skill's context.
  Resume /sara-discuss from where it was paused.
```

---

### `.sara/templates/stakeholder.md` (template, file-I/O — Phase 1 amendment)

**Analog:** `.claude/skills/sara-init/SKILL.md` lines 424–437 (stakeholder template block in Step 12)

**Change required:** Add `nickname` field after `name` (D-07, D-08).

**Current content** (from sara-init Step 12):
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

**Updated content** (after amendment):
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

Pattern rules (from 01-PATTERNS.md Shared Patterns — Annotated YAML Frontmatter):
- Inline comment with `# description` after the new field
- No tab characters; 2-space indentation
- No body section headings for stakeholder template (D-11 constraint: "Stakeholders: No body sections — frontmatter only")

---

### `CLAUDE.md` (project root — Stakeholder schema block, Phase 1 amendment)

**Analog:** `.claude/skills/sara-init/SKILL.md` lines 275–288 (Stakeholder schema block in Step 9)

**Change required:** Add `nickname` field to the Stakeholder schema block in the `## Entity Schemas` section (D-07, D-08).

**Current Stakeholder schema block** (from sara-init Step 9, lines 275–288):
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

**Updated Stakeholder schema block** (after amendment):
```yaml
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

Note: The `CLAUDE.md` file is at the project root (not `wiki/CLAUDE.md` — there is only one CLAUDE.md created by sara-init Step 9 at the root). The Stakeholder block is inside the `### Stakeholder` section under `## Entity Schemas`.

---

## Shared Patterns

### SKILL.md Structure (all five new skills)
**Source:** `.claude/skills/sara-init/SKILL.md` lines 1–521 (full file)
**Apply to:** All five new SKILL.md files

Every skill follows this exact document structure:
```
---
[YAML frontmatter: name, description, argument-hint, allowed-tools]
---

<objective>
[1–4 sentences: what the skill does, when to use it]
</objective>

<process>

**Step N — [verb phrase]**
[prose instructions]
[bash blocks or Write call descriptions where needed]

</process>

<notes>
- [gotcha 1]
- [gotcha 2]
</notes>
```

The `<notes>` block is optional for simple skills but recommended for skills with error paths (sara-update, sara-ingest).

### Stage Guard (sara-discuss, sara-extract, sara-update)
**Source:** RESEARCH.md Pattern 2 (lines 298–314)
**Apply to:** sara-discuss (expected: pending), sara-extract (expected: extracting), sara-update (expected: approved)

Step 1 of every pipeline skill. Pattern is: Read pipeline-state.json → look up item by string key N → check stage → if wrong stage, output plain-English error naming current stage and correct next command → STOP. No override path (D-13).

### pipeline-state.json Read-Modify-Write (all five new skills)
**Source:** RESEARCH.md Pattern 3 (lines 327–341) + sara-init Step 7 Write pattern (lines 124–137)
**Apply to:** sara-ingest (counter increment + new item), sara-discuss (stage advance + discussion_notes), sara-extract (stage advance + extraction_plan), sara-update (counter increments + stage advance), sara-add-stakeholder (counter increment)

Always: Read full JSON with Read tool → modify in memory → Write full JSON with Write tool. Never use Bash jq, sed, or awk for JSON edits. RESEARCH.md is explicit on this constraint.

### AskUserQuestion Header Length (sara-discuss, sara-extract, sara-add-stakeholder)
**Source:** questioning.md line 82 ("Headers longer than 12 characters (hard limit — validation will reject them)")
**Apply to:** Every AskUserQuestion call in all three skills

Headers must be 12 characters or fewer. Reference counts:
- "Artifact 1" = 10 chars — safe (single digit artifact index)
- "Item 10" = 7 chars — safe (double digit, use for N >= 10)
- "Stakeholder" = 11 chars — safe (barely)
- "Name" = 4, "Nickname" = 8, "Vertical" = 8, "Dept" = 4, "Email" = 5, "Role" = 4 — all safe

### Freeform Interaction Rule (sara-discuss, sara-extract)
**Source:** questioning.md lines 103–118 ("When the user wants to explain freely, STOP using AskUserQuestion")
**Apply to:** Any blocker clarification in sara-discuss; the "Discuss" branch of the approval loop in sara-extract

When the user selects "Discuss" in sara-extract, or when sara-discuss needs open-ended clarification on a blocker — use plain text output and wait for reply. Do NOT use AskUserQuestion. Resume AskUserQuestion only after processing the freeform response.

### Annotated YAML Frontmatter (sara-add-stakeholder written pages, amendment files)
**Source:** 01-PATTERNS.md Shared Patterns — Annotated YAML Frontmatter
**Apply to:** All wiki entity pages written by sara-update and sara-add-stakeholder; the two Phase 1 amendments

- `schema_version: "1.0"` always quoted
- Inline `# comment` after fields with constrained enumerations or need clarification
- 2-space indentation; no tabs
- `related: []` using entity IDs only, never file paths or wiki-links (D-14 behavioral rule 5)

### Atomic Git Commit (sara-update, sara-add-stakeholder)
**Source:** sara-init lines 477–503 (Step 14 git add + git commit); RESEARCH.md Pattern 5
**Apply to:** sara-update (all wiki writes + source file move in one commit); sara-add-stakeholder (STK page + index + log in one commit)

Pattern:
```bash
git add {explicit file list — never git add -A or git add .}
git commit -m "{commit message}"
```

sara-update commit message: `feat(sara): ingest {ITEM_ID} — {source_filename}`
sara-add-stakeholder commit message: `feat(sara): add stakeholder {STK_ID} — {name}`

Stage transition to `complete` for sara-update must happen ONLY after the commit succeeds. If commit fails, leave stage at `approved` and report written/unwritten files (D-14).

### vertical and department — Always Separate Fields
**Source:** sara-init lines 439–440 CRITICAL note + `.claude/skills/sara-init/SKILL.md` `<notes>` line 519–520
**Apply to:** sara-add-stakeholder (field collection and page write); all entity page writes in sara-update

`vertical` and `department` MUST be two separate YAML fields. Never merge them. This is a locked domain constraint (SARA domain memory: "vertical (market segment) and department (functional area) are distinct stakeholder axes, never interchangeable").

---

## No Analog Found

All files have analogs. The per-artifact approval loop in `sara-extract` has no pre-existing code analog for the loop structure itself (it is structurally novel), but `sara-init`'s AskUserQuestion in `allowed-tools` + questioning.md provide all the building blocks. The planner should treat RESEARCH.md Pattern 4 (lines 343–379) as the authoritative loop specification.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All files have sufficient analog coverage |

---

## Metadata

**Analog search scope:** `/home/george/Projects/llm-wiki-gsd/.claude/skills/sara-init/` (primary); `/home/george/.claude/skills/` (GSD skills: gsd-discuss-phase, gsd-add-backlog, gsd-do, gsd-import, gsd-review, gsd-execute-phase, gsd-audit-fix reviewed); `/home/george/.claude/get-shit-done/references/questioning.md`; `.planning/phases/01-foundation-schema/01-PATTERNS.md`
**Files read:** 10 (sara-init/SKILL.md, 01-PATTERNS.md, 01-CONTEXT.md, 02-CONTEXT.md, 02-RESEARCH.md, gsd-discuss-phase/SKILL.md, gsd-add-backlog/SKILL.md, gsd-do/SKILL.md, gsd-import/SKILL.md, gsd-execute-phase/SKILL.md, questioning.md)
**Pattern extraction date:** 2026-04-27
