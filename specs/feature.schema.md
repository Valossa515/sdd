---
name: feature-schema
description: Schema definition for feature specification files (.spec.toon)
---

# Feature Specification Schema

Feature specs define **WHAT** the system should do in business terms. They contain no technical decisions — only behavior.

## Format

All feature specs use **TOON v3.0** (Token-Oriented Object Notation) — a compact, token-efficient format optimized for LLM consumption. See `specs/README.md` for the TOON syntax reference.

## Schema

```toon
# TOON v3.0 – Feature Specification
# .agent/specs/features/{feature-name}.spec.toon

feature:
  id: FT-001
  name: Create Order
  version: 1.0
  status: draft
  estimate-lines: 700

requirement:
  summary: One paragraph describing the feature from the user's perspective.
  actor: Authenticated User
  trigger: POST /api/v1/orders

inputs[2]{name,type,required,constraints}:
  customer_id,UUID,true,Must reference an existing customer
  items,list,true,At least 1 item and max 50 items

outputs:
  success:
    description: Order is created and returned with generated ID
    status: 201
    body[2]{name,type,value}:
      id,UUID,
      status,string,PENDING
  errors[2]{code,status,when}:
    CUSTOMER_NOT_FOUND,404,customer_id does not exist
    EMPTY_ORDER,422,items list is empty

business-rules[2]{id,rule}:
  BR-001,Order total must be recalculated from item prices × quantities
  BR-002,Stock must be validated before accepting the order

assumptions[2]:
  Currency is always BRL
  Prices are stored in cents (integer)

batches[2]{id,scope,estimate}:
  BATCH-01,Core order creation (happy path),400 lines
  BATCH-02,Error handling and edge cases,300 lines
```

## Size and batches

`feature.estimate-lines` is the planner's estimate of the lines of code and tests the feature adds or changes. The feature's own SDD artifacts (plan, architecture, spec, acceptance, contract, test plan) do not count.

One pull request carries at most **500 lines**. Above that, the spec needs one of:

- `batches`: each batch is one pull request that builds, passes its tests and can be reviewed on its own. The `estimate` column holds lines
- `feature.single-pr-reason`: why the feature ships as one pull request anyway, for example when most of the lines are one parameterized test and no cut ships on its own

```toon
feature:
  id: FT-011
  name: Installed Apps Inventory
  interface: library
  estimate-lines: 600
  single-pr-reason: Most lines are one parameterized test; there is no cut that ships on its own
```

## Interface (features that are not HTTP endpoints)

`feature.interface` says how the feature is reached. It is optional and defaults to `http`, so existing specs stay valid. It decides what `status` means in `outputs.success` and `outputs.errors`:

| `interface` | The feature is | `trigger` example | `status` holds | Example |
|-------------|----------------|-------------------|----------------|---------|
| `http` (default) | An HTTP endpoint | `POST /api/v1/orders` | HTTP status, 3 digits | `201`, `404` |
| `command` | A CLI command, build or script | `./gradlew build` | Exit code, an integer | `0`, `1` |
| `ui` | A screen or user interaction | `User taps "Scan now"` | The UI state shown | `Content`, `Error`, `Empty` |
| `library` | A function or use case called by other code | `ScanDevice(trigger)` | The result type returned | `Success`, `UnsupportedCard` |
| `background` | A scheduled job, worker or event handler | `Periodic work every 6 hours` | The outcome reported | `Success`, `Retry`, `Failure` |

For `ui`, `library` and `background`, `status` is an identifier: letters, digits, `_`, `.` and `-`, starting with a letter. Use the name the code will use (a sealed result subtype, a `UiState` case, a worker result), so the spec and the code share one vocabulary.

```toon
feature:
  id: FT-002
  name: Scan Installed Apps
  interface: ui

requirement:
  summary: Show the user whether any installed app has a scam profile.
  actor: App user
  trigger: User taps "Scan now" on the home screen

inputs[1]{name,type,required,constraints}:
  trigger,ScanTrigger,true,MANUAL when started by the user

outputs:
  success:
    description: The device risk level and the list of risky apps are shown
    status: Content
  errors[2]{code,status,when}:
    NO_SCAN_YET,Empty,no scan has ever completed
    SCAN_FAILED,Error,the app inventory cannot be read

business-rules[1]{id,rule}:
  BR-001,Risk is never shown by color alone
```

## Required Fields

| Field | Description | Required |
|-------|-------------|----------|
| `feature.id` | Unique identifier (FT-NNN) | ✅ |
| `feature.name` | Human-readable name | ✅ |
| `feature.interface` | `http` (default), `command`, `ui`, `library` or `background` | ⚠️ when not HTTP |
| `requirement.summary` | What the feature does | ✅ |
| `inputs` | Input parameters with types and constraints | ✅ |
| `outputs.success` | Expected success response | ✅ |
| `outputs.errors` | Expected error responses | ✅ |
| `business-rules` | Explicit business rules with unique IDs | ✅ |
| `assumptions` | Assumptions made during planning | ⚠️ |
| `feature.estimate-lines` | Estimated lines of code and tests, SDD artifacts excluded | ⚠️ |
| `batches` | Decomposition, one pull request per batch | ✅ when `estimate-lines` > 500, unless `single-pr-reason` |
| `feature.single-pr-reason` | Why a feature above 500 lines ships as one pull request | ⚠️ |

## Validation Rules

1. Every input must have `name`, `type`, and `required`
2. Every error must have `code`, `status`, and `when`. `status` follows `feature.interface`: 3 digits for `http`, an integer for `command`, an identifier for `ui`, `library` and `background`
3. Business rules must have unique IDs (BR-NNN)
4. `feature.estimate-lines`, when present, is a positive integer. Above 500, `batches` or `feature.single-pr-reason` is required. Batch ids follow `BATCH-NN` and are unique
5. Assumptions must always be flagged explicitly
6. `feature.interface`, when present, must be one of the five values above
