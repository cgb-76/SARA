# Phase 14: Extraction Pipeline Fix - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 2 (both modifications to existing skills)
**Analogs found:** 2 / 2 (self-referential — both files are their own primary analog)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `.claude/skills/sara-extract/SKILL.md` | skill/orchestrator | sequential-transform (extract → approve → write) | Itself — Step 3 pass loop and Step 5 write | exact (same file, adjacent steps) |
| `.claude/skills/sara-update/SKILL.md` | skill/writer | CRUD + transform (resolve → write → commit) | Itself — Step 2 counter-increment-before-write loop | exact (same file, same step) |

---

## Pattern Assignments

### `.claude/skills/sara-extract/SKILL.md` — Step 3: temp_id assignment during inline passes

**What changes:** Each extraction pass currently sets `related: []` as a literal empty array. Phase 14 replaces this with a `temp_id` field (8-hex random string) assigned inline on each artifact object. The `related` field stays as `[]` at extraction time — the full-mesh linking happens in Step 5, not in Step 3.

**Analog pattern — current Step 3 field initialization** (sara-extract/SKILL.md lines 96, 154, 200, 253):

The four passes each set a line equivalent to:
```
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`, `related` = `[]`, `change_summary` = `""`
```

**Copy pattern — add `temp_id` assignment to each pass:**

In each of the four passes (requirements, decisions, actions, risks), add `temp_id` alongside the other field initializations:

```
- Set `temp_id` = an 8-character lowercase hex string generated at extraction time.
  Use: Bash one-liner `python3 -c "import secrets; print(secrets.token_hex(4))"` OR
  generate inline as a random 8-hex string (e.g. `a3f2b901`). Each artifact gets a
  unique temp_id — do not reuse across artifacts in the same batch.
- Set `action` = `"create"`, `type` = `"requirement"`, `id_to_assign` = `"REQ-NNN"`,
  `related` = `[]`, `change_summary` = `""`
```

Apply identically in all four passes:
- Requirements pass (currently line 96 of sara-extract/SKILL.md)
- Decisions pass (currently line 154)
- Actions pass (currently line 200)
- Risks pass (currently line 253)

**Analog pattern — Step 5 write block** (sara-extract/SKILL.md lines 378–406):

```
Read `.sara/pipeline-state.json` using the Read tool.

Update `items["{N}"]` in memory:
  - Set `stage` = `"approved"`
  - Set `extraction_plan` = the `approved_artifacts` array (may be empty if all artifacts were rejected)

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.

Step 5 ALWAYS writes the full `approved_artifacts` array to `extraction_plan`, replacing any
previously stored value. Do NOT read or merge a pre-existing `extraction_plan` — overwrite
it unconditionally.

Do NOT use Bash shell text-processing tools — use Read and Write tools only.
```

**Copy pattern — insert full-mesh linking block BEFORE the write in Step 5:**

Insert this block between the approval loop completion and the `pipeline-state.json` write:

```
**Full-mesh related[] linking**

After all artifacts are resolved to "Accept" or "Reject":

Build the full-mesh related[] for all approved artifacts:
  For each artifact `A` in `approved_artifacts`:
    Set `A.related` = array of `temp_id` values of all OTHER artifacts in `approved_artifacts`
    (i.e. every temp_id in `approved_artifacts` except `A.temp_id` itself)

For a single-artifact batch: `A.related` = `[]` (the other-artifacts set is empty — no special case needed)
For a zero-artifact batch: skip this step entirely (approved_artifacts is empty)

This replaces the `related: []` that was set during Step 3. The temp_id values are stable
cross-reference keys — they persist in extraction_plan until sara-update resolves them to
real IDs at the start of Step 2.
```

**Error handling pattern** (inherited from existing Step 5):

```
Step 5 ALWAYS writes the full `approved_artifacts` array to `extraction_plan`, replacing
any previously stored value. Do NOT read or merge a pre-existing `extraction_plan` —
overwrite it unconditionally.

Do NOT use Bash shell text-processing tools — use Read and Write tools only.
```

No new error handling required — the linking step is pure in-memory mutation of already-validated objects.

---

### `.claude/skills/sara-update/SKILL.md` — Step 2: temp_id → real_id resolution

**What changes:** At the start of Step 2 (before the write loop), build a `temp_id → real_id` map by peeking at current counters, then do an in-memory substitution pass over all `related[]` arrays in the `extraction_plan`. The write loop then runs unchanged — `artifact.related` already contains real IDs by the time any page is written.

**Analog pattern — counter-increment-before-write** (sara-update/SKILL.md lines 83–87):

```
Increment `counters.entity.{entity_type_key}` by 1 in the in-memory JSON state (do NOT
re-read `pipeline-state.json` — the counters loaded in Step 1 are kept current in memory
across loop iterations; each Write call below persists the latest state).

Write the updated `pipeline-state.json` immediately using the Write tool (the counter
increment MUST be persisted before the page is written — this prevents duplicate ID
assignment if a page write fails and the skill is re-run).

