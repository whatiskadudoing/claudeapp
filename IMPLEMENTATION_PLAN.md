# Implementation Plan

## Recommended SLC Release: Notifications & Settings (SLC 2)

**Audience:** Professional developers using Claude Code (Pro, Max 5x, Max 20x plans) who want proactive alerts before hitting limits and the ability to customize app behavior.

**Value proposition:** Never be surprised by rate limits. Get warned at 90% capacity, notified when limits reset, and customize everything to your workflow. The app now anticipates problems instead of just reporting status.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Notifications | Basic | Core value: proactive warnings before hitting limits (Job 3) |
| Settings | Basic | Required for notification config + customization (Job 7) |

**What's NOT in this slice:**
- Update checking (GitHub Releases API) → SLC 3
- Accessibility polish (VoiceOver, full keyboard nav) → SLC 3
- Distribution tooling (DMG, Homebrew, CI/CD) → SLC 3
- Quiet hours for notifications → Future
- Notification history view → Future
- Export/import settings → Future

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| System Notifications | `research/approaches/system-notifications.md` | UNUserNotificationCenter patterns, hysteresis logic |
| Launch at Login | `research/approaches/launch-at-login.md` | SMAppService implementation |
| Design System | `specs/design-system.md` | Settings UI components, colors, typography |
| Notifications Spec | `specs/features/notifications.md` | Notification types, trigger logic, acceptance criteria |
| Settings Spec | `specs/features/settings.md` | Settings categories, UI design, persistence patterns |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Users get proactive warnings before hitting limits (the #1 pain point),
     can customize thresholds, and configure the app to their workflow. This transforms
     ClaudeApp from a passive monitor into an active assistant. -->

## Phase 1: Settings Infrastructure - CRITICAL

Build the settings persistence layer and UI foundation that notifications will depend on.

- [x] **Implement SettingsManager with @Observable state and UserDefaults persistence** [spec: features/settings.md] [file: Packages/Core/Sources/Core/]
  - Create `SettingsKey<Value>` struct for type-safe settings access
  - Create `PercentageSource` enum (highest, session, weekly, opus, sonnet)
  - Create `@MainActor @Observable class SettingsManager` with all settings properties
  - Implement UserDefaults persistence with automatic save on property change
  - Settings: showPlanBadge, showPercentage, percentageSource, refreshInterval, notificationsEnabled, warningThreshold (50-99), warningEnabled, capacityFullEnabled, resetCompleteEnabled, launchAtLogin
  - Include protocol `SettingsRepository` for testability
  - **Research:** `specs/features/settings.md` for settings keys and defaults
  - **Design:** Use `@AppStorage` pattern documented in spec
  - **Completed:** Created `PercentageSource` enum, `SettingsKey<T>` struct, `SettingsRepository` protocol in Domain; `SettingsManager` and `UserDefaultsSettingsRepository` in Core; 17 new tests (98 total passing)

- [x] **Implement LaunchAtLoginManager using SMAppService** [spec: features/settings.md] [file: Packages/Core/Sources/Core/]
  - Create `@MainActor class LaunchAtLoginManager` with `isEnabled` computed property
  - Use `SMAppService.mainApp.register()` and `unregister()`
  - Handle status states: notRegistered, enabled, requiresApproval
  - Revert `isEnabled` on registration failure
  - **Research:** `research/approaches/launch-at-login.md` for implementation pattern
  - **Note:** Requires `import ServiceManagement`
  - **Completed:** Created `LaunchAtLoginManager` with `LaunchAtLoginService` protocol for testability, `isEnabled` property with auto-register/unregister, `refreshStatus()` for syncing with system state, `statusDescription` and `requiresUserApproval` helpers, error handling with revert logic; 17 new tests added (115 total passing)

- [x] **Build Settings window with all sections** [spec: features/settings.md, design-system.md] [file: App/]
  - Create `SettingsView` as a 320x500pt window with scrollable content
  - Sections: DISPLAY, REFRESH, NOTIFICATIONS, GENERAL, ABOUT
  - DISPLAY: showPlanBadge toggle, showPercentage toggle, percentageSource picker
  - REFRESH: refreshInterval slider (1-30 min) with min/max labels
  - NOTIFICATIONS: master toggle, warningThreshold slider (50-99%), individual toggles
  - GENERAL: launchAtLogin toggle
  - ABOUT: App icon, version, "Check for Updates" button (placeholder), GitHub link
  - Add Settings button (gear icon) to dropdown header
  - Open settings in a separate window (not in dropdown)
  - **Research:** `specs/design-system.md` for component styles, spacing, typography
  - **Design:** Use SectionHeader component, SettingsToggle component for consistency
  - **Completed:** Created full SettingsView with all sections in App/ClaudeApp.swift; Added SettingsButton to dropdown header; Settings window opens via SwiftUI Window scene with Cmd+, shortcut; Added SettingsManager and LaunchAtLoginManager to AppContainer with proper environment injection; Added restartAutoRefresh method to UsageManager; All 115 tests passing

- [x] **Connect settings to existing UI (menu bar display + refresh interval)** [spec: features/settings.md] [file: App/ClaudeApp.swift]
  - Update MenuBarLabel to respect showPercentage, percentageSource settings
  - Add plan badge display when showPlanBadge is true
  - Update UsageManager to read refreshInterval from SettingsManager
  - Restart auto-refresh when refreshInterval changes
  - Inject SettingsManager via SwiftUI Environment alongside UsageManager
  - **Note:** Menu bar should update live when settings change
  - **Completed:** MenuBarLabel now respects showPercentage, percentageSource, and showPlanBadge settings; Added utilization(for:) method to UsageData for source selection; Plan badge shows placeholder "Pro" (actual plan detection requires API support); Refresh interval already connected via onRefreshIntervalChanged callback in previous task; 3 new tests added (118 total passing)

---
<!-- CHECKPOINT: Phase 1 delivers configurable settings. Verify settings persist across restarts, menu bar updates with settings, refresh interval changes take effect. -->

## Phase 2: Notification System

Implement proactive notifications for usage warnings, capacity full, and reset complete.

- [x] **Implement NotificationManager actor with permission handling** [spec: features/notifications.md] [file: Packages/Core/Sources/Core/]
  - Create `actor NotificationManager` for thread-safe notification handling
  - Method: `requestPermission() async -> Bool` using UNUserNotificationCenter
  - Method: `checkPermissionStatus() async -> UNAuthorizationStatus`
  - Method: `send(title:body:identifier:) async` for immediate notification delivery
  - Track `hasRequestedPermission` to avoid repeated prompts
  - Track notification state per identifier to prevent duplicates within cycle
  - Method: `resetState(for identifier: String)` to clear notification state
  - **Research:** `research/approaches/system-notifications.md` for implementation patterns
  - **Note:** Request permission when user first enables notifications in settings
  - **Completed:** Created `NotificationService` protocol for testability (allows mocking UNUserNotificationCenter); Created `actor NotificationManager` with permission handling (tracks `hasRequestedPermission`), duplicate notification prevention per identifier, and hysteresis support via `resetState(for:)` and `resetAllStates()`; Added `hasNotified(for:)` helper method; Added `removeDelivered(identifiers:)` method; 14 new tests added (132 total passing)

- [ ] **Implement notification trigger logic with hysteresis** [spec: features/notifications.md] [file: Packages/Core/Sources/Core/]
  - Create `UsageNotificationChecker` class that evaluates usage changes
  - Inject: NotificationManager, SettingsManager
  - Method: `check(current: UsageData, previous: UsageData?) async`
  - Usage Warning: fires when utilization crosses warningThreshold from below
  - Capacity Full: fires when utilization hits 100% (was below 100%)
  - Reset Complete: fires when 7-day drops from >50% to <10%
  - Implement 5% hysteresis: reset notification state when util drops below (threshold - 5%)
  - Respect individual notification toggles from settings
  - Include reset time in notification body when available
  - **Research:** `specs/features/notifications.md` for trigger logic pseudocode
  - **Design:** Notification identifiers: "usage-warning-{window}", "capacity-full-{window}", "reset-complete"

- [ ] **Integrate notifications into UsageManager refresh cycle** [spec: features/notifications.md] [file: Packages/Core/Sources/Core/UsageManager.swift, App/]
  - Add `previousUsageData: UsageData?` property to UsageManager
  - After successful refresh, call `UsageNotificationChecker.check(current:previous:)`
  - Store current as previous after notification check
  - Add NotificationManager to AppContainer dependency injection
  - Request notification permission on app launch if notifications enabled in settings
  - Add UNUserNotificationCenterDelegate to handle notification clicks (open dropdown)
  - **Note:** Only check notifications when notificationsEnabled is true

- [ ] **Add notification permission UI and denied state handling** [spec: features/notifications.md] [file: App/]
  - In Settings NOTIFICATIONS section, show permission status
  - If denied: show warning banner with "Open System Settings" button
  - Use `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)`
  - Disable notification toggles when permission denied
  - Re-check permission status when settings window opens
  - **Research:** `specs/features/notifications.md` for permission denied UI mockup

---
<!-- CHECKPOINT: Phase 2 delivers proactive notifications. Test: enable notifications, set threshold to 50%, verify warning fires when crossing threshold, verify hysteresis prevents spam, verify reset notification when weekly drops. -->

## Phase 3: Polish & Testing

Complete the feature with tests, edge cases, and UI polish.

- [ ] **Add comprehensive tests for Settings and Notifications** [file: Tests/]
  - SettingsManager tests: persistence, defaults, type safety, refresh interval changes
  - LaunchAtLoginManager tests: mock SMAppService, status handling
  - NotificationManager tests: permission flow, send, state tracking, reset
  - UsageNotificationChecker tests: threshold crossing, hysteresis (5%), reset detection
  - Integration test: settings change → notification behavior change
  - Target: maintain 80%+ test coverage for new code
  - **Note:** Use protocol-based mocking for UNUserNotificationCenter and SMAppService

- [ ] **Implement settings button and window lifecycle** [file: App/]
  - Settings gear button in dropdown header (next to refresh button)
  - Open settings in separate NSWindow (not replacing dropdown content)
  - Single settings window instance (bring to front if already open)
  - Close dropdown when settings opens
  - Handle window close gracefully
  - Keyboard shortcut: Cmd+, to open settings
  - **Design:** Use `NSApp.keyWindow` / `NSWindow` for settings window management

---
<!-- CHECKPOINT: Phase 3 completes SLC 2. The app now warns before limits, lets users customize everything, and starts at login. All features have test coverage. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 3: Distribution & Accessibility
- Update checking via GitHub Releases API (manual + auto-check on launch)
- Full accessibility audit (VoiceOver labels, keyboard navigation, focus states)
- Homebrew Cask formula for easy installation
- DMG creation script with code signing
- CI/CD pipeline with GitHub Actions
- **Research:** `research/apis/github-releases.md`, `specs/accessibility.md`, `specs/toolchain.md`

### Future Releases
- Quiet hours setting (pause notifications during focus time)
- Notification history view
- Export/import settings
- Different sounds per notification type
- Custom app icon (replace SF symbol placeholder)
- Internationalization (multiple languages)
- Local JSONL fallback when API unavailable
- Historical usage trends visualization
- Widget support for Notification Center
- **Research:** `specs/internationalization.md`, `specs/features/updates.md`

### Technical Debt Identified
- UI package is minimal (10 lines) - consider moving shared UI components there
- No UI tests - add snapshot tests for visual regression
- No integration tests with mock network layer
- Missing custom Claude brand icon (using SF symbol "sparkle" placeholder)

---

## Implementation Notes

### Settings Persistence Strategy (from specs/features/settings.md)
- Use `UserDefaults` with `@AppStorage` for SwiftUI binding where possible
- Use `SettingsManager` @Observable class for complex settings logic
- Settings keys are typed via `SettingsKey<T>` for compile-time safety
- All settings persist immediately on change (no "Save" button needed)

### Notification Hysteresis (from specs/features/notifications.md)
- Purpose: Prevent notification spam when utilization hovers around threshold
- Implementation: 5% buffer below threshold
- Example: If threshold is 90%, warning fires at 90%. State resets when util drops below 85%.
- Each usage window has independent notification state

### Launch at Login (from research/approaches/launch-at-login.md)
- Use SMAppService.mainApp (macOS 13+, we target 14+)
- Status can be: notRegistered, enabled, requiresApproval, notFound
- Handle requiresApproval by prompting user to check System Settings
- Always check status before showing toggle state (can change externally)

### Design Tokens (from specs/design-system.md)
- Primary color: #C15F3C (Crail)
- Success: #22C55E (green) - low usage
- Warning: #EAB308 (yellow) - medium usage
- Danger: #C15F3C (red) - high usage
- Spacing: xs=4, sm=8, md=12, lg=16, xl=24
- Corner radius: sm=4, md=8, lg=12
- Settings window: 320pt wide, 500pt tall

### Performance Targets (from specs/performance.md)
- Memory: < 15 MB idle, < 25 MB active
- CPU: < 0.1% idle, < 2% during refresh
- Notifications should not impact these targets significantly
- Settings window should load instantly (<100ms)

---

## Previous SLC Releases

### SLC 1: Usage Monitor ✅ COMPLETE

All tasks completed with 81 passing tests.

**Phase 1: Project Foundation** ✅
- [x] Initialize Swift Package project with modular architecture
- [x] Implement Domain models and protocols
- [x] Implement Keychain credentials repository
- [x] Implement Claude API client

**Phase 2: Menu Bar UI** ✅
- [x] Create menu bar app entry point with MenuBarExtra
- [x] Implement UsageManager with @Observable state
- [x] Build menu bar label view
- [x] Build dropdown view with usage bars

**Phase 3: Refresh & Polish** ✅
- [x] Implement auto-refresh lifecycle with exponential backoff
- [x] Implement manual refresh with button states
- [x] Implement error and loading states with stale data display
