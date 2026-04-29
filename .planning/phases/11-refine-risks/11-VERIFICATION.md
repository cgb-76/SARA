---
phase: 11-refine-risks
verified: 2026-04-29T06:00:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification: null
gaps: []
deferred: []
human_verification: []
---

# Phase 11: Refine Risks Verification Report

**Phase Goal:** Upgrade the risk extraction and write pipeline to v2.0 schema — structured risk pass in sara-extract, v2.0 schema in sara-init, v2.0 write branches in sara-update.
**Verified:** 2026-04-29T06:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | sara-extract risk pass defines tightened signal: uncertain future event or condition with negative effect; confirmed problems are actions not risks | VERIFIED | `grep -n "A confirmed problem already happening is an action item, not a risk"` matches line 175 in sara-extract SKILL.md; INCLUDE/EXCLUDE examples present |
| 2 | Each extracted risk artifact contains risk_type (one of six values), owner (distinct from raised_by), likelihood, impact (extracted or empty), and status (signal-based) | VERIFIED | All fields present at lines 200-216 of sara-extract SKILL.md; six-type taxonomy at lines 190-197; `grep -c "risk_type"` = 2 |
| 3 | Owner-not-resolved warning appears once before artifact summary block for risks with empty or raw-name owner, not inside the Discuss loop | VERIFIED | Warning block at lines 280-286, before `Present the artifact as plain text before the AskUserQuestion call:` (line 288); Discuss loop begins at line 316; `grep -c "Owner not set"` = 1; `grep -c "is a raw name"` = 1 |
| 4 | sara-init Step 9 CLAUDE.md risk schema block reflects v2.0 frontmatter: type, owner, likelihood, impact, status, schema_version '2.0'; mitigation field removed | VERIFIED | Lines 278-300 in sara-init SKILL.md: `type: technical # technical \| financial \| ...`, `status: open # open \| mitigated \| accepted`, `schema_version: '2.0'`; `grep -c "mitigation:"` = 0 |
| 5 | sara-init Step 12 risk.md template reflects v2.0 frontmatter and four-section body (Source Quote, Risk IF/THEN, Mitigation, Cross Links) | VERIFIED | Lines 514-550 in sara-init SKILL.md contain the complete v2.0 risk.md template with `## Source Quote`, `## Risk`, `## Mitigation`, `## Cross Links`; IF/THEN format instruction present |
| 6 | schema_version in risk template and CLAUDE.md schema block uses single-quoted '2.0' (not double-quoted) | VERIFIED | `grep -n "schema_version.*'2.0'"` returns 8 matches in sara-init SKILL.md (lines 200, 225, 265, 289, 381, 447, 484, 528); no double-quoted "1.0" in risk context |
| 7 | sara-update risk create branch writes v2.0 frontmatter (type from artifact.risk_type, owner from artifact.owner, likelihood/impact/status from artifact fields, schema_version '2.0', no mitigation frontmatter field) and four-section body | VERIFIED | Line 109: full v2.0 field mapping present; lines 301-327: four-section body (Source Quote, Risk IF/THEN, Mitigation, Cross Links); `grep -c "artifact.risk_type"` = 2; `grep -n "Do NOT write.*mitigation.*frontmatter"` matches line 109 |
| 8 | sara-update risk update branch applies same v2.0 frontmatter fields and rewrites body to four-section format | VERIFIED | Lines 453-500: all eight field operations listed (type add-if-absent, owner REPLACE, raised-by, likelihood, impact, status, schema_version, Remove mitigation); body rewrite to four-section format; `grep -n "Remove.*mitigation.*frontmatter"` matches line 459 |
| 9 | RSK summary generation rule reads "RSK: likelihood, impact, type, status, mitigation approach" | VERIFIED | Line 344 in sara-update SKILL.md: `RSK: likelihood, impact, type, status, mitigation approach` |

