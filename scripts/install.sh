#!/usr/bin/env bash
# install.sh — Install SDD skills into a project
#
# Usage (standalone, via curl):
#   bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) spring-boot
#   bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) dotnet
#   bash <(curl -fsSL https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.sh) dotnet /path/to/project kiro
#
# Usage (from Makefile):
#   make install STACK=spring-boot TARGET=/path/to/project FORMAT=agent

set -euo pipefail

# ─── Args ─────────────────────────────────────────────────────────────────────
STACK="${1:-}"
TARGET="${2:-$(pwd)}"
FORMAT="${3:-agent}"   # agent | kiro
SDD_SOURCE="${4:-}"    # set by Makefile; empty = will clone/use local

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

SDD_REPO="https://github.com/valossa515/sdd.git"
TMPDIR_SDD=""

# ─── Helpers ──────────────────────────────────────────────────────────────────
banner() {
  echo ""
  echo -e "${BOLD}  SDD — Skill-Driven Development${RESET}"
  echo -e "  Specialized skill files for AI coding agents"
  echo ""
}

usage() {
  echo "Usage:"
  echo "  $0 <stack> [target_dir] [format]"
  echo ""
  echo "Arguments:"
  echo "  stack       spring-boot | dotnet"
  echo "  target_dir  Path to your project (default: current dir)"
  echo "  format      agent | kiro  (default: agent)"
  echo ""
  echo "Examples:"
  echo "  $0 spring-boot"
  echo "  $0 dotnet ~/projects/my-api"
  echo "  $0 spring-boot ~/projects/my-api kiro"
  exit 1
}

check_deps() {
  local missing=()
  for cmd in git cp mkdir; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo -e "${RED}✘ Missing required tools: ${missing[*]}${RESET}"
    exit 1
  fi
}

cleanup() {
  if [ -n "$TMPDIR_SDD" ] && [ -d "$TMPDIR_SDD" ]; then
    rm -rf "$TMPDIR_SDD"
  fi
}

# ─── Get SDD source ───────────────────────────────────────────────────────────
ensure_sdd_source() {
  if [ -n "$SDD_SOURCE" ] && [ -d "$SDD_SOURCE/skills" ]; then
    echo "$SDD_SOURCE"
    return
  fi

  # Check if we're running from inside the sdd repo
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local repo_root
  repo_root="$(cd "$script_dir/.." && pwd)"
  if [ -d "$repo_root/skills" ]; then
    echo "$repo_root"
    return
  fi

  # Clone the repo to a temp directory
  echo -e "${CYAN}▶ Fetching SDD from GitHub...${RESET}" >&2
  TMPDIR_SDD=$(mktemp -d)
  trap cleanup EXIT
  git clone --depth=1 --quiet "$SDD_REPO" "$TMPDIR_SDD"
  echo "$TMPDIR_SDD"
}

