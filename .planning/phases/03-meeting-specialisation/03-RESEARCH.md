# Phase 3: Meeting Specialisation - Research

**Researched:** 2026-04-27
**Domain:** Claude Code SKILL.md authoring — generator skills with guard logic and multi-format output
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Stage guard: item N must be in `complete` stage. Any earlier stage aborts with a plain-English error naming the current stage and instructing the user to run `/sara-update N` first.

**D-02:** Type guard: item N must be a `MTG` type. Non-meeting types (EML, SLK, DOC) abort with a clear error naming the type and the correct command for that type.

**D-03:** Guard order: type check → stage check → proceed.

**D-04:** `/sara-minutes N` reads wiki artifacts, not just the raw transcript. It reads `extraction_plan` from `pipeline-state.json` to identify which entities were created or updated, then reads each of those wiki pages for their content. Raw transcript may also be read for attendee list and context not captured in wiki entities.

**D-05:** Minutes are structured around the wiki entities actually created/updated for item N — not a generic summary of the transcript.

**D-06:** Minutes markdown sections:
  - **Attendees** — names and roles (from STK pages where available, otherwise from transcript)
  - **Decisions** — each DEC-NNN, with outcome statement ("DEC-003 (Payment gateway choice) — resolved: Stripe selected.")
  - **Actions** — each ACT-NNN, with owner and due-date from wiki page
  - **Risks** — each RISK-NNN, with status from wiki page
  - **Requirements** — each REQ-NNN, with title and status from wiki page
  - Sections with no artifacts are omitted

**D-07:** Email-ready plain-text: same content as markdown, formatting stripped (headings → CAPS, bullets → dashes, bold removed). No separate summary.

**D-08:** Both outputs appear in the same terminal response: markdown block first, then a separator, then the plain-text email block.

**D-09:** `/sara-agenda` uses a single freeform plain-text prompt. Prompt text: ask the user to describe the meeting — who's attending, what topics, and what they want to achieve. No structured AskUserQuestion fields.

**D-10:** `/sara-agenda` is stateless — no item lookup, no wiki reads required.

**D-11:** `/sara-agenda` output is plain-text only (no markdown). Sections: subject line suggestion, greeting, numbered agenda items (no time allocations), desired outcome statement, sign-off.

**D-12:** Nothing written to disk. No wiki file, no git commit. Output displayed once and discarded.

**Revised requirement (MEET-01):** `/sara-minutes N` outputs markdown + email draft to screen. The original requirement stated "filed in the wiki" — explicitly revised. The wiki is the data source, not the destination.

### Claude's Discretion

- Exact wording of error messages for stage and type guards
- Whether the terminal output uses a visible separator (e.g. `---`) or a header (e.g. `## Email Version`) between markdown and plain-text blocks
- Whether `/sara-minutes` prints a summary line ("4 entities found: 1 DEC, 2 ACT, 1 RISK") before the minutes body

### Deferred Ideas (OUT OF SCOPE)

- Status curation during ingest — updating entity statuses when a meeting resolves a decision (v2)
- Agenda linked to ingest item — `/sara-agenda` creating a pending meeting item (v2)
</user_constraints>

---

## Summary

Phase 3 delivers two Claude Code skills that are both output-only generators. Neither writes to the wiki or makes git commits. `/sara-minutes N` reads the pipeline state and wiki artifacts for a completed meeting item, then synthesises structured markdown minutes plus a plain-text email version displayed to screen. `/sara-agenda` is fully stateless — it takes a single freeform prompt and generates a throw-away agenda draft.

Both skills follow patterns already established in Phases 1 and 2. The key implementation challenge for `/sara-minutes` is the guard logic (type first, then stage) and the entity aggregation loop — reading each wiki page referenced in `extraction_plan`, extracting the structured fields, and composing them into the minutes sections. The `sara-update` skill provides a direct template for the item-lookup and extraction_plan traversal pattern.

`/sara-agenda` is the simpler of the two — it mirrors the freeform prompt pattern from `sara-init`, with no state reads and no writes.

