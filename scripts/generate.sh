#!/usr/bin/env bash
# generate.sh — Generates .toml files from skill .md files
# Usage: bash generate.sh <skills_dir> [output_dir]

set -euo pipefail

SKILLS_DIR="${1:?Skills directory required}"
OUTPUT_DIR="${2:-$(dirname "$SKILLS_DIR")/outputs}"
GENERATED=0

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RESET='\033[0m'

fm_get() {
  local file="$1" key="$2" default="${3:-}"
  local val
  val=$(grep "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}: *//" | tr -d '"' || true)
  echo "${val:-$default}"
}

extract_section() {
  local file="$1" section="$2"
  awk "/^## ${section}/{found=1; next} found && /^## /{found=0} found{print}" "$file" 2>/dev/null || true
}

generate_toml() {
  local md_file="$1"
  local rel="${md_file#$SKILLS_DIR/}"
  local toml_file="$OUTPUT_DIR/skills/${rel%.md}.toml"

  mkdir -p "$(dirname "$toml_file")"

  local name description stack
  name=$(fm_get "$md_file" "name" "unknown")
  description=$(fm_get "$md_file" "description" "" | tr -d '\n')
  stack=$(fm_get "$md_file" "stack" "shared")

  {
    echo "# Auto-generated from ${rel}"
    echo "# Run 'make generate' to rebuild — do not edit manually"
    echo ""
    echo "[skill]"
    echo "name        = \"${name}\""
    echo "description = \"${description}\""
    echo "stack       = \"${stack}\""
    echo "source      = \"${rel}\""
  } > "$toml_file"

  echo -e "  ${CYAN}→${RESET} ${toml_file#$(dirname "$SKILLS_DIR")/}"
  GENERATED=$((GENERATED + 1))
}

echo ""
echo "Generating .toml from skill files..."
echo "───────────────────────────────────────"

while IFS= read -r -d '' file; do
  generate_toml "$file"
done < <(find "$SKILLS_DIR" -name "*.md" -print0 | sort -z)

echo "───────────────────────────────────────"
echo -e "${GREEN}Generated: $GENERATED files${RESET}"
