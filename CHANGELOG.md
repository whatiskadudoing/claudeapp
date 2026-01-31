# Changelog

All notable changes to ClaudeApp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.0.1] - 2026-01-31

### Added
- **CI/CD Pipeline**: Restored GitHub Actions for automated testing on all PRs
  - `swift build` and `swift test` (853 tests) on every push/PR
  - SwiftFormat lint check (`--lint`) enforces code formatting
  - SwiftLint with `--strict` flag ensures code quality
  - SPM dependency caching for faster CI runs
  - 30-minute timeout with `macos-14` runner (Apple Silicon)
- **Release Automation**: GitHub Actions workflow for tag-based releases
  - Triggers on `v*` tags (e.g., `v2.0.1`)
  - Runs full test suite before building
  - Creates DMG with `make dmg`
  - Generates SHA256 checksum for verification
  - Attaches DMG and checksums to GitHub Release
  - Auto-generates release notes from commits
- **Contributing Documentation**: Comprehensive `CONTRIBUTING.md` guide
  - Development setup instructions with prerequisites
  - Makefile commands reference
  - Code style guidelines (SwiftFormat + SwiftLint)
  - Testing requirements and coverage goals
  - Pull request process and checklist
  - Architecture overview (4-package DDD structure)
- **CI Badges**: README now displays CI status and test count badges
  - CI workflow status badge
  - Test count badge (853 tests)
  - Existing: Release, Swift 5.9+, macOS 14+, MIT License badges

### Technical
- SLC 12: CI/CD Infrastructure complete
- No new tests (infrastructure only)
- Total test count: 853 tests passing

## [2.0.0] - 2026-01-30

### Added
- **Multi-Account Support**: Monitor multiple Claude accounts from a single menu bar app
  - Add, edit, and remove accounts from Settings → Accounts section
  - Switch between accounts via dropdown header (click account name)
  - Each account fetches usage independently via its own credentials
  - Primary account indicator (●/○) for default account selection
  - Automatic migration: creates "Default" account on first launch for existing users
- **Account Switcher**: Dropdown header now shows active account name with chevron
  - Click to open account picker menu
  - Quick account switching without opening Settings
  - "Add Account" option directly from switcher menu
- **Per-Account Usage Tracking**: UsageManager now tracks usage per-account
  - `usageByAccount` dictionary stores usage data keyed by account ID
  - `refreshAllAccounts()` fetches usage for all active accounts in parallel
  - `highestUtilizationAcrossAccounts` computed property for aggregate view
  - Per-account error tracking with `errorByAccount` dictionary
  - Per-account usage history for independent burn rate calculation
- **Display Mode Settings**: Control which accounts appear in menu bar
  - All Accounts / Active Only / Primary Only options
  - Show Account Labels toggle for multi-account menu bar display (future)

### Changed
- Major version bump (2.0.0) for architectural change to multi-account support
- Domain package version bumped to 2.0.0 with new Account model
- UsageManager maintains full backward compatibility with single-account setup
- SharedCacheManager writes active account's data for CLI integration
- AppContainer now wires AccountManager as shared dependency

### Technical
- Added `Account` model (Identifiable, Sendable, Codable, Equatable)
- Added `AccountStorage` protocol and `UserDefaultsAccountStorage` implementation
- Added `AccountManager` (@Observable, @MainActor) for account CRUD operations
- Added `MultiAccountCredentialsRepository` actor for per-account credential access
- Added `MultiAccountDisplayMode` enum (all, activeOnly, primaryOnly)
- Added 27 localization strings for account UI (en, pt-BR, es)
- 101 new tests across Domain (+45), Core (+42), UI (+14)
- Total test count: 853 tests passing

## [1.9.0] - 2026-01-30

### Added
- **Terminal Integration**: CLI interface for shell prompt, tmux, and Starship integration
  - `claudeapp --status` outputs usage data from shared cache
  - `--format` option: plain, json, minimal, verbose
  - `--metric` option: session, weekly, highest, opus, sonnet
  - `--refresh` flag forces API fetch and updates cache
  - `--no-color` flag disables ANSI color output
  - Exit codes: 0 (success), 1 (not authenticated), 2 (API error), 3 (stale data)
