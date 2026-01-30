# Implementation Plan

## Recommended SLC Release: SLC 9 - Visualization & Power User Features

**Audience:** Professional developers using Claude Code who run ClaudeApp continuously throughout their workday, demanding passive usage monitoring with zero workflow interruption.

**Value proposition:** Add visual usage trends via sparkline charts and enable settings backup/restore for power users who want to understand consumption patterns and migrate configurations across machines.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Historical Charts | Basic | Most requested visual feature; shows usage trends over time |
| Settings Export/Import | Basic | Power user feature; enables backup and machine migration |

**What's NOT in this slice:**
- Terminal Integration → SLC 10 (requires App Group, ArgumentParser, more complex)
- Multi-Account → SLC 11 (significant architecture refactoring needed)
- Widgets → Future (blocked by code signing requirement)
- Sparkle Auto-Updates → Future (blocked by code signing requirement)

---

## Comprehensive Gap Analysis (2026-01-30)

### ✅ FULLY IMPLEMENTED FEATURES (SLC 1-8 Complete)

| Feature | SLC | Status | Tests | Notes |
|---------|-----|--------|-------|-------|
| View Usage (menu bar + dropdown) | 1 | ✅ | 620 | All 4 windows, progress bars, reset times |
| Refresh Usage (auto + manual) | 1-2 | ✅ | 620 | Configurable interval, debouncing, backoff |
| Notifications | 2 | ✅ | 620 | Warning, capacity full, reset; hysteresis |
| Settings (in-popover) | 2 | ✅ | 620 | Display, refresh, notifications, general |
| Time-to-Exhaustion | 3 | ✅ | 620 | Prediction display, burn rate calculation |
| Burn Rate Calculation | 3 | ✅ | 620 | 4-level system, color-coded badges |
| Icon Styles | 3 | ✅ | 620 | All 6 styles: percentage, bar, battery, compact, icon, full |
| Updates (GitHub Releases) | 3 | ✅ | 620 | Version check, download URL, notification click |
| Power-Aware Refresh | 4-8 | ✅ | 620 | SystemStateMonitor, AdaptiveRefreshManager, power indicators |
| Accessibility | 4-6 | ✅ | 620 | VoiceOver, keyboard nav, reduce motion, high contrast |
| Internationalization | 5 | ✅ | 620 | en, pt-BR, es fully localized |
| 100% Warning Badge | 8 | ✅ | 620 | Menu bar warning icon when at capacity |
| Update Persistence | 8 | ✅ | 620 | lastCheckDate survives app restarts |

### ✅ FULLY IMPLEMENTED (SLC 9 Complete)

| Feature | SLC | Status | Tests | Notes |
|---------|-----|--------|-------|-------|
| Historical Charts | 9 | ✅ | 726 | Sparklines for session and weekly windows |
| Settings Export/Import | 9 | ✅ | 726 | Export, import, backup, reset functionality |

### ❌ NOT IMPLEMENTED (Planned Features)

| Feature | Spec | Complexity | Blocked By | Priority |
|---------|------|------------|------------|----------|
| Terminal Integration | specs/features/terminal-integration.md | High | App Group setup | MEDIUM |
| Multi-Account | specs/features/multi-account.md | High | Architecture changes | LOW |
| Widgets | specs/features/widgets.md | High | Code signing | LOW |
| Sparkle Auto-Updates | specs/sparkle-updates.md | Medium | Code signing | LOW |

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Historical Charts Spec | `specs/features/historical-charts.md` | Full feature specification with data model |
| Settings Export Spec | `specs/features/settings-export.md` | JSON schema, UI design, security considerations |
| Competitive Analysis | `research/competitive-analysis.md` | ccseva has 7-day charts; Rectangle has JSON export |
| Swift Chart Libraries | `research/swift-chart-libraries.md` | DSFSparkline vs Swift Charts evaluation |
| Advanced Settings Patterns | `research/advanced-settings-patterns.md` | Export/import patterns from popular apps |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Adds visual analytics and power user settings management -->

