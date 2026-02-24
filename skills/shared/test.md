---
name: test
description: Use this skill when the user calls @test. Implements the test plan produced by @test-plan, writing all tests following stack conventions and ensuring all scenarios pass.
stack: shared
versions: "SDD 1.x"
---

# @test — Implement the Test Plan

Use this skill when the user invokes `@test`.

## Trigger

```
@test
@test <optional scope override>
```

**Examples:**
```
@test
@test apenas os testes unitários do OrderService
@test pular integration tests por ora
```

---

## Input

1. The test plan from `@test-plan` — read from `.agent/current-test-plan.md` if it exists
2. If no test plan file is found, ask the user to run `@test-plan` first or paste the plan
3. Optional scope overrides passed inline

---

## Context to Read First

Before writing tests:
1. `.agent/current-test-plan.md` — the test plan to execute
2. `.agent/SKILLS.md` — stack and test framework
3. `skills/spring-boot/testing.md` or `skills/dotnet/testing.md` — full testing guide
4. Source files of the classes being tested

---

## Workflow

### Step 1 — Set Up Test Infrastructure (if not already present)

**Spring Boot — verify pom.xml has:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
```

**.NET — verify test projects have:**
```xml
<PackageReference Include="xunit" Version="2.*" />
<PackageReference Include="NSubstitute" Version="5.*" />
<PackageReference Include="FluentAssertions" Version="6.*" />
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.*" />
<PackageReference Include="Testcontainers.PostgreSql" Version="3.*" />
```

### Step 2 — Create Fixtures

Write `*Fixture` or `*Mother` classes for all entities in the plan.

**Spring Boot:**
```java
public class OrderFixture {
    public static Order anyOrder() { return anyOrder(UUID.randomUUID()); }
    public static Order anyOrder(UUID id) {
        Order order = new Order();
        ReflectionTestUtils.setField(order, "id", id);
        ReflectionTestUtils.setField(order, "status", OrderStatus.PENDING);
        // ...
        return order;
    }
}
```

**.NET:**
```csharp
public static class OrderFixture
{
    public static Order AnyPendingOrder() =>
        Order.Create(CustomerFixture.AnyCustomer(), [new OrderItemDto("product-1", 1)]);
}
```

### Step 3 — Write Unit Tests

Follow the plan's unit test table. Each row in the plan becomes one test method.

- Use `@ExtendWith(MockitoExtension.class)` / `Substitute.For<>()` — no Spring context
- Mock all dependencies
- Use `given/when/then` or `arrange/act/assert` structure
- Use fixture classes — no inline entity construction
- Name: `methodName_shouldBehavior_whenCondition`

### Step 4 — Write Slice/Controller Tests

Follow the plan's controller test table.

**Spring Boot (`@WebMvcTest`):**
```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {
    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @MockBean OrderService orderService;

    @Test
    void create_shouldReturn201_whenValid() throws Exception {
        // arrange
        // act + assert
        mockMvc.perform(post("/api/v1/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").exists());
    }
}
```

**.NET (partial `WebApplicationFactory`):**
```csharp
public class OrdersControllerTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Create_ShouldReturn201_WhenValid() { ... }
}
```

### Step 5 — Write Integration Tests

Follow the plan's integration test table. Use Testcontainers for DB.

- Verify that data is actually persisted
- Reset DB state between tests (`@BeforeEach deleteAll` or Respawner)
- Cover the full HTTP request → DB flow

### Step 6 — Run and Fix

After writing all tests:
```bash
# Spring Boot
./mvnw test

# .NET
dotnet test
```

Fix any failures before finishing. Do not leave red tests.

---

## Test Quality Rules

- Every `@Test` / `[Fact]` must have an assertion — no empty tests
- Test only one thing per test method
- No `Thread.sleep()` — use proper async patterns
- No production DB — always use in-memory or Testcontainers
- No `@Disabled` / `[Trait("Skip", "true")]` without a comment explaining why
- Coverage ≥ 80% on Application and Domain layers

---

## What NOT to do

- Do not test private methods directly — test through the public API
- Do not use `@SpringBootTest` for tests that `@WebMvcTest` or plain unit tests can cover
- Do not leave commented-out tests
- Do not use production DB in any test
- Do not mock the class under test itself
- Do not skip writing fixtures — copy-pasted setup is a maintenance problem
