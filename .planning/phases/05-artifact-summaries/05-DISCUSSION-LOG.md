# Phase 5: artifact-summaries - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 05-artifact-summaries
**Areas discussed:** Scope, Skills in scope, Config location, Migration/back-fill, Summary content, Length, Back-fill command

---

## Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Summary field on entities | Add a 'summary' field to each entity, LLM-generated at sara-update time | ✓ |
| New /sara-summary command | A standalone digest/overview command | |
| Something else | Freeform | |

**User's choice:** Summary field on entities, plus grep-extract pattern for read-heavy skills.
**Notes:** User described the core problem: at 500+ artifacts, full-page reads in sara-extract blow out context. The summary field enables a compact grep-extract pattern. User specified the field should be configurable in length.

---

## Skills switching to grep-extract pattern

| Option | Description | Selected |
|--------|-------------|----------|
| /sara-extract | Dedup/cross-ref at Step 3 | ✓ |
| /sara-discuss | Cross-link surfacing | ✓ |
| /sara-minutes | Reads entities for meeting N | |
| /sara-update | Writes artifacts (needs to generate summaries) | ✓ |

**Notes:** /sara-minutes was not selected — it reads a small set of entities for a specific meeting item (bounded by the extraction_plan), so full-page reads are appropriate there. sara-update was selected for generation, not grep-extract reading.

---

## Config location

| Option | Description | Selected |
|--------|-------------|----------|
| .sara/pipeline-state.json | Central state/config store | ✓ |
| wiki/CLAUDE.md | Behavioral contract | |
| .sara/config.json | Separate config file | |

**User's choice:** pipeline-state.json — consistent with existing pattern.

---

## Summary content (type-specific)

**User's input:** Content depends on artifact type. A decision needs options + chosen option. A risk needs likelihood, impact, mitigation. Status and dates are important for update decisions (e.g. knowing if an action is already done before deciding to update it).

**Resolved:** Type-specific prose in a single `summary` field:
- REQ: title, status, one-line description
- DEC: options, chosen option, status, date
- ACT: owner, due-date, status
- RISK: likelihood, impact, mitigation, status
- STK: vertical, department, role

---

## Length

| Option | Description | Selected |
|--------|-------------|----------|
| max_words: 50 | Word count, ~2-3 sentences | ✓ |
| max_chars: 300 | Character count | |
| You decide | | |

**User's choice:** max_words: 50.

---

## Back-fill command

**Initial proposal:** New /sara-summarize skill.
**User challenge:** "Why are we creating another skill for this?"
**Resolution:** Back-fill folded into `/sara-lint` — a maintenance skill already earmarked in v2 requirements. User noted: "Call it /sara-lint because this is a maintenance activity and we'll be able to add these kind of things to the linting process over time."

**UX:** Dry-run first (count + one preview), then confirm before batch write + commit.

---

## Claude's Discretion

- Exact grep command syntax for grep-extract
- Order of artifact type processing in /sara-lint
- Whether `summary` field is inserted at top or end of frontmatter
- Exact lint confirmation prompt wording

## Deferred Ideas

- Future /sara-lint checks: orphans, broken cross-refs, stale actions, index validation — v2
- Structured per-type summary sub-fields — v2 if single-field precision proves insufficient
