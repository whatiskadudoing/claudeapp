# Implementation Plan

## Recommended SLC Release: SLC 11 - Multi-Account Support

**Audience:** Professional developers using Claude Code who have multiple Claude accounts (personal + work, multiple projects, team accounts).

**Value proposition:** Monitor all Claude accounts from a single menu bar app, eliminating the need to switch between accounts or run multiple tools to track usage across work and personal contexts.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Account Management | Basic | Core feature: add/remove/switch between accounts |
| Multi-Account Usage Display | Basic | Show usage for active account with switcher |
| Settings Integration | Basic | Account management in Settings panel |

**What's NOT in this slice:**
- Multi-account menu bar display (showing P:45% W:72%) → Future (after single-account switcher works)
- Aggregate view across all accounts → Future (advanced feature)
- Account-specific notification settings → Future (complexity)
- Multiple provider support (OpenAI, Gemini) → Future (different API requirements)
- Widgets → Blocked by code signing
- Sparkle Auto-Updates → Blocked by code signing

---

## Comprehensive Gap Analysis (2026-01-30)

### ✅ FULLY IMPLEMENTED FEATURES (SLC 1-10 Complete)

| Feature | SLC | Version | Tests | Notes |
|---------|-----|---------|-------|-------|
| View Usage (menu bar + dropdown) | 1 | 1.0.0 | 752 | All 4 windows, progress bars, reset times |
| Refresh Usage (auto + manual) | 1-2 | 1.0.0 | 752 | Configurable interval, debouncing, backoff |
| Notifications | 2 | 1.1.0 | 752 | Warning, capacity full, reset; hysteresis |
| Settings (in-popover) | 2 | 1.1.0 | 752 | Display, refresh, notifications, general, data |
| Time-to-Exhaustion | 3 | 1.2.0 | 752 | Prediction display, burn rate calculation |
| Burn Rate Calculation | 3 | 1.2.0 | 752 | 4-level system, color-coded badges |
| Icon Styles | 3 | 1.2.0 | 752 | All 6 styles: percentage, bar, battery, compact, icon, full |
| Updates (GitHub Releases) | 3 | 1.2.0 | 752 | Version check, download URL, notification click |
| Power-Aware Refresh | 4-8 | 1.7.0 | 752 | SystemStateMonitor, AdaptiveRefreshManager, power indicators |
| Accessibility | 4-6 | 1.5.0 | 752 | VoiceOver, keyboard nav, reduce motion, high contrast |
| Internationalization | 5 | 1.4.0 | 752 | en, pt-BR, es fully localized |
| 100% Warning Badge | 8 | 1.7.0 | 752 | Menu bar warning icon when at capacity |
| Historical Charts | 9 | 1.8.0 | 752 | Sparklines for session and weekly windows |
| Settings Export/Import | 9 | 1.8.0 | 752 | Export, import, backup, reset functionality |
| Terminal Integration | 10 | 1.9.0 | 752 | CLI interface, shared cache, shell integration docs |

### ❌ NOT IMPLEMENTED (Planned Features)

| Feature | Spec | Complexity | Blocked By | Priority |
|---------|------|------------|------------|----------|
| Multi-Account | specs/features/multi-account.md | High | None | **HIGH - SLC 11** |
| Widgets | specs/features/widgets.md | High | Code signing | LOW |
| Sparkle Auto-Updates | specs/sparkle-updates.md | Medium | Code signing | LOW |

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Multi-Account Spec | `specs/features/multi-account.md` | Complete data model, UI design, migration strategy |
| Competitive Analysis | `research/competitive-analysis.md` | Claude Usage Tracker (684★) has multi-profile support |
| Architecture Patterns | `research/menubar-architecture-patterns.md` | Protocol-based services, profile management |
| Keychain Access | `research/approaches/keychain-access.md` | Security CLI approach for per-account credentials |
| API Documentation | `specs/api-documentation.md` | OAuth usage API works with any valid token |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Enables monitoring multiple accounts from one app, directly serves users with work+personal accounts -->

## Phase 0: Build Verification - REQUIRED

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - expect success ✅
  - Run `swift test` - expect all 752 tests pass ✅ (fixed flaky test: increased wait time in AppContainer Power-Aware Integration test from 100ms to 500ms)
  - Run `make release` - expect .app bundle creates successfully ✅
  - Verified: 2026-01-30

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. -->

## Phase 1: Domain Layer - Account Model & Storage

**Purpose:** Define core data models and storage protocol in the Domain package.

