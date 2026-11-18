# Changelog

All notable changes to SDD are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `version` field in `.claude-plugin/plugin.json` must always match the
latest release in this file (CI enforces it) — Claude Code plugin users only
receive updates when that field is bumped.

## [1.7.1] - 2026-11-18

### Fixed

- **Android testing** — the `@Config(sdk)` rule said "one level on each side
  of every cutover", which contradicted its own example. It now asks for
  `minSdk`, the first level of each newer branch and `targetSdk`
- **Android skill** — names `installingPackageName` as the field that
  replaces `getInstallerPackageName` from API 30

## [1.7.0] - 2026-11-18

### Added

- **Android: reading installed packages** — two-step fetch (light list, then
  one `getPackageInfo` per kept app), system apps as `FLAG_SYSTEM` or
  `FLAG_UPDATED_SYSTEM_APP`, the caller's own package excluded, disabled
  services included, vanished packages skipped, and version branches in one
  internal file where `@Suppress("DEPRECATION")` is allowed only on the old
  branch
- **Android: library modules declare no permissions** — restricted
  permissions such as `QUERY_ALL_PACKAGES` go in the app manifest, with a
  test on the library's merged manifest; `api` versus `implementation` for
  types in a library's public API; injected dispatchers with `ensureActive()`
  in loops
- **Android testing** — `@Config(sdk)` lists that include `minSdk` and each
  cutover, the known gaps of the `PackageManager` shadow, and a counting
  dispatcher that wraps the `runTest` dispatcher to prove code runs on the
  injected one (a second `TestCoroutineScheduler` is rejected by `runTest`)

### Changed

- The Robolectric adapter example passes a dispatcher to the adapter and
  tests at `minSdk`

All found while building the installed-apps inventory of an Android app with
the `android` stack.

## [1.6.0] - 2026-11-17

### Added

- **Android persistence guidance** — Room schema files with the Room Gradle
  plugin and a CI step that fails when the build changed the schema folder
  (`git status`, so new `N.json` files are caught), with a schema-freeze rule
  from the first public release; one `DataStore` per file as a singleton,
  reads that handle `IOException`; backup off with `dataExtractionRules` and
  `fullBackupContent`, because `allowBackup="false"` alone leaves
  device-to-device transfer on for some devices from `targetSdk` 31
- **Android testing** — constraint and cascade tests, migration tests on the
  JVM with the schemas in the unit-test assets and the file-and-driver
  `MigrationTestHelper` constructor, Hilt graph tests in the module that
  owns the types, `DataStore` tests on a real file, and the Windows-only
  `DataStore` rename failure with how to skip it and confirm in CI that the
  tests ran

### Changed

- The `android` template lists the schema-freeze rule and backup off under
  Persistence

All found while building the persistence layer of an Android app with the
`android` stack.

## [1.5.0] - 2026-11-17

### Changed

- **Android testing skill runs Compose tests on the JVM without
  `ui-test-manifest`** — `createEmptyComposeRule()` with a `ComponentActivity`
  started by Robolectric. The previous advice (`ui-test-manifest` in
  `debugImplementation`) merged an exported test Activity into the debug APK.
  New sections cover navigation tests through the real Activity, color and
  contrast checks as pure functions, and a merged-manifest test that checks an
  allowlist of permissions and exported Activities instead of forbidding only
  `INTERNET`
- **Android skill** — ktlint and detekt configuration that exempts only
  `@Composable` functions from function naming; `compileSdk` above
  `targetSdk` when AndroidX requires it; theme mode for components through a
  `CompositionLocal`; `enableEdgeToEdge()`; light and dark window themes; and
  checking the merged manifest when a dependency is added

### Fixed

- **README "What gets updated" table** said `SKILLS.md` overrides are
  overwritten on reinstall. Both installers keep `SKILLS.md` and the context
  docs and change only their `sdd-version` line, as CI already tests

All found while building the first screens of an Android app with the
`android` stack.

## [1.4.0] - 2026-11-16

### Added

- **Feature specs for non-HTTP features** — `.spec.toon` files accept an
  optional `feature.interface` (`http`, `command`, `ui`, `library` or
  `background`; default `http`). It decides what `status` means in
  `outputs.errors`: a 3-digit HTTP status, an integer exit code, or an outcome
  identifier such as a result type or UI state. Existing specs are unchanged.
  The validator checks the value and the matching `status` format, the schema
  documents it with an example, and `specs/examples` gains a `ui` spec

### Changed

- **Android skill targets AGP 9** — built-in Kotlin (no `kotlin-android`
  plugin, no kapt), KSP 2.3.6+ and Hilt 2.59.2+, one JDK for toolchain, Gradle
  daemon and CI, and a rule to stop instead of working around a build plugin
  that does not support the project's versions. A new section explains how to
  write specs for screens, use cases, workers and build tasks

### Fixed

- **`validate-spec.sh` rejected every non-HTTP spec** with "invalid HTTP
  status", because `status` had to be three digits. Found while using the
  `android` stack on a real project

## [1.3.0] - 2026-11-16

### Added

- **Android stack** — `android` (Kotlin 2.x, Jetpack Compose, Material 3, Hilt,
  Room, DataStore, WorkManager, multi-module Gradle) with an architecture
  skill, a testing skill and a `SKILLS.md` template. The architecture skill
  keeps business rules in a pure Kotlin `core-domain` module and platform APIs
  behind adapters; the testing skill separates JUnit 5 (JVM modules) from
  JUnit 4 (Robolectric and instrumented tests). The shared `api-design` and
  `error-handling` skills still describe HTTP services only

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