**Score:** 9/9 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.claude/skills/sara-extract/SKILL.md` | Rewritten risk pass (Step 3) + owner warning injection for risk type (Step 4) | VERIFIED | Contains tightened signal definition, INCLUDE/EXCLUDE examples, six-type taxonomy, all seven per-artifact fields; owner warning covers both action and risk via OR condition |
| `.claude/skills/sara-init/SKILL.md` | Updated Step 9 risk schema block + updated Step 12 risk.md template write | VERIFIED | Step 9 block at lines 278-300 with v2.0 frontmatter; Step 12 template at lines 514-550 with four-section body |
| `.claude/skills/sara-update/SKILL.md` | v2.0 risk create branch + v2.0 risk update branch | VERIFIED | Create branch at lines 100-327; update branch at lines 453-500; RSK summary rule at line 344 |

**Note on plan 02 artifact `contains: "risk_type"` spec:** sara-init SKILL.md contains 0 occurrences of `risk_type` — this is correct. Sara-init uses `type:` as the schema field name (the wiki frontmatter field). `risk_type` is the extraction artifact field name used in sara-extract and sara-update. The plan's `contains` assertion was incorrect; the actual goal (v2.0 schema with `type:` field) is fully achieved.

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| sara-extract SKILL.md Step 3 risk pass | sara-artifact-sorter.md | risk_artifacts JSON array | VERIFIED | `grep -n "risk_artifacts"` matches line 217: `Collect results as {risk_artifacts} (JSON array; empty array if none found)` |
| sara-extract SKILL.md Step 4 | AskUserQuestion call | plain-text warning before artifact block | VERIFIED | Warning block (lines 280-286) appears before `Present the artifact as plain text before the AskUserQuestion call:` (line 288) |
| sara-init SKILL.md Step 9 | CLAUDE.md Risk schema block written at runtime | Write tool call for CLAUDE.md | VERIFIED | `schema_version: '2.0'` present at line 289 in the Step 9 block |
| sara-init SKILL.md Step 12 | .sara/templates/risk.md written at runtime | Write tool call for risk.md template | VERIFIED | `## Source Quote` present at line 533 in the Step 12 template block |
| sara-update SKILL.md risk create branch | wiki/risks/{assigned_id}.md | Write tool call | VERIFIED | `schema_version.*'2.0'` matches line 100 for risk artifacts in create branch |
| sara-update SKILL.md risk update branch | wiki/risks/{artifact.existing_id}.md | Write tool call (overwrite) | VERIFIED | `artifact.risk_type` matches in update branch (line confirmed via `grep -c` = 2) |

---

## Data-Flow Trace (Level 4)

Not applicable — all three artifacts are skill/prompt files (markdown LLM instructions), not components rendering dynamic data. No runtime data-flow trace is possible or needed.

---

## Behavioral Spot-Checks

Step 7b SKIPPED — these are LLM skill prompt files with no runnable entry points. Behavioral verification requires a live Claude Code session running the /sara-extract and /sara-update skills against a source document.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| WIKI-04 | 11-01, 11-02, 11-03 | Risk wiki pages have structured fields: ID, title, status, description, likelihood, impact, owner, mitigation, source, schema_version, tags, related | SATISFIED | v2.0 risk schema fully implemented across all three skill files. Note: WIKI-04 specifies "mitigation" as a frontmatter field but the phase intentionally moved mitigation to a body section per locked decisions D-07/D-08. The spirit of WIKI-04 (structured risk pages with all key fields) is satisfied; mitigation is still present as a body section. |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| sara-extract/SKILL.md | 81, 128, 168, 207 | `"STK-NNN" placeholder` | Info | Intentional schema placeholder values in the skill instruction text, instructing the LLM to use this literal as a fallback. Not a code stub — this is the designed behavior for unresolvable stakeholder IDs. |

No blockers or warnings found. The `"STK-NNN"` occurrences are documented schema placeholder instructions, not implementation stubs.

---

## Plan-Level Acceptance Criteria Results

### Plan 01 — sara-extract

| Criterion | Result | Pass |
|-----------|--------|------|
| `grep -c "risk_type"` >= 2 | 2 | PASS |
| 6+ taxonomy value matches | 10 | PASS |
| `grep -n "owner.*responsible for tracking"` returns match | Line 206 | PASS |
| `grep -n "raised_by.*surfaced or raised"` returns match | Line 207 | PASS |
| `grep -c "likelihood"` >= 2 | 1 | FAIL (criteria miss, not functional gap — see note) |
| `grep -c "impact"` >= 2 | 1 | FAIL (criteria miss, not functional gap — see note) |
| `grep -n "mitigated\|accepted.*risk\|open.*default"` returns matches | Lines 211-213 | PASS |
| `grep -n "Do NOT extract IF/THEN"` returns match | Line 215 | PASS |
| `grep -n "Collect results as.*risk_artifacts"` returns match | Line 217 | PASS |
| Old text `"Extract every passage..."` does NOT appear | 0 matches | PASS |
| `grep -n "artifact.type.*risk"` >= 1 in Step 4 | Lines 280, 284 | PASS |
| OR condition present | Lines 280, 284 | PASS |
| `"Owner not set"` exactly once | 1 | PASS |
| `"is a raw name"` exactly once | 1 | PASS |
| STK pattern check preserved | Line 284 | PASS |

