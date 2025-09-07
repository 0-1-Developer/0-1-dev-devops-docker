# Docker Learning Path - Makefile
# Provides common operations and utilities for the Docker learning path

.PHONY: help setup verify clean status progress test-phase build-images lint
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Docker Learning Path - Available Commands$(RESET)"
	@echo "=========================================="
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Initial setup for new learners
	@echo "$(BLUE)Setting up Docker Learning Path environment...$(RESET)"
	@docker --version || (echo "$(RED)Docker not installed. Please install Docker first.$(RESET)" && exit 1)
	@docker compose version || (echo "$(RED)Docker Compose not available. Please install Docker Compose.$(RESET)" && exit 1)
	@echo "$(GREEN)✅ Docker environment verified$(RESET)"
	@echo "$(GREEN)✅ Ready to start learning! Begin with: make progress$(RESET)"

verify: ## Run verification for all completed phases
	@echo "$(BLUE)Running verification for completed phases...$(RESET)"
	@./scripts/verify-progress.sh

verify-phase: ## Run verification for specific phase (usage: make verify-phase PHASE=04)
	@if [ -z "$(PHASE)" ]; then \
		echo "$(RED)Usage: make verify-phase PHASE=04$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Verifying Phase $(PHASE)...$(RESET)"
	@if [ -f "./$(PHASE)-*/verify.rules.md" ]; then \
		echo "Running Phase $(PHASE) verification..."; \
		cd $(shell find . -name "$(PHASE)-*" -type d | head -1) && \
		if [ -f "scripts/verify.sh" ]; then ./scripts/verify.sh; else echo "$(YELLOW)No verification script found$(RESET)"; fi; \
	else \
		echo "$(RED)Phase $(PHASE) not found$(RESET)"; \
		exit 1; \
	fi

clean: ## Clean up all Docker resources from exercises
	@echo "$(YELLOW)⚠️  This will remove ALL Docker resources created during exercises$(RESET)"
	@echo "$(YELLOW)Continue? [y/N]:$(RESET)"; \
	read -r response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		echo "$(BLUE)Cleaning up Docker resources...$(RESET)"; \
		docker container prune -f; \
		docker image prune -a -f; \
		docker volume prune -f; \
		docker network prune -f; \
		docker builder prune -a -f; \
		echo "$(GREEN)✅ Docker cleanup complete$(RESET)"; \
	else \
		echo "$(GREEN)Cleanup cancelled$(RESET)"; \
	fi

clean-safe: ## Safe cleanup - only remove unused resources
	@echo "$(BLUE)Running safe cleanup (unused resources only)...$(RESET)"
	@docker container prune -f
	@docker image prune -f
	@docker volume prune -f
	@docker network prune -f
	@echo "$(GREEN)✅ Safe cleanup complete$(RESET)"

clean-phase: ## Clean up resources from specific phase (usage: make clean-phase PHASE=04)
	@if [ -z "$(PHASE)" ]; then \
		echo "$(RED)Usage: make clean-phase PHASE=04$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Cleaning up Phase $(PHASE) resources...$(RESET)"
	@if [ -f "./$(PHASE)-*/cleanup.rules.md" ]; then \
		cd $(shell find . -name "$(PHASE)-*" -type d | head -1) && \
		if [ -f "scripts/cleanup.sh" ]; then ./scripts/cleanup.sh; else echo "$(YELLOW)No cleanup script found, running manual cleanup$(RESET)"; fi; \
	else \
		echo "$(RED)Phase $(PHASE) not found$(RESET)"; \
		exit 1; \
	fi

status: ## Show current Docker system status
	@echo "$(BLUE)Docker System Status$(RESET)"
	@echo "===================="
	@echo "$(GREEN)Docker Version:$(RESET)"
	@docker version --format "Client: {{.Client.Version}} | Server: {{.Server.Version}}"
	@echo ""
	@echo "$(GREEN)System Information:$(RESET)"
	@docker system df
	@echo ""
	@echo "$(GREEN)Running Containers:$(RESET)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(GREEN)Recent Images:$(RESET)"
	@docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | head -6

progress: ## Show learning progress and next steps
	@echo "$(BLUE)Docker Learning Path Progress$(RESET)"
	@echo "==============================="
	@if [ -f "docs/PROGRESS.json" ]; then \
		./scripts/progress-summary.sh; \
	else \
		echo "$(YELLOW)Progress tracking not initialized$(RESET)"; \
	fi

