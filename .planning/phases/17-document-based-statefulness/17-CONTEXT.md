# Phase 17: document-based-statefulness - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Refactor SARA's pipeline tracking from a monolithic `.sara/pipeline-state.json` to a directory-per-item structure at `.sara/pipeline/{ID}/`. Each pipeline item becomes a folder with three markdown files that grow as the item progresses through stages. Counter values are derived from the filesystem at runtime rather than stored in JSON.

This change does NOT affect the wiki directory, entity schemas, or any SARA command's external behaviour — it is an internal state representation change only. All commands continue to accept the same arguments and produce the same outputs.

**Out of scope:** Migration of existing `pipeline-state.json` data (new repos only). Changes to wiki structure, entity types, or lint checks.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Directory structure: one folder per pipeline item

`sara-ingest` creates `.sara/pipeline/{ID}/` for every new item. Example: `.sara/pipeline/MTG-001/`, `.sara/pipeline/EML-002/`.

The `.sara/pipeline/` directory replaces `.sara/pipeline-state.json` as the pipeline store. `sara-init` creates the directory; it does NOT create `pipeline-state.json`.

### D-02 — Three files per item directory

Each item directory holds exactly three files, written progressively as the item advances:

| File | Written by | Contains |
|------|-----------|----------|
| `state.md` | `sara-ingest` | YAML frontmatter: id, type, filename, source_path, stage, created |
| `discuss.md` | `sara-discuss` | Markdown body: resolved blockers, stakeholder resolutions, discussion context |
| `plan.md` | `sara-extract` | Markdown body: proposed artifacts to create/update (human-readable, LLM-parsed) |

`state.md` frontmatter tracks the current stage field through its lifecycle:
`pending` → `extracting` → `approved` → `complete`

Stage advances are written to `state.md` by each command (same ordering constraint as the old JSON write: stage only advances AFTER the git commit succeeds).

### D-03 — Counters derived from filesystem at runtime

No counter file. Commands that need the next ID derive it by:
- **Ingest counters (MTG, EML, SLK, DOC):** `ls .sara/pipeline/ | grep "^{TYPE_KEY}-" | sort | tail -1` — parse the numeric suffix from the last directory name, increment by 1.
- **Entity counters (REQ, DEC, ACT, RSK, STK):** `ls wiki/{type_dir}/ | sort | tail -1` — parse the numeric suffix from the last wiki page filename, increment by 1.

If no directories exist yet, start at 001.

### D-04 — Extraction plan: markdown body in plan.md

