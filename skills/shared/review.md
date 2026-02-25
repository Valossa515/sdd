---
name: review
description: Use this skill when the user asks for @review or wants a code review of changes, a PR, or a specific module. It performs a structured review against project skills and conventions.
stack: shared
versions: "SDD 1.x"
---

# Review — Structured Code Review

Use this skill when the user asks for `@review` or wants a code review.
This is an **independent skill** — it can be used at any time.

## Trigger phrases

- `@review`
- "review this code"
- "review this PR"
- "check my changes"
- "code review"

## Goal

Perform a systematic code review against the project's skills and conventions, producing actionable feedback organized by severity.

## Workflow

1. **Read project context** — load `.agent/SKILLS.md` and all linked skills.
2. **Identify the scope** — determine what to review:
   - A specific file or set of files.
   - A git diff (`git diff`, `git diff --staged`, or `git diff main..HEAD`).
   - A pull request (via `gh pr diff`).
3. **Review against each skill** — check the code against:
   - **Architecture** (`SKILL.md`): layer separation, naming, dependency direction.
   - **API design** (`api-design.md`): endpoints, status codes, pagination, RFC 7807.
   - **Database** (`database.md`): migrations, naming, N+1, indexes.
   - **Security** (`security.md`): input validation, auth, secrets, OWASP.
   - **Error handling** (`error-handling.md`): exception hierarchy, status mapping.
   - **Observability** (`observability.md`): logging, tracing, health checks.
   - **Testing** (`testing.md`): coverage, naming, patterns.
4. **Classify findings** — organize by severity:
   - 🔴 **Critical**: security vulnerabilities, data loss risk, broken functionality.
   - 🟡 **Warning**: convention violations, missing error handling, missing tests.
   - 🔵 **Suggestion**: style improvements, refactoring opportunities, better naming.
5. **Produce the review report**.

## Review report template

```markdown
# Code Review: <scope description>

## Summary
Brief assessment: LGTM / Needs changes / Needs major rework.

## Findings

### 🔴 Critical
1. **[security.md]** SQL injection risk in `OrderRepository.findByName()`
   - File: `src/.../OrderRepository.java:42`
   - Fix: Use parameterized query instead of string concatenation

### 🟡 Warning
1. **[api-design.md]** POST /orders returns 200 instead of 201
   - File: `src/.../OrderController.java:28`
   - Fix: Return `ResponseEntity.created(uri).body(response)`

2. **[database.md]** Missing index on `orders.customer_id`
   - File: `V3__create_orders.sql`
   - Fix: Add `CREATE INDEX idx_orders_customer_id ON orders(customer_id)`

### 🔵 Suggestion
1. **[SKILL.md]** Service method could use `@Transactional(readOnly = true)`
   - File: `src/.../OrderService.java:55`

## Checklist
- [ ] Layer separation correct
- [ ] Naming conventions followed
- [ ] API responses follow RFC 7807
- [ ] Database migrations are reversible
- [ ] Input validation present
- [ ] Error handling complete
- [ ] Tests cover new code
- [ ] No secrets in code
```

## Quick command

```text
@review
Review the changes in the current branch against main.
```

```text
@review
Review the file src/main/java/com/example/OrderService.java
```

## Output quality rules

- Always reference the specific skill being violated (e.g., `[api-design.md]`).
- Include file path and line number for every finding.
- Provide a concrete fix or suggestion, not just "this is wrong."
- Prioritize critical issues — security and correctness before style.
- Acknowledge what is done well — reviews should be balanced.

## What NOT to do

- ❌ Do not review without reading project skills first — every finding must reference a convention.
- ❌ Do not nitpick style if there are critical issues — prioritize severity.
- ❌ Do not just say "looks good" without actually checking against skills.
- ❌ Do not modify code during a review — only report findings.
- ❌ Do not ignore test coverage — missing tests are a valid finding.
