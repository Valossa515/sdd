---
name: contract-schema
description: Schema definition for architecture contract files (.contract.yml)
---

# Architecture Contract Schema

Contracts define the technical implementation plan for a feature. They are **binding**: the builder creates exactly what the contract specifies, nothing more.

## Schema

```yaml
# .agent/specs/contracts/{feature-name}.contract.yml

contract:
  feature-ref: "FT-001"               # Links to feature spec
  version: "1.0"

layers:
  api:
    files:
      - path: "src/main/java/com/example/api/controller/OrderController.java"
        action: create
        description: "REST endpoint for order creation"
      - path: "src/main/java/com/example/api/dto/CreateOrderRequest.java"
        action: create
        description: "Request DTO with validation"
      - path: "src/main/java/com/example/api/dto/OrderResponse.java"
        action: create
        description: "Response DTO"

  application:
    files:
      - path: "src/main/java/com/example/application/service/OrderService.java"
        action: create
        description: "Service interface"
      - path: "src/main/java/com/example/application/service/OrderServiceImpl.java"
        action: create
        description: "Service implementation with business logic"

  domain:
    files:
      - path: "src/main/java/com/example/domain/model/Order.java"
        action: create
        description: "Order entity with invariants"
      - path: "src/main/java/com/example/domain/repository/OrderRepository.java"
        action: create
        description: "Repository port (interface)"

  infrastructure:
    files:
      - path: "src/main/java/com/example/infrastructure/persistence/JpaOrderRepository.java"
        action: create
        description: "JPA repository adapter"

migrations:
  - file: "V3__create_orders_table.sql"
    description: "Create orders table with indexes"

dependencies:
  uses:
    - "CustomerRepository (existing)"
    - "StockService (existing)"
  introduces: []    # empty = no new external dependencies

test-strategy:
  unit-tests:
    - target: "OrderServiceImpl"
      scenarios:
        - "create-order-happy-path"
        - "customer-not-found"
        - "empty-items-rejected"
        - "total-calculated-correctly"

  integration-tests:
    - target: "OrderController"
      type: "controller-slice"
      scenarios:
        - "post-order-returns-201"
        - "post-order-invalid-customer-returns-404"
        - "post-order-empty-items-returns-422"
    - target: "JpaOrderRepository"
      type: "database"
      scenarios:
        - "save-and-find-by-id"

  excluded:
    - target: "CreateOrderRequest"
      reason: "Pure data class with no logic"
    - target: "OrderResponse"
      reason: "Pure data class with no logic"
```

## Required Fields

| Field | Description | Required |
|-------|-------------|----------|
| `contract.feature-ref` | Feature spec reference (FT-NNN) | ✅ |
| `layers.*.files` | Files to create/modify per layer | ✅ |
| `layers.*.files[].action` | `create` or `modify` | ✅ |
| `migrations` | Database changes (empty list if none) | ✅ |
| `dependencies.uses` | Existing code this feature depends on | ✅ |
| `dependencies.introduces` | New dependencies added (empty if none) | ✅ |
| `test-strategy.unit-tests` | Unit tests to create | ✅ |
| `test-strategy.integration-tests` | Integration tests to create | ✅ |
| `test-strategy.excluded` | What NOT to test and why | ✅ |

## Validation Rules

1. Every file must have a valid `action` (`create` or `modify`)
2. Every file in `layers` must map to a requirement in the feature spec
3. `test-strategy` scenarios must cover all `must-have` acceptance criteria
4. `excluded` items must have a `reason`
5. `dependencies.uses` must reference classes that exist in the project
6. No file should appear in multiple layers
