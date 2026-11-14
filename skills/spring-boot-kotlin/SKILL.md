---
name: spring-boot-kotlin
description: Use this skill for any Spring Boot task written in Kotlin — APIs, services, repositories, config, tests, or refactoring. Targets Spring Boot 3.x with Kotlin 2.x on JVM 21.
stack: spring-boot-kotlin
versions: "Kotlin 2.x, JVM 21, Spring Boot 3.x, Gradle Kotlin DSL"
---

# Spring Boot + Kotlin Agent Skill

You are an expert Spring Boot engineer writing idiomatic Kotlin. Follow these guidelines for every task in this project. The architecture is the same as a Java Spring Boot project; what changes is how Kotlin expresses it — null-safety, data classes, final-by-default classes and use-site annotation targets.

## Stack Versions (always target these unless told otherwise)

- **Kotlin**: 2.x, JVM target 21
- **Spring Boot**: 3.x (Jakarta EE namespace, not `javax`)
- **Build tool**: Gradle with Kotlin DSL (`build.gradle.kts`)
- **Database**: PostgreSQL via Spring Data JPA + Hibernate 6, migrations with Flyway
- **JSON**: Jackson with `jackson-module-kotlin`

### Required Gradle plugins

```kotlin
// build.gradle.kts
plugins {
    kotlin("jvm") version "2.x.x"
    kotlin("plugin.spring") version "2.x.x"   // opens @Component/@Service/@Transactional classes for proxies
    kotlin("plugin.jpa") version "2.x.x"      // generates the no-arg constructors JPA needs
    id("org.springframework.boot") version "3.x.x"
    id("io.spring.dependency-management") version "1.x.x"
}

allOpen {
    // JPA entities must be open for lazy-loading proxies
    annotation("jakarta.persistence.Entity")
    annotation("jakarta.persistence.MappedSuperclass")
    annotation("jakarta.persistence.Embeddable")
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")   // Spring's nullability annotations become Kotlin types
    }
}
```

Without `plugin.spring` and the `allOpen` block, Spring proxies and Hibernate lazy loading silently stop working, because Kotlin classes are `final` by default.

---

## Architecture

Follow **Layered Architecture** with a lean toward **Hexagonal (Ports & Adapters)** for domain-heavy modules.

```
src/main/kotlin/com/example/app/
├── api/                   ← Controllers, DTOs (adapters in)
│   ├── controller/
│   └── dto/
├── application/           ← Use cases / application services
│   └── service/
├── domain/                ← Entities, value objects, domain services
│   ├── model/
│   ├── repository/        ← Interfaces (ports)
│   └── exception/
└── infrastructure/        ← JPA repos, external clients (adapters out)
    ├── persistence/
    └── client/
```

**Rules:**
- Controllers depend on application services only — never on repositories directly
- Domain layer has **zero** Spring dependencies
- Use interfaces in `domain/repository/`, implement in `infrastructure/persistence/`
- One top-level class per file, file named after the class; small related types (a sealed hierarchy, a DTO and its nested items) may share a file

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Controller | `{Resource}Controller` | `OrderController` |
| Service | `{Resource}Service` (a concrete class; add an interface only when there are several implementations) | `OrderService` |
| Repository (port) | `{Resource}Repository` | `OrderRepository` |
| JPA repository | `Jpa{Resource}Repository` | `JpaOrderRepository` |
| Port implementation | `{Resource}RepositoryAdapter` | `OrderRepositoryAdapter` |
| DTO (request) | `{Action}{Resource}Request` | `CreateOrderRequest` |
| DTO (response) | `{Resource}Response` | `OrderResponse` |
| Exception | `{Resource}NotFoundException` | `OrderNotFoundException` |
| Extension functions | `{Type}Extensions.kt` | `OrderExtensions.kt` |

---

## REST Controllers

Constructor injection through the primary constructor. Prefer `ResponseEntity<T>` for explicit status control.

