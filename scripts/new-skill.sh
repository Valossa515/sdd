#!/usr/bin/env bash
# new-skill.sh — Scaffold a new skill file
# Usage: bash new-skill.sh <stack> <name> <skills_dir>

set -euo pipefail

STACK="${1:?Stack required (spring-boot | dotnet | shared)}"
NAME="${2:?Skill name required}"
SKILLS_DIR="${3:?Skills directory required}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

DEST="$SKILLS_DIR/$STACK/$NAME.md"

if [ -f "$DEST" ]; then
  echo "File already exists: $DEST"
  exit 1
fi

mkdir -p "$SKILLS_DIR/$STACK"

cat > "$DEST" <<EOF
---
name: ${STACK}-${NAME}
description: >
  Use this skill when working with ${NAME} in ${STACK} projects.
  [TODO: Describe when this skill should be activated.]
stack: ${STACK}
versions: "[TODO: versions supported]"
---

# ${NAME^} — ${STACK}

[TODO: Brief intro. What problem does this skill solve?]

## Stack Versions

- **[Framework/lib]**: X.x+
- [Add relevant version pins here]

## Architecture

[TODO: Where does this concern fit in the project structure?]

\`\`\`
[Add folder/file structure example]
\`\`\`

**Rules:**
- [Rule 1]
- [Rule 2]

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| [Thing]  | [Pattern] | [Example] |

## Implementation

[TODO: Show the canonical way to implement this concern]

\`\`\`java
// [Stack-appropriate code example]
\`\`\`

## Configuration

[TODO: Any configuration needed?]

## Testing

- [How to test this concern]
- [What to mock, what to integrate]

## What NOT to do

- ❌ [Anti-pattern 1 — explain why]
- ❌ [Anti-pattern 2 — explain why]
EOF

echo -e "${GREEN}✔ Created: $DEST${RESET}"
echo ""
echo -e "${CYAN}Edit the file and fill in the [TODO] sections.${RESET}"
echo -e "Then run ${CYAN}make validate && make generate${RESET} to check and compile it."
