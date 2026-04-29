---
phase: 07-adjust-agent-workflow
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - .claude/skills/sara-extract/SKILL.md
  - install.sh
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 07: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two files were reviewed: the `sara-extract` skill specification (procedural Markdown source) and the `install.sh` bash installer script. The skill document is well-structured with strong defensive notes, but contains two logic gaps: a stale `src_ver` variable scoping issue across the skills loop, and a missing guard for the "re-run on interrupted session" scenario when `extraction_plan` already exists. The installer has two correctness issues: the `tmp_file` trap fires on every loop exit (not just the final iteration) due to shared variable reuse, and the agents loop has no `mkdir -p` guard for the destination directory. Three informational items cover minor documentation and style improvements.

---

## Warnings

### WR-01: `tmp_file` trap deletes the wrong file on subsequent loop iterations

**File:** `install.sh:24,86,116,133,158`

**Issue:** The `EXIT` trap (`rm -f "${tmp_file:-}"`) holds a reference to a single shared variable `tmp_file`. Because `mv` at line 116 and 158 moves (not deletes) the temp file, the variable still holds a path. If the script exits cleanly after the skills loop but before the agents loop (e.g., on SIGINT mid-run), `tmp_file` points to the last assigned value. More concretely: within the skills loop, after a successful `mv "${tmp_file}" "${dest_file}"` (line 116), `tmp_file` still refers to the now-moved path — but if the next iteration's `mktemp` assignment fails (e.g., disk full), `set -e` exits and the trap fires with the stale path, which no longer exists. This is benign for cleanup but masks the real risk: if the process exits between `tmp_file="$(mktemp)"` (line 133) and the first use of that value, the trap will clean up correctly — but the trap captures the variable by reference, not by value, so any exit before line 133 leaves `tmp_file` pointing at the last skills-loop value (already moved away). The practical consequence is the trap does not clean up the agents-loop temp file if the process dies between line 133 and the agents-loop `mv`.

**Fix:** Use a dedicated cleanup function that tracks all temp files, or clear `tmp_file` immediately after each successful `mv`:

```bash
mv "${tmp_file}" "${dest_file}"
tmp_file=""   # prevent stale reference in EXIT trap
```

Apply this after both line 116 and line 158.

---

### WR-02: Agents loop missing `mkdir -p` for destination directory

**File:** `install.sh:126,158`

**Issue:** The agents loop creates `TARGET_AGENTS_DIR` at line 126 (`mkdir -p "$TARGET_AGENTS_DIR"`), but the destination file path is just `"${TARGET_AGENTS_DIR}/${agent_name}.md"` — a flat file, no subdirectory. This is fine today because all agent names produce flat paths. However, `mv "${tmp_file}" "${dest_file}"` at line 158 will fail with "No such file or directory" if `TARGET_AGENTS_DIR` itself does not exist at that point. The `mkdir -p` at line 126 guards this. The actual risk is: if the `mkdir -p` on line 126 silently fails (e.g., permissions), `set -e` would catch it and exit before the loop, so the `mv` is never reached. This is correct behavior. But the agents loop has no per-agent `mkdir -p "${dest_agent_dir}"` equivalent to the skills loop's line 115 (`mkdir -p "${dest_skill_dir}"`), meaning if the agent file structure ever becomes nested (subdirectories per agent), a new agent addition would silently fail with a misleading error. Document the structural assumption explicitly, or add a defensive `mkdir -p "$(dirname "${dest_file}")"` before the `mv` at line 158 to match the skills loop's pattern.

**Fix:**
```bash
mkdir -p "$(dirname "${dest_file}")"
mv "${tmp_file}" "${dest_file}"
```

---

### WR-03: SKILL.md — "Discuss" loop has no exit guard against infinite correction cycles

**File:** `.claude/skills/sara-extract/SKILL.md:170-176`

**Issue:** The "Discuss" path in Step 4 says "Repeat the Accept/Reject/Discuss cycle for this artifact until the user selects Accept or Reject." There is no documented limit on the number of Discuss iterations. If the user repeatedly selects "Discuss" without ever selecting "Accept" or "Reject", the loop runs indefinitely. While this is an LLM skill (not a traditional program), the specification should define what happens when the artifact cannot be resolved after N discuss cycles — otherwise an agent following this spec strictly can get stuck in an unbounded interaction loop.

**Fix:** Add a guard clause to the notes or process steps:

