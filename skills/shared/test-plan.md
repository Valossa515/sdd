---
name: test-plan
description: >
  Redirects to the tester agent. The @test-plan command triggers the tester,
  which designs the testing strategy and produces a test plan document
  before writing all test code.
stack: shared
versions: "SDD 1.x"
---

# Test Plan — Integrated into Tester Agent

The `@test-plan` command is now handled by the **tester agent** (`agents/tester.md`), which produces both the test plan and test code in a single pass:

| Artifact | Format | Location |
|----------|--------|----------|
| Test plan | `.md` | `.agent/plans/<feature-name>-tests.md` |
| Test source files | Stack-specific | Project test directories |

## Quick command

```text
@test-plan
Plan tests for the feature: <describe feature or point to plan>
```

## What the tester does

1. Reads the test strategy from the contract (or analyzes production code)
2. Identifies test categories (unit, integration, edge cases)
3. Produces a structured test plan document
4. Writes all test classes following stack conventions
5. Runs the test suite to verify green

See [agents/tester.md](../../agents/tester.md) for full documentation.
