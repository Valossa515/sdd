---
name: ktor-testing
description: Testing guide for Ktor projects. Unit tests with MockK and runTest, route tests with testApplication, and repository tests against PostgreSQL with Testcontainers.
stack: ktor
versions: "Kotlin 2.x, Ktor 3.x, JUnit 5, MockK, kotlinx-coroutines-test, Testcontainers"
---

# Ktor Testing

## Dependencies (build.gradle.kts)

```kotlin
dependencies {
    testImplementation("io.ktor:ktor-server-test-host")
    testImplementation("io.ktor:ktor-client-content-negotiation")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test")
    testImplementation("io.mockk:mockk:1.x.x")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
}

tasks.withType<Test> { useJUnitPlatform() }
```

---

## Unit Tests — Services

No Ktor, no database. Mock the repositories with MockK, and give the service a `TransactionRunner` that just runs the block.

```kotlin
// src/test/kotlin/com/example/app/support/DirectTransactionRunner.kt
object DirectTransactionRunner : TransactionRunner {
    override suspend fun <T> inTransaction(block: suspend () -> T): T = block()
}
```

```kotlin
class OrderServiceTest {

    private val orderRepository = mockk<OrderRepository>()
    private val customerRepository = mockk<CustomerRepository>()
    private val service = OrderService(DirectTransactionRunner, orderRepository, customerRepository)

    @Test
    fun `findById returns the order when it exists`() = runTest {
        val order = anOrder()
        every { orderRepository.findById(order.id) } returns order

        val response = service.findById(order.id)

        assertEquals(order.id, response.id)
    }

    @Test
    fun `findById throws when the order does not exist`() = runTest {
        val id = UUID.randomUUID()
        every { orderRepository.findById(id) } returns null

        assertFailsWith<OrderNotFoundException> { service.findById(id) }
    }

    @Test
    fun `create saves the order once`() = runTest {
        val customer = aCustomer()
        every { customerRepository.findById(customer.id) } returns customer
        every { orderRepository.save(any()) } answers { firstArg() }

        service.create(aCreateOrderRequest(customerId = customer.id.toString()))

        verify(exactly = 1) { orderRepository.save(any()) }
    }
}
```

Repository ports are plain functions, so they're stubbed with `every`/`verify`; use `coEvery`/`coVerify` for anything declared `suspend` (services, HTTP clients).

---

## Route Tests — testApplication

Start the **real** `module()` — so serialization, validation, StatusPages and auth run exactly as in production — and swap the Koin module for one with mocked services.

```kotlin
class OrderRoutesTest {

    private val orderService = mockk<OrderService>()

    private fun ApplicationTestBuilder.setUp(): HttpClient {
        environment { config = ApplicationConfig("application-test.yaml") }
        application {
            module(koinModules = listOf(module { single { orderService } }))
        }
        return createClient { install(ContentNegotiation) { json() } }
    }

    @Test
    fun `GET order returns 200 when it exists`() = testApplication {
        val client = setUp()
        val id = UUID.randomUUID()
        coEvery { orderService.findById(id) } returns anOrderResponse(id)

        val response = client.get("/api/v1/orders/$id") { bearerAuth(testToken()) }

        assertEquals(HttpStatusCode.OK, response.status)
        assertEquals(id, response.body<OrderResponse>().id)
    }

    @Test
    fun `GET order returns 404 as a problem when it does not exist`() = testApplication {
        val client = setUp()
        val id = UUID.randomUUID()
        coEvery { orderService.findById(id) } throws OrderNotFoundException(id)

        val response = client.get("/api/v1/orders/$id") { bearerAuth(testToken()) }

        assertEquals(HttpStatusCode.NotFound, response.status)
        assertEquals("application/problem+json", response.contentType()?.withoutParameters()?.toString())
    }

    @Test
    fun `POST order returns 422 when the body is invalid`() = testApplication {
        val client = setUp()

        val response = client.post("/api/v1/orders") {
            bearerAuth(testToken())
            contentType(ContentType.Application.Json)
            setBody(CreateOrderRequest(customerId = "", items = emptyList()))
        }

        assertEquals(HttpStatusCode.UnprocessableEntity, response.status)
    }

    @Test
    fun `GET order returns 401 without a token`() = testApplication {
        val client = setUp()

        assertEquals(HttpStatusCode.Unauthorized, client.get("/api/v1/orders/${UUID.randomUUID()}").status)
    }
}
```

- `application-test.yaml` points the JWT config at a test issuer whose key `testToken()` signs with; it must not need a database when the services are mocked
- Leave `ktor.application.modules` out of `application-test.yaml`: `testApplication` would load the module from it as well, and installing the plugins twice fails
- Every route gets: one success case, each error status it can return, and the 401 case

---

## Repository Tests — Testcontainers

Real PostgreSQL, real Flyway migrations, real Exposed queries. Start one container per test class and clean the tables between tests.

```kotlin
@Testcontainers
class ExposedOrderRepositoryTest {

    companion object {
        @Container
        @JvmStatic
        val postgres = PostgreSQLContainer<Nothing>("postgres:16-alpine")

        private lateinit var database: Database

        @BeforeAll
        @JvmStatic
        fun connect() {
            database = connectDatabase(DatabaseConfig(postgres.jdbcUrl, postgres.username, postgres.password, poolSize = 2))
        }
    }

    private val tx = ExposedTransactionRunner(database)
    private val repository = ExposedOrderRepository()

    @BeforeEach
    fun clean() = transaction(database) { OrderItems.deleteAll(); Orders.deleteAll() }

    @Test
    fun `save then findById returns the same order`() = runTest {
        val order = anOrder()

        tx.inTransaction { repository.save(order) }
        val found = tx.inTransaction { repository.findById(order.id) }

        assertEquals(order, found)
    }
}
```

`connectDatabase` is the production function, so the migrations under test are the ones that will run in production.

---

## Test Fixtures

Top-level factory functions with default arguments; each test overrides only what it cares about.

```kotlin
fun anOrder(
    id: UUID = UUID.randomUUID(),
    customerId: String = "customer-test",
    status: OrderStatus = OrderStatus.PENDING,
) = Order(id = id, customerId = customerId, status = status, createdAt = Instant.now().truncatedTo(ChronoUnit.MICROS))
```

Truncate `Instant`s to microseconds — PostgreSQL stores microseconds, so a nanosecond `Instant` won't compare equal after a round trip.

---

## Naming Convention for Tests

Backtick names that read as a sentence: `` `<unit> <does what> when <condition>` ``.

```
`findById returns the order when it exists`
`POST order returns 422 when the body is invalid`
`GET order returns 401 without a token`
```

---

## What NOT to do

- ❌ Testing routes by calling handler functions directly — go through `testApplication` and the real `module()`
- ❌ `runBlocking` in tests — use `runTest`
- ❌ `SchemaUtils.create` in repository tests — run the Flyway migrations
- ❌ Sharing one Koin context across tests — each `testApplication` starts its own
- ❌ Comparing `Instant`s with nanoseconds after a database round trip
