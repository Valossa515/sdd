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

**Specialized skill files for AI coding agents**  
*Spring Boot · .NET · REST APIs · Database · Testing*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-6-blue)](#skills)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](#spring-boot)
[![.NET](https://img.shields.io/badge/.NET-8%2F9-512BD4?logo=dotnet&logoColor=white)](#net)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## What is SDD?

**Skill-Driven Development** is the practice of providing AI coding agents with persistent, structured context about your project's conventions — so they generate code that fits your codebase from the first attempt.

Instead of repeating yourself in every prompt, you drop a `.agent/` folder in your project root. The agent reads it before every task and follows your rules.

> Inspired by [Amazon Kiro's steering system](https://kiro.dev/docs/steering/). Compatible with Claude, GitHub Copilot, Cursor, Kiro, and any agent that reads markdown context files.

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
│   ├── SKILLS.md          ← entry point: tells the agent which skills apply
│   └── skills/
│       ├── spring-boot/
│       │   ├── SKILL.md   ← architecture, patterns, naming, DI rules
│       │   ├── SKILL.toml ← same skill, TOML format (Kiro-compatible)
│       │   └── testing.md
│       └── shared/
│           ├── api-design.md
│           └── database.md
├── src/
└── ...
```

**At task time**, the agent loads `.agent/SKILLS.md`, follows the links to the active skills, and generates code that respects:

- ✅ Your architecture (layered, Clean Arch, hexagonal)
- ✅ Your naming conventions
- ✅ Your testing patterns (JUnit 5, xUnit, Testcontainers)
- ✅ Your API design rules (REST, pagination, error format)
- ✅ Your database conventions (migrations, N+1 prevention, soft delete)

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
