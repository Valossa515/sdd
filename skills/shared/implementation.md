---
name: implementation
description: Use this skill when the user asks for @implementation or wants to execute a previously created plan. It follows the plan document produced by @planning and implements tasks in order.
stack: shared
versions: "SDD 1.x"
---

# Implementation — Plan Execution

Use this skill when the user asks for `@implementation` or wants to execute a feature plan.
This is the **second step** of the feature flow: `@planning` → `@implementation`.

## Trigger phrases

- `@implementation`
- "implement the plan"
- "execute the plan"
- "start coding the feature"
- "build this feature"

## Goal

Execute all tasks from a plan document (`.agent/plans/<feature-name>.md`), following project skills and conventions, producing working code with proper structure.

## Workflow

1. **Read the plan** — load `.agent/plans/<feature-name>.md`.
2. **Read project context** — load `.agent/SKILLS.md` and all linked skills.
3. **Validate preconditions** — ensure required dependencies, migrations, or config exist.
4. **Execute tasks in order** — for each task in the plan:
   a. Mark the task as in-progress.
   b. Write code following the appropriate stack skill (`SKILL.md`).
   c. Follow conventions from `api-design.md`, `database.md`, `security.md`, etc.
   d. Mark the task as complete.
5. **Run validations** — execute `make validate` or project build/lint.
6. **Update the plan** — check off completed tasks, note any deviations.
7. **Suggest next steps** — recommend `@test-plan` → `@test` for the implemented feature.

## Implementation checklist

For each task, verify:

```text
✓ Follows layer separation from SKILL.md
✓ Naming conventions match conventions.md
✓ API endpoints follow api-design.md (verbs, status codes, pagination)
✓ Database changes follow database.md (migrations, naming, indexes)
✓ Error handling uses error-handling.md (RFC 7807, exception hierarchy)
✓ Security rules from security.md applied (input validation, auth)
✓ Observability from observability.md (structured logging, health checks)
```

## Quick command

```text
@implementation
Execute the plan in .agent/plans/<feature-name>.md
```

Or without a prior plan:

```text
@implementation
Implement: <describe what to build, referencing skills to follow>
```

## Commit strategy

- One commit per logical task from the plan.
- Commit message format: `feat(<scope>): <what was done>` or `fix(<scope>): <what was fixed>`.
- Do not bundle unrelated changes in a single commit.

## Output quality rules

- Follow the plan — do not add scope that was not planned.
- Apply all relevant skills — do not skip conventions because "it's faster."
- Keep code consistent with the existing codebase style.
- Add `TODO` comments only for items explicitly marked as open in the plan.

## What NOT to do

- ❌ Do not implement without reading the plan and project skills first.
- ❌ Do not skip layers (e.g., putting business logic in controllers).
- ❌ Do not ignore the plan's task order — dependencies matter.
- ❌ Do not add features beyond the plan's scope without explicit approval.
- ❌ Do not forget to run build/lint validation after implementation.
- ❌ Do not skip database migrations when schema changes are required.
