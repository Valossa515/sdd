---
name: review
description: >
  Redirects to the reviewer agent. The @review command triggers the reviewer,
  which performs a structured code review against project skills and conventions,
  producing severity-classified findings and a verdict.
stack: shared
versions: "SDD 1.x"
---

# Review — Integrated into Reviewer Agent

The `@review` command is now handled by the **reviewer agent** (`agents/reviewer.md`), which performs structured reviews with severity-classified findings:

| Severity | Meaning |
|----------|---------|
| 🔴 Critical | Security vulnerabilities, data loss risk, broken functionality |
| 🟡 Warning | Convention violations, missing error handling, missing tests |
| 🔵 Suggestion | Style improvements, refactoring opportunities, better naming |

## Quick command

```text
@review
Review the changes in the current branch against main.
```

```text
@review
Review the file src/main/java/com/example/OrderService.java
```

## What the reviewer does

1. Reads all project skills and conventions
2. Identifies scope (files, diff, or PR)
3. Reviews against every skill (architecture, API, database, security, etc.)
4. Runs the Definition of Done checklist
5. Classifies findings by severity (🔴 🟡 🔵)
6. Delivers verdict: ✅ Approved or 🔄 Changes Requested

See [agents/reviewer.md](../../agents/reviewer.md) for full documentation.
