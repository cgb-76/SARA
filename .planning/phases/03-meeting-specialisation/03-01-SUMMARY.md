---
plan: 03-01
phase: 03-meeting-specialisation
status: complete
completed: 2026-04-27
---

# Summary: Plan 03-01 — sara-minutes skill

## What was built

Created `.claude/skills/sara-minutes/SKILL.md` — a read-only `/sara-minutes` slash command skill.

## Key decisions implemented

- **D-01/D-02/D-03**: Type guard (`item.type == "meeting"`) runs before stage guard (`item.stage == "complete"`) — non-meeting items are rejected before reaching extraction_plan traversal
- **D-04/D-05**: Both `create` and `update` artifacts from `extraction_plan` are aggregated; entity IDs use `assigned_id` (create) and `existing_id` (update); attendees resolved from STK wiki pages + raw transcript with fallback
- **D-06**: Empty sections (Decisions, Actions, Risks, Requirements) are silently omitted
- **D-07**: Plain-text email version derived from markdown with CAPS headings and bold markers stripped
- **D-08**: Both blocks output in a single terminal response with `---` separator

## Artifacts

- `.claude/skills/sara-minutes/SKILL.md` — 7-step process: item lookup + guards, extraction_plan traversal, attendee resolution, date/source, markdown minutes composition, plain-text derivation, dual output

## Self-Check: PASSED

- ✓ `name: sara-minutes` in frontmatter
- ✓ `allowed-tools: [Read]` only — no Write, no Bash
- ✓ Type guard before stage guard
- ✓ Handles both `create` and `update` extraction_plan actions
- ✓ Wiki dir mapping: requirement→wiki/requirements/, decision→wiki/decisions/, action→wiki/actions/, risk→wiki/risks/
- ✓ Email Version section present
- ✓ No file write instructions anywhere in process steps
- ✓ MEET-01 requirement addressed
