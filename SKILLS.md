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

### Stack Skills

| Skill | File | Scope |
|-------|------|-------|
| Architecture & patterns | [skills/spring-boot/SKILL.md](skills/spring-boot/SKILL.md) | All code |
| Testing | [skills/spring-boot/testing.md](skills/spring-boot/testing.md) | Test files |
| REST & API design | [skills/shared/api-design.md](skills/shared/api-design.md) | Controllers, DTOs |
| Database | [skills/shared/database.md](skills/shared/database.md) | Entities, repositories |

### Agent Guardrails

| Skill | File | Scope |
|-------|------|-------|
| Anti-invention | [skills/shared/anti-invention.md](skills/shared/anti-invention.md) | All tasks — prevents hallucination |
| Pattern analysis | [skills/shared/pattern-analysis.md](skills/shared/pattern-analysis.md) | All generation — 3-example rule |
| Gap analysis | [skills/shared/gap-analysis.md](skills/shared/gap-analysis.md) | Planning — detects missing info |
| Spec validation | [skills/shared/spec-validation.md](skills/shared/spec-validation.md) | Specs — validates structure |
| Definition of Ready | [skills/shared/dor.md](skills/shared/dor.md) | Pre-implementation gate |
| Definition of Done | [skills/shared/dod.md](skills/shared/dod.md) | Post-implementation gate |

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
