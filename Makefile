# Docker Learning Path - Makefile
# Common operations for managing the curriculum

.PHONY: help clean verify progress setup check-docker

# Default target
help:
	@echo "Docker Learning Path - Available Commands:"
	@echo ""
	@echo "  make setup         - Initial setup and dependency check"
	@echo "  make check-docker  - Verify Docker installation"
	@echo "  make progress      - Show learning progress"
	@echo "  make clean         - Clean up Docker resources"
	@echo "  make verify        - Run verification tests"
	@echo "  make phase-XX      - Jump to specific phase (00-11)"
	@echo ""
	@echo "Examples:"
	@echo "  make phase-00      - Start with foundations"
	@echo "  make progress      - Check your progress"
	@echo "  make clean         - Clean up all containers/images"

# Initial setup
setup: check-docker
	@echo "✅ Docker is installed and running"
	@echo "📚 Repository structure is ready"
	@echo "🚀 You can start with: make phase-00"

# Check Docker installation
check-docker:
	@echo "Checking Docker installation..."
	@docker --version > /dev/null 2>&1 || (echo "❌ Docker is not installed" && exit 1)
	@docker ps > /dev/null 2>&1 || (echo "❌ Docker daemon is not running" && exit 1)
	@echo "✅ Docker is installed and running"
	@docker --version

# Show progress
progress:
	@echo "📊 Learning Progress:"
	@echo ""
	@if [ -f docs/PROGRESS.json ]; then \
		completed=$$(grep -c '"status": "completed"' docs/PROGRESS.json); \
		total=$$(grep -c '"status":' docs/PROGRESS.json); \
		percent=$$(( $$completed * 100 / $$total )); \
		echo "  Completed: $$completed/$$total lessons ($$percent%)"; \
		echo ""; \
		echo "Phase Status:"; \
		for i in 00 01 02 03 04 05 06 07 08 09 10 11; do \
			if [ -d "$$i-"* ]; then \
				phase_name=$$(ls -d $$i-* | head -1); \
				phase_complete=$$(grep -A5 "\"phase\": \"$$i\"" docs/PROGRESS.json | grep -c '"status": "completed"' || echo 0); \
				phase_total=$$(grep -A5 "\"phase\": \"$$i\"" docs/PROGRESS.json | grep -c '"status":' || echo 0); \
				if [ $$phase_total -gt 0 ]; then \
					if [ $$phase_complete -eq $$phase_total ]; then \
						echo "  ✅ Phase $$i - $$phase_name"; \
					elif [ $$phase_complete -gt 0 ]; then \
						echo "  🔄 Phase $$i - $$phase_name ($$phase_complete/$$phase_total)"; \
					else \
						echo "  ⭕ Phase $$i - $$phase_name"; \
					fi \
				fi \
			fi \
		done \
	else \
		echo "Progress file not found. Run 'make setup' first."; \
	fi

# Clean up Docker resources
clean:
	@echo "🧹 Cleaning up Docker resources..."
	@echo "This will remove:"
	@echo "  - All stopped containers"
	@echo "  - All dangling images"
	@echo "  - All unused networks"
	@echo ""
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker container prune -f
	@docker image prune -f
	@docker network prune -f
	@echo "✅ Cleanup complete"

# Deep clean (removes ALL Docker resources)
clean-all:
	@echo "⚠️  WARNING: This will remove ALL Docker resources!"
	@echo "This includes:"
	@echo "  - ALL containers (running and stopped)"
	@echo "  - ALL images"
	@echo "  - ALL volumes"
	@echo "  - ALL networks"
	@echo ""
	@read -p "Are you SURE? Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@docker system prune -a --volumes -f
	@echo "✅ Deep cleanup complete"

# Verify current phase
verify:
	@echo "Running verification tests..."
	@if [ -f verify.sh ]; then \
		bash verify.sh; \
	else \
		echo "No verification script found in current directory"; \
	fi

