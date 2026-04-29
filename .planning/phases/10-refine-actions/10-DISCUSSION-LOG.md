# Phase 10: refine-actions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 10-refine-actions
**Areas discussed:** Extraction signals, Type classification, Owner extraction, Body structure

---

## Extraction signals

| Option | Description | Selected |
|--------|-------------|----------|
| Assignment language | Explicit assignment to a person required — no owner = not an action | |
| Task markers + intent | Explicit markers (AI:, Action:, TODO:) AND assignment language | |
| Any task intent | Broadest: any passage implying work needs to happen, even without a named owner | ✓ |

**User's choice:** Any task intent (broadest net)
**Notes:** Actions without owners should be called out during the Step 4 accept/reject/discuss loop — not filtered at extraction time. The user wanted the widest extraction and to resolve ownership interactively.

---

## Exclusion list

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit exclusion list | Define what NOT to extract in the pass | |
| No exclusion list | Rely on existing sorter | ✓ |

**User's choice:** No explicit exclusion list needed
**Notes:** User pointed out the existing sorter already handles cross-type deduplication and ambiguity. Confirmed this covers the risk/decision overlap case.

---

## Due date extraction

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — extract as raw string | Capture "by Friday", "EOW" etc. as-is; user resolves date manually | ✓ |
| Yes — normalise to ISO 8601 | Attempt to resolve relative dates at extraction time | |
| No — leave blank | Due date set manually post-extraction | |

**User's choice:** Yes — extract as raw string
**Notes:** No normalisation risk; user keeps control over date resolution.

---

## Type classification

| Option | Description | Selected |
|--------|-------------|----------|
| No type taxonomy | Actions are simpler; type adds friction | |
| Minimal (2 types) | deliverable vs follow-up | ✓ |
| Full taxonomy (4 types) | task, follow-up, commitment, investigation | |

**User's choice:** Minimal 2-type taxonomy
**Notes:** deliverable = concrete output to produce; follow-up = check-in, response, or update required.

---

## Owner extraction

| Option | Description | Selected |
|--------|-------------|----------|
| Separate owner field | owner distinct from raised_by | ✓ |
| Keep current proxy | raised_by continues to proxy for owner | |

**User's choice:** Separate owner field
**Notes:** raised_by = who surfaced the item; owner = who is assigned to do it. Both STK-NNN if resolvable, raw name string if not.

---

## Owner warning behaviour

| Option | Description | Selected |
|--------|-------------|----------|
| Warning only | Flag in approval loop; user can still accept | ✓ |
| Block acceptance | Require STK ID resolution before accepting | |

**User's choice:** Warning only
**Notes:** Unresolved owner writes raw name string to wiki page; user reconciles after update.

---

## Body structure

| Option | Description | Selected |
|--------|-------------|----------|
| Lean (4 sections) | Source Quote, Description, Owner & Due Date, Cross Links | |
| Standard (5 sections) | Source Quote, Description, Context, Owner & Due Date, Cross Links | |
| Full (6 sections) | Source Quote, Description, Context, Owner, Due Date (each own heading), Cross Links | ✓ |

**User's choice:** Full 6 sections
**Notes:** Owner and Due Date get their own headings — they are primary tracking fields for action management.

---

## Body synthesis

| Option | Description | Selected |
|--------|-------------|----------|
| Synthesise description | sara-update writes 2–4 sentence Description and Context | ✓ |
| Quote only | Only source quote; Description empty for user to fill | |

**User's choice:** Synthesise description and context from source doc + discussion notes

---

## Claude's Discretion

- Exact wording of updated extraction prompt
- Whether to add negative examples to the extraction prompt
- Summary generation wording for deliverable vs follow-up actions

## Deferred Ideas

- Refine risk artifact — subsequent phase
- sara-lint backfill for existing ACT pages predating v2.0 schema
