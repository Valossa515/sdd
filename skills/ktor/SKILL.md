---
name: ktor
description: Use this skill for any Ktor server task — routes, services, persistence with Exposed, config, tests, or refactoring. Targets Ktor 3.x with Kotlin 2.x, kotlinx.serialization, Koin and Exposed.
stack: ktor
versions: "Kotlin 2.x, JVM 21, Ktor 3.x, Exposed, Koin, Gradle Kotlin DSL"
---

# Ktor Agent Skill

You are an expert Kotlin engineer building HTTP services with Ktor. Follow these guidelines for every task in this project. Ktor is unopinionated: structure, DI and persistence are choices this skill makes explicit, so every feature is built the same way.

## Stack Versions (always target these unless told otherwise)

- **Kotlin**: 2.x, JVM target 21, coroutines throughout
- **Ktor**: 3.x server (Netty engine), configured with `application.yaml`
- **Serialization**: kotlinx.serialization (`ContentNegotiation` + `json()`)
- **DI**: Koin (`koin-ktor`)
- **Database**: PostgreSQL via Exposed (DSL) + HikariCP, migrations with Flyway
- **Build tool**: Gradle with Kotlin DSL (`build.gradle.kts`)

---

## Architecture

```
src/main/kotlin/com/example/app/
├── Application.kt          ← main + Application.module(): installs plugins, DI, routing
├── plugins/                ← one file per plugin group: Serialization, StatusPages, Security, Monitoring
├── api/                    ← routes + request/response DTOs (adapters in)
│   ├── OrderRoutes.kt
│   └── dto/
├── application/            ← services / use cases
├── domain/                 ← models, repository interfaces (ports), domain exceptions
└── infrastructure/         ← Exposed tables, repository implementations, external clients (adapters out)
    ├── persistence/
    └── client/
src/main/resources/
├── application.yaml
└── db/migration/           ← Flyway scripts
```

**Rules:**
- Routes parse the request, call one service function and respond — no business logic, no Exposed calls
- Services are plain classes with `suspend` functions; they never touch `ApplicationCall`
- Domain has **zero** Ktor or Exposed dependencies
- All database access goes through repositories; services open the transaction (see Persistence)
- Every plugin is installed from a function in `plugins/` (`fun Application.configureSerialization()`), called from `Application.module()`

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Route file / function | `{Resource}Routes.kt` / `fun Route.{resource}Routes()` | `OrderRoutes.kt` / `orderRoutes()` |
| Service | `{Resource}Service` | `OrderService` |
| Repository (port) | `{Resource}Repository` | `OrderRepository` |
| Repository (Exposed) | `Exposed{Resource}Repository` | `ExposedOrderRepository` |
| Exposed table | plural `object` | `Orders`, `OrderItems` |
| DTO (request) | `{Action}{Resource}Request` | `CreateOrderRequest` |
| DTO (response) | `{Resource}Response` | `OrderResponse` |
| Domain exception | `{Resource}NotFoundException` | `OrderNotFoundException` |
| Plugin config | `fun Application.configure{Plugin}()` | `configureStatusPages()` |

---

## Application Module

```kotlin
// Application.kt
fun main(args: Array<String>) = EngineMain.main(args)

fun Application.module(koinModules: List<Module> = listOf(appModule(environment.config))) {
    configureKoin(koinModules)
    configureSerialization()
    configureMonitoring()
    configureSecurity()
    configureStatusPages()
    configureValidation()
    configureRouting()
}

fun Application.configureRouting() = routing {
    healthRoutes()
    authenticate("auth-jwt") {
        orderRoutes()
    }
}
```

The `koinModules` parameter lets tests start the real module with mocked dependencies.

---

## Routes

```kotlin
fun Route.orderRoutes() {
    val orderService by inject<OrderService>()

    route("/api/v1/orders") {
        get("/{id}") {
            call.respond(orderService.findById(call.uuidParameter("id")))
        }

        post {
            val request = call.receive<CreateOrderRequest>()
            val created = orderService.create(request)
            call.response.header(HttpHeaders.Location, "/api/v1/orders/${created.id}")
            call.respond(HttpStatusCode.Created, created)
        }

        delete("/{id}") {
            orderService.delete(call.uuidParameter("id"))
            call.respond(HttpStatusCode.NoContent)
        }
    }
}

fun ApplicationCall.uuidParameter(name: String): UUID =
    parameters[name]?.let { runCatching { UUID.fromString(it) }.getOrNull() }
        ?: throw BadRequestException("Invalid or missing path parameter '$name'")
```

