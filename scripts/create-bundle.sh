#!/bin/bash

# create-bundle.sh
# Creates a macOS .app bundle from the SPM-built executable
#
# Usage: ./scripts/create-bundle.sh [configuration]
#   configuration: debug or release (default: release)

set -euo pipefail

# Configuration
APP_NAME="ClaudeApp"
BUNDLE_ID="com.claudeapp.ClaudeApp"
CONFIG="${1:-release}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/.build"
RELEASE_DIR="$PROJECT_ROOT/release"
RESOURCES_DIR="$PROJECT_ROOT/Resources"

# Binary path based on configuration
if [[ "$CONFIG" == "debug" ]]; then
    BINARY_PATH="$BUILD_DIR/debug/$APP_NAME"
else
    BINARY_PATH="$BUILD_DIR/release/$APP_NAME"
fi

# App bundle paths
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
BUNDLE_RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Creating $APP_NAME.app bundle (${CONFIG})...${NC}"

# Check that binary exists
if [[ ! -f "$BINARY_PATH" ]]; then
    echo -e "${RED}Error: Binary not found at $BINARY_PATH${NC}"
    echo -e "${YELLOW}Run 'swift build --configuration $CONFIG' first${NC}"
    exit 1
fi

# Check that Info.plist exists
if [[ ! -f "$RESOURCES_DIR/Info.plist" ]]; then
    echo -e "${RED}Error: Info.plist not found at $RESOURCES_DIR/Info.plist${NC}"
    exit 1
fi

# Clean up any existing bundle
if [[ -d "$APP_BUNDLE" ]]; then
    echo "Removing existing bundle..."
    rm -rf "$APP_BUNDLE"
fi

# Create bundle directory structure
echo "Creating bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$BUNDLE_RESOURCES_DIR"

# Copy binary
echo "Copying binary..."
cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
echo "Copying Info.plist..."
cp "$RESOURCES_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy app icon if it exists
if [[ -f "$RESOURCES_DIR/AppIcon.icns" ]]; then
    echo "Copying app icon..."
    cp "$RESOURCES_DIR/AppIcon.icns" "$BUNDLE_RESOURCES_DIR/AppIcon.icns"
else
    echo -e "${YELLOW}Warning: AppIcon.icns not found, skipping icon${NC}"
fi

# Create PkgInfo
echo "Creating PkgInfo..."
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Verify bundle structure
echo ""
echo -e "${CYAN}Bundle structure:${NC}"
find "$APP_BUNDLE" -type f | sed "s|$RELEASE_DIR/||g" | sort

# Verify binary is valid
echo ""
echo -e "${CYAN}Binary info:${NC}"
file "$MACOS_DIR/$APP_NAME"

# Check that bundle can be opened
echo ""
if /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -lint "$APP_BUNDLE" &>/dev/null; then
    echo -e "${GREEN}Bundle validated successfully!${NC}"
else
    echo -e "${YELLOW}Warning: Could not validate bundle with lsregister${NC}"
fi

echo ""
echo -e "${GREEN}App bundle created: $APP_BUNDLE${NC}"
echo ""
echo "To test the app:"
echo "  open $APP_BUNDLE"
