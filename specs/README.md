# ClaudeApp - Specifications

A macOS menu bar application for Claude Code users to monitor their API usage limits in real-time.

---

## Start Here

| Document | Description |
|----------|-------------|
| **[AUDIENCE_JTBD.md](../AUDIENCE_JTBD.md)** | Target audience, personas, jobs to be done - **READ FIRST** |
| **[competitive-analysis.md](./competitive-analysis.md)** | Competitive research and feature gap analysis |

---

## Project Overview

**ClaudeApp** is an open-source, native macOS menu bar app that provides passive monitoring of Claude Code usage limits without interrupting developer workflow.

### What It Does

- **Menu Bar Display**: Shows Claude icon + highest usage percentage (e.g., "86%")
- **Detailed Dropdown**: Breakdown of 5-hour session, 7-day limits, per-model limits
- **Burn Rate**: Consumption velocity indicator (Low/Med/High/Very High)
- **Time-to-Exhaustion**: Predicts when usage limit will be reached
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

## Documentation Structure

### Core Specifications

| File | Description |
|------|-------------|
| [architecture.md](./architecture.md) | Package structure, DDD patterns, dependency rules |
| [design-system.md](./design-system.md) | Hybrid design system (McLaren/TE/KOSMA) |
| [BRANDING.MD](./BRANDING.MD) | Brand identity, voice, visual language |
| [api-documentation.md](./api-documentation.md) | Claude API endpoints, auth, responses |
| [toolchain.md](./toolchain.md) | Build commands, dev workflow, CI/CD |
| [competitive-analysis.md](./competitive-analysis.md) | Competitive research summary |

### Feature Specifications

| File | Description | Status |
|------|-------------|--------|
| [features/view-usage.md](./features/view-usage.md) | Main usage display with burn rate | ✅ Implemented |
| [features/refresh-usage.md](./features/refresh-usage.md) | Auto-refresh and manual refresh | ✅ Implemented |
| [features/notifications.md](./features/notifications.md) | Warning alerts with hysteresis | ✅ Implemented |
| [features/settings.md](./features/settings.md) | In-popover settings UI | ✅ Implemented |
| [features/updates.md](./features/updates.md) | GitHub Releases version checking | ✅ Implemented |
| [features/icon-styles.md](./features/icon-styles.md) | Multiple menu bar display styles | ✅ Implemented |
| [features/historical-charts.md](./features/historical-charts.md) | Sparkline usage charts | ✅ Implemented |
| [features/power-aware-refresh.md](./features/power-aware-refresh.md) | Battery-optimized refresh | ✅ Implemented |
| [features/multi-account.md](./features/multi-account.md) | Multiple Claude accounts | 📋 Planned |
| [features/widgets.md](./features/widgets.md) | macOS Notification Center widgets | 📋 Planned |
| [features/settings-export.md](./features/settings-export.md) | JSON export/import of settings | ✅ Implemented |
| [features/terminal-integration.md](./features/terminal-integration.md) | Shell prompt integration | ✅ Implemented |

### System Specifications

| File | Description | Status |
|------|-------------|--------|
| [sparkle-updates.md](./sparkle-updates.md) | Sparkle framework for auto-updates | 📋 Planned |
| [accessibility.md](./accessibility.md) | VoiceOver, keyboard nav, WCAG | ✅ Implemented |
| [internationalization.md](./internationalization.md) | i18n/l10n, supported languages | ✅ en, pt-BR, es |
| [user-documentation.md](./user-documentation.md) | README, guides, FAQ, privacy | ✅ Complete |
| [performance.md](./performance.md) | Memory/CPU budgets, profiling | ✅ Defined |

---

## Key Features

### Implemented (v1.9.0)

| Feature | Description |
|---------|-------------|
| **View Usage** | Display all usage limits with LED-style progress bars |
| **Burn Rate** | Show consumption velocity (Low/Med/High/Very High) |
| **Time-to-Exhaustion** | Predict when usage limit will be reached |
| **Auto-Refresh** | Configurable polling (1-30 min, default 5 min) |
| **Power-Aware Refresh** | Smart refresh scheduling based on battery/power state |
| **Notifications** | Warnings at configurable thresholds with hysteresis |
| **Settings** | In-popover KOSMA-styled configuration UI |
| **Updates** | GitHub releases version checking |
| **Accessibility** | VoiceOver, keyboard nav, Dynamic Type, color-blind safe |
| **Multi-Language** | English, Portuguese (Brazil), Spanish (Latin America) |
| **Premium Design** | Hybrid McLaren/TE/KOSMA design system |
| **Icon Styles** | 6 customizable menu bar display styles |
| **Historical Charts** | Sparkline usage trends below progress bars |
| **Settings Export** | JSON backup, restore, and reset of configurations |
| **Terminal Integration** | CLI for shell prompts, tmux, Starship with shared cache |

### Planned (v2.0.0+)

| Feature | Priority | Spec |
|---------|----------|------|
| **Sparkle Updates** | High | [sparkle-updates.md](./sparkle-updates.md) |
| **Multi-Account** | Medium | [multi-account.md](./features/multi-account.md) |
| **Widgets** | Low | [widgets.md](./features/widgets.md) |

---

## Research References

Detailed competitive research conducted January 2026:

| Document | Description |
|----------|-------------|
| `research/competitive-analysis.md` | Direct competitors analysis |
| `research/macos-menubar-apps.md` | 19 popular menu bar apps |
| `research/llm-usage-tracking-tools.md` | LLM cost tracking platforms |
| `research/swift-chart-libraries.md` | Data visualization libraries |
| `research/update-mechanisms.md` | Auto-update implementations |
| `research/claude-related-tools.md` | Claude ecosystem tools |

See [competitive-analysis.md](./competitive-analysis.md) for summary.

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

## Design Inspirations

ClaudeApp uses a **hybrid design system** combining three world-class design sources:

| Source | URL | Contribution |
|--------|-----|--------------|
| **McLaren F1 Playbook** | [mclaren.com/racing/formula-1/playbook](https://www.mclaren.com/racing/formula-1/playbook/) | Papaya orange `#FF7300`, timing curves, precision |
| **Teenage Engineering** | [teenage.engineering/products/ep-133](https://teenage.engineering/products/ep-133) | Light typography, LED indicators, warm accents |
| **KOSMA** | Internal spec | Bracket notation, data hierarchy, dark-first |

Additional references:
- **UI Components**: [swiftcn-ui](https://github.com/Mobilecn-UI/swiftcn-ui) - Modern SwiftUI patterns
- **Menu Bar UX**: [Stats](https://github.com/exelban/stats) - Best-in-class system monitor
- **Architecture**: [Quotio](https://github.com/nguyenphutrong/quotio) - Modern @Observable patterns

See [design-system.md](./design-system.md) and [BRANDING.MD](./BRANDING.MD) for complete details.

---

## Out of Scope (v1)

Items deferred to future releases:

- ~~Multiple account support~~ → Spec created: [multi-account.md](./features/multi-account.md)
- ~~Historical usage graphs~~ → Spec created: [historical-charts.md](./features/historical-charts.md)
- Push notifications (polling only)
- In-app update installation (requires signing)
- iOS/iPadOS versions

---

## License

Open Source (MIT License)
