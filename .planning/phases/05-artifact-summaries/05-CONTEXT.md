# Phase 5: artifact-summaries - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a `summary` frontmatter field to all wiki artifact types (REQ, DEC, ACT, RISK, STK). Generate the field at write time in `sara-update`. Switch `sara-extract` and `sara-discuss` from full-page reads to a grep-extract pattern (reading only `summary` fields across all artifacts). Create `/sara-lint` as a new maintenance skill whose v1 implementation back-fills missing summaries on existing artifacts.

**Why:** At 500+ artifacts, full-page reads in `sara-extract` and `sara-discuss` blow out the context window. The `summary` field enables a grep-extract pattern — one grep returns all artifact summaries compactly, giving enough semantic signal for cross-referencing without loading full pages.

No new ingest pipeline steps. No wiki directory changes. Schema extension + read-pattern change + new maintenance skill.

</domain>

<decisions>
## Implementation Decisions

### Summary field schema

- **D-01:** Field name: `summary` — added to the YAML frontmatter of all five entity templates (`.sara/templates/requirement.md`, `decision.md`, `action.md`, `risk.md`, `stakeholder.md`).
- **D-02:** Field type: single prose string. The LLM writes type-appropriate content into one field — no per-type sub-fields.
- **D-03:** Content is type-specific. The summary must include enough for `sara-extract` to confidently decide create-vs-update without reading the full page:
  - **REQ:** title, status, one-line description of what is required
  - **DEC:** options considered, chosen option/recommendation, status, decision date
  - **ACT:** owner, due-date, status (open/in-progress/done/cancelled)
  - **RISK:** likelihood, impact, mitigation approach, status
  - **STK:** vertical, department, role — enough to distinguish from other stakeholders

### Length configuration

- **D-04:** `summary_max_words: 50` stored in `.sara/pipeline-state.json` alongside existing state/config. 50 words ≈ 2–3 sentences — sufficient for cross-ref decisions, not bloated.
- **D-05:** The value is configurable by editing `pipeline-state.json` directly. No dedicated config command needed in v1.

### Generation: sara-update

- **D-06:** `sara-update` generates the `summary` field as part of every artifact write — both `create` and `update` actions. The LLM writes it using the type-specific content rules in D-03, within the `summary_max_words` limit from D-04.
- **D-07:** If `summary_max_words` is absent from `pipeline-state.json`, default to 50.

### Read-pattern change: grep-extract

- **D-08:** `sara-extract` (Step 3 — dedup check) replaces reading full artifact pages with a grep-extract. The pattern: grep all wiki subdirectories for the `summary:` field, returning `filename: summary: "..."` per artifact. Use this compact view to identify create-vs-update and spot cross-link opportunities.
- **D-09:** `sara-discuss` replaces any full artifact page reads with the same grep-extract pattern when surfacing cross-link opportunities.
- **D-10:** If an artifact has no `summary` field (pre-existing artifact), the grep will omit it. In that case: fall back to reading the full page for that artifact only. This is acceptable during the transition period before `/sara-lint` is run.
- **D-11:** `sara-update` already writes full pages — no grep-extract change needed there. It generates summaries (D-06) but reads pages normally.

### New skill: /sara-lint

- **D-12:** `/sara-lint` is a new maintenance skill. v1 scope: scan all wiki artifact pages, identify those missing a `summary` field, generate summaries for them, write them back, and commit.
- **D-13:** UX: lint presents a count of artifacts missing summaries + a preview of one generated summary, then asks the user to confirm before batch-writing and committing. Dry-run-first pattern.
- **D-14:** Commit message: `fix(wiki): back-fill artifact summaries via sara-lint`.
- **D-15:** `/sara-lint` is designed for extensibility — future checks (orphaned pages, broken cross-refs, stale actions, index validation) are added as additional steps. v1 only implements the summary back-fill check.

### wiki/CLAUDE.md behavioral contract

- **D-16:** Add a rule to `wiki/CLAUDE.md`: "When writing or updating any wiki artifact, always generate or refresh the `summary` field using the type-specific content rules and the `summary_max_words` limit from `pipeline-state.json`." This ensures the rule is auto-loaded for all wiki-scoped skills.

