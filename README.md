# ClaudeApp

[![CI](https://github.com/kaduwaengertner/claudeapp/actions/workflows/ci.yml/badge.svg)](https://github.com/kaduwaengertner/claudeapp/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/kaduwaengertner/claudeapp)](https://github.com/kaduwaengertner/claudeapp/releases/latest)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-blue.svg)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A macOS menu bar app for monitoring Claude Code usage limits

A native macOS menu bar application that helps Claude Code users track their API usage in real-time, predict when limits will be reached, and stay informed with configurable notifications.

## Features

- **Real-time Usage Monitoring** - See your current usage percentage at a glance in the menu bar
- **Detailed Breakdown** - View 5-hour session, 7-day limits, and per-model quotas (Opus/Sonnet)
- **Burn Rate Indicator** - Know if you're consuming quota at Low/Medium/High/Very High velocity
- **Time-to-Exhaustion** - Predict when you'll hit your limit based on current consumption rate
- **Premium Industrial Design** - Hybrid aesthetic inspired by McLaren F1, Teenage Engineering, and KOSMA
- **Configurable Notifications** - Get warnings at custom thresholds (default 90%)
- **Auto-Refresh** - Background polling with configurable intervals (1-30 min)
- **Power-Aware Refresh** - Intelligent refresh scheduling based on battery and power state
- **Update Checking** - Automatic checks for new versions via GitHub Releases
- **Launch at Login** - Native SMAppService integration
- **Dark Mode Support** - Technical dark-first design
- **Multi-Language Support** - Available in English, Portuguese (Brazil), and Spanish (Latin America)
- **Terminal Integration** - CLI for shell prompts, tmux, and scripts (NEW in v1.9.0)

## Terminal Integration

ClaudeApp includes a command-line interface for monitoring usage directly in your terminal:

```bash
# Install CLI symlink (one-time)
./scripts/install-cli.sh

# Check usage
claudeapp --status
# Output: 86% (5h: 45%, 7d: 72%)

# Minimal output (for prompts)
claudeapp --status --format minimal
# Output: 86%

# JSON output (for scripts)
claudeapp --status --format json

# Verbose with ASCII progress bars
claudeapp --status --format verbose
```

### Shell Prompt Examples

**Zsh:**
```zsh
# Add to ~/.zshrc
claude_usage() { claudeapp --status --format minimal 2>/dev/null || echo "--"; }
RPROMPT='[Claude: %F{yellow}$(claude_usage)%f]'
```

**Bash:**
```bash
# Add to ~/.bashrc
claude_usage() { claudeapp --status --format minimal 2>/dev/null || echo "--"; }
PS1='\u@\h:\w [Claude: $(claude_usage)] \$ '
```

**Starship:**
```toml
# Add to ~/.config/starship.toml
[custom.claude]
command = "claudeapp --status --format minimal"
when = "test -x /Applications/ClaudeApp.app/Contents/MacOS/ClaudeApp"
format = "[Claude: $output]($style) "
style = "yellow"
```

See [Terminal Integration Guide](docs/TERMINAL.md) for comprehensive documentation including tmux, Oh My Zsh plugin, and scripting examples.

## Accessibility

ClaudeApp is fully accessible and meets WCAG 2.1 AA compliance standards:

| Feature | Description |
|---------|-------------|
| **VoiceOver** | Full screen reader support with descriptive labels for all UI elements |
| **Keyboard Navigation** | Complete keyboard control with standard shortcuts (Cmd+R refresh, Cmd+Q quit) |
| **Dynamic Type** | Scales with system text size preferences, including Accessibility sizes |
| **Reduced Motion** | Respects system "Reduce Motion" setting - animations disabled when enabled |
| **Color-Blind Safe** | Patterns and shapes supplement color for status indicators |
| **High Contrast** | Enhanced borders and visual separation when "Increase Contrast" is enabled |

### Testing Accessibility

To test accessibility features on your Mac:

- **VoiceOver:** System Settings > Accessibility > VoiceOver (or press Cmd+F5)
- **Dynamic Type:** System Settings > Accessibility > Display > Text Size
- **Reduce Motion:** System Settings > Accessibility > Display > Reduce motion
- **Increase Contrast:** System Settings > Accessibility > Display > Increase contrast

See [specs/accessibility.md](specs/accessibility.md) for the complete accessibility specification.

## Supported Languages

ClaudeApp is fully localized in the following languages:

| Language | Code | Region |
|----------|------|--------|
| English | en | US/UK (default) |
| Portuguese | pt-BR | Brazil |
| Spanish | es | Latin America |

The app automatically uses your macOS system language. To manually test a specific language, see [Testing Localization](#testing-localization) below.

## Requirements

- macOS 14 (Sonoma) or later
- [Claude Code CLI](https://claude.ai/code) installed and authenticated

## Installation

### Homebrew (Coming Soon)

```bash
brew tap kaduwaengertner/tap
brew install --cask claudeapp
```

### Manual Download

1. Download the latest `.dmg` from [Releases](https://github.com/kaduwaengertner/claudeapp/releases/latest)
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

## Documentation

Comprehensive documentation is available in the [docs/](docs/) folder:

| Guide | Description |
|-------|-------------|
| [Installation Guide](docs/installation.md) | Detailed installation instructions for all methods |
| [Usage Guide](docs/usage.md) | Complete feature guide and how to use the app |
| [Terminal Integration](docs/TERMINAL.md) | CLI usage, shell prompts, tmux, and scripting |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |
| [FAQ](docs/faq.md) | Frequently asked questions |
| [Privacy Policy](docs/privacy.md) | Data handling and privacy information |

For technical specifications, see [specs/](specs/).

## Design System

ClaudeApp features a **premium industrial design** inspired by three world-class design systems:

| Source | Contribution |
|--------|--------------|
| **McLaren F1 Playbook** | Papaya orange `#FF7300`, precision animations `cubic-bezier(0.19, 1, 0.22, 1)` |
| **Teenage Engineering** | Light typography (300 weight), LED indicators with glow, warm accents `#FFC003` |
| **KOSMA** | `[BRACKET]` notation, uppercase tracking, bold data values, dark-first |

### Key Design Elements

- **LED-style progress bars** with realistic glow effects
- **Calculator aesthetic** with large monospaced percentages
- **Technical bracket notation** for section headers: `[DISPLAY]`, `[SETTINGS]`
- **McLaren timing curve** for smooth, engineered animations
- **Orange-only accent** - no blue, no purple, pure technical orange

See [specs/design-system.md](specs/design-system.md) for the complete design specification and [specs/BRANDING.MD](specs/BRANDING.MD) for brand guidelines.

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
make release       # Build release .app bundle
make dmg           # Create distributable DMG
```

### Code Quality

The project enforces code quality via pre-commit hooks and CI:

```bash
make format        # Format code with SwiftFormat
make lint          # Lint code with SwiftLint
make check         # Run format + lint + test (CI gate)
make setup         # Install git hooks + resolve deps
```

### Testing Localization

To test the app in a specific language, use these launch arguments in Xcode:

**Product > Scheme > Edit Scheme > Run > Arguments > Arguments Passed On Launch:**

```bash
# Portuguese (Brazil)
-AppleLanguages "(pt-BR)"
-AppleLocale "pt_BR"

# Spanish (Latin America)
-AppleLanguages "(es)"
-AppleLocale "es_419"
```

Or run from Terminal:

```bash
# Run in Portuguese
defaults write com.kaduwaengertner.ClaudeApp AppleLanguages -array "pt-BR"
open /Applications/ClaudeApp.app

# Reset to system default
defaults delete com.kaduwaengertner.ClaudeApp AppleLanguages
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick summary:

1. **Fork and branch** - Create a feature branch from `main`
2. **Code quality** - Run `make check` before committing (format, lint, test)
3. **Tests** - Add tests for new functionality
4. **Commits** - Write clear commit messages explaining the "why"
5. **Pull request** - Submit PR with description of changes

### Before Submitting

```bash
make setup         # One-time: install git hooks
make check         # Must pass: format, lint, test
```

The CI workflow runs on all pull requests and must pass before merging.

### Adding Translations

To add support for a new language:

1. **Edit String Catalog** - Open `App/Localizable.xcstrings` in Xcode
2. **Add Language** - In the String Catalog editor, add a new language from the "+" menu
3. **Translate All Keys** - Provide translations for all ~105 strings
4. **Follow Glossary** - Use consistent terminology (see [specs/internationalization.md](specs/internationalization.md#glossary))
5. **Test Thoroughly** - Run the app with your language to verify all strings appear correctly
6. **Submit PR** - Include screenshots showing the localized UI

See [specs/internationalization.md](specs/internationalization.md) for the complete localization specification.

## Privacy

ClaudeApp reads your Claude Code OAuth credentials locally from the macOS Keychain to fetch usage data from the Anthropic API. No data is sent to third parties. All data stays on your device.

## License

MIT License - see [LICENSE](LICENSE)

## Acknowledgments

- [Claude](https://claude.ai) by Anthropic
- Built with Swift and SwiftUI