# ─── Install in .agent/ format ────────────────────────────────────────────────
install_agent_format() {
  local src="$1"
  local dest="$TARGET/.agent"

  mkdir -p "$dest/skills/shared" "$dest/adr"

  echo -e "  ${CYAN}→${RESET} .agent/skills/shared/"
  cp -r "$src/skills/shared/." "$dest/skills/shared/"

  echo -e "  ${CYAN}→${RESET} .agent/context docs"
  cp "$src/templates/common/context.md" "$dest/context.md"
  cp "$src/templates/common/architecture.md" "$dest/architecture.md"
  cp "$src/templates/common/decisions.md" "$dest/decisions.md"
  cp "$src/templates/common/conventions.md" "$dest/conventions.md"
  cp "$src/templates/common/runbook.md" "$dest/runbook.md"
  cp "$src/templates/common/glossary.md" "$dest/glossary.md"
  cp "$src/templates/common/backlog_rules.md" "$dest/backlog_rules.md"

  case "$STACK" in
    spring-boot)
      mkdir -p "$dest/skills/spring-boot"
      echo -e "  ${CYAN}→${RESET} .agent/skills/spring-boot/"
      cp -r "$src/skills/spring-boot/." "$dest/skills/spring-boot/"
      cp "$src/templates/spring-boot/SKILLS.md" "$dest/SKILLS.md"
      ;;
    dotnet)
      mkdir -p "$dest/skills/dotnet"
      echo -e "  ${CYAN}→${RESET} .agent/skills/dotnet/"
      cp -r "$src/skills/dotnet/." "$dest/skills/dotnet/"
      cp "$src/templates/dotnet/SKILLS.md" "$dest/SKILLS.md"
      ;;
    *)
      echo -e "${RED}✘ Unknown stack: $STACK. Use spring-boot or dotnet.${RESET}"
      exit 1
      ;;
  esac

  echo -e "  ${CYAN}→${RESET} .agent/SKILLS.md"

  # ── Agents ────────────────────────────────────────────────────────────────
  if [ -d "$src/agents" ]; then
    mkdir -p "$dest/agents"
    echo -e "  ${CYAN}→${RESET} .agent/agents/"
    for f in "$src/agents/"*.md; do
      [ -f "$f" ] || continue
      cp "$f" "$dest/agents/"
    done
  fi

  # ── Copilot Custom Agents (.github/agents/*.agent.md) ──────────────────
  if [ -d "$src/agents" ]; then
    local agents_dir="$TARGET/.github/agents"
    mkdir -p "$agents_dir"
    echo -e "  ${CYAN}→${RESET} .github/agents/"
    for f in "$src/agents/"*.md; do
      [ -f "$f" ] || continue
      local bname
      bname=$(basename "$f")
      [ "$bname" = "README.md" ] && continue

      local agent_name
      agent_name=$(grep -m1 "^name:" "$f" | sed 's/^name: *//')
      local agent_desc
      agent_desc=$(awk '/^description:/{flag=1; sub(/^description: *>? */, ""); if(length($0)>0) print; next} flag && /^  /{sub(/^  */,""); print; next} flag{flag=0}' "$f" | tr '\n' ' ' | sed 's/  */ /g; s/ *$//')

      # Extract markdown body (everything after second ---)
      local body
      body=$(awk 'BEGIN{c=0} /^---/{c++; next} c>=2{print}' "$f")

      local agent_file="${agents_dir}/${agent_name}.agent.md"
      {
        echo "---"
        echo "name: ${agent_name}"
        echo "description: \"${agent_desc}\""
        echo "---"
        echo ""
        echo "Read and follow all skills in .agent/SKILLS.md before any task."
        echo ""
        echo "$body"
      } > "$agent_file"
      echo -e "     ${agent_name}.agent.md"
    done
  fi

  # ── Prompts ───────────────────────────────────────────────────────────────
  if [ -d "$src/prompts" ]; then
    mkdir -p "$dest/prompts"
    echo -e "  ${CYAN}→${RESET} .agent/prompts/"
    for f in "$src/prompts/"*.md; do
      [ -f "$f" ] || continue
      cp "$f" "$dest/prompts/"
    done
  fi

  # ── Spec schemas ──────────────────────────────────────────────────────────
  if [ -d "$src/specs" ]; then
    mkdir -p "$dest/specs"
    echo -e "  ${CYAN}→${RESET} .agent/specs/"
    for f in "$src/specs/"*.md; do
      [ -f "$f" ] || continue
      cp "$f" "$dest/specs/"
    done
  fi

  # ── PR template ───────────────────────────────────────────────────────────
  if [ -f "$src/templates/PULL_REQUEST_TEMPLATE.md" ]; then
    mkdir -p "$dest/templates"
    cp "$src/templates/PULL_REQUEST_TEMPLATE.md" "$dest/templates/"
    echo -e "  ${CYAN}→${RESET} .agent/templates/PULL_REQUEST_TEMPLATE.md"
  fi

  echo ""
  echo -e "${GREEN}✔ Installed to: ${dest}${RESET}"
}

