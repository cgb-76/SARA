# Stack Research — SARA

**Project:** SARA — Solution Architecture Recall Assistant
**Researched:** 2026-04-27
**Overall confidence:** MEDIUM (no live web/docs access; based on PROJECT.md context + training knowledge through Aug 2025)

---

## Recommended Stack

| Component | Choice | Rationale | Confidence |
|-----------|--------|-----------|------------|
| Runtime | Claude Code custom slash commands (`.claude/commands/*.md`) | SARA is defined in PROJECT.md as a set of Claude Code skills — no alternative runtime | HIGH |
| Slash command format | Markdown files with `$ARGUMENTS` interpolation | Standard Claude Code custom command format; no external build step | HIGH |
| Persistent state | YAML frontmatter in a dedicated state file (`/raw/pipeline-state.yml`) | YAML is human-readable, git-diffable, trivially parseable by the LLM as plain text; no runtime dependency | HIGH |
| Wiki entity schema | YAML frontmatter + markdown body (one file per artifact) | Matches the llm-wiki pattern exactly; Karpathy's original uses this; LLM reads/writes natively | HIGH |
| Frontmatter format | YAML (not TOML, not JSON) | Human-readable, universally supported by static site tools, diff-friendly, well-known to LLMs | HIGH |
| Git workflow | Shell `git` via Claude Code's bash tool | Claude Code has native bash/shell access; no Git library needed — raw CLI is simplest and most reliable | HIGH |
| Full-text search (v1) | `index.md` catalog read into context | PROJECT.md explicitly defers embedding/`qmd`-based search to v2; at v1 scale, LLM reads the index directly | HIGH |
| Full-text search (v2) | `ripgrep` (`rg`) via bash | Fastest grep available; zero-dependency; available on all modern dev systems; far superior to `grep` for this use case | MEDIUM |
| Fuzzy file discovery (v2) | `fzf` via bash | Standard fuzzy-finder, excellent for interactive queries inside Claude Code terminal sessions | MEDIUM |
| Markdown formatting | Plain markdown (CommonMark subset) | Claude Code renders markdown natively; no processing library needed at runtime — LLM writes it directly | HIGH |
| Email draft format | Markdown-first, with explicit "paste this into your email client" UX | v1 is throw-away text output; no email library or SMTP needed | HIGH |
| Meeting minutes | Markdown file in `/wiki/` + plain-text email block in same response | Single LLM response; no templating engine needed | HIGH |
| Directory scaffolding | LLM writes files/dirs via bash tool at `/sara-init` time | No scaffolding library; Claude Code bash tool handles `mkdir -p` and `touch` | HIGH |
| Config file | `/sara-config.yml` at repo root | Stores project name, department list, vertical — read by every command | HIGH |

---

## Key Library Decisions

### No runtime library dependencies — this is the decisive architectural call

SARA's "stack" is intentionally library-free at runtime. The LLM itself is the processor. Every component that would normally require a library (markdown parsing, YAML parsing, git, search, templating) is handled by one of:

1. **The LLM reading plain text directly** — markdown and YAML are LLM-native formats.
2. **Bash tool calls** — `git`, `mkdir`, `cp`, `mv`, `rg` are invoked as shell commands, not wrapped in libraries.
3. **File system operations** — Claude Code's `Read` and `Write` tools handle all I/O.

This is not an accident or a shortcut — it is the core insight of the llm-wiki pattern. The wiki is code; the LLM is the interpreter.

---

### YAML frontmatter (not JSON Schema, not a database)

Each wiki artifact (Requirement, Decision, Action, Risk, Stakeholder) is a single markdown file with a YAML frontmatter block. Example for a Decision:

```yaml
---
id: DEC-001
title: One repo per project
status: accepted
date: 2026-04-27
stakeholders: [george-beatty]
tags: [architecture, multi-tenancy]
---
```

**Why YAML over JSON frontmatter:**
- Git diffs are more readable (no quotes on keys, no trailing commas)
- Standard across all static site generators (Jekyll, Hugo, Obsidian) — tooling compatibility for free
- LLMs are trained on vast YAML corpora — generation quality is high

**Why not a JSON/SQLite database:**
- Git cannot diff binary SQLite
- JSON files don't render in Obsidian / GitHub
- Adds a dependency and a migration concern
- The llm-wiki pattern explicitly avoids databases

---

### Pipeline state: `/raw/pipeline-state.yml`

Each ingest item needs to track: `id`, `source_type`, `original_filename`, `stage` (pending/discussed/extracted/updated), and any discussion context captured during `/sara-discuss`. A single YAML file is sufficient at personal-scale (one user, sequential processing):

```yaml
items:
  - id: 1
    type: meeting
    filename: transcript.md
    stage: discussed
    discussion_summary: "Focus on authentication decision and three action items for Alice"
  - id: 2
    type: email
    filename: vendor-thread.eml.md
    stage: pending
```

**Why not one state file per item:** Simpler to read the whole pipeline at a glance; no directory traversal needed; atomic updates are trivially git-committed.

**Why not CLAUDE.md for state:** CLAUDE.md is for project context injected at session start, not mutable runtime state. Mixing the two would corrupt the context window with stale data.

---

### Git: raw CLI via bash tool

```bash
git add wiki/decisions/DEC-001.md
git commit -m "feat(wiki): add DEC-001 — one repo per project"
```