```kotlin
@RestController
@RequestMapping("/api/v1/orders")
@Tag(name = "Orders", description = "Order management")
class OrderController(
    private val orderService: OrderService,
) {

    @GetMapping("/{id}")
    fun findById(@PathVariable id: UUID): ResponseEntity<OrderResponse> =
        ResponseEntity.ok(orderService.findById(id))

    @PostMapping
    fun create(@RequestBody @Valid request: CreateOrderRequest): ResponseEntity<OrderResponse> {
        val response = orderService.create(request)
        return ResponseEntity.created(URI.create("/api/v1/orders/${response.id}")).body(response)
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: UUID): ResponseEntity<Unit> {
        orderService.delete(id)
        return ResponseEntity.noContent().build()
    }
}
```

---

## DTOs

Use **data classes** for DTOs. Bean Validation annotations need the `@field:` use-site target — without it, Kotlin puts the annotation on the constructor parameter and **validation never runs**.

```kotlin
data class CreateOrderRequest(
    @field:NotBlank val customerId: String,
    @field:NotEmpty @field:Valid val items: List<OrderItemRequest>,
)

data class OrderItemRequest(
    @field:NotBlank val productId: String,
    @field:Positive val quantity: Int,
)

data class OrderResponse(
    val id: UUID,
    val customerId: String,
    val status: OrderStatus,
    val items: List<OrderItemResponse>,
    val total: BigDecimal,
    val createdAt: Instant,
) {
    companion object {
        fun from(order: Order) = OrderResponse(
            id = order.id,
            customerId = order.customerId,
            status = order.status,
            items = order.items.map(OrderItemResponse::from),
            total = order.total,
            createdAt = order.createdAt,
        )
    }
}
```

Nullable types (`String?`) mean "optional in the request". Non-null types without a default are required — Jackson's Kotlin module rejects a missing value with a 400.

---

## Service Layer

Services hold business logic. Use `@Transactional` at method level, not class level. Handle "not found" with the Elvis operator, not `Optional`.

```kotlin
@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val customerRepository: CustomerRepository,
) {

    @Transactional(readOnly = true)
    fun findById(id: UUID): OrderResponse =
        orderRepository.findById(id)?.let(OrderResponse::from)
            ?: throw OrderNotFoundException(id)

    @Transactional
    fun create(request: CreateOrderRequest): OrderResponse {
        val customer = customerRepository.findById(UUID.fromString(request.customerId))
            ?: throw CustomerNotFoundException(request.customerId)

        val order = Order.create(customer, request.items)
        return OrderResponse.from(orderRepository.save(order))
    }
}
```

---

## Repositories

The domain port returns nullable types and has no Spring types; the JPA adapter implements it with Spring Data's `findByIdOrNull`.

```kotlin
// domain/repository/OrderRepository.kt — port, zero Spring dependencies
interface OrderRepository {
    fun findById(id: UUID): Order?
    fun save(order: Order): Order
}

// infrastructure/persistence/JpaOrderRepository.kt
interface JpaOrderRepository : JpaRepository<Order, UUID>

@Repository
class OrderRepositoryAdapter(
    private val jpa: JpaOrderRepository,
) : OrderRepository {
    override fun findById(id: UUID): Order? = jpa.findByIdOrNull(id)
    override fun save(order: Order): Order = jpa.save(order)
}
```

### Coroutines

Spring MVC with JPA is blocking — keep services as plain functions. Use `suspend` functions only when the project already runs on WebFlux with R2DBC or another non-blocking driver; never call JPA from a coroutine without `withContext(Dispatchers.IO)`.

---

## Entities

JPA entities are **regular classes, never data classes**: a data class's generated `equals`/`hashCode`/`toString` touches lazy collections and changes when the generated id is assigned. Base equality on the id.

```kotlin
@Entity
@Table(name = "orders")
class Order protected constructor() {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    lateinit var id: UUID
        protected set

    @Column(nullable = false)
    lateinit var customerId: String
        protected set

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: OrderStatus = OrderStatus.PENDING
        protected set

    @OneToMany(mappedBy = "order", cascade = [CascadeType.ALL], orphanRemoval = true)
    var items: MutableList<OrderItem> = mutableListOf()
        protected set

    @Column(nullable = false, updatable = false)
    var createdAt: Instant = Instant.now()
        protected set

    val total: BigDecimal
        get() = items.fold(BigDecimal.ZERO) { acc, item -> acc + item.subtotal }

    override fun equals(other: Any?): Boolean =
        this === other || (other is Order && this::id.isInitialized && other::id.isInitialized && id == other.id)

    override fun hashCode(): Int = javaClass.hashCode()

    companion object {
        // Factory method — avoid public constructors in domain objects
        fun create(customer: Customer, itemRequests: List<OrderItemRequest>): Order =
            Order().apply {
                customerId = customer.id.toString()
                // map items...
            }
    }
}
```

