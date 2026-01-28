# Implementation Plan

## Recommended SLC Release: Power-Aware Refresh (SLC 8)

**Audience:** Professional developers using Claude Code who run ClaudeApp continuously throughout their workday.

**Value proposition:** Optimize battery life and reduce unnecessary API calls by intelligently adapting refresh behavior based on system state (screen on/off, idle detection, battery vs plugged in) - delivering on the app's promise of being lightweight and efficient.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Power-Aware Refresh | Standard | Core feature - suspend when sleeping, reduce when idle |
| System State Monitor | Standard | Foundation for power-aware behavior |
| Settings Integration | Basic | Toggle to enable/disable + battery indicator |

**What's NOT in this slice:**
- Historical Charts → SLC 9 (visual enhancement, lower priority)
- Settings Export → SLC 9 (power user feature)
- Terminal Integration → SLC 10 (requires App Group, CLI work)
- Multi-Account → Future (complex, niche use case)
- Widgets → Future (blocked by code signing requirement)
- Sparkle Auto-Updates → Future (requires code signing)

---

## Gap Analysis Summary (2026-01-26)

### ✅ COMPLETE - All Core Features Implemented

| Feature | SLC | Status | Tests |
|---------|-----|--------|-------|
| Core usage monitoring | SLC 1 | ✅ | 81 |
| Notifications & Settings | SLC 2 | ✅ | 155 |
| Burn rate + time-to-exhaustion | SLC 3 | ✅ | 320 |
| Accessibility (VoiceOver, keyboard) | SLC 4 | ✅ | 369 |
| Internationalization (en, pt-BR, es) | SLC 5 | ✅ | 402 |
| Advanced Accessibility | SLC 6 | ✅ | 489 |
| Community files + Icon Styles | SLC 7 | ✅ | 552 |

### 🎯 NEXT - SLC 8 Power-Aware Refresh

| Item | Status | Notes |
|------|--------|-------|
| SystemStateMonitor | ❌ Not started | Detect sleep/wake/idle/battery |
| AdaptiveRefreshManager | ❌ Not started | Adjust intervals based on state |
| Settings integration | ❌ Not started | Toggle + battery indicator |
| Tests | ❌ Not started | Target: 580+ tests |

### 🔧 Technical Debt (Minor)

| Item | Priority | Notes |
|------|----------|-------|
| User agent version mismatch | Low | ClaudeAPIClient shows "1.2.0" vs 1.6.0 |
| NotificationPermissionManager tests | Low | No test coverage |
| PlanType enum tests | Low | No test coverage |

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Power-Aware Spec | `specs/features/power-aware-refresh.md` | Complete spec with state machine |
| Competitive Analysis | `research/inspiration.md` | Microverse achieved 83% CPU reduction |
| System APIs | `research/approaches/menubar-extra.md` | NSWorkspace notification patterns |
| Performance Budgets | `specs/performance.md` | Memory/CPU targets |
| Existing Sleep/Wake | `Packages/Core/Sources/Core/UsageManager.swift` | handleSleep/handleWake foundation |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Delivers measurable battery savings without changing core UX -->

## Phase 0: Build Verification - REQUIRED

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - must succeed ✅
  - Run `swift test` - all 552 tests must pass ✅
  - Run `make release` - .app bundle created successfully ✅
  - **Success criteria:** All checks pass, no regressions from SLC 7 ✅
  - **Verified:** 2026-01-26 - Build green, 552 tests passing, release bundle valid

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. Do not proceed if build is broken. -->

## Phase 1: System State Monitor - CRITICAL

**Purpose:** Create the foundation for detecting system state changes that affect refresh behavior.

