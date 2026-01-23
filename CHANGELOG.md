# Changelog

All notable changes to ClaudeApp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-01-23

### Added
- **Burn Rate Indicator**: New badge in dropdown header showing consumption velocity (Low/Medium/High/Very High)
- **Time-to-Exhaustion**: Predictive display showing estimated time until usage limit is reached
- **Update Checking**: Automatic version checking via GitHub Releases with manual check button in Settings
- **BurnRateCalculator**: Core calculation engine for consumption rate analysis based on usage history
- **UsageSnapshot**: Internal model for tracking usage history across refresh cycles
- Comprehensive UI tests for burn rate display components (39 new tests)

### Changed
- Refactored reusable UI components into dedicated UI package (Theme, UsageProgressBar, BurnRateBadge, SettingsComponents)
- UsageProgressBar now displays time-to-exhaustion below reset time when available
- Settings About section now has interactive update checking UI with loading states

### Technical
- Added `BurnRate` and `BurnRateLevel` domain models with Sendable/Equatable/Codable conformance
- Extended `UsageWindow` with optional `burnRate` and `timeToExhaustion` properties
- Implemented `BurnRateCalculator` with configurable minimum samples and rate calculation
- Integrated burn rate calculation into `UsageManager` refresh cycle with history tracking
- Created `UpdateChecker` actor with 24-hour rate limiting and shouldNotify deduplication
- Total test count: 320 tests passing

## [1.1.0] - 2026-01-XX

### Added
- **Settings Window**: Full settings panel with display, refresh, notifications, and general sections
- **Notification System**: Configurable usage warnings at custom thresholds
- **Launch at Login**: Native SMAppService integration
- **Notification Permissions**: UI for requesting and handling notification permissions
- SettingsManager with UserDefaults persistence
- LaunchAtLoginManager for system integration
- NotificationManager actor with hysteresis logic

### Changed
- Settings button now opens dedicated settings window
- Refresh interval now configurable (1-30 minutes)

### Technical
- Total test count: 155 tests passing

## [1.0.0] - 2026-01-XX

### Added
- Initial release
- Menu bar usage display with percentage
- Dropdown with detailed usage breakdown (5-hour session, 7-day limits, per-model quotas)
- Auto-refresh with configurable intervals
- Manual refresh button
- Error and loading states with stale data display
- Dark mode support
- Modular package architecture (Domain, Services, Core, UI)

### Technical
- Swift 5.9+ / SwiftUI
- macOS 14 (Sonoma) required
- 81 tests passing

[Unreleased]: https://github.com/kaduwaengertner/claudeapp/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/kaduwaengertner/claudeapp/releases/tag/v1.2.0
[1.1.0]: https://github.com/kaduwaengertner/claudeapp/releases/tag/v1.1.0
[1.0.0]: https://github.com/kaduwaengertner/claudeapp/releases/tag/v1.0.0
