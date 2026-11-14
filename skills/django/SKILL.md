---
name: django
description: Use this skill for any Django task — models, services, REST APIs with Django REST Framework, migrations, config, tests, or refactoring. Targets Django 5.x with Python 3.12+ and DRF.
stack: django
versions: "Python 3.12+, Django 5.x, Django REST Framework 3.15+, PostgreSQL"
---

# Django Agent Skill

You are an expert Django engineer building APIs with Django REST Framework. Follow these guidelines for every task in this project. Django leaves open where business logic lives; this skill puts it in **services** (writes) and **selectors** (reads), so views, serializers and models stay thin and predictable.

## Stack Versions (always target these unless told otherwise)

- **Python**: 3.12+, type-annotated
- **Django**: 5.x (5.2 LTS preferred)
- **API**: Django REST Framework 3.15+, OpenAPI with `drf-spectacular`
- **Database**: PostgreSQL via Django's ORM, migrations with Django migrations
- **Settings**: split settings + environment variables (`django-environ`)
- **Tooling**: `uv` (or Poetry), Ruff for lint + format, mypy with `django-stubs`

---

## Architecture

One Django **app per business domain**, each with the same internal layout.

```
config/                     ← project package
├── settings/
│   ├── base.py
│   ├── dev.py
│   └── prod.py
├── urls.py                 ← includes each app's api/urls.py under /api/v1/
├── asgi.py / wsgi.py
apps/
└── orders/
    ├── models.py           ← models + field-level invariants
    ├── services.py         ← write use cases (business logic, transactions)
    ├── selectors.py        ← read queries (filtering, prefetching)
    ├── exceptions.py       ← domain exceptions
    ├── api/
    │   ├── serializers.py  ← input/output serializers
    │   ├── views.py
    │   └── urls.py
    ├── admin.py
    ├── migrations/
    └── tests/
```

**Rules:**
- Views: authenticate, validate input with a serializer, call **one** service or selector, serialize the result. Nothing else.
- Services hold business logic and own transactions; they take plain arguments (keyword-only), not `request` or serializers
- Selectors hold every non-trivial read query — and every `select_related`/`prefetch_related`
- Serializers convert data; they never call `.save()` with business rules or touch other models
- No business logic in signals — call the service explicitly instead
- Apps depend on another app only through its services/selectors, never on its views or serializers

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| App | plural domain noun | `orders` |
| Model | singular `PascalCase` | `Order`, `OrderItem` |
| Service function | `{verb}_{resource}` | `create_order`, `cancel_order` |
| Selector function | `get_{resource}` / `list_{resources}` | `get_order`, `list_orders` |
| Input serializer | `{Resource}{Action}InputSerializer` | `OrderCreateInputSerializer` |
| Output serializer | `{Resource}OutputSerializer` | `OrderOutputSerializer` |
| View | `{Resource}{Kind}View` | `OrderListCreateView`, `OrderDetailView` |
| Exception | `{Resource}NotFound` | `OrderNotFound` |
| URL name | `{app}:{resource}-{kind}` | `orders:order-detail` |

---

## Views (DRF)

Prefer explicit `APIView`s calling services over `ModelViewSet`, whose generic `perform_create` hides where business logic goes.

```python
class OrderListCreateView(APIView):
    def get(self, request: Request) -> Response:
        paginator = OrderPagination()
        page = paginator.paginate_queryset(list_orders(owner=request.user), request, view=self)
        return paginator.get_paginated_response(OrderOutputSerializer(page, many=True).data)

    def post(self, request: Request) -> Response:
        serializer = OrderCreateInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = create_order(owner=request.user, **serializer.validated_data)
        return Response(
            OrderOutputSerializer(order).data,
            status=status.HTTP_201_CREATED,
            headers={"Location": reverse("orders:order-detail", kwargs={"order_id": order.id})},
        )


class OrderDetailView(APIView):
    def get(self, request: Request, order_id: UUID) -> Response:
        order = get_order(order_id=order_id, owner=request.user)
        return Response(OrderOutputSerializer(order).data)

    def delete(self, request: Request, order_id: UUID) -> Response:
        cancel_order(order_id=order_id, owner=request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)
```

```python
# apps/orders/api/urls.py
app_name = "orders"
urlpatterns = [
    path("orders/", OrderListCreateView.as_view(), name="order-list"),
    path("orders/<uuid:order_id>/", OrderDetailView.as_view(), name="order-detail"),
]
```

---

## Serializers

Separate **input** and **output** serializers. Input serializers are plain `Serializer`s (explicit fields, no model coupling); output serializers may be `ModelSerializer`s with an explicit `fields` list.

