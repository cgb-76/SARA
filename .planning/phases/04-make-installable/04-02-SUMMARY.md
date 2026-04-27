---
phase: 04-make-installable
plan: "02"
subsystem: installer
tags: [install-script, distribution, versioning, bash]
dependency_graph:
  requires: [skill-version-fields]
  provides: [install-sh]
  affects: []
tech_stack:
  added: []
  patterns: [bash-installer, semver-sort-V, find-glob]
key_files:
  created:
    - install.sh
  modified: []
decisions:
  - install.sh uses `find -name 'sara-*'` glob (not hardcoded list) to stay maintenance-free as new skills are added
  - `sort -V` via `printf | sort -V | head -1` used for semver comparison — portable across bash versions with GNU sort
  - TARGET_DIR defaults to $PWD but --target allows running the script from any location (e.g. after cloning the repo)
  - --force flag overrides downgrade protection to handle edge cases
metrics:
  duration: "~2 minutes"
  completed: "2026-04-27T21:38:56Z"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 1
---

# Phase 04 Plan 02: Write install.sh — Summary

**One-liner:** Single-command bash installer copies all sara-* skills into a target git project with git-repo guard, semver downgrade protection, --backup, and --force flags.

## What Was Built

`install.sh` at the repo root — a 131-line bash script that implements the full SARA installer as defined in decisions D-03 through D-10 from CONTEXT.md.

**Key behaviours:**

- Parses `--target <dir>`, `--backup`, `--force`, `--help` flags with `set -euo pipefail`
- Guards: aborts with a plain-English error if TARGET_DIR contains no `.git` directory
- Discovers all `sara-*` directories dynamically via `find` glob — no hardcoded skills list
- For each skill: extracts source `version` from SKILL.md, compares against installed version using `sort -V`; warns and skips if source is older (downgrade); `--force` overrides
- If `--backup`, copies existing `SKILL.md` to `SKILL.md.bak` before overwriting
- Copies skill directory contents via `cp -r`
- Post-install: prints "Installed skills:" with one name per line, then "Next: open Claude Code in this directory and run /sara-init"

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write install.sh | f98fe22 | install.sh |
| 2 | Smoke-test install.sh | (no files changed) | — |

## Verification

All acceptance criteria passed:

```
bash -n install.sh               → syntax OK
test -x install.sh               → executable
grep "set -euo pipefail"         → match
grep "sara-\*"                   → match
grep "sort -V"                   → match
grep "SKILL.md.bak"              → match
grep "sara-init"                 → match
./install.sh --help              → exit 0, usage to stdout
./install.sh --target /tmp       → exit 1, "Error: ... git repository" on stderr
```

Smoke test results:

| Test | Scenario | Result |
|------|----------|--------|
| 1 | Normal install to temp .git dir | 8 skills installed, "Installed skills:" printed, "/sara-init" next step printed |
| 2 | No-git guard: target has no .git | exit 1, "Error: install.sh must be run inside a git repository" |
| 3 | --backup: second install creates .bak | SKILL.md.bak present in all skill dirs after second run |
| 4 | Downgrade protection + --force | Warning printed + skill skipped without --force; skill overwritten with --force |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All logic is fully implemented and smoke-tested.

## Threat Flags

None. Threat model items T-04-03 through T-04-07 are all addressed:
- T-04-03 (tampering via --target): TARGET_DIR used via literal path only; no eval; no user-input concatenation in shell expansions beyond the validated directory
- T-04-06 (overwrite of customised SKILL.md): --backup flag implemented; downgrade warning implemented
- T-04-07 (writes to unintended path): .git check fires before any `mkdir -p` or `cp`

## Self-Check: PASSED

- `install.sh` exists and is executable
- Commit f98fe22 exists: `git log --oneline | grep f98fe22`
- All 4 smoke test scenarios verified in this session
- No unexpected file deletions (git diff --diff-filter=D confirmed clean)
