# Phase 3: Meeting Specialisation - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 delivers two Claude Code skills:

- `/sara-minutes N` — generates structured meeting minutes (markdown block + email-ready plain-text) output to screen only; nothing written to the wiki or committed
- `/sara-agenda` — generates a throw-away email-friendly agenda draft from a single freeform user prompt; nothing written to the wiki

No wiki entity creation, no git commits, no new wiki directories. Both commands are generators only.

**Revised requirement (MEET-01):** `/sara-minutes N` outputs markdown + email draft to screen. The original requirement stated "filed in the wiki" — this was explicitly revised during context discussion. The wiki is the data source for minutes, not the destination.

</domain>

<decisions>
## Implementation Decisions

### /sara-minutes — Stage Guard and Type Guard

- **D-01:** Stage guard: item N must be in `complete` stage (i.e. `/sara-update N` has been run successfully). Any earlier stage aborts with a plain-English error naming the current stage and instructing the user to run `/sara-update N` first.
- **D-02:** Type guard: item N must be a `MTG` type. Non-meeting types (EML, SLK, DOC) abort with a clear error that names the type and the correct command (e.g. "DOC-001 is a document item. `/sara-minutes` only works on meeting items (MTG-NNN)."). Type check comes first; stage check second.
- **D-03:** Guard order: type check → stage check → proceed.

### /sara-minutes — Source of Truth

- **D-04:** `/sara-minutes N` reads wiki artifacts, not just the raw transcript. It reads `extraction_plan` from `pipeline-state.json` to identify which entities were created or updated, then reads each of those wiki pages for their content. The raw transcript may also be read for attendee list and any context not captured in wiki entities.
- **D-05:** Minutes are structured around the wiki entities actually created/updated for item N — not a generic summary of the transcript.

### /sara-minutes — Output Structure

