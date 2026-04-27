---
phase: 1
slug: foundation-schema
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — pure filesystem verification (bash + file existence checks) |
| **Config file** | none |
| **Quick run command** | `bash -c 'test -f .sara/config.json && test -f pipeline-state.json && echo OK'` |
| **Full suite command** | `bash -c 'test -d wiki && test -d raw && test -f .sara/config.json && test -f pipeline-state.json && test -f wiki/CLAUDE.md && test -f wiki/index.md && test -f wiki/log.md && ls .sara/templates/*.md | wc -l | grep -q 5 && echo ALL_OK'` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash -c 'test -f .sara/config.json && test -f pipeline-state.json && echo OK'`
- **After every plan wave:** Run full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | FOUND-01 | — | N/A | filesystem | `test -d wiki && test -d raw` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 1 | FOUND-02 | — | N/A | filesystem | `python3 -c "import json; c=json.load(open('.sara/config.json')); assert 'verticals' in c and 'departments' in c"` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 1 | FOUND-03 | — | N/A | filesystem | `grep -l 'schema_version' .sara/templates/*.md | wc -l | grep -q 5` | ❌ W0 | ⬜ pending |
| 1-01-04 | 01 | 1 | FOUND-04 | — | N/A | filesystem | `python3 -c "import json; s=json.load(open('pipeline-state.json')); assert 'counters' in s and 'items' in s"` | ❌ W0 | ⬜ pending |
| 1-01-05 | 01 | 1 | WIKI-01..07 | — | N/A | filesystem | `grep -q 'schema_version' .sara/templates/requirement.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None — this phase has no test framework to install. All verification is filesystem + JSON structure checks executable inline.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AskUserQuestion prompts appear correctly for verticals and departments | FOUND-02 | Interactive TUI cannot be driven by automated commands | Run `/sara-init` in an empty test directory; confirm two separate prompts appear, one for verticals and one for departments |
| Guard clause aborts on existing wiki/ | FOUND-01 | Requires a pre-seeded directory state | Create a directory with an existing `wiki/` folder, run `/sara-init`, confirm error message and no changes |
| wiki/CLAUDE.md is loaded by Claude Code in wiki subtree | WIKI-01..07 | Claude Code directory scoping is runtime behaviour | Open a new Claude Code session in the `wiki/` directory; verify CLAUDE.md schema definitions appear in context |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
