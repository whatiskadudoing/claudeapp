# Implementation Plan

## Recommended SLC Release: SLC 8 Completion + Polish

**Audience:** Professional developers using Claude Code who run ClaudeApp continuously throughout their workday, demanding passive usage monitoring with zero workflow interruption.

**Value proposition:** Complete the Power-Aware Refresh feature by adding visual power state indicators and polish the existing implementation to deliver a production-ready v1.7.0 release with measurable battery savings.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Power State Indicator | Basic | Complete user visibility into power-aware state |
| Burn Rate Badge in Header | Basic | Show consumption velocity prominently |
| Update Notification Click | Basic | Fix broken user flow for updates |
| Technical Debt Cleanup | Basic | Improve reliability and maintainability |

**What's NOT in this slice:**
- Historical Charts → SLC 9 (visual enhancement, not core)
- Settings Export → SLC 9 (power user feature)
- Terminal Integration → SLC 10 (requires App Group, CLI work)
- Multi-Account → Future (complex architecture changes)
- Widgets → Future (blocked by code signing)
- Sparkle Auto-Updates → Future (requires code signing)

---

## Comprehensive Gap Analysis (2026-01-30)

### ✅ FULLY IMPLEMENTED FEATURES

| Feature | SLC | Status | Tests | Notes |
|---------|-----|--------|-------|-------|
| View Usage (menu bar + dropdown) | 1 | ✅ | 81 | All 4 windows, progress bars, reset times |
| Refresh Usage (auto + manual) | 1-2 | ✅ | 155 | Configurable interval, debouncing, backoff |
| Notifications | 2 | ✅ | 320 | Warning, capacity full, reset; hysteresis |
| Settings (in-popover) | 2 | ✅ | 369 | Display, refresh, notifications, general |
| Time-to-Exhaustion | 3 | ✅ | 402 | Prediction display, burn rate calculation |
| Burn Rate Calculation | 3 | ✅ | 489 | 4-level system, color-coded badges |
| Icon Styles | 3 | ✅ | 552 | All 6 styles: percentage, bar, battery, compact, icon, full |
| Power-Aware Refresh (core) | 4 | ✅ | 613 | SystemStateMonitor, AdaptiveRefreshManager |
| Settings UI (smart refresh) | 4 | ✅ | 613 | Smart Refresh toggle, Reduce on Battery |
| Updates (GitHub Releases) | 3 | ✅ | 613 | Version check, download URL, notification |
| Accessibility | 4-6 | ✅ | 613 | VoiceOver, keyboard nav, reduce motion, high contrast, dynamic type |
| Internationalization | 5 | ✅ | 613 | en, pt-BR, es fully localized |

### ⚠️ PARTIALLY IMPLEMENTED (Gaps Identified)

| Feature | Gap | Impact | Effort |
|---------|-----|--------|--------|
| **Burn Rate Badge in Header** | Component exists but NOT displayed in dropdown header | HIGH - Key visibility feature | Small |
| **Power State Indicator** | No visual indicator in dropdown footer for battery/idle | MEDIUM - User doesn't know when power-aware is active | Small |
| **Update Notification Click** | Click doesn't open download URL, only activates app | MEDIUM - Broken user flow | Small |
| **Escape Key to Close** | MenuBarExtra limitation, no escape handler | LOW - Minor UX issue | Small |
| **100% Warning Badge** | No menu bar badge when at capacity | LOW - Nice to have | Small |
| **Dynamic Sizing** | Fixed 300px width instead of content-based | LOW - Design choice | N/A |

### ❌ NOT IMPLEMENTED (Future SLC Releases)

| Feature | Spec | Complexity | Blocked By |
|---------|------|------------|------------|
| Historical Charts | specs/features/historical-charts.md | Medium | None |
| Settings Export/Import | specs/features/settings-export.md | Medium | None |
| Terminal Integration | specs/features/terminal-integration.md | High | App Group setup |
| Multi-Account | specs/features/multi-account.md | High | Architecture changes |
| Widgets | specs/features/widgets.md | High | Code signing |
| Sparkle Auto-Updates | specs/sparkle-updates.md | Medium | Code signing |

### 🔧 Technical Debt

