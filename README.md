<div align="center">

```
 ███████╗██████╗ ██████╗
 ██╔════╝██╔══██╗██╔══██╗
 ███████╗██║  ██║██║  ██║
 ╚════██║██║  ██║██║  ██║
 ███████║██████╔╝██████╔╝
 ╚══════╝╚═════╝ ╚═════╝
  Skill-Driven Development
```

**Structured skill files, agent roles, and specification schemas for AI coding agents**  
*Spring Boot · .NET · REST APIs · Database · Testing · Agent Pipeline · Specs*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-12-blue)](#skills)
[![Agents](https://img.shields.io/badge/agents-6-orange)](#agent-pipeline)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](#spring-boot)
[![.NET](https://img.shields.io/badge/.NET-8%2F9-512BD4?logo=dotnet&logoColor=white)](#net)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## What is SDD?

**Skill-Driven Development** is the practice of providing AI coding agents with persistent, structured context about your project's conventions — so they generate code that fits your codebase from the first attempt.

Instead of repeating yourself in every prompt, you drop a `.agent/` folder in your project root. The agent reads it before every task and follows your rules.

SDD goes beyond static context: it includes **agent roles** (planner, architect, builder, tester, reviewer, conductor) that form a structured development pipeline, **specification schemas** for traceable requirements, and **quality gates** (DoR/DoD) that prevent incomplete work from moving forward.

> Compatible with Claude, GitHub Copilot, Cursor, Kiro, and any agent that reads markdown context files.

---

## Install in 30 seconds

```bash
# Spring Boot project
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) spring-boot

# .NET project
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) dotnet
```

Or with `git`:

```bash
git clone https://github.com/valossa515/sdd.git /tmp/sdd && \
  make -C /tmp/sdd install STACK=spring-boot TARGET=$(pwd)
```

This creates a `.agent/` folder in your project with all relevant skills, ready to customize.

---

## How it works

```
your-project/
├── .agent/
│   ├── SKILLS.md              ← entry point: active skills and project overrides
│   ├── skills/
│   │   ├── spring-boot/
│   │   │   ├── SKILL.md       ← architecture, patterns, naming, DI rules
│   │   │   ├── SKILL.toml     ← same skill, TOML format (Kiro-compatible)
│   │   │   └── testing.md
│   │   └── shared/
│   │       ├── api-design.md
│   │       ├── database.md
│   │       ├── anti-invention.md  ← guardrails against hallucination
│   │       ├── pattern-analysis.md ← 3-example rule before generating
│   │       ├── gap-analysis.md    ← requirement gap detection
│   │       ├── spec-validation.md ← spec completeness checks
│   │       ├── dor.md             ← Definition of Ready gate
│   │       └── dod.md             ← Definition of Done gate
│   ├── agents/                    ← agent role definitions
│   │   ├── planner.md             ← requirement → spec
│   │   ├── architect.md           ← spec → contract
│   │   ├── builder.md             ← contract → production code
│   │   ├── tester.md              ← contract → tests
│   │   ├── reviewer.md            ← code review + DoD
│   │   └── conductor.md           ← pipeline orchestration
│   ├── prompts/                   ← step-by-step generation guides
│   │   ├── endpoint.md
│   │   ├── entity.md
│   │   ├── service.md
│   │   ├── repository-impl.md
│   │   └── test-suite.md
│   └── specs/                     ← specification schemas
│       ├── features/              ← feature specs (.spec.yml)
│       ├── acceptance/            ← acceptance criteria (.acceptance.yml)
│       └── contracts/             ← architecture contracts (.contract.yml)
├── src/
└── ...
```

**At task time**, the agent loads `.agent/SKILLS.md`, follows the links to the active skills, and generates code that respects:

- ✅ Your architecture (layered, Clean Arch, hexagonal)
- ✅ Your naming conventions
- ✅ Your testing patterns (JUnit 5, xUnit, Testcontainers)
- ✅ Your API design rules (REST, pagination, error format)
- ✅ Your database conventions (migrations, N+1 prevention, soft delete)
- ✅ Anti-invention guardrails (no hallucinated requirements)
- ✅ Quality gates (Definition of Ready / Definition of Done)

---

## Skills

| Skill | Stack | Description |
|-------|-------|-------------|
| [`spring-boot/SKILL`](skills/spring-boot/SKILL.md) | ☕ Spring Boot 3.x | Architecture, controllers, services, entities, DI, exception handling |
| [`spring-boot/testing`](skills/spring-boot/testing.md) | ☕ Spring Boot 3.x | JUnit 5, Mockito, MockMvc, Testcontainers, @WebMvcTest |
| [`dotnet/SKILL`](skills/dotnet/SKILL.md) | 🔷 .NET 8/9 | Clean Architecture, CQRS/MediatR, FluentValidation, EF Core |
| [`dotnet/testing`](skills/dotnet/testing.md) | 🔷 .NET 8/9 | xUnit, NSubstitute, WebApplicationFactory, Testcontainers, Respawn |
| [`shared/api-design`](skills/shared/api-design.md) | Both | REST conventions, pagination, RFC 7807 errors, OpenAPI |
| [`shared/database`](skills/shared/database.md) | Both | Flyway vs EF Migrations, N+1, projections, soft delete, indexing |
| [`shared/anti-invention`](skills/shared/anti-invention.md) | Both | Guardrails against AI hallucination and scope creep |
| [`shared/pattern-analysis`](skills/shared/pattern-analysis.md) | Both | 3-example rule: study codebase before generating |
| [`shared/gap-analysis`](skills/shared/gap-analysis.md) | Both | Detect missing requirement info before writing specs |
| [`shared/spec-validation`](skills/shared/spec-validation.md) | Both | Validate spec completeness and consistency |
| [`shared/dor`](skills/shared/dor.md) | Both | Definition of Ready — 15-item pre-implementation gate |
| [`shared/dod`](skills/shared/dod.md) | Both | Definition of Done — 23-item completion checklist |

---

## Agent Pipeline

SDD includes six agent roles that form a structured development pipeline:

```
Requirement → planner → architect → builder → tester → reviewer
                              ↑ conductor orchestrates all ↑
```

| Role | File | Responsibility |
|------|------|----------------|
| **planner** | [agents/planner.md](agents/planner.md) | Convert requirement into feature spec + acceptance criteria |
| **architect** | [agents/architect.md](agents/architect.md) | Convert spec into architecture contract (layers, files, test strategy) |
| **builder** | [agents/builder.md](agents/builder.md) | Generate production code from the contract — nothing else |
| **tester** | [agents/tester.md](agents/tester.md) | Generate tests from the contract's test strategy — nothing else |
| **reviewer** | [agents/reviewer.md](agents/reviewer.md) | Validate code against spec + contract + DoD |
| **conductor** | [agents/conductor.md](agents/conductor.md) | Orchestrate the full pipeline with confirmation gates |

Use the full pipeline for new features, or shortcut for simpler tasks:

| Task | Pipeline |
|------|----------|
| New feature | planner → architect → builder → tester → reviewer |
| Bugfix (clear spec) | architect → builder → tester → reviewer |
| Simple bugfix | builder → tester → reviewer |
| Refactor | builder → tester → reviewer |

See [agents/README.md](agents/README.md) for full documentation.

---

## Specification Schemas

Specs create a traceability chain from requirement to code:

```
requirement → feature.spec.yml → acceptance.spec.yml → contract.spec.yml → code
```

| Schema | Purpose | Created by |
|--------|---------|------------|
| [feature.schema.md](specs/feature.schema.md) | Business behavior (inputs, outputs, business rules) | planner |
| [acceptance.schema.md](specs/acceptance.schema.md) | Given/When/Then testable criteria | planner |
| [contract.schema.md](specs/contract.schema.md) | Files, layers, dependencies, test strategy | architect |

See [specs/README.md](specs/README.md) for full documentation.

---

## Action Prompts

Step-by-step generation guides for common artifacts:

| Prompt | Description |
|--------|-------------|
| [endpoint.md](prompts/endpoint.md) | Generate REST endpoint (controller + DTOs) |
| [entity.md](prompts/entity.md) | Generate domain entity with invariants |
| [service.md](prompts/service.md) | Generate application service / use case |
| [repository-impl.md](prompts/repository-impl.md) | Generate repository implementation |
| [test-suite.md](prompts/test-suite.md) | Generate test suite from test strategy |

See [prompts/README.md](prompts/README.md) for full documentation.

---

## Makefile

```bash
make help          # show all commands
make validate      # validate all skill files (frontmatter + structure)
make generate      # generate .toml files from all .md skills
make install       # install into a project (STACK=spring-boot|dotnet TARGET=path)
make check         # validate + generate (CI)
```

---

## Output formats

Each skill is available in two formats, both generated from the same source:

| Format | Use with |
|--------|----------|
| `.md` | Claude, Cursor, Copilot, any markdown-aware agent |
| `.toml` | Amazon Kiro (`.kiro/steering/`), structured config pipelines |

Run `make generate` to rebuild all `.toml` files after editing a skill.

---

## Customizing for your project

After installing, open `.agent/SKILLS.md` and add your project-specific overrides:

```markdown
## Project-Specific Overrides

### Package structure
com.mycompany.myapp

### Database
- PostgreSQL 15 via Flyway
- Migrations in: src/main/resources/db/migration

### Auth
- JWT via Spring Security 6, token in Authorization: Bearer header

### Custom rules
- All monetary values use BigDecimal, never double or float
- Audit fields (createdBy, updatedBy) on every entity
```

These override the base skills — the agent always prioritizes project-specific rules.

---

## Kiro compatibility

If you use Amazon Kiro, use the Kiro install command:

```bash
make install STACK=spring-boot TARGET=$(pwd) FORMAT=kiro
```

This puts the skills in `.kiro/steering/` as `.md` files, which Kiro reads automatically.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short:

1. Edit or create a skill under `skills/`
2. Run `make validate` to check structure
3. Run `make generate` to rebuild `.toml` files
4. Open a PR

---

## License

[MIT](LICENSE) — use freely in any project, commercial or not.
