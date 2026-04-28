# Phase 6: refine-entity-extraction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 06-refine-entity-extraction
**Areas discussed:** Specialist agent I/O, Agent output format, Sorter role, Approval loop, sara-discuss scope, Agent implementation

---

## Specialist agent I/O

| Option | Description | Selected |
|--------|-------------|----------|
| Source + discussion notes only | Lightweight — agents focus on extraction, sorter handles dedup | ✓ |
| Source + discussion notes + grep summaries | Each agent can flag obvious duplicates pre-sorter | |
| Source + discussion notes + type rubric | No summaries, leaves all dedup to sorter, gives agents a classification contract | |

**User's choice:** Source + discussion notes only
**Notes:** Discussion notes must be explicitly passed in the Task() prompt — agents start cold with no implicit access to sara-discuss context.

---

## Agent output format

| Option | Description | Selected |
|--------|-------------|----------|
| JSON array matching current artifact schema | Consistent format from all 4 agents; sorter consumes directly | ✓ |
| Loose prose / markdown | More flexible but sorter bears full parsing burden | |

**User's choice:** JSON array matching current artifact schema

---

## Sorter role

| Option | Description | Selected |
|--------|-------------|----------|
| Merge, dedup, cross-ref — output clean list | Human sees result only, not sorter's working | |
| Merge + surface questions to human | Sorter outputs cleaned list AND ambiguity questions; human resolves before approval loop | ✓ |
| Sorter IS the approval loop | Combines classification reasoning with Accept/Reject/Discuss flow | |

**User's choice:** Merge + surface questions to human
**Notes:** Two-stage flow: sorter questions first, then existing per-artifact approval loop on the resolved list.

---

## Approval loop

| Option | Description | Selected |
|--------|-------------|----------|
| Keep existing Accept/Reject/Discuss loop as-is | Runs on sorter's cleaned, resolved list; no mechanic change | ✓ |
| Drop the approval loop | Sorter questions replace per-artifact approval | |
| Optional — user chooses | Approve-all vs review-each after sorter | |

**User's choice:** Keep existing Accept/Reject/Discuss loop as-is

---

## sara-discuss scope

| Option | Description | Selected |
|--------|-------------|----------|
| Source comprehension + unknown stakeholders only | Classification, dedup, cross-ref move to sorter | ✓ |
| Source comprehension only | STK surfacing also moves to sara-extract | |
| Keep sara-discuss as-is | No change to discuss; some duplication acceptable | |

**User's choice:** Source comprehension + unknown stakeholders only

---

## Agent implementation

| Option | Description | Selected |
|--------|-------------|----------|
| 5 agents: 4 type-specialists + 1 sorter | sara-requirement-extractor.md, sara-decision-extractor.md, sara-action-extractor.md, sara-risk-extractor.md, sara-artifact-sorter.md | ✓ |
| 4 agents: type-specialists only, sorter inline | Sorter logic in SKILL.md; can't be refined independently | |
| 6 agents including orchestrator | sara-extract SKILL.md becomes thin entry point | |

**User's choice:** 5 agents in `.claude/agents/` following `sara-{type}-extractor` / `sara-artifact-sorter` convention
**Notes:** Naming convention: `sara-requirement-extractor`, `sara-decision-extractor`, `sara-action-extractor`, `sara-risk-extractor`, `sara-artifact-sorter`. Pattern is noun-first, not verb-first.

---

## Claude's Discretion

- Parallel vs sequential specialist agent spawning
- Exact prompt structure within each agent file
- How sorter presents questions to human
- Sorter behaviour when a specialist returns zero artifacts
- Order of sorter questions when multiple ambiguities exist

## Deferred Ideas

None
