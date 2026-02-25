---
name: test
description: Use this skill when the user asks for @test or wants to write tests based on a test plan. It reads the test plan produced by @test-plan and generates all test classes following stack conventions.
stack: shared
versions: "SDD 1.x"
---

# Test — Test Implementation

Use this skill when the user asks for `@test` or wants to write tests for a feature.
This is the **second step** of the test flow: `@test-plan` → `@test`.

## Trigger phrases

- `@test`
- "write the tests"
- "implement tests"
- "create tests for..."
- "add test coverage"

## Goal

Write all test classes defined in a test plan (`.agent/plans/<feature-name>-tests.md`), following the stack-specific testing skill and project conventions, then run the test suite to confirm they pass.

## Workflow

1. **Read the test plan** — load `.agent/plans/<feature-name>-tests.md`.
2. **Read testing skill** — load `spring-boot/testing.md` or `dotnet/testing.md`.
3. **Read project conventions** — load `.agent/SKILLS.md` and `conventions.md`.
4. **Create test fixtures** — build shared test data (builders, factories, fixtures).
5. **Write unit tests** — implement all unit test scenarios from the plan:
   a. Follow naming convention: `methodName_shouldExpectedBehavior_whenCondition`.
   b. Use Arrange-Act-Assert (AAA) pattern.
   c. One assertion focus per test method.
6. **Write integration tests** — implement all integration test scenarios:
   a. Use Testcontainers for database tests.
   b. Use MockMvc (`@WebMvcTest`) or `WebApplicationFactory` for API tests.
   c. Reset database state between tests.
7. **Run the test suite** — execute all tests and verify green.
8. **Update the test plan** — check off completed scenarios.

## Test structure reference

### Spring Boot

```java
@DisplayName("OrderService")
class OrderServiceTest {

    @Test
    @DisplayName("createOrder should return created order when input is valid")
    void createOrder_shouldReturnCreatedOrder_whenInputIsValid() {
        // Arrange
        var command = OrderFixture.validCreateCommand();
        when(repository.save(any())).thenReturn(OrderFixture.savedOrder());

        // Act
        var result = service.createOrder(command);

        // Assert
        assertThat(result.id()).isNotNull();
        assertThat(result.status()).isEqualTo(OrderStatus.PENDING);
    }
}
```

### .NET

```csharp
public class CreateOrderCommandHandlerTests
{
    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_ShouldReturnCreatedOrder_WhenInputIsValid()
    {
        // Arrange
        var command = OrderFixture.ValidCreateCommand();
        _repository.Add(Arg.Any<Order>()).Returns(OrderFixture.SavedOrder());

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Id.Should().NotBeEmpty();
        result.Status.Should().Be(OrderStatus.Pending);
    }
}
```

## Quick command

```text
@test
Execute the test plan in .agent/plans/<feature-name>-tests.md
```

Or without a prior test plan:

```text
@test
Write unit and integration tests for <class/feature>, following the testing skill.
```

## Test quality checklist

```text
✓ Naming follows methodName_shouldBehavior_whenCondition
✓ AAA pattern (Arrange-Act-Assert) in every test
✓ No test depends on another test's state
✓ Integration tests use Testcontainers (not H2/in-memory)
✓ Fixtures are reusable and centralized
✓ Both happy path and error scenarios covered
✓ Edge cases included (null, empty, boundary)
✓ Tests run green before committing
```

## Output quality rules

- Follow the test plan — do not skip scenarios.
- Use the stack-specific testing skill for all patterns and tools.
- Keep tests independent — no shared mutable state.
- Prefer specific assertions (`assertThat(x).isEqualTo(y)`) over generic ones (`assertTrue(x == y)`).
- Name test classes consistently: `<ClassUnderTest>Test` or `<ClassUnderTest>Tests`.

## What NOT to do

- ❌ Do not write tests that depend on execution order.
- ❌ Do not use `Thread.sleep` or arbitrary waits — use `Awaitility` or `async` patterns.
- ❌ Do not mock everything — integration tests must hit real databases via Testcontainers.
- ❌ Do not skip running the test suite after writing tests.
- ❌ Do not ignore failing tests — fix them or flag as `TODO` with justification.
- ❌ Do not write tests without reading the testing skill conventions first.
