---
phase: 8
slug: refine-requirements
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no automated test suite in this project) |
| **Config file** | None |
| **Quick run command** | Read modified SKILL.md files and confirm changes match CONTEXT.md decisions |
| **Full suite command** | End-to-end: run `/sara-extract` against a test fixture and inspect the approved artifact list for `priority` and `req_type` fields; run `/sara-update` and inspect the written wiki page |
| **Estimated runtime** | ~10 minutes (manual inspection) |

---

## Sampling Rate

- **After every task commit:** Read the modified skill file; confirm changed section matches the decision from CONTEXT.md
- **After every plan wave:** Not applicable (no automated test runner)
- **Before `/gsd-verify-work`:** End-to-end run of `/sara-extract` + `/sara-update` on a synthetic source document containing modal verbs of different strengths
- **Max feedback latency:** Manual review cadence

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 8-01-01 | 01 | 1 | D-01/D-02 | T-08-03 | Negative examples block observations/aspirations | Manual — LLM prompt review | `grep -n "INCLUDE — these passages ARE requirements" .claude/skills/sara-extract/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 8-01-01 | 01 | 1 | D-03/D-04 | — | MoSCoW priority assigned inline | Manual — artifact inspection | `grep -n "priority.*must-have" .claude/skills/sara-extract/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 8-01-01 | 01 | 1 | D-05 | — | Six-type classification assigned inline | Manual — artifact inspection | `grep -n "req_type" .claude/skills/sara-extract/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 8-01-02 | 01 | 1 | Sorter | — | priority/req_type survive sorter passthrough | Manual — sorter output inspection | `grep -n "priority.*must-have\|req_type.*functional" .claude/agents/sara-artifact-sorter.md` | ❌ Wave 0 | ⬜ pending |
| 8-02-01 | 02 | 2 | D-06/D-09 | — | v2.0 frontmatter shape in template | Manual — file inspection | `grep -n "schema_version.*2.0\|type:\|priority:" .claude/skills/sara-init/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 8-02-02 | 02 | 2 | D-10/D-11 | — | Structured body + section matrix in template | Manual — file inspection | `grep -n "Source Quote\|Section\|Acceptance Criteria" .claude/skills/sara-init/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 8-03-01 | 03 | 2 | D-12 | — | Cross Links written from related[] | Manual — file inspection | `grep -n "Cross Links" .claude/skills/sara-update/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 8-03-02 | 03 | 2 | D-06/D-09 | — | Update branch writes v2.0 frontmatter | Manual — file inspection | `grep -n "schema_version.*2.0" .claude/skills/sara-update/SKILL.md` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test fixture document: a synthetic meeting transcript containing requirements with `must`, `should`, `could`, and aspirational language (to verify extraction precision)
- [ ] Verification checklist: document the exact inspection steps for each decision (file fields to check, sections to confirm)

*All verification is manual for this phase — the project has no automated test suite.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Modal verbs are the primary extraction signal | D-01/D-02 | LLM prompt text — no runtime to execute | Read sara-extract/SKILL.md Step 3; confirm INCLUDE list, EXCLUDE examples present |
| MoSCoW priority mapped from modal verb inline | D-03/D-04 | Requires running /sara-extract against live source | Run `/sara-extract` on test fixture; inspect `priority` field in approval loop output |
| Six-type classification assigned inline | D-05 | Requires running /sara-extract against live source | Inspect `req_type` field in approval loop output |
| v2.0 frontmatter shape on written pages | D-06 to D-09 | Requires running /sara-update end-to-end | Read a written REQ-NNN.md; confirm `schema_version: '2.0'`, `type`, `priority` present, `description` absent |
| Structured body sections with section matrix | D-10/D-11 | Requires running /sara-update end-to-end | Inspect body of written REQ-NNN.md; confirm all required sections present for the artifact's req_type |
| Cross Links written from related[] | D-12 | Requires running /sara-update end-to-end | Inspect `## Cross Links` section of a REQ page with non-empty `related[]` |
| priority and req_type survive sorter passthrough | Sorter fix | Requires full pipeline run | Inspect cleaned_artifacts output from sorter; confirm new fields present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < manual review cadence
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
