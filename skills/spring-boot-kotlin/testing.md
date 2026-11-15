---
name: spring-boot-kotlin-testing
description: Testing guide for Spring Boot projects in Kotlin. Unit tests with MockK, controller slice tests with the MockMvc Kotlin DSL, and Testcontainers integration tests.
stack: spring-boot-kotlin
versions: "Kotlin 2.2+, Spring Boot 4.x, JUnit Jupiter, MockK, springmockk 5, Testcontainers 2"
---

# Spring Boot + Kotlin Testing

## Dependencies (build.gradle.kts)

```kotlin
dependencies {
    testImplementation("org.springframework.boot:spring-boot-starter-webmvc-test") {
        exclude(module = "mockito-core")          // MockK replaces Mockito
    }
    testImplementation("org.springframework.boot:spring-boot-resttestclient")   // RestTestClient auto-configuration
    testImplementation("io.mockk:mockk:1.x.x")
    testImplementation("com.ninja-squad:springmockk:5.x.x")   // @MockkBean / @MockkSpyBean — 5.x is the Spring Boot 4 line
    testImplementation("org.springframework.boot:spring-boot-testcontainers")
    testImplementation("org.testcontainers:testcontainers-junit-jupiter")    // Testcontainers 2 artifact names
    testImplementation("org.testcontainers:testcontainers-postgresql")
}

tasks.withType<Test> { useJUnitPlatform() }
```

MockK is used instead of Mockito because Kotlin classes are `final` by default, and MockK also mocks `suspend` functions and top-level/extension functions.

---

## Unit Tests — Service Layer

No Spring context. Fast, isolated. Mock all dependencies with MockK.

```kotlin
class OrderServiceTest {

    private val orderRepository = mockk<OrderRepository>()
    private val customerRepository = mockk<CustomerRepository>()
    private val orderService = OrderService(orderRepository, customerRepository)

    @Test
    fun `findById returns the order when it exists`() {
        // Arrange
        val order = anOrder()
        every { orderRepository.findById(order.id) } returns order

        // Act
        val response = orderService.findById(order.id)

        // Assert
        assertThat(response.id).isEqualTo(order.id)
        assertThat(response.status).isEqualTo(OrderStatus.PENDING)
    }

    @Test
    fun `findById throws when the order does not exist`() {
        val id = UUID.randomUUID()
        every { orderRepository.findById(id) } returns null

        assertThatThrownBy { orderService.findById(id) }
            .isInstanceOf(OrderNotFoundException::class.java)
            .hasMessageContaining(id.toString())
    }

    @Test
    fun `create saves the order once`() {
        val customer = aCustomer()
        every { customerRepository.findById(customer.id) } returns customer
        every { orderRepository.save(any()) } answers { firstArg() }

        orderService.create(aCreateOrderRequest(customerId = customer.id.toString()))

        verify(exactly = 1) { orderRepository.save(any()) }
    }
}
```

For `suspend` functions use `coEvery`/`coVerify` and run the test body in `runTest { }` from `kotlinx-coroutines-test`.

---

## Controller Tests — @WebMvcTest

Loads only the web layer. Mock the service with `@MockkBean`. Use the MockMvc **Kotlin DSL** (`mockMvc.get { }`), not the Java builder chain.

```kotlin
@WebMvcTest(OrderController::class)
class OrderControllerTest(
    @Autowired private val mockMvc: MockMvc,
    @Autowired private val objectMapper: ObjectMapper,
) {

    @MockkBean
    private lateinit var orderService: OrderService

    @Test
    fun `GET order returns 200 when it exists`() {
        val id = UUID.randomUUID()
        every { orderService.findById(id) } returns anOrderResponse(id)

        mockMvc.get("/api/v1/orders/{id}", id)
            .andExpect {
                status { isOk() }
                jsonPath("$.id") { value(id.toString()) }
                jsonPath("$.status") { value("PENDING") }
            }
    }

    @Test
    fun `POST order returns 422 when the body is invalid`() {
        val invalid = CreateOrderRequest(customerId = "", items = emptyList())

        mockMvc.post("/api/v1/orders") {
            contentType = MediaType.APPLICATION_JSON
            content = objectMapper.writeValueAsString(invalid)
        }.andExpect {
            status { isUnprocessableEntity() }
            jsonPath("$.errors") { isArray() }
        }
    }
}
```

