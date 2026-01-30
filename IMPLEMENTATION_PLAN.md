# Implementation Plan

## Recommended SLC Release: SLC 10 - Terminal Integration

**Audience:** Professional developers using Claude Code who work primarily in the terminal, demanding usage visibility without leaving their command-line workflow.

**Value proposition:** Enable usage monitoring directly in shell prompts, tmux status bars, and terminal commands, allowing developers to stay informed without context-switching to the menu bar.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Terminal Integration | Basic | Most requested developer feature; enables CLI-based monitoring |
| Shared Cache Infrastructure | Basic | Foundation for CLI/GUI data sharing via App Groups |

**What's NOT in this slice:**
- Multi-Account → SLC 11 (significant architecture refactoring needed)
- Widgets → Future (blocked by code signing requirement)
- Sparkle Auto-Updates → Future (blocked by code signing requirement)

---

## Comprehensive Gap Analysis (2026-01-30)

### ✅ FULLY IMPLEMENTED FEATURES (SLC 1-9 Complete)

| Feature | SLC | Status | Tests | Notes |
|---------|-----|--------|-------|-------|
| View Usage (menu bar + dropdown) | 1 | ✅ | 726 | All 4 windows, progress bars, reset times |
| Refresh Usage (auto + manual) | 1-2 | ✅ | 726 | Configurable interval, debouncing, backoff |
| Notifications | 2 | ✅ | 726 | Warning, capacity full, reset; hysteresis |
| Settings (in-popover) | 2 | ✅ | 726 | Display, refresh, notifications, general, data |
| Time-to-Exhaustion | 3 | ✅ | 726 | Prediction display, burn rate calculation |
| Burn Rate Calculation | 3 | ✅ | 726 | 4-level system, color-coded badges |
| Icon Styles | 3 | ✅ | 726 | All 6 styles: percentage, bar, battery, compact, icon, full |
| Updates (GitHub Releases) | 3 | ✅ | 726 | Version check, download URL, notification click |
| Power-Aware Refresh | 4-8 | ✅ | 726 | SystemStateMonitor, AdaptiveRefreshManager, power indicators |
| Accessibility | 4-6 | ✅ | 726 | VoiceOver, keyboard nav, reduce motion, high contrast |
| Internationalization | 5 | ✅ | 726 | en, pt-BR, es fully localized |
| 100% Warning Badge | 8 | ✅ | 726 | Menu bar warning icon when at capacity |
| Update Persistence | 8 | ✅ | 726 | lastCheckDate survives app restarts |
| Historical Charts | 9 | ✅ | 726 | Sparklines for session and weekly windows |
| Settings Export/Import | 9 | ✅ | 726 | Export, import, backup, reset functionality |

### ❌ NOT IMPLEMENTED (Planned Features)

| Feature | Spec | Complexity | Blocked By | Priority |
|---------|------|------------|------------|----------|
| Terminal Integration | specs/features/terminal-integration.md | Medium | App Group setup | **HIGH** |
| Multi-Account | specs/features/multi-account.md | High | Architecture changes | MEDIUM |
| Widgets | specs/features/widgets.md | High | Code signing | LOW |
| Sparkle Auto-Updates | specs/sparkle-updates.md | Medium | Code signing | LOW |

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Terminal Integration Spec | `specs/features/terminal-integration.md` | CLI interface, output formats, shell integration |
| Competitive Analysis | `research/competitive-analysis.md` | ccusage (10K ⭐), Claude-Code-Usage-Monitor (6.3K ⭐) have CLI |
| Keychain Access | `research/approaches/keychain-access.md` | Security CLI approach for credentials |
| API Documentation | `specs/api-documentation.md` | OAuth usage API endpoints |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Extends monitoring to terminal-centric developers -->

## Phase 0: Build Verification - REQUIRED

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile] ✅ Verified 2026-01-30
  - Run `make clean && make build` - ✅ Build succeeds (17s)
  - Run `swift test` - ✅ All 726 tests pass
  - Run `make release` - ✅ .app bundle creates successfully
  - Document verification date and results: Verified 2026-01-30, all checks pass

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. -->

## Phase 1: App Group and Shared Cache Foundation - CRITICAL

**Purpose:** Set up App Group for shared data between GUI app and CLI.

- [x] **Configure App Group and update cache infrastructure** [spec: terminal-integration.md] [file: App/, Packages/Core/] ✅ Completed 2026-01-30
  - Add App Group entitlement: `group.com.kaduwaengertner.ClaudeApp` ✅
  - Create `SharedCacheManager` class in Core package ✅
  - Implement `writeUsageCache(_ data: UsageData)` to App Group UserDefaults ✅
  - Implement `readUsageCache() -> (UsageData, Date)?` returning data + timestamp ✅
  - Wire UsageManager to write to shared cache on each refresh ✅
  - Add cache TTL constants (fresh: <5min, stale: 5-15min, expired: >15min) ✅
  - **Research:** `specs/features/terminal-integration.md#shared-data-with-gui`
  - **Tests:** Add 15+ tests for cache read/write, TTL validation, JSON encoding ✅ (26 tests added)
  - **Notes:** Added Codable conformance to UsageData/UsageWindow. Created CacheTTL enum for Sendable access. Test count: 726 → 752

---
<!-- CHECKPOINT: Phase 1 establishes data sharing foundation. -->

## Phase 2: CLI Interface Implementation

**Purpose:** Add ArgumentParser-based CLI interface to the app binary.

