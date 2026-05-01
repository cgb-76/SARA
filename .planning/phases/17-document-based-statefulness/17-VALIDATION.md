---
phase: 17
slug: document-based-statefulness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — SARA skills are markdown/LLM workflows; verification is filesystem-based |
| **Config file** | none |
| **Quick run command** | `ls .sara/pipeline/ 2>/dev/null && echo OK` |
| **Full suite command** | `ls .sara/pipeline/*/state.md 2>/dev/null && echo OK` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `ls .sara/pipeline/ 2>/dev/null && echo OK`
- **After every plan wave:** Run `ls .sara/pipeline/*/state.md 2>/dev/null && echo OK`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | — | — | N/A | filesystem | `grep -q "pipeline/" .claude/skills/sara-init/SKILL.md && echo OK` | ✅ | ⬜ pending |
| 17-02-01 | 02 | 1 | — | — | N/A | filesystem | `grep -q "pipeline/" .claude/skills/sara-ingest/SKILL.md && echo OK` | ✅ | ⬜ pending |
| 17-03-01 | 03 | 2 | — | — | N/A | filesystem | `grep -q "state.md" .claude/skills/sara-discuss/SKILL.md && echo OK` | ✅ | ⬜ pending |
| 17-04-01 | 04 | 2 | — | — | N/A | filesystem | `grep -q "plan.md" .claude/skills/sara-extract/SKILL.md && echo OK` | ✅ | ⬜ pending |
| 17-05-01 | 05 | 3 | — | — | N/A | filesystem | `grep -q "plan.md" .claude/skills/sara-update/SKILL.md && echo OK` | ✅ | ⬜ pending |
| 17-06-01 | 06 | 3 | — | — | N/A | filesystem | `grep -q "log.md" .claude/skills/sara-minutes/SKILL.md && echo OK` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework installation needed — all verification is filesystem-based (grep, ls, file existence checks).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end ingest → extract → update pipeline via new directory structure | Phase goal | Requires full pipeline execution with real content | Run `/sara-ingest` on a test file, verify `.sara/pipeline/{ID}/` created, run `/sara-extract`, verify `plan.md` written, run `/sara-update`, verify wiki page created and stage=complete in state.md |
| STATUS mode lists items from filesystem | D-06 | Requires running skill with no arguments | Run `/sara-ingest` with no args, verify table lists items from `.sara/pipeline/*/state.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
