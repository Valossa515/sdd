# Contributing to SDD

Thank you for wanting to improve these skills! Every good convention captured here saves someone from explaining it in 50 prompts.

---

## Adding a new skill

### 1. Scaffold it

```bash
make new STACK=spring-boot NAME=messaging
# or
make new STACK=dotnet NAME=outbox
# or
make new STACK=shared NAME=security
```

This creates `skills/<stack>/<name>.md` with the right template.

### 2. Fill in the [TODO] sections

Every skill must have:

- **Frontmatter** (`name`, `description`, `stack`, `versions`)
- At least one `## ` section with real content
- **Code examples** — prose is not enough
- **`## What NOT to do`** — anti-patterns matter as much as patterns

### 3. Validate and generate

```bash
make validate   # check frontmatter and structure
make generate   # build .toml files
```

Both must pass cleanly before you open a PR.

### 4. Update the relevant SKILLS.md template

If your skill should be active by default for a stack, add it to `templates/<stack>/SKILLS.md`.

---

## Editing an existing skill

- Keep breaking changes minimal
- If changing a major convention (e.g., switching from `@Value` to `@ConfigurationProperties`), briefly mention the old way so readers can migrate
- Re-run `make validate && make generate` after every edit

---

## Skill quality checklist

Before opening a PR, verify:

- [ ] Frontmatter is complete (`name`, `description`, `stack`, `versions`)
- [ ] At least one code example per major concept
- [ ] `## What NOT to do` section present
- [ ] Version-specific (e.g., "Spring Boot 3.x" not just "Spring Boot")
- [ ] `make check` passes

---

## Conventions for skill files

### Frontmatter

```markdown
---
name: spring-boot-messaging        # kebab-case, must be unique
description: >
  One or two lines. Start with "Use this skill when..."
  Be specific about what triggers it.
stack: spring-boot                 # spring-boot | dotnet | shared
versions: "Java 21+, Spring Boot 3.x"
---
```

### Section order (preferred)

1. Stack Versions
2. Architecture (if applicable)
3. Naming Conventions
4. [Main concepts]
5. Configuration
6. Testing
7. What NOT to do

### Code examples

- Use the language of the stack (Java for Spring Boot, C# for .NET)
- Show realistic, production-like examples — not toy snippets
- Include imports when they add clarity
- Prefer full class/method examples over fragments

---

## Stack version targets

Always target these unless creating a version-specific skill:

| Stack | Version |
|-------|---------|
| Java | 21+ |
| Spring Boot | 3.x |
| .NET | 8 / 9 |
| C# | 12+ |
| EF Core | 8+ |
| PostgreSQL | 16 |

---

## Questions or ideas?

Open an issue! Skill suggestions, real-world war stories, anti-patterns you've seen in the wild — all welcome.
