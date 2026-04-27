---
name: sara-add-stakeholder
description: "Capture stakeholder details, write STK wiki page, and commit — standalone or callable inline from sara-discuss"
argument-hint: "[<name>]"
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
version: 1.0.0
---

<objective>
Capture a stakeholder's details — name (required), plus optional fields: nickname, vertical,
email, role, and department — write a frontmatter-only STK wiki page, increment the STK counter
in pipeline-state.json, update wiki/index.md and wiki/log.md, and commit everything in a single
atomic git commit. This skill operates as a standalone command (`/sara-add-stakeholder`) and is
also callable inline from `/sara-discuss` during blocker resolution — when called inline, it
returns the assigned `STK-NNN` ID for the calling skill to use immediately.
</objective>

<process>

**Step 1 — Collect stakeholder name**

If `$ARGUMENTS` is non-empty: use the argument value as `{name}`. Proceed to Step 2.

Otherwise: output the following as plain text and wait for the user's reply:

```
What is the stakeholder's full formal name? (required — must not be blank)
```

Capture the reply as `{name}`. If blank: repeat the prompt once more; if still blank, output `"Name is required. Aborting."` and STOP.

**Step 2 — Collect optional fields via AskUserQuestion**

Read `.sara/config.json` using the Read tool. Store the `verticals` array for the Vertical prompt
and the `departments` array for the Dept prompt below.

Collect the following fields in order. Each is optional — user may choose Skip:

```
AskUserQuestion:
  header: "Nickname"
  question: "Colloquial name appearing in meeting body text? (e.g. 'Raj' for 'Rajiwath') — or skip"
  options: ["Skip"]
```
Capture reply as `{nickname}`. If "Skip": set `{nickname}` = `""`.

```
AskUserQuestion:
  header: "Vertical"
  question: "Which market vertical? (leave blank if unknown)"
  options: [values from .sara/config.json verticals array] + ["Skip"]
```
Capture reply as `{vertical}`. If "Skip": set `{vertical}` = `""`.

```
AskUserQuestion:
  header: "Dept"
  question: "Which department? (leave blank if unknown)"
  options: [values from .sara/config.json departments array] + ["Skip"]
```
Capture reply as `{department}`. If "Skip": set `{department}` = `""`.

**Step 2b — Sync new values to config**

Re-read `.sara/config.json` using the Read tool (use the already-read copy if still in memory).

If `{vertical}` is non-empty and not already present in `config.verticals`: append `{vertical}` to the `verticals` array and write the updated JSON back to `.sara/config.json` using the Write tool.

If `{department}` is non-empty and not already present in `config.departments`: append `{department}` to the `departments` array and write the updated JSON back to `.sara/config.json` using the Write tool.

If neither value is new, skip the write.


```
AskUserQuestion:
  header: "Email"
  question: "Email address? (leave blank if unknown)"
  options: ["Skip"]
```
Capture reply as `{email}`. If "Skip": set `{email}` = `""`.

```
AskUserQuestion:
  header: "Role"
  question: "Role or title? (leave blank if unknown)"
  options: ["Skip"]
```
Capture reply as `{role}`. If "Skip": set `{role}` = `""`.

**Step 3 — Assign STK-NNN ID**

Read `.sara/pipeline-state.json` using the Read tool.

Increment `counters.entity.STK` by 1. The new value is `{stk_counter}`.

Compute `{new_id}` = `"STK-"` + zero-padded 3-digit counter (e.g. 1 → `STK-001`, 12 → `STK-012`).

Write the modified JSON back to `.sara/pipeline-state.json` using the Write tool.

Do NOT use shell text-processing tools for this — use Read and Write tools only.

**Step 4 — Write STK wiki page**

Use the Write tool to create `wiki/stakeholders/{new_id}.md` with the following content, substituting all collected values. Use `""` for any field that was left blank or skipped:

```markdown
---
id: {new_id}
name: "{name}"
nickname: "{nickname}"  # colloquial name from transcript body text
vertical: "{vertical}"    # from project config verticals list
department: "{department}"  # from project config departments list
email: "{email}"
role: "{role}"
schema_version: "1.0"
related: []
---
```

No body sections. Frontmatter only — stakeholders are reference data, not document-style pages (D-11 constraint).

**Step 5 — Update wiki/index.md and wiki/log.md**

Read `wiki/index.md` using the Read tool.

Append a new row to the table:

```
| [[{new_id}]] | {name} | active | stakeholder | [] | {today YYYY-MM-DD} |
```

Write the updated `wiki/index.md` back using the Write tool.

Read `wiki/log.md` using the Read tool.

Append the following entry after the existing content:

```
| — | {today YYYY-MM-DD} | stakeholder | (standalone) | {new_id} created — {name} |
```

Write the updated `wiki/log.md` back using the Write tool.

**Step 6 — Commit and report**

Run the following Bash command. If `.sara/config.json` was updated in Step 2b, include it in the staged files:

```bash
git add wiki/stakeholders/{new_id}.md wiki/index.md wiki/log.md .sara/pipeline-state.json
# If config was updated:
git add .sara/config.json
git commit -m "feat(sara): add stakeholder {new_id} — {name}"
```

(Always run `git add .sara/config.json` — if the file was not modified it will be a no-op.)

Output to the user:

```
{new_id} created — {name}
STK page: wiki/stakeholders/{new_id}.md
Committed: feat(sara): add stakeholder {new_id} — {name}
```

When this skill is called inline from `/sara-discuss`: the output `{new_id}` is the return value for the calling skill's context. `/sara-discuss` should add this ID to its running list of resolved stakeholders and continue from the point of interruption.

</process>

<notes>
- `vertical` (market segment) and the functional area field are ALWAYS written as two separate
  YAML fields — never combined. The functional area field name is `department`. This separation
  is a locked domain constraint (project memory).
- All empty optional fields are stored as `""` (empty string), not null or omitted. This ensures the YAML structure is consistent and parseable in all cases.
- The STK-NNN ID is assigned BEFORE the page is written (counter increment in Step 3, file write in Step 4). This ensures `counters.entity.STK` in pipeline-state.json is always consistent with written STK pages — even if the Write call for the page fails, the counter reflects the attempt and prevents ID reuse.
- When called inline from `/sara-discuss`: `/sara-discuss` first reads `.claude/skills/sara-add-stakeholder/SKILL.md`, then executes this skill inline for the current unknown stakeholder. After Step 6 completes, `/sara-discuss` resumes with the returned `{new_id}` added to its resolved-stakeholders context. The caller should continue iterating over remaining unknown stakeholders before moving on to other blocker priorities.
- `schema_version` must always be quoted: `"1.0"` — unquoted, YAML parsers (including Obsidian) interpret `1.0` as a float, which breaks frontmatter round-trips.
- AskUserQuestion header lengths: "Nickname" = 8, "Vertical" = 8, "Dept" = 4, "Email" = 5, "Role" = 4 — all within the 12-character hard limit.
- New verticals and departments entered via "New..." are appended to `.sara/config.json` in Step 2b and committed alongside the STK page in Step 6. This keeps the config in sync so the new value appears as a selectable option in future `/sara-add-stakeholder` runs.
- The git add list in Step 6 uses explicit file paths — never `git add .` or `git add -A`. This ensures only the four expected files are staged and no unintended files are committed.
- If `$ARGUMENTS` is provided (inline caller supplies the name), Step 1 skips the plain-text prompt entirely and uses the argument directly. The argument is the stakeholder's full formal name as determined by the calling skill.
</notes>
