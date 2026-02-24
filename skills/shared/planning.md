---
name: planning
description: Use this skill when the user calls @planning. Produces a structured technical plan for a feature or change before any code is written. Outputs a plan that can be consumed by @implementation.
stack: shared
versions: "SDD 1.x"
---

# @planning — Technical Planning

Use this skill when the user invokes `@planning`.

## Trigger

```
@planning <feature or change description>
```

**Examples:**
```
@planning Preciso de um módulo de checkout com pagamento assíncrono via Stripe
@planning Adicionar autenticação OAuth2 com Google no projeto
@planning Refatorar o módulo de orders para suportar multi-tenancy
```

---

## Input

The user provides:
- A short description of the feature, change, or problem to solve
- Optionally: constraints, deadlines, or technical preferences

If the description is vague, **ask 1–3 clarifying questions** before planning:
- What is the expected input/output?
- Are there external dependencies (APIs, queues, DB)?
- What scope? (new feature / change existing / migration)

---

## Context to Read First

Before planning, read the following from `.agent/`:
1. `SKILLS.md` — active skills and project overrides
2. `architecture.md` — existing layers and boundaries
3. `context.md` — domain and business rules
4. `conventions.md` — project-specific naming and patterns

---

## Workflow

Follow these steps in order:

### Step 1 — Understand the Scope
- Identify which layer(s) are affected (API, Application, Domain, Infrastructure)
- List external dependencies (DB tables, external services, auth)
- Identify risks and unknowns

### Step 2 — Define the Components
- List all files/classes to be created or changed
- Group by layer
- Flag any new DB migrations needed

### Step 3 — Define the API Contract (if applicable)
- HTTP method, path, request body, response body
- Status codes and error scenarios
- Follow `api-design.md` conventions

### Step 4 — Write the Plan
Output the plan in the format below.

### Step 5 — Save the Plan
Save the output to `.agent/current-plan.md` so `@implementation` can consume it.

---

## Output Format

Produce a plan in this exact structure:

```markdown
# Plan: <feature name>
Date: <YYYY-MM-DD>

## Summary
<2–3 sentences describing what will be built and why>

## Scope
- **Stack**: <spring-boot | dotnet>
- **Layers affected**: <API / Application / Domain / Infrastructure>
- **New migrations**: <yes/no — list tables if yes>
- **External dependencies**: <list or none>

## API Contract
| Method | Path | Request | Response | Status |
|--------|------|---------|----------|--------|
| POST | /api/v1/... | `CreateXRequest` | `XResponse` | 201 |

## Components

### New files
- `api/controller/XController.java` — handles HTTP layer
- `application/service/XService.java` — business logic
- `domain/model/X.java` — entity
- `domain/repository/XRepository.java` — port interface
- `infrastructure/persistence/JpaXRepository.java` — adapter

### Modified files
- `XExistingClass` — reason for change

### DB Migrations
- `V{n}__create_x_table.sql`

## Implementation Steps
1. Create DB migration
2. Create domain entity and repository interface
3. Implement service
4. Implement controller
5. Write unit tests for service
6. Write controller tests
7. Write integration test

## Risks and Decisions
- [Risk or open question]

## Out of Scope
- [What will NOT be done in this task]
```

---

## What NOT to do

- Do not start writing code — this skill only plans
- Do not skip the context reading step (architecture.md, conventions.md)
- Do not produce a plan without at least a component list and implementation steps
- Do not assume the stack — confirm from SKILLS.md or ask the user
- Do not plan without considering existing conventions (naming, error handling, testing)
