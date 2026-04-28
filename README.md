# SARA — Solution Architecture Recall Assistant

SARA is a personal, git-backed knowledge pipeline for solution design, operated entirely through Claude Code slash commands. Every meeting, email thread, and document gets permanently integrated into a structured wiki — knowledge compounds across sessions instead of disappearing into chat history. One SARA instance per project.

## Requirements

- [Claude Code](https://claude.ai/code) installed

## Installation

From inside your project directory, run:

```bash
curl -fsSL https://raw.githubusercontent.com/cgb-76/SARA/main/install.sh | bash
```
## Updating

Re-run the install command to update:

```bash
curl -fsSL https://raw.githubusercontent.com/cgb-76/SARA/main/install.sh | bash
```

Downgrade protection is built in — if the source version is older than what you have installed, a warning is printed and that skill is skipped. Use `--force` to override.

## Setup

After installation:

1. Open Claude Code in your project directory
2. Run `/sara-init` — this sets up the wiki structure and prompts for your project's vertical and department lists

## Commands

| Command | Description |
|---------|-------------|
| `/sara-init` | Initialise a new SARA wiki in the current directory |
| `/sara-ingest` | Register a raw input file as a pipeline item |
| `/sara-discuss` | LLM-guided discussion to agree on extraction intent |
| `/sara-extract` | Present the extraction plan for user approval |
| `/sara-update` | Write approved artifacts to the wiki and commit |
| `/sara-add-stakeholder` | Create a new stakeholder page |
| `/sara-minutes` | Generate meeting minutes from a completed ingest item |
| `/sara-agenda` | Generate a pre-meeting agenda draft |
