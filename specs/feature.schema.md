---
name: feature-schema
description: Schema definition for feature specification files (.spec.yml)
---

# Feature Specification Schema

Feature specs define **WHAT** the system should do in business terms. They contain no technical decisions — only behavior.

## Schema

```yaml
# .agent/specs/features/{feature-name}.spec.yml

feature:
  id: "FT-001"                        # Unique ID (FT-NNN)
  name: "Create Order"                 # Human-readable name
  version: "1.0"                       # Spec revision
  status: draft | ready | approved     # Lifecycle status

requirement:
  summary: |
    One paragraph describing the feature from the user's perspective.
  actor: "Authenticated User"          # Who triggers this
  trigger: "POST /api/v1/orders"       # How it starts (optional)

inputs:
  - name: customer_id
    type: UUID
    required: true
    constraints: "Must reference an existing customer"
  - name: items
    type: list
    required: true
    constraints: "At least 1 item, max 50 items"

outputs:
  success:
    description: "Order is created and returned with generated ID"
    status: 201
    body:
      - name: id
        type: UUID
      - name: status
        type: string
        value: "PENDING"
  errors:
    - code: "CUSTOMER_NOT_FOUND"
      status: 404
      when: "customer_id does not exist"
    - code: "EMPTY_ORDER"
      status: 422
      when: "items list is empty"

business-rules:
  - id: "BR-001"
    rule: "Order total must be recalculated from item prices × quantities"
  - id: "BR-002"
    rule: "Stock must be validated before accepting the order"

assumptions:
  - "Currency is always BRL"
  - "Prices are stored in cents (integer)"

batches:
  - id: "BATCH-01"
    scope: "Core order creation (happy path)"
    estimate: "1-2 days"
  - id: "BATCH-02"
    scope: "Error handling and edge cases"
    estimate: "1 day"
```

## Required Fields

| Field | Description | Required |
|-------|-------------|----------|
| `feature.id` | Unique identifier (FT-NNN) | ✅ |
| `feature.name` | Human-readable name | ✅ |
| `requirement.summary` | What the feature does | ✅ |
| `inputs` | Input parameters with types and constraints | ✅ |
| `outputs.success` | Expected success response | ✅ |
| `outputs.errors` | Expected error responses | ✅ |
| `business-rules` | Explicit business rules with unique IDs | ✅ |
| `assumptions` | Assumptions made during planning | ⚠️ |
| `batches` | Decomposition for large features | ⚠️ |

## Validation Rules

1. Every input must have `name`, `type`, and `required`
2. Every error must have `code`, `status`, and `when`
3. Business rules must have unique IDs (BR-NNN)
4. If the feature estimate > 2 days, `batches` is required
5. Assumptions must always be flagged explicitly