```python
class OrderItemInputSerializer(serializers.Serializer):
    product_id = serializers.CharField(max_length=64)
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateInputSerializer(serializers.Serializer):
    customer_id = serializers.CharField(max_length=64)
    items = OrderItemInputSerializer(many=True, allow_empty=False)


class OrderOutputSerializer(serializers.ModelSerializer):
    total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Order
        fields = ["id", "customer_id", "status", "total", "created_at"]
```

Never `fields = "__all__"` — a new model field would leak to clients without anyone deciding it should.

---

## Services and Selectors

```python
# apps/orders/services.py
@transaction.atomic
def create_order(*, owner: User, customer_id: str, items: list[dict[str, Any]]) -> Order:
    order = Order.objects.create(owner=owner, customer_id=customer_id, status=Order.Status.PENDING)
    OrderItem.objects.bulk_create(
        [OrderItem(order=order, product_id=i["product_id"], quantity=i["quantity"]) for i in items]
    )
    transaction.on_commit(lambda: send_order_confirmation(order_id=order.id))
    return order


@transaction.atomic
def cancel_order(*, order_id: UUID, owner: User) -> Order:
    order = get_order(order_id=order_id, owner=owner, for_update=True)
    if order.status != Order.Status.PENDING:
        raise OrderNotCancellable(order_id)
    order.status = Order.Status.CANCELLED
    order.save(update_fields=["status", "updated_at"])
    return order
```

```python
# apps/orders/selectors.py
def get_order(*, order_id: UUID, owner: User, for_update: bool = False) -> Order:
    queryset = Order.objects.filter(owner=owner).prefetch_related("items")
    if for_update:
        queryset = queryset.select_for_update()
    try:
        return queryset.get(id=order_id)
    except Order.DoesNotExist:
        raise OrderNotFound(order_id) from None


def list_orders(*, owner: User) -> QuerySet[Order]:
    return Order.objects.filter(owner=owner).prefetch_related("items").order_by("-created_at", "id")
```

- Keyword-only arguments (`*`) — call sites stay readable and safe to extend
- Side effects that must not happen if the transaction rolls back (emails, events, tasks) go in `transaction.on_commit`
- `save(update_fields=[...])` on updates, so concurrent writers don't overwrite each other's columns
- Scope by owner/tenant **in the selector**, so no view can forget it

---

## Models

```python
class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Order(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "PENDING"
        PAID = "PAID"
        CANCELLED = "CANCELLED"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="orders")
    customer_id = models.CharField(max_length=64)
    status = models.CharField(max_length=16, choices=Status.choices, default=Status.PENDING)

    class Meta:
        db_table = "orders"
        indexes = [models.Index(fields=["owner", "-created_at"])]

    @property
    def total(self) -> Decimal:
        return sum((item.subtotal for item in self.items.all()), Decimal("0"))
```

- `UUIDField` primary keys for anything exposed in a URL
- `TextChoices` for enums; `DecimalField` for money; `on_delete` chosen deliberately (`PROTECT` for business data)
- Constraints that must always hold go in the database: `models.UniqueConstraint`, `models.CheckConstraint`
- `null=True` never on `CharField`/`TextField` — use `blank=True` with an empty string
- Custom user model (`AUTH_USER_MODEL`) set from the start of the project

---

## Migrations

- `makemigrations` for every model change, review the generated file, commit it with the code
- CI runs `python manage.py makemigrations --check --dry-run` — a missing migration fails the build
- Never edit a migration that has been applied anywhere shared; add a new one
- Data migrations use `RunPython` with a reverse function and `apps.get_model(...)` (never import models directly)
- Large tables: add indexes with `AddIndexConcurrently` (`atomic = False` migration) and split "add column, backfill, add NOT NULL" into separate migrations

---

## Error Handling

Domain exceptions carry no HTTP knowledge; one DRF exception handler maps them — and DRF's own exceptions — to RFC 7807.

```python
# apps/core/exceptions.py
from rest_framework import exceptions as drf_exceptions
from rest_framework.views import exception_handler


class DomainError(Exception): ...
class ResourceNotFound(DomainError): ...          # not "NotFound": DRF already has one
class BusinessRuleViolation(DomainError): ...


def problem_exception_handler(exc: Exception, context: dict[str, Any]) -> Response:
    if isinstance(exc, ResourceNotFound):
        return problem(404, "Not found", str(exc))
    if isinstance(exc, BusinessRuleViolation):
        return problem(409, "Business rule violated", str(exc))
    if isinstance(exc, drf_exceptions.ValidationError):
        return problem(422, "Validation failed", errors=flatten_errors(exc.detail))

    response = exception_handler(exc, context)        # DRF: 401, 403, 404, 405, 429...
    if response is not None:
        return problem(response.status_code, response.status_text, str(exc))

    logger.exception("Unexpected error", exc_info=exc)
    return problem(500, "Internal error", "An unexpected error occurred")


def problem(status_code: int, title: str, detail: str | None = None, **extra: Any) -> Response:
    body = {"type": "about:blank", "title": title, "status": status_code, "detail": detail, **extra}
    return Response(body, status=status_code, content_type="application/problem+json")
```