# Phase targets
phase-00:
	@echo "📚 Phase 00: Foundations"
	@echo "Topics: Images vs Containers, Lifecycle, Resource Mapping"
	@if [ -d "00-foundations" ]; then \
		cd 00-foundations && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 00-foundations; \
	fi

phase-01:
	@echo "📚 Phase 01: Dockerfile Basics"
	@echo "Topics: Directives, Caching, Context Management"
	@if [ -d "01-dockerfile-basics" ]; then \
		cd 01-dockerfile-basics && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 01-dockerfile-basics; \
	fi

phase-02:
	@echo "📚 Phase 02: BuildKit Advanced"
	@echo "Topics: Multi-stage, Cache Mounts, Secrets"
	@if [ -d "02-buildkit-advanced" ]; then \
		cd 02-buildkit-advanced && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 02-buildkit-advanced; \
	fi

phase-03:
	@echo "📚 Phase 03: Container Operations"
	@echo "Topics: Health Checks, Restart Policies, Resource Limits"
	@if [ -d "03-container-ops" ]; then \
		cd 03-container-ops && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 03-container-ops; \
	fi

phase-04:
	@echo "📚 Phase 04: Networking"
	@echo "Topics: Network Types, Service Discovery, Isolation"
	@if [ -d "04-networking" ]; then \
		cd 04-networking && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 04-networking; \
	fi

phase-05:
	@echo "📚 Phase 05: Storage & Volumes"
	@echo "Topics: Volume Types, Backup/Restore, Permissions"
	@if [ -d "05-storage-volumes" ]; then \
		cd 05-storage-volumes && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 05-storage-volumes; \
	fi

phase-06:
	@echo "📚 Phase 06: Compose"
	@echo "Topics: Multi-container, Profiles, Dependencies"
	@if [ -d "06-compose" ]; then \
		cd 06-compose && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 06-compose; \
	fi

phase-07:
	@echo "📚 Phase 07: Security"
	@echo "Topics: Non-root, Capabilities, Scanning"
	@if [ -d "07-security" ]; then \
		cd 07-security && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 07-security; \
	fi

phase-08:
	@echo "📚 Phase 08: CI/CD & Buildx"
	@echo "Topics: Multi-arch, Cache, SBOM"
	@if [ -d "08-ci-cd-buildx" ]; then \
		cd 08-ci-cd-buildx && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 08-ci-cd-buildx; \
	fi

phase-09:
	@echo "📚 Phase 09: Registries"
	@echo "Topics: Local Registry, Mirroring, Auth"
	@if [ -d "09-registries" ]; then \
		cd 09-registries && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 09-registries; \
	fi

phase-10:
	@echo "📚 Phase 10: Observability"
	@echo "Topics: Logging, Metrics, Analysis"
	@if [ -d "10-observability" ]; then \
		cd 10-observability && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 10-observability; \
	fi

phase-11:
	@echo "📚 Phase 11: Advanced Images"
	@echo "Topics: Distroless, Static Linking, Debug"
	@if [ -d "11-advanced-images" ]; then \
		cd 11-advanced-images && ls -la; \
	else \
		echo "Phase directory not found. Creating..."; \
		mkdir -p 11-advanced-images; \
	fi

# Quick status check
status: progress

# Update progress for a specific lesson
mark-complete:
	@echo "To mark a lesson complete, edit docs/PROGRESS.json"
	@echo "Change the lesson status from 'pending' to 'completed'"

# List all phases
list-phases:
	@echo "Available Phases:"
	@echo ""
	@echo "  00 - Foundations"
	@echo "  01 - Dockerfile Basics"
	@echo "  02 - BuildKit Advanced"
	@echo "  03 - Container Operations"
	@echo "  04 - Networking"
	@echo "  05 - Storage & Volumes"
	@echo "  06 - Compose"
	@echo "  07 - Security"
	@echo "  08 - CI/CD & Buildx"
	@echo "  09 - Registries"
	@echo "  10 - Observability"
	@echo "  11 - Advanced Images"