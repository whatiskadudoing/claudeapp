# Implementation Plan

## Recommended SLC Release: Community Ready (SLC 7)

**Audience:** Professional developers using Claude Code who want to adopt ClaudeApp and potentially contribute to the project.

**Value proposition:** Transform ClaudeApp from a working application into a professional open-source project ready for community adoption. Users need documentation to install, troubleshoot, and contribute. Without proper docs, adoption friction is high and contributions are unlikely.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| User Documentation | Standard | Users need installation/usage guides |
| Community Files | Basic | Contributors need CONTRIBUTING/CODE_OF_CONDUCT |
| Homebrew Distribution | Basic | Most macOS developers expect Homebrew install |

**What's NOT in this slice:**
- Phase 2 languages (French, German, Japanese, Chinese, Korean) → SLC 8
- RTL language support (Arabic, Hebrew) → Future
- Local JSONL fallback → Future
- Custom app icon design → Future
- Plan badge auto-detection (requires API support) → BLOCKED
- Historical usage graphs/trends → Future

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Documentation Structure | `specs/user-documentation.md` | Complete doc spec with templates |
| Homebrew Setup | `research/inspiration.md#distribution` | Example cask formulas |
| Project Conventions | `README.md` | Current state to extend |
| Contributing Guide | `specs/toolchain.md` | Build commands and workflow |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - A professional open-source project needs documentation and
     proper distribution channels. This slice removes adoption barriers and
     enables community contributions. -->

## Phase 0: Build Verification - CRITICAL

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - should succeed ✅
  - Run `swift test` - all 489 tests should pass ✅
  - Run `make release` - .app bundle should be created ✅
  - **Success criteria:** All checks pass, no regressions from SLC 6 ✅

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. Do not proceed if build is broken. -->

## Phase 1: User Documentation - CRITICAL

**Purpose:** Create the docs/ folder with user-facing documentation that enables self-service installation and troubleshooting.

- [x] **Create docs/ folder with installation and usage guides** [spec: user-documentation.md] [file: docs/installation.md, docs/usage.md]
  - Created `docs/installation.md` with:
    - System requirements (macOS 14+, Claude Code CLI)
    - Homebrew installation (with note about "coming soon" until tap is ready)
    - Direct download from GitHub Releases
    - Bypassing Gatekeeper instructions (both right-click and System Settings methods)
    - Build from source instructions
    - Post-installation setup (claude login)
    - Uninstallation instructions for all methods
  - Created `docs/usage.md` with:
    - Menu bar display explanation with percentage source options
    - Dropdown view breakdown with ASCII diagram
    - Progress bar colors meaning (green/yellow/red thresholds)
    - Burn rate levels and their thresholds (<10%, 10-25%, 25-50%, >50%/hr)
    - Time-to-exhaustion display and calculation rules
    - Complete Settings documentation (all 4 sections)
    - Keyboard shortcuts reference (Cmd+R, Cmd+,, Cmd+Q, Tab)
    - Notification behavior with hysteresis details
    - Accessibility features summary
    - Supported languages list
  - **Test:** Documentation verified against codebase exploration ✅

- [x] **Create troubleshooting and FAQ documentation** [spec: user-documentation.md] [file: docs/troubleshooting.md, docs/faq.md]
  - Created `docs/troubleshooting.md` with:
    - "Claude Code not found" resolution with Keychain details
    - Stale data issues and refresh behavior
    - Gatekeeper bypass (both right-click and System Settings methods)
    - Notification permission issues with in-app guidance
    - High CPU/memory troubleshooting with expected values
    - Menu bar icon missing solutions
    - Settings not saving fix
    - Rate limiting explanation with exponential backoff
    - Burn rate and time-to-exhaustion visibility conditions
    - Complete issue reporting guide with version info steps
  - Created `docs/faq.md` with:
    - General section: What is ClaudeApp, official status, free/open source
    - Privacy & security: Data access, security, storage locations table
    - Usage section: Claude Code requirement, usage windows table, percentages, refresh, burn rate, time-to-exhaustion
    - Troubleshooting section: Common quick fixes with links
    - Technical section: macOS 14+ requirement, App Store, Homebrew, contributing, languages
  - **Research:** Used `specs/user-documentation.md` templates, adapted with actual repo URLs
  - **Test:** Documentation verified against codebase exploration ✅

