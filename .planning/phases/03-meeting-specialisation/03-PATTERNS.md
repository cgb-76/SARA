# Phase 3: Meeting Specialisation - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 2 (both new SKILL.md files)
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-minutes/SKILL.md` | skill (read + transform + output) | request-response (read pipeline-state + wiki pages → terminal output) | `.claude/skills/sara-update/SKILL.md` | role-match (same item-lookup + extraction_plan traversal; no writes) |
| `.claude/skills/sara-agenda/SKILL.md` | skill (stateless generator) | request-response (user prompt → terminal output) | `.claude/skills/sara-init/SKILL.md` | role-match (same freeform prompt-and-wait pattern; no writes) |

---

## Pattern Assignments

### `.claude/skills/sara-minutes/SKILL.md` (skill, request-response — read + synthesise + output)

**Primary analog:** `.claude/skills/sara-update/SKILL.md`
**Secondary analog:** `.claude/skills/sara-ingest/SKILL.md` (type guard logic)

---

**Frontmatter pattern** (sara-update lines 1-9, reduced for read-only):

```yaml
---
name: sara-minutes
description: "Generate structured meeting minutes and email-ready draft from a completed meeting item"
argument-hint: "<ID>"
allowed-tools:
  - Read
---
```

Key difference from sara-update: `Write` and `Bash` are removed. `/sara-minutes` only reads — no file writes, no shell commands.

---

**Guard pattern — type check first, then stage check** (sara-update lines 17-41 + sara-ingest lines 41-45 combined):

Guard order per D-03: type → stage → proceed. This is inverted from sara-update (which only checks stage). The type check logic comes from how sara-ingest validates `{type}` against the hardcoded list — applied here to `item.type`.

```markdown
Step 1 — Item lookup and guard

Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
  Output: `"Usage: /sara-minutes <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Find the item with key `"{N}"` in the `items` object.

If no item exists with key `"{N}"`:
  Output: `"No pipeline item {N} found. Run /sara-ingest with no arguments to see the pipeline status."` and STOP.

Check `items["{N}"].type`. Expected type: `"meeting"`.
If type != "meeting":
  Output: `"{N} is a {item.type} item. /sara-minutes only works on meeting items (MTG-NNN)."` and STOP.

Check `items["{N}"].stage`. Expected stage: `"complete"`.
If stage != "complete":
  Output: `"Item {N} is in stage '{item.stage}'. Run /sara-update {N} first to complete the extraction pipeline before generating minutes."` and STOP.

Store `{item}` = `items["{N}"]`.
Store `{extraction_plan}` = `items["{N}"].extraction_plan`.
```

Source lines: sara-update lines 17-41 (stage guard structure), sara-ingest lines 41-45 (type validation approach).

---

**Extraction plan traversal pattern** (sara-update lines 54-67):

```markdown
For each artifact in `{extraction_plan}`:

  Determine wiki page path from `artifact.type`:
  - `requirement` → `wiki/requirements/{id}.md`
  - `decision`    → `wiki/decisions/{id}.md`
  - `action`      → `wiki/actions/{id}.md`
  - `risk`        → `wiki/risks/{id}.md`

  For `action == "create"`: use `{assigned_id}` from artifact.
  For `action == "update"`: use `{artifact.existing_id}`.

  Read the wiki page using the Read tool.
  Extract frontmatter fields relevant to that type:
  - decision:     id, title, status, date, ## Decision body section
  - action:       id, title, status, owner, due-date
  - risk:         id, title, status, likelihood, impact
  - requirement:  id, title, status
  - stakeholder:  id, name, role (for Attendees section)
```

Source: sara-update lines 54-67 (wiki_dir mapping), lines 198-204 (update branch using existing_id).

Note: aggregate both `create` and `update` action artifacts — both represent what this meeting did to the wiki (open question 2 in RESEARCH.md, recommended answer: yes, include both).

---

**Entity field schemas** (sara-init lines 153-289 — the CLAUDE.md content block):

These are the canonical field names to extract when reading wiki pages:

```
Decision (wiki/decisions/DEC-NNN.md frontmatter):
  id, title, status (proposed|accepted|rejected|superseded), date
  Body: ## Decision section text

Action (wiki/actions/ACT-NNN.md frontmatter):
  id, title, status (open|in-progress|done|cancelled), owner, due-date

Risk (wiki/risks/RISK-NNN.md frontmatter):
  id, title, status (open|mitigated|accepted|closed), likelihood, impact

Requirement (wiki/requirements/REQ-NNN.md frontmatter):
  id, title, status (open|accepted|rejected|superseded)

Stakeholder (wiki/stakeholders/STK-NNN.md frontmatter):
  id, name, role
```

Source: sara-init lines 178-289 (entity schemas in the CLAUDE.md block written by that skill).

---

**Output pattern — multi-format single response** (no prior analog; pattern 4 from RESEARCH.md):

No existing skill outputs two formats in a single response. The pattern to follow, per Claude's discretion:

```markdown
Step N — Output minutes

Output the following in a single terminal response:

---
[Markdown minutes block]

## Email Version

[Plain-text email block]
---
```

Plain-text conversion rules (D-07):
- Headings (`## Attendees`) → `ATTENDEES` (all caps, no `##`)
- Bullets (`- item`) → `- item` (dashes remain; no markdown bullet symbols like `*`)
- Bold (`**text**`) → `text` (bold markers removed)

---

**Error output format** (sara-update lines 283-309):