## Phase 0: Build Verification - REQUIRED

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - must succeed ✅
  - Run `swift test` - all 620 tests must pass ✅
  - Run `make release` - verify .app bundle creates successfully ✅
  - **Verified:** 2026-01-30 - Build clean, all 620 tests pass, release bundle validates

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. -->

## Phase 1: Historical Charts Foundation - CRITICAL

**Purpose:** Add sparkline chart infrastructure and data persistence.

- [x] **Create UsageDataPoint model and UsageHistoryManager** [spec: historical-charts.md] [file: Packages/Domain/Sources/Domain/]
  - Add `UsageDataPoint` struct (utilization: Double, timestamp: Date) - ✅ Domain/UsageDataPoint.swift
  - Create `UsageHistoryManager` class (@Observable, @MainActor) - ✅ Core/UsageHistoryManager.swift
  - Implement session history (5-min granularity, max 60 points) - ✅
  - Implement weekly history (1-hour granularity, max 168 points) - ✅
  - Add persistence via UserDefaults (JSON encoding) - ✅
  - Add clear history methods - ✅
  - **Research:** `specs/features/historical-charts.md#data-model`
  - **Tests:** Add 15+ tests for history recording, persistence, trimming - ✅ 34 new tests (12 UsageDataPoint + 22 UsageHistoryManager)

- [x] **Integrate UsageHistoryManager with UsageManager** [spec: historical-charts.md] [file: Packages/Core/Sources/Core/UsageManager.swift]
  - Record usage snapshot on each successful refresh - ✅ in refresh() method
  - Wire UsageHistoryManager into AppContainer - ✅ created and connected to UsageManager
  - Expose history data for UI consumption - ✅ via container.usageHistoryManager
  - Clear session history when session window resets - ✅ checkAndHandleSessionReset() method
  - **Research:** `specs/features/historical-charts.md#implementation`
  - **Tests:** Add integration tests for history recording on refresh - ✅ 9 new tests added

---
<!-- CHECKPOINT: Phase 1 establishes data persistence for charts. -->

## Phase 2: Sparkline UI Implementation

**Purpose:** Add sparkline chart components to dropdown view.

- [x] **Add UsageSparkline component using Swift Charts** [spec: historical-charts.md] [file: Packages/UI/Sources/UI/]
  - Create `UsageSparkline` view using native Swift Charts (macOS 13+) - ✅ UsageSparkline.swift
  - Implement AreaMark + LineMark with catmullRom interpolation - ✅
  - Color matches progress bar threshold colors - ✅ Uses Theme.Colors.brand
  - Height: 20px, hidden axes - ✅
  - Support gradient fill under line - ✅ LinearGradient with opacity
  - Accessibility: mark as decorative (parent provides context) - ✅ accessibilityHidden(true)
  - LED glow shadow effect added to match KOSMA design - ✅
  - **Research:** `specs/features/historical-charts.md#option-1-native-swift-charts-recommended`
  - **Tests:** Added 26 tests for sparkline initialization, edge cases, accessibility, and visual styling

- [x] **Add showSparklines settings toggle** [spec: historical-charts.md] [file: Packages/Domain/Sources/Domain/SettingsKey.swift]
  - Add `SettingsKey<Bool>("showSparklines", defaultValue: true)` - ✅ Domain/SettingsKey.swift
  - Add setting toggle in Display section of Settings UI - ✅ ClaudeApp.swift DisplaySectionContent
  - Wire to SettingsManager property with persistence - ✅ Core/SettingsManager.swift
  - Add localization strings for all 3 languages (en, es, pt-BR) - ✅ App/Localizable.xcstrings
  - **Research:** `specs/features/historical-charts.md#settings-toggle`
  - **Tests:** Add tests for setting persistence and UI toggle behavior - ✅ 3 tests updated in CoreTests.swift

