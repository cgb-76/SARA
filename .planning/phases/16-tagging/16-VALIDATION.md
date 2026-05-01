---
phase: 16
slug: tagging
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (sara skills use human-in-the-loop acceptance criteria) |
| **Config file** | none — spec-based verification only |
| **Quick run command** | `grep -n "D-08\|Step 6\|tag curation" .claude/skills/sara-lint/SKILL.md` |
| **Full suite command** | Read `.claude/skills/sara-lint/SKILL.md` and verify all acceptance criteria below |
| **Estimated runtime** | ~10 seconds (grep) / ~2 minutes (full read) |

---

## Sampling Rate

- **After every task commit:** Run `grep -c "D-08" .claude/skills/sara-lint/SKILL.md` (should be >= 6)
- **After every plan wave:** Full read of sara-lint SKILL.md, verify Step 6 flow end-to-end
- **Before `/gsd-verify-work`:** All acceptance criteria must pass
- **Max feedback latency:** 10 seconds (grep checks)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | TAG-01 | — | Step 6 D-08 block present | grep | `grep "D-08\|tag curation\|Step 6" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-02 | 01 | 1 | TAG-02 | — | Vocabulary derivation described | grep | `grep "vocabulary derivation\|derived.*tag" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-03 | 01 | 1 | TAG-03 | — | AskUserQuestion vocabulary gate present | grep | `grep "Approve.*Edit.*Skip\|vocabulary.*user" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-04 | 01 | 1 | TAG-04 | — | Assignment fires only after approval | read | Manual review of Step 6 flow | ❌ Wave 0 | ⬜ pending |
| 16-01-05 | 01 | 1 | TAG-05 | T-16-01 | Kebab-case normalisation enforced | grep | `grep "kebab\|normalise\|lowercase" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-06 | 01 | 1 | TAG-06 | — | All four artifact dirs targeted | grep | `grep "wiki/requirements.*wiki/decisions.*wiki/actions.*wiki/risks" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-07 | 01 | 1 | TAG-07 | T-16-02 | Atomic commit with explicit file list | grep | `grep "fix.wiki.*tags via sara-lint D-08\|atomic.*tag" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-08 | 01 | 1 | TAG-08 | — | D-08 runs unconditionally (no opt-in guard) | read | Manual review — Step 6 has no invocation guard except empty-wiki check | ❌ Wave 0 | ⬜ pending |
| 16-01-09 | 01 | 1 | TAG-09 | — | Full replacement semantics documented | grep | `grep "replace.*existing tags\|full replacement\|replaces" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |
| 16-01-10 | 01 | 1 | TAG-10 | — | Empty-wiki guard present | grep | `grep "No artifact pages\|no.*pages.*skip\|empty wiki" .claude/skills/sara-lint/SKILL.md` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No test infrastructure exists for skill verification — all verification is spec-based grep checks above.

*These are documentation skills, not code with unit tests — the grep-based checks are the complete verification suite. No test files need to be created.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Assignment fires only after vocabulary approved | TAG-04 | Control flow check — grep cannot verify execution order | Read Step 6 in SKILL.md and confirm the assignment pass section appears after the AskUserQuestion / approval branch |
| D-08 runs unconditionally on every sara-lint invocation | TAG-08 | No conditional guard to grep for | Read Step 6 and confirm no `if --tags` or opt-in flag wraps the D-08 block |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
