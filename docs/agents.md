# Agent Roles

SDD defines **six specialized agent roles** for AI-assisted development. Each role has a clear responsibility boundary and expects specific inputs/outputs.

Not every task needs every role. A simple bugfix might use only `builder` + `tester` + `reviewer`. A new feature uses the full pipeline.

## Pipeline

```
User Requirement
      │
      ▼
  ┌──────────┐     ┌───────────┐     ┌─────────┐
  │ planner  │ ──▶ │ architect │ ──▶ │ builder │
  └──────────┘     └───────────┘     └─────────┘
                                          │
                                          ▼
                                    ┌──────────┐     ┌──────────┐
                                    │  tester  │ ──▶ │ reviewer │
                                    └──────────┘     └──────────┘
```

The **conductor** orchestrates this pipeline end-to-end, or you can invoke each role individually.

## Roles

| Role | File | Input | Output |
|------|------|-------|--------|
| **planner** | [planner.md](../agents/planner.md) | Business requirement | Plan (.md) + feature spec + acceptance (.toon) |
| **architect** | [architect.md](../agents/architect.md) | Feature spec + plan (.toon + .md) | Architecture decisions (.md) + contract (.toon) |
| **builder** | [builder.md](../agents/builder.md) | Contract (.toon) or plan (.md) | Production code only |
| **tester** | [tester.md](../agents/tester.md) | Contract (.toon) + code | Test plan (.md) + test code |
| **reviewer** | [reviewer.md](../agents/reviewer.md) | Everything above | Review verdict (🔴🟡🔵) |
| **conductor** | [conductor.md](../agents/conductor.md) | Business requirement | Full pipeline |

## Cross-Cutting Rules (All Roles)

1. **Anti-invention** — never fabricate requirements (see `skills/shared/anti-invention/SKILL.md`)
2. **Pattern analysis** — study 3+ existing examples before generating (see `skills/shared/pattern-analysis/SKILL.md`)
3. **Scope isolation** — each role does ONLY its job, never another role's work
4. **Skills compliance** — always follow the active skills in `SKILLS.md`

## How to Use

During `make install`, agent files are placed in `.agent/agents/`. Each agent reads `SKILLS.md` and the linked skills before executing.

To use a specific role:
> "Act as the planner defined in `.agent/agents/planner.md`"

To run the full pipeline:
> "Act as the conductor defined in `.agent/agents/conductor.md` and implement: [your requirement]"