# ─── Install in Kiro .kiro/steering/ format ───────────────────────────────────
install_kiro_format() {
  local src="$1"
  local dest="$TARGET/.kiro/steering"

  mkdir -p "$dest"

  # Copy shared skills
  echo -e "  ${CYAN}→${RESET} .kiro/steering/ (shared)"
  for f in "$src/skills/shared/"*.md; do
    cp "$f" "$dest/"
    echo -e "     $(basename $f)"
  done

  # Copy stack-specific skills
  local stack_dir="$src/skills/$STACK"
  if [ ! -d "$stack_dir" ]; then
    echo -e "${RED}✘ No skills found for stack: $STACK${RESET}"
    exit 1
  fi

  echo -e "  ${CYAN}→${RESET} .kiro/steering/ ($STACK)"
  for f in "$stack_dir/"*.md; do
    cp "$f" "$dest/${STACK}-$(basename $f)"
    echo -e "     ${STACK}-$(basename $f)"
  done

  # Also copy .toml if they exist
  for f in "$stack_dir/"*.toml; do
    [ -f "$f" ] || continue
    cp "$f" "$dest/${STACK}-$(basename $f)"
    echo -e "     ${STACK}-$(basename $f)"
  done

  # Copy agents (flattened with agent- prefix)
  if [ -d "$src/agents" ]; then
    echo -e "  ${CYAN}→${RESET} .kiro/steering/ (agents)"
    for f in "$src/agents/"*.md; do
      [ -f "$f" ] || continue
      bname=$(basename "$f")
      [ "$bname" = "README.md" ] && continue
      cp "$f" "$dest/agent-$bname"
      echo -e "     agent-$bname"
    done
  fi

  # Copy prompts (flattened with prompt- prefix)
  if [ -d "$src/prompts" ]; then
    echo -e "  ${CYAN}→${RESET} .kiro/steering/ (prompts)"
    for f in "$src/prompts/"*.md; do
      [ -f "$f" ] || continue
      bname=$(basename "$f")
      [ "$bname" = "README.md" ] && continue
      cp "$f" "$dest/prompt-$bname"
      echo -e "     prompt-$bname"
    done
  fi

  echo ""
  echo -e "${GREEN}✔ Installed to: ${dest}${RESET}"
}

# ─── .gitignore hint ──────────────────────────────────────────────────────────
suggest_gitignore() {
  local gitignore="$TARGET/.gitignore"
  local comment="# SDD — commit .agent/ to share conventions with your team"

  if [ -f "$gitignore" ]; then
    if ! grep -q "\.agent/" "$gitignore" 2>/dev/null; then
      echo ""
      echo -e "${YELLOW}Tip:${RESET} Commit the .agent/ folder so your team shares the same conventions."
      echo -e "     (Don't add it to .gitignore)"
    fi
  fi
}

# ─── Post-install summary ─────────────────────────────────────────────────────
post_install_summary() {
  echo ""
  echo "  ┌─────────────────────────────────────────────────────────┐"
  echo "  │  ${BOLD}What to do next${RESET}                                         │"
  echo "  │                                                         │"
  if [ "$FORMAT" = "kiro" ]; then
    echo "  │  1. Open .kiro/steering/ and review the skills          │"
    echo "  │  2. Edit ${STACK}-SKILL.md to add project conventions   │"
  else
    echo "  │  1. Open .agent/SKILLS.md and review the active skills  │"
    echo "  │  2. Fill in the '## Project Overrides' section          │"
    echo "  │  3. Review .agent/agents/ for the agent pipeline        │"
    echo "  │  4. Review .agent/prompts/ for action templates         │"
  fi
  echo "  │  5. Commit the folder alongside your source code        │"
  echo "  │  6. Tell your agent: 'Read .agent/SKILLS.md before      │"
  echo "  │     every task'  (or set up auto-context loading)       │"
  echo "  └─────────────────────────────────────────────────────────┘"
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  banner
  check_deps

  if [ -z "$STACK" ]; then
    echo -e "${RED}✘ Stack is required.${RESET}"
    usage
  fi

  if [ ! -d "$TARGET" ]; then
    echo -e "${RED}✘ Target directory does not exist: $TARGET${RESET}"
    exit 1
  fi

  echo -e "  Stack  : ${YELLOW}${STACK}${RESET}"
  echo -e "  Target : ${YELLOW}${TARGET}${RESET}"
  echo -e "  Format : ${YELLOW}${FORMAT}${RESET}"
  echo ""

  local sdd_src
  sdd_src=$(ensure_sdd_source)

  echo -e "${CYAN}▶ Installing skills...${RESET}"
  echo ""

  case "$FORMAT" in
    agent)  install_agent_format "$sdd_src" ;;
    kiro)   install_kiro_format  "$sdd_src" ;;
    *)
      echo -e "${RED}✘ Unknown format: $FORMAT. Use 'agent' or 'kiro'.${RESET}"
      exit 1
      ;;
  esac

  suggest_gitignore
  post_install_summary
}

main "$@"