- **Shared Cache Infrastructure**: App Group for CLI/GUI data sharing
  - SharedCacheManager in Core package with read/write operations
  - Cache TTL system: fresh (<5min), stale (5-15min), expired (>15min)
  - Automatic cache updates on each GUI refresh
  - JSON-encoded UsageData with timestamp in App Group UserDefaults
- **Shell Integration Documentation**: Comprehensive terminal setup guides
  - bash prompt integration example
  - zsh prompt integration example
  - Starship custom module configuration
  - tmux status bar configuration
  - Oh My Zsh plugin template
  - `scripts/install-cli.sh` for symlink creation

### Changed
- UsageManager now writes to SharedCacheManager on each refresh
- UsageData and UsageWindow models now Codable for JSON serialization
- App entry point moved to main.swift for CLI/GUI routing

### Technical
- Added ArgumentParser dependency for CLI parsing
- Created CLIHandler with ParsableCommand conformance
- Added 26 SharedCacheManager tests
- Total test count: 752 tests passing

## [1.8.0] - 2026-01-30

### Added
- **Historical Sparkline Charts**: Visual usage trends below progress bars
  - UsageSparkline component using native Swift Charts
  - Session history (5-min granularity, up to 60 points)
  - Weekly history (1-hour granularity, up to 168 points)
  - Smooth catmullRom interpolation with gradient fill
  - LED glow effect matching KOSMA design system
- **UsageHistoryManager**: Persistent history tracking with UserDefaults
  - Automatic session history clearing on window reset
  - History data exposed via SwiftUI environment
- **Show Usage Charts Toggle**: Settings option to enable/disable sparklines
- **Settings Export/Import**: Backup and restore user configurations
  - ExportedSettings model with version, timestamp, and full settings payload
  - SettingsExportManager for export, import, backup, and reset operations
  - Pretty-printed JSON output with ISO 8601 dates
  - Validation and import summary before applying settings
  - Automatic backup creation before import (optional)
- **Data Section in Settings**: Export, Import, and Reset to Defaults buttons
  - Export sheet with usage history inclusion toggle
  - Import confirmation with settings summary
  - Reset confirmation dialog with destructive action

### Changed
- UsageManager now records usage snapshots to UsageHistoryManager on each refresh
- Dropdown view displays sparklines below each usage window (when enabled)
- Settings UI now includes Data section for backup/restore operations

### Technical
- Added UsageDataPoint model in Domain package (Sendable, Equatable, Codable)
- Added ExportedSettings model with nested settings payload structures
- UsageHistoryManager integrated into AppContainer dependency injection
- Total test count: 726 tests passing

## [1.7.0] - 2026-01-30

### Added
- **Power-Aware Refresh**: Smart refresh scheduling based on battery/power state
  - AdaptiveRefreshManager with system state monitoring
  - Longer intervals on battery, shorter when charging
  - Respects Low Power Mode settings
  - Power state indicator in dropdown footer (battery/idle icons)
- **Burn Rate Badge in Header**: Display consumption velocity badge prominently in dropdown header
- **Menu Bar Warning Indicator**: Shows ⚠️ warning icon when any usage window reaches 100%
- **Update Notification Click**: Clicking update notification now opens download URL in browser
- **Premium Design System**: Hybrid McLaren/Teenage Engineering/KOSMA aesthetic
  - McLaren Papaya orange `#FF7300` as primary brand color
  - TE-style light typography (300 weight) for elegant technical feel
  - LED-style indicators with realistic glow effects
  - McLaren timing curve `cubic-bezier(0.19, 1, 0.22, 1)` for animations
  - Calculator aesthetic with large monospaced percentages
  - KOSMA bracket notation `[DISPLAY]` for section headers

