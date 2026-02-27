---
name: planning
description: >
  Redirects to the planner agent. The @planning command triggers the planner,
  which produces the plan document (.md) and TOON specs (.spec.toon + .acceptance.toon)
  together in one step.
stack: shared
versions: "SDD 1.x"
---

# Planning — Integrated into Planner Agent

The `@planning` command is now handled by the **planner agent** (`agents/planner.md`), which produces all planning artifacts in one step:

| Artifact | Format | Location |
|----------|--------|----------|
| Plan document | `.md` | `.agent/plans/` |
| Feature specification | `.spec.toon` | `.agent/specs/features/` |
| Acceptance criteria | `.acceptance.toon` | `.agent/specs/acceptance/` |

## Trigger phrases

- `@planning`
- "plan this feature"
- "design the solution"
- "create a plan for..."
- "break down this task"

## Quick command

```text
@planning
Plan the feature: <describe feature here>
```

This produces the plan `.md`, `.spec.toon`, and `.acceptance.toon` together.

## Handoff to @implementation

After the plan and specs are reviewed and approved, use:

```text
@implementation
Execute the plan in .agent/plans/<feature-name>.md
```

The `@implementation` command is now handled by the **builder agent** (`agents/builder.md`).

## Full reference

See `agents/planner.md` for the complete workflow, gap analysis protocol, decomposition rules, and constraints.

## What NOT to do

- ❌ Do not write code during planning — this is a design-only phase.
- ❌ Do not skip reading existing context files before planning.
- ❌ Do not create plans without acceptance criteria.
- ❌ Do not leave scope ambiguous — list affected layers and files explicitly.
- ❌ Do not plan tasks that are too large to implement atomically.
- ❌ Do not generate the plan without the TOON specs or vice-versa.