- [x] **Implement SystemStateMonitor with screen sleep/wake and idle detection** [spec: power-aware-refresh.md] [file: Packages/Core/Sources/Core/SystemStateMonitor.swift]
  - Create `SystemState` enum: `.active`, `.idle`, `.sleeping`
  - Create `@MainActor @Observable` SystemStateMonitor class
  - Implement screen sleep/wake detection using `NSWorkspace.screensDidSleepNotification` and `NSWorkspace.screensDidWakeNotification`
  - Implement system sleep/wake detection using `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification`
  - Implement idle detection using `CGEventSource.secondsSinceLastEventType` with 5-minute threshold
  - Implement battery/AC detection using IOKit `IOPSCopyPowerSourcesInfo`
  - Add `isOnBattery: Bool` computed property
  - Add `currentState: SystemState` observable property
  - **Research:** `specs/features/power-aware-refresh.md` lines 64-194 for implementation
  - **Test:** Unit tests for state transitions, notification handling, battery detection
  - **Completed:** 2026-01-28 - 23 new tests added (575 total), includes SystemStateMonitorProtocol and MockSystemStateMonitor for testing

- [x] **Add SettingsKeys for power-aware refresh** [spec: power-aware-refresh.md] [file: Packages/Domain/Sources/Domain/SettingsKey.swift, Packages/Core/Sources/Core/SettingsManager.swift]
  - Add `SettingsKey.enablePowerAwareRefresh` (Bool, default: true)
  - Add `SettingsKey.reduceRefreshOnBattery` (Bool, default: true)
  - Add corresponding properties to SettingsManager
  - **Research:** `specs/features/power-aware-refresh.md` lines 280-291
  - **Test:** Settings persistence tests
  - **Target:** 4+ new tests
  - **Completed:** 2026-01-28 - 6 new tests added (581 total), keys in Domain, properties in Core SettingsManager with persistence

---
<!-- CHECKPOINT: Phase 1 delivers system state detection. Refresh behavior can now adapt. -->

## Phase 2: Adaptive Refresh Manager

**Purpose:** Replace the simple auto-refresh with intelligent, state-aware refresh scheduling.

- [x] **Implement AdaptiveRefreshManager with state-based interval calculation** [spec: power-aware-refresh.md] [file: Packages/Core/Sources/Core/AdaptiveRefreshManager.swift]
  - Create `@MainActor @Observable` AdaptiveRefreshManager class
  - Inject SystemStateMonitor, UsageManager, SettingsManager dependencies
  - Implement `effectiveRefreshInterval: TimeInterval` computed property:
    - **Sleeping:** Return `.infinity` (suspended)
    - **Idle on battery:** Double the user's interval (max 30 min)
    - **Idle on power:** Use user's interval
    - **Active with critical usage (>90%):** Min(user interval, 2 min)
    - **Active normal:** Use user's interval
  - Implement `startAutoRefresh()` / `stopAutoRefresh()` mirroring UsageManager API
  - Schedule next refresh using Task.sleep with recalculated interval after each refresh
  - Observe SystemStateMonitor changes to adjust schedule dynamically
  - **Research:** `specs/features/power-aware-refresh.md` lines 199-271
  - **Test:** Unit tests for interval calculation, state transitions, edge cases
  - **Target:** 20+ new tests
  - **Completed:** 2026-01-28 - 23 new tests added for AdaptiveRefreshManager + 6 new tests for MockAdaptiveRefreshManager (604 total)

- [ ] **Integrate AdaptiveRefreshManager into AppContainer** [file: Packages/Core/Sources/Core/AppContainer.swift, App/ClaudeApp.swift]
  - Create SystemStateMonitor instance in AppContainer
  - Create AdaptiveRefreshManager instance in AppContainer
  - Replace UsageManager's auto-refresh with AdaptiveRefreshManager when power-aware is enabled
  - Maintain backward compatibility: if power-aware disabled, use UsageManager's original refresh
  - Wire up sleep/wake notifications to use AdaptiveRefreshManager
  - Update existing sleep/wake observers to delegate to AdaptiveRefreshManager
  - **Research:** Existing AppContainer patterns in `Packages/Core/Sources/Core/AppContainer.swift`
  - **Test:** Integration tests for manager wiring
  - **Target:** 5+ new tests

---
<!-- CHECKPOINT: Phase 2 delivers adaptive refresh. Battery savings now active. -->

