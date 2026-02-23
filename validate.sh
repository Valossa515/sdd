#!/usr/bin/env bash
# validate.sh — Validates all skill .md files
# Usage: bash validate.sh <skills_dir>

set -euo pipefail

SKILLS_DIR="${1:?Skills directory required}"
ERRORS=0
FILES_CHECKED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

check_frontmatter() {
  local file="$1"
  local rel="${file#$SKILLS_DIR/}"

  # Must start with ---
  if ! head -1 "$file" | grep -q "^---"; then
    echo -e "  ${RED}✘${RESET} $rel — missing frontmatter (must start with ---)"
    return 1
  fi

  # Must have 'name:' field
  if ! grep -q "^name:" "$file"; then
    echo -e "  ${RED}✘${RESET} $rel — missing 'name:' in frontmatter"
    return 1
  fi

  # Must have 'description:' field
  if ! grep -q "^description:" "$file"; then
    echo -e "  ${RED}✘${RESET} $rel — missing 'description:' in frontmatter"
    return 1
  fi

  return 0
}

check_structure() {
  local file="$1"
  local rel="${file#$SKILLS_DIR/}"
  local warn=0

  # Should have at least one ## section
  if ! grep -q "^## " "$file"; then
    echo -e "  ${YELLOW}⚠${RESET}  $rel — no '##' sections found (skills should be structured)"
    warn=1
  fi

  # Should have code examples
  if ! grep -q '```' "$file"; then
    echo -e "  ${YELLOW}⚠${RESET}  $rel — no code examples found (skills work best with examples)"
    warn=1
  fi

  return 0
}

check_no_empty_sections() {
  local file="$1"
  local rel="${file#$SKILLS_DIR/}"
  local prev_header=""
  local in_section=0
  local has_content=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]] ]]; then
      if [[ -n "$prev_header" && "$has_content" -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠${RESET}  $rel — empty section: '$prev_header'"
      fi
      prev_header="$line"
      has_content=0
    elif [[ -n "$line" && ! "$line" =~ ^--- ]]; then
      has_content=1
    fi
  done < "$file"

  return 0
}

echo ""
echo "Scanning: $SKILLS_DIR"
echo "───────────────────────────────────────"

while IFS= read -r -d '' file; do
  rel="${file#$SKILLS_DIR/}"
  FILES_CHECKED=$((FILES_CHECKED + 1))

  if ! check_frontmatter "$file"; then
    ERRORS=$((ERRORS + 1))
    continue
  fi

  check_structure "$file"
  check_no_empty_sections "$file"

  echo -e "  ${GREEN}✔${RESET} $rel"

done < <(find "$SKILLS_DIR" -name "*.md" -print0 | sort -z)

echo "───────────────────────────────────────"
echo "Files checked: $FILES_CHECKED"

if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}Errors: $ERRORS — fix the issues above before generating.${RESET}"
  exit 1
fi

echo -e "${GREEN}All good!${RESET}"