- [x] **Create privacy policy** [spec: user-documentation.md] [file: docs/privacy.md]
  - Created comprehensive privacy policy documenting:
    - What data is accessed: OAuth token (read-only from Keychain), usage statistics, user preferences
    - What is NOT accessed: conversations, code, personal info, browsing history
    - Local-only storage: Keychain (managed by Claude Code), UserDefaults for settings, memory-only for usage history
    - No analytics, no crash reporting, no telemetry (verified via codebase audit)
    - Third-party services: Anthropic API (required), GitHub API (optional, for updates)
    - User rights: data access commands, complete deletion instructions
    - Network security details (HTTPS, credential handling)
    - Children's privacy statement
    - Summary table for quick reference
  - **Research:** Used `specs/user-documentation.md#privacy.md` template, verified against actual codebase
  - **Test:** Privacy policy matches actual app behavior (verified via codebase exploration) ✅

---
<!-- CHECKPOINT: Phase 1 delivers user documentation. Users can now install and troubleshoot. -->

## Phase 2: Community Files

**Purpose:** Add standard open-source community files that enable and guide contributions.

- [x] **Create CONTRIBUTING.md with development guide** [spec: user-documentation.md] [file: CONTRIBUTING.md]
  - Code of Conduct reference (links to CODE_OF_CONDUCT.md)
  - Ways to contribute: Bug reports, Feature requests, Code contributions
  - Development setup: Prerequisites, optional tools, `make setup`, `make run`
  - Available commands: Building, Testing, Code Quality, Cleaning, Release
  - Project architecture: Package structure with dependency flow diagram
  - Code style: SwiftFormat (4-space indent, 120 char), SwiftLint rules
  - Concurrency guidelines: async/await, actor, @MainActor, Sendable
  - Testing: Swift Testing framework with example code
  - Commit guidelines: Focus on "why", pre-commit hook info
  - Pull request process: Checklist, review process
  - Testing requirements: Coverage goals by package
  - Localization contribution guide: Adding new languages
  - Documentation references: Links to specs/ and docs/
  - Release process: For maintainers
  - Getting help: Links to Discussions, Issues, Security
  - **Research:** `specs/user-documentation.md#CONTRIBUTING.md`, `specs/toolchain.md`, codebase exploration
  - **Test:** Guide verified against actual Makefile commands and project structure

- [ ] **Create CODE_OF_CONDUCT.md and SECURITY.md** [spec: user-documentation.md] [file: CODE_OF_CONDUCT.md, SECURITY.md]
  - `CODE_OF_CONDUCT.md`: Use Contributor Covenant v2.1 (industry standard)
  - `SECURITY.md`:
    - Security scope (local app, no network except Anthropic/GitHub)
    - How to report vulnerabilities (email or GitHub private advisory)
    - Supported versions
    - Response process
  - **Research:** https://www.contributor-covenant.org/version/2/1/code_of_conduct/
  - **Test:** Files follow standard formats, links work

- [ ] **Update CHANGELOG.md with proper version dates and SLC 3-6 entries** [file: CHANGELOG.md]
  - Add missing version entries:
    - v1.3.0 (Distribution Ready - SLC 4)
    - v1.4.0 (Internationalization - SLC 5)
    - v1.5.0 (Advanced Accessibility - SLC 6)
  - Fix placeholder dates (2026-01-XX → actual dates)
  - Add current v1.6.0 entry for Community Ready (SLC 7)
  - Ensure format follows Keep a Changelog
  - **Test:** CHANGELOG accurately reflects git history

---
<!-- CHECKPOINT: Phase 2 delivers community files. Contributors can now participate. -->

## Phase 3: Homebrew Distribution

**Purpose:** Enable the standard macOS developer installation method.

- [ ] **Create Homebrew tap repository and cask formula** [spec: user-documentation.md] [file: external: homebrew-tap repo]
  - Create new GitHub repository: `kaduwaengertner/homebrew-tap`
  - Create `Casks/claudeapp.rb` with:
    - Version from GitHub Releases
    - SHA256 checksum for DMG
    - URL to GitHub Release DMG asset
    - App name and target location
    - Caveats about Gatekeeper bypass
  - Document tap creation in project wiki or docs
  - Update README.md to remove "(Coming Soon)" from Homebrew section
  - **Research:** `research/inspiration.md` for example Homebrew casks
  - **Test:** `brew tap kaduwaengertner/tap && brew install --cask claudeapp` works

---
<!-- CHECKPOINT: Phase 3 delivers Homebrew distribution. Standard installation works. -->

## Phase 4: Polish & Cross-References

**Purpose:** Ensure all documentation is consistent and cross-referenced.