**Primary recommendation:** Write both skills as SKILL.md files following the existing four-field frontmatter convention (`name`, `description`, `argument-hint`, `allowed-tools`). `/sara-minutes` reuses the item-lookup + extraction_plan traversal from `sara-update`. `/sara-agenda` reuses the freeform prompt-and-respond pattern from `sara-init`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guard logic (type + stage) | SKILL.md process steps | pipeline-state.json (data source) | Guard runs at skill entry before any reads beyond the state file |
| Entity aggregation | SKILL.md process steps | wiki pages (data source) | Skill reads wiki pages listed in extraction_plan and extracts field values |
| Minutes formatting | SKILL.md process steps | — | Pure LLM text synthesis; no external formatter needed |
| Plain-text conversion | SKILL.md process steps | — | Rule-based: headings → CAPS, bullets → dashes, bold removed |
| Agenda generation | SKILL.md process steps | — | Stateless generation from user freeform input; no external state |

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code SKILL.md | v1 (project convention) | Slash command definition | Established pattern — all five prior skills use this format |
| pipeline-state.json | schema_version 1.0 | State store for item lookup and extraction_plan | Phase 1/2 locked data structure |
| wiki entity pages | schema_version 1.0 | Content source for minutes | Populated by `sara-update` in Phase 2 |

[VERIFIED: existing skill files in .claude/skills/]

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `$ARGUMENTS` variable | Receive the N argument in `/sara-minutes` | Used in every process skill — direct carry from sara-update pattern |
| Read tool | Read pipeline-state.json and wiki pages | Only tool permitted for JSON/markdown reads |
| Write tool | Not used in Phase 3 | Neither skill writes files |
| Bash tool | Not used in Phase 3 | Neither skill runs shell commands |

[VERIFIED: existing SKILL.md files confirm allowed-tools lists are enforced]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline entity field extraction (LLM reads page and extracts) | jq / frontmatter parser in Bash | LLM extraction is consistent with all prior skills; Bash tool not needed and adds complexity |
| Freeform prompt (D-09) for `/sara-agenda` | AskUserQuestion structured fields | Freeform is lower friction; user explicitly chose it over structured input |

---

## Architecture Patterns

### System Architecture Diagram

```
/sara-minutes N
─────────────────────────────────────────────────────────────
  User invokes command
        │
        ▼
  [1] Read pipeline-state.json
        │
        ├── item not found → ERROR: "No pipeline item N found"
        │
        ├── type != MTG → ERROR: "N is a <type> item. /sara-minutes only works on MTG items."
        │
        └── stage != complete → ERROR: "Item N is in stage '<stage>'. Run /sara-update N first."
        │
        ▼
  [2] For each entity in extraction_plan:
        Read wiki/<type>/<ID>.md
        Extract: id, title, status, owner, due-date (type-specific)
        │
        ▼
  [3] Read raw transcript for attendee list
  (if attendees not fully covered by STK pages)
        │
        ▼
  [4] Compose markdown minutes
        (Attendees / Decisions / Actions / Risks / Requirements)
        (omit empty sections)
        │
        ▼
  [5] Derive plain-text email version
        (CAPS headings, dashes for bullets, bold removed)
        │
        ▼
  [6] Output to terminal:
        [markdown block]
        ---
        [plain-text email block]

/sara-agenda
─────────────────────────────────────────────────────────────
  User invokes command
        │
        ▼
  [1] Output freeform prompt (no AskUserQuestion)
      "Describe the meeting: who's attending, topics, and goal."
        │
        ▼
  [2] Wait for user reply
        │
        ▼
  [3] Synthesise agenda (plain-text only):
        Subject line / Greeting / Numbered items / Outcome / Sign-off
        │
        ▼
  [4] Output to terminal — no file write, no commit
```

### Recommended Project Structure

```
.claude/skills/
├── sara-minutes/
│   └── SKILL.md    ← new Phase 3 skill
├── sara-agenda/
│   └── SKILL.md    ← new Phase 3 skill
├── sara-update/    ← reference: item-lookup + extraction_plan pattern
├── sara-ingest/    ← reference: type-guard pattern
└── sara-init/      ← reference: freeform-prompt pattern
```

### Pattern 1: Item Lookup and Type/Stage Guard (from sara-update / sara-ingest)

**What:** Read pipeline-state.json, find item by ID, validate type prefix, validate stage.
**When to use:** `/sara-minutes` — every invocation before any further reads.

