---
# .agent/SKILLS.md
# ─────────────────────────────────────────────────────────
# SDD — Skill-Driven Development entry point
# This file is read by the AI agent BEFORE every task.
# Commit this folder alongside your source code.
# ─────────────────────────────────────────────────────────
name: my-android-app
stack: android
sdd-version: "1.0"
---

# Project Agent Skills

This is an **Android / Kotlin 2.x** app (AGP 9 with built-in Kotlin, Jetpack Compose, Material 3, Hilt, Room, DataStore, WorkManager, multi-module Gradle). Before writing any code,
read and follow all the skills listed below.

## Active Skills

### Stack Skills

| Skill | File | Scope |
|-------|------|-------|
| Architecture & patterns | [skills/android/SKILL.md](skills/android/SKILL.md) | All code |
| Testing | [skills/android/testing.md](skills/android/testing.md) | Test files |
| Database | [skills/shared/database/SKILL.md](skills/shared/database/SKILL.md) | Room entities, DAOs, migrations |
| Security | [skills/shared/security/SKILL.md](skills/shared/security/SKILL.md) | Permissions, data at rest, input validation |
| Observability | [skills/shared/observability/SKILL.md](skills/shared/observability/SKILL.md) | Logging without personal data |
| Bootstrap | [skills/shared/bootstrap/SKILL.md](skills/shared/bootstrap/SKILL.md) | Project context setup and maintenance |
| Refactor | [skills/shared/refactor/SKILL.md](skills/shared/refactor/SKILL.md) | Convention-aligned refactoring |

> The shared `api-design` and `error-handling` skills describe HTTP services. They apply only if this
> app also ships or talks to a backend the team owns; otherwise follow the error handling section of
> the Android skill.

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

### Modules
```
app/                 ← screens, navigation, workers, DI wiring
core-domain/         ← pure Kotlin: models, ports, business rules
core-data/           ← Room, DataStore, repository implementations
core-YOURCAPABILITY/ ← platform adapters behind domain ports
```

### SDK levels
- **minSdk**: 26
- **targetSdk / compileSdk**: the level Google Play currently requires
- **Application id**: `com.YOURCOMPANY.YOURAPP`

### Build
- **AGP**: 9.x with built-in Kotlin (no `kotlin-android` plugin)
- **JDK**: one version for toolchain, Gradle daemon and CI

### Spec format
- Feature specs set `feature.interface` (`ui`, `library`, `background` or `command`); `status` is a UI state, a result type or an exit code, never an HTTP status

### Persistence
- **Database**: Room, schemas exported to `core-data/schemas`
- **Settings**: Preferences DataStore
- **Migrations**: one `Migration` + one migration test per version bump
- **Schema freeze**: before the first public release version 1 may change (JSON committed); after it, a published `N.json` never changes
- **Backup**: off — `allowBackup="false"`, `dataExtractionRules` and `fullBackupContent` excluding every domain

### Permissions
<!-- List every permission the app declares and why. Anything not listed here must not be added. -->
- `android.permission.POST_NOTIFICATIONS` — alerts

### How data and platform layers are tested
- `core-domain`: JUnit 5 on the JVM
- Adapters and Room: Robolectric with an in-memory database (no device needed)
- Screens: Compose UI tests on the stateless content composables

### Custom rules
<!-- Add your project-specific rules below. Examples:
- The app never declares android.permission.INTERNET
- Sensitive values are masked in the adapter and never persisted
- Every user-visible string lives in strings.xml
-->

## How to use

Point your agent at this file before each task:
> "Read `.agent/SKILLS.md` and follow all linked skills before writing any code."

Or configure your IDE plugin to auto-load context from `.agent/`.
