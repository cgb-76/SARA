# Phase 2: Ingest Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 02-ingest-pipeline
**Areas discussed:** Discussion skill flow, Extract approval granularity, Stakeholder discovery flow, Error & edge case handling

---

## Discussion Skill Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Present then converse | Summary → multi-turn freeform chat | |
| Guided questions only | Fixed AskUserQuestion prompts | |
| Single-shot analysis | One-shot output, no back-and-forth | |
| LLM-driven blocker-clearing | LLM generates blocker list, drives resolution in priority order | ✓ |

**User's choice:** LLM-driven blocker-clearing session — not freeform Q&A. The LLM has a job: clear all unknowns and inconsistencies that would cause issues in extraction. Stakeholders resolved first (batch), then ambiguities, then cross-links. Done when blocker list is empty.

**Notes:** User framed the insight: "The human isn't discussing it for the sake of being friends with the LLM, the LLM needs to drive the conversation." The goal is to surface and eliminate unknowns before extraction, not have a general conversation.

---

## Extract Approval Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Per-artifact approve/reject | Accept or reject each artifact individually | |
| Accept all or cancel | Binary — whole plan or nothing | |
| Approve with inline edits | Accept/reject/edit field values | |
| Per-artifact with discuss loop | Accept, reject, or discuss (revise + re-present) per artifact | ✓ |

**User's choice:** Per-artifact with accept, reject, discuss options. "Discuss" triggers inline correction — user provides context, SARA revises the artifact and re-presents it, loops back to accept/reject/discuss until resolved.

**Notes:** User specified the discuss loop explicitly: "loops around to accept / reject / discuss again."

---

## Stakeholder Discovery Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Inline as encountered | Handle each unknown as it appears in the blocker list | |
| Batch at the top | Collect all unknowns upfront, resolve all before other blockers | ✓ |
| End of discuss | Flag unknowns throughout, create at the end | |

**User's choice:** Batch at the top — consistent with "stakeholders first" intent stated during discussion skill flow discussion.

**Additional decisions from this area:**
- `/sara-add-stakeholder` is a reusable sub-skill: standalone + callable from other skills; closed-loop (capture → record → commit)
- Name is the only required field; all others optional with placeholders
- Stakeholder schema gains a `nickname` field — matches colloquial transcript names to formal speaker-label names
- Phase 1 artifacts (template + wiki/CLAUDE.md schema) require amendment to add `nickname`

**Notes:** User identified the nickname need from a real transcript pattern: "Raj might be what everyone calls him (in the transcription text), but his name is Rajiwath (in the transcription placeholder for who is talking)."

---

## Error & Edge Case Handling

| Question | Options | Selected |
|----------|---------|---------|
| Stage order violations | Hard stop with clear message / Warn and allow override | Hard stop with clear message |
| Missing file at ingest | Abort with helpful message / Create placeholder item | Abort with helpful message |
| Partial update failure | Leave state, report what happened / Auto git reset | Leave state, report what happened |

**User's choice:** All recommended defaults — hard stops with clear messages, no override paths, no auto-rollback.

**Notes:** All three questions selected the recommended option without discussion — straightforward decisions.

---

## Claude's Discretion

- Exact wording of blocker-list presentation in `/sara-discuss`
- Whether `/sara-extract` groups artifacts by type or source-document order
- Exact table format for `/sara-ingest` status display

## Deferred Ideas

None — discussion stayed within Phase 2 scope.
