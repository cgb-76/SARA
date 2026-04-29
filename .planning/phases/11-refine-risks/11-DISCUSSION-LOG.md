# Phase 11: refine-risks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 11-refine-risks
**Areas discussed:** Extraction signal, Likelihood & impact, Mitigation field, Status lifecycle

---

## Extraction Signal

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, add risk_type | Add type taxonomy mirroring req_type/dec_type/act_type from prior phases | ✓ |
| No type, just tighten the signal | Keep single-bucket extraction, better examples only | |
| You decide | Match prior phases | |

**User's choice:** Add `risk_type` classification

---

| Option | Description | Selected |
|--------|-------------|----------|
| technical / commercial / operational / people | Four broad buckets | |
| technical / financial / schedule / quality / compliance / people | Six granular PM risk register buckets | ✓ |
| You decide | | |

**User's choice:** Six-bucket taxonomy: technical / financial / schedule / quality / compliance / people

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, extract owner separately | Mirrors action pattern from Phase 10 | ✓ |
| No, keep raised_by only | Simpler, manual owner assignment | |

**User's choice:** Extract `owner` as a distinct field separate from `raised_by`

---

| Option | Description | Selected |
|--------|-------------|----------|
| Synthesise in sara-update | Consistent with decisions/actions — narrative synthesised, never extracted raw | ✓ |
| Extract inline as mitigation field | Verbatim extraction | |

**User's choice:** Mitigation synthesised by sara-update, not extracted inline

---

## Likelihood & Impact

| Option | Description | Selected |
|--------|-------------|----------|
| Extract inline when signals present | Map source language to high/medium/low when signal present; leave empty otherwise | ✓ |
| Leave as manual fields | Always empty at extraction time | |
| You decide | | |

**User's choice:** Extract likelihood and impact inline when source signals are present

---

| Option | Description | Selected |
|--------|-------------|----------|
| No severity field — keep it simple | Likelihood + impact are sufficient; severity is derivable | ✓ |
| Add severity: low / medium / high / critical | Extra frontmatter field for filtering | |

**User's choice:** No severity field

---

## Mitigation Field

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, remove from frontmatter | Consistent with Phase 9 pattern; frontmatter for structured fields only | ✓ |
| Keep mitigation in both places | One-liner in frontmatter + narrative in body | |

**User's choice:** Remove `mitigation` from frontmatter entirely; body section only

---

| Option | Description | Selected |
|--------|-------------|----------|
| Source Quote / Risk (IF...THEN...) / Mitigation / Cross Links | Custom format specified by user | ✓ |
| Source Quote / Description / Triggers / Mitigation / Cross Links | Five sections with explicit Triggers section | |
| Source Quote / Description / Mitigation / Cross Links | Four simple sections | |

**User's choice:** Four sections: Source Quote / Risk / Mitigation / Cross Links
**Notes:** The `## Risk` section uses `IF <trigger> THEN <adverse_event>` format with IF and THEN in caps. This was user-specified, not one of the presented options.

---

## Status Lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| All new risks start as 'open' | Simple, consistent with actions | |
| Signal-based initial status | Extract status from source language like decisions | ✓ |

**User's choice:** Signal-based initial status

---

| Option | Description | Selected |
|--------|-------------|----------|
| Keep all four: open / mitigated / accepted / closed | Full lifecycle | |
| Simplify to: open / closed | Less granular | |
| You decide | | |

**User's choice (custom):** Three values: `open` / `mitigated` / `accepted`. `closed` removed — user noted that once open, a risk resolves to either mitigated or accepted, not simply closed.

---

| Option | Description | Selected |
|--------|-------------|----------|
| open by default, mitigated/accepted from explicit language | Default open; map explicit acceptance/mitigation language | ✓ |
| You decide | | |

**User's choice:** Default `open`; `mitigated` or `accepted` set when source contains explicit language indicating controls in place or risk tolerated

---

## Claude's Discretion

- Exact wording of the extraction prompt
- Whether to add negative examples (confirmed problems = actions; background context = not a risk)
- Summary generation wording per status value

## Deferred Ideas

- sara-lint backfill for existing RSK pages predating v2.0 schema