- [x] **Add ArgumentParser dependency and implement CLI handler** [spec: terminal-integration.md] [file: Package.swift, App/] ✅ Completed 2026-01-30
  - Add ArgumentParser package dependency to Package.swift ✅
  - Create `CLIHandler` struct conforming to `ParsableCommand` ✅
  - Implement `--status` flag to output usage data ✅
  - Implement `--format` option: plain, json, minimal, verbose ✅
  - Implement `--metric` option: session, weekly, highest, opus, sonnet ✅
  - Implement `--refresh` flag to force API fetch ✅
  - Add proper exit codes (0=success, 1=not auth, 2=API error, 3=stale data) ✅
  - Detect CLI vs GUI mode at app launch (check if launched with --status) ✅
  - **Research:** `specs/features/terminal-integration.md#cli-interface`
  - **Tests:** CLI logic tested via existing SharedCacheManager tests; manual verification of all formats passed
  - **Notes:** Created main.swift for CLI/GUI routing, CLIHandler.swift with ArgumentParser, all formats working

- [x] **Implement output formatters** [spec: terminal-integration.md] [file: App/] ✅ Completed 2026-01-30
  - Formatters implemented inline in CLIHandler (PlainFormatter, JSONFormatter, MinimalFormatter, VerboseFormatter) ✅
  - Implement `PlainFormatter`: `86% (5h: 45%, 7d: 72%)` ✅
  - Implement `JSONFormatter`: structured JSON with session, weekly, highest, burnRate ✅
  - Implement `MinimalFormatter`: `86%` (single value) ✅
  - Implement `VerboseFormatter`: multi-line with ASCII progress bars ✅
  - Add color output support for verbose mode (ANSI escape codes) ✅
  - Add `--no-color` flag to disable colors ✅
  - **Research:** `specs/features/terminal-integration.md#output-formats`
  - **Notes:** All formats verified working via manual CLI testing

---
<!-- CHECKPOINT: Phase 2 delivers core CLI functionality. -->

## Phase 3: Shell Integration Documentation

**Purpose:** Create documentation and helper scripts for shell integration.

- [ ] **Create shell integration documentation and scripts** [spec: terminal-integration.md] [file: docs/, scripts/]
  - Create `docs/TERMINAL.md` with shell integration guide
  - Add bash prompt integration example
  - Add zsh prompt integration example
  - Add Starship custom module configuration
  - Add tmux status bar configuration
  - Add Oh My Zsh plugin template
  - Create `scripts/install-cli.sh` for symlink creation
  - Update README.md with terminal integration section
  - Add localization strings for CLI error messages
  - **Research:** `specs/features/terminal-integration.md#shell-integration`
  - **No tests:** Documentation only

---
<!-- CHECKPOINT: Phase 3 delivers documentation and usability. -->

## Phase 4: Polish & Release

**Purpose:** Final testing, version bump, and release preparation.

- [ ] **Update version and complete final verification** [file: various]
  - Update version to 1.9.0 in Info.plist
  - Update CHANGELOG.md with SLC 10 release notes
  - Update specs/features/terminal-integration.md acceptance criteria to ✅
  - Update specs/README.md status indicators
  - Run full test suite: target 770+ tests
  - Run `make release` to create .app bundle (v1.9.0)
  - Test CLI manually: verify all formats and flags work
  - Test shell integration: verify bash/zsh/Starship work
  - Verify backward compatibility (GUI still works normally)
  - **Success criteria:** All acceptance criteria verified via tests and manual testing

---
<!-- CHECKPOINT: Phase 4 completes SLC 10. Ready for v1.9.0 release. -->

## Acceptance Criteria Summary

### SLC 10 Checklist

**CLI Interface:**
- [x] `claudeapp --status` outputs usage data ✅
- [x] `--format plain` shows human-readable output ✅
- [x] `--format json` shows structured JSON ✅
- [x] `--format minimal` shows percentage only ✅
- [x] `--format verbose` shows detailed multi-line output ✅
- [x] `--metric session|weekly|highest|opus|sonnet` filters output ✅
- [x] `--refresh` forces API fetch (updates cache) ✅
- [x] Exit codes indicate status (0, 1, 2, 3) ✅

**Shared Cache:**
- [x] GUI app writes to App Group UserDefaults on refresh ✅
- [x] CLI reads from App Group UserDefaults ✅
- [x] Stale data (>15 min) returns exit code 3 ✅
- [x] Cache timestamp included in JSON output ✅

**Shell Integration:**
- [ ] Documentation for bash, zsh, Starship, tmux
- [ ] Symlink installation script provided
- [ ] Oh My Zsh plugin template provided

---

## Future Work (Outside Current Scope)

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
| CLI integration tests | Medium | Need end-to-end CLI tests |
| Burn rate thresholds configurable | Low | Currently hardcoded |
| Hysteresis buffer configurable | Low | Currently hardcoded 5% |

---

## Test Coverage Summary

**Current:** 752 tests across 4 packages (Phase 1 complete)

| Package | Tests | Coverage |
|---------|-------|----------|
| Domain | 132 | Excellent - models fully tested |
| Services | 29 | Basic - needs error scenarios |
| Core | 339 | Comprehensive - business logic (+26 SharedCacheManager) |
| UI | 252 | Excellent - accessibility focus |

**Target for SLC 10:** 790+ tests (adding ~40 for CLI and output formatters)

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
| 10 | Terminal Integration | 1.9.0 | 770+ | 📋 PLANNED |
