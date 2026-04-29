# Phase 9: refine-decisions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 09-refine-decisions
**Areas discussed:** Extraction signal, Type classification, Schema v2.0

---

## Extraction Signal

| Option | Description | Selected |
|--------|-------------|----------|
| Commitment language | Phrases like "we decided", "we chose", "we agreed on" — past/present-tense commitment | ✓ |
| Outcome phrases only | Narrower: only explicit decision-outcome phrases | |
| Modal verb overlap | Reuse Phase 8's modal verb list with decision-specific framing | |

**User's choice:** Commitment language — but also the inverse: misalignment/disagreement extracts as `status: open`. Concluded/aligned decisions extract as `status: accepted`. Drop `proposed` as initial status entirely.

**Notes:** User clarified that "if we're all aligned, we're done and the decision is accepted" — there's no reason for an accepted decision to be `open`. The two statuses reflect two real states: concluded (`accepted`) and unresolved (`open`).

---

## Type Classification

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — 6 types mirroring requirements | architectural, process, tooling, data, business-rule, organisational | ✓ |
| Yes — simpler 3-type taxonomy | technical, process, business | |
| No types for decisions | Keep decisions type-free | |

**User's choice:** 6 types mirroring requirements, classified inline in the same extraction pass.

**Notes:** User confirmed British English spelling: `organisational` (not `organizational`).

---

## Schema v2.0

### Extraction depth

| Option | Description | Selected |
|--------|-------------|----------|
| Source quote + chosen option + alternatives | Structured choice data extracted; sara-update synthesises Context and Rationale | ✓ |
| Source quote only | Minimal extraction; all synthesis in sara-update | |
| Full structured extraction | Extract context, rationale, deciders inline | |

**User's choice:** Option 1 — extraction captures `source_quote`, `chosen_option`, `alternatives`. sara-update synthesises narrative sections from the full source doc in context.

**Notes:** Discussion explored whether changing the artifact JSON schema was a problem for the sorter. Conclusion: no — the sorter passes extra fields through unchanged (established in Phase 8 with `req_type`/`priority`). Option 3 rejected because extraction pass can't reliably pull rationale from informal source material; sara-update with full source in context does this better.

### Frontmatter shape

| Option | Description | Selected |
|--------|-------------|----------|
| Drop narrative fields, add type | Remove context/decision/rationale/alternatives-considered from frontmatter; add type | ✓ |
| Keep narrative fields, add type | Keep duplication, add type | |
| Drop narrative, add type + chosen_option | Add structured chosen_option frontmatter field | |

**User's choice:** Drop narrative frontmatter fields, add type only.

### Body section order

| Option | Description | Selected |
|--------|-------------|----------|
| Source Quote → Context → Decision → Alternatives Considered → Rationale | Narrative order: what was said → why needed → what chosen → what else → why chosen | ✓ |
| Source Quote → Decision → Context → Alternatives Considered → Rationale | Lead with the answer | |

**User's choice:** Source Quote → Context → Decision → Alternatives Considered → Rationale

---

## Claude's Discretion

- Exact wording of the extraction prompt
- Whether to include negative examples in the extraction prompt
- Summary field wording for `accepted` vs `open` decisions

## Deferred Ideas

- Refine action artifact — subsequent phase
- Refine risk artifact — subsequent phase