```markdown
<!-- Source: .claude/skills/sara-update/SKILL.md Step 1 + .claude/skills/sara-ingest/SKILL.md Step 1 -->

Step 1 — Type guard and stage guard

Read `.sara/pipeline-state.json` using the Read tool.

Validate `$ARGUMENTS`: must be a non-empty pipeline item ID.
If empty: output usage message and STOP.

Find item with key `"{N}"` in the `items` object.
If not found: output "No pipeline item {N} found. Run /sara-ingest with no arguments
to see the pipeline status." and STOP.

Check `items["{N}"].type`. Expected type: `"meeting"`.
If type != "meeting":
  Output: "{N} is a {type} item. /sara-minutes only works on meeting items (MTG-NNN)."
  STOP.

Check `items["{N}"].stage`. Expected stage: `"complete"`.
If stage != "complete":
  Output: "Item {N} is in stage '{stage}'. Run /sara-update {N} first to complete
  the extraction pipeline before generating minutes."
  STOP.
```

[VERIFIED: sara-ingest SKILL.md line 41-50, sara-update SKILL.md lines 21-37]

### Pattern 2: Extraction Plan Traversal (from sara-update)

**What:** Iterate extraction_plan, read each wiki page, extract structured field values.
**When to use:** `/sara-minutes` Step 2 — entity aggregation.

```markdown
<!-- Source: .claude/skills/sara-update/SKILL.md Step 2 -->

For each artifact in `items["{N}"].extraction_plan`:

  Determine wiki page path from artifact.type:
  - "requirement" → wiki/requirements/{id}.md
  - "decision"    → wiki/decisions/{id}.md
  - "action"      → wiki/actions/{id}.md
  - "risk"        → wiki/risks/{id}.md

  Read the wiki page using the Read tool.
  Extract frontmatter fields relevant to that type.

  For decisions:  id, title, status, date, decision (body section)
  For actions:    id, title, status, owner, due-date
  For risks:      id, title, status, likelihood, impact
  For requirements: id, title, status
```

[VERIFIED: sara-update SKILL.md Step 2 action=="update" branch, wiki entity schemas in CLAUDE.md]

### Pattern 3: Freeform Prompt and Wait (from sara-init)

**What:** Output a plain-text question, wait for the user's reply, continue generation.
**When to use:** `/sara-agenda` — single interaction before generation.

```markdown
<!-- Source: .claude/skills/sara-init/SKILL.md Steps 2-4 -->

Step 1 — Collect meeting description

Output the following as plain text and wait for the user's reply:

> Describe the meeting: who will be attending (names and roles if relevant),
> what topics need to be covered, and what you want to achieve by the end.

Capture the user's reply as {meeting_description}.
Proceed to Step 2 — generate agenda.
```

[VERIFIED: sara-init SKILL.md lines 54-75]

### Pattern 4: Multi-Format Output in a Single Response

**What:** Output markdown block, then separator, then plain-text block — all in one terminal response.
**When to use:** `/sara-minutes` Step 6 — final output.

No prior skill does this, but the pattern is straightforward. Claude's discretion governs exact separator choice (e.g. `---` rule or `## Email Version` heading).

```markdown
<!-- Derived pattern — no prior skill precedent -->

Output:

---
[Markdown minutes block]

---

## Email Version

[Plain-text email block with CAPS headings, dashes for bullets, bold removed]
---
```

