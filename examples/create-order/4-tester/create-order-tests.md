# Test Plan: Create Order

## Scope
Order creation flow: `POST /api/v1/orders` — service orchestration, API status
codes/error mapping, and JPA persistence round-trip. Mirrors the contract's
test strategy exactly (`2-architect/create-order.contract.toon`).

## Unit tests

### OrderServiceImpl
| # | Scenario | Method | Expected result |
|---|----------|--------|-----------------|
| 1 | create-order-happy-path | createOrder | Returns response with ID, status PENDING (AC-001) |
| 2 | customer-not-found | createOrder | Throws CustomerNotFoundException (AC-002) |
| 3 | empty-items-rejected | createOrder | Throws EmptyOrderException (AC-003) |
| 4 | total-calculated-correctly | createOrder | Total = Σ(price × quantity) = 5500 (AC-004 / BR-001) |

## Integration tests

### OrderController (controller slice)
| # | Scenario | Method | Endpoint | Expected status |
|---|----------|--------|----------|-----------------|
| 1 | post-order-returns-201 | POST | /api/v1/orders | 201 Created + Location header |
| 2 | post-order-invalid-customer-returns-404 | POST | /api/v1/orders | 404 + code CUSTOMER_NOT_FOUND |
| 3 | post-order-empty-items-returns-422 | POST | /api/v1/orders | 422 + code EMPTY_ORDER |

### JpaOrderRepository (database)
| # | Scenario | Expected result |
|---|----------|-----------------|
| 1 | save-and-find-by-id | Saved order (with items) is found intact by ID |

## Edge cases
- Items list at the max boundary (50) is accepted; 51 rejected by validation
- Quantity must be positive (Bean Validation on the DTO)

## Test data & fixtures
- Valid request: customer `c0a8...`, item A (qty 3, price 1000), item B (qty 1, price 2500)
- Priced items come from a mocked `StockService`

## Infrastructure
- Mockito for unit tests
- MockMvc (`@WebMvcTest`) for the controller slice, `OrderService` mocked
- Testcontainers PostgreSQL + `@DataJpaTest` for the repository test

## Excluded (per contract)
- `CreateOrderRequest`, `OrderResponse` — pure data classes with no logic
