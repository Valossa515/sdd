#!/usr/bin/env bash
# generate.sh — Generates .toml files from skill .md files
# Usage: bash generate.sh <skills_dir>

SKILLS_DIR="${1:?Skills directory required}"
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
  local toml_file="${md_file%.md}.toml"
  local rel="${md_file#$SKILLS_DIR/}"

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
    echo ""

    # Architecture rules
    local arch
    arch=$(extract_section "$md_file" "Architecture")
    if [ -n "$arch" ]; then
      local rules
      rules=$(echo "$arch" | grep "^- " | sed 's/^- //' | sed 's/\*\*//g; s/`//g' | sed "s/\"/'/g" || true)
      if [ -n "$rules" ]; then
        echo "[skill.architecture]"
        echo "rules = ["
        while IFS= read -r r; do
          [ -z "$r" ] && continue
          echo "  \"${r}\","
        done <<< "$rules"
        echo "]"
        echo ""
      fi
    fi

    # Naming conventions from table
    local naming
    naming=$(extract_section "$md_file" "Naming Conventions")
    if [ -n "$naming" ]; then
      local first=true
      while IFS='|' read -r _ artifact convention example _; do
        artifact=$(echo "$artifact" | xargs 2>/dev/null || true)
        convention=$(echo "$convention" | xargs 2>/dev/null || true)
        example=$(echo "$example" | xargs 2>/dev/null | sed 's/`//g' || true)
        [[ -z "$artifact" || "$artifact" == "Artifact" || "$artifact" =~ ^-+$ ]] && continue
        if $first; then
          echo "[[skill.naming]]"
          first=false
        fi
        echo "  [[skill.naming]]"
        echo "  artifact   = \"${artifact}\""
        echo "  convention = \"${convention}\""
        echo "  example    = \"${example}\""
      done <<< "$naming"
      echo ""
    fi

    # Anti-patterns
    local antis
    antis=$(extract_section "$md_file" "What NOT to do")
    if [ -n "$antis" ]; then
      echo "[skill.antipatterns]"
      echo "rules = ["
      while IFS= read -r line; do
        item=$(echo "$line" | sed 's/^- ❌ //' | sed 's/^- //' | sed 's/`//g; s/\*\*//g' | sed "s/\"/'/g" | xargs 2>/dev/null || true)
        [ -z "$item" ] && continue
        echo "  \"${item}\","
      done <<< "$(echo "$antis" | grep "^- ")"
      echo "]"
      echo ""
    fi

    # Testing rules
    local testing
    testing=$(extract_section "$md_file" "Testing")
    if [ -n "$testing" ]; then
      local trules
      trules=$(echo "$testing" | grep "^- " | sed 's/^- //' | sed 's/`//g; s/\*\*//g' | sed "s/\"/'/g" || true)
      if [ -n "$trules" ]; then
        echo "[skill.testing]"
        echo "rules = ["
        while IFS= read -r r; do
          [ -z "$r" ] && continue
          echo "  \"${r}\","
        done <<< "$trules"
        echo "]"
      fi
    fi

  } > "$toml_file"

  echo -e "  ${CYAN}→${RESET} ${rel%.md}.toml"
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
