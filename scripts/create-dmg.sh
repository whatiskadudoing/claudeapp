#!/bin/bash

# create-dmg.sh
# Creates a distributable DMG with Applications symlink
#
# Usage: ./scripts/create-dmg.sh

set -euo pipefail

# Configuration
APP_NAME="ClaudeApp"
VERSION="${VERSION:-1.3.0}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="$PROJECT_ROOT/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Creating $DMG_NAME...${NC}"

# Check that app bundle exists
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo -e "${RED}Error: App bundle not found at $APP_BUNDLE${NC}"
    echo -e "${YELLOW}Run 'make release' first${NC}"
    exit 1
fi

# Create temporary DMG directory
DMG_DIR=$(mktemp -d)
trap 'rm -rf "$DMG_DIR"' EXIT

echo "Setting up DMG contents..."

# Copy app bundle to temporary directory
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create symlink to Applications folder
ln -s /Applications "$DMG_DIR/Applications"

# Remove any existing DMG
if [[ -f "$RELEASE_DIR/$DMG_NAME" ]]; then
    echo "Removing existing DMG..."
    rm -f "$RELEASE_DIR/$DMG_NAME"
fi

# Create the DMG
echo "Creating DMG image..."
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$RELEASE_DIR/$DMG_NAME"

# Verify DMG was created
if [[ -f "$RELEASE_DIR/$DMG_NAME" ]]; then
    echo ""
    echo -e "${GREEN}DMG created successfully: $RELEASE_DIR/$DMG_NAME${NC}"
    echo ""
    echo "DMG info:"
    ls -lh "$RELEASE_DIR/$DMG_NAME"
    echo ""
    echo "To test the DMG:"
    echo "  open $RELEASE_DIR/$DMG_NAME"
else
    echo -e "${RED}Error: Failed to create DMG${NC}"
    exit 1
fi
