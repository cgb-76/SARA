# Phase 2: Ingest Pipeline - Research

**Researched:** 2026-04-27
**Domain:** Claude Code skill authoring, stateful pipeline orchestration, JSON state management, git-atomic commits
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**sara-discuss — Blocker-Clearing Model**
- **D-01:** `/sara-discuss N` is LLM-driven, not a freeform chat. The LLM reads the source, generates a blocker list — things that would cause `/sara-extract` to fail or produce wrong output — and works through it in priority order. Done when all blockers are resolved.
- **D-02:** Blocker priority order: (1) unknown stakeholders, (2) ambiguous entity type decisions, (3) missing context gaps, (4) cross-link candidates needing confirmation.
- **D-03:** Stakeholders are batched at the top. `/sara-discuss` scans the full source for all unknown names upfront, resolves all of them via `/sara-add-stakeholder` before moving to any other blockers.
- **D-04:** "Done" is objective — the LLM declares completion when the blocker list is empty. It writes the resolved context to `discussion_notes` in `pipeline-state.json` and advances the item stage to `extracting`.

**sara-add-stakeholder — Reusable Sub-Skill**
- **D-05:** `/sara-add-stakeholder` is a standalone skill AND callable inline from other skills (e.g. `/sara-discuss`). Closed-loop: capture fields → write STK page → increment counter in pipeline-state → update `wiki/index.md` and `wiki/log.md` → commit. Returns a `STK-NNN` ID immediately usable in the calling skill.
- **D-06:** Required field: `name` only. All other fields (`vertical`, `department`, `email`, `role`, `nickname`) are prompted but can be left blank with a placeholder. SARA still assigns a `STK-NNN` ID so it is immediately referenceable.
- **D-07:** Stakeholder schema gains a `nickname` field — the colloquial name used in transcript body text, vs the formal name in speaker labels (e.g. `name: Rajiwath`, `nickname: Raj`). When checking for unknown stakeholders, `/sara-discuss` matches on **both** `name` and `nickname`.
- **D-08:** Phase 1 artifacts require amendment: `.sara/templates/stakeholder.md` and the stakeholder schema block in `wiki/CLAUDE.md` both need the `nickname` field added. Planner should include this as a task in Phase 2 execution.

**sara-extract — Per-Artifact Approval Loop**
- **D-09:** Approval is per-artifact. Each proposed artifact gets three options: **accept** (include in update plan), **reject** (drop), **discuss** (user provides correction or context inline → SARA revises and re-presents that artifact → loops back to accept/reject/discuss until resolved).
- **D-10:** The `/sara-extract` dedup check (PIPE-06) runs before presenting the artifact list — existing wiki pages are checked and update proposals are shown instead of create proposals where applicable.

**sara-ingest — Registration and Status**
- **D-11:** `/sara-ingest <type> <filename>` with a missing file: hard stop. Report the file wasn't found, list what IS in `/raw/input/`, make no changes to `pipeline-state.json`.
- **D-12:** `/sara-ingest` with no arguments displays pipeline status — all items, type, current stage, filename. Format: table.

**Error & Stage Guard**
- **D-13:** Every pipeline skill checks the item's current stage at startup. If the item isn't in the expected stage, abort with a plain-English error naming the current stage and the correct next command. No override path.
- **D-14:** If `/sara-update N` partially fails mid-write, do not auto-rollback. Report exactly which files were written and which weren't. The user has full git history to recover from; they can `git reset` or re-run as appropriate.

### Claude's Discretion
- Exact wording of blocker-list presentation in `/sara-discuss` (structured list vs narrative)
- Whether `/sara-extract` shows artifacts grouped by type (all REQs, then all DECs, etc.) or in source-document order
- Exact table format for `/sara-ingest` status display

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within Phase 2 scope.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PIPE-01 | `/sara-ingest <type> <filename>` registers a file from `/raw/input/` as item N in `pending` state | Skill authoring pattern; `pipeline-state.json` write via Read+Write tools; file existence check via Bash |
| PIPE-02 | `/sara-discuss N` reads source, surfaces takeaways, flags cross-links, identifies unknown stakeholders | LLM-driven blocker model; wiki/CLAUDE.md auto-loaded schema context; inline sub-skill invocation pattern |
| PIPE-03 | Unknown stakeholders in `/sara-discuss N` can be confirmed and created as STK pages | `/sara-add-stakeholder` sub-skill; AskUserQuestion for field capture; closed-loop STK commit |
| PIPE-04 | `/sara-extract N` presents full artifact list with source-quote citations; user approves per artifact | Per-artifact AskUserQuestion loop; extraction_plan written to pipeline-state.json |
| PIPE-05 | `/sara-update N` executes approved plan atomically in one git commit; source archived; stage → complete | Staged git add + single commit; file rename via Bash; stage transition in pipeline-state.json |
| PIPE-06 | During `/sara-extract N`, LLM checks existing wiki pages; proposes updates not duplicates | wiki/index.md lookup before artifact proposal; wiki/CLAUDE.md dedup rule already in scope |
| PIPE-07 | `/sara-ingest` with no args shows pipeline status table | Argument-detection branch in skill; read pipeline-state.json items |

</phase_requirements>

---

## Summary

