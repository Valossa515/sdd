---
name: implementation
description: Use this skill when the user calls @implementation. Implements the technical plan produced by @planning, following all active project skills and conventions.
stack: shared
versions: "SDD 1.x"
---

# @implementation — Implement the Plan

Use this skill when the user invokes `@implementation`.

## Trigger

```
@implementation
@implementation <optional override or additional context>
```

**Examples:**
```
@implementation
@implementation usar UUID v7 em vez de UUID v4 para os IDs
@implementation ignorar o passo de migrations, o DB já existe
```

---

## Input

1. The plan produced by `@planning` — read from `.agent/current-plan.md` if it exists
2. If no plan file is found, ask the user to run `@planning` first or paste the plan
3. Optional overrides passed inline

---

## Context to Read First

Before implementing, read:
1. `.agent/current-plan.md` — the plan to execute
2. `.agent/SKILLS.md` — active skills (stack, versions, conventions)
3. The stack skill (`skills/spring-boot/SKILL.md` or `skills/dotnet/SKILL.md`)
4. `skills/shared/api-design.md` — REST conventions
5. `skills/shared/database.md` — DB patterns
6. `skills/shared/error-handling.md` — exception patterns
7. `skills/shared/security.md` — if auth/input validation is in scope

---

## Workflow

Follow the implementation steps from the plan **in order**. For each step:

### Step 1 — DB Migration (if needed)
- Create migration file following naming convention from `database.md`
- Never use `ddl-auto: create` or `auto-migrate`
- Add indexes for FKs and query columns

### Step 2 — Domain Layer
- Create entity with UUID PK, `created_at`, `updated_at`
- Use factory methods — no public constructors on domain objects
- Define repository interface (Spring: in `domain/repository/`, .NET: `I{Resource}Repository`)

### Step 3 — Application Layer
- Implement service/handler following conventions:
  - Spring Boot: `@Service`, `@Transactional` per method
  - .NET: `IRequestHandler<TCommand, TResponse>` + MediatR
- Add input validation (Bean Validation or FluentValidation)
- Throw domain exceptions (`NotFoundException`, `ConflictException`) — never generic `Exception`

### Step 4 — Infrastructure Layer
- Implement repository adapter (Spring: `JpaXRepository`, .NET: `XRepository`)
- Apply N+1 prevention (fetch joins or Include)
- Use projections for read-only queries

### Step 5 — API Layer
- Create controller following `api-design.md` and stack skill conventions
- Return proper HTTP status codes
- Map exceptions via global handler — never catch in controllers

### Step 6 — Tests
- Write unit tests for service/handler (mock dependencies)
- Write controller/slice tests
- Write integration test if the plan requires it
- Follow naming convention: `methodName_shouldBehavior_whenCondition`

### Step 7 — Review
After implementing, verify:
- [ ] Follows naming conventions from `conventions.md`
- [ ] Uses constructor injection (not field injection)
- [ ] No business logic in controllers
- [ ] All error paths handled
- [ ] Tests cover happy path and main error paths

---

## Rules

- Implement **exactly what is in the plan** — no extra features
- If the plan is ambiguous for a step, note it with a `// TODO:` comment and continue
- If a step is blocked (e.g., missing dependency), stop and report to the user
- Never skip tests — if time-constrained, implement at minimum one unit test and one integration test

---

## What NOT to do

- Do not add features beyond what the plan describes
- Do not refactor code that is not in the plan's scope
- Do not use field `@Autowired` — always constructor injection
- Do not return domain entities from controllers — always DTOs
- Do not commit secrets or hardcoded credentials
- Do not skip DB migration if the plan requires schema changes
