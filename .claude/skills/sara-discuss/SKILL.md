---
name: sara-discuss
description: "Run LLM-driven blocker-clearing session for a pipeline item before extraction"
argument-hint: "<ID>"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 2.0.0
---

<objective>
This skill reads the source document for pipeline item N and generates a structured blocker list — things that would cause `/sara-extract` to fail or produce wrong output. It works through blockers in priority order: unknown stakeholders first (resolved via inline `/sara-add-stakeholder`), then source comprehension blockers (ambiguous or unclear passages that would prevent accurate extraction). Classification, deduplication, and cross-reference reasoning now belong to the sorter agent in `/sara-extract` — those concerns are no longer part of `/sara-discuss`. The skill declares done objectively when the blocker list is empty; it then writes the resolved context to `.sara/pipeline/{N}/discuss.md` and advances the item stage to `extracting` in `.sara/pipeline/{N}/state.md`.

Note: `AskUserQuestion` is required in `allowed-tools` because `/sara-add-stakeholder` (invoked inline during stakeholder resolution) uses it for structured field collection.
</objective>

<process>

**Step 1 — Stage guard and item lookup**

Validate `$ARGUMENTS`: it must be a non-empty pipeline item ID (e.g. `MTG-001`). If empty:
Output: `"Usage: /sara-discuss <ID> where ID is a pipeline item identifier (e.g. MTG-001)."` and STOP.

Check if `.sara/pipeline/{N}/state.md` exists by attempting to read it with the Read tool.

If the file cannot be read (does not exist):
  Output: `"No pipeline item {N} found. Run /sara-ingest to register a new item, or run /sara-ingest with no arguments to see the full pipeline status."`
  STOP.

Parse the YAML frontmatter from state.md. Extract the following fields:
- `id` → store as `{item.id}`
- `type` → store as `{item.type}`
- `filename` → store as `{item.filename}`
- `source_path` → store as `{item.source_path}`
- `stage` → store as `{item.stage}`
- `created` → store as `{item.created}`

Check `{item.stage}`. Expected stage: `"pending"`.

If `{item.stage}` != `"pending"`:
  Output: `"Item {N} is currently in stage '{item.stage}'. Run /sara-discuss <ID> only when stage is 'pending'. If the item is 'extracting', run /sara-extract {N}."`
  STOP.

**Step 2 — Load source and context**

Read `{item.source_path}` using the Read tool. This is the source document. The `source_path` value comes from the state.md frontmatter field parsed in Step 1.

Read `wiki/index.md` using the Read tool. This is the existing entity catalog for cross-link identification.

Build `known_names` by running a Bash grep across all STK page frontmatter — do NOT read individual stakeholder pages into context:

```bash
grep -rh "^\(name\|nickname\):" wiki/stakeholders/ 2>/dev/null
```

Parse each output line to extract the value after the colon (stripping quotes and whitespace). Collect all non-empty values into the `known_names` set.

  Example: if the grep output contains `name: "Rajiwath Patel"` and `nickname: "Raj"`, both `"Rajiwath Patel"` and `"Raj"` are in `known_names`. A source reference to "Raj" is NOT unknown.

Read `.sara/config.json` using the Read tool. This is needed by `/sara-add-stakeholder` when invoked inline in Step 4.

**Step 3 — Generate blocker list**

Using the source document and existing wiki context, identify blockers in priority order. Present the full blocker list to the user as a structured summary before resolving anything.

**Priority 1 — Unknown stakeholders:** Scan the full source for every person mentioned by name (including informal references, initials, and nicknames). For each person found, check if their name appears in `known_names` (checking both `name` AND `nickname` fields — dual-field matching is required). Collect ALL unknown persons before proceeding. Do not process any Priority 2 blockers until the complete list of unknown persons is identified.

**Priority 2 — Source comprehension blockers:** Identify passages in the source that are ambiguous, unclear, or reference context that cannot be inferred from the document alone — and where the ambiguity would prevent accurate extraction. Do NOT classify entity types here — that is the sorter's job in `/sara-extract`. List each comprehension blocker with the source passage and why it is unclear.

Present a structured blocker summary to the user before proceeding. Example format:

```
Blocker analysis for item {N} ({item.id}):

Priority 1 — Unknown stakeholders (N found):
  - [name A]
  - [name B]

Priority 2 — Source comprehension blockers (N found):
  - [passage excerpt] — unclear because: [reason]

Total blockers: N. Resolving Priority 1 first.
```

If both priority lists are empty: skip Steps 4 and 5 entirely and proceed to Step 6.

**Step 4 — Resolve unknown stakeholders (Priority 1)**

For each unknown stakeholder identified in Step 3:

  Output: `"Unknown stakeholder: {name}. Resolving via /sara-add-stakeholder."`

  Read `.claude/skills/sara-add-stakeholder/SKILL.md` using the Read tool.
  Execute the sara-add-stakeholder skill inline for this stakeholder.
  Pass `{name}` as the `$ARGUMENTS` value so the name prompt in sara-add-stakeholder Step 1 is skipped.
  Capture the returned `{STK-NNN}` ID from the skill's output.
  Add `{name} → {STK-NNN}` to the running resolved stakeholders context.

After all unknown stakeholders are resolved, proceed to Step 5.

**Step 5 — Work through source comprehension blockers (Priority 2)**

For each source comprehension blocker from the list:

  Present the specific blocker to the user as plain text with the relevant source passage:
  `"Blocker [source comprehension]: The passage '...' is unclear because [reason]. What does this mean in context?"`

  Wait for the user's reply using a plain-text wait (freeform rule — do NOT use AskUserQuestion here).

  Incorporate the user's clarification into the running comprehension clarifications context.

  Mark that blocker resolved. Proceed to the next blocker.