- **D-06:** Minutes markdown sections (derived from wiki artifacts for item N):
  - **Attendees** — names and roles (from STK pages where available, otherwise from transcript)
  - **Decisions** — each DEC-NNN created/updated, with explicit outcome statement: "DEC-003 (Payment gateway choice) — resolved: Stripe selected." Pull title and status from the wiki page.
  - **Actions** — each ACT-NNN created/updated, with owner and due-date from the wiki page.
  - **Risks** — each RISK-NNN created/updated, with status (flagged, mitigated, accepted) from the wiki page.
  - **Requirements** — each REQ-NNN created/updated, with title and status from the wiki page.
  - Sections with no artifacts are omitted (don't print an empty Risks section).
- **D-07:** Email-ready plain-text version is the same content as the markdown, with formatting stripped: headings become CAPS, bullets become dashes, bold removed. No separate summary — same structure.
- **D-08:** Both outputs appear in the same terminal response: markdown block first, then a separator, then the plain-text email block. User copies the one they need.

### /sara-agenda — Interaction Model

- **D-09:** `/sara-agenda` uses a single freeform plain-text prompt (wait for user message). Prompt text: ask the user to describe the meeting — who's attending, what topics, and what they want to achieve. No structured AskUserQuestion fields.
- **D-10:** `/sara-agenda` does NOT tie to pipeline-state or the stakeholder registry. It is stateless — no item lookup, no wiki reads required.

### /sara-agenda — Output Structure

- **D-11:** Output is plain-text only (no markdown). Sections: subject line suggestion, greeting, numbered agenda items (no time allocations), desired outcome statement, sign-off.
- **D-12:** Nothing is written to disk. No wiki file, no git commit. Output is displayed once and discarded.

### Claude's Discretion

- Exact wording of error messages for stage and type guards
- Whether the terminal output uses a visible separator (e.g. `---`) or a header (e.g. `## Email Version`) between markdown and plain-text blocks
- Whether `/sara-minutes` prints a summary line ("4 entities found: 1 DEC, 2 ACT, 1 RISK") before the minutes body

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Requirements
- `.planning/REQUIREMENTS.md` — Full v1 requirement list. Phase 3 covers: MEET-01 (revised: output-only), MEET-02

### Project Context
- `.planning/PROJECT.md` — Vision, command taxonomy (sara-minutes is "Process", sara-agenda is "Generate"), ingest pipeline overview, constraints

### Prior Phase Decisions
- `.planning/phases/01-foundation-schema/01-CONTEXT.md` — Locked decisions from Phase 1: pipeline-state.json structure (D-07, D-08), entity ID formats (D-06), skill pattern (SKILL.md), wiki/CLAUDE.md behavioral contract
- `.planning/phases/02-ingest-pipeline/02-CONTEXT.md` — Locked decisions from Phase 2: stage guard pattern (D-13), extraction_plan structure (D-09), pipeline item ID format (D-11, D-12)

### Existing Skills (read before implementing — follow established patterns)
- `.claude/skills/sara-update/SKILL.md` — Stage guard implementation pattern; how extraction_plan is read and wiki pages are accessed
- `.claude/skills/sara-ingest/SKILL.md` — Stage and type validation pattern; item lookup from pipeline-state.json
- `.claude/skills/sara-init/SKILL.md` — Plain-text freeform prompt pattern (wait for user message)

No external specs or ADRs — all requirements captured in REQUIREMENTS.md and decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/skills/sara-update/SKILL.md` — Stage guard + `pipeline-state.json` item lookup pattern. `/sara-minutes` will reuse the same item validation approach.
- `.claude/skills/sara-ingest/SKILL.md` — Item type parsing (MTG/EML/SLK/DOC prefix). `/sara-minutes` type guard uses same logic.
- `.claude/skills/sara-init/SKILL.md` — Plain-text freeform prompt loop. `/sara-agenda` uses the same "output text, wait for user reply" pattern.

### Established Patterns
- All skills are SKILL.md files in `.claude/skills/<skill-name>/` with YAML frontmatter (`name`, `description`, `argument-hint`, `allowed-tools`) and `<objective>` + `<process>` blocks.
- Stage guard is always Step 1 in process skills — check before any reads or writes.
- `pipeline-state.json` is the state store; entity wiki pages are the content store.
- `wiki/CLAUDE.md` auto-loads behavioral contract for any wiki-scoped skill — but `/sara-minutes` and `/sara-agenda` do NOT write to the wiki, so this contract is read-only context at most.

### Integration Points
- `/sara-minutes N` reads: `pipeline-state.json` (item lookup + extraction_plan) + individual wiki pages (the entities listed in extraction_plan) + optionally the raw transcript in `/raw/meetings/`.
- `/sara-agenda` has no integration points — pure generation from user input.

</code_context>

<specifics>
## Specific Ideas

- Minutes are intentionally post-update: the user's mental model is that minutes summarise what the wiki now reflects, not what was discussed. Minutes = "what the meeting did to the wiki."
- The entity-outcome framing (e.g. "DEC-003 — resolved: Stripe selected") was explicit: minutes should read like a record of decisions made, not a transcript of conversation.
- `/sara-agenda` output deliberately omits time allocations — user does not want them in the email template.
- The freeform prompt for `/sara-agenda` was chosen over structured field collection: lower friction for a throw-away command.

</specifics>

<deferred>
## Deferred Ideas

- **Status curation during ingest** — User noted that in a future version, `/sara-ingest` (or related commands) should curate entity statuses: e.g. when a meeting resolves a decision, the DEC-NNN page's status should be updated to "accepted" as part of that ingest. This was flagged as a v2 concern — not in scope for Phase 3.
- **Agenda linked to ingest item** — Already noted in PROJECT.md as v2: `/sara-agenda` could optionally create a pending meeting item in pipeline-state, linked when the transcript is later ingested. Out of scope for v1.

</deferred>

---

*Phase: 03-meeting-specialisation*
*Context gathered: 2026-04-27*
