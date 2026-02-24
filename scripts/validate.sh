#!/usr/bin/env bash
# validate.sh — Validates all skill .md files
# Usage: bash validate.sh <skills_dir>

set -euo pipefail

SKILLS_DIR="${1:?Skills directory required}"
TEMPLATES_DIR="${2:-}"
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

  # Must have closing --- for frontmatter
  local fm_end
  fm_end=$(awk 'NR>1 && /^---/{print NR; exit}' "$file")
  if [ -z "$fm_end" ]; then
    echo -e "  ${RED}✘${RESET} $rel — frontmatter not closed (missing second ---)"
    return 1
  fi

  # Must have 'name:' field
  if ! grep -q "^name:" "$file"; then
    echo -e "  ${RED}✘${RESET} $rel — missing 'name:' in frontmatter"
    return 1
  fi

  # Name must be kebab-case
  local name_val
  name_val=$(grep -m1 "^name:" "$file" | sed 's/^name: *//')
  if ! echo "$name_val" | grep -qE '^[a-z][a-z0-9-]*$'; then
    echo -e "  ${RED}✘${RESET} $rel — 'name:' must be kebab-case (got: $name_val)"
    return 1
  fi

  # Must have 'description:' field
  if ! grep -q "^description:" "$file"; then
    echo -e "  ${RED}✘${RESET} $rel — missing 'description:' in frontmatter"
    return 1
  fi

  # Must have 'stack:' field
  if ! grep -q "^stack:" "$file"; then
    echo -e "  ${RED}✘${RESET} $rel — missing 'stack:' in frontmatter"
    return 1
  fi

  # Stack must be a valid value
  local stack_val
  stack_val=$(grep -m1 "^stack:" "$file" | sed 's/^stack: *//')
  if ! echo "$stack_val" | grep -qE '^(spring-boot|dotnet|shared)$'; then
    echo -e "  ${RED}✘${RESET} $rel — 'stack:' must be spring-boot, dotnet, or shared (got: $stack_val)"
    return 1
  fi

  # Must have 'versions:' field
  if ! grep -q "^versions:" "$file"; then
    echo -e "  ${RED}✘${RESET} $rel — missing 'versions:' in frontmatter"
    return 1
  fi

  # Skill file must be in the matching stack directory
  local dir_stack
  dir_stack=$(echo "$rel" | cut -d'/' -f1)
  if [ "$dir_stack" != "$stack_val" ]; then
    echo -e "  ${YELLOW}⚠${RESET}  $rel — stack '$stack_val' does not match directory '$dir_stack'"
  fi

  return 0
}

check_required_templates() {
  local base="$1"
  local required=(
    "context.md"
    "architecture.md"
    "decisions.md"
    "conventions.md"
    "runbook.md"
    "glossary.md"
    "backlog_rules.md"
  )

  echo ""
  echo "Checking required project context templates in: $base"
  for f in "${required[@]}"; do
    if [ ! -f "$base/$f" ]; then
      echo -e "  ${RED}✘${RESET} missing template: $f"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "  ${GREEN}✔${RESET} $f"
    fi
  done
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

  # Should have a "What NOT to do" section (recommended for all skills)
  if ! grep -qi "## What NOT to do" "$file"; then
    echo -e "  ${YELLOW}⚠${RESET}  $rel — missing 'What NOT to do' section (recommended)"
    warn=1
  fi

  # Should have a top-level # heading
  if ! grep -q "^# " "$file"; then
    echo -e "  ${YELLOW}⚠${RESET}  $rel — missing top-level '# ' heading"
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

if [ -n "$TEMPLATES_DIR" ] && [ -d "$TEMPLATES_DIR/common" ]; then
  check_required_templates "$TEMPLATES_DIR/common"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}Errors: $ERRORS — fix the issues above before generating.${RESET}"
  exit 1
fi

echo -e "${GREEN}All good!${RESET}"
