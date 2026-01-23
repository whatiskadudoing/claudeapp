# ClaudeApp

> A macOS menu bar app for monitoring Claude Code usage limits

A native macOS menu bar application that helps Claude Code users track their API usage in real-time, predict when limits will be reached, and stay informed with configurable notifications.

## Features

- **Real-time Usage Monitoring** - See your current usage percentage at a glance in the menu bar
- **Detailed Breakdown** - View 5-hour session, 7-day limits, and per-model quotas (Opus/Sonnet)
- **Burn Rate Indicator** - Know if you're consuming quota at Low/Medium/High/Very High velocity
- **Time-to-Exhaustion** - Predict when you'll hit your limit based on current consumption rate
- **Configurable Notifications** - Get warnings at custom thresholds (default 90%)
- **Auto-Refresh** - Background polling with configurable intervals (1-30 min)
- **Update Checking** - Automatic checks for new versions via GitHub Releases
- **Launch at Login** - Native SMAppService integration
- **Dark Mode Support** - Follows system appearance

## Requirements

- macOS 14 (Sonoma) or later
- [Claude Code CLI](https://claude.ai/code) installed and authenticated

## Installation

### Manual Download

1. Download the latest release from [Releases](https://github.com/kaduwaengertner/claudeapp/releases)
2. Open the DMG and drag ClaudeApp to Applications
3. On first launch, right-click and select "Open" to bypass Gatekeeper

### Build from Source

```bash
# Clone the repository
git clone https://github.com/kaduwaengertner/claudeapp.git
cd claudeapp

# Build and run
make build
make run

# Or install to /Applications
make install
```

## Quick Start

1. Install ClaudeApp
2. Ensure you're logged in to Claude Code (`claude login`)
3. ClaudeApp appears in your menu bar with usage percentage
4. Click to see detailed breakdown with burn rate and time-to-exhaustion

## Architecture

ClaudeApp uses a modular package architecture inspired by Domain-Driven Design:

```
ClaudeApp/
├── App/                    # Main app target
├── Packages/
│   ├── Domain/             # Models, protocols (zero deps)
│   ├── Services/           # API client, Keychain
│   ├── Core/               # Business logic, managers
│   └── UI/                 # SwiftUI components
```

See [specs/](specs/) for detailed specifications.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| State Management | @Observable / Observation |
| Concurrency | Swift Concurrency (async/await, actors) |
| Build System | Swift Package Manager + Makefile |

## Development

```bash
make help          # Show all commands
make build         # Build debug version
make test          # Run all tests
make run           # Build and run
make dev           # Open in Xcode
```

## Privacy

ClaudeApp reads your Claude Code OAuth credentials locally from the macOS Keychain to fetch usage data from the Anthropic API. No data is sent to third parties. All data stays on your device.

## License

MIT License - see [LICENSE](LICENSE)

## Acknowledgments

- [Claude](https://claude.ai) by Anthropic
- Built with Swift and SwiftUI
