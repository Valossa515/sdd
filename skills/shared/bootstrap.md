---
name: bootstrap
description: Use this skill when the user asks for @bootstrap, project initialization, or wants the agent to map project context before coding. It creates and maintains project context docs and links them in .agent/SKILLS.md.
stack: shared
versions: "SDD 1.x"
---

# Bootstrap — Project Context Initialization

Use this skill when the user asks for `@bootstrap` or wants full project context setup.

## Trigger phrases

- `@bootstrap`
- "bootstrap do projeto"
- "initialize project context"
- "prepare .agent docs"

## Goal

Create/update a minimal project knowledge base in `.agent/` so future tasks have domain context and not only generic coding rules.

## Required files

Ensure these files exist in `.agent/`:

- `context.md`
- `architecture.md`
- `decisions.md` or `adr/` (preferred)
- `conventions.md`
- `runbook.md`
- `glossary.md`
- `backlog_rules.md`

## Workflow

1. Read existing `.agent/SKILLS.md` and active skills.
2. Scan repository signals (`README`, `Makefile`, CI, source tree).
3. Create or refresh the required context files.
4. Update `.agent/SKILLS.md` with:
   - Active skills only
   - A section **Overrides específicos do projeto**
   - Links to `context.md`, `architecture.md`, and `runbook.md`
5. Add or update ADRs for key architecture decisions.
6. Run Makefile validations as part of bootstrap (do not skip):
   - `make validate`
   - `make check`
   - If installing context in repo root: `make bootstrap STACK=<stack> TARGET=$(pwd)`

## Quick command

```text
@bootstrap
```

Or run the repository bootstrap flow:

```bash
make bootstrap STACK=spring-boot TARGET=$(pwd)
```

## Output quality rules

- Keep docs concise, practical, and project-specific.
- Prefer bullets and short sections.
- Use explicit defaults (versions, environments, migration tool, test command).
- Add unknowns as `TODO` instead of inventing facts.

## What NOT to do

- ❌ Do not keep only generic stack text when project context is known.
- ❌ Do not duplicate entire skills inside context documents.
- ❌ Do not leave `.agent/SKILLS.md` without links to context files.