Phase 2 delivers five Claude Code skills implementing the four-stage ingest pipeline: `/sara-ingest`, `/sara-discuss`, `/sara-extract`, `/sara-update`, and the reusable sub-skill `/sara-add-stakeholder`. No external libraries or network calls are involved — every operation uses Claude Code built-in tools (Read, Write, Bash, AskUserQuestion) operating on local files and git.

The core architectural challenge is orchestrating a stateful, multi-session workflow where each skill must (1) read `pipeline-state.json` to verify preconditions, (2) do its work, and (3) write updated state before completing. The human-in-the-loop gates (blocker resolution in discuss, per-artifact approval in extract) are the UX heart of the system — they must feel purposeful and responsive, not mechanical.

The per-artifact approval loop in `/sara-extract` (accept / reject / discuss) is the most structurally novel element of this phase. It maps cleanly to a bounded AskUserQuestion cycle per artifact, but requires careful state accumulation: the approved artifact list must be collected across multiple user interactions before any wiki writes occur.

**Primary recommendation:** Implement each skill as a self-contained SKILL.md with inline `<process>` steps. Use Bash for file checks and git operations. Use Read/Write for JSON state and markdown files. Use AskUserQuestion for bounded choices (accept/reject/discuss, field collection). Keep `pipeline-state.json` as the single source of truth for all stage transitions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pipeline stage management | Claude Code skill → Write tool | pipeline-state.json | State is a JSON file; skills read/write it directly |
| File existence checking | Claude Code skill → Bash | — | `ls raw/input/` for PIPE-01; `[ -f ]` for guard |
| Stage guard / precondition check | Claude Code skill (process step 1) | — | Every skill reads pipeline-state.json and checks stage before proceeding |
| LLM-driven blocker analysis | Claude Code skill (LLM inference) | wiki/CLAUDE.md | LLM reads source + existing wiki; wiki/CLAUDE.md provides schema context |
| Unknown stakeholder detection | Claude Code skill (LLM inference) | .sara/config.json + wiki/stakeholders/ | Scan source for names not in existing STK pages; match on name AND nickname |
| Per-artifact approval loop | Claude Code skill → AskUserQuestion | extraction_plan in pipeline-state.json | AskUserQuestion for each artifact; results accumulated before any wiki write |
| Dedup check (PIPE-06) | Claude Code skill (LLM inference) | wiki/index.md | Read index.md before proposing artifacts; LLM matches on title/description |
| Atomic wiki commit | Claude Code skill → Bash (git) | — | All wiki writes staged then committed in single `git commit` |
| Source file archiving | Claude Code skill → Bash | — | `git mv` or `mv` + `git add` to archive with numeric prefix |
| Sub-skill invocation | Claude Code inline execution | .claude/skills/sara-add-stakeholder/ | LLM reads target SKILL.md and executes inline during /sara-discuss session |
| Index and log updates | wiki/CLAUDE.md behavioral rules | Claude Code skill execution | Rules in wiki/CLAUDE.md auto-applied when working in wiki/ subtree |

---

## Standard Stack

### Core

No external library dependencies. [VERIFIED: codebase inspection — sara-init uses no packages]

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Claude Code Write tool | built-in | Create/update wiki pages, templates, pipeline-state.json | Canonical file creation in skills |
| Claude Code Read tool | built-in | Read source files, pipeline-state.json, existing wiki pages | Canonical file reading in skills |
| Claude Code Bash tool | built-in | File existence checks, directory listing, git operations | Shell operations; git already permitted in .claude/settings.local.json |
| AskUserQuestion | built-in | Per-artifact approval loop, stakeholder field collection | Locked by Phase 1 D-01; structured TUI interaction |
| git (via Bash) | system | Atomic commits for wiki writes; source file archiving | Already in .claude/settings.local.json allow list (`Bash(git *)`) |

### Supporting

None — no additional tools required for the pipeline skill scope.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline SKILL.md process | External workflow file (@workflow.md delegation) | Workflow delegation adds indirection; SARA skills are self-contained by convention established in Phase 1 |
| AskUserQuestion per artifact | Plain-text approval prompt | AskUserQuestion provides structured options (accept/reject/discuss) needed for D-09; plain text would require parsing free-form responses |
| Single git commit for all updates | Per-artifact commits | PIPE-05 explicitly requires one commit; per-artifact commits violate atomicity requirement |
| Inline /sara-add-stakeholder logic | Separate sub-skill | D-05 locks standalone + callable pattern; reuse across discuss and future skills |

**Installation:** None required.

---

## Architecture Patterns

### System Architecture Diagram

