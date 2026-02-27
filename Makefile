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
AGENTS_DIR  := $(SDD_DIR)agents
PROMPTS_DIR := $(SDD_DIR)prompts
SPECS_DIR   := $(SDD_DIR)specs
OUTPUTS     := $(SDD_DIR)outputs

STACK  ?= spring-boot
TARGET ?= $(CURDIR)
FORMAT ?= agent
# FORMAT: agent | kiro

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
	@echo "    make bootstrap STACK=spring-boot TARGET=~/projects/my-api"
	@echo "    make install STACK=dotnet TARGET=~/projects/my-app FORMAT=kiro"
	@echo "    make generate"
	@echo "    make validate"
	@echo ""

# ─── Validate ─────────────────────────────────────────────────────────────────
.PHONY: validate
validate: ## Validate all skill files (frontmatter + required sections)
	@echo "$(CYAN)▶ Validating skill files...$(RESET)"
	@bash $(SCRIPTS_DIR)/validate.sh $(SKILLS_DIR) $(TEMPLATES)
	@echo "$(GREEN)✔ All skills valid$(RESET)"

# ─── Generate ─────────────────────────────────────────────────────────────────
.PHONY: generate
generate: ## Generate .toml files from all .md skill files
	@echo "$(CYAN)▶ Generating .toml files...$(RESET)"
	@bash $(SCRIPTS_DIR)/generate.sh $(SKILLS_DIR) $(OUTPUTS)
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


# ─── Bootstrap ────────────────────────────────────────────────────────────────
.PHONY: bootstrap
bootstrap: check install ## Bootstrap workflow: validate, generate and install .agent context
	@echo "$(GREEN)✔ Bootstrap completed (validation + install)$(RESET)"

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

# ─── Upgrade ─────────────────────────────────────────────────────────────────
.PHONY: upgrade
upgrade: update install ## Pull latest skills, regenerate, and reinstall into TARGET project
	@echo "$(GREEN)✔ SDD upgraded in: $(TARGET)$(RESET)"

# ─── Check (CI) ───────────────────────────────────────────────────────────────
.PHONY: check
check: validate generate validate-agents ## Run all checks (for CI)
	@echo "$(GREEN)✔ All checks passed$(RESET)"

# ─── Validate Agents ──────────────────────────────────────────────────────────
.PHONY: validate-agents
validate-agents: ## Validate agent, prompt, and spec files (frontmatter check)
	@echo "$(CYAN)▶ Validating agents...$(RESET)"
	@errors=0; \
	for f in $(AGENTS_DIR)/*.md; do \
		[ -f "$$f" ] || continue; \
		bname=$$(basename "$$f"); \
		[ "$$bname" = "README.md" ] && continue; \
		if ! head -1 "$$f" | grep -q "^---"; then \
			echo "  $(RED)✘$(RESET) agents/$$bname — missing frontmatter"; \
			errors=$$((errors+1)); \
		fi; \
	done; \
	echo "$(CYAN)▶ Validating prompts...$(RESET)"; \
	for f in $(PROMPTS_DIR)/*.md; do \
		[ -f "$$f" ] || continue; \
		bname=$$(basename "$$f"); \
		[ "$$bname" = "README.md" ] && continue; \
		if ! head -1 "$$f" | grep -q "^---"; then \
			echo "  $(RED)✘$(RESET) prompts/$$bname — missing frontmatter"; \
			errors=$$((errors+1)); \
		fi; \
	done; \
	echo "$(CYAN)▶ Validating spec schemas...$(RESET)"; \
	for f in $(SPECS_DIR)/*.schema.md; do \
		[ -f "$$f" ] || continue; \
		bname=$$(basename "$$f"); \
		if ! head -1 "$$f" | grep -q "^---"; then \
			echo "  $(RED)✘$(RESET) specs/$$bname — missing frontmatter"; \
			errors=$$((errors+1)); \
		fi; \
	done; \
	if [ $$errors -gt 0 ]; then \
		echo "$(RED)✘ $$errors file(s) failed validation$(RESET)"; exit 1; \
	fi
	@echo "$(GREEN)✔ All agents, prompts, and specs valid$(RESET)"

# ─── Structure ────────────────────────────────────────────────────────────────
.PHONY: structure
structure: ## Show the full SDD project structure
	@echo ""
	@echo "  $(BOLD)SDD Project Structure$(RESET)"
	@echo ""
	@echo "  $(CYAN)Skills:$(RESET)"
	@find $(SKILLS_DIR) -name "*.md" 2>/dev/null | sort | while read f; do \
		printf "    %s\n" "$${f#$(SDD_DIR)}"; \
	done
	@echo ""
	@echo "  $(CYAN)Agents:$(RESET)"
	@find $(AGENTS_DIR) -name "*.md" 2>/dev/null | sort | while read f; do \
		printf "    %s\n" "$${f#$(SDD_DIR)}"; \
	done
	@echo ""
	@echo "  $(CYAN)Prompts:$(RESET)"
	@find $(PROMPTS_DIR) -name "*.md" 2>/dev/null | sort | while read f; do \
		printf "    %s\n" "$${f#$(SDD_DIR)}"; \
	done
	@echo ""
	@echo "  $(CYAN)Specs:$(RESET)"
	@find $(SPECS_DIR) -name "*.md" 2>/dev/null | sort | while read f; do \
		printf "    %s\n" "$${f#$(SDD_DIR)}"; \
	done
	@echo ""

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
clean: ## Remove generated outputs
	@echo "$(CYAN)▶ Cleaning generated files...$(RESET)"
	@rm -rf $(OUTPUTS)
	@echo "$(GREEN)✔ Cleaned$(RESET)"