`sara-extract` writes the approved plan as a human-readable markdown body in `plan.md`. No YAML frontmatter in plan.md — the markdown body is the artifact list. `sara-update` reads `plan.md` via the Read tool and uses LLM parsing to execute the plan (same way it currently reads the human-approved artifact list from sara-extract's approval flow).

`plan.md` describes each proposed artifact in enough detail for `sara-update` to act: entity type, action (create/update), title, field values. The markdown format is Claude-native — no additional structured format needed.

### D-05 — Migration: new repos only

`sara-init` creates `.sara/pipeline/` (no `pipeline-state.json`). Existing repos with a `pipeline-state.json` are not automatically migrated — this phase documents the new schema in CLAUDE.md. Existing users would need to re-ingest pending items or manually create item directories from their JSON data.

MEET-01 (assigned_id not persisted in pipeline-state.json) is naturally rendered moot: `plan.md`'s markdown body describes the entities to create with their proposed IDs; `sara-minutes` reads `plan.md` directly to find the entity IDs, so no write-back is needed.

### D-06 — STATUS mode: glob .sara/pipeline/*/state.md

`sara-ingest` with no arguments (STATUS mode) now globs `.sara/pipeline/*/state.md`, reads frontmatter from each, and renders the same table as before (ID, type, stage, source path). Empty pipeline directory = same "no items" message.

### Claude's Discretion

- Exact markdown structure for plan.md — how each artifact entry is formatted (table vs bullet list vs headed sections). Pick whatever is most reliably parseable by sara-update.
- Exact markdown structure for discuss.md — how stakeholder resolutions and comprehension blockers are presented. Consistent with existing sara-discuss output prose.
- Whether state.md has a minimal markdown body below the frontmatter (e.g. a `# {ID}` heading) or is frontmatter-only.
- Whether `.sara/pipeline-state.json` is explicitly deleted by sara-init or simply not created (preferred: not created — clean start).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills to modify (all 6 pipeline commands)
- `.claude/skills/sara-init/SKILL.md` — Remove pipeline-state.json creation (Step 7); create `.sara/pipeline/` directory instead
- `.claude/skills/sara-ingest/SKILL.md` — Create item directory + state.md; STATUS mode reads .sara/pipeline/*/state.md; derive next ID from filesystem
- `.claude/skills/sara-discuss/SKILL.md` — Read state.md (not pipeline-state.json); write discuss.md; update stage in state.md
- `.claude/skills/sara-extract/SKILL.md` — Read state.md + discuss.md; write plan.md; update stage in state.md
- `.claude/skills/sara-update/SKILL.md` — Read plan.md (markdown body); update stage in state.md to complete after commit
- `.claude/skills/sara-minutes/SKILL.md` — Read state.md (source_path) + plan.md (entity IDs) instead of pipeline-state.json

### Reference pattern
- `.ideation/get-shit-done/` — GSD codebase, reference for document-based state pattern. Directory-per-phase at `.planning/phases/NN-name/` with multiple files inside mirrors the `.sara/pipeline/{ID}/` pattern.

### Prior phase that first established this pattern concern
- `.planning/phases/2-ingest-pipeline/` — Original pipeline state design (pipeline-state.json). Understanding the original rationale helps avoid re-introducing the same constraints in document form.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Stage guard pattern in every command: check state.md frontmatter `stage:` field instead of `items["{N}"].stage` in JSON — same logic, different read mechanism.
- ID parsing: all commands already construct IDs like `MTG-001` — the new filesystem-based counter derivation uses the same `{TYPE_KEY}-{NNN}` format.
- Read tool + Write tool pattern: already used for all wiki files; state.md/discuss.md/plan.md use the same tools (no Bash text-processing).

### Established Patterns
- Atomic commits: stage advance in state.md is committed ONLY after the wiki write commit succeeds (preserves the ordering guarantee from the old pipeline-state.json pattern).
- Read + Write tools only for markdown files — no Bash text-processing on markdown.
- `stage=complete` written only after git commit — critical invariant, must be preserved in state.md writes.

### Integration Points
- `sara-lint` is not affected — it reads wiki pages only, not pipeline state.
- `sara-add-stakeholder` is not affected — it creates STK pages and updates known_names, no pipeline state.
- `sara-agenda` is not affected — stateless by design (D-10).
- `wiki/index.md`, `wiki/log.md` — not affected.
- CLAUDE.md in any SARA project — will need a brief note about the new pipeline directory structure (added by sara-init's CLAUDE.md generation step).

</code_context>

<specifics>
## Specific Ideas

- The `.sara/pipeline/{ID}/` pattern is explicitly modelled on GSD's `.planning/phases/NN-name/` directories — see `.ideation/get-shit-done/` for reference. The researcher should read how GSD structures its phase directories as an implementation guide.
- `plan.md` is Claude-native markdown — it doesn't need a strict schema because sara-update is an LLM that reads the document the same way a human would. Prioritise readability over parseability.
- MEET-01 (deferred bug) becomes irrelevant: since plan.md's markdown body names the entity IDs directly and no JSON write-back is needed, the bug naturally disappears. Document this in CLAUDE.md or a SUMMARY note.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 17-document-based-statefulness*
*Context gathered: 2026-05-01*
