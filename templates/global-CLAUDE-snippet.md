<!-- Add this section to ~/.claude/CLAUDE.md. Replace the path and the project list. -->

## Context Vault

An Obsidian knowledge vault lives at `/absolute/path/to/your/vault/`.
It stores session logs, architecture docs, and MOCs (Maps of Content) for all projects.

**Before starting significant work**, check the vault for relevant context:
- Look in the project's subfolder for recent session logs and MOCs
- Use `/obs-load` for the latest session, `/harpoon <topic>` for a question, `/detective <topic>` for the full history
- Project folder mapping:
  - `project-a/` — what project-a is
  - `project-b/` — what project-b is

**At the end of significant sessions**, run `/obs-save` to write a session log to the vault.