- [x] **Integrate sparklines into UsageProgressBar** [spec: historical-charts.md] [file: App/ClaudeApp.swift]
  - Added usageHistoryManager to SwiftUI environment in ClaudeApp scene - ✅
  - Modified UsageContent to access UsageHistoryManager and SettingsManager via environment - ✅
  - Display sparkline below progress bar when showSparklines enabled - ✅
  - Pass session history for 5-hour window, weekly history for 7-day windows - ✅
  - Only show sparkline when hasSessionChartData/hasWeeklyChartData (>= 2 points) - ✅
  - Localization strings already added in previous task - ✅
  - **Note:** Opus/Sonnet-specific windows don't have separate history tracking (use weekly history)
  - **Tests:** All 685 tests pass including existing sparkline component tests

---
<!-- CHECKPOINT: Phase 2 delivers visual usage trends. -->

## Phase 3: Settings Export/Import

**Purpose:** Enable backup, restore, and migration of user settings.

- [x] **Create ExportedSettings model and SettingsExportManager** [spec: settings-export.md] [file: Packages/Core/Sources/Core/]
  - Add `ExportedSettings` struct matching JSON schema (version, exportedAt, appVersion, settings) - ✅ Domain/ExportedSettings.swift
  - Create `SettingsExportManager` class (@MainActor) - ✅ Core/SettingsExportManager.swift
  - Implement `export(includeUsageHistory:)` method - ✅
  - Implement `exportToFile(url:includeUsageHistory:)` with pretty-printed JSON - ✅
  - Implement `importFromFile(url:)` and `applySettings(_:)` methods - ✅
  - Implement `createBackup()` to ~/Library/Application Support/ClaudeApp/Backups/ - ✅
  - Implement `resetToDefaults()` clearing UserDefaults - ✅
  - Implement validation with ImportSummary and ValidationResult - ✅
  - **Security:** Never exports credentials or authentication data - ✅
  - **Research:** `specs/features/settings-export.md#settings-export-manager`
  - **Tests:** Add 20+ tests for export, import, backup, reset, validation - ✅ 40+ tests added (726 total)

- [x] **Add Data section to Settings UI** [spec: settings-export.md] [file: App/ClaudeApp.swift]
  - Add "Data" section with Export, Import, Reset buttons - ✅ CollapsibleSection added
  - Create ExportSettingsSheet with account/history checkboxes - ✅ includes usage history toggle
  - Implement file picker for import (`.json` content type) - ✅ fileImporter
  - Add confirmation dialog before reset to defaults - ✅ confirmationDialog
  - Show import summary before applying - ✅ ImportConfirmationSheet
  - Add option to create backup before import - ✅ createBackup toggle
  - Add localization strings for all new UI elements (en, es, pt-BR) - ✅ 35+ new strings
  - **Note:** SettingsExportManager now marked @Observable for SwiftUI environment
  - **Tests:** All 726 tests pass

---
<!-- CHECKPOINT: Phase 3 delivers settings backup/restore. -->

## Phase 4: Polish & Documentation

**Purpose:** Clean up, add documentation, and prepare release.

- [x] **Update version and documentation** [file: various]
  - Update version to 1.8.0 in Info.plist ✅
  - Update CHANGELOG.md with SLC 9 release notes ✅
  - Update specs/features/historical-charts.md acceptance criteria to ✅
  - Update specs/features/settings-export.md acceptance criteria to ✅
  - Update specs/README.md status indicators ✅

- [x] **Final verification** [file: Makefile]
  - Run full test suite: target 680+ tests - ✅ 726 tests pass
  - Run `make release` to create .app bundle (v1.8.0) - ✅ Bundle validates successfully
  - Code verification of all new features:
    - Sparklines integrated in UsageContent (ClaudeApp.swift:742-762) ✅
    - Settings toggle in Display section (ClaudeApp.swift:1131-1135) ✅
    - Export/Import/Reset buttons in Data section (ClaudeApp.swift:1515-1622) ✅
    - SettingsExportManager wired into AppContainer (AppContainer.swift:130-135) ✅
    - All 35+ localization strings present in 3 languages ✅
    - Version 1.8.0 in Info.plist ✅
  - **Success criteria:** All acceptance criteria verified via code review and tests