`"$.id"` is fine in a Kotlin string because `$` followed by `.` is not a template; write `"\$name"` when a JSON path segment starts with a letter right after `$`.

---

## Integration Tests — Testcontainers

Full Spring context with a real database, called over HTTP with `RestTestClient`. In Kotlin the container lives in a `companion object` with `@JvmStatic`, so JUnit sees it as static.

```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureRestTestClient
@Testcontainers
@ActiveProfiles("test")
class OrderIntegrationTest(
    @Autowired private val client: RestTestClient,
    @Autowired private val jpaOrderRepository: JpaOrderRepository,
) {

    companion object {
        @Container
        @ServiceConnection
        @JvmStatic
        val postgres = PostgreSQLContainer("postgres:16-alpine")   // org.testcontainers.postgresql, no type argument in 2.x
    }

    @BeforeEach
    fun setUp() = jpaOrderRepository.deleteAll()

    @Test
    fun `POST order persists it and returns 201`() {
        val request = aCreateOrderRequest()

        val body = client.post().uri("/api/v1/orders")
            .contentType(MediaType.APPLICATION_JSON)
            .body(request)
            .exchange()
            .expectStatus().isCreated()
            .expectBody(OrderResponse::class.java)
            .returnResult()
            .responseBody

        assertThat(jpaOrderRepository.findByIdOrNull(requireNotNull(body).id)).isNotNull()
    }
}
```

`@ServiceConnection` configures the datasource from the container — no manual property override needed. Boot 4 no longer gives `@SpringBootTest` an HTTP client or `MockMvc` by itself: add `@AutoConfigureRestTestClient` or `@AutoConfigureMockMvc`.

---

## Test Fixtures

Use top-level factory functions with **default arguments** instead of `*Fixture` classes or builders — each test overrides only what it cares about.

```kotlin
// src/test/kotlin/com/example/app/fixtures/OrderFixtures.kt
fun aCreateOrderRequest(
    customerId: String = UUID.randomUUID().toString(),
    items: List<OrderItemRequest> = listOf(OrderItemRequest(productId = "product-1", quantity = 2)),
) = CreateOrderRequest(customerId = customerId, items = items)

fun anOrderResponse(
    id: UUID = UUID.randomUUID(),
    status: OrderStatus = OrderStatus.PENDING,
) = OrderResponse(
    id = id,
    customerId = "customer-test",
    status = status,
    items = emptyList(),
    total = BigDecimal.TEN,
    createdAt = Instant.now(),
)
```

For entities whose constructor is protected, build them through the domain's factory method (`Order.create(...)`) rather than reflection.

---

## Naming Convention for Tests

Use backtick names that read as a sentence: `` `<unit> <does what> when <condition>` ``.

```
`findById returns the order when it exists`
`create throws when the customer does not exist`
`DELETE order returns 204 when it was deleted`
```

---

## Test Configuration

```yaml
# src/test/resources/application-test.yml
spring:
  jpa:
    show-sql: false
  flyway:
    enabled: true   # run migrations in tests too
logging:
  level:
    org.springframework: WARN
    com.example: DEBUG
```

---

## What NOT to do

- ❌ Mockito / `@MockBean` (removed in Spring Boot 4) — use MockK and `@MockkBean`; `@SpykBean` is now `@MockkSpyBean`
- ❌ `@SpringBootTest` for logic a plain unit test can cover
- ❌ H2 instead of PostgreSQL in integration tests — use Testcontainers
- ❌ Building entities through reflection — use the domain factory methods
- ❌ `Thread.sleep` to wait for async work — use `runTest`, Awaitility or a test clock
