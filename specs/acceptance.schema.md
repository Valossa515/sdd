---
name: acceptance-schema
description: Schema definition for acceptance criteria files (.acceptance.yml)
---

# Acceptance Criteria Schema

Acceptance criteria define the testable conditions that prove a feature works correctly. Each criterion maps to at least one test.

## Schema

```yaml
# .agent/specs/acceptance/{feature-name}.acceptance.yml

acceptance:
  feature-ref: "FT-001"               # Links to feature spec
  version: "1.0"

criteria:
  - id: "AC-001"
    scenario: "Create order with valid data"
    given: "A customer with ID exists and items are in stock"
    when: "POST /api/v1/orders with valid body"
    then: "Returns 201 with new order ID and status PENDING"
    priority: must-have

  - id: "AC-002"
    scenario: "Reject order for non-existent customer"
    given: "customer_id does not exist in the database"
    when: "POST /api/v1/orders with invalid customer_id"
    then: "Returns 404 with error code CUSTOMER_NOT_FOUND"
    priority: must-have

  - id: "AC-003"
    scenario: "Reject order with empty items"
    given: "items list is empty"
    when: "POST /api/v1/orders with empty items"
    then: "Returns 422 with error code EMPTY_ORDER"
    priority: must-have

  - id: "AC-004"
    scenario: "Verify order total calculation"
    given: "Order with 2 items: item A (qty 3, price 1000) and item B (qty 1, price 2500)"
    when: "Order is created"
    then: "Order total equals 5500"
    priority: must-have
    business-rule-ref: "BR-001"
```

## Required Fields

| Field | Description | Required |
|-------|-------------|----------|
| `acceptance.feature-ref` | Feature spec this relates to | ✅ |
| `criteria[].id` | Unique ID (AC-NNN) | ✅ |
| `criteria[].scenario` | Short description | ✅ |
| `criteria[].given` | Preconditions | ✅ |
| `criteria[].when` | Action performed | ✅ |
| `criteria[].then` | Expected outcome | ✅ |
| `criteria[].priority` | must-have · should-have · nice-to-have | ✅ |
| `criteria[].business-rule-ref` | Reference to BR-NNN (if applicable) | ⚠️ |

## Validation Rules

1. `feature-ref` must match an existing feature spec ID
2. Every error in the feature spec must have at least one acceptance criterion
3. Every business rule should be covered by at least one criterion
4. Criterion IDs must be unique within a file
5. All `must-have` criteria must be covered by the test strategy in the contract