next: ## Show next recommended learning step
	@echo "$(BLUE)Next Learning Step$(RESET)"
	@echo "=================="
	@./scripts/next-step.sh

test-phase: ## Run tests for specific phase (usage: make test-phase PHASE=04)
	@if [ -z "$(PHASE)" ]; then \
		echo "$(RED)Usage: make test-phase PHASE=04$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Testing Phase $(PHASE) exercises...$(RESET)"
	@if [ -f "./$(PHASE)-*/lab.md" ]; then \
		cd $(shell find . -name "$(PHASE)-*" -type d | head -1) && \
		echo "Running Phase $(PHASE) tests..." && \
		if [ -f "scripts/test.sh" ]; then ./scripts/test.sh; else echo "$(YELLOW)No test script found$(RESET)"; fi; \
	else \
		echo "$(RED)Phase $(PHASE) not found$(RESET)"; \
		exit 1; \
	fi

build-images: ## Pre-build common images for faster exercises
	@echo "$(BLUE)Pre-building common images for faster exercises...$(RESET)"
	@echo "Pulling frequently used base images..."
	@docker pull ubuntu:20.04
	@docker pull alpine:latest
	@docker pull nginx:latest
	@docker pull node:18-alpine
	@docker pull python:3.11-slim
	@docker pull golang:1.21-alpine
	@echo "$(GREEN)✅ Common images cached$(RESET)"

lint: ## Check all Markdown files for common issues
	@echo "$(BLUE)Linting learning path content...$(RESET)"
	@./scripts/lint-content.sh

check-links: ## Verify all internal links work correctly
	@echo "$(BLUE)Checking internal links...$(RESET)"
	@./scripts/check-links.sh

quick-start: ## Quick start guide for new learners
	@echo "$(BLUE)Docker Learning Path - Quick Start$(RESET)"
	@echo "=================================="
	@echo ""
	@echo "$(GREEN)1. Verify your setup:$(RESET)"
	@echo "   make setup"
	@echo ""
	@echo "$(GREEN)2. Check your progress:$(RESET)"
	@echo "   make progress"
	@echo ""
	@echo "$(GREEN)3. Start with Phase 00:$(RESET)"
	@echo "   cd 00-foundations && cat README.md"
	@echo ""
	@echo "$(GREEN)4. After each phase:$(RESET)"
	@echo "   make verify-phase PHASE=00"
	@echo "   make clean-phase PHASE=00"
	@echo ""
	@echo "$(GREEN)5. Track progress:$(RESET)"
	@echo "   make next"
	@echo ""
	@echo "$(GREEN)6. Get help:$(RESET)"
	@echo "   cat docs/FAQ.md"
	@echo ""
	@echo "$(BLUE)Happy learning! 🐳$(RESET)"

# Advanced maintenance commands
update-progress: ## Update progress tracking from completed anchors
	@echo "$(BLUE)Updating progress tracking...$(RESET)"
	@./scripts/update-progress.sh

generate-report: ## Generate learning progress report
	@echo "$(BLUE)Generating progress report...$(RESET)"
	@./scripts/generate-report.sh > learning-report.md
	@echo "$(GREEN)✅ Report saved to learning-report.md$(RESET)"

backup-progress: ## Backup current progress and configurations
	@echo "$(BLUE)Backing up learning progress...$(RESET)"
	@mkdir -p backups
	@cp docs/PROGRESS.json backups/progress-$(shell date +%Y%m%d-%H%M%S).json
	@echo "$(GREEN)✅ Progress backed up to backups/$(RESET)"

# Development and maintenance commands
dev-setup: ## Setup development environment for contributors
	@echo "$(BLUE)Setting up development environment...$(RESET)"
	@npm install -g markdownlint-cli
	@pip install pre-commit
	@pre-commit install
	@echo "$(GREEN)✅ Development tools installed$(RESET)"

validate-structure: ## Validate repository structure against requirements
	@echo "$(BLUE)Validating repository structure...$(RESET)"
	@./scripts/validate-structure.sh