```
User runs /sara-ingest meeting transcript.md
        │
        ▼
[Read pipeline-state.json] ── check file exists in raw/input/ ──► STOP: list raw/input/ contents
        │ file exists
        ▼
[Increment counters.ingest.MTG]
[Add item to items{} with stage=pending]
[Write pipeline-state.json]
        │
        ▼
Output: "MTG-001 registered. Stage: pending. Run /sara-discuss 1 to continue."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User runs /sara-discuss 1
        │
        ▼
[Read pipeline-state.json] ── stage != pending? ──► STOP: wrong stage error
        │ stage = pending
        ▼
[Read source file from raw/input/]
[Read wiki/index.md — existing artifact catalog]
[Read wiki/stakeholders/ — existing STK pages for name matching]
        │
        ▼
[LLM: scan for unknown names (match on name AND nickname)]
        │
        ├── unknown names found?
        │   ▼
        │   [For each unknown: /sara-add-stakeholder inline]
        │   → AskUserQuestion: name, vertical, dept, email, role, nickname
        │   → Write wiki/stakeholders/STK-NNN.md
        │   → Update wiki/index.md + wiki/log.md
        │   → git commit (STK page only)
        │   → STK-NNN ID returned to /sara-discuss context
        │
        ▼
[LLM: work through remaining blockers in priority order]
[D-02: entity type decisions → context gaps → cross-links]
        │
        ▼ (all blockers resolved)
[Write discussion_notes to pipeline-state.json]
[Advance stage: pending → extracting]
[Write pipeline-state.json]
        │
        ▼
Output: "Discuss complete. All blockers resolved. Run /sara-extract 1."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User runs /sara-extract 1
        │
        ▼
[Read pipeline-state.json] ── stage != extracting? ──► STOP: wrong stage error
        │ stage = extracting
        ▼
[Read source file]
[Read wiki/index.md — dedup check (PIPE-06)]
[Read discussion_notes from pipeline-state.json]
        │
        ▼
[LLM: generate artifact list with source-quote citations]
[LLM: for any topic in index.md → propose UPDATE not CREATE]
        │
        ▼
For each artifact:
        │
        ├── AskUserQuestion: Accept / Reject / Discuss
        │   ├── Accept → add to approval_list
        │   ├── Reject → drop
        │   └── Discuss → user corrects → LLM revises → re-present (loop)
        │
        ▼ (all artifacts processed)
[Write extraction_plan to pipeline-state.json]
[Advance stage: extracting → approved]
[Write pipeline-state.json]
        │
        ▼
Output: summary of approved artifacts. "Run /sara-update 1 to write to wiki."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User runs /sara-update 1
        │
        ▼
[Read pipeline-state.json] ── stage != approved? ──► STOP: wrong stage error
        │ stage = approved
        ▼
[Read extraction_plan from pipeline-state.json]
        │
        ▼
For each artifact in plan:
        ├── Write wiki/{type}/ID-NNN.md (create or update)
        │   Track: written / not-yet-written
        ▼
[Update wiki/index.md — add/update rows for all artifacts]
[Append to wiki/log.md — ingest event record]
        │
        ▼
[git add wiki/ .sara/pipeline-state.json]
[git commit -m "feat(sara): ingest MTG-001 — <source filename>"]
        │
        ├── commit fails? ──► Report which files written / not written; DO NOT auto-rollback
        │
        ▼ (commit succeeds)
[Bash: mv/rename source file → raw/meetings/001-transcript.md]
[Advance stage: approved → complete]
[Write pipeline-state.json]
        │
        ▼
Output: commit hash, list of artifacts written, archived file path.
```

### Recommended Project Structure

```
.claude/
└── skills/
    ├── sara-ingest/
    │   └── SKILL.md
    ├── sara-discuss/
    │   └── SKILL.md
    ├── sara-extract/
    │   └── SKILL.md
    ├── sara-update/
    │   └── SKILL.md
    └── sara-add-stakeholder/
        └── SKILL.md
```

State files (already created by Phase 1):
```
.sara/pipeline-state.json    ← all stage transitions, discussion_notes, extraction_plan
.sara/config.json            ← project config; verticals + departments for validation
wiki/index.md                ← dedup lookup; updated by sara-update and sara-add-stakeholder
wiki/log.md                  ← append-only ingest record
wiki/stakeholders/           ← STK pages written by sara-add-stakeholder
wiki/requirements/           ← REQ pages written by sara-update
wiki/decisions/              ← DEC pages written by sara-update
wiki/actions/                ← ACT pages written by sara-update
wiki/risks/                  ← RISK pages written by sara-update
```

### Pattern 1: SKILL.md Frontmatter for Pipeline Skills

All skills follow the same frontmatter convention established in Phase 1. [VERIFIED: inspection of sara-init/SKILL.md and multiple GSD skills]

```yaml
---
name: sara-ingest
description: "Register a source file in the SARA ingest pipeline"
argument-hint: "[<type> <filename>]"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
```

The `allowed-tools` list is a security boundary — any tool used in `<process>` must appear here or it will silently fail. Pipeline skills all need Read + Write + Bash. `AskUserQuestion` required for `/sara-add-stakeholder`, `/sara-extract`. `/sara-discuss` needs it only if using it for blocker confirmation (not required — plain prose + wait-for-reply is also valid).

### Pattern 2: Stage Guard at Skill Entry

Every pipeline skill reads `pipeline-state.json` as step 1 and aborts on wrong stage. [VERIFIED: D-13 decision; pattern consistent with gsd-thread guard clause approach]

```
Step 1 — Stage guard

Read `.sara/pipeline-state.json`.

Find item with index N in `items`. If not found:
  Output: "No pipeline item N found. Run /sara-ingest to register a new item."
  STOP.

Check `items[N].stage`:
  Expected: {expected_stage}
  If stage != expected_stage:
    Output: "Item N is in stage '{current_stage}'. Run /{correct_next_command} N to continue."
    STOP.
```

Stage transition map:

| Skill | Expected Stage at Entry | Stage After Completion |
|-------|------------------------|------------------------|
| /sara-discuss N | pending | extracting |
| /sara-extract N | extracting | approved |
| /sara-update N | approved | complete |

