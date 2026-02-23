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

## Project Overrides

> ✏️ **Edit this section** with your project's specific conventions.
> Rules here take precedence over the base skills above.

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
