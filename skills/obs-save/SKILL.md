---
name: obs-save
description: Save a session summary plus any plan/design/spec/brainstorm artifacts to the Obsidian vault before clearing context
disable-model-invocation: true
user-invocable: true
---

# Obsidian Session Save

Save a concise summary of the current conversation to the Obsidian vault, **including any working artifacts produced during the session** (plans, designs, specs, brainstorms, review reports), then compact the context.

## Step 0: Resolve the vault root

Run this command with the Bash tool:

```bash
v="${AGENT_CONTEXT_VAULT%/}"; echo "vault=${v:-UNSET}"; [ -d "$v" ] && echo "status=ok" || echo "status=missing"
```

- `vault=UNSET` → stop and tell the user:

  > `AGENT_CONTEXT_VAULT` is not set. Add `{ "env": { "AGENT_CONTEXT_VAULT": "/absolute/path/to/vault" } }` to `~/.claude/settings.json`, then start a new session.

- `status=missing` → stop and tell the user that the vault directory does not exist at the printed path.
- `status=ok` → use the printed path as `<vault>` in every path below. Use it exactly as printed (case-sensitive). Do not search for the vault anywhere else.

## Step 1: Determine the project name

Use the basename of the current working directory as `<project>`.

## Step 2: Identify session artifacts

Scan your own tool-use history for this session. Identify files you **created or materially rewrote** that match the artifact profile below. Do NOT scan the filesystem — rely on what you actually wrote during this session.

**Artifact profile (include):**
- Plans: `*plan*.md`, `*.plan.md`, anything under `plans/`, `.plans/`
- Brainstorms: `*brainstorm*.md`, anything under `brainstorms/`, `.brainstorms/`
- Designs: `DESIGN.md`, `*design*.md`, anything under `.design/`, `design/`
- Specs: `*spec*.md`, `SPEC.md`, anything under `specs/`
- Review reports: `*review*.md`, `code-review-*.md`, anything under `reviews/`
- Any standalone `.md` in a hidden (`.`-prefixed) working directory that this session created

**Exclude:**
- Source code (`.ts`, `.tsx`, `.js`, `.py`, `.go`, etc.)
- Config files (`package.json`, `tsconfig.json`, `.env*`, etc.)
- `README.md`, `CHANGELOG.md`, `LICENSE` — project-level docs, not session artifacts
- Anything already inside the vault
- Trivial edits (a 1-line change does not an artifact make)

If no artifacts were produced, skip to Step 4.

## Step 3: Confirm and copy artifacts

Show the user the detected artifact list in this exact format:

```
## Detected session artifacts

1. <type>: <relative path from cwd>
2. <type>: <relative path from cwd>
...

Copy these to the vault? (y / n / select: 1,3)
```

Wait for the user's answer. On `y` or a selection, copy each confirmed artifact to:

```
<vault>/<project>/artifacts/YYYY-MM-DD_<slug>.md
```

Where:
- `YYYY-MM-DD` is today's date
- `<slug>` is the original filename without extension, lowercased, with non-alphanumerics replaced by `-`

**Artifact file format:** prepend this frontmatter, then the **full original content unchanged**:

```markdown
---
aliases: []
tags: [artifact, <type>]
date: YYYY-MM-DD
project: "[[<project>]]"
type: <plan | design | brainstorm | spec | review>
source_path: <absolute path to the original file in the project repo>
session: "[[YYYY-MM-DD_HH-MM-SS]]"
---

<original file content verbatim>
```

Create the `artifacts/` subfolder if it does not exist. Do **not** modify the original file in the project repo — this is a copy, not a move.

Remember the list of vault-relative paths of each copied artifact for Step 5.

## Step 4: Create the session note

Create the session log at:

```
<vault>/<project>/YYYY-MM-DD_HH-MM-SS.md
```

Use the current date and time (24-hour format) for the filename. Create the project directory if it does not exist.

## Step 5: Format the session note

The file MUST follow this exact format:

```markdown
---
aliases: []
tags: [devlog, context, claude-session]
date: YYYY-MM-DD
project: "[[<project>]]"
artifacts:
  - "[[<artifact-wiki-link-1>]]"
  - "[[<artifact-wiki-link-2>]]"
related:
  - "[[<related-note-1>]]"
  - "[[<related-note-2>]]"
---

# Session — <Month DD, YYYY HH:MM AM/PM>

**Project:** `<full working directory path>`

## Summary

<2-5 bullet points summarizing what was accomplished, discussed, or decided>

## Key Changes

<Source-code / config files created, modified, or deleted in the project repo. If none, write "No file changes.">

## Artifacts

<For each copied artifact, one bullet:>
- **[[<artifact-wiki-link>]]** (<type>) — one-line description of what it is and why it exists

<If no artifacts were copied, omit this whole section.>

## Decisions & Context

<Any architectural decisions, gotchas discovered, or important context for future sessions. Use [[backlinks]] for technologies, patterns, and related notes.>

## Related
- [[<project>]]
- <any other relevant backlinks discovered during the session>
```

### Rules

- **Tag format is `[devlog, context, claude-session]` — NO `#` prefix.** YAML treats `#` as a comment and the frontmatter will silently fail to parse.
- Use `[[wikilinks]]` throughout the body for all technologies, projects, patterns, concepts, and artifacts mentioned
- The `related` frontmatter and `## Related` section must include the project name and any technologies/concepts discussed
- The `artifacts` frontmatter field is **omitted entirely** if no artifacts were copied (do not write `artifacts: []`)
- Keep the summary concise — this is a reference note, not a transcript
- If the session was trivial, still save a note but say so in the summary
- Do NOT include full code blocks or long outputs — summarize instead

## Step 6: Index the session in a MOC

Every session log must appear in at least one topic MOC. Add the row at save time so no backlog forms.

1. Look for `<vault>/<project>/00 - Master MOC.md` (or any `00 - *.md` hub file).
2. **No Master MOC?** Skip this step. In Step 7, note that the project has no MOCs yet.
3. Read the Master MOC. Pick the topic MOC(s) whose scope matches this session. Read them.
4. Append one row to the session table of each matching MOC, in that table's existing format:

   `| [[YYYY-MM-DD_HH-MM-SS]] | <one-line what-was-done> | <small / medium / large> |`

   Place the row in chronological position (normally last). If a table uses a different column layout, match that layout.
5. **No topic MOC matches?** Append the row to `Unsorted MOC.md` instead. Create it if missing: standard topic-MOC frontmatter, `> Back to [[00 - Master MOC]]` at the top, a `| Session | What | Scale |` table. Add an `Unsorted` row to the Master MOC's table.
6. Update each edited MOC's frontmatter `date:` to today. If the Master MOC shows a total session count, add 1.

### Rules

- Append rows and update dates/counts only. Do not reorganize, rewrite, or re-sort MOC content during a save — that is consolidation work, done separately in the vault.
- Never modify session logs.

## Step 7: Confirm and compact

Report to the user:
- The session file path
- A one-line summary of what was saved
- The count and vault paths of any artifacts copied
- The MOC row(s) added in Step 6, or a note that the project has no MOCs yet

Then run `/clear` to compact the context.