---

## DTOs and Serialization

DTOs are `@Serializable` data classes. Types kotlinx.serialization can't encode out of the box (`UUID`, `BigDecimal`, `Instant`) get one serializer each, kept in a single `serialization/` file and applied with a typealias.

```kotlin
@Serializable
data class CreateOrderRequest(
    val customerId: String,
    val items: List<OrderItemRequest>,
)

@Serializable
data class OrderResponse(
    val id: UUIDAsString,
    val customerId: String,
    val status: OrderStatus,
    val total: BigDecimalAsString,
)

typealias UUIDAsString = @Serializable(with = UUIDSerializer::class) UUID
typealias BigDecimalAsString = @Serializable(with = BigDecimalSerializer::class) BigDecimal

object UUIDSerializer : KSerializer<UUID> {
    override val descriptor = PrimitiveSerialDescriptor("UUID", PrimitiveKind.STRING)
    override fun serialize(encoder: Encoder, value: UUID) = encoder.encodeString(value.toString())
    override fun deserialize(decoder: Decoder): UUID = UUID.fromString(decoder.decodeString())
}
```

Money goes over the wire as a string (`"10.50"`), never as a JSON number.

```kotlin
fun Application.configureSerialization() {
    install(ContentNegotiation) {
        json(Json {
            ignoreUnknownKeys = true      // tolerate new client fields
            explicitNulls = false
        })
    }
}
```

### Validation

Use the `RequestValidation` plugin — one `validate<T>` block per request DTO. It throws `RequestValidationException`, which StatusPages maps to 422.

```kotlin
fun Application.configureValidation() {
    install(RequestValidation) {
        validate<CreateOrderRequest> { request ->
            val errors = buildList {
                if (request.customerId.isBlank()) add("customerId must not be blank")
                if (request.items.isEmpty()) add("items must not be empty")
                if (request.items.any { it.quantity <= 0 }) add("items.quantity must be positive")
            }
            if (errors.isEmpty()) ValidationResult.Valid else ValidationResult.Invalid(errors)
        }
    }
}
```

---

## Services

Services own the transaction boundary, like `@Transactional` in Spring: each public function wraps its work in `tx.inTransaction { }`, so every repository call in a use case commits or rolls back together.

```kotlin
class OrderService(
    private val tx: TransactionRunner,
    private val orderRepository: OrderRepository,
    private val customerRepository: CustomerRepository,
) {
    suspend fun findById(id: UUID): OrderResponse = tx.inTransaction {
        orderRepository.findById(id)?.toResponse() ?: throw OrderNotFoundException(id)
    }

    suspend fun create(request: CreateOrderRequest): OrderResponse = tx.inTransaction {
        val customer = customerRepository.findById(UUID.fromString(request.customerId))
            ?: throw CustomerNotFoundException(request.customerId)
        orderRepository.save(Order.create(customer, request.items)).toResponse()
    }
}
```

Domain models are immutable data classes — Exposed DSL maps rows to them, so the JPA entity caveats do not apply here.

---

## Persistence — Exposed

### Tables

```kotlin
object Orders : UUIDTable("orders") {
    val customerId = varchar("customer_id", 64).index()
    val status = enumerationByName<OrderStatus>("status", 32)
    val createdAt = timestamp("created_at")      // exposed-java-time
}
```

### Transactions

Exposed uses blocking JDBC, so every transaction runs as a **suspended transaction on `Dispatchers.IO`**. The application layer only sees a small interface; the Exposed implementation lives in infrastructure.

```kotlin
// application/TransactionRunner.kt
interface TransactionRunner {
    suspend fun <T> inTransaction(block: suspend () -> T): T
}

// infrastructure/persistence/ExposedTransactionRunner.kt
class ExposedTransactionRunner(private val database: Database) : TransactionRunner {
    override suspend fun <T> inTransaction(block: suspend () -> T): T =
        newSuspendedTransaction(Dispatchers.IO, database) { block() }
}
```

