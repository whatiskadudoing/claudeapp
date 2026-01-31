#!/bin/bash
#
# ClaudeApp Installer
#
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/whatiskadudoing/claudeapp/main/scripts/install.sh | bash
#
# With specific version:
#   curl -fsSL https://raw.githubusercontent.com/whatiskadudoing/claudeapp/main/scripts/install.sh | bash -s -- v2.0.1
#

set -e

# Configuration
REPO="whatiskadudoing/claudeapp"
APP_NAME="ClaudeApp"
INSTALL_DIR="/Applications"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check macOS
check_os() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "ClaudeApp only supports macOS"
        exit 1
    fi
    print_info "macOS detected: $(sw_vers -productVersion)"
}

# Get latest version from GitHub
get_latest_version() {
    curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | \
        grep '"tag_name"' | \
        sed -E 's/.*"([^"]+)".*/\1/'
}

# Download and install
install_app() {
    local version="$1"
    local download_url="https://github.com/$REPO/releases/download/$version/ClaudeApp.dmg"
    local tmp_dir=$(mktemp -d)
    local dmg_path="$tmp_dir/ClaudeApp.dmg"
    local mount_point="$tmp_dir/mount"

    print_step "Downloading ClaudeApp $version..."
    if ! curl -fsSL -o "$dmg_path" "$download_url"; then
        print_error "Failed to download from: $download_url"
        print_error "Make sure version $version exists at: https://github.com/$REPO/releases"
        rm -rf "$tmp_dir"
        exit 1
    fi

    print_step "Mounting DMG..."
    mkdir -p "$mount_point"
    hdiutil attach "$dmg_path" -mountpoint "$mount_point" -quiet

    print_step "Installing to $INSTALL_DIR..."
    # Remove old version if exists
    if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
        print_warn "Removing existing installation..."
        rm -rf "$INSTALL_DIR/$APP_NAME.app"
    fi

    cp -R "$mount_point/$APP_NAME.app" "$INSTALL_DIR/"

    print_step "Cleaning up..."
    hdiutil detach "$mount_point" -quiet
    rm -rf "$tmp_dir"

    # Remove quarantine attribute
    xattr -rd com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

    print_info "Installation complete!"
}

# Verify installation
verify_installation() {
    local app_path="$INSTALL_DIR/$APP_NAME.app"

    if [ -d "$app_path" ]; then
        print_info "ClaudeApp installed at: $app_path"

        # Get version from Info.plist if available
        local version=$(defaults read "$app_path/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
        print_info "Version: $version"

        echo ""
        echo "To launch ClaudeApp:"
        echo "  open -a ClaudeApp"
        echo ""
        echo "Or find it in your Applications folder."
        echo ""
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Print banner
print_banner() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║        ClaudeApp Installer            ║"
    echo "║   Anthropic API Usage Monitor         ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
}

# Main
main() {
    print_banner

    check_os

    local version="${1:-}"

    if [ -z "$version" ]; then
        print_step "Fetching latest version..."
        version=$(get_latest_version)
        if [ -z "$version" ]; then
            print_error "Could not determine latest version"
            print_error "Please specify a version: bash install.sh v2.0.1"
            exit 1
        fi
    fi

    print_info "Installing version: $version"
    echo ""

    install_app "$version"
    verify_installation

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Installation successful!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
