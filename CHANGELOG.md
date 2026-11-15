# Changelog

All notable changes to SDD are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `version` field in `.claude-plugin/plugin.json` must always match the
latest release in this file (CI enforces it) — Claude Code plugin users only
receive updates when that field is bumped.

## [1.2.0] - 2026-11-15

### Changed

- **Spring Boot 4** — `spring-boot` and `spring-boot-kotlin` target Spring
  Boot 4.x (Spring Framework 7, Jakarta EE 11, Hibernate 7, Spring Security 7,
  Jackson 3; Kotlin 2.2+). The skills cover the modular starters
  (`spring-boot-starter-webmvc`, `spring-boot-starter-flyway`, per-technology
  test starters), JSpecify null safety, and the test changes: `@MockitoBean`
  replaces the removed `@MockBean`, `RestTestClient` with
  `@AutoConfigureRestTestClient`, Testcontainers 2 artifacts and packages,
  springmockk 5. `spring-boot/testing.md` has a Boot 3 → 4 test migration table
- **.NET 10** — `dotnet` targets .NET 10 (LTS), C# 14, ASP.NET Core 10 and
  EF Core 10: built-in OpenAPI 3.1, Minimal API validation, EF Core named
  query filters, xUnit v3. A licensing table flags MediatR 13+, AutoMapper
  15+ and FluentAssertions 8+ as commercial; the testing skill pins
  FluentAssertions to 7.x

### Fixed

- **Remote install with `install.sh`** (the `bash <(curl ...)` one-liner, with
  or without `--ref`) failed with `cp: cannot stat .../skills/shared/.`: the
  temporary clone was deleted before the install started, because its cleanup
  trap was registered inside a `$(...)` subshell. CI now tests the clone path
  of both installers

## [1.1.0] - 2026-11-14

### Added

- **Four new stacks** — `spring-boot-kotlin` (Spring Boot 3 in Kotlin),
  `ktor` (Ktor 3 + Exposed + Koin), `fastapi` (FastAPI + Pydantic v2 + async
  SQLAlchemy 2.0 + Alembic) and `django` (Django 5 + DRF), each with an
  architecture skill, a testing skill and a `SKILLS.md` template. SDD now
  ships 25 skill files across six stacks
- **Native Windows installer** — `scripts/install.ps1` runs on Windows
  PowerShell 5.1 and PowerShell 7+ with only `git` (no bash, `make` or Git
  Bash), one line via `irm` or `-File` from a clone, and produces the same
  files as `install.sh` (CI compares the two byte by byte for every stack)
- **Bootstrap from a project description** — `@bootstrap` now takes a
  description of what the project does (purpose, users, flows, business
  rules, constraints) as a source alongside the code, records divergences
  between the two, and can bootstrap a project that has no code yet
- **Logo** — the README banner is an SVG logo with light and dark variants

### Changed

- **Re-installing keeps project-owned files** — both installers create
  `.agent/SKILLS.md` and the bootstrap context docs only on first install;
  re-running them refreshes skills, agents, prompts and schemas but keeps
  your Project Overrides and bootstrap output (only the `sdd-version` line
  is updated). Previously a re-install overwrote them
- **Reviewer scope rules** — a finding that needs files or tests outside the
  contract is fixed by amending the contract through the architect first;
  a feature's own SDD artifacts (plan, specs, contracts, test plan) are
  always in scope of its batches; the reviewer never blocks the same item in
  both directions
- **DoD item 9** accepts the project's established repository/API test
  approach recorded in Project Overrides (e.g. rendered-query tests)
- **Bootstrap** reconciles the Active Skills table with the real stack,
  records how repositories and APIs are tested, uses the exact
  `## Project Overrides` heading, and recognises `build.gradle.kts`,
  `pyproject.toml` and `manage.py`
- **Shared skills** state that their rules apply to every stack and point to
  the stack skill for the implementation
- **CI** installs and checks every stack under `skills/` instead of a fixed list

### Fixed

- `agents/README.md` was loaded as a seventh agent by the Claude Code plugin;
  the pipeline guide moved to `docs/agents.md` and is still installed as
  `.agent/agents/README.md`
- ANSI colors printed as raw `\033[...` codes in `make` output and in the
  install summary, whose right border was also misaligned
- Shell scripts and the Makefile are forced to LF line endings, so Windows
  checkouts with `core.autocrlf=true` no longer break them
- README: Windows instructions, single-stack install examples, and
  `make bootstrap` (installs templates) separated from `@bootstrap` (fills them)

## [1.0.0] - 2026-07-13

First versioned release. Everything below describes the state of SDD at v1.0.0.

### Added

- **Skills** — 17 skill files: Spring Boot and .NET stack skills
  (architecture + testing) and 13 shared skills (api-design, database,
  security, observability, error-handling, bootstrap, refactor,
  anti-invention, pattern-analysis, gap-analysis, spec-validation, DoR, DoD)
- **Agent pipeline** — six roles (planner, architect, builder, tester,
  reviewer, conductor) with confirmation gates between stages
- **TOON spec schemas** — feature (`.spec.toon`), acceptance
  (`.acceptance.toon`) and contract (`.contract.toon`), with reference
  examples in `specs/examples/`
- **Spec validator** — `scripts/validate-spec.sh` enforces the schema rules
  (required fields, FT/BR/AC id formats and uniqueness, declared row counts,
  enums, cross-file feature-ref resolution), with regression tests in
  `tests/`
- **Claude Code plugin** — the repo doubles as plugin and marketplace:
  `/plugin marketplace add valossa515/sdd` + `/plugin install sdd@sdd`;
  15 auto-discovered skills, 6 subagents, 8 slash commands (`/sdd:plan`,
  `/sdd:architect`, `/sdd:implement`, `/sdd:test`, `/sdd:review`,
  `/sdd:refactor`, `/sdd:pipeline`, `/sdd:bootstrap`)
- **Installers** — `install.sh` (curl or Makefile) targeting `.agent/`
  (agent format) or `.kiro/steering/` (kiro format), with dynamic stack
  detection and Copilot custom-agent generation; `--ref` flag to pin a
  released version
- **End-to-end example** — `examples/create-order/`: one feature through
  the full pipeline with every artifact in its role's format
- **CI** — skill/spec/agent validation, ShellCheck, installer dry-runs,
  validator regression tests, release automation on version tags
