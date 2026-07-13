# Examples

End-to-end, artifact-by-artifact snapshots of the SDD pipeline in action.

| Example | Stack | What it shows |
|---------|-------|---------------|
| [create-order](create-order/) | Spring Boot | Full pipeline run: requirement → planner → architect → builder → tester → reviewer, with every artifact in its role's format |

All `.toon` specs inside the examples are validated in CI by
`scripts/validate-spec.sh` — they double as living documentation and as
regression fixtures for the spec validator.