Note: `pipeline-state.json` uses `items` as an object keyed by string N (e.g. `"1"`, `"2"`). Skills must look up by the string-coerced argument. [VERIFIED: Phase 1 D-08 — items{} is an object]

### Pattern 3: Reading and Writing pipeline-state.json

All pipeline skills read, modify in-memory, and write the full JSON back. No partial updates. [VERIFIED: Phase 1 D-07/D-08 structure; no streaming JSON tools available]

```
Step N — Update pipeline state

Read `.sara/pipeline-state.json` via the Read tool.
Locate `items["{N}"]`.
Update the target field(s):
  - stage: "{new_stage}"
  - discussion_notes: "{resolved_context}" (sara-discuss)
  - extraction_plan: [{artifact_objects}] (sara-extract)
Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.
Do NOT use Bash jq or sed — use Read + Write only.
```

### Pattern 4: Per-Artifact Approval Loop

The `/sara-extract` approval loop is the most complex user interaction in the phase. [VERIFIED: D-09 decision; AskUserQuestion 12-char header limit confirmed in questioning.md]

```
For each proposed artifact (artifact_index = 1, 2, 3...):

  Present artifact to user:
    - Type: {REQ | DEC | ACT | RISK}
    - Proposed title: {title}
    - Source quote: "{exact text from source}"
    - Proposed action: CREATE new {type} / UPDATE {existing ID}

  AskUserQuestion:
    header: "Artifact {N}"  ← max 12 chars, fits within limit
    question: "Accept, reject, or discuss artifact {N}?"
    options: ["Accept", "Reject", "Discuss"]

  If Accept:
    Add to approved_artifacts list.
    Continue to next artifact.

  If Reject:
    Skip. Continue to next artifact.

  If Discuss:
    Output: "What would you like to change?"
    Wait for plain-text user response (NOT another AskUserQuestion — freeform rule)
    Incorporate correction, revise artifact.
    Re-present revised artifact.
    Loop back to AskUserQuestion.

After all artifacts processed:
  Write approved_artifacts as extraction_plan in pipeline-state.json.
```

Key constraint: The AskUserQuestion `header` field must be 12 characters or fewer. "Artifact 1" = 10 chars (safe for up to "Artifact 9"). For double-digit items, "Item 10" = 7 chars. [CITED: questioning.md hard limit]

### Pattern 5: Atomic Git Commit for Wiki Updates

`/sara-update` must land all wiki writes in a single commit. [VERIFIED: PIPE-05 requirement; git already permitted in .claude/settings.local.json]

```bash
# Stage all wiki artifacts + state file
git add wiki/requirements/ wiki/decisions/ wiki/actions/ wiki/risks/ \
        wiki/index.md wiki/log.md \
        .sara/pipeline-state.json

# Single commit
git commit -m "feat(sara): ingest {ITEM_ID} — {source_filename}"
```

Only commit after ALL write operations succeed. The commit is the atomicity boundary. If any individual file write fails before the commit, report the failure state (D-14) — do not commit partial work.

### Pattern 6: Inline Sub-Skill Invocation

`/sara-add-stakeholder` is callable from within `/sara-discuss`. The mechanism is: the skill's `<process>` instructs Claude to read the target SKILL.md file and execute it inline. [VERIFIED: .claude/skills/sara-init/SKILL.md code_context section confirms this pattern; CONTEXT.md code_context D-05]

```
When an unknown stakeholder is encountered during /sara-discuss:

  Read `.claude/skills/sara-add-stakeholder/SKILL.md`.
  Execute the sara-add-stakeholder skill inline for this stakeholder.
  The skill returns a STK-NNN ID.
  Add the STK-NNN ID to the current discussion context.
  Continue /sara-discuss from where it was paused.
```

This is the established SARA inline-invocation pattern. The sub-skill commit (STK page only) happens at sub-skill completion, before `/sara-discuss` resumes — separate earlier commit from the eventual `/sara-update` commit.

### Pattern 7: Source File Archiving

`/sara-update` renames and moves the source file to the type-specific archive directory with a numeric prefix. [VERIFIED: PIPE-05 requirement; PROJECT.md directory structure]

The ingest item ID provides the numeric prefix. Prefix format is locked by Phase 1 as integer (not zero-padded), per Phase 1 CONTEXT.md Claude's Discretion note. However, since the item IDs are type-prefixed (MTG-001), the file archive prefix should use the counter value (001), not the full ID, for clean browsability.

```bash
# Item MTG-001, source filename: transcript-2026-04-27.md
# Archive to: raw/meetings/001-transcript-2026-04-27.md
mv raw/input/transcript-2026-04-27.md raw/meetings/001-transcript-2026-04-27.md
git add raw/input/transcript-2026-04-27.md raw/meetings/001-transcript-2026-04-27.md
# (included in the main wiki commit)
```

Note: The file move should be included in the same git commit as the wiki writes. The `git add` of the renamed file and the `git rm` of the original are both included in the single commit.

### Pattern 8: Nickname Field — Phase 1 Amendment

D-07 and D-08 require amending two Phase 1 artifacts before Phase 2 skills can function correctly. [VERIFIED: CONTEXT.md D-08 explicitly requires planner to include this as a task]

