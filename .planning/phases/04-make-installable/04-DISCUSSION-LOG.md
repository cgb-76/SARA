# Phase 4: make-installable - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 04-make-installable
**Areas discussed:** Distribution mechanism, Install scope, Post-install UX, Update story

---

## Distribution mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Shell script | curl-friendly install.sh at repo root | ✓ |
| git clone + manual copy | README instructions, fully manual | |
| npm package | npx sara-install, adds tooling dependency | |

**User's choice:** Shell script

| Option | Description | Selected |
|--------|-------------|----------|
| In this repo | install.sh at repo root | ✓ |
| Separate installer repo | Dedicated repo for installer | |

**User's choice:** In this repo

| Option | Description | Selected |
|--------|-------------|----------|
| Require git repo | Guard: abort if no .git directory | ✓ |
| Work anywhere | Install regardless of git status | |

**User's choice:** Require git repo

---

## Install scope

| Option | Description | Selected |
|--------|-------------|----------|
| Everything in skills folder (sara-* glob) | Dynamic, no hardcoded list | ✓ |
| All 8 skills together (hardcoded) | Fixed list requiring maintenance | |
| Per-skill selection | Interactive picker | |

**User's choice:** Everything in `.claude/skills/sara-*/` — dynamic glob, not hardcoded list

**Notes:** User explicitly noted that hardcoding a list of 8 skills would require maintenance as future phases add more skills. Dynamic glob avoids this.

| Option | Description | Selected |
|--------|-------------|----------|
| Overwrite with --backup flag | Default: overwrite; --backup preserves old file | ✓ |
| Always back up | Always create .bak files | |
| Abort if exists, require --force | Safe but annoying on upgrades | |

**User's choice:** Overwrite with --backup flag

| Option | Description | Selected |
|--------|-------------|----------|
| Only sara-* prefixed | Filter to SARA skills only | ✓ |
| All of .claude/skills/ | Copy everything including non-SARA skills | |

**User's choice:** Only sara-* prefixed

---

## Post-install UX

| Option | Description | Selected |
|--------|-------------|----------|
| Skills installed, /sara-init still required | Clean separation: install = tools, init = config | ✓ |
| Installer also runs /sara-init | One-step but incompatible with interactive /sara-init | |

**User's choice:** Skills installed only; user runs /sara-init separately

| Option | Description | Selected |
|--------|-------------|----------|
| Skills list + next step command | Print installed skills + "run /sara-init" | ✓ |
| Minimal: just "Done" | Minimal output | |

**User's choice:** Skills list + next step command

---

## Update story

| Option | Description | Selected |
|--------|-------------|----------|
| Re-run the installer | Same command updates in place | ✓ |
| Separate update command | Explicit update.sh or --update flag | |
| No update support in v1 | Manual copy only | |

**User's choice:** Re-run install.sh to update

| Option | Description | Selected |
|--------|-------------|----------|
| No version check | Always overwrite | |
| Version check, warn if downgrading | Warn when source is older than installed | ✓ |

**User's choice:** Version check — warn if downgrading

| Option | Description | Selected |
|--------|-------------|----------|
| Add version field to SKILL.md frontmatter | Add 'version: 1.0.0' to each SKILL.md | ✓ |
| Use git tags from this repo | Requires network + tag discipline | |
| Use file modification timestamps | Unreliable after clone | |

**User's choice:** Add version field to SKILL.md frontmatter (initial value: 1.0.0)

---

## Claude's Discretion

- Exact version number format for initial release
- Whether install.sh creates .claude/skills/ if it doesn't exist
- README installation section wording
- Exact error/warning message copy

## Deferred Ideas

None — discussion stayed within phase scope.
