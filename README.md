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
*Spring Boot · .NET · REST APIs · Database · Testing · Bootstrap*

</div>

## What is SDD?

SDD (Skill-Driven Development) gives AI agents persistent context via `.agent/` files and stack skills.

## Repository structure

```text
skills/
├── spring-boot/
│   ├── SKILL.md
│   └── testing.md
├── dotnet/
│   ├── SKILL.md
│   └── testing.md
└── shared/
    ├── api-design.md
    ├── database.md
    └── bootstrap.md

scripts/
├── install.sh
├── validate.sh
├── generate.sh
└── new-skill.sh

templates/
├── spring-boot/SKILLS.md
├── dotnet/SKILLS.md
└── common/
    ├── context.md
    ├── architecture.md
    ├── decisions.md
    ├── conventions.md
    ├── runbook.md
    ├── glossary.md
    └── backlog_rules.md
```

## New: Bootstrap skill (`@bootstrap`)

The shared `bootstrap` skill helps create/update project context docs in `.agent/`:

- `context.md`
- `architecture.md`
- `decisions.md` (or `adr/`)
- `conventions.md`
- `runbook.md`
- `glossary.md`
- `backlog_rules.md`

Use in prompt:

```text
@bootstrap
```

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) spring-boot
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) dotnet
```

Or:

```bash
make install STACK=spring-boot TARGET=$(pwd)
```

## Commands

```bash
make validate      # validates frontmatter + required context templates
make generate      # generates .toml files into outputs/
make install       # installs .agent/ for chosen stack
make check         # validate + generate
```

## Frontmatter required in all skills

Every skill markdown must include:

- `name`
- `description`
- `stack`
- `versions`

## Project overrides

In installed `.agent/SKILLS.md`, keep only active skills and use **Overrides específicos do projeto** for local rules. Include links to `context.md`, `architecture.md`, and `runbook.md`.

## ADR and glossary

Document architecture decisions in `decisions.md` (or `.agent/adr/adr-xxxx.md`) and keep domain terms in `glossary.md`.

## License

MIT.
