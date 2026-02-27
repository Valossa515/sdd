---
name: implementation
description: >
  Redirects to the builder agent. The @implementation command triggers the builder,
  which reads the plan document or architecture contract and generates production code
  following all project skills and conventions.
stack: shared
versions: "SDD 1.x"
---

# Implementation — Integrated into Builder Agent

The `@implementation` command is now handled by the **builder agent** (`agents/builder.md`), which supports two modes:

| Mode | Input | When |
|------|-------|------|
| **Pipeline** | `.contract.toon` + `.spec.toon` + architecture decisions `.md` | Via conductor |
| **Manual** | `.agent/plans/<feature-name>.md` | User invokes `@implementation` directly |

## Quick command

```text
@implementation
Execute the plan in .agent/plans/<feature-name>.md
```

## What the builder does

1. Reads the plan or contract completely
2. Reads project skills and conventions
3. Analyzes 3+ existing files for pattern adherence
4. Generates production code following the implementation checklist
5. Verifies compilation and alignment

See [agents/builder.md](../../agents/builder.md) for full documentation.
