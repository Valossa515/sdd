# Architecture: Create Order

## Summary
Additive feature following the existing layered architecture: thin controller,
service orchestrating validation, domain entity owning the total-calculation
invariant, JPA adapter behind a repository port.

## Pattern Analysis
- **Existing patterns found**: `CustomerController` (controller + record DTOs),
  `CustomerServiceImpl` (interface + impl, constructor injection),
  `JpaCustomerRepository` (port in domain, adapter in infrastructure)
- **Pattern followed**: same controller → service → port → adapter chain

## Layer Decisions

| Layer | Decision | Justification |
|-------|----------|---------------|
| API | `OrderController` + record DTOs | Follows existing controller pattern; Bean Validation on the request record |
| Application | `OrderService` interface + impl | Matches existing service layer; orchestrates customer/stock checks |
| Domain | `Order` entity with invariants | BR-001 (total) and EMPTY_ORDER enforced in the factory method, not in the service |
| Infrastructure | `JpaOrderRepository` adapter | Same adapter style as existing repositories |

## Dependencies
- **Reusing**: `CustomerRepository` (customer existence check → CUSTOMER_NOT_FOUND),
  `StockService` (BR-002 stock validation + catalog pricing),
  `GlobalExceptionHandler` (maps domain exceptions to RFC 7807 responses)
- **New**: none

## Database Changes
- `V3__create_orders_table.sql`: `orders` table + `order_items` collection table
- Index on `orders.customer_id` — orders will be queried by customer

## Test Strategy Rationale
- `OrderServiceImpl` gets unit tests: it holds the orchestration logic and all
  four failure/success paths are observable through it
- `OrderController` gets a controller-slice test: status codes and error mapping
  are API behavior, not unit behavior
- `JpaOrderRepository` gets one database round-trip test: mapping + collection table
- DTOs are excluded: pure data classes with no logic

## Trade-offs & Alternatives Considered
- Price on the request DTO — rejected: totals must never be trusted from the
  client (requirement); prices come from `StockService`
- Separate `OrderItem` entity/table with its own repository — rejected:
  items have no identity outside an order; an `@ElementCollection` is enough
  for this batch

## Risks
- Verify-only stock check can race with concurrent orders — acceptable for
  BATCH-01; reservation semantics tracked as a follow-up
