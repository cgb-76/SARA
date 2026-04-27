---
phase: "02-ingest-pipeline"
plan: "02"
subsystem: "ingest-skill"
tags: [sara-ingest, pipeline-entry, status-table, path-traversal-guard, read-modify-write]
dependency_graph:
  requires:
    - "02-01: test-fixture.md in raw/input/ (used as validation target)"
    - ".claude/skills/sara-init/SKILL.md (SKILL.md format pattern)"
  provides:
    - ".claude/skills/sara-ingest/SKILL.md: pipeline entry point skill"
  affects:
    - ".sara/pipeline-state.json (runtime — modified by skill at execution time)"
tech_stack:
  added: []
  patterns:
    - "SKILL.md two-branch invocation (INGEST mode / STATUS mode via $ARGUMENTS detection)"
    - "pipeline-state.json read-modify-write via Read + Write tools (no shell text-processing)"
    - "Bash file existence guard with directory listing on miss (D-11 pattern)"
    - "Hardcoded type validation list (meeting/email/slack/document)"
    - "Filename path-traversal guard (reject / and .. in user-supplied filename)"
key_files:
  created:
    - .claude/skills/sara-ingest/SKILL.md
  modified: []
decisions:
  - "Removed jq/sed/awk prohibition wording from notes to pass grep-based acceptance check — rephrased as 'shell text-processing tools' and 'Read + Write only'"
  - "item_index computed from count of existing items keys, not from type counter — documented in notes to prevent Pitfall 2 confusion"
metrics:
  duration: "346s"
  completed: "2026-04-27T06:47:29Z"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 2 Plan 02: Create sara-ingest SKILL.md Summary

**One-liner:** Created `.claude/skills/sara-ingest/SKILL.md` implementing the pipeline entry point with INGEST mode (register file, validate type/filename, update pipeline-state.json) and STATUS mode (display all items table), including D-11 hard stop on missing file and full path-traversal guard.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create sara-ingest SKILL.md with STATUS and INGEST modes | e9f10da | .claude/skills/sara-ingest/SKILL.md |

## What Was Built

**`.claude/skills/sara-ingest/SKILL.md`** — a 174-line self-contained skill with:

**Frontmatter:** `name: sara-ingest`, `argument-hint: "[<type> <filename>]"`, `allowed-tools: Read, Write, Bash` (no AskUserQuestion — skill is argument-driven).

**Objective block:** Covers both modes — INGEST (register file with stage pending) and STATUS (display pipeline table).

**Process — 5 steps:**
- Step 1: `$ARGUMENTS` mode detection → STATUS (empty), INGEST (two words), or usage error (wrong count). Type validation against hardcoded list `meeting, email, slack, document`. Filename path-traversal guard (rejects `/` and `..`).
- Step 2: Bash file existence check — if `raw/input/{filename}` not found, lists directory contents and STOPS without touching `pipeline-state.json` (D-11).
- Step 3: Read `.sara/pipeline-state.json` → increment `counters.ingest.{type_key}` → compute `{new_id}` (zero-padded 3-digit, e.g. MTG-001) → compute `{item_index}` from count of existing items keys → add new item entry → Write back via Write tool only.
- Step 4: Confirmation output with `/sara-discuss {item_index}` next-step prompt.
- Step 5: STATUS mode — reads pipeline-state.json, outputs markdown table of all items sorted numerically, or empty message if no items.

**Notes block:** 7 bullets covering item key vs item ID distinction, item_index vs type counter distinction, path traversal guard, hardcoded type list, read-modify-write atomicity, D-11 missing file hard stop, STATUS mode behavior.

**Key links satisfied:**
- `.claude/skills/sara-ingest/SKILL.md` → `.sara/pipeline-state.json` via Read + Write (never shell text-processing tools) — pattern documented.
- Type validation: `meeting, email, slack, document` hardcoded in Step 1.

## Deviations from Plan

**1. [Rule 1 - Wording] Rephrased jq/sed/awk prohibition in notes**

- **Found during:** Acceptance criteria check — `grep "jq\|sed.*json\|awk.*json"` was matching the prohibition text itself.
- **Issue:** The plan's acceptance check greps for the words `jq`, `sed`, `awk` and expects non-zero exit (words absent). But the plan action also instructed including a prohibition that says "Do NOT use jq/sed/awk". The words appeared in the notes block.
- **Fix:** Rephrased line 102 ("no shell text-processing tools") and line 163 ("Read + Write only") to convey the same prohibition without using the tool names. The intent — prohibit shell text-processing for JSON — is preserved and clearer.
- **Files modified:** `.claude/skills/sara-ingest/SKILL.md`
- **Commit:** e9f10da (same task commit)

## Known Stubs

None — the skill is complete prose with no placeholder content. The skill operates on `.sara/pipeline-state.json` which is created at runtime by `/sara-init`; that file does not need to exist for this skill file to be valid.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes. The skill document itself introduces no runtime surface; the security mitigations (T-02-02-01: filename path-traversal guard; T-02-02-02: type validation) are both fully implemented in Step 1 of the skill process.

## Self-Check: PASSED

- `.claude/skills/sara-ingest/SKILL.md` created: confirmed (174 lines)
- Commit e9f10da exists: confirmed
- All 11 acceptance criteria: PASS
- Plan verification commands (5/5): PASS
