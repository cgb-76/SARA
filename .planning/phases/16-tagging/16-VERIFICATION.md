---
phase: 16-tagging
verified: 2026-05-01T00:00:00Z
status: human_needed
score: 6/6 must-haves verified
overrides_applied: 0
human_verification:
  - test: "TAG-08 — D-08 runs on every sara-lint invocation (no opt-in flag)"
    expected: "Invoking /sara-lint completes Steps 1-5 then unconditionally enters Step 6 without any flag or condition gate other than the empty-wiki check"
    why_human: "The prose text does not include a conditional guard or flag, but verifying runtime behaviour — that an agent actually executes Step 6 on every run — requires observing a live sara-lint session"
  - test: "TAG-04 — Phase 2 assignment pass fires only AFTER vocabulary is approved"
    expected: "If the user selects Skip at the AskUserQuestion gate, no artifact files are read or written by the assignment pass; Phase 2 is unreachable via Skip path"
    why_human: "The prose structure is correct (Phase 2 block appears only under the Approve branch, with explicit STOP on Skip), but runtime ordering of LLM instruction following cannot be verified by static grep"
---

# Phase 16: Tagging Verification Report

**Phase Goal:** Activate the `tags: []` schema field by implementing sara-lint D-08 — a whole-wiki two-phase LLM pass that derives an emergent tag vocabulary from the corpus and assigns tags to every artifact page.
**Verified:** 2026-05-01
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | sara-lint runs a two-phase tag curation pass (vocabulary derivation + assignment) after the per-finding loop on every invocation | VERIFIED | Step 6 block at line 390, after Step 5 ends (line 315 "Continue to next finding."), before `</process>` at line 501. "Phase 1: Vocabulary derivation pass" at line 402; "Phase 2: Assignment pass" at line 435. |
| 2 | The user approves a derived vocabulary before any tags are written to wiki pages | VERIFIED | AskUserQuestion gate at line 418-431. Options `["Approve", "Edit", "Skip"]` confirmed. Phase 2 only entered via `"If \"Approve\" (or after Edit confirmed): store the approved list as {approved_vocabulary}. Continue to Phase 2."` Skip path issues STOP before Phase 2. |
| 3 | Tags written to artifact pages are lowercase kebab-case strings stored as inline YAML arrays | VERIFIED | Line 411: "Kebab-case normalisation (apply before presenting to user and before any writes)". Line 470-471: format rules — `tags: []` (zero) and `tags: [tag1, tag2, tag3]` (one or more), "lowercase kebab-case strings, no quotes". |
| 4 | One atomic commit captures all tag writes from a D-08 run | VERIFIED | Lines 483-488: single `git add {file_1} ... {file_N}` + `git commit -m "fix(wiki): update tags via sara-lint D-08"`. Written_files list accumulated across the full write loop before any commit. |
| 5 | If no artifact pages exist, D-08 exits gracefully without prompting | VERIFIED | Line 398: "If `{artifact_pages}` is empty (zero files found): output `\"D-08: No artifact pages to analyse — tag curation skipped.\"` and STOP Step 6." Exits before AskUserQuestion or any file read/write. |
| 6 | Full-replacement semantics: every D-08 run replaces all existing tags rather than merging | VERIFIED | Line 414: "Full replacement semantics (per D-06): Every D-08 run re-derives the vocabulary from scratch and replaces all existing tags. Do not merge with or preserve previous tag assignments." |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.claude/skills/sara-lint/SKILL.md` | D-08 tag curation as Step 6 after the per-finding loop | VERIFIED | File exists, 516 lines. Step 6 block at lines 390-500. Objective line at line 14 updated. Substantive prose — 110 lines of new skill content, not a stub. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| SKILL.md Step 5 | SKILL.md Step 6 | Sequential execution — Step 6 fires after per-finding loop completes | VERIFIED | Step 5 ends at line 315; separator `---` at line 316; back-fill rules section; another separator `---` at line 388; Step 6 header at line 390; `</process>` at line 501. Step 6 is unambiguously positioned after Step 5 and before process close. |
| SKILL.md Step 6 vocabulary approval | SKILL.md Step 6 assignment pass | AskUserQuestion Approve/Edit branch | VERIFIED | Line 423: `options: ["Approve", "Edit", "Skip"]`. Line 427: Skip → STOP. Line 431: "Continue to Phase 2" only on Approve/Edit-confirmed path. Phase 2 at line 435 is unreachable via Skip. |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces a skill/instruction document (SKILL.md), not a runnable component that renders dynamic data. The "data" in this context is LLM instruction prose, which is verified by static content inspection rather than runtime data-flow tracing.

### Behavioral Spot-Checks

Step 7b: SKIPPED — The artifact is a skill prose document (`.claude/skills/sara-lint/SKILL.md`). There is no runnable entry point to invoke; execution requires an LLM agent following the prose instructions. Runtime behaviour is covered by human verification items below.

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| TAG-01 | sara-lint D-08 check exists as Step 6, runs after the per-finding loop on every invocation | VERIFIED | `grep "Step 6" SKILL.md` — "**Step 6 — D-08 Tag curation**" at line 390, after Step 5 (line 315). No conditional guard other than empty-wiki check (TAG-10). No opt-in flag found. |
| TAG-02 | D-08 vocabulary derivation pass reads all artifact pages and derives emergent concept-level tags | VERIFIED | Lines 402-415: "Phase 1: Vocabulary derivation pass" reads all `{artifact_pages}` using Read tool, derives `{proposed_vocabulary}` as concept-level labels using 20-page context window strategy. |
| TAG-03 | D-08 presents derived vocabulary to the user via AskUserQuestion (Approve / Edit / Skip) before any writes | VERIFIED | Lines 418-431: AskUserQuestion with options `["Approve", "Edit", "Skip"]`. Invoked before Phase 2 and before any Write call. |
| TAG-04 | D-08 assignment pass fires only after vocabulary is approved (not before) | HUMAN_NEEDED | Prose structure is correct: Phase 2 is only entered from the Approve/Edit-confirmed branch (line 431). Skip path issues STOP (line 427). Static analysis confirms correct structure; runtime ordering requires human observation. |
| TAG-05 | All tags are normalised to lowercase kebab-case before presentation and before any write | VERIFIED | Line 411-413: normalisation rule defined and applied "before presenting to user and before any writes". Line 429: Edit branch re-normalises user input. Line 471: write format enforces "lowercase kebab-case strings, no quotes". |
| TAG-06 | D-08 assignment targets all four artifact directories (requirements, decisions, actions, risks) | VERIFIED | Lines 394-396: `find wiki/requirements wiki/decisions wiki/actions wiki/risks -name "*.md" ! -name ".gitkeep"` — all four directories. `grep -c` returns 14 matches of this four-directory pattern across the file. |
| TAG-07 | All tag writes from a single D-08 run are committed as one atomic commit with message `fix(wiki): update tags via sara-lint D-08` | VERIFIED | Lines 483-488: single `git add {file_1} ... {file_N}` and `git commit -m "fix(wiki): update tags via sara-lint D-08"`. `grep` returns 2 matches (bash block + error-path manual instruction). |
| TAG-08 | D-08 runs on every sara-lint invocation — no opt-in flag required | HUMAN_NEEDED | No opt-in flag, no conditional guard, no feature toggle found in Step 6 prose. Only guard is the empty-wiki check (TAG-10), which is intentional. Runtime invocation behaviour requires human verification. |
| TAG-09 | Every D-08 run fully replaces existing tags — no merging with previous assignments | VERIFIED | Line 414: "Every D-08 run re-derives the vocabulary from scratch and replaces all existing tags. Do not merge with or preserve previous tag assignments." `grep -iE "re-derives"` matches. |
| TAG-10 | D-08 exits gracefully (without prompting) when no artifact pages exist in the wiki | VERIFIED | Line 398: empty `{artifact_pages}` → output message and STOP Step 6, before any AskUserQuestion or Read/Write call. |

**Requirements summary:** 8/10 VERIFIED by static analysis; 2/10 (TAG-04, TAG-08) require human observation of runtime behaviour.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | No stub patterns, placeholder comments, or empty implementations found | — | — |

Scanned for: TODO/FIXME, placeholder, `return null`, empty handlers, hardcoded empty arrays. The SKILL.md is a prose instruction document — all D-08 sections contain substantive, complete instruction text. D-08 occurrence count: 8. Step 6 block: 110 lines of non-stub prose.

### Human Verification Required

#### 1. TAG-08 — D-08 invocation is unconditional

**Test:** Run `/sara-lint` on a wiki with at least one artifact page.
**Expected:** After the Step 5 per-finding loop completes (or if no findings, after Step 4), the agent proceeds directly into Step 6 without requiring any flag, argument, or explicit user command to trigger it.
**Why human:** Static analysis confirms no opt-in flag exists in the prose, but whether the LLM agent actually follows Step 6 on every invocation (including auto-invocations from sara-update) requires observing a live session.

#### 2. TAG-04 — Phase 2 fires only after approval, not before

**Test:** Run `/sara-lint`, reach the D-08 vocabulary gate, select "Skip".
**Expected:** No artifact pages are read or written by the assignment pass. The skill outputs "Tag curation skipped." and stops Step 6. No `tags:` frontmatter is modified.
**Why human:** The prose ordering is correct — Phase 2 is textually gated behind the Approve/Edit branch — but confirming that the LLM agent does not "look ahead" and begin assignment work before the gate requires observing the actual session output.

### Gaps Summary

No gaps found. All six observable truths are verified by static code analysis. The two human verification items (TAG-04, TAG-08) concern runtime LLM agent behaviour that cannot be validated by grep/file inspection; they do not indicate missing or broken implementation — the prose structure is correct for both.

---

_Verified: 2026-05-01_
_Verifier: Claude (gsd-verifier)_