No `nodegit`, `simple-git`, or `pygit2`. The bash tool in Claude Code can run `git` directly. This is simpler, more debuggable, and has zero dependency surface. The commit message format follows Conventional Commits (`feat(wiki):`, `chore(ingest):`) for clean history.

---

### Search: `index.md` in v1, `ripgrep` in v2

`/wiki/index.md` is an LLM-maintained catalog — one line per artifact with id, title, type, and status. At personal scale (dozens to low hundreds of artifacts), loading this into context is fast and sufficient for `/sara-query`.

When the wiki grows beyond ~200 artifacts, `rg --type md` with a targeted query pattern becomes the right move. `ripgrep` is already installed on virtually every developer machine, handles large file trees fast, and outputs plain text the LLM can process directly.

Explicitly deferred: embedding-based vector search (FAISS, Chroma, pgvector). The LLM-wiki pattern's central argument is that compiled wiki pages make RAG redundant. Do not add a vector store.

---

### Markdown link style: wiki-links (`[[Page Name]]`) vs standard (`[text](path)`)

Use **standard CommonMark links** (`[Decision: One repo per project](../decisions/DEC-001.md)`) not Obsidian-style wiki-links. Reason: CommonMark links render correctly on GitHub, are unambiguous for the LLM to generate, and do not require Obsidian or any wiki-link resolver. Wiki-links are an Obsidian-specific extension.

---

### Email draft format

`/sara-minutes N` produces two sections in its response:

1. `### Meeting Minutes` — a markdown file written to `/wiki/` (committed)
2. `### Email Draft` — a plain-text block formatted for copy-paste into any email client

The email block uses: subject line, salutation, paragraph body, bullet list of action items, closing. No HTML, no MJML, no markdown-to-HTML conversion. This is sufficient for v1.

---

## What NOT to Use

| Technology | Why Not |
|------------|---------|
| **RAG / vector search** (FAISS, Chroma, pgvector, LlamaIndex) | Antithetical to the llm-wiki pattern. Knowledge compiled into the wiki makes re-retrieval redundant at personal scale. Adds significant infra complexity. |
| **Obsidian wiki-links** (`[[Page]]`) | Non-standard; breaks on GitHub; requires Obsidian or a custom resolver. Use CommonMark links. |
| **SQLite / any database** | Not git-diffable; adds a binary artifact to the repo; breaks the "plain text all the way down" principle. |
| **TOML frontmatter** | Less universally supported than YAML; less LLM training data; fewer tool integrations. |
| **JSON frontmatter** | Verbose, noisy diffs, no comment support, harder to hand-edit. |
| **Templating engines** (Jinja2, Handlebars, Liquid) | The LLM generates structured output directly from instructions in the slash command. No templating engine adds value. |
| **Markdown-to-HTML converters** (unified, remark, marked) | SARA's output is markdown consumed by Claude Code or copy-pasted by a human. HTML conversion is not needed in v1. |
| **Node.js / Python runtime** | SARA is Claude Code skills, not a standalone application. Adding a language runtime creates an installation and dependency management burden with no benefit. |
| **gray-matter / front-matter npm packages** | The LLM reads YAML frontmatter as plain text. Parsing libraries are only needed if you're building a runtime that programmatically processes frontmatter — SARA isn't. |
| **CLAUDE.md for mutable state** | CLAUDE.md is session context, not a state store. Writing pipeline state into CLAUDE.md creates stale-data corruption risk. |
| **One state file per ingest item** | Adds directory traversal complexity; a single `pipeline-state.yml` is simpler and fully sufficient at personal scale. |
| **`qmd` / Quarto** | Overkill for a personal wiki; introduces a build system; v2 search is handled better by `ripgrep`. |
| **Email sending libraries** (Nodemailer, SendGrid) | v1 is copy-paste UX by explicit design. External integrations are out of scope. |

---

## Open Questions

| Question | Impact | Notes |
|----------|--------|-------|
| **Does Claude Code's bash tool persist cwd between tool calls within a single slash command?** | Medium — affects whether `git` commands need explicit `-C /path/to/repo` flags | Training data suggests cwd resets per invocation; safest to always use absolute paths in bash calls from slash commands |
| **What is the exact CLAUDE.md injection mechanism for project-level context?** | Medium — determines how much of `sara-config.yml` should be mirrored into CLAUDE.md vs read on demand | If CLAUDE.md auto-injects at session start, config could live there; if not, each command must explicitly read the config file |
| **Is there a maximum file size that Claude Code's Read tool will load cleanly?** | Low in v1, Medium in v2 — relevant when `index.md` grows large | At personal scale (< 500 artifacts) this is unlikely to be an issue, but worth monitoring |
| **Conventional Commits enforcement:** should `/sara-update` enforce a commit message format or leave it free-form? | Low | Conventional Commits gives clean history for free; the LLM can generate them consistently with a one-line instruction |
| **Cross-artifact linking strategy at init time:** should artifact IDs be globally unique (REQ-001, DEC-001) or namespaced by project (PROJ-REQ-001)? | Low in v1 (one-repo-per-project), Medium if repo sharing becomes a use case | Global unique IDs (REQ-001 etc.) are simpler and sufficient for single-project repos |
| **YAML vs TOML for `sara-config.yml`:** YAML chosen, but TOML is gaining ground in developer tooling (pyproject.toml, Cargo.toml) | Low | YAML is the right call here; more LLM training data, wider tool support |
