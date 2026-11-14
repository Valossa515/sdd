---
name: fastapi
description: Use this skill for any FastAPI task — routers, schemas, services, persistence with SQLAlchemy, config, tests, or refactoring. Targets FastAPI with Python 3.12+, Pydantic v2, async SQLAlchemy 2.0 and Alembic.
stack: fastapi
versions: "Python 3.12+, FastAPI 0.115+, Pydantic v2, SQLAlchemy 2.0 (async), Alembic"
---

# FastAPI Agent Skill

You are an expert Python engineer building APIs with FastAPI. Follow these guidelines for every task in this project. FastAPI only gives you routing, validation and dependency injection — the layering, persistence and error rules below are what keep every feature built the same way.

## Stack Versions (always target these unless told otherwise)

- **Python**: 3.12+, fully type-annotated (`mypy --strict` clean)
- **FastAPI**: 0.115+, async endpoints
- **Pydantic**: v2 (`model_config`, `model_validate`, `Field`) — never v1 idioms (`class Config`, `.dict()`, `orm_mode`)
- **Database**: PostgreSQL via SQLAlchemy 2.0 async (`asyncpg`), migrations with Alembic
- **Settings**: `pydantic-settings`
- **Tooling**: `uv` (or Poetry), Ruff for lint + format, mypy

---

## Architecture

```
app/
├── main.py                 ← create_app(): routers, exception handlers, middleware, lifespan
├── api/                    ← HTTP layer (adapters in)
│   ├── deps.py             ← Depends() providers: session, current user, services
│   └── v1/
│       ├── orders.py       ← APIRouter
│       └── schemas/        ← Pydantic request/response models
├── services/               ← use cases / business logic
├── domain/                 ← domain exceptions, enums, value objects
├── repositories/           ← all SQLAlchemy queries
├── db/                     ← engine, session factory, ORM models
│   └── models/
└── core/                   ← settings, logging, security
alembic/                    ← migrations
tests/
```

**Rules:**
- Routers validate input (Pydantic), call **one** service method and return a response schema — no queries, no business rules
- Services never import FastAPI: no `HTTPException`, no `Request` — they raise domain exceptions that the app's exception handlers map to HTTP
- Repositories are the only place that builds SQLAlchemy queries; they never commit
- ORM models never leave the service layer — routers return Pydantic schemas (`response_model`)

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Router module | plural resource, `snake_case` | `api/v1/orders.py` |
| Endpoint function | `{verb}_{resource}` | `get_order`, `create_order` |
| Request schema | `{Resource}Create` / `{Resource}Update` | `OrderCreate` |
| Response schema | `{Resource}Read` | `OrderRead` |
| ORM model | singular `PascalCase` | `Order` (table `orders`) |
| Service | `{Resource}Service` | `OrderService` |
| Repository | `{Resource}Repository` | `OrderRepository` |
| Domain exception | `{Resource}NotFoundError` | `OrderNotFoundError` |
| Dependency alias | `{Thing}Dep` | `SessionDep`, `OrderServiceDep` |

Modules and functions `snake_case`, classes `PascalCase`, constants `UPPER_SNAKE_CASE`.

---

## Routers

```python
router = APIRouter(prefix="/api/v1/orders", tags=["orders"])


@router.get("/{order_id}", response_model=OrderRead)
async def get_order(order_id: UUID, service: OrderServiceDep) -> OrderRead:
    return await service.get(order_id)


@router.post("", response_model=OrderRead, status_code=status.HTTP_201_CREATED)
async def create_order(payload: OrderCreate, service: OrderServiceDep, response: Response) -> OrderRead:
    order = await service.create(payload)
    response.headers["Location"] = f"/api/v1/orders/{order.id}"
    return order


@router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_order(order_id: UUID, service: OrderServiceDep) -> None:
    await service.delete(order_id)
```

### Dependencies (`api/deps.py`)

Wire everything with `Depends` and `Annotated` aliases — one place builds the session, repositories and services.

```python
async def get_session() -> AsyncIterator[AsyncSession]:
    async with SessionLocal() as session:
        yield session


SessionDep = Annotated[AsyncSession, Depends(get_session)]


def get_order_service(session: SessionDep) -> OrderService:
    return OrderService(session, OrderRepository(session))


OrderServiceDep = Annotated[OrderService, Depends(get_order_service)]
```

Tests replace `get_order_service` (or `get_session`) through `app.dependency_overrides`, so keep providers as named functions, never inline lambdas.

---

## Schemas (Pydantic v2)

