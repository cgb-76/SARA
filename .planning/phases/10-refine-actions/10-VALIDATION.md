---
phase: 10
slug: refine-actions
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual / diff review (skill files are markdown — no test runner) |
| **Config file** | none |
| **Quick run command** | `grep -n "act_type\|owner\|due_date\|due-date\|schema_version" .claude/skills/sara-extract/SKILL.md .claude/skills/sara-update/SKILL.md .claude/skills/sara-init/SKILL.md` |
| **Full suite command** | `grep -rn "act_type\|owner\|due_date\|due-date\|schema_version\|2\.0" .claude/skills/sara-*/SKILL.md .claude/agents/sara-artifact-sorter.md` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `grep -n "act_type\|owner\|due_date\|due-date\|schema_version" .claude/skills/sara-extract/SKILL.md .claude/skills/sara-update/SKILL.md .claude/skills/sara-init/SKILL.md`
- **After every plan wave:** Run `grep -rn "act_type\|owner\|due_date\|due-date\|schema_version\|2\.0" .claude/skills/sara-*/SKILL.md .claude/agents/sara-artifact-sorter.md`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | — | — | N/A | manual | `grep -n "act_type\|owner\|due_date" .claude/skills/sara-extract/SKILL.md` | ✅ | ⬜ pending |
| 10-02-01 | 02 | 1 | — | — | N/A | manual | `grep -n "act_type\|owner\|due-date\|schema_version\|2\.0" .claude/skills/sara-init/SKILL.md` | ✅ | ⬜ pending |
| 10-03-01 | 03 | 1 | — | — | N/A | manual | `grep -n "act_type\|owner\|due-date\|schema_version" .claude/skills/sara-update/SKILL.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. Skill files are markdown — no test framework installation required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Extraction prompt produces correct act_type, owner, due_date fields | D-01–D-05 | Skill files are LLM prompts — no unit test runner | Read modified sara-extract SKILL.md; verify prompt text and artifact schema section |
| sara-update writes v2.0 frontmatter with correct field order and quoting | D-06–D-10 | Template/prompt code in markdown | Read sara-update SKILL.md action write branch; grep for `schema_version: '2.0'` with single quotes |
| sara-init generates v2.0 action schema block and template | D-07–D-10 | Init writes CLAUDE.md and templates | Read sara-init SKILL.md; verify action schema block matches v2.0 frontmatter shape |
| Owner warning appears in approval loop for unresolved owners | D-13 | Approval loop logic in sara-update SKILL.md | Read sara-update SKILL.md Step 4 approval loop; verify warning text present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
