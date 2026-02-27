---
name: bootstrap
description: Use this skill when the user asks for @bootstrap, project initialization, or wants the agent to map project context before coding. It creates and maintains project context docs and links them in .agent/SKILLS.md.
stack: shared
versions: "SDD 1.x"
---

# Bootstrap — Project Context Initialization

> ## ⚠️ EXECUTION CONTRACT
>
> **This skill produces FILES, not chat messages.**
>
> When you receive `@bootstrap`, your job is to:
> 1. Scan the codebase silently (no chat output)
> 2. Create 9 files inside `.agent/`
> 3. Report which files were created
>
> **You are DONE only when all 9 files exist on disk.**
> If you find yourself writing project summaries or architecture overviews in the chat — STOP. That content belongs in a file.

## Trigger phrases

- `@bootstrap`
- "bootstrap do projeto"
- "initialize project context"
- "prepare .agent docs"

## Execution steps

Follow these steps in order. Each step ends with a FILE being written to disk.

---

### Step 1 — Scan & write `.agent/project-reference.md`

**Scan:** Read `README`, build file (`pom.xml`, `build.gradle`, `*.csproj`, `package.json`), CI config, and the full source tree. Map every package/namespace, class, controller, service, repository, entity, and config. Identify architecture style, conventions, integrations, and domain vocabulary.

**Write file** at `.agent/project-reference.md` with:
- Follow template structure from `templates/common/project-reference.md`
- Project overview (name, type, stack, build tool, runtime version)
- Architecture style and layer map
- **Complete class/module map** — every class found, with path and responsibility
- Available endpoints (from controllers/routes)
- Database schema (from entities/migrations)
- Conventions summary (naming, structure, technical choices)
- Domain glossary (entities, enums, business terms)
- Dependencies table (from build file)
- How to build, run, and test

> This is the PRIMARY deliverable. It must be comprehensive and populated with real data.
> MUST NOT contain placeholder text like `[project name]` or `[describe...]` — use real values from the scan or `TODO: <reason>` for genuinely unknowable info.

---

### Step 2 — Write `.agent/context.md`

**Write file** at `.agent/context.md` with:
- Follow template from `templates/common/context.md`
- Project overview, problem statement, objectives, main flows, endpoints, constraints, dependencies
- Populate from the data already collected in Step 1

---

### Step 3 — Write `.agent/architecture.md`

**Write file** at `.agent/architecture.md` with:
- Follow template from `templates/common/architecture.md`
- Architecture style, layer responsibilities, package structure, integration points
- Populate from the data already collected in Step 1

---

### Step 4 — Write `.agent/conventions.md`

**Write file** at `.agent/conventions.md` with:
- Follow template from `templates/common/conventions.md`
- Naming patterns, code structure, DI style, error handling, test conventions
- Populate from the data already collected in Step 1

---

### Step 5 — Write `.agent/runbook.md`

**Write file** at `.agent/runbook.md` with:
- Follow template from `templates/common/runbook.md`
- Build, run, test, deploy, and migration commands
- Environment setup, required tools, common troubleshooting

---

### Step 6 — Write `.agent/glossary.md`

**Write file** at `.agent/glossary.md` with:
- Follow template from `templates/common/glossary.md`
- Domain terms, entity names, enum values, abbreviations from the codebase

---

### Step 7 — Write `.agent/decisions.md`

**Write file** at `.agent/decisions.md` with:
- Key architecture decisions found in the code (database choice, ORM, auth mechanism, etc.)
- Format as lightweight ADRs (context → decision → consequences)

---

### Step 8 — Write `.agent/backlog_rules.md`

**Write file** at `.agent/backlog_rules.md` with:
- Follow template from `templates/common/backlog_rules.md`

---

### Step 9 — Write `.agent/SKILLS.md`

**Write file** at `.agent/SKILLS.md` with:
- Active skills list
- Section **Overrides específicos do projeto**
- Links to `project-reference.md`, `context.md`, `architecture.md`, and `runbook.md`

---

### Step 10 — Report

After all 9 files are written, output ONLY this checklist:

```
✅ Bootstrap complete. Files created:
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

**Self-check:** If any file above was NOT written to disk, go back and write it now before reporting.

---

## Output quality rules

- Every section must contain **real project data** — scan the codebase before writing.
- Class/module descriptions must be specific (e.g., "Handles order creation and stock validation") not generic (e.g., "Service layer").
- Architecture docs must reflect the actual folder structure and class relationships.
- Use `TODO: <reason>` instead of inventing facts — but only for genuinely unknowable info.
- Keep docs concise, practical, and project-specific.

## ❌ FORBIDDEN — Common failure modes

1. **Presenting a project summary in chat without creating files.** If you scanned the project and wrote an overview in the chat but created zero files → you FAILED. Go execute Steps 1-9.
2. **Stopping after scanning the project.** Scanning is Step 1a. Writing the file is Step 1b. You are not done until Step 10.
3. **Asking "should I create the files?"** — YES. Always. That is the entire point of `@bootstrap`. Just do it.
4. **Showing file content in a chat code block instead of writing the file.** If you are about to type ` ```markdown ` with the contents of `project-reference.md` in a chat message → STOP → use a file-creation tool instead.
5. **Leaving placeholder text** like `[project name]` or `[describe...]` when the data is in the codebase.

## Quick reference

```text
@bootstrap
```

```bash
make bootstrap STACK=spring-boot TARGET=$(pwd)
```
