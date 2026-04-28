# Phase 4: make-installable - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Package and distribute SARA's skills so any user can install them into their own Claude Code project with a single command. The deliverable is `install.sh` at the repo root, plus a `version` field added to all existing SKILL.md frontmatter files. No new SARA commands are added. No wiki structure changes. Distribution mechanism only.

</domain>

<decisions>
## Implementation Decisions

### Distribution mechanism
- **D-01:** Distribution is a shell script (`install.sh`) at the repo root. Users run it directly (e.g. via GitHub raw URL or after cloning).
- **D-02:** The script lives in this repo alongside the skills — no separate installer repo.
- **D-03:** Installer guard: script must be run inside a git repo (checks for `.git` directory). If not in a git repo, abort with a plain-English error — SARA pipeline commands depend on git commits and a partial install without git is misleading.

### Install scope
- **D-04:** The installer copies all `sara-*` prefixed directories from `.claude/skills/` dynamically — it does not enumerate a hardcoded list of skills. New skills added in future phases are automatically included without script changes.
- **D-05:** Overwrite behaviour: default is to overwrite existing installed skills silently. A `--backup` flag copies the installed SKILL.md to SKILL.md.bak before overwriting (useful when the user has customised their local copy).

### Post-install UX
- **D-06:** The installer copies skill files only. After install, the user still runs `/sara-init` in Claude Code to set up the wiki structure and configure verticals/departments. Clean separation: install = get the tools; `/sara-init` = configure for this project.
- **D-07:** After a successful install, the script prints: the list of installed skill names (one per line) and a next-step line: "Next: open Claude Code in this directory and run /sara-init"

### Version tracking
- **D-08:** Add a `version` field to the YAML frontmatter of all existing SKILL.md files as part of this phase. Initial value: `1.0.0`. This is the version check source of truth.
- **D-09:** On install, the script compares the `version` field of the source SKILL.md (from this repo) against the installed SKILL.md (in the user's project) for each skill. If the source version is older (downgrade), print a warning per affected skill: "Warning: source version (X) is older than installed version (Y) for sara-FOO — skipping unless --force is passed."
- **D-10:** Updates are handled by re-running `install.sh`. No separate update command or mechanism.

### Claude's Discretion
- Exact version number format for initial release (semver `1.0.0` is implied by D-08 but exact patch policy is open)
- Whether `install.sh` creates `.claude/skills/` if it doesn't exist in the target project
- README installation section wording
- Exact error/warning message copy beyond what's specified above

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing skills (version field must be added to each)
- `.claude/skills/sara-init/SKILL.md` — Existing frontmatter structure; add `version: 1.0.0`
- `.claude/skills/sara-ingest/SKILL.md` — Same
- `.claude/skills/sara-discuss/SKILL.md` — Same
- `.claude/skills/sara-extract/SKILL.md` — Same
- `.claude/skills/sara-update/SKILL.md` — Same
- `.claude/skills/sara-add-stakeholder/SKILL.md` — Same
- `.claude/skills/sara-minutes/SKILL.md` — Same
- `.claude/skills/sara-agenda/SKILL.md` — Same

### Project context
- `.planning/PROJECT.md` — Constraints section: SARA is Claude Code skills only; git-backed by design; single-user per repo
- `.planning/REQUIREMENTS.md` — No v1 requirements cover distribution; this phase adds the install mechanism outside the numbered requirement set

No external specs or ADRs — all decisions captured above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- All 8 SKILL.md files in `.claude/skills/sara-*/` — the files to be distributed. Each has YAML frontmatter with `name`, `description`, `argument-hint`, `allowed-tools`.

### Established Patterns
- SKILL.md frontmatter already uses YAML — adding a `version` field is consistent with the existing schema pattern.
- `schema_version: '1.0'` is already used in wiki entity templates (quoted as string to prevent Obsidian float parse). The skill `version` field is different — it tracks installer version, not schema version — and can use plain semver without quoting issues.

### Integration Points
- `install.sh` reads from: this repo's `.claude/skills/sara-*/SKILL.md`
- `install.sh` writes to: the target project's `.claude/skills/sara-*/SKILL.md`
- No integration with `pipeline-state.json`, wiki, or any SARA runtime files

</code_context>

<specifics>
## Specific Ideas

- The installer should be dynamic (glob `sara-*`), not maintain a hardcoded skills list — this was explicitly requested to avoid script maintenance burden as new skills are added.
- Version check protects users who have customised their local SKILL.md files — downgrade warning gives them a chance to review before overwriting.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-make-installable*
*Context gathered: 2026-04-28*