Compute `{assigned_id}` = `"{entity_type_key}-"` + zero-padded 3-digit counter
(e.g. counter = 1 → `"REQ-001"`).
```

**Critical constraint from notes** (sara-update/SKILL.md line 608):

```
CRITICAL: Entity counter increments happen BEFORE each create-action page write, and the
updated counter is written to `pipeline-state.json` immediately (as a separate Write call
before the page Write call). This prevents duplicate ID assignment if a page write fails
and the skill is re-run. Counters are tracked in-memory across loop iterations — the
in-memory state is authoritative after each Write; do NOT re-read `pipeline-state.json`
inside the loop.
```

**Copy pattern — temp_id → real_id resolution block at start of Step 2:**

Insert this block BEFORE "Initialize `written_files = []` and `failed_files = []`":

```
**Temp ID resolution (before write loop)**

Build the `temp_id → real_id` map by simulating the ID assignment sequence without
incrementing the counters:

  Initialize `id_map` = {} (empty mapping)
  Initialize `preview_counters` = deep copy of `counters.entity` from the in-memory state
    (do NOT modify the real counters — these are read-only preview increments)

  For each artifact in `{extraction_plan}` where `artifact.action == "create"`:
    Determine `{entity_type_key}` from `artifact.type`:
    - `requirement` → `REQ`
    - `decision`    → `DEC`
    - `action`      → `ACT`
    - `risk`        → `RSK`
    Increment `preview_counters.{entity_type_key}` by 1
    Compute `{preview_id}` = `"{entity_type_key}-"` + zero-padded 3-digit preview counter
    Set `id_map[artifact.temp_id]` = `{preview_id}`
    (skip artifacts where `artifact.action == "update"` — they have no temp_id)

Do NOT write `preview_counters` to `pipeline-state.json`. The real counter increments
happen inside the write loop as they always have (Pitfall 1 guard preserved).

**Substitution pass:**

  For each artifact in `{extraction_plan}`:
    For each entry `t` in `artifact.related`:
      If `id_map[t]` exists: replace `t` with `id_map[t]`
      If `id_map[t]` does not exist: leave `t` unchanged (it may already be a real ID
        from a sorter cross-reference resolution in sara-extract Step 3)

After this pass, all `artifact.related` arrays in the in-memory `extraction_plan` contain
real entity IDs. Proceed to "Initialize `written_files = []`" and the write loop.

Do NOT write the substituted `extraction_plan` back to `pipeline-state.json` at this
point — the write loop persists counters on each create-action iteration as before.
The temp_id fields on artifact objects may be left in `pipeline-state.json` (they are
inert after resolution) or stripped — either is acceptable.
```

**Analog pattern — related[] write in frontmatter** (sara-update/SKILL.md lines 96–97):

```
- `related` = `artifact.related` (array of entity IDs)
```

This line is UNCHANGED. By the time the write loop reaches this field, `artifact.related` already contains resolved real IDs from the substitution pass. No change to the write loop is required.

**Analog pattern — Cross Links body section generation** (sara-update/SKILL.md lines 229–236):

```
## Cross Links
{Generate one wiki link per entry in artifact.related. Resolve display text per wikilink rule:
 - STK entities: [[STK-NNN|name]] — read wiki/stakeholders/{ID}.md for the name field
 - REQ/DEC/ACT/RSK entities: [[ID|ID Title]] — read wiki/index.md for the title
 - If title/name cannot be resolved: fall back to bare [[ID]]
 Write each link on its own line. If artifact.related is empty, write this heading with no
 content (heading-only — consistent with the established empty-section pattern for this skill).}
```

This section is UNCHANGED. It already reads from `artifact.related` — which now contains real IDs after the substitution pass.

---

## Shared Patterns

### Read/Write tools only — no Bash text-processing on pipeline-state.json

**Source:** Both skill files (sara-extract/SKILL.md line 388, sara-update/SKILL.md line 617)
**Apply to:** Both modified files

```
Do NOT use Bash shell text-processing tools — use Read and Write tools only.
pipeline-state.json is read and written using Read and Write tools only — never Bash
shell text-processing tools.
```

This constraint applies equally to the new temp_id assignment (Step 3 of sara-extract) and the substitution pass (Step 2 of sara-update). Both are pure in-memory operations on already-loaded JSON — no file re-reads or shell text manipulation.

### Counter increment-before-write (Pitfall 1 guard)

**Source:** sara-update/SKILL.md lines 83–87, 608
**Apply to:** sara-update Step 2 resolution block

The resolution block peeks at counters WITHOUT incrementing them. The real counters are only incremented inside the write loop, immediately before each page write, as they always have been. The preview counter sequence must match the real loop sequence exactly (same artifact order, same type-key mapping, same zero-padding).

### In-memory state authority

**Source:** sara-update/SKILL.md lines 83–84, 608
**Apply to:** Both modified files

```
the counters loaded in Step 1 are kept current in memory across loop iterations;
each Write call below persists the latest state
```

For the resolution block: `preview_counters` is a local copy only — it does not replace or affect the in-memory `counters.entity` object that the write loop uses.

---

## No Analog Found

None — both files are modifications to existing skills with well-established internal patterns. The temp_id mechanism follows the same in-memory JSON mutation and Read/Write-only patterns already present in both skills.

---

## Metadata

**Analog search scope:** `.claude/skills/sara-extract/`, `.claude/skills/sara-update/`, `.planning/phases/07-adjust-agent-workflow/`, `.planning/phases/13-lint-refactor/`
**Files scanned:** 4 skill/context files read in full
**Pattern extraction date:** 2026-04-30
