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
*Spring Boot · .NET · REST APIs · Database · Testing · Bootstrap · Agent Pipeline · Specs*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-12-blue)](#skills)
[![Agents](https://img.shields.io/badge/agents-6-orange)](#agent-pipeline)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](#spring-boot)
[![.NET](https://img.shields.io/badge/.NET-8%2F9-512BD4?logo=dotnet&logoColor=white)](#net)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

## What is SDD?

SDD (Skill-Driven Development) gives AI agents persistent context via `.agent/` files and stack skills.

## Repository structure

SDD goes beyond static context: it includes **agent roles** (planner, architect, builder, tester, reviewer, conductor) that form a structured development pipeline, **specification schemas** for traceable requirements, and **quality gates** (DoR/DoD) that prevent incomplete work from moving forward.

> Compatible with Claude, GitHub Copilot, Cursor, Kiro, and any agent that reads markdown context files.

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
    ├── security.md
    ├── observability.md
    ├── error-handling.md
    ├── bootstrap.md
    ├── planning.md          # @planning → @implementation flow
    ├── implementation.md    # @planning → @implementation flow
    ├── test-plan.md         # @test-plan → @test flow
    ├── test.md              # @test-plan → @test flow
    ├── review.md            # independent
    ├── refactor.md          # independent
    ├── anti-invention.md    # guardrails against hallucination
    ├── pattern-analysis.md  # 3-example rule before generating
    ├── gap-analysis.md      # requirement gap detection
    ├── spec-validation.md   # spec completeness checks
    ├── dor.md               # Definition of Ready gate
    └── dod.md               # Definition of Done gate

agents/
├── planner.md               # requirement → spec
├── architect.md             # spec → contract
├── builder.md               # contract → production code
├── tester.md                # contract → tests
├── reviewer.md              # code review + DoD
└── conductor.md             # pipeline orchestration

prompts/
├── endpoint.md              # generate REST endpoint
├── entity.md                # generate domain entity
├── service.md               # generate application service
├── repository-impl.md       # generate repository implementation
└── test-suite.md            # generate test suite

specs/
├── feature.schema.md        # .spec.yml schema
├── acceptance.schema.md     # .acceptance.yml schema
└── contract.schema.md       # .contract.yml schema

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

### Option 1: one-line install (curl)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) spring-boot
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) dotnet
```

### Option 2: install via `git clone` (recommended for teams)

```bash
git clone https://github.com/valossa515/sdd.git /tmp/sdd && \
  make -C /tmp/sdd install STACK=spring-boot TARGET=$(pwd)

# .NET
make -C /tmp/sdd install STACK=dotnet TARGET=$(pwd)
```

### Option 3: run from local clone

```bash
make install STACK=spring-boot TARGET=$(pwd)
# full flow: validate + generate + install
make bootstrap STACK=spring-boot TARGET=$(pwd)
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
├── .github/
│   └── agents/                    ← Copilot custom agents (auto-generated)
│       ├── conductor.agent.md
│       ├── planner.agent.md
│       ├── architect.agent.md
│       ├── builder.agent.md
│       ├── tester.agent.md
│       └── reviewer.agent.md
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

### Using agents in GitHub Copilot (VS Code)

When you install SDD, the script automatically creates `.github/agents/*.agent.md` files in your project. These are **custom agents** recognized natively by GitHub Copilot in VS Code.

After installation:

1. Open the Copilot Chat panel
2. Click the **agent dropdown** (where it says "Agent", "Ask", or "Plan")
3. You will see the SDD agents listed: **conductor**, **planner**, **architect**, **builder**, **tester**, **reviewer**
4. Select an agent and start chatting — it will follow its role instructions automatically

> **Tip:** If agents don't appear, reload the VS Code window (`Cmd+Shift+P` → `Developer: Reload Window`).

Each agent file includes the full role instructions plus a directive to read `.agent/SKILLS.md` before every task, so your project conventions are always respected.

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

## Commands

```bash
make validate      # validates frontmatter + required context templates
make generate      # generates .toml files into outputs/
make install       # installs .agent/ for chosen stack
make bootstrap     # validate + generate + install in one flow
make update        # pull latest skills and regenerate
make upgrade       # update + install (update SDD in an existing project)
make check         # validate + generate
```

## Updating SDD

When a new version of SDD is released, you can update your project's `.agent/` folder in two ways:

### Option 1: upgrade from cloned repo (recommended)

If you cloned the SDD repo during initial install:

```bash
cd /path/to/sdd
git pull                # fetch latest version
make upgrade STACK=spring-boot TARGET=/path/to/your/project
```

`make upgrade` runs `update` (pull + regenerate) then `install` — replacing all skill, agent, prompt, and spec files in your project's `.agent/` folder while preserving your `SKILLS.md` overrides.

### Option 2: one-line reinstall (curl)

Re-run the install command to overwrite with the latest version:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) spring-boot /path/to/your/project
```

### Option 3: manual update

```bash
cd /path/to/sdd
git pull
make install STACK=spring-boot TARGET=/path/to/your/project
```

### What gets updated

| Artifact | Updated? | Notes |
|----------|----------|-------|
| `skills/shared/*` | ✅ Yes | Guardrails, DoR, DoD, etc. |
| `skills/<stack>/*` | ✅ Yes | Stack-specific skills |
| `agents/*` | ✅ Yes | Agent role definitions |
| `prompts/*` | ✅ Yes | Action prompt templates |
| `specs/*` | ✅ Yes | Specification schemas |
| `SKILLS.md` | ✅ Yes | Regenerated from template |
| `.github/agents/*` | ✅ Yes | Copilot custom agents (auto-generated) |
| Your project overrides in `SKILLS.md` | ⚠️ Overwritten | Back up before updating |

> **Tip:** Before upgrading, commit your current `.agent/` folder so you can diff the changes and restore any custom overrides.

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

## Invocable skills

SDD includes 6 invocable workflow skills organized in two flows plus two independent skills:

### Feature flow: `@planning` → `@implementation`

| Command | Skill | Purpose |
|---------|-------|---------|
| `@planning` | [planning.md](skills/shared/planning.md) | Design a feature before coding — produces a plan document |
| `@implementation` | [implementation.md](skills/shared/implementation.md) | Execute a plan — implements tasks in order following conventions |

```text
@planning
Plan the feature: user registration with email verification

# After plan review:
@implementation
Execute the plan in .agent/plans/user-registration.md
```

### Test flow: `@test-plan` → `@test`

| Command | Skill | Purpose |
|---------|-------|---------|
| `@test-plan` | [test-plan.md](skills/shared/test-plan.md) | Design a testing strategy — produces a test plan document |
| `@test` | [test.md](skills/shared/test.md) | Write all tests from the plan — unit, integration, edge cases |

```text
@test-plan
Plan tests for the Order module

# After test plan review:
@test
Execute the test plan in .agent/plans/order-tests.md
```

### Independent skills: `@review` and `@refactor`

| Command | Skill | Purpose |
|---------|-------|---------|
| `@review` | [review.md](skills/shared/review.md) | Structured code review against project skills and conventions |
| `@refactor` | [refactor.md](skills/shared/refactor.md) | Restructure code to align with conventions without changing behavior |

```text
@review
Review the changes in the current branch against main.

@refactor
Refactor the Order module to follow skills/spring-boot/SKILL.md layer separation.
```

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

## License

MIT.