### Claude's Discretion

- Exact grep command syntax for the grep-extract pattern (single grep across all wiki subdirs, or per-subdir)
- Whether `/sara-lint` processes artifact types in a fixed order or alphabetically
- Exact wording of the lint confirmation prompt and preview format
- Whether the `summary` field is inserted at the top of frontmatter or at the end

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing skill implementations (read to understand current patterns before changing them)
- `.claude/skills/sara-extract/SKILL.md` — Current dedup/cross-ref logic at Step 3; grep-extract replaces full-page reads here
- `.claude/skills/sara-discuss/SKILL.md` — Current cross-link surfacing; grep-extract replaces full reads here
- `.claude/skills/sara-update/SKILL.md` — Current artifact write flow; summary generation is added to Step 2

### Templates (summary field added to each)
- `.sara/templates/requirement.md` — Add `summary:` field
- `.sara/templates/decision.md` — Add `summary:` field
- `.sara/templates/action.md` — Add `summary:` field
- `.sara/templates/risk.md` — Add `summary:` field
- `.sara/templates/stakeholder.md` — Add `summary:` field

### Behavioral contract (rule added here)
- `wiki/CLAUDE.md` — Auto-loaded behavioral contract; D-16 rule added here

### Project context
- `.planning/REQUIREMENTS.md` — `/sara-lint` is listed as a v2 requirement; this phase delivers v1 of it
- `.planning/PROJECT.md` — Constraints: git-backed, Read+Write tools only for pipeline-state.json

### State/config
- `.sara/pipeline-state.json` — `summary_max_words: 50` added here (D-04)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/skills/sara-update/SKILL.md` — Step 2 artifact write loop; summary generation slots in here per artifact
- `.claude/skills/sara-extract/SKILL.md` — Step 3 dedup loop; grep-extract replaces existing index read + any full page reads
- `.claude/skills/sara-discuss/SKILL.md` — Cross-link surfacing section; grep-extract replaces full reads

### Established Patterns
- All pipeline-state reads/writes use Read + Write tools only — never Bash shell text-processing tools. Grep (via Bash) is acceptable for the grep-extract read pattern since it's a read-only operation across wiki files.
- Stage guards are Step 1 in all process skills — `/sara-lint` follows the same pattern (though it guards on wiki existence, not pipeline stage).
- Commit is always the final step; `stage=complete` (or equivalent) only after successful commit.

### Integration Points
- `pipeline-state.json` → add `summary_max_words: 50`
- `.sara/templates/*.md` → add `summary:` field to each
- `wiki/CLAUDE.md` → add behavioral rule D-16
- `.claude/skills/sara-extract/SKILL.md` → change Step 3 read pattern
- `.claude/skills/sara-discuss/SKILL.md` → change cross-link read pattern
- `.claude/skills/sara-update/SKILL.md` → add summary generation in Step 2
- New: `.claude/skills/sara-lint/SKILL.md`

</code_context>

<specifics>
## Specific Ideas

- The grep-extract pattern is a single Bash grep across wiki subdirs returning `filename:summary: "..."` — compact enough to load 500 summaries without blowing context.
- Fall-back to full-page read for summary-less artifacts (D-10) ensures no regression during the transition period before lint is run.
- `/sara-lint` extensibility is explicit in the SKILL.md design — stub out future check sections so future phases can add checks without redesigning the skill.
- `summary_max_words` defaulting to 50 if absent (D-07) makes the field optional in pipeline-state during rollout.

</specifics>

<deferred>
## Deferred Ideas

- **Future /sara-lint checks:** orphaned pages, broken cross-references, contradicting status fields, stale open Actions, index validation (bidirectional), regenerable index via `--fix` — all v2 per REQUIREMENTS.md.
- **Structured per-type summary sub-fields:** keeping summary as a single prose field in v1; could become structured (e.g. `summary_status`, `summary_decision`) if grep-parsing needs to be more precise in v2.

</deferred>

---

*Phase: 05-artifact-summaries*
*Context gathered: 2026-04-28*