```python
class OrderItemCreate(BaseModel):
    product_id: str = Field(min_length=1)
    quantity: int = Field(gt=0)


class OrderCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    customer_id: str = Field(min_length=1)
    items: list[OrderItemCreate] = Field(min_length=1)


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)   # build from ORM objects

    id: UUID
    customer_id: str
    status: OrderStatus
    total: Decimal
    created_at: datetime
```

- Money is `Decimal`, never `float`
- Request schemas forbid unknown fields; response schemas list exactly what the client may see
- Use `Field(...)` constraints and `@field_validator` for validation — FastAPI turns failures into 422

---

## Services

Services own the **transaction boundary**: writes run inside `async with self._session.begin():`, so all repository calls in a use case commit or roll back together.

```python
class OrderService:
    def __init__(self, session: AsyncSession, orders: OrderRepository) -> None:
        self._session = session
        self._orders = orders

    async def get(self, order_id: UUID) -> OrderRead:
        order = await self._orders.get(order_id)
        if order is None:
            raise OrderNotFoundError(order_id)
        return OrderRead.model_validate(order)

    async def create(self, data: OrderCreate) -> OrderRead:
        async with self._session.begin():
            order = Order(customer_id=data.customer_id, status=OrderStatus.PENDING)
            order.items = [OrderItem(product_id=i.product_id, quantity=i.quantity) for i in data.items]
            self._orders.add(order)
        return OrderRead.model_validate(order)
```

### Async rules

- Never block the event loop in an `async def`: no `requests`, `time.sleep`, sync DB drivers or heavy CPU work — use `httpx.AsyncClient`, `asyncio.sleep`, `asyncpg`
- A library that is only sync goes behind a plain `def` endpoint (FastAPI runs it in a thread pool) or `await run_in_threadpool(fn, ...)`
- Shared clients (`httpx.AsyncClient`, engine) are created once in the app `lifespan` and closed there

---

## Persistence — SQLAlchemy 2.0 async

### Engine and session

```python
engine = create_async_engine(settings.database_url.unicode_string(), pool_pre_ping=True)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)
```

`expire_on_commit=False` is required with async sessions: otherwise reading an attribute after commit triggers a lazy reload, which fails outside an `await`.

### ORM models (typed declarative)

```python
class Base(DeclarativeBase):
    pass


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    customer_id: Mapped[str] = mapped_column(String(64), index=True)
    status: Mapped[OrderStatus] = mapped_column(Enum(OrderStatus, native_enum=False, length=32))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(UTC), server_default=func.now()
    )
    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", lazy="raise"
    )

    @property
    def total(self) -> Decimal:
        return sum((item.subtotal for item in self.items), Decimal("0"))
```

- `lazy="raise"` makes a forgotten eager load fail loudly instead of an implicit lazy load, which async SQLAlchemy cannot do (`MissingGreenlet`)
- Give columns a Python-side `default` as well as any `server_default`: a value only the database generates is expired after the insert, and reading it later is that same implicit load

### Repositories

```python
class OrderRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, order_id: UUID) -> Order | None:
        stmt = select(Order).where(Order.id == order_id).options(selectinload(Order.items))
        return await self._session.scalar(stmt)

    async def list_by_customer(self, customer_id: str, *, limit: int, offset: int) -> Sequence[Order]:
        stmt = (
            select(Order)
            .where(Order.customer_id == customer_id)
            .options(selectinload(Order.items))
            .order_by(Order.created_at.desc(), Order.id)
            .limit(limit)
            .offset(offset)
        )
        return (await self._session.scalars(stmt)).all()

    def add(self, order: Order) -> None:
        self._session.add(order)
```

- Load relationships explicitly with `selectinload` / `joinedload` — one query per relationship, never N+1
- Paginated queries always have a deterministic `order_by` ending in a unique column

### Migrations — Alembic

- Every schema change is an Alembic revision: `alembic revision --autogenerate -m "add order status index"`, then **review the generated file** — autogenerate misses renames, server defaults and some type changes
- Never `Base.metadata.create_all()` outside tests
- Data migrations get their own revision, with a working `downgrade()`
- `alembic/env.py` uses the async engine and imports `Base.metadata` from `app/db/models`

---

## Error Handling

Domain exceptions carry no HTTP knowledge; `main.py` maps them to RFC 7807 responses in one place.

```python
# domain/exceptions.py
class DomainError(Exception): ...
class NotFoundError(DomainError): ...
class BusinessRuleError(DomainError): ...

class OrderNotFoundError(NotFoundError):
    def __init__(self, order_id: UUID) -> None:
        super().__init__(f"Order {order_id} not found")
```

