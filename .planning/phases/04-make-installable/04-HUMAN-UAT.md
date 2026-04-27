---
status: partial
phase: 04-make-installable
source: [04-VERIFICATION.md]
started: 2026-04-28T00:00:00Z
updated: 2026-04-28T00:00:00Z
---

## Current Test

Live curl-pipe install into a real project directory

## Tests

### 1. Full curl-pipe install — all 8 skills land
expected: 8 sara-* directories under .claude/skills/, each with a populated SKILL.md; output contains "Installed skills:" with all 8 names and "Next: open Claude Code in this directory and run /sara-init"
result: [pending — requires GitHub push first so raw.githubusercontent.com serves the updated files]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

Note: This test requires `git push` to cgb-76/SARA so the updated SKILL.md files (with version: 1.0.0) and the redesigned install.sh are served from raw.githubusercontent.com.

Run from inside any git-initialised project:
```bash
git init  # if not already a git repo
curl -fsSL https://raw.githubusercontent.com/cgb-76/SARA/main/install.sh | bash
```