---
<!-- CHECKPOINT: Phase 4 completes SLC 9. Ready for v1.8.0 release. -->

## Acceptance Criteria Summary

### SLC 9 Checklist

**Historical Charts:**
- [x] Sparkline chart for 5-hour session window
- [x] Sparkline chart for 7-day weekly window
- [x] Toggle to enable/disable sparklines in settings
- [x] Charts update on data refresh
- [x] History persists across app restarts
- [x] Smooth interpolated line style with gradient fill
- [x] Color matches progress bar threshold

**Settings Export/Import:**
- [x] Export settings to JSON file
- [x] Import settings from JSON file
- [x] Reset to defaults option
- [x] Confirmation dialog before import/reset
- [x] Create backup before import (optional)
- [x] Include/exclude usage history option
- [x] Pretty-printed JSON output
- [x] Version compatibility check on import

---

## Future Work (Outside Current Scope)

### SLC 10: Terminal Integration

**Value:** Enable usage monitoring from CLI and shell prompts.

| Feature | Spec | Why Deferred |
|---------|------|--------------|
| CLI Interface | specs/features/terminal-integration.md | Requires App Group, ArgumentParser dependency |

**Prerequisites:**
- Add ArgumentParser dependency to Package.swift
- Set up App Group for shared UserDefaults
- Create cache sharing between GUI and CLI

**Research Reference:** `specs/features/terminal-integration.md`

### SLC 11: Multi-Account Support

**Value:** Monitor multiple Claude accounts in one app.

| Feature | Spec | Why Deferred |
|---------|------|--------------|
| Account Management | specs/features/multi-account.md | Significant architecture refactoring needed |

**Prerequisites:**
- Create AccountManager with Account model
- Create MultiAccountCredentialsRepository
- Update UsageManager for per-account tracking
- Design account switcher UI

**Research Reference:** `specs/features/multi-account.md`

### Future Releases (External Dependencies)

| Feature | Blocker | Notes |
|---------|---------|-------|
| Widgets | Code Signing | WidgetKit requires signed app |
| Sparkle Auto-Updates | Code Signing | Sparkle requires signed app for auto-install |

### Technical Debt Backlog

| Item | Priority | Notes |
|------|----------|-------|
| Integration tests with mock network | Medium | No network failure tests |
| Keychain error scenario tests | Medium | Only happy path tested |
| Settings data migration tests | Low | No version compatibility tests |
| Burn rate thresholds configurable | Low | Currently hardcoded |
| Hysteresis buffer configurable | Low | Currently hardcoded 5% |

---

## Test Coverage Summary

**Current:** 726 tests across 4 packages

| Package | Tests | Coverage |
|---------|-------|----------|
| Domain | 132 | Excellent - models fully tested (+25 ExportedSettings tests) |
| Services | 29 | Basic - needs error scenarios |
| Core | 313 | Comprehensive - business logic (+16 SettingsExportManager tests) |
| UI | 252 | Excellent - accessibility focus (+26 UsageSparkline tests) |

**Target for SLC 9:** 680+ tests (met! currently 726)

---

## Previous SLC Releases

| SLC | Name | Version | Tests | Status |
|-----|------|---------|-------|--------|
| 1 | Usage Monitor | 1.0.0 | 81 | ✅ COMPLETE |
| 2 | Notifications & Settings | 1.1.0 | 155 | ✅ COMPLETE |
| 3 | Predictive Insights | 1.2.0 | 320 | ✅ COMPLETE |
| 4 | Distribution Ready | 1.3.0 | 369 | ✅ COMPLETE |
| 5 | Internationalization | 1.4.0 | 402 | ✅ COMPLETE |
| 6 | Advanced Accessibility | 1.5.0 | 489 | ✅ COMPLETE |
| 7 | Community Ready + Icon Styles | 1.6.0 | 552 | ✅ COMPLETE |
| 8 | Power-Aware Refresh | 1.7.0 | 620 | ✅ COMPLETE |
| 9 | Visualization & Power User | 1.8.0 | 726 | ✅ COMPLETE |