Files to amend:
1. `.sara/templates/stakeholder.md` — add `nickname: ""  # colloquial name used in transcript body` after `name:`
2. `CLAUDE.md` (project root, contains wiki schema) — add `nickname:` field to the Stakeholder schema block

```yaml
# In stakeholder template and CLAUDE.md schema block, add after "name:":
nickname: ""  # colloquial name used in body text (e.g. "Raj" for "Rajiwath")
```

This amendment is a prerequisite for `/sara-discuss` to correctly identify stakeholders referenced by nickname in source documents.

### Anti-Patterns to Avoid

- **Writing wiki pages before commit:** All wiki writes must be staged and committed atomically. Never commit partial sets of artifacts (e.g., REQs committed, then DECs fail). D-14 is explicit: report failure, don't auto-rollback.
- **Stage transition before write success:** Stage must advance to `complete` only after the git commit succeeds. If the commit fails, leave the stage at `approved` so the user can retry `/sara-update`.
- **Skipping the dedup check:** `/sara-extract` must read `wiki/index.md` before proposing any artifacts. Creating a duplicate entity violates PIPE-06 and wiki/CLAUDE.md behavioral rule 1.
- **Using wiki-links in cross-references:** `related` fields use entity IDs only (REQ-001, DEC-002). Never Obsidian `[[wiki-links]]` or file paths. This is a Phase 1 constraint carried forward.
- **Merging vertical and department:** The domain constraint applies in `/sara-add-stakeholder` — two separate fields always.
- **Matching stakeholders on name only:** `/sara-discuss` must check both `name` and `nickname` fields when scanning for unknowns. A transcript saying "Raj" should not flag as unknown if STK-001 has `nickname: Raj`.
- **Using the ingest ID as item index N in the pipeline:** The user refers to items by integer index (e.g., `1`, `2`, `3`). The item's `id` field (`MTG-001`) is distinct from its integer key in `items{}`. Skills must be clear about which they use in each context.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deduplication check | Custom entity matcher | Read wiki/index.md; LLM checks titles + descriptions | wiki/index.md is maintained for this exact purpose; LLM handles semantic matching |
| YAML frontmatter parsing | Custom YAML parser | Read tool + LLM reads field values from existing pages | Full YAML parser unnecessary; LLM can extract values directly |
| JSON state persistence | Custom state database | Read + Write to pipeline-state.json | Already locked by Phase 1; JSON file is the canonical state store |
| Approval UI | Custom TUI | AskUserQuestion with options | The established Claude Code interaction mechanism |
| File archive naming | Complex naming logic | `{counter_value}-{original_filename}` | Simple concatenation; counter is already in pipeline-state.json |
| Stage validation | Stateful workflow engine | Read pipeline-state.json step 1 in every skill | Single JSON read is sufficient; no workflow engine needed |

**Key insight:** This phase has no runtime complexity problems that require libraries. Every "hard" operation (state persistence, deduplication, approval loops, atomic commits) is solved by composing Claude Code built-in tools with explicit prose instructions in SKILL.md `<process>` blocks.

---

## Common Pitfalls

### Pitfall 1: Stage Advances Before Commit Succeeds

**What goes wrong:** `/sara-update` writes stage=complete to pipeline-state.json, then the git commit fails. The item is permanently stuck at `complete` with no way to re-run `/sara-update`.

**Why it happens:** State write and git commit are separate operations with no transaction.

**How to avoid:** Always update pipeline-state.json LAST — after the git commit succeeds. The commit is the authoritative completion signal, not the state write. This is the correct sequence: (1) write all wiki files, (2) git add + commit, (3) only then write stage=complete to pipeline-state.json.

**Warning signs:** Item is `complete` but wiki pages are missing or the source file hasn't been archived.

### Pitfall 2: Item Key vs Item ID Confusion

**What goes wrong:** The user runs `/sara-discuss 1` but the skill looks up `items["MTG-001"]` instead of `items["1"]`. Not found. Error.

**Why it happens:** pipeline-state.json uses integer keys (string-encoded) for items, but items have type-prefixed IDs (MTG-001, EML-002). They are different things.

**How to avoid:** Skills must be explicit: item keys in `items{}` are string integers ("1", "2", "3"). The `id` field inside the item is the type-prefixed ID. User arguments (N) are integer keys. The skill process must spell this out clearly.

**Warning signs:** "No pipeline item found" errors when items clearly exist.

### Pitfall 3: Partial Extraction Plan on Context Reset

**What goes wrong:** `/sara-extract` is mid-loop when the Claude Code session resets. Some artifacts have been accepted; others haven't been presented yet. The extraction_plan in pipeline-state.json is partial or empty.

**Why it happens:** The approval loop accumulates approved artifacts in-memory; pipeline-state.json is only written at the end of the loop.

**How to avoid:** `/sara-extract` should write the extraction_plan to pipeline-state.json after the user has approved or rejected all artifacts — at the end of the full loop, not incrementally. If the skill is re-run on a `extracting` stage item, it should re-run the full loop (re-present all artifacts for fresh approval). This is safe because the wiki hasn't been written yet.

**Warning signs:** Stage is `extracting` but extraction_plan is empty; user ran `/sara-extract` twice.

### Pitfall 4: Dedup Check Against Stale Index