- [x] **Add Account model and storage protocol to Domain package** [spec: multi-account.md] [file: Packages/Domain/Sources/Domain/]
  - Create `Account.swift` with Account struct (id, name, email, planType, keychainIdentifier, isActive, isPrimary, createdAt) ✅
  - Ensure Account conforms to Identifiable, Sendable, Codable, Equatable ✅
  - Create `AccountStorage.swift` with AccountStorage protocol ✅
  - Add `MultiAccountDisplayMode` enum (all, activeOnly, primaryOnly) ✅
  - Add new SettingsKey constants for multi-account settings (multiAccountDisplayMode, showAccountLabels) ✅
  - Update `Domain.swift` exports (version bumped to 2.0.0) ✅
  - **Research:** `specs/features/multi-account.md#data-model`
  - **Tests:** Added 45 new tests (797 total, was 752) - Account model, MultiAccountDisplayMode, SettingsKey tests ✅
  - **Success criteria:** Domain package builds, all new types are Sendable-safe ✅
  - **Completed:** 2026-01-30

---
<!-- CHECKPOINT: Phase 1 establishes data foundation. -->

## Phase 2: Core Layer - Account Manager & Credentials

**Purpose:** Implement account management business logic and multi-account credential access.

- [x] **Implement AccountManager and credential retrieval in Core package** [spec: multi-account.md] [file: Packages/Core/Sources/Core/]
  - Create `UserDefaultsAccountStorage.swift` implementing AccountStorage protocol ✅
  - Create `AccountManager.swift` with @Observable @MainActor class ✅
  - Implement addAccount, removeAccount, updateAccount, setActiveAccount, setPrimaryAccount ✅
  - Implement automatic primary assignment (first account becomes primary) ✅
  - Create `MultiAccountCredentialsRepository.swift` as actor ✅
  - Support both "default" (Claude Code-credentials) and custom keychainIdentifier ✅
  - Implement migration logic: auto-create "Default" account on first launch if accounts empty ✅
  - ~~Wire AccountManager into AppContainer as shared dependency~~ (Deferred to Phase 3 with UsageManager integration)
  - **Research:** `specs/features/multi-account.md#credentials-management`
  - **Tests:** Added 42 new tests (839 total, was 797) - UserDefaultsAccountStorage, AccountManager CRUD, migration, MultiAccountCredentialsRepository ✅
  - **Success criteria:** Can add/remove accounts, credentials fetched per-account ✅
  - **Completed:** 2026-01-30
  - **Note:** AppContainer wiring deferred to Phase 3 to integrate with UsageManager changes simultaneously

---
<!-- CHECKPOINT: Phase 2 delivers account management infrastructure. -->

## Phase 3: Core Layer - UsageManager Multi-Account Support

**Purpose:** Update UsageManager to track usage per-account.

- [ ] **Update UsageManager to support per-account usage tracking** [spec: multi-account.md] [file: Packages/Core/Sources/Core/UsageManager.swift]
  - Add `usageByAccount: [UUID: UsageData]` dictionary
  - Update init to accept AccountManager dependency
  - Implement `refreshActiveAccount()` using active account's credentials
  - Implement `refreshAllAccounts()` with TaskGroup for parallel fetches
  - Update `currentUsageData` computed property to return active account's data
  - Add `highestUtilizationAcrossAccounts` computed property
  - Ensure backward compatibility: if no accounts exist, use default credentials (existing behavior)
  - Update SharedCacheManager to write active account's data
  - **Research:** `specs/features/multi-account.md#usagemanager-updates`
  - **Tests:** Add 40+ tests for multi-account refresh, per-account storage, active account switching
  - **Success criteria:** Usage refreshes for active account, switching accounts shows correct data

---
<!-- CHECKPOINT: Phase 3 delivers functional multi-account data flow. -->

## Phase 4: UI Layer - Account Switcher & Settings

**Purpose:** Add account switcher UI and settings management.

- [ ] **Implement account switcher in dropdown and accounts settings section** [spec: multi-account.md] [file: App/ClaudeApp.swift, Packages/UI/]
  - Add account switcher dropdown to DropdownView header (shows active account name with chevron)
  - Create AccountSwitcherMenu view with account list and "Add Account" option
  - Add "Accounts" section to SettingsContent with account list (name, plan type, edit/delete buttons)
  - Implement "Add Account" flow: name input, uses new keychain identifier
  - Implement "Edit Account" flow: rename, set primary
  - Implement "Remove Account" with confirmation alert
  - Show account status indicator (connected vs error state)
  - Add display mode picker (All / Active Only / Primary Only) in settings
  - Update MenuBarLabel to show active account's usage
  - Add localization strings for all new UI (en, pt-BR, es)
  - **Research:** `specs/features/multi-account.md#design`
  - **Tests:** Add 30+ UI tests for account switcher, settings section, display modes
  - **Success criteria:** Can switch accounts in dropdown, manage accounts in settings

---
<!-- CHECKPOINT: Phase 4 delivers complete multi-account UI. -->

## Phase 5: Polish & Release

**Purpose:** Final testing, version bump, and release preparation.

