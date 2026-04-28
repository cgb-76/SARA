---
phase: 2
slug: ingest-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual inspection (skills are SKILL.md prose — no automated test runner) |
| **Config file** | none |
| **Quick run command** | Run target skill with a test fixture file in `raw/input/`; inspect outputs |
| **Full suite command** | Run full pipeline end-to-end: ingest → discuss → extract → update; inspect all outputs |
| **Estimated runtime** | ~10–20 minutes (manual end-to-end run with a test fixture transcript) |

---

## Sampling Rate

- **After every task commit:** Manual spot-check — inspect the file or state written in that task (e.g., `cat .sara/pipeline-state.json`, `ls wiki/stakeholders/`)
- **After every plan wave:** Run targeted pipeline stage(s) from that wave with a test fixture; verify state transitions
- **Before `/gsd-verify-work`:** Full end-to-end pipeline run must succeed: ingest → discuss → extract → update → single git commit containing all artifacts
- **Max feedback latency:** 20 minutes per wave

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-P1-T1 | Phase1-amend | 1 | D-08 | — | N/A | smoke | `grep -n "nickname" .sara/templates/stakeholder.md` | ❌ W0 | ⬜ pending |
| 02-P1-T2 | Phase1-amend | 1 | D-08 | — | N/A | smoke | `grep -n "nickname" CLAUDE.md` | ❌ W0 | ⬜ pending |
| 02-P2-T1 | sara-ingest | 1 | PIPE-01 | T-type-valid | Reject unknown type | smoke | `cat .sara/pipeline-state.json` — check `items["1"].stage = "pending"` | ❌ W0 | ⬜ pending |
| 02-P2-T2 | sara-ingest | 1 | PIPE-01 | T-path-traversal | Reject filename with `..` or `/` | smoke | Check pipeline-state.json unchanged after failed ingest | ❌ W0 | ⬜ pending |
| 02-P2-T3 | sara-ingest | 1 | PIPE-07 | — | N/A | smoke | Run `/sara-ingest`; verify table present in output | ❌ W0 | ⬜ pending |
| 02-P3-T1 | sara-add-stakeholder | 2 | PIPE-03 | — | N/A | smoke | `ls wiki/stakeholders/ \| grep STK-`; `git log --oneline -1` shows STK commit | ❌ W0 | ⬜ pending |
| 02-P4-T1 | sara-discuss | 2 | PIPE-02 | — | N/A | inspection | Read discuss output; check `discussion_notes` populated in pipeline-state.json | ❌ W0 | ⬜ pending |
| 02-P4-T2 | sara-discuss | 2 | PIPE-03 | — | N/A | smoke | Unknown name in source → STK page created mid-discuss; discussion continues | ❌ W0 | ⬜ pending |
| 02-P5-T1 | sara-extract | 3 | PIPE-04 | — | N/A | inspection | Read extract output; verify source quotes present for each artifact | ❌ W0 | ⬜ pending |
| 02-P5-T2 | sara-extract | 3 | PIPE-04 | — | N/A | smoke | `cat .sara/pipeline-state.json` — check `extraction_plan` populated after approval | ❌ W0 | ⬜ pending |
| 02-P5-T3 | sara-extract | 3 | PIPE-06 | — | N/A | inspection | Run against source with topic matching existing wiki page; check plan `action = "update"` | ❌ W0 | ⬜ pending |
| 02-P6-T1 | sara-update | 4 | PIPE-05 | — | N/A | smoke | `git log --oneline -1` + `git show --stat HEAD` — all wiki pages in one commit | ❌ W0 | ⬜ pending |
| 02-P6-T2 | sara-update | 4 | PIPE-05 | — | N/A | smoke | `ls raw/meetings/` — source file exists with numeric prefix | ❌ W0 | ⬜ pending |
| 02-P6-T3 | sara-update | 4 | PIPE-05 | — | N/A | smoke | `cat .sara/pipeline-state.json` — stage = "complete" only after commit | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No automated test runner to install — all verification is manual inspection and pipeline execution
- Planner must include a Wave 0 task: "Create a test fixture transcript (`raw/input/test-fixture.md`) with known content — at least two stakeholder names (one existing, one new), one requirement, one decision, and a topic matching an existing wiki page for dedup testing"
- The fixture provides a stable, repeatable input for all smoke tests above

*Existing infrastructure covers no automated test requirements — all phase behaviors require manual pipeline execution.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `/sara-discuss` surfaces cross-link opportunities | PIPE-02 | LLM-generated output; no programmatic assert | Read discuss output; verify at least one existing wiki artifact is referenced by ID |
| Per-artifact discuss loop revises and re-presents artifact | PIPE-04 | Interactive TUI loop; no automated replay | During extract, choose "Discuss" on one artifact; verify revised version is re-presented |
| Stage guard aborts with plain-English error | D-13 | Requires running skill in wrong state | Run `/sara-discuss 1` when item is in `extracting` stage; verify error message names current stage and correct next command |
| Partial-failure report in `/sara-update` | D-14 | Hard to simulate programmatically | Intentionally interrupt a write mid-update (manual test); verify report lists which files were/were not written |

---

## Validation Sign-Off

- [ ] All tasks have manual spot-check or Wave 0 fixture dependency
- [ ] Sampling continuity: no 3 consecutive tasks without a manual checkpoint
- [ ] Wave 0 test fixture created before any pipeline skill is executed
- [ ] No watch-mode flags (none applicable — no test runner)
- [ ] Feedback latency < 20 minutes per wave
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
