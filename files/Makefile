# SDD — Skill-Driven Development
# ================================
# Usage:
#   make help
#   make validate
#   make generate
#   make install STACK=spring-boot TARGET=/path/to/your/project
#   make install STACK=dotnet     TARGET=/path/to/your/project FORMAT=kiro

SHELL := /bin/bash
.DEFAULT_GOAL := help

# ─── Config ───────────────────────────────────────────────────────────────────
SDD_DIR     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SKILLS_DIR  := $(SDD_DIR)skills
SCRIPTS_DIR := $(SDD_DIR)scripts
TEMPLATES   := $(SDD_DIR)templates

STACK  ?= spring-boot
TARGET ?= $(CURDIR)
FORMAT ?= agent   # agent | kiro

GREEN  := \033[0;32m
YELLOW := \033[1;33m
CYAN   := \033[0;36m
RED    := \033[0;31m
RESET  := \033[0m
BOLD   := \033[1m

# ─── Help ─────────────────────────────────────────────────────────────────────
.PHONY: help
help: ## Show this help
	@echo ""
	@echo "  $(BOLD)SDD — Skill-Driven Development$(RESET)"
	@echo "  Specialized skill files for AI coding agents"
	@echo ""
	@echo "  $(CYAN)Usage:$(RESET)"
	@echo "    make <target> [STACK=spring-boot|dotnet] [TARGET=path] [FORMAT=agent|kiro]"
	@echo ""
	@echo "  $(CYAN)Targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "    $(GREEN)%-18s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "  $(CYAN)Examples:$(RESET)"
	@echo "    make install STACK=spring-boot TARGET=~/projects/my-api"
	@echo "    make install STACK=dotnet TARGET=~/projects/my-app FORMAT=kiro"
	@echo "    make generate"
	@echo "    make validate"
	@echo ""

# ─── Validate ─────────────────────────────────────────────────────────────────
.PHONY: validate
validate: ## Validate all skill files (frontmatter + required sections)
	@echo "$(CYAN)▶ Validating skill files...$(RESET)"
	@bash $(SCRIPTS_DIR)/validate.sh $(SKILLS_DIR)
	@echo "$(GREEN)✔ All skills valid$(RESET)"

# ─── Generate ─────────────────────────────────────────────────────────────────
.PHONY: generate
generate: ## Generate .toml files from all .md skill files
	@echo "$(CYAN)▶ Generating .toml files...$(RESET)"
	@bash $(SCRIPTS_DIR)/generate.sh $(SKILLS_DIR)
	@echo "$(GREEN)✔ Generation complete$(RESET)"

# ─── Install ──────────────────────────────────────────────────────────────────
.PHONY: install
install: validate generate ## Install skills into a project (.agent/ or .kiro/steering/)
	@echo "$(CYAN)▶ Installing SDD into: $(TARGET)$(RESET)"
	@echo "  Stack  : $(YELLOW)$(STACK)$(RESET)"
	@echo "  Format : $(YELLOW)$(FORMAT)$(RESET)"
	@bash $(SCRIPTS_DIR)/install.sh "$(STACK)" "$(TARGET)" "$(FORMAT)" "$(SDD_DIR)"
	@echo "$(GREEN)✔ SDD installed successfully!$(RESET)"
	@echo ""
	@echo "  $(BOLD)Next steps:$(RESET)"
	@if [ "$(FORMAT)" = "kiro" ]; then \
		echo "  1. Open $(TARGET)/.kiro/steering/ and review the installed skills"; \
		echo "  2. Edit the files to add project-specific rules"; \
	else \
		echo "  1. Open $(TARGET)/.agent/SKILLS.md and review the active skills"; \
		echo "  2. Add your project-specific overrides in the '## Project Overrides' section"; \
	fi
	@echo "  3. Commit the .agent/ folder alongside your source code"
	@echo ""

# ─── Update ───────────────────────────────────────────────────────────────────
.PHONY: update
update: ## Pull latest skills and regenerate (for projects that already have SDD installed)
	@echo "$(CYAN)▶ Updating SDD...$(RESET)"
	@if [ ! -d "$(SDD_DIR).git" ]; then \
		echo "$(RED)✘ Not a git repo. Run from the sdd/ directory.$(RESET)"; exit 1; \
	fi
	git -C $(SDD_DIR) pull --ff-only
	@$(MAKE) generate
	@echo "$(GREEN)✔ SDD updated$(RESET)"

# ─── Check (CI) ───────────────────────────────────────────────────────────────
.PHONY: check
check: validate generate ## Run all checks (for CI)
	@echo "$(GREEN)✔ All checks passed$(RESET)"

# ─── List skills ──────────────────────────────────────────────────────────────
.PHONY: list
list: ## List all available skills
	@echo "$(CYAN)Available skills:$(RESET)"
	@echo ""
	@find $(SKILLS_DIR) -name "*.md" | sort | while read f; do \
		rel=$${f#$(SDD_DIR)}; \
		name=$$(grep -m1 '^name:' "$$f" 2>/dev/null | sed 's/name: *//'); \
		desc=$$(grep -m1 '^description:' "$$f" 2>/dev/null | sed 's/description: *//'); \
		printf "  $(GREEN)%-40s$(RESET) %s\n" "$$rel" "$$name"; \
	done
	@echo ""

# ─── New skill ────────────────────────────────────────────────────────────────
.PHONY: new
new: ## Scaffold a new skill (STACK=<stack> NAME=<name>)
	@if [ -z "$(NAME)" ]; then \
		echo "$(RED)✘ NAME is required. Usage: make new STACK=spring-boot NAME=messaging$(RESET)"; exit 1; \
	fi
	@bash $(SCRIPTS_DIR)/new-skill.sh "$(STACK)" "$(NAME)" "$(SKILLS_DIR)"

# ─── Clean generated ──────────────────────────────────────────────────────────
.PHONY: clean
clean: ## Remove all generated .toml files
	@echo "$(CYAN)▶ Cleaning generated files...$(RESET)"
	@find $(SKILLS_DIR) -name "*.toml" -delete
	@echo "$(GREEN)✔ Cleaned$(RESET)"
