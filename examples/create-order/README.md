# Example: Create Order — a full pipeline run

This directory is a **snapshot of one feature going through the complete SDD
pipeline**, stage by stage. Every artifact here is in the exact format its
agent role defines. Use it to understand what SDD produces before installing
it in your own project.

```
requirement → planner → architect → builder → tester → reviewer
```

> **Note:** the Java sources are an illustrative snapshot of the *generated*
> files only. Pre-existing project classes referenced by the contract
> (`CustomerRepository`, `StockService`, domain exceptions, the RFC 7807
> `GlobalExceptionHandler`) are assumed to already exist in the host project
> and are not part of this feature's diff.

## The run

### Stage 0 — the requirement

One paragraph from the user: [`0-requirement.md`](0-requirement.md). No specs,
no design — that's the pipeline's job.

### Stage 1 — planner (`/sdd:plan` or `@planning`)

The planner ran gap analysis (stock semantics was flagged, resolved as
verify-only), then produced its three artifacts together:

| Artifact | File |
|----------|------|
| Plan document | [`1-planner/create-order.md`](1-planner/create-order.md) |
| Feature spec | [`1-planner/create-order.spec.toon`](1-planner/create-order.spec.toon) |
| Acceptance criteria | [`1-planner/create-order.acceptance.toon`](1-planner/create-order.acceptance.toon) |

Note the traceability IDs: the feature is `FT-001`, business rules are
`BR-001`/`BR-002`, acceptance criteria are `AC-001`…`AC-004`. Everything
downstream references them.

**🚦 Gate:** user confirmed the plan and specs → proceed.

### Stage 2 — architect (`/sdd:architect`)

The architect read the spec + acceptance criteria and produced the *why* and
the *what*:

| Artifact | File |
|----------|------|
| Architecture decisions | [`2-architect/create-order-architecture.md`](2-architect/create-order-architecture.md) |
| Binding contract | [`2-architect/create-order.contract.toon`](2-architect/create-order.contract.toon) |

The contract lists **exactly 8 files + 1 migration** across 4 layers, the
dependencies to reuse, and a binding test strategy (8 scenarios, 2 exclusions
with reasons).

**🚦 Gate:** user confirmed the contract → proceed.

### Stage 3 — builder (`/sdd:implement`)

The builder created **exactly** what the contract specifies — nothing more:

```
3-builder/src/main/java/com/example/
├── api/controller/OrderController.java          # 201 + Location header
├── api/dto/CreateOrderRequest.java              # Bean Validation, max 50 items
├── api/dto/OrderResponse.java
├── application/service/OrderService.java
├── application/service/OrderServiceImpl.java    # BR-002: stock before accept
├── domain/model/Order.java                      # BR-001: total invariant lives here
├── domain/repository/OrderRepository.java       # port
└── infrastructure/persistence/JpaOrderRepository.java  # adapter
3-builder/src/main/resources/db/migration/
└── V3__create_orders_table.sql                  # + index on customer_id
```

**🚦 Gate:** code compiles → proceed.

### Stage 4 — tester (`/sdd:test`)

The tester derived the test plan from the contract's test strategy and then
wrote one test per scenario — no more, no less:

| Artifact | File |
|----------|------|
| Test plan | [`4-tester/create-order-tests.md`](4-tester/create-order-tests.md) |
| Unit tests (4 scenarios) | [`4-tester/.../OrderServiceImplTest.java`](4-tester/src/test/java/com/example/application/service/OrderServiceImplTest.java) |
| Controller slice (3 scenarios) | [`4-tester/.../OrderControllerIT.java`](4-tester/src/test/java/com/example/api/controller/OrderControllerIT.java) |
| Database round-trip (1 scenario) | [`4-tester/.../JpaOrderRepositoryIT.java`](4-tester/src/test/java/com/example/infrastructure/persistence/JpaOrderRepositoryIT.java) |

**🚦 Gate:** tests compile & pass → proceed.

### Stage 5 — reviewer (`/sdd:review`)

The reviewer delivers its verdict **in chat, never as a repository file**
(that is one of its constraints), so this is the transcript of what it replied:

> ## Review: Create Order (FT-001)
>
> **Verdict:** ✅ Approved
>
> ### Summary
> Implementation matches the spec and the contract. All 8 acceptance-relevant
> scenarios are covered by the test strategy. LGTM.
>
> ### Findings
>
> #### 🔵 Suggestion
> 1. **[SKILL.md]** `Order.getItems()` could return an unmodifiable view to
>    protect the invariant after loading from JPA
>    - File: `domain/model/Order.java`
>
> ### Spec Alignment: PASS
> AC-001…AC-004 all implemented; BR-001 enforced in the domain entity,
> BR-002 in the service. No extra features beyond the spec.
>
> ### Contract Alignment: PASS
> Only the 8 contracted files + migration were created. Layer dependencies
> follow api → application → domain ← infrastructure.
>
> ### Code Quality: PASS
> Constructor injection, record DTOs, RFC 7807 mapping via the existing
> handler, index on `orders.customer_id` present.
>
> ### Test Quality: PASS
> One test per contracted scenario, AAA pattern, naming convention followed,
> DTOs excluded as contracted.

## Reproduce this run in your project

With the [Claude Code plugin](../../README.md#option-0-as-a-claude-code-plugin-recommended-for-claude-code-users) installed:

```text
/sdd:pipeline order creation with stock validation and server-side totals
```

Or stage by stage with any agent that reads markdown context:

```text
@planning  Plan the feature: order creation with stock validation ...
@implementation  Execute the plan in .agent/plans/create-order.md
@test  Write tests for the Order module following the test plan
@review  Review the changes in the current branch against main
```

The `.toon` specs in this example validate against the SDD schemas — run:

```bash
bash scripts/validate-spec.sh examples/create-order
```
