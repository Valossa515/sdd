---
name: test
description: >
  Redirects to the tester agent. The @test command triggers the tester,
  which reads or generates the test plan and writes all test classes
  following stack conventions.
stack: shared
versions: "SDD 1.x"
---

# Test — Integrated into Tester Agent

The `@test` command is now handled by the **tester agent** (`agents/tester.md`), which produces both the test plan and test code in a single pass:

| Artifact | Format | Location |
|----------|--------|----------|
| Test plan | `.md` | `.agent/plans/<feature-name>-tests.md` |
| Test source files | Stack-specific | Project test directories |

## Quick command

```text
@test
Write tests for <class/feature>, following the testing skill.
```

Or with a prior test plan:

```text
@test
Execute the test plan in .agent/plans/<feature-name>-tests.md
```

## What the tester does

1. Designs the testing strategy (unit, integration, edge cases)
2. Produces a structured test plan document
3. Analyzes existing test patterns in the project
4. Writes all test classes following AAA pattern and stack conventions
5. Runs the test suite to verify green

See [agents/tester.md](../../agents/tester.md) for full documentation.
