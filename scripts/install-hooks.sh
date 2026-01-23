#!/bin/bash

# install-hooks.sh
# Installs git pre-commit hooks for code quality enforcement
#
# Usage: ./scripts/install-hooks.sh

set -euo pipefail

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Installing git hooks...${NC}"

# Check that .git directory exists
if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook for ClaudeApp
# Runs SwiftFormat and SwiftLint on staged Swift files

set -e

echo "Running pre-commit checks..."

# Get list of staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' || true)

if [[ -z "$STAGED_FILES" ]]; then
    echo "No Swift files staged, skipping checks."
    exit 0
fi

# Run SwiftFormat on staged files
if command -v swiftformat &> /dev/null; then
    echo "Formatting staged Swift files..."
    echo "$STAGED_FILES" | while read -r file; do
        if [[ -f "$file" ]]; then
            swiftformat "$file" --config .swiftformat 2>/dev/null || true
            git add "$file"
        fi
    done
else
    echo "SwiftFormat not installed, skipping formatting."
fi

# Run SwiftLint on staged files
if command -v swiftlint &> /dev/null; then
    echo "Linting staged Swift files..."
    LINT_RESULT=0
    echo "$STAGED_FILES" | while read -r file; do
        if [[ -f "$file" ]]; then
            if ! swiftlint lint --config .swiftlint.yml --quiet "$file"; then
                LINT_RESULT=1
            fi
        fi
    done

    if [[ "$LINT_RESULT" -ne 0 ]]; then
        echo ""
        echo "SwiftLint found issues. Please fix them before committing."
        echo "Run 'make lint-fix' to auto-fix some issues."
        exit 1
    fi
else
    echo "SwiftLint not installed, skipping linting."
fi

echo "Pre-commit checks passed!"
EOF

# Make hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo -e "${GREEN}Git hooks installed successfully!${NC}"
echo ""
echo "Installed hooks:"
echo "  - pre-commit: Runs SwiftFormat and SwiftLint on staged Swift files"
echo ""
echo "To uninstall hooks, remove: $HOOKS_DIR/pre-commit"
