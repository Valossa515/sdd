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

> **CRITICAL — File creation is MANDATORY.**
> This skill MUST produce real files on disk inside the `.agent/` directory.
> Presenting content only in chat is NOT acceptable — every document listed below MUST be written to the filesystem using file-creation tools.
> At the end of execution the agent MUST confirm which files were created/updated and their paths.

## Required files

Ensure these files exist in `.agent/` (create them if they don't):

- `project-reference.md` ← **single-file consolidated reference** (overview, architecture, class map, conventions, glossary)
- `context.md`
- `architecture.md`
- `decisions.md` or `adr/` (preferred)
- `conventions.md`
- `runbook.md`
- `glossary.md`
- `backlog_rules.md`

## Workflow

### Phase 1 — Silent Project Discovery

Before creating any file, scan the codebase and collect real information.

> **IMPORTANT:** Phase 1 is a SILENT research phase. Do NOT present a summary in the chat.
> Do NOT output architecture overviews, class lists, or project descriptions as chat messages.
> ALL collected information goes directly into the files created in Phase 2.
> The only acceptable chat output during Phase 1 is brief status like "Scanning project..." or "Reading pom.xml...".

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

**When Phase 1 is complete, proceed IMMEDIATELY to Phase 2. Do not stop. Do not present results in chat.**

### Phase 2 — Create Files (MANDATORY)

> **⚠️ THIS IS THE CORE DELIVERABLE. If you skip this phase, the bootstrap has FAILED.**
>
> Execute each step below as a file-creation action. Do NOT display file content in chat instead of writing to disk.

For each file below, **create or overwrite** the file at the exact path shown.
If `.agent/` directory does not exist, create it first.

#### Step 2.1 — Write `.agent/project-reference.md`

**Action:** Create file at path `.agent/project-reference.md`
- Follow the template structure from `templates/common/project-reference.md`
- Populate ALL sections with real data collected in Phase 1
- Include: project overview, architecture style, full class/module map, endpoints, database schema, conventions, domain glossary, dependencies, and run commands
- This file must be self-sufficient — anyone reading only this file should understand the entire project

#### Step 2.2 — Write `.agent/context.md`

**Action:** Create file at path `.agent/context.md`
- Follow the template structure from `templates/common/context.md`
- Populate with real project data from Phase 1

#### Step 2.3 — Write `.agent/architecture.md`

**Action:** Create file at path `.agent/architecture.md`
- Follow the template structure from `templates/common/architecture.md`
- Populate with real architecture data from Phase 1

#### Step 2.4 — Write `.agent/conventions.md`

**Action:** Create file at path `.agent/conventions.md`
- Follow the template structure from `templates/common/conventions.md`
- Populate with real conventions detected in Phase 1

#### Step 2.5 — Write `.agent/runbook.md`

**Action:** Create file at path `.agent/runbook.md`
- Follow the template structure from `templates/common/runbook.md`
- Include build, run, test, and deploy commands

#### Step 2.6 — Write `.agent/glossary.md`

**Action:** Create file at path `.agent/glossary.md`
- Follow the template structure from `templates/common/glossary.md`
- Populate with domain vocabulary extracted in Phase 1

#### Step 2.7 — Write `.agent/decisions.md`

**Action:** Create file at path `.agent/decisions.md`
- Document key architecture decisions discovered in the code (database, ORM, auth, etc.)

#### Step 2.8 — Write `.agent/backlog_rules.md`

**Action:** Create file at path `.agent/backlog_rules.md`
- Follow the template structure from `templates/common/backlog_rules.md`

#### Step 2.9 — Write `.agent/SKILLS.md`

**Action:** Create or update file at path `.agent/SKILLS.md`
- List active skills only
- Add a section **Overrides específicos do projeto**
- Add links to `project-reference.md`, `context.md`, `architecture.md`, and `runbook.md`

#### Step 2.10 — Confirm file creation

**Action:** After ALL files above are written, output a checklist like this in the chat:

```
✅ Files created/updated:
- .agent/project-reference.md
- .agent/context.md
- .agent/architecture.md
- .agent/conventions.md
- .agent/runbook.md
- .agent/glossary.md
- .agent/decisions.md
- .agent/backlog_rules.md
- .agent/SKILLS.md
```

> **If any file from the list above was NOT created, the bootstrap is INCOMPLETE. Go back and create it.**

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

### ❌ FORBIDDEN — These are the most common failure modes:

1. **NEVER present project analysis only in chat without creating files.** The whole point of `@bootstrap` is to produce files. If you analyzed the project and wrote a summary in the chat but created zero files, you have FAILED. Go back and execute Phase 2.
2. **NEVER stop after Phase 1.** Phase 1 is research. Phase 2 is the deliverable. You are not done until Phase 2 is complete.
3. **NEVER ask "Do you want me to create the files?"** — File creation is automatic and expected. Just do it.
4. **NEVER present file content in a code block in chat as a substitute for writing the actual file.** If you find yourself writing ```markdown in a chat response with the contents of `project-reference.md`, STOP — you should be creating that file on disk instead.

### Other rules:

- ❌ Do not keep only generic stack text when project context is known.
- ❌ Do not duplicate entire skills inside context documents.
- ❌ Do not leave `.agent/SKILLS.md` without links to context files.
- ❌ Do not skip generating `project-reference.md` — it is the primary output of bootstrap.
- ❌ Do not leave `project-reference.md` with example/placeholder classes — every entry must be real.
