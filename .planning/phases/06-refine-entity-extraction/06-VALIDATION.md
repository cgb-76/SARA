---
phase: 6
slug: refine-entity-extraction
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-28
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — pure markdown/SKILL.md project |
| **Config file** | none |
| **Quick run command** | `ls .claude/agents/ && grep -c "^---" .claude/agents/*.md` |
| **Full suite command** | End-to-end `/sara-extract` pipeline run against a sample source file |
| **Estimated runtime** | ~5 minutes (manual pipeline run) |

---

## Sampling Rate

- **After every task commit:** Check agent file exists and has valid frontmatter
- **After every plan wave:** Inspect `sara-extract` SKILL.md diff for Step 2–3 replacement correctness
- **Before `/gsd-verify-work`:** Full end-to-end `/sara-ingest` → `/sara-discuss` → `/sara-extract` pipeline run completes without errors
- **Max feedback latency:** Manual inspection per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | — | — | N/A | manual | `ls .claude/agents/sara-requirement-extractor.md` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | — | — | N/A | manual | `ls .claude/agents/sara-decision-extractor.md` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | — | — | N/A | manual | `ls .claude/agents/sara-action-extractor.md` | ❌ W0 | ⬜ pending |
| 06-01-04 | 01 | 1 | — | — | N/A | manual | `ls .claude/agents/sara-risk-extractor.md` | ❌ W0 | ⬜ pending |
| 06-01-05 | 01 | 1 | — | — | N/A | manual | `ls .claude/agents/sara-artifact-sorter.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None — no test framework to install. All verification is file-existence + manual pipeline execution.

*Existing infrastructure covers all phase requirements (manual end-to-end validation consistent with prior phases).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Specialist agents extract correct artifact types | D-01–D-06 | No automated test framework | Run `/sara-extract` on sample source; verify each agent returns only its own type |
| Sorter deduplicates and asks targeted questions | D-07–D-09 | Requires human interaction | Run `/sara-extract`; verify sorter presents ambiguity questions before approval loop |
| Approval loop unchanged | D-10 | Integration behavior | Confirm AskUserQuestion Accept/Reject/Discuss loop fires after sorter resolves |
| `sara-discuss` no longer classifies | D-11 | Scope change, not code change | Run `/sara-discuss`; verify classification/dedup language absent from output |
| `install.sh` includes agent files | research finding | Script audit | `grep -n "agents" install.sh` shows coverage |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < manual-inspection-per-task
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
