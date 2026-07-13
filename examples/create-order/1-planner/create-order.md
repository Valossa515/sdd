# Plan: Create Order

## Summary
Allow an authenticated user to create an order with one or more items. The
server validates the customer and stock, recalculates the total from catalog
prices, and persists the order with status `PENDING`.

## Scope
- **Layers affected**: API / Application / Domain / Infrastructure
- **New files**: order controller + DTOs, order service, order entity + repository port, JPA adapter
- **Modified files**: none (feature is additive)

## Approach
Follow the existing layered architecture (see `skills/spring-boot/SKILL.md`):
controller → service interface → domain entity → repository port → JPA adapter.
Request validation via Bean Validation on the DTO; error responses follow
RFC 7807 (`skills/shared/error-handling/SKILL.md`). Endpoint design follows
`skills/shared/api-design/SKILL.md` (POST returns 201 + Location header).

## Tasks
1. [ ] Feature spec + acceptance criteria (this stage)
2. [ ] Architecture contract (architect)
3. [ ] API layer — `POST /api/v1/orders` controller and DTOs
4. [ ] Application layer — `OrderService` with customer/stock validation
5. [ ] Domain layer — `Order` entity with total-calculation invariant
6. [ ] Infrastructure layer — JPA repository adapter + migration
7. [ ] Tests per contract test strategy (tester)

## Database changes
- New table: `orders` (id, customer_id, status, total_cents) + `order_items` collection table
- New migration: `V3__create_orders_table.sql`

## Risks & open questions
- Stock reservation semantics (reserve vs. verify-only) — assumed verify-only for BATCH-01
- TODO: payment flow is out of scope for this feature

## Acceptance criteria
- [ ] Valid request returns 201 with generated ID and status PENDING (AC-001)
- [ ] Unknown customer returns 404 CUSTOMER_NOT_FOUND (AC-002)
- [ ] Empty items list returns 422 EMPTY_ORDER (AC-003)
- [ ] Total equals Σ(price × quantity), computed server-side (AC-004 / BR-001)
