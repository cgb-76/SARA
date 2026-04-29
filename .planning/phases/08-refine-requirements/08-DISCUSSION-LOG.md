# Phase 8: refine-requirements - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 08-refine-requirements
**Areas discussed:** Phase goal definition, Extraction signals, MoSCoW priority, Type taxonomy, Wiki page structure, Section matrix

---

## Phase Goal Definition

| Option | Description | Selected |
|--------|-------------|----------|
| REQUIREMENTS.md reconciliation | Audit docs to match what was built | |
| v2 feature: sara-query | Build natural language query command | |
| Refine artifacts starting with requirements | Two tracks: extraction prompt + wiki page format | ✓ |

**User's choice:** Refine all artifacts starting with requirements (decisions, risks etc. in subsequent phases). Two tracks: (1) how requirements are extracted in sara-extract, (2) how they're written to the wiki. Extraction focus: tighten the prompt beyond the current vague definition. Writing focus: best practice sections — language, acceptance criteria, user stories, etc.

---

## Extraction — Primary Signal

| Option | Description | Selected |
|--------|-------------|----------|
| Linguistic markers | Modal verbs: must, shall, should, will, need to, required to, has to | ✓ |
| Commitment language + source role | Modals combined with who is committing | |
| Intent over language | Sharpen current definition with negative examples | |

**User's choice:** Linguistic markers (modal verbs) as primary signal.

---

## Extraction — MoSCoW Priority

| Option | Description | Selected |
|--------|-------------|----------|
| Capture modal as field (recommended) | Store strength as a field | |
| Filter out weak modals | Only extract must/shall/will | |
| Treat all modals as equal | No strength field | |
| MoSCoW format | must-have / should-have / could-have / wont-have mapped from modals | ✓ |

**User's choice:** MoSCoW format — capture priority as `must-have`, `should-have`, `could-have`, `wont-have` mapped from modal verb strength.

---

## Extraction — Type Classification Location

| Option | Description | Selected |
|--------|-------------|----------|
| Inline extraction pass | Type + MoSCoW assigned in same step as identification | ✓ |
| Sorter agent | Extraction finds passages only; sorter classifies | |

**User's choice:** Inline extraction pass — simpler, no extra round-trip.

---

## Type Taxonomy

**User drove the definition:**
- Regulatory = external only (not internal policy/governance)
- Drop Constraints as a separate type — fold into Non-functional
- Rename Interface → Integration
- Data and Business rule confirmed

**Final list:** functional | non-functional | regulatory | integration | business-rule | data

---

## Wiki Page Structure

**User corrections to proposed layout:**
- `summary` moves under `title` in frontmatter (not after `description` which is removed)
- The **entire** markdown body is replaced by the new structure (not just some fields)
- `## Cross Links` section added at bottom
- sara-update must write `related[]` values as wiki links, one per line, following link conventions

**User request:** Build a matrix of which sections apply to which types, with rationale embedded in the skill file.

---

## Section Matrix

**Matrix agreed:**

| Section | Functional | Non-functional | Regulatory | Integration | Business rule | Data |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Source Quote | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Statement | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| User Story | ✓ | opt | — | opt | — | — |
| Acceptance Criteria | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| BDD Criteria | ✓ | — | — | opt | ✓ | — |
| Context | opt | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cross Links | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**User's instruction:** Include the rationale for each cell in the skill file so future maintainers understand the why.

---

## Claude's Discretion

- Number of BDD scenarios per requirement (one primary + edge cases vs. exactly one)
- Whether sara-lint should back-fill new schema fields on existing requirement pages
- Exact wording of the updated extraction prompt negative examples

## Deferred Ideas

- Apply same two-track refinement to decisions, risks, actions — subsequent phases
- REQUIREMENTS.md documentation gap (MEET-01/02, sara-lint, sara-add-stakeholder mismarked) — not scoped here
- sara-lint migration pass for existing REQ pages to v2.0 schema
