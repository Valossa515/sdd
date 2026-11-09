---
description: Create or update the project's .agent/ context docs (SDD bootstrap skill)
argument-hint: [optional: what the project does, or a focus such as "only glossary"]
---

Read the `sdd:bootstrap` skill (`${CLAUDE_PLUGIN_ROOT}/skills/shared/bootstrap/SKILL.md`) and follow it for this task.

Map the repository and create/update the `.agent/` context files (context.md, architecture.md, decisions.md, conventions.md, runbook.md, glossary.md, backlog_rules.md). If the arguments describe what the project does (purpose, users, flows, business rules, constraints), use that description as a source alongside the code, as the skill's "Two sources" section explains. Do not invent facts — add TODOs for unknowns.

Description or focus: $ARGUMENTS
