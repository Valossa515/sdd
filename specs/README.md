# Specification Schemas

SDD uses structured YAML specifications to keep requirements unambiguous and traceable. Every line of generated code must trace back to a spec.

## Specification Types

| Type | Schema | Purpose | Created by |
|------|--------|---------|------------|
| Feature | [feature.schema.md](feature.schema.md) | Business behavior definition | planner |
| Acceptance | [acceptance.schema.md](acceptance.schema.md) | Testable success/failure criteria | planner |
| Contract | [contract.schema.md](contract.schema.md) | Technical architecture decisions | architect |

## Flow

```
requirement → feature.spec.yml → acceptance.spec.yml → contract.spec.yml → code
```

Each downstream artifact references its upstream source. This creates a traceability chain from requirement to code.

## Where Specs Live

When installed in a project:

```
.agent/
└── specs/
    ├── features/        ← feature specifications
    ├── acceptance/      ← acceptance criteria
    └── contracts/       ← architecture contracts
```

## Principles

1. **Spec before code** — no code without a spec (or at minimum, a contract)
2. **Traceable** — every spec has an `id` that downstream artifacts reference
3. **Deterministic** — same spec → same code (agents must not add undocumented behavior)
4. **Validated** — specs are checked against schemas before use (see `skills/shared/spec-validation.md`)
