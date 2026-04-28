---
phase: 3
slug: meeting-specialisation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash / manual skill invocation |
| **Config file** | none |
| **Quick run command** | `cat .planning/phases/03-meeting-specialisation/03-RESEARCH.md` |
| **Full suite command** | manual skill invocation tests per plan |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Check file outputs exist and contain expected sections
- **After every plan wave:** Run full invocation test per plan verification steps
- **Before `/gsd-verify-work`:** All success criteria verified manually
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | MEET-01 | — | Type guard rejects non-meeting items | manual | `grep -q '"type": "meeting"' pipeline-state.json` | ❌ W0 | ⬜ pending |
| 3-01-02 | 01 | 1 | MEET-01 | — | Minutes markdown written to correct path | manual | `ls wiki/minutes/` | ❌ W0 | ⬜ pending |
| 3-01-03 | 01 | 1 | MEET-01 | — | Plain-text email block output to stdout | manual | skill invocation | ❌ W0 | ⬜ pending |
| 3-02-01 | 02 | 1 | MEET-02 | — | Agenda draft output to stdout only, no wiki write | manual | skill invocation | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Fixture meeting pipeline-state.json with `"type": "meeting"` and populated `extraction_plan`
- [ ] Fixture non-meeting pipeline-state.json (e.g. `"type": "article"`) for guard testing

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Minutes markdown quality | MEET-01 | LLM output — no deterministic command | Invoke `/sara-minutes N`, review markdown structure |
| Email block readability | MEET-01 | LLM output | Check plain-text section below `---` separator |
| Agenda draft content | MEET-02 | LLM output | Invoke `/sara-agenda`, confirm agenda sections present |
| No wiki write on agenda | MEET-02 | File-system check | Confirm wiki dir unchanged after `/sara-agenda` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