| Item | Priority | Location | Notes |
|------|----------|----------|-------|
| Update repo owner/name hardcoded | HIGH | UpdateChecker.swift | Uses placeholder values |
| User agent version mismatch | LOW | ClaudeAPIClient.swift | Shows "1.2.0" vs actual |
| No persistent lastCheckDate | LOW | UpdateChecker.swift | Rate limit resets on restart |
| PlanType detection stub | LOW | ClaudeApp.swift:236 | Hardcoded badge |
| isStale hardcoded 60s | LOW | UsageManager.swift | Should use refresh interval |

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Power-Aware Spec | `specs/features/power-aware-refresh.md` | Power state indicator design |
| View Usage Spec | `specs/features/view-usage.md` | Burn rate badge placement |
| Updates Spec | `specs/features/updates.md` | Notification click handling |
| Competitive Analysis | `research/competitive-analysis.md` | Feature parity reference |
| API Documentation | `research/apis/anthropic-oauth.md` | Response schemas |
| Keychain Access | `research/approaches/keychain-access.md` | Auth patterns |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Completes SLC 8 and delivers polished v1.7.0 -->

## Phase 0: Build Verification - REQUIRED

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - must succeed ✅
  - Run `swift test` - all 613 tests must pass ✅
  - **Verified:** 2026-01-28 - Build green, 613 tests passing

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. -->

## Phase 1: Complete Power-Aware UI - CRITICAL

**Purpose:** Finish the power-aware refresh feature with visual indicators.

- [x] **Add power state indicator to dropdown footer** [spec: power-aware-refresh.md] [file: App/ClaudeApp.swift]
  - ✅ Created `PowerStateIndicator` view showing current power state
  - ✅ Shows battery icon (`battery.50`) when on battery power
  - ✅ Shows moon icon (`moon.zzz`) when in idle state
  - ✅ Displays in dropdown footer near "Updated X ago" text
  - ✅ Only shows when power-aware refresh is enabled
  - ✅ Added accessibility labels for VoiceOver
  - ✅ Added localization strings in en, es, pt-BR: `accessibility.powerState.onBattery`, `accessibility.powerState.idle`
  - **Completed:** 2026-01-30
  - **Note:** Also fixed 8 pre-existing broken tests from KOSMA redesign (DiagonalStripes removed, Theme values changed)
  - **Tests:** 605 tests passing (was 613, some tests removed with DiagonalStripes)

- [x] **Integrate burn rate badge into dropdown header** [spec: view-usage.md] [file: App/ClaudeApp.swift]
  - ✅ Added header row with "CLAUDE USAGE" title in KOSMA uppercase styling
  - ✅ Display `BurnRateBadge` in header next to title (only when data available)
  - ✅ Use `usageManager.overallBurnRateLevel` for badge level
  - ✅ Added `headerAccessibilityLabel` computed property for VoiceOver support
  - ✅ Layout matches KOSMA design system with proper spacing and styling
  - **Completed:** 2026-01-30
  - **Tests:** 605 tests passing (existing BurnRateBadge and overallBurnRateLevel tests cover component behavior)

---
<!-- CHECKPOINT: Phase 1 delivers visual feedback for power state and burn rate. -->

## Phase 2: Update Flow Fix

**Purpose:** Fix the broken update notification click handling.

- [x] **Fix notification click to open download URL** [spec: updates.md] [file: App/ClaudeApp.swift]
  - ✅ Added `userInfo` parameter to `NotificationManager.send()` method
  - ✅ Updated `checkForUpdatesInBackground()` to pass download URL in userInfo
  - ✅ Updated `NotificationDelegate.didReceive()` to check for update notifications and open download URL
  - ✅ Maintains existing behavior (activate app) for all notification types
  - ✅ Added 4 new tests for userInfo functionality
  - **Completed:** 2026-01-30
  - **Tests:** 609 tests passing (was 605, +4 new userInfo tests)

- [x] **Configure actual GitHub repository in UpdateChecker** [file: Packages/Core/Sources/Core/UpdateChecker.swift]
  - ✅ Changed `repoOwner` default from "yourname" to "whatiskadudoing"
  - ✅ Repo name "claudeapp" was already correct
  - **Completed:** 2026-01-30
  - **Impact:** Auto-update checks will now work against correct repo (whatiskadudoing/claudeapp)
  - **Tests:** 609 tests passing (no changes to tests needed)

---
<!-- CHECKPOINT: Phase 2 fixes the update user flow. -->

## Phase 3: Polish & Technical Debt

**Purpose:** Clean up minor issues and prepare for release.

- [ ] **Fix user agent version in ClaudeAPIClient** [file: Packages/Services/Sources/Services/ClaudeAPIClient.swift]
  - Update hardcoded "1.2.0" to read from Bundle.appVersion
  - Or: Define version constant in Domain package for consistency
  - **Impact:** API requests will report correct version
  - **Target:** No new tests needed (behavior verification)

