---
name: fastapi-testing
description: Testing guide for FastAPI projects. Service tests with mocks, API tests with httpx and dependency overrides, and repository tests against PostgreSQL with Testcontainers and Alembic.
stack: fastapi
versions: "Python 3.12+, pytest, pytest-asyncio, httpx, testcontainers-python"
---

# FastAPI Testing

## Dependencies and configuration

```toml
# pyproject.toml
[dependency-groups]
dev = ["pytest", "pytest-asyncio", "pytest-cov", "httpx", "testcontainers[postgres]"]

[tool.pytest.ini_options]
asyncio_mode = "auto"          # every async test/fixture runs without a decorator
testpaths = ["tests"]
addopts = "--strict-markers"
```

```
tests/
├── conftest.py            ← app, client, database fixtures
├── factories.py           ← test data builders
├── unit/                  ← services, domain (no I/O)
├── api/                   ← routers through httpx, services mocked
└── integration/           ← repositories against real PostgreSQL
```

---

## Unit Tests — Services

No database, no HTTP. Replace repositories with `AsyncMock(spec=...)` — `spec` makes a call to a method that doesn't exist fail instead of silently passing.

```python
async def test_get_returns_order_when_it_exists() -> None:
    order = an_order()
    orders = AsyncMock(spec=OrderRepository)
    orders.get.return_value = order
    service = OrderService(session=AsyncMock(), orders=orders)

    result = await service.get(order.id)

    assert result.id == order.id
    assert result.status is OrderStatus.PENDING


async def test_get_raises_when_order_does_not_exist() -> None:
    orders = AsyncMock(spec=OrderRepository)
    orders.get.return_value = None
    service = OrderService(session=AsyncMock(), orders=orders)

    with pytest.raises(OrderNotFoundError):
        await service.get(uuid4())
```

`session.begin()` returns an async context manager; when a test exercises a write path with a mocked session, use `MagicMock()` for the session and set `session.begin.return_value.__aenter__` / `__aexit__` to `AsyncMock()` — or test write paths at the integration level.

---

## API Tests — httpx + dependency overrides

Run the real app (routers, validation, exception handlers) in-process with `ASGITransport`, and swap services with `app.dependency_overrides`.

```python
# tests/conftest.py
@pytest.fixture
def app() -> Iterator[FastAPI]:
    application = create_app()
    yield application
    application.dependency_overrides.clear()


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.fixture
def order_service(app: FastAPI) -> AsyncMock:
    service = AsyncMock(spec=OrderService)
    app.dependency_overrides[get_order_service] = lambda: service
    app.dependency_overrides[get_current_user] = lambda: a_user()
    return service
```

```python
async def test_get_order_returns_200_when_it_exists(client: AsyncClient, order_service: AsyncMock) -> None:
    order_id = uuid4()
    order_service.get.return_value = an_order_read(id=order_id)

    response = await client.get(f"/api/v1/orders/{order_id}")

    assert response.status_code == 200
    assert response.json()["id"] == str(order_id)


async def test_get_order_returns_404_problem_when_missing(client: AsyncClient, order_service: AsyncMock) -> None:
    order_id = uuid4()
    order_service.get.side_effect = OrderNotFoundError(order_id)

    response = await client.get(f"/api/v1/orders/{order_id}")

    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"


async def test_create_order_returns_422_when_items_empty(client: AsyncClient, order_service: AsyncMock) -> None:
    response = await client.post("/api/v1/orders", json={"customer_id": "c-1", "items": []})

    assert response.status_code == 422
    assert response.json()["errors"][0]["field"] == "items"
    order_service.create.assert_not_awaited()


async def test_get_order_returns_401_without_token(app: FastAPI, client: AsyncClient) -> None:
    response = await client.get(f"/api/v1/orders/{uuid4()}")

    assert response.status_code in (401, 403)
```

- `ASGITransport` does not run the app's `lifespan`; when a test needs it, wrap the app with `asgi_lifespan.LifespanManager`
- Every endpoint gets: one success case, each error status it can return, and the unauthenticated case

---

## Integration Tests — repositories against PostgreSQL

One PostgreSQL container for the whole session, schema created by the **real Alembic migrations**, tables truncated after each test.

```python
# tests/conftest.py
@pytest.fixture(scope="session")
def database_url() -> Iterator[str]:
    with PostgresContainer("postgres:16-alpine", driver="asyncpg") as postgres:
        url = postgres.get_connection_url()
        config = Config("alembic.ini")
        config.set_main_option("sqlalchemy.url", url)
        command.upgrade(config, "head")
        yield url


@pytest.fixture
async def session(database_url: str) -> AsyncIterator[AsyncSession]:
    engine = create_async_engine(database_url)
    async with async_sessionmaker(engine, expire_on_commit=False)() as s:
        yield s
    async with engine.begin() as conn:
        await conn.execute(text("TRUNCATE order_items, orders CASCADE"))
    await engine.dispose()
```

```python
async def test_get_loads_order_with_items(session: AsyncSession) -> None:
    order = an_order(item_count=2)
    async with session.begin():
        OrderRepository(session).add(order)
    session.expunge_all()          # force a real SELECT instead of the identity map

    found = await OrderRepository(session).get(order.id)

    assert found is not None
    assert len(found.items) == 2   # would raise with lazy="raise" if selectinload were missing
```

`expunge_all()` matters: without it the session returns the object it already holds, and the test never checks that the query loads the relationships.

---

## Test Data

Plain factory functions with keyword defaults (or `factory_boy` if the project already uses it). Each test sets only what it asserts on.

```python
# tests/factories.py
def an_order(*, customer_id: str = "customer-test", item_count: int = 1, status: OrderStatus = OrderStatus.PENDING) -> Order:
    order = Order(id=uuid4(), customer_id=customer_id, status=status, created_at=datetime.now(UTC))
    order.items = [OrderItem(product_id=f"product-{n}", quantity=1) for n in range(item_count)]
    return order


def an_order_read(**overrides: Any) -> OrderRead:
    defaults: dict[str, Any] = {
        "id": uuid4(), "customer_id": "customer-test", "status": OrderStatus.PENDING,
        "total": Decimal("10.00"), "created_at": datetime.now(UTC),
    }
    return OrderRead(**(defaults | overrides))
```

---

## Naming Convention for Tests

`test_<unit>_<expected>_when_<condition>` — the name alone says what broke.

```
test_get_returns_order_when_it_exists
test_create_order_returns_422_when_items_empty
test_get_order_returns_401_without_token
```

Run with coverage: `pytest --cov=app --cov-report=term-missing`.

---

## What NOT to do

- ❌ `TestClient` for async apps with async fixtures — use `httpx.AsyncClient` + `ASGITransport`
- ❌ `Base.metadata.create_all()` for the test schema — run the Alembic migrations
- ❌ SQLite in place of PostgreSQL for repository tests
- ❌ `Mock()` without `spec=` — typos in method names pass silently
- ❌ Leaving `app.dependency_overrides` set after a test