**What goes wrong:** `/sara-extract` reads `wiki/index.md` at the start of the session. Mid-session, `/sara-add-stakeholder` runs (called from `/sara-discuss`) and updates the index. `/sara-extract` uses its old in-memory copy of the index.

**Why it happens:** Index is read once at skill start; sub-skill updates it mid-session.

**How to avoid:** `/sara-extract` should re-read wiki/index.md at the start of its dedup check step (not cache it from session start). This is straightforward — just include the Read call in the dedup step rather than at skill entry.

**Warning signs:** `/sara-extract` proposes creating a STK page for someone added by `/sara-add-stakeholder` in the same session.

### Pitfall 5: AskUserQuestion Header Too Long

**What goes wrong:** AskUserQuestion header exceeds 12 characters; TUI validator rejects it.

**Why it happens:** Forgetting the 12-char hard limit when writing skill prose. [CITED: questioning.md]

**How to avoid:** Use short headers. For per-artifact loops: "Artifact 1" (10 chars), "Item 10" (7 chars). For stakeholder field prompts: "Name", "Vertical", "Dept", "Email", "Role", "Nickname" — all under 12 chars.

**Warning signs:** AskUserQuestion renders incorrectly; validation error thrown.

### Pitfall 6: Source File Not in git Before Move

**What goes wrong:** `/sara-update` moves the source file from `raw/input/` to `raw/meetings/` using `mv`, but the file was never `git add`-ed to the repo (it was dropped into the directory manually). The git commit doesn't include the file move — git sees it as an untracked deletion.

**Why it happens:** Users drop files manually into `raw/input/`; `/sara-ingest` doesn't commit the source file.

**How to avoid:** `/sara-update` should use `git mv` if the file is already tracked, or add both paths manually (`git add raw/input/old-name raw/meetings/new-name`) if untracked. Explicitly check with `git status raw/input/{filename}` to determine tracked status before the move. Alternatively, include the source file add in the `/sara-update` commit regardless.

**Warning signs:** `git status` shows untracked deletion of source file after update.

---

## Code Examples

### SKILL.md Frontmatter — Pipeline Skill

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
[VERIFIED: pattern from .claude/skills/sara-init/SKILL.md and multiple GSD skills]

### pipeline-state.json — Item Entry After Ingest

```json
{
  "counters": {
    "ingest": { "MTG": 1, "EML": 0, "SLK": 0, "DOC": 0 },
    "entity": { "REQ": 0, "DEC": 0, "ACT": 0, "RISK": 0, "STK": 0 }
  },
  "items": {
    "1": {
      "id": "MTG-001",
      "type": "meeting",
      "filename": "transcript-2026-04-27.md",
      "stage": "pending",
      "created": "2026-04-27",
      "discussion_notes": "",
      "extraction_plan": []
    }
  }
}
```
[VERIFIED: Phase 1 D-07/D-08 locked structure]

### pipeline-state.json — After /sara-discuss

```json
"1": {
  "id": "MTG-001",
  "type": "meeting",
  "filename": "transcript-2026-04-27.md",
  "stage": "extracting",
  "created": "2026-04-27",
  "discussion_notes": "Stakeholders confirmed: STK-001 (Alice, Sales), STK-002 (Bob, Engineering). Key topic: API rate limiting. Related: DEC-002 (existing auth decision).",
  "extraction_plan": []
}
```
[VERIFIED: D-04/D-08]

### pipeline-state.json — After /sara-extract

