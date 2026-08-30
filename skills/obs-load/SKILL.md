---
name: obs-load
description: Load the latest session context (including linked artifacts) from the Obsidian vault for the current project
disable-model-invocation: true
user-invocable: true
---

# Obsidian Context Load

Find and read the most recent context from the Obsidian vault for the current project, including any artifacts that session linked, then present a summary to the user.

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

## Step 2: Find the latest session file

List `.md` files in:

```
<vault>/<project>/
```

(not recursing into `artifacts/`), sorted by modification time, newest first. Pick the most recently modified file that matches the session-log filename pattern `YYYY-MM-DD_HH-MM-SS.md`.

If none exists, fall back to any non-overview `.md` in the project folder. If the folder itself does not exist, tell the user:

> No Obsidian context found for this project. Use `/obs-save` to save your first session.

and stop.

## Step 3: Read the session file and its linked artifacts

Read the session file. Parse its frontmatter.

**If `artifacts:` is present in the frontmatter**, resolve each wiki-link to a path under `<project>/artifacts/` and read each artifact file. Cap at **5 artifacts** to keep context bounded — if there are more, read the 5 most recently modified and list the rest by name only.

**Also read** the project overview file at the vault root if it exists:

```
<vault>/<project>.md
```

This contains accumulated architectural context.

## Step 4: Present the loaded context

Display to the user in this format:

```
## Loaded Context from Obsidian

**Project:** <project>
**Last session:** <date from the session file>
**Artifacts loaded:** <count>  (omit this line if zero)

### Previous Session Summary
<The Summary + Decisions & Context sections from the session file>

### Artifacts
<For each loaded artifact, 2-4 bullet points of what it contains>
- **<artifact title>** (<type>): <brief description + key decisions>

### Project Context
<If the project overview file exists, key points from it>
```

After presenting, tell the user you are ready to continue with this context in mind.

### Rules

- **Read-only skill.** Do not modify any files.
- Do not read session logs other than the latest one — that is what `/harpoon` is for.
- If an artifact wiki-link does not resolve to an existing file, note it as missing but do not fail.
- Do not dump full artifact content back to the user — summarize each into 2-4 bullets.
