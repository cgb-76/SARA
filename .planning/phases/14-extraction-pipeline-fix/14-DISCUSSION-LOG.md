# Phase 14: Extraction Pipeline Fix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 14-extraction-pipeline-fix
**Areas discussed:** ID placeholder strategy, Inference scope, Rejected artifact cleanup

---

## ID Placeholder Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Array indices | sara-extract adds related_batch_indices field; sara-update resolves at write time | |
| Peek at counters | sara-extract reads current counters to assign provisional real IDs | |
| sara-update does the linking | sara-extract leaves related: []; sara-update builds related[] after writing all pages | |
| 8-hex temp_id (user proposal) | Random temp ID per artifact; full-mesh after approval loop; sara-update resolves before writing | ✓ |

**User's choice:** 8-hex random temp_id per artifact. Assign at Step 3 (extraction passes), build full-mesh related[] at Step 5 (post-approval), resolve temp_id → real_id at start of sara-update Step 2.

**Notes:** User identified the index corruption problem directly — rejected artifacts would corrupt index-based related[] if linking happened before the approval loop. Proposed the temp_id approach as a cleaner alternative. The temp_id approach avoids corruption because linking happens post-approval over approved_artifacts only.

---

## Inference Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full mesh | Every approved artifact links to every other approved artifact in the batch | ✓ |
| Selective / topical filtering | Only link artifacts that appear topically related | |

**User's choice:** Full mesh over approved_artifacts.

**Notes:** All artifacts in a batch derive from the same source document, making full mesh semantically appropriate. Selective filtering would require semantic judgment at extract time — unnecessary complexity.

---

## Rejected Artifact Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Scrub at Step 4 | Remove rejected artifact refs from surviving artifacts' related[] | |
| Leave for sara-lint | Leave dangling refs; lint detects broken related[] IDs | |
| Non-issue (post-approval linking) | Linking happens after approval loop; rejected artifacts never enter related[] | ✓ |

**User's choice:** Non-issue — resolved by the post-approval linking design.

**Notes:** Because full-mesh linking runs at Step 5 over approved_artifacts only, rejected artifacts are structurally excluded. No cleanup logic needed.

---

## Claude's Discretion

- Exact temp_id generation method (Bash one-liner vs inline LLM hex string)
- Whether temp_id is stored in pipeline-state.json or resolved in-memory and stripped

## Deferred Ideas

None.
