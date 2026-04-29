---
phase: 9
slug: refine-decisions
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual — no automated test suite (SKILL.md files, markdown/text editing) |
| **Config file** | none |
| **Quick run command** | Manual inspection of modified SKILL.md files |
| **Full suite command** | Manual end-to-end: run sara-extract on sample transcript, verify artifact JSON fields |
| **Estimated runtime** | ~5 minutes manual review |

---

## Sampling Rate

- **After every task commit:** Spot-check modified SKILL.md section for correctness
- **After every plan wave:** Manual end-to-end validation pass
- **Before `/gsd-verify-work`:** Full manual suite must pass
- **Max feedback latency:** ~5 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 9-01-01 | 01 | 1 | D-01/D-02/D-03 | — | N/A | manual | grep for commitment/misalignment phrases in SKILL.md | ✅ | ⬜ pending |
| 9-01-02 | 01 | 1 | D-04/D-06 | — | N/A | manual | grep for dec_type/chosen_option/alternatives fields in SKILL.md | ✅ | ⬜ pending |
| 9-01-03 | 01 | 1 | sorter passthrough | — | N/A | manual | grep for dec_type/status in sorter output_format example | ✅ | ⬜ pending |
| 9-02-01 | 02 | 1 | D-07/D-08/D-09/D-10 | — | N/A | manual | grep for schema_version and type field in sara-init SKILL.md | ✅ | ⬜ pending |
| 9-02-02 | 02 | 1 | D-11/D-12 | — | N/A | manual | grep for ## Source Quote section in template | ✅ | ⬜ pending |
| 9-03-01 | 03 | 2 | D-05/D-11 | — | N/A | manual | grep for dec_type mapping and status: accepted/open in sara-update | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. This phase is SKILL.md text editing only — no test framework installation required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Extraction signal detection (commitment vs misalignment) | D-01 | LLM prompt behaviour, no unit tests | Run sara-extract on sample transcript with known decision; verify status=accepted or status=open in output JSON |
| Type classification (six types) | D-06 | LLM classification, no unit tests | Run sara-extract on sample; verify dec_type is one of: architectural, process, tooling, data, business-rule, organisational |
| v2.0 wiki page body sections | D-11/D-12 | Markdown output, no unit tests | Run sara-update create; inspect generated .sara/decisions/DEC-NNN.md for ## Source Quote, ## Context, ## Decision, ## Alternatives Considered, ## Rationale sections |
| open decision body | D-12 | Prose output | Run sara-update with status:open artifact; verify ## Decision reads "No decision reached — alignment required." |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5 minutes (manual)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
