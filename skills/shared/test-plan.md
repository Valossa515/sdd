---
name: test-plan
description: Use this skill when the user calls @test-plan. Produces a structured test plan for a feature, covering unit, integration, and contract tests. Output can be consumed by @test.
stack: shared
versions: "SDD 1.x"
---

# @test-plan — Test Plan Generation

Use this skill when the user invokes `@test-plan`.

## Trigger

```
@test-plan
@test-plan <feature or component name>
@test-plan <based on current plan>
```

**Examples:**
```
@test-plan
@test-plan módulo de checkout
@test-plan OrderService — cobertura de cenários de erro
@test-plan baseado no plano atual
```

---

## Input

1. Feature or component to plan tests for
2. If `@planning` was already run: read `.agent/current-plan.md` to base the test plan on it
3. If no input: ask the user what to test

---

## Context to Read First

Before planning:
1. `.agent/current-plan.md` — if a plan exists, base tests on its components
2. `.agent/SKILLS.md` — stack and testing tools
3. `skills/spring-boot/testing.md` or `skills/dotnet/testing.md` — testing conventions
4. `.agent/conventions.md` — naming patterns

---

## Workflow

### Step 1 — List Components to Test
- Identify all classes/methods from the feature scope
- Group by type: domain, service/handler, controller, integration

### Step 2 — Define Scenarios per Component

For each component, define:
- **Happy path** — everything works
- **Not found** — resource doesn't exist
- **Validation error** — invalid input
- **Business rule violation** — domain constraint broken
- **Unauthorized** — missing/invalid auth (if applicable)
- **External dependency failure** — service down, timeout (if applicable)

### Step 3 — Define Test Types

| Test type | What it covers | Tool |
|-----------|---------------|------|
| Unit | Domain logic, service logic in isolation | JUnit5+Mockito / xUnit+NSubstitute |
| Slice | HTTP layer only (controller + validation) | @WebMvcTest / WebApplicationFactory(partial) |
| Integration | Full stack with real DB | @SpringBootTest+Testcontainers / WebApplicationFactory+Testcontainers |

### Step 4 — Write the Plan

Output in the format below.

### Step 5 — Save the Plan
Save to `.agent/current-test-plan.md` so `@test` can consume it.

---

## Output Format

```markdown
# Test Plan: <feature name>
Date: <YYYY-MM-DD>
Stack: <spring-boot | dotnet>

## Summary
<Which components are covered and what test types will be used>

## Unit Tests

### <ClassName>Tests
| Test method | Scenario | Input | Expected |
|-------------|----------|-------|----------|
| `create_shouldReturnOrder_whenValid` | Happy path | Valid request | OrderResponse with PENDING status |
| `create_shouldThrow_whenCustomerNotFound` | Not found | Unknown customerId | CustomerNotFoundException |
| `create_shouldThrow_whenItemListEmpty` | Validation | Empty items list | ValidationException |

## Slice / Controller Tests

### <ControllerName>Tests
| Test method | HTTP | Scenario | Expected status | Expected body |
|-------------|------|----------|-----------------|---------------|
| `create_shouldReturn201_whenValid` | POST /api/v1/... | Happy path | 201 | OrderResponse |
| `create_shouldReturn422_whenBodyInvalid` | POST | Missing required field | 422 | errors array |
| `getById_shouldReturn404_whenNotFound` | GET | ID not found | 404 | Problem Details |

## Integration Tests

### <Feature>IntegrationTests
| Test method | Scenario | Verifies |
|-------------|----------|---------|
| `createOrder_shouldPersistAndReturn201` | Full happy path | DB record + response |
| `createOrder_shouldReturn409_whenDuplicate` | Conflict | No duplicate created |

## Coverage Goals
- Domain / Application layer: ≥ 80%
- Controllers: happy path + main error paths
- Integration: at least 1 per main flow

## Fixtures Needed
- `OrderFixture.anyOrder()` — pre-built Order entity
- `CreateOrderRequestFixture.valid()` — valid request
- `CreateOrderRequestFixture.withEmptyItems()` — invalid request
```

---

## What NOT to do

- Do not write test code — this skill only plans
- Do not plan only happy paths — error scenarios are mandatory
- Do not plan tests without a clear component list
- Do not use integration tests for logic that unit tests can cover
- Do not skip fixture definitions — they are part of the plan
