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

- `project-reference.md` ← **single-file consolidated reference** (overview, architecture, class map, conventions, glossary)
- `context.md`
- `architecture.md`
- `decisions.md` or `adr/` (preferred)
- `conventions.md`
- `runbook.md`
- `glossary.md`
- `backlog_rules.md`

## Workflow

### Phase 1 — Project Discovery (NEW)

Before creating any file, the agent MUST scan the codebase and collect real information:

1. **Read project metadata**: `README`, `Makefile`, `build.gradle`, `pom.xml`, `*.csproj`, `package.json`, CI files.
2. **Map the source tree**: list all packages/namespaces and their top-level classes/files.
3. **Identify the architecture style**: layered, hexagonal, clean architecture, MVC, etc. — based on folder structure and class naming.
4. **Catalog modules and classes**: for each main class/file, determine:
   - Its layer (API, Application, Domain, Infrastructure)
   - Its responsibility (controller, service, repository, entity, DTO, config, etc.)
   - Key dependencies it uses
5. **Detect conventions**: naming patterns, test structure, DI style, error handling approach.
6. **Discover external integrations**: databases, queues, HTTP clients, cloud services.
7. **Extract domain vocabulary**: entity names, enum values, business terms from class/method names.

> The agent MUST NOT leave placeholders like `[describe...]` when the information can be discovered from the code. Use `TODO` only for genuinely unknowable information (business context, roadmap, personas).

### Phase 2 — Generate Context Documents

1. Read existing `.agent/SKILLS.md` and active skills.
2. **Generate `project-reference.md` first** — this is the consolidated single-file reference.
   - Follow the template in `templates/common/project-reference.md`.
   - Populate ALL sections with real data from Phase 1.
   - Include: project overview, architecture style, full class/module map with responsibilities, available endpoints, database schema, conventions, domain glossary, dependencies, and run commands.
   - This file must be self-sufficient — anyone reading only this file should understand the entire project.
3. Create or refresh the individual context files (`context.md`, `architecture.md`, `conventions.md`, etc.), **populating them with real data from Phase 1**.
4. Update `.agent/SKILLS.md` with:
   - Active skills only
   - A section **Overrides específicos do projeto**
   - Links to `project-reference.md`, `context.md`, `architecture.md`, and `runbook.md`
5. Add or update ADRs for key architecture decisions discovered in the code (e.g., chosen database, ORM, auth mechanism).

### Phase 3 — Validate

1. Run Makefile validations as part of bootstrap (do not skip):
   - `make validate`
   - `make check`
   - If installing context in repo root: `make bootstrap STACK=<stack> TARGET=$(pwd)`
2. Verify no context file still has only placeholder text — every section must have real content or an explicit `TODO` with reason.

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
- Add unknowns as `TODO: <reason>` instead of inventing facts.
- **Every section must contain real project data** — scan the codebase before writing.
- Class/module descriptions must be specific (e.g., "Handles order creation and stock validation") not generic (e.g., "Service layer").
- Architecture docs must reflect the actual folder structure and class relationships found in the code.

## What NOT to do

- ❌ Do not keep only generic stack text when project context is known.
- ❌ Do not duplicate entire skills inside context documents.
- ❌ Do not leave `.agent/SKILLS.md` without links to context files.
- ❌ Do not skip generating `project-reference.md` — it is the primary output of bootstrap.
- ❌ Do not leave `project-reference.md` with example/placeholder classes — every entry must be real.
