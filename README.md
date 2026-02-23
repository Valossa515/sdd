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

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) spring-boot
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) dotnet
```

Or:

```bash
make install STACK=spring-boot TARGET=$(pwd)
# full flow: validate + generate + install
make bootstrap STACK=spring-boot TARGET=$(pwd)
```

## Commands

```bash
make validate      # validates frontmatter + required context templates
make generate      # generates .toml files into outputs/
make install       # installs .agent/ for chosen stack
make bootstrap     # validate + generate + install in one flow
make check         # validate + generate
```

## How to use skills in your project

After installation, your project will have `.agent/SKILLS.md` plus stack/shared skills.

### 1) Instruct your agent to always load `.agent/SKILLS.md`

Use prompts like:

```text
Read .agent/SKILLS.md and all linked skills before writing code.
```

### 2) Example prompts for Spring Boot projects

```text
Read .agent/SKILLS.md.
Create endpoint POST /api/v1/orders following skills/shared/api-design.md,
use validation and RFC7807 errors, and add tests based on skills/spring-boot/testing.md.
```

```text
Read .agent/SKILLS.md.
Refactor Order module to respect layered architecture from skills/spring-boot/SKILL.md
and database conventions from skills/shared/database.md.
```

### 3) Example prompts for .NET projects

```text
Read .agent/SKILLS.md.
Implement CreateOrderCommand with MediatR + FluentValidation,
expose controller endpoint, and add unit/integration tests using skills/dotnet/testing.md.
```

```text
Read .agent/SKILLS.md.
Add pagination and ProblemDetails responses to Orders endpoints
following skills/shared/api-design.md.
```

### 4) Keep project-specific rules in `.agent/SKILLS.md`

In **Overrides específicos do projeto**, add concrete rules such as:

- package/solution naming
- auth strategy
- migration paths
- non-functional constraints (timeouts, observability, etc.)

## How to use bootstrap (`@bootstrap`)

The shared `bootstrap` skill helps create/update project context docs in `.agent/`:

- `context.md`
- `architecture.md`
- `decisions.md` (or `adr/`)
- `conventions.md`
- `runbook.md`
- `glossary.md`
- `backlog_rules.md`

### Prompt-driven bootstrap

Use in prompt:

```text
@bootstrap
Read .agent/SKILLS.md, map the repository context, and update all .agent context files.
Do not invent facts: add TODOs for unknowns.
```

### CLI bootstrap (recommended)

```bash
make bootstrap STACK=spring-boot TARGET=$(pwd)
# or
make bootstrap STACK=dotnet TARGET=$(pwd)
```

This guarantees validation and generation happen before installation.

### Suggested bootstrap routine per project

1. Run `make bootstrap STACK=<stack> TARGET=$(pwd)`.
2. Open `.agent/context.md` and fill domain/problem details.
3. Register key architectural choices in `.agent/decisions.md` or `.agent/adr/`.
4. Update `.agent/glossary.md` with domain terminology.
5. Commit `.agent/` together with code changes.

## Frontmatter required in all skills

Every skill markdown must include:

- `name`
- `description`
- `stack`
- `versions`

## ADR and glossary

Document architecture decisions in `decisions.md` (or `.agent/adr/adr-xxxx.md`) and keep domain terms in `glossary.md`.


## Troubleshooting: PR merge/diff issues

If a PR was merged with conflicts and your branch did not receive the README updates:

1. Confirm the latest commit contains README changes:
   - `git log --oneline -n 5`
   - `git show --name-only <commit_sha>`
2. Rebase your branch on the target branch (`main` or release branch).
3. If needed, cherry-pick the README commit:
   - `git cherry-pick <commit_sha>`
4. Re-run checks:
   - `make check`
5. Open README and confirm sections:
   - "How to use skills in your project"
   - "How to use bootstrap (`@bootstrap`)"

This helps guarantee onboarding docs are present after merge.
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