[ASSUMED — separator style is Claude's discretion per CONTEXT.md]

### Anti-Patterns to Avoid

- **Writing to wiki from `/sara-minutes`:** CONTEXT.md D-01 through D-08 are clear — output to screen only. The original REQUIREMENTS.md stated "filed in the wiki" but this was explicitly revised.
- **Reading `extraction_plan` from a non-`complete` item:** The stage guard must come before any extraction_plan read. A `pending` or `extracting` item may have an empty or partial `extraction_plan`.
- **Using AskUserQuestion for `/sara-agenda`:** D-09 explicitly specifies freeform plain text, not structured field collection.
- **Including time allocations in `/sara-agenda` output:** D-11 explicitly omits them.
- **Emitting empty sections in `/sara-minutes`:** D-06 — sections with no artifacts are omitted entirely from output.
- **Stage guard before type guard:** D-03 locks the order: type check → stage check → proceed.
- **Using Bash tool in either skill:** Neither skill needs shell commands. `allowed-tools` should list Read only (for `/sara-minutes`) or no tools at all (for `/sara-agenda`).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Frontmatter field extraction from wiki pages | Custom parser | LLM reads the page and extracts fields inline | All five prior skills use this pattern; consistent with project conventions |
| Entity type → wiki directory mapping | New lookup table | Reuse the same mapping already in sara-update | Mapping is stable and defined: requirement→requirements/, decision→decisions/, action→actions/, risk→risks/ |
| Item ID validation | New regex | Reuse the guard pattern from sara-update / sara-ingest | Pattern is identical — lookup by key in `items` object |

**Key insight:** Both Phase 3 skills are compositions of existing patterns, not new mechanisms. The research value here is confirmation that no new tools, libraries, or data structures are needed.

---

## Runtime State Inventory

> This section is SKIPPED. Phase 3 is greenfield skill creation — no rename, refactor, or migration. No existing runtime state is affected.

---

## Environment Availability

> Step 2.6: SKIPPED. Phase 3 is purely SKILL.md file creation. No external tools, runtimes, databases, or services are required beyond the Claude Code runtime already in use.

---

## Common Pitfalls

### Pitfall 1: Reading extraction_plan Before Confirming Stage

**What goes wrong:** The guard passes type but the extraction_plan is empty (item is `pending` or `extracting`). Minutes silently produce no entity sections.

**Why it happens:** Type check passes (it is a meeting), but stage is not `complete`. The extraction_plan is either `[]` or only partially approved.

**How to avoid:** Guard order per D-03: type → stage → proceed. Stage must be `complete` before touching extraction_plan.

**Warning signs:** Empty minutes output with no error message.

### Pitfall 2: Using the Item's Type Field vs. the ID Prefix

**What goes wrong:** Type guard checks `item.id` starts with "MTG" instead of `item.type == "meeting"`.

**Why it happens:** The ID prefix and the type field are redundant but not identical ("MTG" vs "meeting"). Checking the wrong one could silently pass or fail on edge cases.

**How to avoid:** Check `item.type == "meeting"` (the string stored in the `type` field by `sara-ingest`). The type guard message uses the full ID (e.g. "EML-001 is an email item").

**Warning signs:** Guard works on new items but fails on items created under an older schema if type field casing differs.

[VERIFIED: sara-ingest SKILL.md line 73-82 — `type` field stores lowercase `"meeting"`, `"email"`, `"slack"`, `"document"`]

### Pitfall 3: Attendee List Sourcing Gap

**What goes wrong:** Attendees section shows only STK pages that were formally created, missing participants who appear in the transcript but were not added as stakeholders during `/sara-discuss`.

**Why it happens:** `/sara-discuss` adds unknown stakeholders as STK pages — but only those the user confirmed. Ad-hoc attendees may be in the transcript but have no STK page.

**How to avoid:** Per D-04, the raw transcript should be read as a fallback for attendee context. The SKILL.md process should read the STK pages for each stakeholder referenced in the extraction_plan, then fall back to the transcript for names not covered.

**Warning signs:** Attendees section is shorter than the actual meeting participant list.

### Pitfall 4: Markdown in /sara-agenda Output

**What goes wrong:** Generator produces markdown-formatted output (headers with `##`, bold text, bullet `*`) instead of plain text.

**Why it happens:** The LLM defaults to markdown for structured output.

**How to avoid:** D-11 is explicit: output is plain-text only. SKILL.md process step must include instruction "output plain-text only — no markdown formatting." CAPS headings replace `##`. Dashes replace bullets.

**Warning signs:** User receives output with `##` headings or `**bold**` syntax that doesn't render well in an email client.

### Pitfall 5: Both Skills Listed with Unnecessary allowed-tools

**What goes wrong:** SKILL.md frontmatter lists `Write` or `Bash` in `allowed-tools`, creating risk of accidental wiki writes or shell execution.

**Why it happens:** Copy-paste from sara-update which does need those tools.

**How to avoid:**
- `/sara-minutes`: `allowed-tools: [Read]` — reads pipeline-state + wiki pages; no writes.
- `/sara-agenda`: `allowed-tools: []` — fully stateless; no file operations.

**Warning signs:** Claude uses Write tool during minutes generation.

---

## Code Examples

### /sara-minutes Frontmatter

```yaml
# Source: inferred from existing skills (.claude/skills/sara-*/SKILL.md)
---
name: sara-minutes
description: "Generate structured meeting minutes and email-ready draft from a completed meeting item"
argument-hint: "<ID>"
allowed-tools:
  - Read
---
```

[VERIFIED: frontmatter pattern from all six existing SKILL.md files]

### /sara-agenda Frontmatter

```yaml
# Source: inferred from existing skills (.claude/skills/sara-*/SKILL.md)
---
name: sara-agenda
description: "Generate an email-friendly meeting agenda draft from user-provided meeting description"
argument-hint: ""
allowed-tools: []
---
```

[ASSUMED — no prior skill is fully stateless; `allowed-tools: []` is structurally valid YAML but not confirmed against Claude Code documentation]

### Entity Field Extraction Reference

For each entity type, the fields `/sara-minutes` should extract from the wiki page frontmatter:

```
# Source: wiki/CLAUDE.md entity schemas (verified in sara-init SKILL.md)

Decision (wiki/decisions/DEC-NNN.md):
  id, title, status, date, decision (body section ## Decision)

Action (wiki/actions/ACT-NNN.md):
  id, title, status, owner, due-date

Risk (wiki/risks/RISK-NNN.md):
  id, title, status, likelihood, impact

Requirement (wiki/requirements/REQ-NNN.md):
  id, title, status
```

[VERIFIED: entity schemas in .claude/skills/sara-init/SKILL.md lines 180-287]

### Minutes Output Structure

```
# Markdown block (output first)

# Meeting Minutes — {item.id}
**Date:** {date from transcript or today}
**Source:** {item.filename}

## Attendees
- {name} ({role}) — STK-NNN or transcript-sourced

## Decisions
- **DEC-001** (Title here) — resolved: {decision body text}

## Actions
- **ACT-001** (Title) — Owner: {owner}, Due: {due-date}, Status: {status}

## Risks
- **RISK-001** (Title) — {status}, Likelihood: {likelihood}, Impact: {impact}

## Requirements
- **REQ-001** (Title) — Status: {status}

---

## Email Version   (or "---" separator — Claude's discretion)

MEETING MINUTES — {item.id}
DATE: {date}
SOURCE: {item.filename}

ATTENDEES
- {name} ({role})

DECISIONS
- DEC-001 (Title) — resolved: {decision body}

ACTIONS
- ACT-001 (Title) — Owner: {owner}, Due: {due-date}, Status: {status}

RISKS
- RISK-001 (Title) — {status}, Likelihood: {likelihood}, Impact: {impact}

REQUIREMENTS
- REQ-001 (Title) — Status: {status}
```

[ASSUMED — exact section ordering and formatting derived from D-06, D-07, D-08; Claude's discretion governs separator wording]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| MEET-01 required wiki write ("filed in the wiki") | MEET-01 revised: output-only to screen | Phase 3 context session 2026-04-27 | No wiki writes, no git commits in either Phase 3 skill |

**Deprecated/outdated:**
- ROADMAP.md line 96 still states the original MEET-01 wording ("markdown minutes filed in the wiki"). CONTEXT.md D-08 and the phase boundary statement supersede it. Plans must follow the revised spec.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `allowed-tools: []` is valid Claude Code SKILL.md frontmatter for a fully stateless skill | Standard Stack + Code Examples | If empty array is invalid, `/sara-agenda` may need `allowed-tools` omitted entirely or set to a comment — low risk, easy to verify at execution time |
| A2 | Separator style between markdown and email blocks is Claude's discretion — either `---` rule or `## Email Version` heading | Code Examples / Architecture Patterns | If user has a strong preference, they should be consulted before implementation; current discretion assignment in CONTEXT.md covers this |
| A3 | `/sara-minutes` should read the raw transcript (from `raw/meetings/` archive path) for attendee fallback | Common Pitfalls #3 | If the archive path differs from expected, the Read will fail silently — the SKILL.md process step should include error handling or a note that attendee fallback is best-effort |

---

## Open Questions

1. **Attendee resolution depth**
   - What we know: D-04 says "optionally read raw transcript for attendee list and context not captured in wiki entities"
   - What's unclear: When exactly should the transcript fallback trigger? Always? Only when STK count from extraction_plan < N attendees in transcript? Or only when the extraction_plan has zero STK entries?
   - Recommendation: Default to "always read transcript for attendees"; merge STK-page names with any additional names found in the transcript header/speaker labels. The SKILL.md process step should document this merge strategy.

2. **extraction_plan structure for update actions**
   - What we know: `sara-update` processes both `create` and `update` actions in extraction_plan. For `update` actions, `existing_id` is the wiki entity ID.
   - What's unclear: For `/sara-minutes`, should it aggregate entities from both create and update actions? An update to DEC-001 from this meeting is still a relevant minutes entry.
   - Recommendation: Yes — aggregate both create and update actions. The minutes should represent "what this meeting did to the wiki," per the `specifics` note in CONTEXT.md. The SKILL.md should not filter by action type.

3. **Empty extraction_plan on a complete item**
   - What we know: An item can reach `complete` stage with an empty `extraction_plan` (user rejected all artifacts in `/sara-extract`, then ran `/sara-update` anyway — the commit still advances stage).
   - What's unclear: Should `/sara-minutes` handle this gracefully or is it an error?
   - Recommendation: Graceful handling. Output a minimal minutes document with "No wiki entities were recorded for this meeting" in each section rather than an error. The meeting still happened — attendees and date may still be recoverable from the transcript.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test framework configured in this project) |
| Config file | None |
| Quick run command | Run `/sara-minutes MTG-001` against a completed pipeline item in a test wiki |
| Full suite command | Same — manual verification against success criteria |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MEET-01 (revised) | `/sara-minutes N` outputs markdown + plain-text to screen for a complete MTG item | smoke | Manual — invoke skill and inspect output | N/A |
| MEET-01 type guard | Non-MTG item returns clear error | smoke | Manual — invoke with EML item ID | N/A |
| MEET-01 stage guard | Non-complete item returns clear error | smoke | Manual — invoke with pending/extracting/approved item | N/A |
| MEET-02 | `/sara-agenda` outputs plain-text agenda draft with no file writes | smoke | Manual — invoke skill, inspect output, confirm no new wiki files | N/A |

### Sampling Rate

- **Per task commit:** Manual invocation of the skill under development
- **Per wave merge:** Full success criteria checklist (all 3 success criteria from ROADMAP.md)
- **Phase gate:** All 3 success criteria pass before `/gsd-verify-work`

### Wave 0 Gaps

None — this project uses manual verification only. No test framework install needed.

---

## Security Domain

Phase 3 introduces no new attack surface. Both skills are output-only generators with no network calls, no file writes, and no user-supplied data written to disk. The only reads are from the local filesystem (pipeline-state.json and wiki pages). No ASVS categories apply beyond what was already in scope for Phases 1 and 2.

---

## Project Constraints (from CLAUDE.md)

The project root CLAUDE.md contains GSD-specific phase completion instructions and wiki behavioral rules. Relevant constraints for Phase 3:

1. All wiki entity pages include a `schema_version: "1.0"` field (quoted string, not float) — `/sara-minutes` reads but does not write these, so this constraint is informational only.
2. `vertical` and `department` are always separate fields in stakeholder pages — relevant when reading STK pages for attendee information.
3. `related` fields use entity IDs only, never file paths or wikilinks — relevant to how `/sara-minutes` formats cross-references in output (for display, wikilinks in markdown body are acceptable per sara-update pattern, but YAML frontmatter must use plain IDs).
4. GSD phase completion steps (update ROADMAP.md, STATE.md, PROJECT.md) — planner should include a final task for this after both skills are verified.

[VERIFIED: CLAUDE.md at project root, lines 149-303]

---

## Sources

### Primary (HIGH confidence)
- `.claude/skills/sara-update/SKILL.md` — item lookup pattern, extraction_plan traversal, entity type → directory mapping, stage guard implementation
- `.claude/skills/sara-ingest/SKILL.md` — type validation pattern, item ID format, type field values
- `.claude/skills/sara-init/SKILL.md` — freeform prompt pattern (Steps 2-4), SKILL.md frontmatter convention, entity schemas
- `.planning/phases/03-meeting-specialisation/03-CONTEXT.md` — all locked decisions D-01 through D-12
- `wiki/CLAUDE.md` (project CLAUDE.md) — entity schema field definitions

### Secondary (MEDIUM confidence)
- `.planning/PROJECT.md` — command taxonomy, ingest pipeline overview, requirement status
- `.planning/REQUIREMENTS.md` — MEET-01 and MEET-02 requirement text
- `.planning/phases/02-ingest-pipeline/02-CONTEXT.md` — stage guard pattern D-13

### Tertiary (LOW confidence)
- Assumed: `allowed-tools: []` is valid Claude Code SKILL.md syntax for a stateless skill (A1)
- Assumed: Minutes output separator and summary line per Claude's discretion scope (A2, A3)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components verified against existing skill files
- Architecture: HIGH — patterns are direct reuse of verified Phase 2 skills
- Pitfalls: HIGH — most derived from examining existing skill notes and guard patterns already in production
- Output format: MEDIUM — exact wording and separator are Claude's discretion; structure is locked by D-06 through D-08

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (stable domain — SKILL.md conventions are unlikely to change)