All error outputs are plain text (no markdown headers), match the style used across all existing skills — single sentence, name the current state, name the remediation command.

```markdown
"Item {N} is in stage '{item.stage}'. Run /sara-update {N} first to complete the extraction pipeline before generating minutes."
```

---

**Objective block pattern** (sara-update lines 11-13):

```markdown
<objective>
Reads the approved extraction plan from `pipeline-state.json` and ... [concise single paragraph]
</objective>
```

---

### `.claude/skills/sara-agenda/SKILL.md` (skill, stateless generator)

**Primary analog:** `.claude/skills/sara-init/SKILL.md` (freeform prompt-and-wait pattern, Steps 2-4)

---

**Frontmatter pattern** (sara-init lines 1-10, stripped to stateless minimum):

```yaml
---
name: sara-agenda
description: "Generate an email-friendly meeting agenda draft from user-provided meeting description"
argument-hint: ""
allowed-tools: []
---
```

`allowed-tools: []` — fully stateless; no file operations. This is structurally valid YAML; if the empty array proves invalid at runtime, omit the key entirely. (Assumption A1 from RESEARCH.md.)

Note: sara-init uses `AskUserQuestion` in its `allowed-tools` list (line 9). `/sara-agenda` explicitly does NOT use structured field collection per D-09 — freeform plain text only.

---

**Freeform prompt-and-wait pattern** (sara-init lines 54-75):

```markdown
Step 1 — Collect meeting description

Output the following as plain text and wait for the user's reply:

> Describe the meeting: who will be attending (names and roles if relevant),
> what topics need to be covered, and what you want to achieve by the end.

Capture the user's reply as `{meeting_description}`.
Proceed to Step 2 — generate agenda.
```

Source: sara-init lines 54-75 (Steps 2-4 of its process block — same output-question-then-capture structure).

Key difference from sara-init: only one question (not three separate prompts). `/sara-agenda` waits for a single freeform reply and then generates. No `AskUserQuestion` tool.

---

**Plain-text output constraint** (D-11, mirroring pitfall 4 in RESEARCH.md):

The process step for generation must include an explicit instruction:

```markdown
Step 2 — Generate agenda

Using `{meeting_description}`, synthesise a plain-text agenda draft.
Output plain-text only — no markdown formatting (no `##`, no `**bold**`, no `*` bullets).

Use the following structure:
- Subject line suggestion
- Greeting
- Numbered agenda items (no time allocations)
- Desired outcome statement
- Sign-off
```

---

**No-write, no-commit constraint** (D-12):

No Write tool call, no Bash tool call. The skill produces output text only. The final step of the process block must not include any file operation.

---

**Objective block pattern** (sara-init lines 11-17):

```markdown
<objective>
Generates a throw-away email-friendly agenda draft from a single freeform user prompt.
No state is read or written. Output is displayed once and discarded.
</objective>
```

---

## Shared Patterns

### SKILL.md File Structure

**Source:** All six existing skills in `.claude/skills/`
**Apply to:** Both new skills

Every SKILL.md uses the same four-section layout:

```
1. YAML frontmatter block (name, description, argument-hint, allowed-tools)
2. <objective> block — single paragraph, plain English
3. <process> block — numbered steps with bold step headings
4. <notes> block — bulleted critical rules and edge cases
```

Bold step headings format (from all skills):
```markdown
**Step N — Short description**
```

---

### pipeline-state.json Read Pattern

**Source:** `.claude/skills/sara-update/SKILL.md` lines 19-20
**Apply to:** `/sara-minutes` Step 1

```markdown
Read `.sara/pipeline-state.json` using the Read tool.
```

The path is always `.sara/pipeline-state.json` (not `pipeline-state.json` at root). This prefix is consistent across all skills that touch this file.

---

### Item Key Lookup Pattern

**Source:** `.claude/skills/sara-update/SKILL.md` lines 24-28; `.claude/skills/sara-ingest/SKILL.md` notes (lines 138-142)

```markdown
Find the item with key `"{N}"` in the `items` object
(N is the full ID argument — for `/sara-minutes MTG-001`, N = `"MTG-001"`).
```

Item keys are the full type-prefixed ID strings (e.g. `"MTG-001"`), not numeric indices.

---

### Notes Block Critical Rules

**Source:** `.claude/skills/sara-update/SKILL.md` lines 314-327
**Apply to:** Both new skills

Each skill's `<notes>` block must capture:
- CRITICAL items (fatal ordering constraints)
- Tool restrictions (what is and is not permitted)
- Edge cases (empty extraction_plan, no STK pages for attendees)
- Any false-positive warnings for grep-based lint tools

---

## No Analog Found

No files are without an analog. Both new skills are direct compositions of patterns already established in Phases 1 and 2.

| File | Gap | Resolution |
|------|-----|------------|
| `.claude/skills/sara-minutes/SKILL.md` — multi-format output step | No prior skill outputs two formats in one response | Use RESEARCH.md Pattern 4 (derived pattern); Claude's discretion governs separator wording per CONTEXT.md |
| `.claude/skills/sara-agenda/SKILL.md` — `allowed-tools: []` | No prior skill is fully stateless; not confirmed against Claude Code docs | Structurally valid YAML; test at runtime. If invalid, omit key entirely (Assumption A1) |

---

## Metadata

**Analog search scope:** `.claude/skills/` (all six existing skills examined; three read in full)
**Files scanned:** sara-update/SKILL.md, sara-ingest/SKILL.md, sara-init/SKILL.md
**Pattern extraction date:** 2026-04-27