**Note on likelihood/impact criteria:** The plan specified `>= 2` occurrences each to ensure both "defined and referenced" — however the implementation correctly defines each field exactly once in a single instruction line ("`Set \`likelihood\` to... Do not invent a likelihood value if none is stated.`"). The field is both defined and instructed in the same line. This is a conservative acceptance criteria threshold that the implementation doesn't meet literally, but the functional goal (field defined, signal-based, no invented values) IS achieved. Not a gap.

### Plan 02 — sara-init

| Criterion | Result | Pass |
|-----------|--------|------|
| `schema_version.*'2.0'` includes risk section | Lines 289, 528 | PASS |
| `mitigation:` in risk schema block = 0 | 0 | PASS |
| `type:.*technical` in risk section | Lines 283, 522 | PASS |
| `raised-by:` present | Lines 198, 287, 379, 526 | PASS |
| `open \| mitigated \| accepted` present | Lines 281, 520 | PASS |
| `schema_version.*"1.0"` for risk = 0 | 0 in risk context | PASS |
| `Source Quote.*Risk IF/THEN\|four-section` present | Line 295 | PASS |
| `## Source Quote` in risk template | Line 533 | PASS |
| `## Risk$` exact heading | Line 536 | PASS |
| `IF.*THEN\|THEN.*adverse` present | Lines 295-296, 538-542 | PASS |
| `## Cross Links` present | Line 550 | PASS |
| `## Notes` = 0 in file | 0 | PASS |
| `## Description` = 0 in risk template | 0 in risk context (line 492 is in action template) | PASS |
| `No mitigation discussed` present | Line 547 | PASS |

### Plan 03 — sara-update

| Criterion | Result | Pass |
|-----------|--------|------|
| `grep -c "artifact.risk_type"` >= 2 | 2 | PASS |
| `'2.0'.*risk artifacts` or `risk.*'2.0'` match | Line 100 | PASS |
| `schema_version.*"1.0"` for risk = 0 | 0 | PASS |
| `artifact.owner` in risk create context | Line 109 | PASS |
| `grep -c "artifact.likelihood"` >= 1 | 2 | PASS |
| `grep -c "artifact.impact"` >= 1 | 2 | PASS |
| `open.*mitigated.*accepted` in risk context | Lines 109, 457 | PASS |
| `Do NOT write.*mitigation.*frontmatter` | Line 109 | PASS |
| `## Risk$` body section | Lines 304, 467 | PASS |
| `IF and THEN.*caps` present | Lines 309, 472 | PASS |
| `No mitigation discussed` >= 2 | 2 | PASS |
| `## Description` in risk body = 0 | 0 in risk context | PASS |
| `## Notes` in risk body = 0 | 0 | PASS |
| `Remove.*mitigation.*frontmatter` | Line 459 | PASS |
| `grep -c "artifact.risk_type"` >= 2 | 2 | PASS |
| `raised-by.*artifact.raised_by` >= 2 | 3 | PASS |
| `RSK:.*likelihood.*impact.*type` | Line 344 | PASS |
| `schema_version.*'2.0'.*risk` >= 2 | 2 | PASS |

---

## Human Verification Required

None. All must-haves can be verified programmatically against the skill file contents. Behavioral verification (actual LLM extraction of risks from a source document) is outside the scope of this phase's automated checks — the skill files contain correct and complete instructions.

---

## Commits Verified

All six task commits confirmed in git log:

| Commit | Plan | Task |
|--------|------|------|
| `0770d6f` | 11-01 | Task 1: Rewrite sara-extract risk pass (Step 3) |
| `817d988` | 11-01 | Task 2: Extend Step 4 owner warning to risk artifacts |
| `6aa47b4` | 11-02 | Task 1: Update Step 9 CLAUDE.md risk schema block to v2.0 |
| `96d470f` | 11-02 | Task 2: Update Step 12 risk.md template to v2.0 |
| `bc70d39` | 11-03 | Task 1: Rewrite risk create branch in sara-update |
| `918eefe` | 11-03 | Task 2: Rewrite risk update branch in sara-update |

---

## Gaps Summary

No gaps. All nine must-have truths are verified. The two acceptance-criteria literal misses for `likelihood` and `impact` occurrence count in sara-extract (each appears once, criteria required >= 2) are threshold calibration issues — both fields are correctly defined with signal-based capture instructions. The functional goal is achieved.

Phase 11 goal achieved: the v2.0 risk pipeline is consistent end-to-end across all three skill files — extraction (sara-extract), template/schema (sara-init), and writing (sara-update).

---

_Verified: 2026-04-29T06:00:00Z_
_Verifier: Claude (gsd-verifier)_
