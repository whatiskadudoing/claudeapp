# ClaudeApp Makefile
# Modern Swift development toolchain

.PHONY: help build run test clean release format lint check watch install uninstall dmg

# Configuration
APP_NAME := ClaudeApp
BUNDLE_ID := com.claudeapp.ClaudeApp
BUILD_DIR := .build
RELEASE_DIR := release
DERIVED_DATA := $(BUILD_DIR)/DerivedData

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)ClaudeApp Development Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

# ============================================================================
# Building
# ============================================================================

build: ## Build debug version
	@echo "$(CYAN)Building debug...$(NC)"
	@swift build --configuration debug 2>&1 | xcbeautify || swift build --configuration debug

build-release: ## Build release version (optimized)
	@echo "$(CYAN)Building release...$(NC)"
	@swift build --configuration release 2>&1 | xcbeautify || swift build --configuration release

run: build ## Build and run the app
	@echo "$(CYAN)Running $(APP_NAME)...$(NC)"
	@$(BUILD_DIR)/debug/$(APP_NAME)

# ============================================================================
# Testing
# ============================================================================

test: ## Run all tests
	@echo "$(CYAN)Running tests...$(NC)"
	@swift test 2>&1 | xcbeautify || swift test

test-verbose: ## Run tests with verbose output
	@echo "$(CYAN)Running tests (verbose)...$(NC)"
	@swift test --verbose

test-domain: ## Run Domain package tests only
	@swift test --filter DomainTests

test-services: ## Run Services package tests only
	@swift test --filter ServicesTests

test-core: ## Run Core package tests only
	@swift test --filter CoreTests

test-ui: ## Run UI package tests only
	@swift test --filter UITests

# ============================================================================
# Code Quality
# ============================================================================

format: ## Format code with SwiftFormat
	@echo "$(CYAN)Formatting code...$(NC)"
	@if command -v swiftformat &> /dev/null; then \
		swiftformat . --config .swiftformat; \
		echo "$(GREEN)Formatting complete$(NC)"; \
	else \
		echo "$(YELLOW)SwiftFormat not installed. Run: brew install swiftformat$(NC)"; \
	fi

lint: ## Lint code with SwiftLint
	@echo "$(CYAN)Linting code...$(NC)"
	@if command -v swiftlint &> /dev/null; then \
		swiftlint lint --config .swiftlint.yml; \
	else \
		echo "$(YELLOW)SwiftLint not installed. Run: brew install swiftlint$(NC)"; \
	fi

lint-fix: ## Auto-fix linting issues
	@echo "$(CYAN)Auto-fixing lint issues...$(NC)"
	@swiftlint lint --fix --config .swiftlint.yml

check: format lint test ## Run all checks (CI gate)
	@echo "$(GREEN)All checks passed!$(NC)"

# ============================================================================
# Development
# ============================================================================

watch: ## Hot reload development mode
	@echo "$(CYAN)Starting hot reload mode...$(NC)"
	@echo "$(YELLOW)Watching for changes... Press Ctrl+C to stop$(NC)"
	@fswatch -o App/ Packages/ | xargs -n1 -I{} make build run

dev: ## Open in Xcode
	@echo "$(CYAN)Opening in Xcode...$(NC)"
	@open Package.swift

# ============================================================================
# Cleaning
# ============================================================================

clean: ## Clean build artifacts
	@echo "$(CYAN)Cleaning...$(NC)"
	@swift package clean
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DERIVED_DATA)
	@rm -rf $(RELEASE_DIR)
	@echo "$(GREEN)Clean complete$(NC)"

reset: clean ## Full reset (clean + resolve dependencies)
	@echo "$(CYAN)Resetting package dependencies...$(NC)"
	@swift package reset
	@swift package resolve
	@echo "$(GREEN)Reset complete$(NC)"

# ============================================================================
# Release
# ============================================================================

release: build-release ## Build release and create app bundle
	@echo "$(CYAN)Creating release...$(NC)"
	@mkdir -p $(RELEASE_DIR)
	@cp -R $(BUILD_DIR)/release/$(APP_NAME).app $(RELEASE_DIR)/ 2>/dev/null || cp $(BUILD_DIR)/release/$(APP_NAME) $(RELEASE_DIR)/
	@echo "$(GREEN)Release created at $(RELEASE_DIR)/$(NC)"

dmg: release ## Create distributable DMG
	@echo "$(CYAN)Creating DMG...$(NC)"
	@./scripts/create-dmg.sh
	@echo "$(GREEN)DMG created at $(RELEASE_DIR)/$(APP_NAME).dmg$(NC)"

archive: release ## Create ZIP archive for GitHub release
	@echo "$(CYAN)Creating archive...$(NC)"
	@cd $(RELEASE_DIR) && zip -r $(APP_NAME).zip $(APP_NAME).app 2>/dev/null || zip -r $(APP_NAME).zip $(APP_NAME)
	@echo "$(GREEN)Archive created at $(RELEASE_DIR)/$(APP_NAME).zip$(NC)"

# ============================================================================
# Installation
# ============================================================================

install: release ## Install to /Applications
	@echo "$(CYAN)Installing to /Applications...$(NC)"
	@cp -R $(RELEASE_DIR)/$(APP_NAME).app /Applications/ 2>/dev/null || echo "$(YELLOW)No .app bundle to install$(NC)"
	@echo "$(GREEN)Installed to /Applications/$(APP_NAME).app$(NC)"

uninstall: ## Remove from /Applications
	@echo "$(CYAN)Uninstalling...$(NC)"
	@rm -rf /Applications/$(APP_NAME).app
	@echo "$(GREEN)Uninstalled$(NC)"

# ============================================================================
# Dependencies
# ============================================================================

deps: ## Resolve package dependencies
	@echo "$(CYAN)Resolving dependencies...$(NC)"
	@swift package resolve

deps-update: ## Update package dependencies
	@echo "$(CYAN)Updating dependencies...$(NC)"
	@swift package update

# ============================================================================
# Setup
# ============================================================================

setup: ## Initial project setup
	@echo "$(CYAN)Setting up project...$(NC)"
	@if [ -f ./scripts/install-hooks.sh ]; then ./scripts/install-hooks.sh; fi
	@make deps
	@echo "$(GREEN)Setup complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  make build  - Build the project"
	@echo "  make run    - Run the app"
	@echo "  make dev    - Open in Xcode"
