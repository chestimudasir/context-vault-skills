# context-vault-skills

Four [Claude Code](https://code.claude.com) skills that keep your session context in an [Obsidian](https://obsidian.md) vault.

Claude Code forgets everything between sessions. These skills give it a memory that you own: plain Markdown files, linked with `[[wiki-links]]`, organized as a knowledge graph you can browse in Obsidian.

| Skill | Invoke | What it does |
|-------|--------|--------------|
| **obs-save** | `/obs-save` | Writes a session log (summary, key changes, decisions) plus any plan/design/spec artifacts to the vault, adds the session's row to a matching topic MOC, then clears context. |
| **obs-load** | `/obs-load` | Reads the latest session log for the current project, plus its linked artifacts, and presents a summary. |
| **harpoon** | `/harpoon <topic>` | Answers a question about past work by walking the graph: Master MOC → topic MOC → 2–5 sessions. About 10 file reads. |
| **detective** | `/detective <topic>` | Builds the complete story of a topic in two passes (map, then dig). About 35 file reads. |

`harpoon` and `detective` are also model-invocable: Claude reaches for them on its own when you ask "what happened with X?" or "give me the whole picture of Y".

## How the vault is organized

The skills expect this layout. One folder per project, named after the project directory's basename.

```
<vault>/
├── CLAUDE.md                          # vault-level instructions (see templates/)
├── <project-name>/
│   ├── 00 - Master MOC.md             # tier 1: single entry point, links every topic MOC
│   ├── <Topic> MOC.md                 # tier 2: one per domain (Bugs, Database, Migration, ...)
│   ├── YYYY-MM-DD_HH-MM-SS.md         # tier 3: session logs (immutable)
│   └── artifacts/
│       └── YYYY-MM-DD_<slug>.md       # plans, designs, specs copied from sessions
└── <project-name>.md                  # optional root-level project overview
```

- **Session logs** are written by `obs-save`. Never edit them by hand.
- `obs-save` also appends the new session's row to a matching topic MOC at save time (or to an `Unsorted MOC` when nothing matches), so sessions do not pile up unindexed. Projects without MOCs are skipped with a note.
- **MOCs** (Maps of Content) are living documents that index sessions by topic. `harpoon` and `detective` enter the vault only through MOCs — they never grep session files.
- **Artifacts** are copies of plans/designs/specs your session produced. They often hold more decision history than the session summary.

`templates/vault-CLAUDE.md` describes the full MOC system and how to consolidate sessions into MOCs. Copy it to your vault root as `CLAUDE.md`.

## Install

### Option A — `install.sh` (recommended for personal use)

Symlinks the skills into `~/.claude/skills/` so you invoke them as `/obs-save`, `/harpoon`, etc., and writes the vault path into `~/.claude/settings.json`.

```bash
git clone https://github.com/chestimudasir/context-vault-skills.git
cd context-vault-skills
./install.sh "/absolute/path/to/your/vault"
```

Flags: `--replace` (back up and replace existing skill directories of the same name), `--skills-only`, `--env-only`. Run `./install.sh --help` for details.

### Option B — Claude Code plugin

Inside Claude Code:

```
/plugin marketplace add chestimudasir/context-vault-skills
/plugin install context-vault@context-vault-skills
```

Plugin skills are namespaced: `/context-vault:obs-save`, `/context-vault:harpoon`, and so on. Then set the vault path (next section).

### Option C — manual

Copy or symlink each `skills/<name>` directory into `~/.claude/skills/` (personal) or `<project>/.claude/skills/` (per project). Then set the vault path.

## Configure the vault path

Every skill reads the vault location from the `AGENT_CONTEXT_VAULT` environment variable. The cleanest way to set it is the `env` block in a Claude Code settings file, which reaches every Bash call the skills make:

```json
// ~/.claude/settings.json
{
  "env": {
    "AGENT_CONTEXT_VAULT": "/Users/you/Documents/My Vault"
  }
}
```

- Use an absolute path, no trailing slash.
- To use a different vault for one project, put the same block in that project's `.claude/settings.json` or `.claude/settings.local.json`.
- Start a new session after changing settings.
- If the variable is unset, each skill stops and tells you how to set it.

## Usage

```
/obs-load                          # start of session: pick up where you left off
... work ...
/obs-save                          # end of session: log it, copy artifacts, clear context

/harpoon why did we move reports to SQS
/harpoon rate limiting in billing-api
/harpoon redis eviction --all      # search every project (expensive)

/detective the report scheduler bug chain
/detective auth migration in web-frontend
```

## Bootstrap a new vault

1. Create an empty folder (or an Obsidian vault) and point `AGENT_CONTEXT_VAULT` at it.
2. Copy `templates/vault-CLAUDE.md` to `<vault>/CLAUDE.md`. Edit the project list.
3. Optionally add the snippet in `templates/global-CLAUDE-snippet.md` to `~/.claude/CLAUDE.md` so Claude checks the vault before significant work.
4. Run `/obs-save` at the end of your first session. The project folder is created for you.
5. After 5+ sessions, open Claude Code in the vault directory and ask it to consolidate sessions into MOCs. `vault-CLAUDE.md` tells it how.

`harpoon` and `detective` need at least one MOC (`00 - Master MOC.md`) in the project folder to work well. Until then, use `/obs-load`.

## Requirements

- Claude Code 2.1 or newer (the skills use `disable-model-invocation` and `user-invocable` frontmatter)
- Bash (the skills run one `echo` to resolve the vault path)
- Obsidian is optional. The vault is plain Markdown.

## Repository layout

```
.claude-plugin/plugin.json       # plugin manifest (name: context-vault)
.claude-plugin/marketplace.json  # lets /plugin marketplace add <owner>/<repo> work
skills/obs-save/SKILL.md
skills/obs-load/SKILL.md
skills/harpoon/SKILL.md
skills/detective/SKILL.md
templates/vault-CLAUDE.md        # instructions for the vault root
templates/global-CLAUDE-snippet.md
install.sh
```

## License

MIT — see [LICENSE](LICENSE).