- Persistent state is `var ... protected set`: Hibernate assigns fields by reflection when loading, and only the entity itself changes them
- Keep JPA annotations on class-body properties, not on primary-constructor parameters, where Kotlin's annotation targeting is easy to get wrong
- Collections are `MutableList` internally; expose `List` from DTOs, never the entity

---

## Exception Handling

Use a single `@RestControllerAdvice` returning Spring 6's `ProblemDetail` (RFC 7807).

```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {

    private val log = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(EntityNotFoundException::class)
    fun handleNotFound(ex: EntityNotFoundException): ResponseEntity<ProblemDetail> =
        ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.message))

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(ex: MethodArgumentNotValidException): ResponseEntity<ProblemDetail> {
        val problem = ProblemDetail.forStatus(HttpStatus.UNPROCESSABLE_ENTITY).apply {
            title = "Validation failed"
            setProperty("errors", ex.bindingResult.fieldErrors.map { mapOf("field" to it.field, "message" to it.defaultMessage) })
        }
        return ResponseEntity.unprocessableEntity().body(problem)
    }

    @ExceptionHandler(Exception::class)
    fun handleGeneral(ex: Exception): ResponseEntity<ProblemDetail> {
        log.error("Unexpected error", ex)
        return ResponseEntity.internalServerError()
            .body(ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred"))
    }
}
```

Model domain errors as a small hierarchy (`sealed class DomainException`) so the advice maps each subtype once.

---

## Configuration

Use typed `@ConfigurationProperties` data classes — never `@Value` for groups of related properties. Constructor binding is the default in Spring Boot 3.

```kotlin
@ConfigurationProperties(prefix = "app.payment")
data class PaymentProperties(
    val apiUrl: String,
    val apiKey: String,
    val timeout: Duration = Duration.ofSeconds(5),
    val maxRetries: Int = 3,
)
```

```yaml
# application.yml
app:
  payment:
    api-url: https://api.payment.com
    api-key: ${PAYMENT_API_KEY}
    timeout: 5s
    max-retries: 3
```

Enable with `@ConfigurationPropertiesScan` on the application class.

---

## Logging

Use SLF4J through a per-class logger (`private val log = LoggerFactory.getLogger(javaClass)`), or `io.github.oshai:kotlin-logging` if the project already uses it. Pass values as placeholders (`log.info("Order created orderId={}", id)`), not string templates — the template is built even when the level is off.

---

## Testing

See `testing.md` for full testing guide. Quick rules:

- Unit tests: JUnit 5 + **MockK** (not Mockito — it can't mock final Kotlin classes without extra setup), no Spring context
- Controller tests: `@WebMvcTest` + MockMvc Kotlin DSL + `@MockkBean` (springmockk)
- Integration tests: `@SpringBootTest` + Testcontainers for DB
- **Minimum coverage**: 80% on `application/` and `domain/`

---

## What NOT to do

- ❌ `!!` — handle null with `?.`, `?:`, `requireNotNull` or `checkNotNull` and a message
- ❌ `@Autowired lateinit var` — always primary-constructor injection
- ❌ Data classes as JPA entities
- ❌ Validation annotations without `@field:` on DTO properties
- ❌ `Optional` in Kotlin code — use nullable types (`findByIdOrNull` in the JPA adapter)
- ❌ Business logic in controllers
- ❌ `@Transactional` on the whole class
- ❌ `String` as primary key — use `UUID`
- ❌ `javax.*` imports — use `jakarta.*` (Spring Boot 3+)
- ❌ Returning entities from controllers — always use DTOs
- ❌ Blocking calls (JPA, `RestTemplate`) inside coroutines without `Dispatchers.IO`
