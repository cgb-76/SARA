---
phase: 11-refine-risks
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .claude/skills/sara-extract/SKILL.md
  - .claude/skills/sara-init/SKILL.md
  - .claude/skills/sara-update/SKILL.md
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three skill files were reviewed for v2.0 risk schema implementation. The risk extraction pass (sara-extract), the schema contract and templates (sara-init), and the wiki write logic (sara-update) were all examined. The v2.0 risk schema fields (`risk_type`, `likelihood`, `impact`, `status`, `owner`, `raised_by`) are consistently present across all three files. However, four actionable inconsistencies were found: a missing Cross Links section in the decision update branch, a within-file inconsistency in RSK summary rules between the create and update branches of sara-update, a schema version header mismatch in the generated CLAUDE.md, and an action artifact `raised-by` frontmatter mismatch. Three lower-priority items are also noted.

## Warnings

### WR-01: Decision update branch missing Cross Links section

**File:** `.claude/skills/sara-update/SKILL.md:376-398`

**Issue:** The decision artifact update branch rewrites the full body to v2.0 format but the body section instructions at lines 376–398 only enumerate five sections: Source Quote, Context, Decision, Alternatives Considered, Rationale. The `## Cross Links` section is absent from the update branch instructions. The decision create branch (lines 254–261) correctly includes Cross Links. Any decision artifact processed via `action == "update"` will have its Cross Links section silently dropped when the page is rewritten.

**Fix:** Add a Cross Links section to the decision update branch body instructions, immediately after the Rationale block and before the `Use the Write tool` line (~line 396):

```
## Cross Links
{Generate one wiki link per entry in artifact.related (after merging with the existing
 related[] array). Use the wikilink rule: STK → [[STK-NNN|name]], REQ/DEC/ACT/RSK →
 [[ID|ID Title]], fallback to [[ID]] if title/name cannot be resolved.
 Write each link on its own line. Write heading only if artifact.related is empty after merge.}
```

---

### WR-02: RSK summary rule omits `type` in create branch but includes it in update branch

**File:** `.claude/skills/sara-update/SKILL.md:118` (create branch) vs `344` (update branch)

**Issue:** The two branches specify different content for the RSK summary field. The create branch (line 118) says: `RSK: likelihood, impact, mitigation approach, status`. The update branch (line 344) says: `RSK: likelihood, impact, type, status, mitigation approach`. The `type` field is absent from the create branch rule. This means newly created risk pages will have summaries that omit the risk type, while updated risk pages will include it — producing inconsistent wiki page summaries across the corpus.

The sara-init risk template comment (`.claude/skills/sara-init/SKILL.md:529`) and the CLAUDE.md risk schema comment (line 183) are also split: the template comment includes `type` but the CLAUDE.md behavioral rules summary description omits `type`. The sara-update create branch is the operative instruction and it is missing `type`.

**Fix:** Update the create branch RSK summary rule at line 118 to match the update branch:

```
- RSK: likelihood, impact, type, status, mitigation approach
```

---

### WR-03: Generated CLAUDE.md declares `Schema version: 1.0` but embeds v2.0 entity schemas

**File:** `.claude/skills/sara-init/SKILL.md:159`

**Issue:** Step 9 writes a CLAUDE.md header: `**Schema version:** 1.0`. Below that header the same CLAUDE.md block embeds entity schemas that all declare `schema_version: '2.0'`. Any project initialised with `/sara-init` after Phase 11 will have a CLAUDE.md that says version 1.0 at the top but v2.0 in the entity schema blocks. If any skill or downstream tool reads the header version to decide behaviour, it will get the wrong value. Even without programmatic use, the mismatch is misleading for human readers.

**Fix:** Update the schema version header in the CLAUDE.md template written by sara-init Step 9 (line 159):

```markdown
**Schema version:** 2.0
```

---

### WR-04: Action artifact `raised-by` absent from action frontmatter template but present in create branch field mapping

**File:** `.claude/skills/sara-update/SKILL.md:95` vs `.claude/skills/sara-init/SKILL.md:471-488`