## Phase 3: Settings UI & Indicators

**Purpose:** Allow users to control power-aware behavior and see current power state.

- [ ] **Add Smart Refresh toggle to Settings Refresh section** [spec: power-aware-refresh.md] [file: App/ClaudeApp.swift]
  - Add "Smart Refresh" toggle in RefreshSection after refresh interval slider
  - Add subtitle: "Reduce refresh when idle or on battery"
  - Connect to `settings.enablePowerAwareRefresh`
  - Add "Reduce on Battery" toggle (only visible when Smart Refresh enabled)
  - Connect to `settings.reduceRefreshOnBattery`
  - **Research:** `specs/features/power-aware-refresh.md` lines 296-307 for UI layout
  - **Test:** Visual verification, settings persistence

- [ ] **Add power state indicator to dropdown footer** [spec: power-aware-refresh.md] [file: App/ClaudeApp.swift]
  - Create `PowerStateIndicator` view component
  - Show battery icon (`battery.50`) when on battery power
  - Show moon icon (`moon.zzz`) when in idle state
  - Display in dropdown footer near "Updated X ago" text
  - Only show when power-aware refresh is enabled
  - Add accessibility labels for VoiceOver
  - **Research:** `specs/features/power-aware-refresh.md` lines 351-369
  - **Test:** Accessibility tests for indicators
  - **Target:** 4+ new tests

- [ ] **Add localization strings for power-aware features** [file: App/Localizable.xcstrings]
  - Add English strings:
    - `settings.refresh.smartRefresh` = "Smart Refresh"
    - `settings.refresh.smartRefresh.subtitle` = "Reduce refresh when idle or on battery"
    - `settings.refresh.reduceOnBattery` = "Reduce on Battery"
    - `accessibility.powerState.onBattery` = "On battery power"
    - `accessibility.powerState.idle` = "System idle"
  - Add Portuguese (pt-BR) translations
  - Add Spanish (es) translations
  - **Research:** `specs/internationalization.md` for translation guidelines
  - **Test:** Localization key tests
  - **Target:** 3+ new tests

---
<!-- CHECKPOINT: Phase 3 delivers user-facing controls. Feature is complete and configurable. -->

## Phase 4: Polish, Testing & Documentation

**Purpose:** Ensure quality and complete the release.

- [ ] **Add comprehensive tests for power-aware refresh** [file: Packages/Core/Tests/CoreTests/]
  - SystemStateMonitor tests:
    - State transitions (active → idle → sleeping → active)
    - Notification handling (screen sleep/wake, system sleep/wake)
    - Battery detection (AC → battery → AC)
    - Idle threshold timing
  - AdaptiveRefreshManager tests:
    - Interval calculation for all states
    - Critical usage override (>90%)
    - Battery modifier behavior
    - Integration with settings toggle
  - UI tests for power indicators
  - Accessibility tests for new components
  - **Target:** 580+ total tests (28+ new)

- [ ] **Fix minor technical debt** [file: various]
  - Update ClaudeAPIClient user agent from "1.2.0" to current version
  - Add basic tests for NotificationPermissionManager (at least init, status)
  - Add basic tests for PlanType enum (rawValue, badgeText, displayName)
  - **Target:** 5+ additional tests

- [ ] **Update version and documentation** [file: various]
  - Update version to 1.7.0 in Info.plist
  - Update version constants in Domain, Services, Core, UI packages
  - Update CHANGELOG.md with Power-Aware Refresh feature
  - Update README.md features list if needed
  - Update specs/features/power-aware-refresh.md status to ✅ Implemented
  - **Success criteria:** 580+ tests passing, build green, docs accurate

---
<!-- CHECKPOINT: Phase 4 completes SLC 8. The app now optimizes for battery life. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 9: Visualization & Export
- **Historical Charts** - Sparkline usage visualization
  - 5-hour session history (5-min granularity)
  - 7-day weekly history (1-hour granularity)
  - **Research:** `specs/features/historical-charts.md`
- **Settings Export** - JSON export/import of settings
  - Backup, migration, team sharing
  - **Research:** `specs/features/settings-export.md`

