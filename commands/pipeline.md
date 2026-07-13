---
description: Run the full SDD pipeline (planner → architect → builder → tester → reviewer) with confirmation gates
argument-hint: <feature description>
---

Read `${CLAUDE_PLUGIN_ROOT}/agents/conductor.md` and adopt the conductor role, orchestrating the full pipeline with a confirmation gate at every stage transition. Load each role definition from `${CLAUDE_PLUGIN_ROOT}/agents/` as you reach its stage.

If the project has a `.agent/SKILLS.md`, read it first and follow the linked skills and project overrides throughout the pipeline.

Feature to deliver: $ARGUMENTS
