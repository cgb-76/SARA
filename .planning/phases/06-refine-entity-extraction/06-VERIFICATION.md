---
phase: 06-refine-entity-extraction
verified: 2026-04-28T10:00:00Z
status: human_needed
score: 3/3 must-haves verified (automated checks passed; one human item outstanding)
human_verification:
  - test: "Run /sara-discuss on a test item and confirm the blocker list shows ONLY Priority 1 (unknown stakeholders) and Priority 2 (source comprehension blockers) — no entity-type classification questions of any kind"
    expected: "Output shows Priority 1 and Priority 2 headings only; no prompt asking 'is this a REQ or DEC?'; session completes and stage advances to extracting"
    why_human: "Cannot invoke a live Claude Code skill session programmatically; the narrowing is present in the static file but runtime output requires a human to observe"
  - test: "Run /sara-extract on an item in extracting stage; observe that four specialist Task() calls fire and the sorter runs before any Artifact N Accept/Reject/Discuss prompt appears"
    expected: "Evidence of four specialist agents running (requirement/decision/action/risk); sorter runs after; any sorter questions appear one-at-a-time with A/B/C options BEFORE the first per-artifact approval prompt"
    why_human: "Task() dispatch occurs at LLM runtime; static file analysis confirms the instructions are present and correct but cannot verify actual agent invocation order without running the skill"
---

# Phase 06: Refine Entity Extraction — Verification Report

**Phase Goal:** sara-extract dispatches to four specialist extraction agents (one per entity type) and a sorter agent via Task(); the sorter deduplicates, resolves create-vs-update, and surfaces ambiguity questions for the human before the per-artifact approval loop; sara-discuss is narrowed to source comprehension and unknown-stakeholder surfacing only; install.sh distributes the new agent files

**Verified:** 2026-04-28T10:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `/sara-extract N` dispatches four specialist Task() calls and one sorter Task() call; sorter resolves create-vs-update and presents ambiguity questions before the approval loop | ✓ VERIFIED (automated) + ? HUMAN (runtime) | SKILL.md Step 3 has explicit Task() lines for all five agents; sorter_questions loop iterates one-at-a-time before Step 4; `cleaned_artifacts` fed to approval loop; old monolithic Step 3 removed |
| 2 | `/sara-discuss N` produces only Priority 1 (unknown stakeholders) and Priority 2 (source comprehension) — no entity type classification questions | ✓ VERIFIED (automated) + ? HUMAN (runtime) | Old P2 (entity type), P3 (context gaps), P4 (cross-links) all absent from SKILL.md; new P2 "Source comprehension blockers" present; objective explicitly states classification/dedup moved to sorter |
| 3 | `install.sh` copies both the nine skill files AND all five agent files to the correct `.claude/` subdirectories | ✓ VERIFIED | SKILLS array has 9 entries; AGENTS array has 5 entries; TARGET_AGENTS_DIR set to `$TARGET_DIR/.claude/agents`; agent loop appears at lines 118–147, before "Post-install output" at line 149; `bash -n` exits 0 |

