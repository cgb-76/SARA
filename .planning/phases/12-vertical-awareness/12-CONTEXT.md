# Phase 12: vertical-awareness - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Two tracks:

1. **Rename** — Rename the concept `vertical` to `segment` everywhere in the SARA skills and agent files. This is a find-and-replace across all SKILL.md files and sara-artifact-sorter.md: field names, variable names, prompt text, constraint notes, config.json keys, and schema block documentation. Scope is skills only — no migration of existing initialised wikis or their wiki pages.

2. **Segment tagging** — Add a `segments: []` array field to all four artifact types (REQ, DEC, ACT, RSK). The sara-extract extraction passes infer the segment(s) for each artifact: first preference is the segment of the stakeholder attributed in the source quote; fallback is keyword matching against the project's configured segments list; if neither resolves, the field is left as `[]`. sara-update writes the `segments` array to the wiki page frontmatter for all four artifact types. sara-init is updated to include `segments: []` in all four entity templates and schema blocks.

No changes to: the sorter agent logic, per-artifact approval loop mechanics, sara-discuss pipeline behaviour, pipeline-state.json structure.

</domain>

<decisions>
## Implementation Decisions

### Track 1 — Rename vertical → segment

- **D-01:** All occurrences of `vertical` (field names, variable names, config keys, prompt text, constraint notes, summary rules) in SKILL.md files and sara-artifact-sorter.md are renamed to `segment`. This includes:
  - `.sara/config.json` key: `verticals` → `segments`
  - STK page frontmatter field: `vertical:` → `segment:`
  - sara-add-stakeholder question prompt: "Which market vertical?" → renamed to reflect "segment"
  - sara-init Step 3 prompt: "Provide all market verticals that apply?" → **"What segments or customer groups does this project cover?"**
  - sara-add-stakeholder constraint note: `vertical` and `department` always separate fields → update field name only
  - sara-update summary rule for STK: `STK: vertical, department, role` → `STK: segment, department, role`
  - sara-lint summary rule for STK: same update

- **D-02:** sara-add-stakeholder also updates its config auto-extend logic: reads `config.segments` (was `config.verticals`) and appends new segment values if not already present.

- **D-03:** No migration step. Existing initialised wikis keep `vertical:` in their STK pages and `verticals` in their config.json. sara-lint does not get a new check for the old field name.

### Track 2 — Segment tagging on artifacts