- [ ] **Add menu bar warning indicator at 100%** [spec: view-usage.md] [file: App/ClaudeApp.swift]
  - Modify `MenuBarLabel` to show warning icon when any window at 100%
  - Display format: `[✦] 100% ⚠️` or just add subtle indicator
  - Use SF Symbol `exclamationmark.triangle.fill`
  - **Research:** `specs/features/view-usage.md` "Display badge when any limit at 100%"
  - **Test:** Visual verification at 100% utilization
  - **Target:** 2+ new tests (627+ total)

- [ ] **Persist UpdateChecker lastCheckDate across restarts** [file: Packages/Core/Sources/Core/UpdateChecker.swift]
  - Save `lastCheckDate` to UserDefaults on successful check
  - Load on init to maintain 24-hour rate limit across app restarts
  - Use SettingsRepository pattern for consistency
  - **Impact:** Won't re-check immediately after restart
  - **Target:** 2+ new tests (629+ total)

---
<!-- CHECKPOINT: Phase 3 completes polish items. -->

## Phase 4: Documentation & Release

**Purpose:** Update documentation and prepare v1.7.0 release.

- [ ] **Update version numbers** [file: various]
  - Update version to 1.7.0 in Info.plist
  - Update CHANGELOG.md with SLC 8 features
  - Update specs/features/power-aware-refresh.md status to ✅ Implemented
  - **Success criteria:** Version displays correctly in About section

- [ ] **Final verification** [file: Makefile]
  - Run full test suite: 629+ tests passing
  - Run `make release` to create .app bundle
  - Manual verification of all new features
  - **Success criteria:** All acceptance criteria met

---
<!-- CHECKPOINT: Phase 4 completes SLC 8. Ready for v1.7.0 release. -->

## Acceptance Criteria Summary

### SLC 8 Completion Checklist

**Power-Aware Refresh (from existing plan):**
- [x] Suspend refresh when screen is off/locked
- [x] Resume refresh immediately on wake
- [x] Respect user's refresh interval setting
- [x] Toggle to enable/disable power-aware refresh
- [x] Reduce refresh frequency when idle
- [x] Reduce refresh frequency on battery
- [x] Increase frequency for critical usage (>90%)
- [x] **NEW:** Show power state indicator in footer (battery/idle icons) ✅ 2026-01-30

**Burn Rate Display:**
- [x] Burn rate badge component with 4 levels
- [x] Color-coded for accessibility (shapes + colors)
- [x] Calculate from highest burn rate across windows
- [x] **NEW:** Display badge in dropdown header ✅ 2026-01-30

**Update Flow:**
- [x] Check for updates via GitHub Releases
- [x] Show notification when update available
- [x] **NEW:** Notification click opens download URL ✅ 2026-01-30

**Polish:**
- [ ] Fix user agent version string
- [ ] Add 100% warning indicator in menu bar
- [ ] Persist update check date across restarts

---

## Future Work (Outside Current Scope)

### SLC 9: Visualization & Export (Recommended Next)

**Value:** Enable users to see usage patterns over time and backup settings.

| Feature | Spec | Why Deferred |
|---------|------|--------------|
| **Historical Charts** | specs/features/historical-charts.md | Visual enhancement, not core monitoring |
| **Settings Export** | specs/features/settings-export.md | Power user feature, not critical path |

**Prerequisites:**
- Add Swift Charts dependency (or DSFSparkline)
- Create UsageHistoryManager for data persistence
- Implement file picker dialogs

### SLC 10: Terminal Integration

**Value:** Enable usage monitoring from CLI and shell prompts.

| Feature | Spec | Why Deferred |
|---------|------|--------------|
| **CLI Interface** | specs/features/terminal-integration.md | Requires App Group, ArgumentParser |

**Prerequisites:**
- Add ArgumentParser dependency
- Set up App Group for shared UserDefaults
- Create ClaudeAppCLI command structure

### Future Releases (External Dependencies)

| Feature | Blocker | Notes |
|---------|---------|-------|
| Multi-Account | Architecture | Requires significant refactoring |
| Widgets | Code Signing | WidgetKit requires signed app |
| Sparkle Auto-Updates | Code Signing | Sparkle requires signed app |

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

**Current:** 609 tests across 4 packages

| Package | Tests | Coverage |
|---------|-------|----------|
| Domain | 81 | Excellent - models fully tested |
| Services | 29 | Basic - needs error scenarios |
| Core | 266 | Comprehensive - business logic (+4 userInfo tests) |
| UI | 233 | Excellent - accessibility focus |

**Target for SLC 8:** 620+ tests (adjusted after cleanup)

**Coverage Gaps to Address in Future:**
- API error response handling (401, 429, 500)
- Keychain permission denied scenarios
- Network timeout/retry logic
- End-to-end integration tests

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
| 8 | Power-Aware Refresh | 1.7.0 | 629+ | 🔄 IN PROGRESS (75%) |
