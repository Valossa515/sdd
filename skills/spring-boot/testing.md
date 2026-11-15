---
name: spring-boot-testing
description: Testing guide for Spring Boot projects. Unit tests, integration tests, controller slice tests, and Testcontainers setup.
stack: spring-boot
versions: "Java 21+, Spring Boot 4.x, JUnit Jupiter, Testcontainers 2"
---

# Spring Boot Testing

## Dependencies (add to pom.xml)

```xml
<!-- MockMvc, @WebMvcTest; brings spring-boot-starter-test (JUnit, AssertJ, Mockito) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webmvc-test</artifactId>
    <scope>test</scope>
</dependency>
<!-- RestTestClient / TestRestTemplate auto-configuration -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-resttestclient</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-testcontainers</artifactId>
    <scope>test</scope>
</dependency>
<!-- Testcontainers 2: every module artifact is prefixed with testcontainers- -->
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>testcontainers-junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>testcontainers-postgresql</artifactId>
    <scope>test</scope>
</dependency>
```

---

## Unit Tests — Service Layer

No Spring context. Fast, isolated. Mock all dependencies.

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    @Test
    void findById_shouldReturnOrder_whenExists() {
        // Arrange
        UUID id = UUID.randomUUID();
        Order order = OrderFixture.anyOrder(id);
        given(orderRepository.findById(id)).willReturn(Optional.of(order));

        // Act
        OrderResponse response = orderService.findById(id);

        // Assert
        assertThat(response.id()).isEqualTo(id);
        assertThat(response.status()).isEqualTo(OrderStatus.PENDING);
    }

    @Test
    void findById_shouldThrow_whenNotFound() {
        UUID id = UUID.randomUUID();
        given(orderRepository.findById(id)).willReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.findById(id))
            .isInstanceOf(OrderNotFoundException.class)
            .hasMessageContaining(id.toString());
    }
}
```

---

## Controller Tests — @WebMvcTest

Loads only the web layer. Mock the service with `@MockitoBean` (Spring Framework's bean override — Boot's `@MockBean` was removed in Spring Boot 4).

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private OrderService orderService;

    @Test
    void getById_shouldReturn200_whenOrderExists() throws Exception {
        UUID id = UUID.randomUUID();
        OrderResponse response = OrderFixture.anyOrderResponse(id);
        given(orderService.findById(id)).willReturn(response);

        mockMvc.perform(get("/api/v1/orders/{id}", id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id.toString()))
            .andExpect(jsonPath("$.status").value("PENDING"));
    }

    @Test
    void create_shouldReturn422_whenBodyInvalid() throws Exception {
        CreateOrderRequest invalid = new CreateOrderRequest("", List.of());

        mockMvc.perform(post("/api/v1/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalid)))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.errors").isArray());
    }
}
```

---

## Integration Tests — Testcontainers

Full Spring context with real database, called over HTTP with `RestTestClient` (Spring Framework 7). Boot 4 no longer auto-configures a client for `@SpringBootTest` — `@AutoConfigureRestTestClient` adds it.

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureRestTestClient
@Testcontainers
@ActiveProfiles("test")
class OrderIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16-alpine");   // org.testcontainers.postgresql

    @Autowired
    private RestTestClient client;

    @Autowired
    private OrderRepository orderRepository;

    @BeforeEach
    void setUp() {
        orderRepository.deleteAll();
    }

    @Test
    void createOrder_shouldPersistAndReturn201() {
        CreateOrderRequest request = new CreateOrderRequest(
            "customer-123",
            List.of(new OrderItemRequest("product-1", 2))
        );

        OrderResponse body = client.post().uri("/api/v1/orders")
            .contentType(MediaType.APPLICATION_JSON)
            .body(request)
            .exchange()
            .expectStatus().isCreated()
            .expectBody(OrderResponse.class)
            .returnResult()
            .getResponseBody();

        assertThat(body).isNotNull();
        assertThat(orderRepository.findById(body.id())).isPresent();
    }
}
```

Notes:
- `@ServiceConnection` configures the datasource from the container — no manual property override needed
- Testcontainers 2 moved `PostgreSQLContainer` to `org.testcontainers.postgresql` and dropped its generic type parameter
- A `@SpringBootTest` that injects `MockMvc` needs `@AutoConfigureMockMvc` — Boot 4 no longer adds it

---

## Migrating tests from Spring Boot 3

| Spring Boot 3 | Spring Boot 4 |
|---------------|---------------|
| `@MockBean` / `@SpyBean` | `@MockitoBean` / `@MockitoSpyBean` (test-class fields only, not `@Configuration` classes) |
| `TestRestTemplate` injected by `@SpringBootTest` | `RestTestClient` + `@AutoConfigureRestTestClient` (or `@AutoConfigureTestRestTemplate` to keep `TestRestTemplate`) |
| `MockMvc` injected by `@SpringBootTest` | add `@AutoConfigureMockMvc` |
| `spring-boot-starter-test` | the technology's test starter, e.g. `spring-boot-starter-webmvc-test` |
| `org.testcontainers:postgresql`, `PostgreSQLContainer<?>` | `org.testcontainers:testcontainers-postgresql`, `org.testcontainers.postgresql.PostgreSQLContainer` |

---

## Test Fixtures

Create a `*Fixture` or `*Mother` class per domain object to avoid repeated test setup.

```java
public class OrderFixture {

    public static Order anyOrder() {
        return anyOrder(UUID.randomUUID());
    }

    public static Order anyOrder(UUID id) {
        Order order = new Order();
        ReflectionTestUtils.setField(order, "id", id);
        ReflectionTestUtils.setField(order, "customerId", "customer-test");
        ReflectionTestUtils.setField(order, "status", OrderStatus.PENDING);
        ReflectionTestUtils.setField(order, "createdAt", Instant.now());
        return order;
    }

    public static OrderResponse anyOrderResponse(UUID id) {
        return new OrderResponse(id, "customer-test", OrderStatus.PENDING, List.of(), BigDecimal.TEN, Instant.now());
    }
}
```

---

## Naming Convention for Tests

```
methodName_shouldExpectedBehavior_whenCondition

Examples:
  findById_shouldReturnOrder_whenExists
  create_shouldThrowException_whenCustomerNotFound
  delete_shouldReturn204_whenOrderDeleted
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