**Issue:** The sara-update create branch field mapping at line 95 includes a general instruction: `raised-by` = `artifact.raised_by`. This applies to all artifact types unless overridden. However, the action frontmatter template in sara-init (`.sara/templates/action.md`, lines 471–488) and the action schema in CLAUDE.md (lines 256–269) both omit the `raised-by` field entirely. If sara-update writes `raised-by` into an action page's frontmatter (following the general mapping), it will be an undocumented field not present in the schema contract. Conversely, if a future implementation follows the template strictly and omits it, the attribution blockquote in the Source Quote section will still work (it uses `raised_by` for the body line only), but inconsistency between the mapping instruction and the template creates ambiguity.

The risk and requirement templates both explicitly include `raised-by` in their frontmatter. The action template does not. The intent is unclear: is `raised-by` intentionally absent from action frontmatter, or was it omitted by oversight when the action schema was defined?

**Fix (option A — omit from action frontmatter, update mapping):** Clarify in the sara-update create branch that `raised-by` is NOT written to action page frontmatter. Add a note to the action artifact section:

```
- Do NOT write raised-by to action frontmatter — it is used only in the Source Quote body
  attribution line. The action schema does not define a raised-by frontmatter field.
```

**Fix (option B — add to action frontmatter):** Add `raised-by: ""` to the action template in sara-init Step 12 and to the action schema in CLAUDE.md Step 9, consistent with requirement and risk schemas.

Option A is lower-risk: it clarifies intent without schema change.

---

## Info

### IN-01: RSK summary description in CLAUDE.md behavioral rules omits `type`

**File:** `.claude/skills/sara-init/SKILL.md:183`

**Issue:** The `summary` field behavioral rule for RSK in CLAUDE.md (written by sara-init Step 9, line 183) reads: `RSK: likelihood/impact/mitigation/status`. This omits `type`. The risk template comment at line 529 reads: `# RSK: likelihood, impact, type, status, mitigation approach`. If `type` is added to the sara-update create branch rule (WR-02 fix), this CLAUDE.md behavioral rule description should also be updated to match, otherwise a reader of CLAUDE.md gets incomplete guidance.

**Fix:** Update the CLAUDE.md template RSK summary rule at line 183:

```
RSK: likelihood/impact/type/mitigation/status
```

---

### IN-02: Stakeholder `schema_version` uses double-quotes while all other entities use single-quotes

**File:** `.claude/skills/sara-init/SKILL.md:314` and `566`

**Issue:** The stakeholder schema in CLAUDE.md (line 314) and the stakeholder template (line 566) both write `schema_version: "1.0"` using double-quotes. Every other entity type uses single-quotes (e.g. `schema_version: '2.0'`). The difference is not just the version number — the quoting style also differs. The single-quote convention for `schema_version` was established precisely to prevent YAML float parsing. Double-quoting `"1.0"` also prevents float parsing, so this is not a functional bug, but the inconsistency in convention across templates could cause confusion.

**Fix:** This is intentional if stakeholder is remaining at v1.0. If so, add a comment to the stakeholder template clarifying it is intentionally v1.0. Otherwise, standardise to single-quotes: `schema_version: '1.0'`.

---

### IN-03: Index append hardcodes `open` for all artifact types regardless of extracted status

**File:** `.claude/skills/sara-update/SKILL.md:513`

**Issue:** Step 3's Bash append for CREATE artifacts hardcodes `open` as the index Status column value for every new artifact:

```bash
printf '%s\n' "| [[{assigned_id}]] | {artifact.title} | open | ...
```

Risk artifacts can legitimately have `status: "accepted"` or `status: "mitigated"` at creation time if the source document contains explicit signals (per sara-extract line 210–213). A risk with `artifact.status = "accepted"` would be written to its wiki page with `status: accepted` in the frontmatter but `open` in the index — an immediate inconsistency between the page and its index entry.

**Fix:** Replace the hardcoded `open` with a reference to the artifact's actual status:

```bash
printf '%s\n' "| [[{assigned_id}]] | {artifact.title} | {artifact.status} | {artifact.type} | [] | {today YYYY-MM-DD} |" >> wiki/index.md
```

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