**Score:** 3/3 truths verified (automated checks)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.claude/agents/sara-requirement-extractor.md` | Specialist agent — REQ type only | ✓ VERIFIED | `name: sara-requirement-extractor`, `tools: Read, Bash`, `action: create`, `source_quote MANDATORY`, `Do NOT access wiki` |
| `.claude/agents/sara-decision-extractor.md` | Specialist agent — DEC type only | ✓ VERIFIED | `name: sara-decision-extractor`, `tools: Read, Bash`, `action: create`, `source_quote MANDATORY`, `Do NOT access wiki` |
| `.claude/agents/sara-action-extractor.md` | Specialist agent — ACT type only | ✓ VERIFIED | `name: sara-action-extractor`, `tools: Read, Bash`, `action: create`, `source_quote MANDATORY`, `Do NOT access wiki` |
| `.claude/agents/sara-risk-extractor.md` | Specialist agent — RSK type only | ✓ VERIFIED | `name: sara-risk-extractor`, `tools: Read, Bash`, `action: create`, `source_quote MANDATORY`, `Do NOT access wiki` |
| `.claude/agents/sara-artifact-sorter.md` | Sorter agent: dedup, create-vs-update, questions | ✓ VERIFIED | `name: sara-artifact-sorter`, `tools: Read, Bash`, dual-output `cleaned_artifacts`+`questions`, `action: update` with `existing_id`, A/B/C option labels, zero-questions case `[]`, no-write prohibition |
| `.claude/skills/sara-extract/SKILL.md` | Orchestrator with multi-agent dispatch in Steps 2–3 | ✓ VERIFIED | All five agent names present, Task() dispatch for all four specialists + sorter, sorter questions before Step 4, Steps 1/4/5 preserved verbatim, `version: 1.0.0` unchanged |
| `.claude/skills/sara-discuss/SKILL.md` | Narrowed to P1 (unknown STKs) + P2 (source comprehension) | ✓ VERIFIED | Old P2/P3/P4 absent, new P2 "Source comprehension blockers" present, objective explicitly delegates classification/dedup to sorter |
| `install.sh` | Distributes skill files AND agent files | ✓ VERIFIED | AGENTS array with 5 entries, TARGET_AGENTS_DIR, loop before post-install output block, bash -n passes |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `sara-extract SKILL.md Step 3` | `sara-requirement-extractor.md` | Task() agent name reference | ✓ WIRED | `Task(`sara-requirement-extractor`, ...)` present in Step 3 |
| `sara-extract SKILL.md Step 3` | `sara-decision-extractor.md` | Task() agent name reference | ✓ WIRED | `Task(`sara-decision-extractor`, ...)` present in Step 3 |
| `sara-extract SKILL.md Step 3` | `sara-action-extractor.md` | Task() agent name reference | ✓ WIRED | `Task(`sara-action-extractor`, ...)` present in Step 3 |
| `sara-extract SKILL.md Step 3` | `sara-risk-extractor.md` | Task() agent name reference | ✓ WIRED | `Task(`sara-risk-extractor`, ...)` present in Step 3 |
| `sara-extract SKILL.md Step 3` | `sara-artifact-sorter.md` | Task() agent name reference | ✓ WIRED | `Task(`sara-artifact-sorter`, ...)` present in Step 3 |
| `sara-extract sorter output` | `Step 4 approval loop` | `cleaned_artifacts` handoff, questions resolved first | ✓ WIRED | Lines 88–97: questions iterated one-at-a-time, Step 4 receives `{cleaned_artifacts}` only after all questions resolved |
| `sara-discuss objective` | `sorter agent` | Narrative delegation statement | ✓ WIRED | "Classification, deduplication, and cross-reference reasoning now belong to the sorter agent in `/sara-extract`" |
| `install.sh AGENTS loop` | `.claude/agents/*.md` | curl download to TARGET_AGENTS_DIR | ✓ WIRED | Loop downloads each agent name with `${BASE_URL}/.claude/agents/${agent_name}.md` |

### Data-Flow Trace (Level 4)

Not applicable — all artifacts are LLM instruction files (markdown), not components rendering dynamic data. No data-flow trace needed.

### Behavioral Spot-Checks

Step 7b: SKIPPED for skill/agent markdown files — these are LLM instruction documents, not runnable entry points. Runtime behaviour requires live Claude Code session (see Human Verification section).

The following static checks were performed in place of runtime spot-checks:

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| Four specialist agents each extract only their own type | `grep '"type": "requirement"'` absent from decision/action/risk agents | PASS — each agent's output_format block hardcodes only its own type | ✓ VERIFIED |
| Sorter questions gate before approval loop | Line order: sorter_questions loop (lines 88–97) precedes Step 4 (line 99) | PASS | ✓ VERIFIED |
| discussion_notes passed explicitly to specialists | `Task() prompt template includes <discussion_notes>` tag | PASS | ✓ VERIFIED |
| One-at-a-time question iteration (06-05 fix) | `For each question in {sorter_questions}, one at a time` | PASS | ✓ VERIFIED |
| A/B/C option labels (06-05 fix) | Sorter process block contains `A)`, `B)`, `C)` templates for all three question types | PASS | ✓ VERIFIED |
| Names required alongside IDs in questions (06-05 fix) | "ID resolution rule (mandatory)" block in sorter process step 5 | PASS | ✓ VERIFIED |

### Requirements Coverage

No formal requirement IDs were assigned to Phase 6. Coverage is assessed against the three ROADMAP success criteria, all verified above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.claude/skills/sara-discuss/SKILL.md` | 46 | Stale comment: `wiki/index.md` described as "existing entity catalog for cross-link identification" | ℹ️ Info | Comment is a leftover from old Priority 4 language; the index is still read (legitimately, for context) but no cross-link priority exists in Step 3. No functional impact — sara-discuss Step 3 has no cross-link category. The comment is misleading but does not affect behaviour. |

No blocker or warning anti-patterns found. No TODO/FIXME/placeholder content. No empty implementations. No hardcoded stub returns.

### Human Verification Required

#### 1. sara-discuss narrowed scope — live run

**Test:** Run `/sara-discuss` on a test pipeline item (ingest a meeting fixture if needed). Observe the complete blocker analysis output.

**Expected:** Blocker list shows exactly Priority 1 (unknown stakeholders) and Priority 2 (source comprehension blockers). No prompt of the form "is this a REQ or DEC?" or any entity classification question appears. The session completes and the item stage advances to `extracting`.

**Why human:** The static file confirms the instructions are correct (old P2/P3/P4 removed, new P2 source comprehension present, no entity classification in Step 3). Runtime output requires a human to confirm the LLM follows the updated instructions and does not hallucinate entity classification questions from prior training context.

#### 2. sara-extract agent dispatch — live run

**Test:** Run `/sara-extract` on the item now in `extracting` stage. Observe the dispatch sequence.

**Expected:** Four specialist Task() agents fire (requirement/decision/action/risk). The sorter fires after all four complete. If the sorter produces questions, each appears one at a time with A/B/C options and stakeholder names alongside IDs — and all questions are fully resolved BEFORE the first "Artifact 1: Accept/Reject/Discuss" prompt appears. The approval loop completes and stage advances to `approved`.

**Why human:** Task() dispatch is a runtime Claude Code mechanism. Static analysis confirms all five agent names are referenced with correct prompts and the question-gate logic is structurally correct. Whether the LLM actually invokes Task() in the correct order and whether the sorter question gate holds in practice requires a live run to verify.

### Gaps Summary

No gaps found. All three success criteria are met at the static verification level:

1. **sara-extract multi-agent dispatch:** All five agent files exist with valid frontmatter and correct isolation contracts. SKILL.md Step 3 references all five agents via Task(), passes source+discussion_notes to specialists, passes merged+grep+wiki_index to sorter, resolves questions one-at-a-time before Step 4, and feeds cleaned_artifacts to the approval loop.

2. **sara-discuss narrowed scope:** Old Priority 2 (entity type), Priority 3 (context gaps), and Priority 4 (cross-links) are absent. New Priority 2 (source comprehension) is present. Objective block explicitly delegates classification and dedup to the sorter.

3. **install.sh agent distribution:** AGENTS array with all five files, TARGET_AGENTS_DIR loop, correct placement before post-install output, bash syntax valid.

The two human verification items are runtime confirmation of correct LLM behaviour — the static structure fully supports both success criteria.

---

_Verified: 2026-04-28T10:00:00Z_
_Verifier: Claude (gsd-verifier)_