```python
# core/errors.py
def problem(status_code: int, title: str, detail: str | None = None, **extra: Any) -> JSONResponse:
    body = {"type": "about:blank", "title": title, "status": status_code, "detail": detail, **extra}
    return JSONResponse(body, status_code=status_code, media_type="application/problem+json")


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(NotFoundError)
    async def not_found(_: Request, exc: NotFoundError) -> JSONResponse:
        return problem(404, "Not found", str(exc))

    @app.exception_handler(BusinessRuleError)
    async def business_rule(_: Request, exc: BusinessRuleError) -> JSONResponse:
        return problem(409, "Business rule violated", str(exc))

    @app.exception_handler(RequestValidationError)
    async def validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        errors = [{"field": ".".join(map(str, e["loc"][1:])), "message": e["msg"]} for e in exc.errors()]
        return problem(422, "Validation failed", errors=errors)

    @app.exception_handler(Exception)
    async def unexpected(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("Unexpected error")
        return problem(500, "Internal error", "An unexpected error occurred")
```

`HTTPException` is acceptable only inside `api/` for purely HTTP concerns (a malformed header), never as a substitute for a domain error.

---

## Configuration

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_nested_delimiter="__", extra="ignore")

    database_url: PostgresDsn
    payment_api_url: HttpUrl
    payment_api_key: SecretStr
    payment_timeout_seconds: float = 5.0
    cors_origins: list[str] = []


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

- Settings are read from the environment once; inject them with `Depends(get_settings)` where a request needs them
- Secrets are `SecretStr` (never logged by accident); `.env` is for local development only and is git-ignored

---

## Security

```python
bearer = HTTPBearer()
jwks = PyJWKClient(settings.jwt_jwks_url)   # caches the issuer's keys


async def get_current_user(credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer)]) -> User:
    token = credentials.credentials
    try:
        # PyJWKClient fetches keys with blocking HTTP, so keep it off the event loop
        signing_key = await run_in_threadpool(jwks.get_signing_key_from_jwt, token)
        claims = jwt.decode(
            token, key=signing_key.key,
            algorithms=["RS256"], audience=settings.jwt_audience, issuer=settings.jwt_issuer,
        )
    except jwt.PyJWTError as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid token") from exc
    return User(id=claims["sub"], roles=claims.get("roles", []))


CurrentUserDep = Annotated[User, Depends(get_current_user)]
```

- JWT verification with PyJWT against the issuer's JWKS; always pass `algorithms`, `audience` and `issuer`
- Protect a whole router with `APIRouter(dependencies=[Depends(get_current_user)])`; authorization checks (ownership, roles) live in services
- `CORSMiddleware` with the explicit `settings.cors_origins` list — never `["*"]` together with credentials

---

## Observability

- **Logging**: stdlib `logging` (or `structlog`) with JSON output in production; one module-level `logger = logging.getLogger(__name__)`; a middleware puts a request id (from `X-Request-ID` or generated) into a `contextvars` value that the log formatter includes
- **Health**: `GET /health/live` (no dependencies) and `GET /health/ready` (runs `SELECT 1`), both unauthenticated and excluded from request logging
- **Tracing**: `opentelemetry-instrumentation-fastapi` + the SQLAlchemy and httpx instrumentations
- **Metrics**: Prometheus via OpenTelemetry metrics or `prometheus-client`, exposed at `/metrics`
- Use `logger.info("Order created", extra={"order_id": str(order.id)})` — never f-strings with secrets or personal data

---

## Testing

See `testing.md` for full testing guide. Quick rules:

- pytest + pytest-asyncio (`asyncio_mode = "auto"`)
- Service tests: real logic, repositories replaced with `AsyncMock(spec=...)` or in-memory fakes
- API tests: `httpx.AsyncClient` + `ASGITransport` against `create_app()`, services swapped with `app.dependency_overrides`
- Repository tests: PostgreSQL via Testcontainers, schema created by running the Alembic migrations
- **Minimum coverage**: 80% on `services/` and `domain/`

---

## What NOT to do

- ❌ `HTTPException` (or any FastAPI import) in services, repositories or domain
- ❌ Returning ORM objects without a `response_model`, or schemas that expose internal fields
- ❌ Blocking I/O inside `async def` (`requests`, `time.sleep`, sync DB drivers)
- ❌ Lazy-loading relationships in async code — load them with `selectinload`/`joinedload`
- ❌ `Base.metadata.create_all()` in production — use Alembic
- ❌ Committing inside repositories — the service owns the transaction
- ❌ Pydantic v1 idioms: `class Config`, `.dict()`, `.parse_obj()`, `orm_mode`
- ❌ `float` for money, mutable default arguments, bare `except:`
- ❌ Secrets in code or in committed `.env` files
