# ClaudeApp - Specifications

A macOS menu bar application for Claude Code users to monitor their API usage limits in real-time.

---

## Start Here

| Document | Description |
|----------|-------------|
| **[AUDIENCE_JTBD.md](../AUDIENCE_JTBD.md)** | Target audience, personas, jobs to be done - **READ FIRST** |

This document lives at the project root and defines WHO we're building for and WHY. All specs flow from it.

---

## Project Overview

**ClaudeApp** is an open-source, native macOS menu bar app that provides passive monitoring of Claude Code usage limits without interrupting developer workflow.

### What It Does

- **Menu Bar Display**: Shows Claude icon + highest usage percentage (e.g., "86%")
- **Detailed Dropdown**: Breakdown of 5-hour session, 7-day limits, per-model limits
- **Warnings**: Visual alerts when hitting 100% capacity
- **Auto-Refresh**: Background polling with configurable intervals

### Target Users

- Claude Code CLI users (Pro, Max 5x, Max 20x plans)
- Developers who want to monitor usage without leaving their workflow

### Platform Requirements

- **macOS**: Latest version only (macOS 14 Sonoma+)
- **No legacy support**: We optimize for modern APIs only
- **Open Source**: No Apple Developer ID required
  - Distributed via GitHub Releases + Homebrew
  - Users bypass Gatekeeper on first launch

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI (latest) |
| State Management | @Observable / Observation framework |
| Concurrency | Swift Concurrency (async/await, actors) |
| Build System | Swift Package Manager + Makefile |
| Distribution | GitHub Releases, Homebrew tap |

---

## Architecture Principles

### Domain-Driven Design (DDD) Inspired

The app uses a **modular package architecture** that separates concerns and enables:
- Easy swapping of repositories/APIs
- Independent unit testing per module
- Clear dependency boundaries

### Package Structure

```
ClaudeApp/
├── App/                    # Main app target
├── Packages/
│   ├── Domain/             # Models, protocols, business rules (zero deps)
│   ├── Services/           # API client, Keychain, networking
│   ├── Core/               # Business logic, managers, use cases
│   └── UI/                 # SwiftUI views, components, theme
├── Tests/                  # Unit & integration tests
├── Makefile                # Developer toolchain commands
└── Package.swift           # SPM workspace definition
```

### Dependency Rules

```
UI → Core → Services → Domain
         ↘    ↗
          Domain (leaf, no internal deps)
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| **View Usage** | Display all usage limits with progress bars |
| **Auto-Refresh** | Configurable polling (1-30 min, default 5 min) |
| **Manual Refresh** | On-demand usage update |
| **Notifications** | Warnings at configurable thresholds |
| **Configure Display** | Toggle plan badge, choose percentage source |
| **Launch at Login** | Native SMAppService integration |
| **Check Updates** | GitHub releases version checking |
| **Time-to-Exhaustion** | Predict when usage limit will be reached |
| **Burn Rate Indicator** | Show consumption velocity (Low/Med/High) |
| **Multi-Language** | Localized in English, Portuguese (Brazil), Spanish (Latin America) |

> **Internationalization (v1.4.0):** Full localization support with 105 translated strings. See [internationalization.md](./internationalization.md) for adding new languages.

---

## Data Sources

### Primary: OAuth Usage API

The app reads Claude Code credentials from macOS Keychain and calls the OAuth usage endpoint:

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer {oauth_token}
anthropic-beta: oauth-2025-04-20
```

Returns:
- `five_hour.utilization` - 5-hour rolling window (0-100%)
- `seven_day.utilization` - Weekly limit (0-100%)
- `seven_day_opus.utilization` - Opus-specific weekly quota
- Reset timestamps for each window

### Fallback: Local JSONL Parsing

If API is unavailable, can parse local usage files from `~/.claude/projects/*.jsonl` for offline estimation.

---

## Documentation Structure

### Core Specifications

| File | Description |
|------|-------------|
| [architecture.md](./architecture.md) | Package structure, DDD patterns, dependency rules |
| [design-system.md](./design-system.md) | Colors, typography, spacing, components |
| [api-documentation.md](./api-documentation.md) | Claude API endpoints, auth, responses |
| [toolchain.md](./toolchain.md) | Build commands, dev workflow, CI/CD |
| [features/](./features/) | Individual feature specifications |

### User-Facing Polish

| File | Description | Status |
|------|-------------|--------|
| [accessibility.md](./accessibility.md) | VoiceOver, keyboard nav, WCAG compliance | Phase 1 ✅ |
| [internationalization.md](./internationalization.md) | i18n/l10n strategy, supported languages | Phase 1 ✅ (en, pt-BR, es) |
| [user-documentation.md](./user-documentation.md) | README, guides, FAQ, privacy policy | ✅ |

### Production Readiness

| File | Description |
|------|-------------|
| [performance.md](./performance.md) | Memory/CPU budgets, optimization, profiling |

---

## Design Inspirations

- **UI Components**: [swiftcn-ui](https://github.com/Mobilecn-UI/swiftcn-ui) - Modern SwiftUI patterns
- **Functionality**: Existing Claude monitors analyzed for best practices
- **Brand**: Official Claude colors and iconography

---

## Out of Scope (v1)

- Multiple account support
- Historical usage graphs/predictions
- Push notifications (polling only)
- In-app update installation (requires signing)
- iOS/iPadOS versions

---

## License

Open Source (MIT License)