- [ ] **Update README.md with documentation links and finalize content** [file: README.md]
  - Add Documentation section with links to:
    - [Installation Guide](docs/installation.md)
    - [Usage Guide](docs/usage.md)
    - [Troubleshooting](docs/troubleshooting.md)
    - [FAQ](docs/faq.md)
    - [Privacy Policy](docs/privacy.md)
  - Update Homebrew installation (remove "Coming Soon" after Phase 3)
  - Ensure Contributing section links to CONTRIBUTING.md
  - Add Acknowledgments section
  - **Test:** All links work, content accurate

- [ ] **Run final verification** [file: Makefile]
  - Run `make check` (format, lint, test) - all must pass
  - Verify all new markdown files have no broken links
  - Test app still builds and runs correctly
  - Verify release workflow works with `make dmg`
  - **Success criteria:** 489+ tests passing, all docs accurate, build green

---
<!-- CHECKPOINT: Phase 4 completes SLC 7. The project is now community-ready. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 8: Phase 2 Languages
- French (fr-FR/CA)
- German (de-DE)
- Japanese (ja-JP)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)
- Korean (ko-KR)
- RTL preparation for future Arabic/Hebrew
- **Research:** `specs/internationalization.md` Phase 2 section

### Future Releases
- Local JSONL fallback when API unavailable
- Custom Claude brand app icon (replace SF Symbol)
- Plan badge auto-detection (requires Anthropic API support - BLOCKED)
- Historical usage graphs/trends visualization
- Widget support for Notification Center
- Warning badge at 100% in menu bar icon
- Different notification sounds per type
- Release notes display in update checker
- Export/import settings
- Reset to defaults option

### Technical Debt Identified
- Hysteresis values hardcoded (5%) - could be configurable
- Burn rate thresholds hardcoded (10/25/50% per hour)
- No integration tests with mock network layer
- Memory leak detection for long-running sessions
- GitHub repo URL uses actual repo now (kaduwaengertner/claudeapp)

---

## Implementation Notes

### Homebrew Cask Formula Template

```ruby
cask "claudeapp" do
  version "1.6.0"
  sha256 "CHECKSUM_HERE"

  url "https://github.com/kaduwaengertner/claudeapp/releases/download/v#{version}/ClaudeApp-#{version}.dmg"
  name "ClaudeApp"
  desc "macOS menu bar app for monitoring Claude Code usage limits"
  homepage "https://github.com/kaduwaengertner/claudeapp"

  depends_on macos: ">= :sonoma"

  app "ClaudeApp.app"

  caveats <<~EOS
    ClaudeApp requires Claude Code CLI to be installed and authenticated.
    Run `claude login` if you haven't already.

    On first launch, you may need to bypass Gatekeeper:
    - Right-click the app and select "Open"
    - Or go to System Settings > Privacy & Security and click "Open Anyway"
  EOS

  zap trash: [
    "~/Library/Preferences/com.kaduwaengertner.ClaudeApp.plist",
  ]
end
```

### Documentation Style Guide

- Use clear, concise language
- Include code examples where helpful
- Provide screenshots for UI-related docs
- Use tables for structured information
- Include command-line examples
- Test all instructions before publishing

### Contributor Covenant Reference

Use version 2.1 of the Contributor Covenant:
https://www.contributor-covenant.org/version/2/1/code_of_conduct/

---

## Previous SLC Releases

### SLC 1: Usage Monitor - COMPLETE ✅

All tasks completed with 81 passing tests.

**Phase 1: Project Foundation**
- [x] Initialize Swift Package project with modular architecture
- [x] Implement Domain models and protocols
- [x] Implement Keychain credentials repository
- [x] Implement Claude API client

**Phase 2: Menu Bar UI**
- [x] Create menu bar app entry point with MenuBarExtra
- [x] Implement UsageManager with @Observable state
- [x] Build menu bar label view
- [x] Build dropdown view with usage bars

**Phase 3: Refresh & Polish**
- [x] Implement auto-refresh lifecycle with exponential backoff
- [x] Implement manual refresh with button states
- [x] Implement error and loading states with stale data display

---

### SLC 2: Notifications & Settings - COMPLETE ✅

All tasks completed with 155 passing tests.

**Phase 1: Settings Infrastructure**
- [x] Implement SettingsManager with @Observable state and UserDefaults persistence
- [x] Implement LaunchAtLoginManager using SMAppService
- [x] Build Settings window with all sections
- [x] Connect settings to existing UI (menu bar display + refresh interval)