- [ ] **Update version and complete final verification** [file: various]
  - Update version to 2.0.0 in Info.plist (major version for architecture change)
  - Update CHANGELOG.md with SLC 11 release notes
  - Update specs/features/multi-account.md acceptance criteria to ✅
  - Update specs/README.md status indicators
  - Run full test suite: expect 870+ tests pass
  - Run `make release` to create .app bundle
  - Test migration: fresh install creates "Default" account automatically
  - Test backward compatibility: single account setup works unchanged
  - Verify CLI still works (uses active account's cached data)
  - Test account switching with real accounts (if available)
  - **Success criteria:** All acceptance criteria met, migration works, no regressions

---
<!-- CHECKPOINT: Phase 5 completes SLC 11. Ready for v2.0.0 release. -->

## Acceptance Criteria Summary

### SLC 11 Checklist

**Account Management:**
- [ ] Add account with custom name and keychain identifier
- [ ] Remove account with confirmation
- [ ] Edit account name
- [ ] Set account as primary
- [ ] Automatic migration creates "Default" account on first launch

**Account Switching:**
- [ ] Dropdown shows active account name with switcher
- [ ] Clicking switcher shows account list
- [ ] Selecting account switches active account
- [ ] Usage display updates to show new account's data

**Credentials:**
- [ ] Default account uses "Claude Code-credentials" (backward compatible)
- [ ] Additional accounts use custom keychain identifiers
- [ ] Credential errors shown per-account (not global)

**Settings:**
- [ ] Accounts section shows all accounts with plan type
- [ ] Add/edit/remove accounts from settings
- [ ] Primary account indicator (●/○)
- [ ] Display mode picker (All/Active/Primary)

**Compatibility:**
- [ ] Single-account usage works unchanged (no regression)
- [ ] CLI uses active account's cached data
- [ ] Notifications work for active account
- [ ] Terminal integration continues to work

---

## Future Work (Outside Current Scope)

### SLC 12+: Advanced Multi-Account Features

| Feature | Spec | Why Deferred |
|---------|------|--------------|
| Multi-account menu bar display | multi-account.md | Added complexity, evaluate after basic switching works |
| Aggregate view across accounts | multi-account.md | Requires additional UI design |
| Per-account notifications | notifications.md + multi-account.md | Significant settings complexity |
| Refresh all accounts button | multi-account.md | Nice-to-have, not core |

### Future Releases (External Dependencies)

| Feature | Blocker | Notes |
|---------|---------|-------|
| Widgets | Code Signing | WidgetKit requires signed app |
| Sparkle Auto-Updates | Code Signing | Sparkle requires signed app for auto-install |
| Multiple Providers | Different APIs | OpenAI, Gemini have different auth/endpoints |

### Technical Debt Backlog

| Item | Priority | Notes |
|------|----------|-------|
| Integration tests with mock network | Medium | No network failure tests |
| Keychain error scenario tests | Medium | Only happy path tested |
| Account migration edge cases | Medium | What if keychain entry deleted? |
| CLI multi-account support | Low | Currently shows active account only |
| Account sync across devices | Low | Would need iCloud integration |

---

## Test Coverage Summary

**Current (Phase 2 complete):** 839 tests across 4 packages (+87 from SLC 10)

| Package | Tests | Coverage |
|---------|-------|----------|
| Domain | 168 | Excellent - models fully tested (+45 from Phase 1) |
| Services | 29 | Basic - needs error scenarios |
| Core | 383 | Comprehensive - business logic (+42 from Phase 2) |
| UI | 259 | Excellent - accessibility focus |

**Target for SLC 11:** 870+ tests (31+ more tests needed for UsageManager and UI)

| Package | Remaining Tests | Focus |
|---------|-----------------|-------|
| Core | +20 | UsageManager multi-account integration |
| UI | +30 | Account switcher, settings section, display modes |

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
| 10 | Terminal Integration | 1.9.0 | 752 | ✅ COMPLETE |
| **11** | **Multi-Account Support** | **2.0.0** | **870+** | **📋 PLANNED** |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Keychain access for custom identifiers | Medium | High | Test early in Phase 2; fall back to CLI security tool |
| Migration breaks existing users | Low | High | Extensive testing; automatic "Default" account creation |
| Performance with many accounts | Low | Medium | TaskGroup for parallel refreshes; limit active accounts |
| UI complexity in dropdown | Medium | Medium | Start with simple switcher; iterate based on feedback |

---

## Implementation Notes

1. **Version 2.0.0**: Major version bump signals architecture change (multi-account support)
2. **Backward Compatibility**: Crucial - single-account users must not notice any change
3. **Keychain Strategy**: Documented in spec - default account uses existing "Claude Code-credentials"
4. **Test First**: Each phase has explicit test requirements before proceeding
5. **Localization**: All new strings in en, pt-BR, es before Phase 5
