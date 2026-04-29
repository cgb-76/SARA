# Phase 7: adjust-agent-workflow - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 07-adjust-agent-workflow
**Areas discussed:** Extraction architecture, sorter retention, file cleanup

---

## Problem Statement

The specialist agent architecture (Phase 6) passes the full source document to 4 parallel Task() agents, costing ~4x the source document size in tokens. Production SARA sources are expected to be much larger; the current approach does not scale with document size or number of artifact types.

---

## Extraction Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Typed buckets | Main loop classifies passages by type, each specialist gets only its bucket | |
| Un-typed candidate list | Main loop extracts all notable passages without classifying; each specialist receives the same small list | |
| Sequential inline passes (Option C) | Eliminate specialist Task() agents; main loop runs one extraction pass per type using inline prompts; source doc stays in context | ✓ |

**User's choice:** Sequential inline passes — source document read once, four sequential LLM passes inside the main skill loop, no Task() for specialist extraction.

**Notes:** Parallel Task() with inline prompts was considered (keeping speed, eliminating agent files) but rejected — Task() agents start cold and still require the full source document passed explicitly in the prompt, which is the core cost problem.

---

## Sorter Agent

| Option | Description | Selected |
|--------|-------------|----------|
| Stays as-is | Sorter input (merged artifacts + grep summaries + wiki index) is unchanged | ✓ |
| Needs review | Check if sorter assumptions about upstream format need updating | |

**User's choice:** Stays as-is. Sorter receives no source document — only the merged artifact array (small regardless of source size) — so the token cost problem does not apply.

---

## Per-type Prompt Location

| Option | Description | Selected |
|--------|-------------|----------|
| Inline in the step | Prompts written directly in Step 3 of SKILL.md | ✓ |
| Notes section | Prompt templates in a `<notes>` block, referenced from Step 3 | |

**User's choice:** Inline in Step 3.

---

## Specialist Agent File Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Remove from install.sh | Update install.sh to only distribute the sorter agent; specialist files deleted | ✓ |
| Leave install.sh unchanged | Keep specialist files in repo but unused | |

**User's choice:** Remove from install.sh. Four specialist agent files deleted; only `sara-artifact-sorter.md` remains.

---

## Deferred Ideas

- Un-typed candidate pre-filtering (Option B): discussed and set aside in favour of simpler sequential inline passes
- Parallel inline passes: not feasible without Task() (which reintroduces the doc-passing problem)
