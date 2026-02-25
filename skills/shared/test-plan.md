---
name: test-plan
description: Use this skill when the user asks for @test-plan or wants to design a testing strategy before writing tests. It produces a structured test plan that feeds into @test.
stack: shared
versions: "SDD 1.x"
---

# Test Plan — Testing Strategy Design

Use this skill when the user asks for `@test-plan` or wants to design a testing strategy.
This is the **first step** of the test flow: `@test-plan` → `@test`.

## Trigger phrases

- `@test-plan`
- "plan the tests"
- "design test strategy"
- "what should we test?"
- "create a test plan for..."

## Goal

Produce a structured **test plan document** (`.agent/plans/<feature-name>-tests.md`) that defines what to test, at which level, and with what data — so the test writing phase is systematic and complete.

## Workflow

1. **Read the feature context** — load the implementation plan or review the implemented code.
2. **Read testing skill** — load the stack-specific testing skill (`spring-boot/testing.md` or `dotnet/testing.md`).
3. **Identify test categories**:
   - **Unit tests**: domain logic, services, validators, mappers.
   - **Integration tests**: API endpoints, database queries, external services.
   - **Edge cases**: null inputs, empty collections, boundary values, concurrency.
4. **Define test scenarios** — for each category, list concrete test cases.
5. **Specify test data** — describe fixtures, builders, or factories needed.
6. **List infrastructure needs** — Testcontainers, mocks, stubs, in-memory databases.
7. **Save the test plan** — write to `.agent/plans/<feature-name>-tests.md`.

## Test plan template

```markdown
# Test Plan: <Feature Name>

## Scope
Brief description of what is being tested.

## Unit tests

### <Class/Service under test>
| # | Scenario | Method | Expected result |
|---|----------|--------|-----------------|
| 1 | Valid input | createOrder | Returns created order |
| 2 | Missing required field | createOrder | Throws ValidationException |
| 3 | Duplicate entry | createOrder | Throws ConflictException |

## Integration tests

### <Endpoint / Flow under test>
| # | Scenario | Method | Endpoint | Expected status |
|---|----------|--------|----------|-----------------|
| 1 | Create order | POST | /api/v1/orders | 201 Created |
| 2 | Get non-existent | GET | /api/v1/orders/{id} | 404 Not Found |
| 3 | Invalid payload | POST | /api/v1/orders | 422 Unprocessable |

## Edge cases
- Empty list handling
- Concurrent modification
- Maximum payload size

## Test data & fixtures
- OrderFixture: valid order with 2 items
- CustomerFixture: active customer with address

## Infrastructure
- Testcontainers PostgreSQL for integration tests
- MockMvc / WebApplicationFactory for controller tests
- Mocked external service clients
```

## Quick command

```text
@test-plan
Plan tests for the feature: <describe feature or point to plan>
```

## Coverage targets

- **Domain logic**: 90%+ line coverage on business rules.
- **API endpoints**: every success and error status code documented in the plan.
- **Validations**: every validation rule must have a test.
- **Edge cases**: null, empty, boundary, and concurrent scenarios.

## Output quality rules

- Every test scenario must be concrete — "test validation" is too vague; "test that empty customerId returns 422" is correct.
- Reference the testing skill for naming conventions and patterns.
- Include both happy path and failure scenarios for every operation.
- Mark uncertain scenarios as `TODO` for team review.

## Handoff to @test

After the test plan is reviewed, use:

```text
@test
Execute the test plan in .agent/plans/<feature-name>-tests.md
```

The `@test` skill reads the plan and writes all test classes.

## What NOT to do

- ❌ Do not write test code during planning — this is strategy only.
- ❌ Do not plan tests without reading the implementation first.
- ❌ Do not skip edge cases and only test the happy path.
- ❌ Do not leave test scenarios vague — each must have expected input and output.
- ❌ Do not ignore the stack-specific testing skill conventions.