### SLC 10: Terminal Integration
- **CLI Interface** - `claudeapp --status` for shell prompts
  - Multiple output formats (plain, json, minimal, verbose)
  - Starship/Oh My Zsh integration
  - Requires App Group for shared cache
  - **Research:** `specs/features/terminal-integration.md`

### Future (External Dependencies)
- **Multi-Account Support** - Monitor multiple Claude accounts
  - Complex, requires significant architecture changes
  - **Research:** `specs/features/multi-account.md`
- **Widgets** - macOS Notification Center widgets
  - Blocked by code signing requirement
  - **Research:** `specs/features/widgets.md`
- **Sparkle Auto-Updates** - Automatic update installation
  - Requires code signing
  - **Research:** `specs/sparkle-updates.md`

### Technical Debt Identified
- Burn rate thresholds hardcoded (10/25/50% per hour) - could be configurable
- Hysteresis buffer hardcoded (5%) - could be configurable
- No integration tests with mock network layer

---

## Implementation Notes

### SystemStateMonitor Key APIs

```swift
// Screen sleep/wake
NSWorkspace.screensDidSleepNotification
NSWorkspace.screensDidWakeNotification

// System sleep/wake
NSWorkspace.willSleepNotification
NSWorkspace.didWakeNotification

// Idle detection
CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)

// Battery detection
IOPSCopyPowerSourcesInfo()
IOPSCopyPowerSourcesList()
kIOPSPowerSourceStateKey / kIOPSBatteryPowerValue
```

### Refresh Interval Logic

```
effectiveInterval = switch (state, settings) {
    case (.sleeping, _):           .infinity  // Suspended
    case (.idle, battery: true):   userInterval * 2  // Save battery
    case (.idle, battery: false):  userInterval      // Normal when plugged in
    case (.active, usage >= 90%):  min(userInterval, 120)  // Critical monitoring
    case (.active, _):             userInterval      // Normal
}
```

### Expected Battery Savings

| Scenario | Without Optimization | With Optimization | Improvement |
|----------|---------------------|-------------------|-------------|
| Screen off (8h sleep) | 96 API calls | 0 API calls | 100% |
| Idle at desk (4h) | 48 API calls | 24 API calls | 50% |
| On battery, moderate use | 12 calls/hr | 6 calls/hr | 50% |
| Critical usage (>90%) | 6 calls/hr | 30 calls/hr | -400% (intentional) |

---

## Previous SLC Releases

### SLC 1: Usage Monitor - COMPLETE ✅
All tasks completed with 81 passing tests.

### SLC 2: Notifications & Settings - COMPLETE ✅
All tasks completed with 155 passing tests.

### SLC 3: Predictive Insights - COMPLETE ✅
All tasks completed with 320 passing tests.

### SLC 4: Distribution Ready - COMPLETE ✅
All tasks completed with 369 passing tests.

### SLC 5: Internationalization - COMPLETE ✅
All tasks completed with 402 passing tests.

### SLC 6: Advanced Accessibility - COMPLETE ✅
All tasks completed with 489 passing tests.

### SLC 7: Community Ready + Icon Styles - COMPLETE ✅
All tasks completed with 552 passing tests.

---

## Version History

| SLC | Name | Version | Tests | Status |
|-----|------|---------|-------|--------|
| 1 | Usage Monitor | 1.0.0 | 81 | COMPLETE |
| 2 | Notifications & Settings | 1.1.0 | 155 | COMPLETE |
| 3 | Predictive Insights | 1.2.0 | 320 | COMPLETE |
| 4 | Distribution Ready | 1.3.0 | 369 | COMPLETE |
| 5 | Internationalization | 1.4.0 | 402 | COMPLETE |
| 6 | Advanced Accessibility | 1.5.0 | 489 | COMPLETE |
| 7 | Community Ready + Icon Styles | 1.6.0 | 552 | COMPLETE |
| 8 | Power-Aware Refresh | 1.7.0 | 580+ | PLANNED |
