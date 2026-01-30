#!/bin/bash
#
# ClaudeApp CLI Installation Script
#
# Creates a symlink for easier CLI access to ClaudeApp.
# Usage: ./scripts/install-cli.sh [install-dir]
#
# Default install location: /usr/local/bin
# Custom example: ./scripts/install-cli.sh ~/bin
#

set -e

# Configuration
APP_NAME="ClaudeApp"
BINARY_NAME="claudeapp"
APP_PATH="/Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp"
DEFAULT_INSTALL_DIR="/usr/local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print with color
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if ClaudeApp is installed
check_app_installed() {
    if [ ! -f "$APP_PATH" ]; then
        print_error "ClaudeApp not found at: $APP_PATH"
        echo ""
        echo "Please install ClaudeApp first:"
        echo "  1. Download from: https://github.com/kaduwaengertner/claudeapp/releases"
        echo "  2. Move ClaudeApp.app to /Applications/"
        echo ""
        exit 1
    fi
}

# Get install directory from argument or use default
get_install_dir() {
    local dir="${1:-$DEFAULT_INSTALL_DIR}"

    # Expand ~ to home directory
    dir="${dir/#\~/$HOME}"

    # Remove trailing slash
    dir="${dir%/}"

    echo "$dir"
}

# Check if directory exists and is writable
check_install_dir() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        print_warn "Directory does not exist: $dir"
        echo "Creating directory..."

        if [[ "$dir" == /usr/* || "$dir" == /opt/* ]]; then
            sudo mkdir -p "$dir"
        else
            mkdir -p "$dir"
        fi
    fi

    # Check if we need sudo
    if [ ! -w "$dir" ]; then
        return 1  # Need sudo
    fi

    return 0  # No sudo needed
}

# Create symlink
create_symlink() {
    local install_dir="$1"
    local symlink_path="$install_dir/$BINARY_NAME"

    # Remove existing symlink if present
    if [ -L "$symlink_path" ]; then
        print_info "Removing existing symlink..."
        if [ ! -w "$install_dir" ]; then
            sudo rm "$symlink_path"
        else
            rm "$symlink_path"
        fi
    elif [ -f "$symlink_path" ]; then
        print_error "A file already exists at: $symlink_path"
        echo "Please remove it manually and try again."
        exit 1
    fi

    # Create new symlink
    print_info "Creating symlink: $symlink_path -> $APP_PATH"
    if [ ! -w "$install_dir" ]; then
        sudo ln -sf "$APP_PATH" "$symlink_path"
    else
        ln -sf "$APP_PATH" "$symlink_path"
    fi
}

# Verify installation
verify_installation() {
    local install_dir="$1"
    local symlink_path="$install_dir/$BINARY_NAME"

    if [ -L "$symlink_path" ] && [ -x "$symlink_path" ]; then
        print_info "Installation successful!"
        echo ""

        # Check if directory is in PATH
        if [[ ":$PATH:" != *":$install_dir:"* ]]; then
            print_warn "Note: $install_dir is not in your PATH"
            echo ""
            echo "Add to your shell config (~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish):"
            echo ""
            echo "  export PATH=\"\$PATH:$install_dir\""
            echo ""
        fi

        echo "Usage:"
        echo "  $BINARY_NAME --status              # Check usage"
        echo "  $BINARY_NAME --status --format json # JSON output"
        echo "  $BINARY_NAME --help                # Show all options"
        echo ""
        echo "See docs/TERMINAL.md for shell integration examples."
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Print usage
print_usage() {
    echo "ClaudeApp CLI Installation Script"
    echo ""
    echo "Usage: $0 [install-dir]"
    echo ""
    echo "Arguments:"
    echo "  install-dir    Directory to install symlink (default: /usr/local/bin)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install to /usr/local/bin"
    echo "  $0 ~/bin              # Install to ~/bin"
    echo "  $0 /opt/local/bin     # Install to /opt/local/bin"
    echo ""
}

# Uninstall function
uninstall() {
    local install_dir="$1"
    local symlink_path="$install_dir/$BINARY_NAME"

    if [ -L "$symlink_path" ]; then
        print_info "Removing symlink: $symlink_path"
        if [ ! -w "$install_dir" ]; then
            sudo rm "$symlink_path"
        else
            rm "$symlink_path"
        fi
        print_info "Uninstallation complete"
    else
        print_warn "No symlink found at: $symlink_path"
    fi
}

# Main
main() {
    # Handle help flag
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        print_usage
        exit 0
    fi

    # Handle uninstall flag
    if [ "$1" = "--uninstall" ]; then
        local install_dir=$(get_install_dir "$2")
        uninstall "$install_dir"
        exit 0
    fi

    echo "==================================="
    echo "  ClaudeApp CLI Installation"
    echo "==================================="
    echo ""

    # Check if app is installed
    check_app_installed

    # Get install directory
    local install_dir=$(get_install_dir "$1")

    print_info "Install directory: $install_dir"

    # Check directory and permissions
    if ! check_install_dir "$install_dir"; then
        print_info "Administrator privileges required for $install_dir"
    fi

    # Create symlink
    create_symlink "$install_dir"

    # Verify
    verify_installation "$install_dir"
}

main "$@"