# Platform-specific helpers
windows-setup: ## Windows/WSL2-specific setup instructions
	@echo "$(BLUE)Windows/WSL2 Setup Instructions$(RESET)"
	@echo "================================"
	@echo ""
	@echo "$(GREEN)1. Enable WSL2:$(RESET)"
	@echo "   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
	@echo "   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
	@echo ""
	@echo "$(GREEN)2. Install Ubuntu:$(RESET)"
	@echo "   wsl --install -d Ubuntu"
	@echo ""
	@echo "$(GREEN)3. Configure Docker Desktop:$(RESET)"
	@echo "   Enable WSL2 integration in Docker Desktop settings"
	@echo ""
	@echo "$(GREEN)4. Set line endings:$(RESET)"
	@echo "   git config --global core.autocrlf input"
	@echo ""
	@echo "$(GREEN)5. Continue with:$(RESET)"
	@echo "   make setup"

macos-setup: ## macOS-specific setup instructions
	@echo "$(BLUE)macOS Setup Instructions$(RESET)"
	@echo "========================="
	@echo ""
	@echo "$(GREEN)1. Install Docker Desktop for Mac$(RESET)"
	@echo ""
	@echo "$(GREEN)2. Allocate resources:$(RESET)"
	@echo "   - Recommended: 4+ CPU cores, 8GB+ RAM"
	@echo "   - Docker Desktop > Preferences > Resources"
	@echo ""
	@echo "$(GREEN)3. Enable file sharing:$(RESET)"
	@echo "   - Add your project directory to file sharing"
	@echo ""
	@echo "$(GREEN)4. Continue with:$(RESET)"
	@echo "   make setup"

# Emergency commands
emergency-reset: ## Emergency reset - remove all Docker data (DESTRUCTIVE)
	@echo "$(RED)⚠️  EMERGENCY RESET - This will remove ALL Docker data!$(RESET)"
	@echo "$(RED)This includes all containers, images, volumes, and networks$(RESET)"
	@echo "$(YELLOW)Type 'CONFIRM' to proceed:$(RESET)"; \
	read -r response; \
	if [ "$$response" = "CONFIRM" ]; then \
		echo "$(RED)Performing emergency reset...$(RESET)"; \
		docker system prune -a -f --volumes; \
		docker builder prune -a -f; \
		echo "$(GREEN)✅ Emergency reset complete$(RESET)"; \
	else \
		echo "$(GREEN)Reset cancelled$(RESET)"; \
	fi

troubleshoot: ## Show troubleshooting information and common solutions
	@echo "$(BLUE)Docker Learning Path Troubleshooting$(RESET)"
	@echo "===================================="
	@echo ""
	@echo "$(GREEN)1. Check Docker status:$(RESET)"
	@echo "   make status"
	@echo ""
	@echo "$(GREEN)2. Verify specific phase:$(RESET)"
	@echo "   make verify-phase PHASE=XX"
	@echo ""
	@echo "$(GREEN)3. Clean up resources:$(RESET)"
	@echo "   make clean-safe"
	@echo ""
	@echo "$(GREEN)4. Platform-specific help:$(RESET)"
	@echo "   cat docs/platform-notes.md"
	@echo ""
	@echo "$(GREEN)5. Check FAQ:$(RESET)"
	@echo "   cat docs/FAQ.md"
	@echo ""
	@echo "$(GREEN)6. Emergency reset (if needed):$(RESET)"
	@echo "   make emergency-reset"

# Information commands
info: ## Show detailed information about the learning path
	@echo "$(BLUE)Docker Learning Path Information$(RESET)"
	@echo "================================="
	@echo ""
	@echo "$(GREEN)Repository Structure:$(RESET)"
	@find . -type d -name "[0-9][0-9]-*" | sort | sed 's/^/  /'
	@echo ""
	@echo "$(GREEN)Documentation:$(RESET)"
	@ls -la docs/ | grep -E "\.(md|json)$$" | awk '{print "  " $$9}' | sort
	@echo ""
	@echo "$(GREEN)Total Phases:$(RESET) $(shell find . -type d -name "[0-9][0-9]-*" | wc -l)"
	@echo "$(GREEN)Learning Time:$(RESET) ~30-40 hours"
	@echo "$(GREEN)Skill Level:$(RESET) Beginner to Advanced"

version: ## Show version information
	@echo "$(BLUE)Docker Learning Path Version$(RESET)"
	@echo "============================"
	@if [ -f "docs/PROGRESS.json" ]; then \
		cat docs/PROGRESS.json | grep -E '"version"|"last_updated"' | sed 's/^/  /'; \
	else \
		echo "  Version: 1.0.0"; \
		echo "  Status: Development"; \
	fi
	@echo ""
	@echo "$(GREEN)Docker Environment:$(RESET)"
	@docker --version | sed 's/^/  /'
	@docker compose version | sed 's/^/  /'