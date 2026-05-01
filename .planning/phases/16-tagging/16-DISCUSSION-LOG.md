# Phase 16: tagging - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 16-tagging
**Areas discussed:** Tag population, Tag vocabulary, Tag purpose + scope, Lint check coverage

---

## Gray Area Selection

| Option | Selected |
|--------|----------|
| Tag population — how do tags get assigned? | ✓ |
| Tag vocabulary — free-form vs controlled | ✓ |
| Tag purpose + scope — what tagging enables | ✓ |
| Lint check coverage — D-08 check design | ✓ |

---

## Tag Population

| Option | Description | Selected |
|--------|-------------|----------|
| Sara-lint D-08 only | New lint check curates tags via whole-wiki LLM pass, same approval+commit pattern as D-07 | |
| Sara-extract + lint repair | Populate tags during extraction, D-08 catches legacy pages | ✓ |
| Manual /sara-tag command | New slash command; LLM suggests, user approves | |

**Initial selection:** Sara-extract + lint repair

**User clarification (key insight):** Tags are not per-artifact labels — they are emergent concepts across the wiki. Looking at a single page to generate tags produces incoherent labels. The correct model: LLM reads the wiki as a whole, identifies what conceptual themes emerge, then asks which of those tags apply to each page. This is fundamentally different from per-artifact tagging.

**Revised selection:** D-08 only — whole wiki

| Option | Description | Selected |
|--------|-------------|----------|
| D-08 only — whole wiki | Extract leaves tags: [] default; D-08 derives emergent concepts from full corpus then assigns | ✓ |
| Extract seeds, D-08 refines | Two-stage: extract suggests per-artifact tags, D-08 normalises | |

**Notes:** The whole-wiki model was the decisive insight. Sara-extract only sees one source document; it cannot derive emergent concepts across the full wiki.

---

## Tag Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Free-form LLM strings | LLM generates descriptive labels; no upfront config | ✓ |
| Controlled vocabulary from config | User defines allowed tags at sara-init time | |
| Hybrid: suggested from wiki + free | LLM reuses existing tags but can introduce new ones | |

**User's choice:** Free-form LLM strings — but with the whole-wiki emergent model, consistency comes from deriving the vocabulary corpus-wide before assignment, not from a predefined list.

---

## Tag Purpose + Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Wiki browsing / navigation | Tags shown in index.md as grouping dimension | |
| Future /sara-query filtering | Tags become filter axis for planned query command | ✓ |
| Display only for now | Populate field; no structural changes to index.md or query | |

**User's choice:** Future /sara-query filtering — tags are designed as a query filter axis from the start.

---

## D-08 Approval UX

| Option | Description | Selected |
|--------|-------------|----------|
| Vocabulary-first, then batch assign | Present inferred vocabulary for approval, then assign across all pages with summary | ✓ |
| Per-page approval (like D-07) | For each changed page, present current vs proposed and ask Apply/Skip | |

**Notes:** Vocabulary-first was recommended and selected because per-page approval would be impractical at full-wiki scale.

---

## Tag Format

| Option | Description | Selected |
|--------|-------------|----------|
| Lowercase kebab-case | e.g. 'authentication', 'data-governance'. Consistent, grep-friendly | ✓ |
| Title case with spaces | e.g. 'Data Governance'. Readable but harder to filter | |
| Free-form, no normalisation | LLM writes as-is; risks 'auth' vs 'authentication' mismatches | |

---

## D-08 Re-run Behaviour

| Option | Description | Selected |
|--------|-------------|----------|
| Full re-evaluation each run | Re-derives vocabulary from current corpus; replaces all tags | ✓ |
| Incremental — only untagged pages | Skips already-tagged pages unless forced | |
| Flag missing, user-triggered refresh | D-08 flags empty tags; full re-evaluation only on explicit request | |

---

## Tags Per Artifact

| Option | Description | Selected |
|--------|-------------|----------|
| 2–5 tags per artifact | Target range; LLM instructed to stay within it | |
| No limit — LLM decides | LLM judges based on artifact's conceptual footprint | ✓ |
| 1–3 tags per artifact | Tight constraint; forces LLM to pick only most essential | |

---

## D-08 Trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit only — /sara-lint --tags | D-08 skipped in regular lint; opt-in only | |
| Always — part of every sara-lint run | D-08 runs every invocation including sara-update auto-invoke | ✓ |

---

## Claude's Discretion

- Context window management for large wikis (full-page reads vs summary-based vocabulary derivation)
- Ordering of D-08 within the lint check sequence
- Exact format of vocabulary approval prompt
- Whether assignment summary is a table or inline per-type
- Atomic commit scope (all tag updates in one commit vs one per entity type)

## Deferred Ideas

None — discussion stayed within phase scope.
