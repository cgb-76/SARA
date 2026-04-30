# Phase 13: lint-refactor - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 13-lint-refactor
**Areas discussed:** Phase scope, Check scope, Back-fill behavior, Semantic fix flow, Concept page creation, Commit strategy

---

## Phase Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Implement v2 lint checks | Extend stubbed Checks 2/3 and add new v2.0 field checks | |
| Refactor other skills | Structural refactoring of other SARA skills | |
| Lint + wiki maintenance | Full LLM-driven health-check per llm-wiki design intent | ✓ |

**User's choice:** Rewrite sara-lint as a full wiki health-check consistent with the llm-wiki vision — not just field validation but LLM reasoning over the wiki to find contradictions, stale claims, missing concept pages, and cross-reference gaps. Body structure (cross-links) is in scope, not just frontmatter.

**Notes:** User shared the llm-wiki design document excerpt: *"Periodically, ask the LLM to health-check the wiki. Look for: contradictions between pages, stale claims that newer sources have superseded, orphan pages with no inbound links, important concepts mentioned but lacking their own page, missing cross-references, data gaps that could be filled with a web search."*

---

## Check Scope

| Option | Description | Selected |
|--------|-------------|----------|
| All checks | Mechanical + semantic | ✓ |
| Mechanical only | grep-detectable field/structure checks only | |
| Semantic only | LLM reasoning checks only | |

**User's choice:** All checks — full health-check in this phase.

---

## Back-fill Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Infer + back-fill | Generate missing values, confirm, commit | ✓ |
| Report only | Flag gaps, no writes | |
| Hybrid | Back-fill mechanical, report semantic | |

**User's choice:** Infer + back-fill for all mechanical gaps.

---

## Semantic Fix Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Tiered autonomy | Auto-apply derivable fixes, report ambiguous | |
| Per-finding approval | Every fix shown individually, user accepts/rejects | ✓ |
| Batch report + select | Health report first, then apply selected fixes | |

**User's choice:** Per-finding approval for all fixes — mechanical and semantic.

**Notes:** User also clarified that lint should be able to *maintain* wiki content (not just report), consistent with the llm-wiki design intent. Lint never rewrites narrative body content unilaterally — it can update frontmatter fields, add/remove `related[]` IDs, and update `status` values. Body rewrites require user-supplied text.

---

## Concept Page Creation (Missing Concepts Check)

| Option | Description | Selected |
|--------|-------------|----------|
| Create stubs on confirm | Frontmatter-only stub after accept | |
| Suggest only | Surface concept name, user creates manually | |
| Mini-interview on accept | Accept/reject, then interview fills body before creating | ✓ |

**User's choice:** Accept/reject per concept → if accepted, lint runs a short interview (what is it, why it matters, how it relates to the project) → user answers become the page body → page created with full frontmatter + body.

---

## Concept Page Entity Type

| Option | Description | Selected |
|--------|-------------|----------|
| New type: concept (CON-NNN) | New entity type for concept pages | |
| Decision page | Map concepts to DEC entity type | |
| PGE-NNN (Page) | New generic wiki page entity type | ✓ |

**User's choice:** PGE-NNN — "Page" entity type. Intentionally minimal: id, title, summary, schema_version, tags, related. Lives in `wiki/pages/`.

---

## Commit Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| One commit per fix | Atomic commit after each accepted fix | ✓ |
| Batch commit at end | Single commit for entire lint run | |

**User's choice:** One commit per fix — consistent with sara-update's atomic commit pattern.

---

## Claude's Discretion

- Exact ordering and grouping of checks within the lint run
- Threshold for proposing a PGE (how many page mentions before a concept qualifies)
- Summary count before the per-finding loop vs jumping straight in
- Exact wording of per-finding prompts

## Deferred Ideas

- `--fix` flag for non-interactive batch apply — future enhancement
- sara-init update to include `wiki/pages/` and PGE template
- Full body-text rewrite proposals (body rewrites require user-supplied text in v1)