Each app's `exceptions.py` subclasses these (`class OrderNotFound(ResourceNotFound)`, `class OrderNotCancellable(BusinessRuleViolation)`), so a new exception needs no new mapping.

DRF returns 400 for validation errors by default; the handler returns **422** to match the SDD `api-design` and `error-handling` skills. `flatten_errors` turns DRF's nested error dict into `[{"field": "items.0.quantity", "message": "..."}]`.

```python
# config/settings/base.py
REST_FRAMEWORK = {
    "EXCEPTION_HANDLER": "apps.core.exceptions.problem_exception_handler",
    "DEFAULT_AUTHENTICATION_CLASSES": ["rest_framework_simplejwt.authentication.JWTAuthentication"],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_PAGINATION_CLASS": "apps.core.pagination.DefaultPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}
```

---

## Configuration

```python
# config/settings/base.py
env = environ.Env()

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env.bool("DJANGO_DEBUG", default=False)
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=[])
DATABASES = {"default": env.db("DATABASE_URL")}
DATABASES["default"]["CONN_MAX_AGE"] = env.int("DB_CONN_MAX_AGE", default=60)
PAYMENT_API_URL = env("PAYMENT_API_URL")
PAYMENT_API_KEY = env("PAYMENT_API_KEY")
```

- `base.py` holds shared settings; `dev.py`/`prod.py` import from it and override; `DJANGO_SETTINGS_MODULE` selects one
- Every secret and environment-specific value comes from the environment; nothing secret is committed
- Code reads settings through `django.conf.settings`, never by importing the settings module

---

## Security

- Authentication: `djangorestframework-simplejwt` (or the project's OIDC provider); `IsAuthenticated` is the default permission — opt **out** per view with `AllowAny`, never opt in
- Object-level authorization: selectors filter by owner/tenant; role checks are DRF permission classes
- Production settings: `DEBUG = False`, `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS`; CI runs `python manage.py check --deploy`
- CORS with `django-cors-headers` and an explicit `CORS_ALLOWED_ORIGINS` list
- Never build SQL with string formatting — ORM, or `cursor.execute(sql, params)` with parameters
- Throttling (`DEFAULT_THROTTLE_CLASSES`) on authentication and other abuse-prone endpoints

---

## Observability

- **Logging**: `LOGGING` dict config with a JSON formatter in production; module-level `logger = logging.getLogger(__name__)`; a middleware adds a request id (from `X-Request-ID` or generated) to every log record
- **Health**: `GET /health/live` (no dependencies) and `GET /health/ready` (database `SELECT 1`), both `AllowAny` and excluded from request logging
- **Tracing**: `opentelemetry-instrumentation-django` + the psycopg instrumentation
- **Metrics**: `django-prometheus` (or OpenTelemetry metrics) exposed at `/metrics`
- **Query performance**: `django-debug-toolbar` in development; tests pin query counts on list endpoints (see `testing.md`)

---

## Testing

See `testing.md` for full testing guide. Quick rules:

- pytest + pytest-django + factory_boy
- Service and selector tests hit the test database (`@pytest.mark.django_db`) — they are the core of the suite
- API tests: DRF `APIClient` with `force_authenticate`, asserting status codes, problem bodies and query counts
- **Minimum coverage**: 80% on `services.py`, `selectors.py` and models

---

## What NOT to do

- ❌ Business logic in views, serializers (`create`/`update`), model `save()` overrides or signals
- ❌ Queries in views or serializers — use selectors, with `select_related`/`prefetch_related`
- ❌ `ModelSerializer` with `fields = "__all__"`, or one serializer for both input and output
- ❌ Unpaginated list endpoints, or `Model.objects.all()` without owner/tenant scoping
- ❌ Editing applied migrations, or importing models directly in data migrations
- ❌ Side effects (emails, events) inside a transaction without `transaction.on_commit`
- ❌ `null=True` on string fields, `FloatField` for money
- ❌ Raw SQL built with f-strings or `%` formatting
- ❌ `DEBUG = True` or secrets in committed settings
