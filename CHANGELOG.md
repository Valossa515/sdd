# Changelog

All notable changes to SDD are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `version` field in `.claude-plugin/plugin.json` must always match the
latest release in this file (CI enforces it) — Claude Code plugin users only
receive updates when that field is bumped.

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
