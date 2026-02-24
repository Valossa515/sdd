---
name: review
description: Use this skill when the user calls @review. Performs a structured code review covering architecture, conventions, security, testing, and performance. Returns a prioritized list of findings.
stack: shared
versions: "SDD 1.x"
---

# @review — Structured Code Review

Use this skill when the user invokes `@review`.

## Trigger

```
@review
@review <file or path>
@review <PR description or diff>
```

**Examples:**
```
@review
@review src/main/java/com/example/order/
@review OrderController.java OrderService.java
@review Revisar o PR de checkout que acabei de criar
```

---

## Input

1. Files, paths, or a description of what to review
2. If no input is given, review all recently changed files (`git diff HEAD` or `git diff main`)
3. Optional focus area: `@review segurança`, `@review testes`, `@review performance`

---

## Context to Read First

Before reviewing, read:
1. `.agent/SKILLS.md` — active skills and project overrides
2. `.agent/conventions.md` — project-specific rules
3. The stack skill — for naming, architecture, and antipatterns

---

## Workflow

### Step 1 — Identify Files to Review
- If explicit paths provided: use them
- If not: run `git diff --name-only main` or `git diff HEAD` to find changed files
- Skip generated files, migration files, and lock files

### Step 2 — Run the Review Checklist

Evaluate each file against all relevant sections below.

### Step 3 — Produce the Report

Group findings by severity and provide the output in the format below.

---

## Review Checklist

### Architecture
- [ ] Controllers depend only on Application services — never on repositories directly
- [ ] Domain layer has zero framework dependencies
- [ ] No business logic in controllers or DTOs
- [ ] Dependency direction respected (Api → Application → Domain ← Infrastructure)
- [ ] No circular dependencies between layers

### Naming & Conventions
- [ ] Follows naming conventions from stack skill and `conventions.md`
- [ ] DTOs named `{Resource}Request` / `{Resource}Response`
- [ ] Exceptions named `{Resource}NotFoundException` etc.
- [ ] Test methods follow `methodName_shouldBehavior_whenCondition`

### API Design
- [ ] URL uses plural nouns, kebab-case, no verbs
- [ ] Correct HTTP verbs and status codes (201 for POST, 204 for DELETE)
- [ ] Errors follow RFC 7807 Problem Details
- [ ] Pagination applied to list endpoints
- [ ] OpenAPI annotations present

### Database
- [ ] UUID PK, `created_at`, `updated_at` on every entity
- [ ] No N+1 queries (fetch joins / Include used)
- [ ] Indexes on FK columns and filter columns
- [ ] Migrations versioned and named correctly
- [ ] `readOnly = true` / `AsNoTracking()` on read queries
- [ ] No `SELECT *` or loading full entity when projection suffices

### Transactions
- [ ] `@Transactional` at method level — not class level (Spring)
- [ ] No external API calls inside transactions
- [ ] Single `SaveChangesAsync` call per operation (.NET)

### Security
- [ ] Input validated at request DTO level
- [ ] No user input concatenated into queries
- [ ] No secrets in source code
- [ ] Authorization applied at correct layer
- [ ] Sensitive data not logged

### Error Handling
- [ ] Domain exceptions thrown (not generic `Exception`)
- [ ] Exceptions mapped in global handler — not in controllers
- [ ] No swallowed exceptions (`catch` with empty body or `log and ignore`)
- [ ] External service failures wrapped in application exceptions

### Testing
- [ ] Unit tests present for service/handler logic
- [ ] Controller/slice tests present
- [ ] Mocks used correctly (no real DB in unit tests)
- [ ] Test fixtures use `*Fixture` or `*Mother` classes — no repeated setup
- [ ] Tests cover: happy path, not-found, validation error, auth error

### Performance
- [ ] No loading collections just to count — use `COUNT` query
- [ ] Large datasets paginated
- [ ] No `LIKE '%term%'` on unindexed columns
- [ ] Async all the way down — no `.Result` / `.Wait()` blocking (.NET)

### Code Quality
- [ ] No dead code or commented-out blocks
- [ ] No magic numbers or strings — use constants or enums
- [ ] No `TODO` left from a previous task
- [ ] Constructor injection (not field `@Autowired`)
- [ ] `Optional.get()` never called without `isPresent()` check (Spring)

---

## Output Format

```markdown
# Code Review: <scope>
Date: <YYYY-MM-DD>

## Summary
<1–2 sentences: overall quality and main concerns>

## Critical (must fix before merging)
- [ ] **[File:Line]** Description of the problem. Suggested fix: `code snippet`

## Major (should fix)
- [ ] **[File:Line]** Description. Suggested fix: ...

## Minor (nice to fix)
- [ ] **[File:Line]** Description. Suggested fix: ...

## Positive observations
- What was done well

## Checklist passed (no issues)
- Architecture, Naming, Security (list sections with no issues)
```

---

## What NOT to do

- Do not rewrite entire files — focus on specific issues
- Do not flag style preferences as "Critical"
- Do not approve code with Critical issues present
- Do not skip the Security and Testing sections
- Do not produce a review without concrete file and line references
