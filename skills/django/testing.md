---
name: django-testing
description: Testing guide for Django + DRF projects. Service and selector tests on the test database, API tests with APIClient, factory_boy test data, and query-count assertions.
stack: django
versions: "Python 3.12+, pytest, pytest-django, factory_boy, Django REST Framework"
---

# Django Testing

## Dependencies and configuration

```toml
# pyproject.toml
[dependency-groups]
dev = ["pytest", "pytest-django", "pytest-cov", "factory-boy"]

[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings.test"
python_files = ["test_*.py"]
addopts = "--reuse-db --strict-markers"
```

```python
# config/settings/test.py
from .base import *  # noqa: F403

PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]   # fast user creation
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
```

Run the tests against **PostgreSQL**, the same engine as production — a CI service container or Testcontainers. SQLite hides differences in constraints, JSON fields, `select_for_update` and case sensitivity.

```
apps/orders/tests/
├── factories.py
├── test_services.py
├── test_selectors.py
└── test_api.py
```

---

## Test Data — factory_boy

One factory per model, with defaults that produce a valid object. Tests override only what they assert on.

```python
# apps/orders/tests/factories.py
class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = settings.AUTH_USER_MODEL

    email = factory.Sequence(lambda n: f"user{n}@example.com")


class OrderFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Order

    owner = factory.SubFactory(UserFactory)
    customer_id = "customer-test"
    status = Order.Status.PENDING


class OrderItemFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = OrderItem

    order = factory.SubFactory(OrderFactory)
    product_id = factory.Sequence(lambda n: f"product-{n}")
    quantity = 1
```

---

## Service Tests

Services are the core of the suite. They run against the test database — mocking the ORM tests nothing useful.

```python
pytestmark = pytest.mark.django_db


def test_create_order_persists_order_and_items() -> None:
    owner = UserFactory()

    order = create_order(
        owner=owner,
        customer_id="c-1",
        items=[{"product_id": "p-1", "quantity": 2}, {"product_id": "p-2", "quantity": 1}],
    )

    assert order.status == Order.Status.PENDING
    assert order.items.count() == 2


def test_cancel_order_raises_when_order_already_paid() -> None:
    order = OrderFactory(status=Order.Status.PAID)

    with pytest.raises(OrderNotCancellable):
        cancel_order(order_id=order.id, owner=order.owner)


def test_create_order_sends_confirmation_only_after_commit(django_capture_on_commit_callbacks) -> None:
    with django_capture_on_commit_callbacks(execute=True) as callbacks:
        create_order(owner=UserFactory(), customer_id="c-1", items=[{"product_id": "p-1", "quantity": 1}])

    assert len(callbacks) == 1
```

`django_capture_on_commit_callbacks` is needed because pytest-django wraps each test in a transaction that never commits, so `on_commit` callbacks would otherwise never run.

---

## Selector Tests

Selectors carry the tenant scoping — test that it holds.

```python
pytestmark = pytest.mark.django_db


def test_get_order_raises_for_another_owners_order() -> None:
    order = OrderFactory()

    with pytest.raises(OrderNotFound):
        get_order(order_id=order.id, owner=UserFactory())


def test_list_orders_returns_only_the_owners_orders_newest_first() -> None:
    owner = UserFactory()
    older, newer = OrderFactory(owner=owner), OrderFactory(owner=owner)
    OrderFactory()   # someone else's

    assert list(list_orders(owner=owner)) == [newer, older]
```

---

## API Tests — APIClient

Use DRF's `APIClient` with `force_authenticate`: it exercises routing, permissions, serializers and the exception handler without dealing with real tokens.

```python
pytestmark = pytest.mark.django_db


@pytest.fixture
def owner() -> User:
    return UserFactory()


@pytest.fixture
def api(owner: User) -> APIClient:
    client = APIClient()
    client.force_authenticate(user=owner)
    return client


def test_get_order_returns_200_for_the_owner(api: APIClient, owner: User) -> None:
    order = OrderFactory(owner=owner)

    response = api.get(reverse("orders:order-detail", kwargs={"order_id": order.id}))

    assert response.status_code == 200
    assert response.json()["id"] == str(order.id)


def test_get_order_returns_404_problem_for_another_owners_order(api: APIClient) -> None:
    order = OrderFactory()

    response = api.get(reverse("orders:order-detail", kwargs={"order_id": order.id}))

    assert response.status_code == 404
    assert response["Content-Type"] == "application/problem+json"


def test_create_order_returns_422_when_items_empty(api: APIClient) -> None:
    response = api.post(reverse("orders:order-list"), {"customer_id": "c-1", "items": []}, format="json")

    assert response.status_code == 422
    assert response.json()["errors"][0]["field"] == "items"


def test_get_order_returns_401_without_authentication() -> None:
    response = APIClient().get(reverse("orders:order-detail", kwargs={"order_id": uuid4()}))

    assert response.status_code == 401


def test_list_orders_runs_a_constant_number_of_queries(api: APIClient, owner: User, django_assert_max_num_queries) -> None:
    for order in OrderFactory.create_batch(10, owner=owner):
        OrderItemFactory.create_batch(3, order=order)

    with django_assert_max_num_queries(4):    # auth + count + orders + prefetched items
        response = api.get(reverse("orders:order-list"))

    assert response.status_code == 200
```

- Every endpoint gets: one success case, each error status it can return, the unauthenticated case, and — for list endpoints — a query-count test that would catch an N+1
- Use `reverse()` with URL names, never hard-coded paths

---

## Migrations in CI

```bash
python manage.py makemigrations --check --dry-run   # fails if a model change has no migration
python manage.py check --deploy --settings=config.settings.prod
```

---

## Naming Convention for Tests

`test_<unit>_<expected>_when_<condition>` (or `..._for_<case>`) — the name alone says what broke.

```
test_create_order_persists_order_and_items
test_cancel_order_raises_when_order_already_paid
test_get_order_returns_404_problem_for_another_owners_order
```

Run with coverage: `pytest --cov=apps --cov-report=term-missing`.

---

## What NOT to do

- ❌ Mocking the ORM in service tests — use the test database
- ❌ SQLite for tests when production runs PostgreSQL
- ❌ Fixtures in JSON files (`fixtures=[...]`) — use factory_boy
- ❌ Hard-coded URLs — use `reverse()`
- ❌ List endpoint tests without a query-count assertion
