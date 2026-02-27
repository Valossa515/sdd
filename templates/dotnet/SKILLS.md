---
# .agent/SKILLS.md
# ─────────────────────────────────────────────────────────
# SDD — Skill-Driven Development entry point
# This file is read by the AI agent BEFORE every task.
# Commit this folder alongside your source code.
# ─────────────────────────────────────────────────────────
name: my-dotnet-project
stack: dotnet
sdd-version: "1.0"
---

# Project Agent Skills

This is a **.NET 8 / ASP.NET Core / C# 12** project using Clean Architecture.
Before writing any code, read and follow all the skills listed below.

## Active Skills

| Skill | File | Scope |
|-------|------|-------|
| Architecture & patterns | [skills/dotnet/SKILL.md](skills/dotnet/SKILL.md) | All code |
| Testing | [skills/dotnet/testing.md](skills/dotnet/testing.md) | Test files |
| REST & API design | [skills/shared/api-design.md](skills/shared/api-design.md) | Controllers, DTOs |
| Database | [skills/shared/database.md](skills/shared/database.md) | Entities, DbContext |
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

### Solution structure
```
src/
├── YOURAPP.Api/
├── YOURAPP.Application/
├── YOURAPP.Domain/
└── YOURAPP.Infrastructure/
tests/
├── YOURAPP.UnitTests/
└── YOURAPP.IntegrationTests/
```

### Database
- **Engine**: PostgreSQL 16 via EF Core 8 + Npgsql
- **Migrations**: EF Core code-first
- **DbContext**: `AppDbContext` in `Infrastructure/Persistence/`

### Authentication
- `Microsoft.AspNetCore.Authentication.JwtBearer`
- Token header: `Authorization: Bearer <token>`

### Custom rules
<!-- Add your project-specific rules below. Examples:
- Use Result<T> pattern (FluentResults) instead of exceptions for expected failures
- All domain events must be dispatched via MediatR IPublisher
- Outbox pattern required for all cross-service events
-->

## How to use

Point your agent at this file before each task:
> "Read `.agent/SKILLS.md` and follow all linked skills before writing any code."

Or configure your IDE plugin to auto-load context from `.agent/`.