**Phase 2: Notification System**
- [x] Implement NotificationManager actor with permission handling
- [x] Implement notification trigger logic with hysteresis
- [x] Integrate notifications into UsageManager refresh cycle
- [x] Add notification permission UI and denied state handling

**Phase 3: Polish & Testing**
- [x] Add comprehensive tests for Settings and Notifications (155 tests)
- [x] Implement settings button and window lifecycle

---

### SLC 3: Predictive Insights - COMPLETE ✅

All tasks completed with 320 passing tests.

**Phase 1: Burn Rate Domain Models**
- [x] Implement BurnRate and BurnRateLevel domain models
- [x] Extend UsageWindow with burn rate properties
- [x] Extend UsageData with highestBurnRate computed property

**Phase 2: Burn Rate Calculator**
- [x] Create UsageSnapshot model for history tracking
- [x] Implement BurnRateCalculator
- [x] Integrate burn rate calculation into UsageManager
- [x] Add comprehensive tests for BurnRateCalculator

**Phase 3: Burn Rate UI**
- [x] Create BurnRateBadge component
- [x] Add time-to-exhaustion display to UsageProgressBar
- [x] Integrate burn rate into dropdown header
- [x] Update UsageProgressBar instances with time-to-exhaustion

**Phase 4: Update Checking**
- [x] Create UpdateChecker actor
- [x] Create GitHub API models
- [x] Integrate update checking into app lifecycle
- [x] Implement update UI in Settings About section

**Phase 5: Polish & Code Organization**
- [x] Refactor UI components into UI package
- [x] Add UI tests for burn rate display
- [x] Update documentation and version

---

### SLC 4: Distribution Ready - COMPLETE ✅

All tasks completed with 369 passing tests.

**Phase 0: Build Verification**
- [x] Verify build, test, and run work correctly
- [x] Create app bundle generation script
- [x] Verify app bundle launches correctly

**Phase 1: Accessibility Foundation**
- [x] Implement VoiceOver labels for menu bar and dropdown
- [x] Add VoiceOver support to UsageProgressBar
- [x] Implement keyboard navigation
- [x] Add VoiceOver announcements for state changes

**Phase 2: Distribution Tooling**
- [x] Create release scripts (DMG, hooks)
- [x] Add SwiftFormat and SwiftLint configuration

**Phase 3: CI/CD Pipeline**
- [x] Create GitHub Actions CI workflow
- [x] Create GitHub Actions release workflow
- [x] Document release process in README

**Phase 4: Polish & Testing**
- [x] Add accessibility tests (18 new tests)
- [x] Verify color contrast and update documentation

**Known Issue (RESOLVED in SLC 6):** Yellow warning color was updated from #EAB308 (2.1:1 contrast) to #B8860B goldenrod (3.5:1 contrast) in SLC 6, meeting WCAG AA 3:1 minimum.

---

### SLC 5: Internationalization - COMPLETE ✅

All tasks completed with 402 passing tests.

**Phase 1: Internationalization Infrastructure**
- [x] Create String Catalog and extract all UI strings
- [x] Update SwiftUI views to use LocalizedStringKey
- [x] Implement locale-aware date and number formatting

**Phase 2: Portuguese (pt-BR) Localization**
- [x] Add Portuguese translations to String Catalog
- [x] Test Portuguese localization end-to-end

**Phase 3: Spanish (es-LATAM) Localization**
- [x] Add Spanish translations to String Catalog
- [x] Test Spanish localization end-to-end

**Phase 4: Localization Tests & Documentation**
- [x] Add localization unit tests (33 new tests)
- [x] Update documentation for i18n

---

### SLC 6: Advanced Accessibility - COMPLETE ✅

All tasks completed with 489 passing tests.

**Phase 0: Build Verification**
- [x] Verify current build and test status
- [x] Bug Found & Fixed: Localization strings showed as keys instead of values in release bundle

**Phase 1: Dynamic Type Support**
- [x] Implement adaptive text scaling throughout UI
- [x] Add layout adaptations for extreme text sizes

**Phase 2: Color-Blind Safe Patterns**
- [x] Add pattern overlays to progress bars at critical thresholds
- [x] Add shape indicators to burn rate badge

**Phase 3: Reduced Motion & High Contrast**
- [x] Implement reduced motion support
- [x] Fix yellow warning color contrast (WCAG AA compliance)
- [x] Add high contrast mode support

**Phase 4: Accessibility Tests & Documentation**
- [x] Add accessibility unit tests (28 new tests)
- [x] Update accessibility documentation

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
| 7 | Community Ready | 1.6.0 | 489+ | PLANNED |