- **D-04:** All four extraction passes in sara-extract Step 3 (requirements, decisions, actions, risks) gain a `segments` field on their artifact JSON output. Type: array of strings (zero or more segment names from the project's configured segments list).

- **D-05:** Inference priority for `segments`:
  1. **STK attribution** — If the artifact's source quote is attributed to a stakeholder (e.g. `— [[STK-001|Alice Smith]]`), read that STK page's `segment:` field and use it as the first entry.
  2. **Context clue matching** — Scan the source passage for keywords that match any configured segment name (case-insensitive substring match against `config.segments`). Add matching segment names.
  3. **Empty fallback** — If neither resolves, `segments: []`.
  - Deduplication: each segment name appears at most once in the array.

- **D-06:** The configured segments list is read from `.sara/config.json` → `segments` array. The extraction pass must read this file before running the four passes (it already reads pipeline-state.json; config.json is read the same way).

- **D-07:** `segments` is **not** shown in the Step 4 approval loop preview beyond being part of the artifact JSON. No approval-loop warning for empty segments.

- **D-08:** sara-update writes `segments:` to the wiki page frontmatter for all four artifact types in both create and update branches. The field is a YAML list, e.g. `segments: [Residential, Enterprise]` or `segments: []`.

- **D-09:** sara-init adds `segments: []` to all four entity templates (requirement.md, decision.md, action.md, risk.md) and updates the corresponding schema blocks in CLAUDE.md.

- **D-10:** sara-artifact-sorter passes `segments` through unchanged — same pattern as `req_type`, `priority`, `act_type`, `risk_type`, `owner`, `likelihood`, `impact` in Phases 8–11.

### Claude's Discretion

- Exact wording of the sara-extract inference prompt for segment detection — must describe both the STK-attribution lookup and the keyword-matching fallback
- Whether to read config.json once at skill entry or inline before Step 3 (either is acceptable; inline is simpler for the extraction passes)
- YAML serialisation of `segments: []` vs `segments: [Residential]` — use block style only if the array has 3+ entries; flow style otherwise (consistent with `related`, `tags`, `source` in existing templates)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skills being modified (Track 1 — rename)
- `.claude/skills/sara-init/SKILL.md` — config.json template (verticals → segments), Step 3 prompt, STK schema block, STK template
- `.claude/skills/sara-add-stakeholder/SKILL.md` — question prompt, variable name, config read/write, STK page template, constraint note
- `.claude/skills/sara-update/SKILL.md` — STK summary rule, constraint note
- `.claude/skills/sara-lint/SKILL.md` — STK summary rule, constraint note

### Skills being modified (Track 2 — segment tagging)
- `.claude/skills/sara-extract/SKILL.md` — All four extraction passes in Step 3 gain `segments` field; config.json read added
- `.claude/skills/sara-update/SKILL.md` — All four entity create + update branches write `segments:` to frontmatter
- `.claude/skills/sara-init/SKILL.md` — All four entity templates + CLAUDE.md schema blocks gain `segments: []`

### Agent files (compatibility — do not break sorter contract)
- `.claude/agents/sara-artifact-sorter.md` — Rename `vertical` → `segment` in STK summary rule; verify `segments` new field passes through unchanged

### Prior phase context (pattern references)
- `.planning/phases/08-refine-requirements/08-CONTEXT.md` — Two-track pattern: extraction refinement + schema v2.0 update
- `.planning/phases/10-refine-actions/10-CONTEXT.md` — Array field example (`source: []`, `tags: []`, `related: []`); owner field distinction pattern
- `.planning/phases/11-refine-risks/11-CONTEXT.md` — Most recent refinement; confirms sorter passes extra fields through unchanged

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- sara-extract Step 3: four inline passes each produce a typed artifact array; adding `segments` is a targeted prompt + schema extension per pass, surrounding structure unchanged
- sara-update entity write branches: targeted frontmatter field addition; body structure unchanged
- sara-artifact-sorter: no logic change needed — extra fields pass through by design (validated pattern from Phases 8–11)

### Established Patterns
- Array fields in YAML frontmatter use flow style for 0–2 entries (`segments: []`, `segments: [Residential]`) and block style for 3+ — consistent with `tags`, `related`, `source`
- `schema_version: '2.0'` single-quote convention — all artifact types already at v2.0 after Phases 8–11; this phase does not bump schema_version again (segments is an additive field, not a breaking change)
- config.json is already read by sara-add-stakeholder via the Read tool; same pattern applies to sara-extract reading config.segments

### Integration Points
- `.sara/config.json` `segments` key: read by sara-extract (new), sara-add-stakeholder (existing, renamed), sara-init (template write, renamed)
- STK page `segment:` field: read by sara-extract for STK-attribution inference
- All four entity wiki pages: gain `segments:` frontmatter field written by sara-update

</code_context>

<specifics>
## Specific Ideas

- The inference rule "prefer the segment of the source-quote stakeholder" maps naturally to the existing quote attribution format `— [[STK-NNN|Name]]` — the extraction pass can parse the STK-NNN ID from this pattern and look up the STK page's `segment:` field
- `segments` is intentionally an array (not a single string) because one artifact can be cross-segment — e.g. a compliance risk affecting both Residential and Wholesale simultaneously
- The rename is a pure find-and-replace; no logic changes accompany it in Track 1

</specifics>

<deferred>
## Deferred Ideas

- sara-lint migration check: add a lint rule that flags STK pages still using the old `vertical:` field name — deferred, user chose skills-only scope
- Index grouping by segment: add a segment-grouped view to wiki/index.md — not scoped here
- Segment filtering command (e.g. show all open risks for Residential) — future phase

</deferred>

---

*Phase: 12-vertical-awareness*
*Context gathered: 2026-04-30*
