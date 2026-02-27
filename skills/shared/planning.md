---
name: planning
description: Use this skill when the user asks for @planning or wants to plan a new feature, epic, or user story before implementation. It produces a structured plan document that feeds into @implementation.
stack: shared
versions: "SDD 1.x"
---

# Planning — Feature & Task Planning

Use this skill when the user asks for `@planning` or wants to design a feature before writing code.
This is the **first step** of the feature flow: `@planning` → `@implementation`.

## Trigger phrases

- `@planning`
- "plan this feature"
- "design the solution"
- "create a plan for..."
- "break down this task"

## Goal

Produce a structured **plan document** (`.agent/plans/<feature-name>.md`) that covers scope, approach, affected files, risks, and acceptance criteria — so the implementation phase has no ambiguity.

## Workflow

1. **Understand the request** — read the feature description, related issues, or user story.
2. **Read context** — load `.agent/SKILLS.md`, `context.md`, `architecture.md`, and `conventions.md`.
3. **Identify scope** — list which layers, modules, and files will be affected.
4. **Design the approach** — describe the solution at the architectural level:
   - New entities, DTOs, endpoints, services, or commands.
   - Database changes (new tables, columns, migrations).
   - Integration points (external APIs, events, queues).
5. **Define tasks** — break the work into ordered, implementable tasks.
6. **List risks and open questions** — flag unknowns as `TODO`.
7. **Write acceptance criteria** — concrete, testable conditions.
8. **Save the plan** — write to `.agent/plans/<feature-name>.md`.

## Plan document template

```markdown
# Plan: <Feature Name>

## Summary
One paragraph describing what will be built and why.

## Scope
- **Layers affected**: API / Application / Domain / Infrastructure
- **New files**: list expected new files
- **Modified files**: list files that will change

## Approach
Describe the technical design. Reference skills and conventions.

## Tasks
1. [ ] Task 1 — description
2. [ ] Task 2 — description
3. [ ] Task 3 — description

## Database changes
- New table: `table_name` (columns...)
- New migration: `V<N>__description` or EF migration name

## Risks & open questions
- TODO: ...

## Acceptance criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

## Quick command

```text
@planning
Plan the feature: <describe feature here>
```

## Output quality rules

- Keep plans concise — one page, not ten.
- Every task must be small enough to implement in a single commit.
- Reference specific skill files for conventions (e.g., "follow `api-design.md` for endpoint structure").
- Mark unknowns as `TODO` instead of guessing.
- Include database migration details when schema changes are needed.

## Handoff to @implementation

After the plan is reviewed and approved, use:

```text
@implementation
Execute the plan in .agent/plans/<feature-name>.md
```

The `@implementation` skill reads the plan and executes tasks in order.

## What NOT to do

- ❌ Do not write code during planning — this is a design-only phase.
- ❌ Do not skip reading existing context files before planning.
- ❌ Do not create plans without acceptance criteria.
- ❌ Do not leave scope ambiguous — list affected layers and files explicitly.
- ❌ Do not plan tasks that are too large to implement atomically.
