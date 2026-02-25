---
# .agent/SKILLS.md
# ─────────────────────────────────────────────────────────
# SDD — Skill-Driven Development entry point
# This file is read by the AI agent BEFORE every task.
# Commit this folder alongside your source code.
# ─────────────────────────────────────────────────────────
name: my-spring-boot-project
stack: spring-boot
sdd-version: "1.0"
---

# Project Agent Skills

This is a **Spring Boot 3.x / Java 21** project. Before writing any code,
read and follow all the skills listed below.

## Active Skills

| Skill | File | Scope |
|-------|------|-------|
| Architecture & patterns | [skills/spring-boot/SKILL.md](skills/spring-boot/SKILL.md) | All code |
| Testing | [skills/spring-boot/testing.md](skills/spring-boot/testing.md) | Test files |
| REST & API design | [skills/shared/api-design.md](skills/shared/api-design.md) | Controllers, DTOs |
| Database | [skills/shared/database.md](skills/shared/database.md) | Entities, repositories |
| Security | [skills/shared/security.md](skills/shared/security.md) | Auth, CORS, input validation |
| Observability | [skills/shared/observability.md](skills/shared/observability.md) | Logging, tracing, health checks |
| Error handling | [skills/shared/error-handling.md](skills/shared/error-handling.md) | Exception mapping, RFC 7807 |
| Bootstrap | [skills/shared/bootstrap.md](skills/shared/bootstrap.md) | Project context setup and maintenance |
| Planning | [skills/shared/planning.md](skills/shared/planning.md) | Feature planning (`@planning` → `@implementation`) |
| Implementation | [skills/shared/implementation.md](skills/shared/implementation.md) | Plan execution (`@planning` → `@implementation`) |
| Test Plan | [skills/shared/test-plan.md](skills/shared/test-plan.md) | Test strategy design (`@test-plan` → `@test`) |
| Test | [skills/shared/test.md](skills/shared/test.md) | Test implementation (`@test-plan` → `@test`) |
| Review | [skills/shared/review.md](skills/shared/review.md) | Structured code review |
| Refactor | [skills/shared/refactor.md](skills/shared/refactor.md) | Convention-aligned refactoring |

## Project Overrides

> ✏️ **Edit this section** with your project's specific conventions.
> Rules here take precedence over the base skills above.


### Context documents
- [context.md](context.md)
- [architecture.md](architecture.md)
- [runbook.md](runbook.md)
- [glossary.md](glossary.md)

### Package structure
```
com.YOURCOMPANY.YOURAPP
├── api/
│   ├── controller/
│   └── dto/
├── application/
│   └── service/
├── domain/
│   ├── model/
│   ├── repository/
│   └── exception/
└── infrastructure/
    └── persistence/
```

### Database
- **Engine**: PostgreSQL 16
- **Migrations**: Flyway
- **Migration path**: `src/main/resources/db/migration`

### Authentication
- Spring Security 6 + JWT
- Token header: `Authorization: Bearer <token>`

### Custom rules
<!-- Add your project-specific rules below. Examples:
- All monetary values use BigDecimal, never double or float
- Audit fields (createdBy, updatedBy) required on every entity
- All external API calls must have a timeout of 5s configured
-->

## How to use

Point your agent at this file before each task:
> "Read `.agent/SKILLS.md` and follow all linked skills before writing any code."

Or configure your IDE plugin to auto-load context from `.agent/`.
