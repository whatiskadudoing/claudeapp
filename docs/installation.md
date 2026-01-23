# Installation Guide

## System Requirements

| Requirement | Minimum |
|-------------|---------|
| macOS | 14.0 (Sonoma) |
| Claude Code | Installed & authenticated |
| Storage | ~15 MB |

## Installation Methods

### 1. Homebrew (Coming Soon)

```bash
# Add the tap
brew tap kaduwaengertner/tap

# Install ClaudeApp
brew install --cask claudeapp
```

To update:
```bash
brew upgrade --cask claudeapp
```

To uninstall:
```bash
brew uninstall --cask claudeapp
```

### 2. Direct Download

1. Go to [Releases](https://github.com/kaduwaengertner/claudeapp/releases/latest)
2. Download `ClaudeApp.dmg` from the latest release
3. Open the DMG file
4. Drag ClaudeApp to your Applications folder

#### Bypassing Gatekeeper

Since ClaudeApp is not signed with an Apple Developer ID, macOS will block it on first launch:

**Option A: Right-Click Method**
1. Right-click (or Control-click) the app in Applications
2. Select "Open" from the context menu
3. Click "Open" in the dialog that appears

**Option B: System Settings Method**
1. Try to open the app normally (it will be blocked)
2. Open **System Settings** > **Privacy & Security**
3. Scroll down to the Security section
4. Click "Open Anyway" next to the ClaudeApp message
5. Click "Open" in the confirmation dialog

### 3. Build from Source

```bash
# Clone the repository
git clone https://github.com/kaduwaengertner/claudeapp.git
cd claudeapp

# Build and run
make build
make run

# Or install to /Applications
make release
make install
```

#### Build Requirements

- Xcode 15.0+ (includes Swift 5.9+)
- Command Line Tools (`xcode-select --install`)

## Post-Installation Setup

### 1. Authenticate Claude Code

ClaudeApp requires Claude Code CLI to be installed and authenticated. If you haven't already:

```bash
# Install Claude Code (if needed)
# Follow instructions at https://claude.ai/code

# Log in to Claude Code
claude login
```

Follow the prompts to complete authentication. This stores OAuth credentials in your macOS Keychain that ClaudeApp reads to fetch usage data.

### 2. Launch ClaudeApp

1. Find ClaudeApp in your Applications folder
2. Double-click to launch (or use right-click > Open on first launch)
3. The Claude icon appears in your menu bar with your current usage percentage

### 3. Configure (Optional)

Click the menu bar icon, then click the Settings button (gear icon) to:

- **Display**: Toggle percentage display, plan badge, choose which metric to show
- **Refresh**: Set auto-refresh interval (1-30 minutes, default 5 minutes)
- **Notifications**: Enable warnings at custom thresholds (default 90%)
- **General**: Enable Launch at Login, automatic update checking

## Verifying Installation

1. Click the ClaudeApp icon in your menu bar
2. You should see your current usage percentages for:
   - Current Session (5-hour window)
   - Weekly (All Models)
   - Weekly (Opus) - if applicable
   - Weekly (Sonnet) - if applicable
3. If you see "Claude Code not found", ensure Claude Code is installed and run `claude login`

## Uninstalling

### If Installed via DMG

1. Quit ClaudeApp (click menu bar icon > Quit)
2. Delete ClaudeApp from Applications folder
3. Optionally, remove preferences:
   ```bash
   rm ~/Library/Preferences/com.kaduwaengertner.ClaudeApp.plist
   ```

### If Installed via Homebrew

```bash
brew uninstall --cask claudeapp
```

### If Built from Source

```bash
make uninstall
```

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for solutions to common installation issues.