```
After {discuss_count} Discuss cycles on the same artifact (suggested limit: 5),
present a plain-text warning: "This artifact has been discussed {N} times. Please
select Accept or Reject to proceed, or Reject to skip it."
```

This prevents unbounded sessions without constraining normal use.

---

### WR-04: SKILL.md — Re-run on interrupted session does not handle pre-existing `extraction_plan`

**File:** `.claude/skills/sara-extract/SKILL.md:180`

**Issue:** The note at line 180 states "If `/sara-extract N` is re-run on an item that is still in `extracting` stage (possible if a previous session was interrupted): re-run the full loop with freshly generated artifacts." However, Step 5 writes `extraction_plan` and advances the stage to `"approved"` atomically. If the session is interrupted *after* Step 5 completes but *before* the summary is displayed (rare but possible), the stage becomes `"approved"` and a re-run would be blocked by the stage guard in Step 1. This is actually correct behavior. The real gap is the opposite: if a session is interrupted *during* Step 4 (mid-approval loop), the stage remains `"extracting"` and `extraction_plan` may be absent or partially written from a prior interrupted attempt. The spec says to "re-run the full loop" — but does not say to discard/ignore any stale `extraction_plan` that might exist in that state. An agent following the spec literally might read a partial `extraction_plan` at Step 5 and merge it incorrectly. The spec should explicitly state that Step 5 always overwrites `extraction_plan` in full (not appends).

**Fix:** Add to Step 5 or the notes:

```
Step 5 ALWAYS writes the full approved_artifacts array to extraction_plan,
replacing any previously stored value. Do NOT read or merge a pre-existing
extraction_plan — overwrite it unconditionally.
```

---

## Info

### IN-01: `install.sh` — version variable `src_ver` from the skills loop bleeds into agents loop scope

**File:** `install.sh:94,144`

**Issue:** `src_ver` is set in the skills loop (line 94) and is a shell-scoped variable. The agents loop uses a distinct name `src_ver_agent` (line 144), which is correct. However `src_ver` from the last skills iteration remains in scope during the agents loop. This is not a bug (the agents loop never reads `src_ver`), but the asymmetric naming (`src_ver` vs `src_ver_agent`) is a maintenance hazard. A future contributor adding a third loop type might accidentally reuse `src_ver`.

**Fix:** Rename `src_ver` to `src_ver_skill` in the skills loop (lines 94, 95, 103, 104) to match the agents loop's `src_ver_agent` naming pattern.

---

### IN-02: SKILL.md — `id_to_assign` placeholder format is not enforced for distinct types

**File:** `.claude/skills/sara-extract/SKILL.md:58,68,78,88`

**Issue:** Each extraction pass uses a generic placeholder: `"REQ-NNN"`, `"DEC-NNN"`, `"ACT-NNN"`, `"RSK-NNN"`. The notes at line 221 clarify these are placeholders resolved by the sorter. However, the spec does not state what happens if the sorter returns an artifact with `action=create` and `id_to_assign` still containing the literal `"REQ-NNN"` string (sorter failed to assign a real ID). Step 5 would write this placeholder into `extraction_plan`, and `/sara-update` would then try to create a file named `REQ-NNN.md` — a silent data quality issue.

**Fix:** Add a validation note in Step 5:

```
Before writing extraction_plan, validate that no artifact with action=create
has id_to_assign equal to a bare placeholder ("REQ-NNN", "DEC-NNN", "ACT-NNN",
"RSK-NNN"). If found, present a warning to the user and offer to reject that
artifact rather than write a placeholder ID to the wiki.
```

---

### IN-03: SKILL.md — `discussion_notes` pass-through note contradicts current inline architecture

**File:** `.claude/skills/sara-extract/SKILL.md:228`

**Issue:** The final note (line 228) says "The `discussion_notes` string MUST be passed explicitly in each specialist Task() prompt. Agents start cold and have no implicit access to pipeline-state.json." However, Step 3 was updated to use inline passes (no specialist Task() agents for extraction) — the note is a leftover from an earlier architecture. The note still applies to the sorter Task(), but the phrase "each specialist Task() prompt" is misleading and could cause a future maintainer to incorrectly add Task() calls for the extraction passes.

**Fix:** Revise the note to scope it to the sorter only:

```
The `discussion_notes` string is already in context from Step 1 for inline
extraction passes. If a specialist Task() is added in future, pass discussion_notes
explicitly — agents start cold and have no implicit access to pipeline-state.json.
(This currently applies to the sorter Task() only.)
```

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