### Changed
- Updated color palette with warmer, more vibrant oranges
- Progress bars now use LED meter aesthetic with double glow
- Typography weights reduced for TE-inspired elegance
- Animation timing updated to McLaren standard (300ms)
- Section headers use lighter font weights with increased tracking
- UpdateChecker now persists lastCheckDate across app restarts

### Fixed
- User agent now reports correct app version to API (was hardcoded to 1.2.0)
- GitHub repository configured correctly for update checking

### Documentation
- Complete rewrite of `specs/design-system.md`
- New `specs/BRANDING.MD` with brand identity guidelines
- Updated `research/inspiration.md` with design sources
- Updated README with design system section

### Technical
- Added `isAtCapacity` computed property to UsageData
- Added `userInfo` parameter to NotificationManager for update notification handling
- Total test count: 620 tests passing

## [1.6.0] - 2026-01-26

### Added
- **Icon Styles**: 6 customizable menu bar display styles (Percentage, Progress Bar, Battery, Compact, Icon Only, Full)
- Icon style picker in Settings with live preview
- Localization strings for all icon styles in English, Portuguese (pt-BR), and Spanish
- LICENSE file with MIT license
- CODE_OF_CONDUCT.md referencing Contributor Covenant v2.1
- SECURITY.md with vulnerability reporting process
- README.md Documentation section with links to all guides

### Changed
- CHANGELOG.md now has accurate dates and complete version history
- MenuBarLabel now supports 6 different display styles based on user preference
- Settings Display section now includes Menu Bar Style picker

### Technical
- Added IconStyle enum with RawRepresentable, CaseIterable, Codable, Sendable conformance
- Added IconStyleComponents (ProgressBarIcon, BatteryIndicator, StatusDot)
- Total test count: 552 tests passing

## [1.5.0] - 2026-01-24

### Added
- **Dynamic Type Support**: Adaptive text scaling with semantic typography system
- **Color-Blind Safe Patterns**: Diagonal stripe overlays on progress bars at critical thresholds
- **Shape Indicators**: Geometric shapes on burn rate badges for accessibility
- **Reduced Motion Support**: Respects system "Reduce Motion" preference
- **High Contrast Mode**: Enhanced visibility for users with visual impairments
- Comprehensive accessibility unit tests (28 new tests)

### Fixed
- Yellow warning color updated from #EAB308 (2.1:1) to #B8860B goldenrod (3.5:1) for WCAG AA compliance

### Technical
- Total test count: 489 tests passing

## [1.4.0] - 2026-01-23

### Added
- **Internationalization Infrastructure**: String Catalog with centralized localization
- **Portuguese (pt-BR)**: Full Brazilian Portuguese translation
- **Spanish (es-LATAM)**: Full Latin American Spanish translation
- Locale-aware date and number formatting
- Localization unit tests (33 new tests)

### Changed
- All UI strings now use LocalizedStringKey for proper localization
- Date displays use system RelativeDateTimeFormatter for localized output

### Technical
- Total test count: 402 tests passing

## [1.3.0] - 2026-01-22

### Added
- **VoiceOver Support**: Full accessibility labels for menu bar and dropdown
- **Keyboard Navigation**: Complete keyboard control throughout the app
- **VoiceOver Announcements**: State change announcements for screen reader users
- **GitHub Actions CI/CD**: Automated build and test workflows
- **Release Automation**: GitHub Actions release workflow
- **App Bundle Generation**: macOS .app bundle creation script
- Accessibility tests (18 new tests)

### Technical
- Total test count: 369 tests passing

## [1.2.0] - 2026-01-21

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

## [1.1.0] - 2026-01-21

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

## [1.0.0] - 2026-01-20

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

[Unreleased]: https://github.com/kaduwaengertner/claudeapp/compare/v2.0.1...HEAD
[2.0.1]: https://github.com/kaduwaengertner/claudeapp/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.9.0...v2.0.0
[1.9.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/kaduwaengertner/claudeapp/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/kaduwaengertner/claudeapp/releases/tag/v1.0.0
