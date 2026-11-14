---
# .agent/SKILLS.md
# ─────────────────────────────────────────────────────────
# SDD — Skill-Driven Development entry point
# This file is read by the AI agent BEFORE every task.
# Commit this folder alongside your source code.
# ─────────────────────────────────────────────────────────
name: my-django-project
stack: django
sdd-version: "1.0"
---

# Project Agent Skills

This is a **Django 5.x / Django REST Framework / Python 3.12+** project. Before writing any code,
read and follow all the skills listed below.

## Active Skills

### Stack Skills

| Skill | File | Scope |
|-------|------|-------|
| Architecture & patterns | [skills/django/SKILL.md](skills/django/SKILL.md) | All code |
| Testing | [skills/django/testing.md](skills/django/testing.md) | Test files |
| REST & API design | [skills/shared/api-design/SKILL.md](skills/shared/api-design/SKILL.md) | Views, serializers |
| Database | [skills/shared/database/SKILL.md](skills/shared/database/SKILL.md) | Models, selectors, migrations |
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

### Project structure
```
config/
├── settings/
│   ├── base.py
│   ├── dev.py
│   └── prod.py
└── urls.py
apps/
└── YOURAPP/
    ├── models.py
    ├── services.py
    ├── selectors.py
    ├── exceptions.py
    ├── api/
    │   ├── serializers.py
    │   ├── views.py
    │   └── urls.py
    ├── migrations/
    └── tests/
```

### Database
- **Engine**: PostgreSQL 16 via the Django ORM
- **Migrations**: Django migrations, checked in CI with `makemigrations --check`
- **Settings**: `DATABASE_URL` read with `django-environ`

### Authentication
- `djangorestframework-simplejwt`, `IsAuthenticated` as the default permission
- Token header: `Authorization: Bearer <token>`

### Custom rules
<!-- Add your project-specific rules below. Examples:
- All monetary values use DecimalField, never FloatField
- Every model with business data has an owner/tenant foreign key, filtered in selectors
- Background work goes through Celery tasks, enqueued with transaction.on_commit
-->

## How to use

Point your agent at this file before each task:
> "Read `.agent/SKILLS.md` and follow all linked skills before writing any code."

Or configure your IDE plugin to auto-load context from `.agent/`.