```json
"1": {
  "stage": "approved",
  "extraction_plan": [
    {
      "action": "create",
      "type": "requirement",
      "id_to_assign": "REQ-NNN",
      "title": "API rate limiting per tenant",
      "source_quote": "We need to cap API calls at 1000/hour per tenant",
      "raised_by": "STK-001",
      "related": []
    },
    {
      "action": "update",
      "type": "decision",
      "existing_id": "DEC-002",
      "title": "Auth token expiry policy",
      "change_summary": "Add note: rate limit enforcement relies on token identity",
      "source_quote": "The token must carry tenant ID for rate limit tracking"
    }
  ]
}
```
[ASSUMED: structure inferred from D-08 and D-09 requirements; exact field names are Claude's discretion]

### Stakeholder Template — With Nickname Field (amended)

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
[VERIFIED: D-07/D-08 — nickname field required for Phase 2]

### Stage Guard Prose (for each skill's Step 1)

```
Step 1 — Stage guard and item lookup

Read `.sara/pipeline-state.json`.

Find the item with key "{N}" in the `items` object (where N is the integer argument
provided by the user — e.g., for `/sara-discuss 1`, N = "1").

If no item exists with key "{N}":
  Output: "No pipeline item {N} found. Run /sara-ingest to register a new item, or
  run /sara-ingest with no arguments to see the full pipeline status."
  STOP.

Check `items["{N}"].stage`:
  Expected stage: {expected_stage}
  Actual stage: items["{N}"].stage

If actual stage != expected stage:
  Output: "Item {N} ({id}) is currently in stage '{actual_stage}'.
  {correction_message}"
  STOP.
```

Correction messages per skill:
- `/sara-discuss`: "Run /sara-discuss N only when stage is 'pending'. If the item is 'extracting', run /sara-extract N."
- `/sara-extract`: "Run /sara-extract N only when stage is 'extracting'. Re-run /sara-discuss N if you need to revisit."
- `/sara-update`: "Run /sara-update N only when stage is 'approved'. Re-run /sara-extract N if you need to revise the plan."
[VERIFIED: D-13 decision]

---

## Runtime State Inventory

> Phase 2 writes new runtime state but does not rename or migrate existing state. Not a rename/refactor phase. Abbreviated inventory.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `pipeline-state.json` — created by Phase 1, Phase 2 reads and writes it | No migration; schema extended by Phase 2 skills at runtime |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

**Phase 1 artifacts that Phase 2 must amend before they can function correctly:**
- `.sara/templates/stakeholder.md` — add `nickname` field (D-08 explicit task)
- `CLAUDE.md` (project root) — add `nickname` to Stakeholder schema block (D-08 explicit task)

These amendments are not migrations — they are additive changes to static template files. No existing data is affected.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Claude Code Write tool | All skills | ✓ | built-in | — |
| Claude Code Read tool | All skills | ✓ | built-in | — |
| Claude Code Bash tool | All skills | ✓ | built-in | — |
| AskUserQuestion | sara-extract, sara-add-stakeholder | ✓ | built-in | — |
| git (Bash) | sara-update, sara-add-stakeholder | ✓ | system (Bash(git *) allowed) | — |
| `mv` (POSIX) | sara-update (file archiving) | ✓ | OS standard | — |

No missing dependencies. All capabilities are built-in or already permitted.

---

## Validation Architecture

Nyquist validation is enabled (`nyquist_validation: true` in config.json).

### Test Framework

Skills are SKILL.md prose documents executed by Claude Code — not compiled programs. Verification is observational: run each skill, inspect outputs and state transitions.

| Property | Value |
|----------|-------|
| Framework | Manual inspection (no automated test runner) |
| Config file | none |
| Quick run command | Run target skill with a test fixture file in raw/input/ |
| Full suite command | Run full pipeline end-to-end: ingest → discuss → extract → update; inspect all outputs |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PIPE-01 | `/sara-ingest meeting file.md` creates item 1 in pending stage | smoke | `cat .sara/pipeline-state.json` — check items["1"].stage = "pending" | ❌ Wave 0 (manual) |
| PIPE-01 | Missing file hard stop; no pipeline-state.json changes | smoke | Check pipeline-state.json unchanged after failed ingest | ❌ Wave 0 (manual) |
| PIPE-02 | `/sara-discuss 1` surfaces cross-links and unknown stakeholders | inspection | Read discussion output; check discussion_notes populated | ❌ Wave 0 (manual) |
| PIPE-03 | Unknown stakeholder creates STK page and advances discussion | smoke | `ls wiki/stakeholders/` — STK-NNN.md exists; git log shows commit | ❌ Wave 0 (manual) |
| PIPE-04 | `/sara-extract 1` presents each artifact with source quote | inspection | Read extract output; verify source quotes present | ❌ Wave 0 (manual) |
| PIPE-04 | Approved artifacts written to extraction_plan in pipeline-state.json | smoke | `cat .sara/pipeline-state.json` — check extraction_plan populated | ❌ Wave 0 (manual) |
| PIPE-05 | `/sara-update 1` produces single git commit with all artifacts | smoke | `git log --oneline -1` + `git show --stat HEAD` — all wiki pages in one commit | ❌ Wave 0 (manual) |
| PIPE-05 | Source file archived to raw/meetings/ with numeric prefix | smoke | `ls raw/meetings/` — file exists with prefix | ❌ Wave 0 (manual) |
| PIPE-06 | Source mentioning existing wiki topic → update proposal not create | inspection | Run extract against source with topic matching existing wiki page; check plan action = "update" | ❌ Wave 0 (manual) |
| PIPE-07 | `/sara-ingest` (no args) shows table of all items | smoke | Run /sara-ingest; verify table format in output | ❌ Wave 0 (manual) |

### Sampling Rate

- **Per task commit:** Manual spot-check — inspect the file or state written in that task
- **Per wave merge:** Run the end-to-end pipeline with a test transcript; inspect all outputs against the checklist
- **Phase gate:** All 7 PIPE requirements verified; full pipeline runs from ingest to complete in a single end-to-end session

### Wave 0 Gaps

- No test runner to install — verification is entirely manual inspection and pipeline execution
- Planner should include a verification task: "Run the full ingest pipeline with a test fixture transcript; verify all stage transitions, artifact outputs, git commit, and source file archiving"
- Test fixture: a short mock meeting transcript with known stakeholder names (some existing, some new) and at least two distinct entity types (e.g., one requirement, one decision)

---

## Security Domain

Security enforcement applies (not explicitly disabled). Phase 2 has a narrow security surface — all operations are local file manipulation and git. No network calls, no authentication, no external services.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — local tool, single user |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a — no multi-user |
| V5 Input Validation | yes (low risk) | Validate type argument against hardcoded list (meeting/email/slack/document); N argument must be positive integer |
| V6 Cryptography | no | n/a |

### Known Threat Patterns for Pipeline Skills

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via filename argument | Tampering | Validate filename: no path separators, no `..`; only use `raw/input/` as the base path |
| Invalid type argument | Tampering | Validate against hardcoded list: meeting, email, slack, document — error on unknown type |
| Integer injection via N argument | Tampering | N must be a positive integer; reject non-numeric or negative values; use as JSON key string only |
| Source file content injection | Tampering | Source file content is read and passed to LLM for analysis — LLM output goes to wiki pages (markdown) not to shell; low risk |

**Assessment:** Security risk is minimal. The only user-controlled inputs are the type argument, filename, and item index N — all of which feed into JSON state or markdown files, not shell commands or eval contexts. Filename validation is the most important control (prevent path traversal).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | pipeline-state.json items are keyed by string integers ("1", "2") not type-prefixed IDs | Pattern 3 | Skills would fail to locate items; fix by keying differently at ingest time |
| A2 | Inline sub-skill invocation (LLM reads target SKILL.md and executes inline) works reliably mid-session | Pattern 6 | /sara-discuss cannot delegate to /sara-add-stakeholder; would need to inline the stakeholder capture logic |
| A3 | The extraction_plan artifact structure (action, type, id_to_assign, title, source_quote, etc.) is valid; exact field names are Claude's discretion | Code Examples | If field names differ from what /sara-update expects, update step would fail; internal consistency matters more than exact names |
| A4 | Source files dropped in raw/input/ are not git-tracked at ingest time | Pitfall 6 | If files ARE tracked at ingest, `git mv` works cleanly; if not, explicit `git add` of both paths required at update time |
| A5 | `wiki/CLAUDE.md` is auto-loaded by Claude Code for sessions within the wiki/ subtree | Architecture Map | Phase 2 wiki-writing skills inherit schema and behavioral rules automatically; if loading fails, skills must explicitly read wiki/CLAUDE.md |

---

## Open Questions

1. **Extraction plan artifact object schema — exact field names**
   - What we know: D-08 specifies `extraction_plan` is an empty array; D-09 specifies accept/reject/discuss loop; content is Claude's discretion
   - What's unclear: The planner will need to define a consistent artifact object schema used by both `/sara-extract` (writes it) and `/sara-update` (reads it); these two skills must agree
   - Recommendation: Define a minimal artifact object in the `/sara-extract` skill prose and reference the same fields in `/sara-update`. The schema can be embedded as a comment in the SKILL.md process steps.

2. **Archive filename numeric prefix format**
   - What we know: Phase 1 counter format is integer (not zero-padded per CONTEXT.md Claude's Discretion note); source files become `001-filename.md` in the archive
   - What's unclear: Whether to use the ingest counter value (1 → "001") or the full ingest ID number (MTG-001 → "001"). Both give the same result for the same type.
   - Recommendation: Use zero-padded 3-digit counter value from `counters.ingest.{TYPE}` at ingest time, stored on the item as a separate `archive_prefix` field. This avoids re-parsing the ID at update time.

3. **Commit message format for wiki updates**
   - What we know: sara-init uses `chore: initialise SARA — {project_name}`; PIPE-05 doesn't specify commit format
   - What's unclear: Whether to use `feat(sara):`, `chore:`, or a custom format
   - Recommendation: Use `feat(sara): ingest {ITEM_ID} — {source_filename}` for the main wiki commit. Use `feat(sara): add stakeholder {STK_ID} — {name}` for STK-only commits from `/sara-add-stakeholder`.

---

## Sources

### Primary (HIGH confidence)
- `.claude/skills/sara-init/SKILL.md` — SKILL.md format, process step structure, file write patterns, git commit pattern
- `.planning/phases/02-ingest-pipeline/02-CONTEXT.md` — all locked decisions (D-01 through D-14)
- `.planning/phases/01-foundation-schema/01-CONTEXT.md` — pipeline-state.json structure (D-07/D-08), stage values, entity ID formats (D-06)
- `.planning/phases/01-foundation-schema/01-RESEARCH.md` — established patterns (SKILL.md frontmatter, AskUserQuestion usage, annotated YAML, wiki/CLAUDE.md loading)
- `.planning/phases/01-foundation-schema/01-PATTERNS.md` — pattern map with GSD skill analogs
- `.planning/REQUIREMENTS.md` — PIPE-01 through PIPE-07 complete requirement descriptions
- `.planning/PROJECT.md` — directory structure, pipeline stage names, command taxonomy
- `/home/george/.claude/get-shit-done/references/questioning.md` — AskUserQuestion 12-char limit, freeform rule
- `.claude/settings.local.json` — confirmed `Bash(git *)` and `Bash(gsd-sdk query *)` are permitted

### Secondary (MEDIUM confidence)
- Multiple GSD skills reviewed for patterns (gsd-thread, gsd-add-backlog, gsd-do, gsd-import) — confirmed SKILL.md conventions, inline process structure

### Tertiary (LOW confidence)
- Inline sub-skill invocation mechanism (A2) — pattern described in CONTEXT.md code_context but not directly demonstrated in an existing skill

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no external dependencies; all tools are built-in; confirmed by Phase 1 precedent
- Architecture: HIGH — all decisions locked by CONTEXT.md; pipeline-state.json structure locked by Phase 1; skill structure verified from existing examples
- Pitfalls: HIGH — derived from explicit locked decisions (D-13, D-14) and direct inspection of pipeline-state.json structure
- Extraction plan schema: MEDIUM — field names are Claude's discretion; planner must define and maintain consistency between sara-extract and sara-update

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (stable domain — Claude Code SKILL.md format; all decisions locked)