Declare completion ONLY when all blockers (Priority 1 and Priority 2) are resolved and the blocker list is empty.

**Step 6 — Write discuss.md, commit, and advance stage**

Compile `{discussion_notes}` as a structured markdown document summarising all resolved context. Format as follows:

```markdown
## Resolved Stakeholders

{For each stakeholder resolved in Step 4: one line per stakeholder}
- {name} → {STK-NNN} (segment: {segment}, role: {role})

## Source Comprehension Clarifications

{For each comprehension blocker resolved in Step 5: one line per resolution}
- "{passage excerpt}" — {clarification}
```

If no stakeholders were resolved, omit the "## Resolved Stakeholders" section.
If no comprehension blockers were resolved, omit the "## Source Comprehension Clarifications" section.
If both lists are empty (no blockers existed — Step 3 found zero blockers): write a minimal discuss.md:
```markdown
## Resolved Stakeholders

(none)

## Source Comprehension Clarifications

(none — no blockers found)
```

Write `.sara/pipeline/{N}/discuss.md` using the Write tool with the compiled content.

Do NOT use Bash shell text-processing tools — use Write tool only.

Run git commit:
```bash
git add ".sara/pipeline/{N}/discuss.md"
git commit -m "feat(sara): discuss {N} — blockers resolved"
echo "EXIT:$?"
```

Check the exit code from the `echo "EXIT:$?"` output.

If commit FAILS (exit code != 0):
  Output: `"Commit failed for {N}. discuss.md has been written but the commit did not succeed. Stage remains 'pending'. Resolve the git issue and re-run /sara-discuss {N}."`
  STOP. Do NOT write state.md with stage: extracting.

If commit SUCCEEDS (exit code 0):
  Capture `{commit_hash}` by running: `git log --oneline -1`

  Read `.sara/pipeline/{N}/state.md` using the Read tool.
  Reconstruct the frontmatter with `stage: extracting` (all other fields unchanged):
  ```markdown
  ---
  id: {item.id}
  type: {item.type}
  filename: {item.filename}
  source_path: {item.source_path}
  stage: extracting
  created: {item.created}
  ---
  ```
  Write `.sara/pipeline/{N}/state.md` using the Write tool with the updated content.

  Run:
  ```bash
  git add ".sara/pipeline/{N}/state.md"
  git commit -m "feat(sara): stage {N} → extracting"
  echo "EXIT:$?"
  ```

  If commit FAILS (exit code != 0):
    Output: `"Stage-advance commit failed for {N}. state.md on disk shows stage: extracting but the commit did not succeed. Run: git add .sara/pipeline/{N}/state.md && git commit -m 'feat(sara): stage {N} → extracting' to retry."`
    STOP.

  Output:
  ```
  Discussion complete. All blockers resolved.
  discuss.md written to .sara/pipeline/{N}/discuss.md.
  Stage advanced to extracting. Commit: {commit_hash}
  Run /sara-extract {N} to proceed to extraction.
  ```

</process>

<notes>
- Stakeholder matching in Step 2 and Step 3 MUST check both the `name` field AND the `nickname` field in every STK page. A source reference to "Raj" is NOT unknown if any STK page has `nickname: "Raj"` — even if the page's `name` field is "Rajiwath Patel". Failure to check both fields causes false unknown-stakeholder blockers.
- The `known_names` set is built at Step 2 using Bash grep — do NOT read individual STK pages into context. The grep runs fresh against `wiki/stakeholders/` so any STK pages created by prior `/sara-add-stakeholder` runs in this session are included without loading them into the context window.
- Priority 1 (unknown stakeholders) must be fully cleared before any Priority 2 blocker is tackled. Batch all unknown stakeholders upfront; do not interleave stakeholder work with source comprehension work.
- Priority 2 (source comprehension) clarification uses plain-text output and waits for the user's reply. Do NOT use AskUserQuestion for these open-ended questions (freeform rule applies). AskUserQuestion is only invoked within the inline sara-add-stakeholder sub-skill during Priority 1 work.
- Stage advance to `"extracting"` happens ONLY after all blockers across Priority 1 and Priority 2 are resolved AND after the git commit of discuss.md succeeds. Do not write `"extracting"` partway through the session, and do not write `"extracting"` before the commit.
- CRITICAL — Stage advance to 'extracting' happens ONLY after the git commit of discuss.md succeeds. Writing state.md with stage: extracting before the commit would leave the item stuck if the commit fails (Pitfall 1).
- state.md is updated using Read + Write tools only — never shell text-processing tools. Read the current state.md, modify the stage: field in LLM memory, write the full file back.
- discuss.md is written with the Write tool only. No Bash text-processing on markdown files.
- The `discuss.md` content is the key output — it carries resolved context forward into `/sara-extract`. Make it specific: include STK-NNN IDs for resolved stakeholders and clear explanations of any source ambiguities. Entity type classification and cross-reference identification are handled by the sorter in `/sara-extract`, not here.
- The N argument is the full pipeline item ID (e.g. `MTG-001`). The state.md file for item MTG-001 is at `.sara/pipeline/MTG-001/state.md`. For `/sara-discuss MTG-001`, read `.sara/pipeline/MTG-001/state.md`.
- When invoking `/sara-add-stakeholder` inline: read `.claude/skills/sara-add-stakeholder/SKILL.md` fresh for each stakeholder. Pass the stakeholder name as `$ARGUMENTS`. The sub-skill will collect optional fields (nickname, vertical, department, email, role) via AskUserQuestion before writing the STK page and committing. This is expected — the AskUserQuestion calls originate from the sub-skill, which is why `AskUserQuestion` is in this skill's `allowed-tools`.
</notes>
