# Phase 3: Meeting Specialisation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 03-meeting-specialisation
**Areas discussed:** Minutes file location & ID, Minutes structure & email draft, Minutes stage guard, Agenda interaction model

---

## Minutes file location & ID

| Option | Description | Selected |
|--------|-------------|----------|
| wiki/minutes/ + MIN-NNN | New dedicated directory, new entity ID type MIN-NNN tracked in pipeline-state | |
| wiki/minutes/, no entity ID | New directory, filed by ingest ID (e.g. MTG-001-minutes.md), no entity type | |
| Freeform, no wiki directory | Minutes output-only — no wiki file, nothing written to disk | ✓ |

**User's choice:** Freeform, no wiki directory
**Notes:** User selected output-only. This conflicted with the written MEET-01 requirement ("filed in the wiki"). User confirmed: MEET-01 should be revised — minutes are output-only, not committed to the wiki.

---

## MEET-01 requirement revision

| Option | Description | Selected |
|--------|-------------|----------|
| Update MEET-01: output only | Revise requirement — /sara-minutes outputs to screen only | ✓ |
| Write file on confirm | Generate to screen, then optionally write on user confirmation | |
| Keep MEET-01 as written | Minutes ARE committed to the wiki | |

**User's choice:** Update MEET-01 — output only
**Notes:** Explicit override of written requirement. CONTEXT.md records the revised intent.

---

## Minutes structure & email draft

| Option | Description | Selected |
|--------|-------------|----------|
| Standard minutes structure | Date, attendees, decisions, actions, next meeting — from transcript | |
| Wiki-entity cross-linked structure | Same as standard but references DEC-NNN, ACT-NNN, etc. from post-update wiki | ✓ (via write-in) |
| Minimal: summary + actions only | Brief summary paragraph + flat action list | |

**User's choice:** Write-in — "Minutes are run after processing, based on the processed data added to the wiki. A meeting that resolves a decision or mitigates a risk should say so in its minutes."
**Notes:** User explicitly wants wiki artifacts (not raw transcript) as the source of truth. Outcomes stated explicitly (e.g. "DEC-003 — resolved: Stripe selected"). Also flagged future curation concern (noted as deferred).

### Minutes source follow-up

| Option | Description | Selected |
|--------|-------------|----------|
| Read extraction_plan + wiki pages | Read extraction_plan from pipeline-state, then read each referenced wiki page | ✓ |
| Read wiki pages by scanning index.md | Use ingest item ID to find artifacts via index.md | |

**User's choice:** Option 1 (extraction_plan), AND "fails with message if called out of order"
**Notes:** Confirmed stage guard (complete only) in same answer.

### Status changes in minutes

| Option | Description | Selected |
|--------|-------------|----------|
| State the outcome explicitly | "DEC-003 (Payment gateway choice) — resolved: Stripe selected." | ✓ |
| Just list artifact with current status | "DEC-003: accepted." | |

**User's choice:** State the outcome explicitly

---

## Email-ready version

| Option | Description | Selected |
|--------|-------------|----------|
| Same content, plain text | Strip markdown, same sections, copy-paste ready | ✓ |
| Shorter summary version | Condensed: 2-3 sentence summary + action list | |

**User's choice:** Same content, plain text

---

## Minutes stage guard

| Option | Description | Selected |
|--------|-------------|----------|
| complete only | Must have passed /sara-update N | ✓ |
| complete or approved | Also allow post-extract, pre-commit | |

**User's choice:** complete only

### Type guard wording

| Option | Description | Selected |
|--------|-------------|----------|
| Clear type error + guidance | Names the type, explains what to do instead | ✓ |
| Type error only, no guidance | Short terse message | |

**User's choice:** Clear type error + guidance

---

## Agenda interaction model

| Option | Description | Selected |
|--------|-------------|----------|
| One prompt per field | Separate prompts: attendees, topics, goal | |
| Single freeform prompt | One open prompt, LLM structures the output | ✓ |
| AskUserQuestion structured | TUI with multiSelect from stakeholder registry | |

**User's choice:** Single freeform prompt

### Agenda output format

| Option | Description | Selected |
|--------|-------------|----------|
| Plain-text email-ready draft | Subject, greeting, numbered items, outcome, sign-off — no markdown | ✓ (with modification) |
| Markdown + plain-text pair | Both formats in one output | |
| Structured markdown only | Headings only, not email-ready | |

**User's choice:** Option 1 but WITHOUT time allocations
**Notes:** User explicitly removed time allocations from the plain-text email template.

---

## Claude's Discretion

- Exact wording of stage and type error messages
- Separator style between markdown and plain-text email blocks in /sara-minutes output
- Whether /sara-minutes prints an entity summary line before the minutes body

## Deferred Ideas

- Status curation during ingest (v2): /sara-ingest or related commands should update entity statuses (e.g. DEC-NNN to "accepted") when a meeting resolves them
- Agenda linked to ingest item (v2): /sara-agenda creates a pending meeting item, linked when transcript is later ingested — already noted in PROJECT.md
