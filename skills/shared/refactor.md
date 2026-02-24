---
name: refactor
description: Use this skill when the user calls @refactor. Analyzes existing code for smells and structural issues, then proposes and applies safe refactorings aligned with project conventions.
stack: shared
versions: "SDD 1.x"
---

# @refactor — Guided Refactoring

Use this skill when the user invokes `@refactor`.

## Trigger

```
@refactor
@refactor <file or path>
@refactor <specific goal>
```

**Examples:**
```
@refactor OrderService.java está muito grande
@refactor src/orders/ — extrair lógica de pricing para um domain service
@refactor eliminar duplicação entre CreateOrderHandler e UpdateOrderHandler
```

---

## Input

1. File(s) or path to refactor — or a description of the code smell
2. Optional goal: extract method, reduce complexity, apply pattern, etc.
3. If no input given, ask the user what they want to improve

---

## Context to Read First

Before refactoring:
1. `.agent/SKILLS.md` — active skills, stack version, conventions
2. `.agent/conventions.md` — naming and structure rules
3. The stack skill — architecture patterns to target
4. Existing tests for the code to be changed

---

## Workflow

### Step 1 — Understand the Current State
- Read all files in scope
- Identify the code smell(s) present (see catalogue below)
- Check if tests exist — if not, note it as a prerequisite

### Step 2 — Define the Refactoring
- Name the refactoring technique(s) to apply
- Describe the before/after structure
- List files that will change
- Confirm: does this change observable behavior? (It must not)

### Step 3 — Verify Tests Exist
- If tests don't exist for the code to change: **write tests first**, then refactor
- This protects against regressions

### Step 4 — Apply the Refactoring
- Make changes in small, focused commits
- Run tests after each logical step
- Do not add new features during refactoring

### Step 5 — Report
- Describe what changed and why
- Confirm tests still pass

---

## Code Smell Catalogue

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Long Method** | Method > 30 lines | Extract Method |
| **Large Class** | Class > 300 lines | Extract Class, Move Method |
| **Feature Envy** | Method uses another class more than its own | Move Method |
| **Data Clumps** | Same 3+ fields always together | Extract Class/Record |
| **Primitive Obsession** | String/int used for domain concepts | Introduce Value Object |
| **Long Parameter List** | Method takes 4+ parameters | Introduce Parameter Object |
| **Duplicate Code** | Same logic in 2+ places | Extract Method, Template Method |
| **Dead Code** | Unreachable or unused code | Delete It |
| **God Service** | Service handles unrelated operations | Split Service |
| **Anemic Domain** | All logic in services, entities are data bags | Move logic to domain |
| **Inappropriate Intimacy** | Class accesses internals of another | Move Method, Extract Interface |
| **Shotgun Surgery** | One change requires edits in many places | Move Method, Inline Class |
| **Switch on Type** | `if/else` or `switch` on type field | Polymorphism, Strategy Pattern |

---

## Safe Refactoring Rules

- **Never change behavior** — refactoring is purely structural
- **Always have tests before changing** — write them if missing
- **One refactoring at a time** — do not mix multiple transforms in one commit
- **Rename clearly** — if renaming, use IDE rename refactoring to catch all references
- **Keep commits small** — one logical change per commit

---

## Example: Extract Domain Service

**Before:**
```java
// OrderServiceImpl.java — 400 lines, pricing logic mixed with persistence
public OrderResponse create(CreateOrderRequest request) {
    // 40 lines of pricing calculation...
    BigDecimal subtotal = items.stream()
        .map(i -> i.getPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
        .reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal discount = subtotal.compareTo(new BigDecimal("100")) > 0
        ? subtotal.multiply(new BigDecimal("0.1")) : BigDecimal.ZERO;
    BigDecimal total = subtotal.subtract(discount);
    // save order...
}
```

**After:**
```java
// PricingService.java — new domain service
public class PricingService {
    public OrderPricing calculate(List<OrderItem> items) {
        BigDecimal subtotal = items.stream()
            .map(i -> i.getPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal discount = subtotal.compareTo(new BigDecimal("100")) > 0
            ? subtotal.multiply(new BigDecimal("0.1")) : BigDecimal.ZERO;
        return new OrderPricing(subtotal, discount, subtotal.subtract(discount));
    }
}

// OrderServiceImpl.java — focused on coordination only
public OrderResponse create(CreateOrderRequest request) {
    OrderPricing pricing = pricingService.calculate(items);
    // save order...
}
```

---

## What NOT to do

- Do not add features while refactoring — separate PR
- Do not rename public APIs (breaking change) — discuss first
- Do not refactor without tests in place
- Do not change multiple smells at once — one at a time
- Do not introduce new dependencies or frameworks during a refactor
