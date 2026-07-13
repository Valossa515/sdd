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
| REST & API design | [skills/shared/api-design/SKILL.md](skills/shared/api-design/SKILL.md) | Controllers, DTOs |
| Database | [skills/shared/database/SKILL.md](skills/shared/database/SKILL.md) | Entities, DbContext |
| Security | [skills/shared/security/SKILL.md](skills/shared/security/SKILL.md) | Auth, CORS, input validation |
| Observability | [skills/shared/observability/SKILL.md](skills/shared/observability/SKILL.md) | Logging, tracing, health checks |
| Error handling | [skills/shared/error-handling/SKILL.md](skills/shared/error-handling/SKILL.md) | Exception mapping, RFC 7807 |
| Bootstrap | [skills/shared/bootstrap/SKILL.md](skills/shared/bootstrap/SKILL.md) | Project context setup and maintenance |
| Refactor | [skills/shared/refactor/SKILL.md](skills/shared/refactor/SKILL.md) | Convention-aligned refactoring |

### Commands

Workflow commands are handled directly by the agent roles:

| Command | Agent | What it does |
|---------|-------|--------------|
| `@planning` | [agents/planner.md](agents/planner.md) | Plan a feature — produces plan.md + .spec.toon + .acceptance.toon |
| `@implementation` | [agents/builder.md](agents/builder.md) | Execute a plan — implements tasks following conventions |
| `@test-plan` | [agents/tester.md](agents/tester.md) | Design the testing strategy + test plan document |
| `@test` | [agents/tester.md](agents/tester.md) | Implement the tests from the test plan |
| `@review` | [agents/reviewer.md](agents/reviewer.md) | Structured code review with 🔴🟡🔵 severity classification |

### Agent Guardrails

| Skill | File | Scope |
|-------|------|-------|
| Anti-invention | [skills/shared/anti-invention/SKILL.md](skills/shared/anti-invention/SKILL.md) | All tasks — prevents hallucination |
| Pattern analysis | [skills/shared/pattern-analysis/SKILL.md](skills/shared/pattern-analysis/SKILL.md) | All generation — 3-example rule |
| Gap analysis | [skills/shared/gap-analysis/SKILL.md](skills/shared/gap-analysis/SKILL.md) | Planning — detects missing info |
| Spec validation | [skills/shared/spec-validation/SKILL.md](skills/shared/spec-validation/SKILL.md) | Specs — validates structure |
| Definition of Ready | [skills/shared/dor/SKILL.md](skills/shared/dor/SKILL.md) | Pre-implementation gate |
| Definition of Done | [skills/shared/dod/SKILL.md](skills/shared/dod/SKILL.md) | Post-implementation gate |

### Agent Roles

For pipeline-driven development, see [agents/README.md](agents/README.md):

| Role | File | When to use |
|------|------|-------------|
| Planner | [agents/planner.md](agents/planner.md) | Convert requirement → spec |
| Architect | [agents/architect.md](agents/architect.md) | Convert spec → contract |
| Builder | [agents/builder.md](agents/builder.md) | Generate production code |
| Tester | [agents/tester.md](agents/tester.md) | Generate tests |
| Reviewer | [agents/reviewer.md](agents/reviewer.md) | Validate + review |
| Conductor | [agents/conductor.md](agents/conductor.md) | Run full pipeline |

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