(Exposed 1.x renames `newSuspendedTransaction` to `suspendTransaction`; use whichever the project's Exposed version provides.)

### Repositories

Repository functions assume they run inside the service's transaction — they never open one themselves.

```kotlin
class ExposedOrderRepository : OrderRepository {

    override fun findById(id: UUID): Order? =
        Orders.selectAll().where { Orders.id eq id }.singleOrNull()?.toOrder()

    override fun save(order: Order): Order {
        Orders.insert {
            it[id] = order.id
            it[customerId] = order.customerId
            it[status] = order.status
            it[createdAt] = order.createdAt
        }
        return order
    }
}

private fun ResultRow.toOrder() = Order(
    id = this[Orders.id].value,
    customerId = this[Orders.customerId],
    status = this[Orders.status],
    createdAt = this[Orders.createdAt],
)
```

### Migrations and connection

```kotlin
fun connectDatabase(config: DatabaseConfig): Database {
    val dataSource = HikariDataSource(HikariConfig().apply {
        jdbcUrl = config.url
        username = config.user
        password = config.password
        maximumPoolSize = config.poolSize
    })
    Flyway.configure().dataSource(dataSource).load().migrate()
    return Database.connect(dataSource)
}
```

- Schema changes go in Flyway scripts (`V3__add_order_status_index.sql`) — never `SchemaUtils.create` outside tests
- Index every foreign key and every column used in a `where`

---

## Error Handling

One `StatusPages` installation maps every exception to an RFC 7807 response. Name domain exceptions so they don't clash with Ktor's own `NotFoundException`.

```kotlin
@Serializable
data class Problem(
    val type: String = "about:blank",
    val title: String,
    val status: Int,
    val detail: String? = null,
    val errors: List<String>? = null,
)

suspend fun ApplicationCall.respondProblem(
    status: HttpStatusCode, title: String, detail: String? = null, errors: List<String>? = null,
) = respondText(
    Json.encodeToString(Problem(title = title, status = status.value, detail = detail, errors = errors)),
    ContentType.parse("application/problem+json"),
    status,
)

fun Application.configureStatusPages() {
    install(StatusPages) {
        exception<ResourceNotFoundException> { call, e -> call.respondProblem(HttpStatusCode.NotFound, "Not found", e.message) }
        exception<BusinessRuleException> { call, e -> call.respondProblem(HttpStatusCode.Conflict, "Business rule violated", e.message) }
        exception<RequestValidationException> { call, e ->
            call.respondProblem(HttpStatusCode.UnprocessableEntity, "Validation failed", errors = e.reasons)
        }
        exception<BadRequestException> { call, e -> call.respondProblem(HttpStatusCode.BadRequest, "Bad request", e.message) }
        exception<Throwable> { call, e ->
            call.application.log.error("Unexpected error", e)
            call.respondProblem(HttpStatusCode.InternalServerError, "Internal error", "An unexpected error occurred")
        }
    }
}
```

`OrderNotFoundException` extends `ResourceNotFoundException`, so new resources need no new mapping.

---

## Dependency Injection — Koin

```kotlin
fun appModule(config: ApplicationConfig) = module {
    single { DatabaseConfig.from(config) }
    single { connectDatabase(get()) }                         // runs Flyway, returns Exposed's Database
    single<TransactionRunner> { ExposedTransactionRunner(get()) }
    single<OrderRepository> { ExposedOrderRepository() }
    single<CustomerRepository> { ExposedCustomerRepository() }
    single { OrderService(get(), get(), get()) }
}

fun Application.configureKoin(modules: List<Module>) {
    install(Koin) {
        slf4jLogger()
        modules(modules)
    }
}
```

Constructor injection only: classes receive dependencies as constructor parameters and never call `get()`/`inject()` themselves — only routes and the module wiring do.

---

## Configuration

`application.yaml` holds everything; secrets come from environment variables. Read it once at startup into typed data classes.

```yaml
ktor:
  deployment:
    port: 8080
  application:
    modules:
      - com.example.app.ApplicationKt.module

app:
  database:
    url: "$DATABASE_URL"
    user: "$DATABASE_USER"
    password: "$DATABASE_PASSWORD"
    poolSize: 10
  payment:
    apiUrl: "https://api.payment.com"
    apiKey: "$PAYMENT_API_KEY"
    timeoutMillis: 5000
```

```kotlin
data class PaymentConfig(val apiUrl: String, val apiKey: String, val timeout: Duration) {
    companion object {
        fun from(config: ApplicationConfig) = PaymentConfig(
            apiUrl = config.property("app.payment.apiUrl").getString(),
            apiKey = config.property("app.payment.apiKey").getString(),
            timeout = config.property("app.payment.timeoutMillis").getString().toLong().milliseconds,
        )
    }
}
```

---

## Security — JWT

```kotlin
fun Application.configureSecurity() {
    val jwt = JwtConfig.from(environment.config)
    val jwkProvider = JwkProviderBuilder(URI(jwt.jwksUrl).toURL())
        .cached(10, 24, TimeUnit.HOURS)
        .rateLimited(10, 1, TimeUnit.MINUTES)
        .build()
    install(Authentication) {
        jwt("auth-jwt") {
            realm = jwt.realm
            verifier(jwkProvider, jwt.issuer) { withAudience(jwt.audience) }
            validate { credential ->
                if (credential.payload.audience.contains(jwt.audience)) JWTPrincipal(credential.payload) else null
            }
            challenge { _, _ -> call.respondProblem(HttpStatusCode.Unauthorized, "Unauthorized") }
        }
    }
}
```

- Protect routes with `authenticate("auth-jwt") { ... }`; read the user with `call.principal<JWTPrincipal>()`
- Verify tokens against the issuer's JWKS (RS256); HMAC secrets only for internal service-to-service tokens, loaded from env
- Install `CORS` with an explicit `allowHost(...)` list — never `anyHost()` in production

---

## Observability

```kotlin
fun Application.configureMonitoring() {
    install(CallId) {
        retrieveFromHeader(HttpHeaders.XRequestId)
        generate { UUID.randomUUID().toString() }
        replyToHeader(HttpHeaders.XRequestId)
    }
    install(CallLogging) {
        level = Level.INFO
        callIdMdc("requestId")
        filter { call -> call.request.path().startsWith("/api") }
    }
    val registry = PrometheusMeterRegistry(PrometheusConfig.DEFAULT)
    install(MicrometerMetrics) { this.registry = registry }
    routing { get("/metrics") { call.respondText(registry.scrape()) } }
}
```

- Logs: SLF4J + Logback with a JSON encoder in production; the `requestId` MDC key ties log lines to a request
- Health: `GET /health/live` (process up, no dependencies) and `GET /health/ready` (runs `SELECT 1` through the `TransactionRunner`), both outside `authenticate`
- Tracing: OpenTelemetry Java agent or the `opentelemetry-ktor` instrumentation, whichever the project uses

---

## Testing

See `testing.md` for full testing guide. Quick rules:

- Unit tests: JUnit 5 (or kotlin-test) + MockK + `runTest`, with a `TransactionRunner` that just runs the block
- Route tests: `testApplication { }` with the real `module()` and mocked services injected through `koinModules`
- Repository tests: Testcontainers PostgreSQL + Flyway, real Exposed queries
- **Minimum coverage**: 80% on `application/` and `domain/`

---

## What NOT to do

- ❌ Exposed or JDBC calls outside a transaction opened by a service through `TransactionRunner` (a suspended transaction on `Dispatchers.IO`)
- ❌ Repositories opening their own transactions — the service owns the boundary
- ❌ `runBlocking` in production code, or `GlobalScope.launch`
- ❌ Business logic or database access inside route handlers
- ❌ `SchemaUtils.create` / `createMissingTablesAndColumns` in production — use Flyway
- ❌ Throwing Ktor's `NotFoundException` from services — use domain exceptions
- ❌ Classes calling Koin's `get()`/`inject()` instead of taking constructor parameters
- ❌ `!!` — use `?:` with a domain exception or `requireNotNull` with a message
- ❌ Money as `Double` or as a JSON number — `BigDecimal`, serialized as a string
- ❌ `anyHost()` in CORS, or HMAC JWT secrets in `application.yaml`
