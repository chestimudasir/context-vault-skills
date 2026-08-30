# Agent Context Vault — Instructions

This is an Obsidian knowledge vault that stores development context across projects.
When running Claude in this directory, the primary tasks are:
- **Recalling context** for upcoming work
- **Consolidating sessions** into MOCs
- **Updating MOCs** when new sessions are added

---

## Vault Structure

```
Root/
├── CLAUDE.md (this file)
├── Root-level topic stubs (e.g. Redis.md, SQS.md) — anchor points for cross-project topics
├── <project-a>/          — sessions + MOCs
├── <project-b>/          — sessions only, needs MOCs
└── <project-c>/          — 1 session, needs hub
```

Each project folder is named after the project directory's basename. Keep this list current.

---

## MOC System — 3-Tier Hierarchy

The vault uses a layered Map of Content system.

### Tier 1: Master MOC (`00 - Master MOC.md`)
- One per project, the single entry point
- Links to all topic MOCs in a table: `| MOC | What it covers | Sessions |`
- Quick stats (total sessions, date range, key metrics)
- Key files section listing most-referenced files

**Frontmatter:**
```yaml
---
aliases: [Home, Index, Dashboard]
tags: [MOC, master, index]
date: YYYY-MM-DD
---
```

### Tier 2: Topic MOCs
- Organized by domain (not chronology): Migration, Reports, AWS, Database, etc.
- Each has `> Back to [[00 - Master MOC]]` at the top
- Sessions listed in tables: `| Session | What | Scale |`
- Grouped by phases/categories within the MOC
- Cross-link to related MOCs at the bottom under `## Related MOCs`

**Frontmatter:**
```yaml
---
aliases: [alt1, alt2]
tags: [MOC, topic, domain-tag]
date: YYYY-MM-DD
project: "[[projectFolderName]]"
---
```

**Standard topic MOC types to consider for any project:**
- By domain/feature (e.g., Billing, Authentication, Reports)
- By technology (e.g., Database, Redis, AWS, Email)
- Timeline MOC (chronological phases)
- Bug Tracker MOC (organized by root cause pattern, not by date)
- Architecture Patterns MOC (reusable patterns extracted)
- Project Module MOC (organized by subsystem)

### Tier 3: Session Logs
- Named `YYYY-MM-DD_HH-MM-SS.md`, written by `/obs-save`
- Link back via `project: "[[projectFolderName]]"` and `related:` field
- Sections: Summary, Key Changes, Decisions & Context, Related

**Frontmatter:**
```yaml
---
aliases: []
tags: [devlog, context, claude-session]
date: YYYY-MM-DD
project: "[[projectFolderName]]"
related:
  - "[[projectFolderName]]"
  - "[[TopicOrMOC]]"
---
```

### Artifacts (`<project>/artifacts/`)
- Copies of plans, designs, specs, brainstorms, and review reports produced during a session
- Named `YYYY-MM-DD_<slug>.md`, written by `/obs-save`
- Frontmatter carries `type:`, `source_path:`, and a `session:` link back to the session log

---

## How to Consolidate Sessions into MOCs

When the user asks to consolidate or update MOCs:

### For projects WITH existing MOCs:
1. Read the Master MOC to understand current coverage
2. Read each topic MOC to see which sessions are already indexed
3. Read any NEW session logs not yet in MOCs
4. For each new session:
   - Determine which topic MOC(s) it belongs to
   - Add a row to the relevant table(s) in those MOCs
   - If a session spans multiple topics, add it to ALL relevant MOCs
5. Update the Master MOC's session count and date range
6. If new sessions reveal a new theme not covered by existing MOCs, propose creating a new topic MOC

### For projects WITHOUT MOCs:
1. Read ALL session logs in the project folder
2. Identify recurring themes, technologies, and domains
3. Create a Master MOC (`00 - Master MOC.md`) with:
   - Summary stats
   - Table linking to topic MOCs
4. Create topic MOCs grouped by the identified themes
5. Ensure every session is referenced in at least one topic MOC

### Consolidation rules:
- **Never modify session logs** — they are immutable records
- **MOCs are living documents** — update them freely
- **Every session must appear in at least one MOC table**
- **Use the existing table format**: `| [[YYYY-MM-DD_HH-MM-SS]] | What was done | Scale/scope |`
- **Update the `date:` field** in MOC frontmatter to the date of the latest update
- **Keep table rows chronological** within each phase/section
- **Cross-link MOCs** when sessions touch multiple domains

---

## Linking Conventions

- Use `[[wiki-links]]` for all internal references
- Session logs link to MOCs and topics in `related:` frontmatter
- MOCs link to sessions in tables
- MOCs link to other MOCs in `## Related MOCs` section
- Root-level stubs (e.g. `Redis.md`, `SQS.md`) are anchor points for cross-project topics

---

## Hub Notes vs MOCs

Some projects use a **hub note** instead of a full MOC system (e.g., `<project>.md` at the vault root).
Hub notes are project overviews with architecture, tech stack, and module structure.
They are NOT MOCs — they don't index sessions. When a project grows enough sessions (5+),
create a proper MOC system alongside the hub note. The hub becomes a reference linked from the Master MOC.
