---
name: sara-agenda
description: "Generate an email-friendly meeting agenda draft from user-provided meeting description"
argument-hint: ""
allowed-tools: []
version: 1.0.0
---

<objective>
Generates a throw-away email-friendly agenda draft from a single freeform user prompt.
No pipeline state is read. No wiki files are read or written. No git commands are run.
Output is displayed once to the terminal and discarded — nothing persists.
</objective>

<process>

**Step 1 — Collect meeting description (D-09)**

Output the following as plain text and wait for the user's reply:

> Describe the meeting: who will be attending (names and roles if relevant),
> what topics need to be covered, and what you want to achieve by the end.

Capture the user's reply as `{meeting_description}`.

**Step 2 — Generate agenda and output (D-11, D-12)**

Using `{meeting_description}`, synthesise a plain-text agenda draft.

Output plain-text only — no markdown formatting whatsoever (no `##` headings, no `**bold**`,
no `*` or `-` bullet symbols unless they are natural list dashes). Use CAPS for section labels.

Use the following structure for the output:

```
SUBJECT: [suggested email subject line derived from meeting topics]

[Greeting — e.g. "Hi team," or "Hi [name]," as appropriate from the description]

Please find the agenda for our upcoming meeting below.

AGENDA

1. [First topic from description]
2. [Second topic from description]
3. [Additional topics as needed]

DESIRED OUTCOME

[One or two sentences stating what we aim to achieve or decide by end of meeting]

[Sign-off — e.g. "Best," followed by a blank line for the sender to fill in their name]
```

Do NOT include time allocations next to agenda items (D-11 — user explicitly excluded them).

STOP — do NOT write any file, do NOT run any git command, do NOT read any wiki or pipeline file.

</process>

<notes>

- CRITICAL — NO WRITES: This skill is fully stateless. Do NOT use the Write tool. Do NOT use the Read tool. Do NOT run Bash commands. `allowed-tools: []` is intentional.
- CRITICAL — PLAIN TEXT ONLY: The generated agenda output must be plain text. No `##` markdown headings, no `**bold**` markers, no `*` bullet symbols. Use CAPS for section labels (AGENDA, DESIRED OUTCOME, SUBJECT). Dashes as natural list separators are acceptable if the LLM produces them, but numbered items are preferred per the output structure. (D-11, Pitfall 4)
- NO TIME ALLOCATIONS: Do not include time estimates (e.g. "15 min") next to agenda items. The user explicitly does not want them. (D-11)
- SINGLE FREEFORM PROMPT: Only one question is asked. Do not use `AskUserQuestion` tool. Do not ask separate follow-up questions for each field. (D-09)
- STATELESS: Do not read `pipeline-state.json`, do not read wiki files, do not look up stakeholder pages. The output is derived entirely from the user's free-text reply. (D-10)
- NO GIT COMMIT: No commit is made. Output is throw-away. (D-12)
- `argument-hint: ""` — this skill takes no argument. If the user passes `$ARGUMENTS`, ignore it; proceed directly to the freeform prompt.

</notes>
