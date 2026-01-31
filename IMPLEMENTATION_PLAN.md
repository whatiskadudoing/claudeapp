# Implementation Plan

## Gap Analysis Summary (2026-01-31)

### Current State: v2.0.0 - All Core Features Complete

**Comprehensive Analysis Complete:**
- 11 SLCs delivered (1.0.0 → 2.0.0)
- 853 tests passing across 4 packages (verified 2026-01-31)
- All 9 Jobs-to-be-Done from AUDIENCE_JTBD.md satisfied
- Zero technical debt (no TODOs/FIXMEs in codebase)
- 3 languages (English, Portuguese BR, Spanish LA)
- WCAG 2.1 AA accessibility compliance

### User Journey Visualization

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ClaudeApp User Journey                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  DISCOVER      INSTALL       CONFIGURE     MONITOR       MAINTAIN       EXTEND      │
│  ────────      ───────       ─────────     ───────       ────────       ──────      │
│                                                                                      │
│  ✅ GitHub     ✅ DMG        ✅ Settings   ✅ View       ⚠️ Manual      📋 Widgets   │
│  ✅ Homebrew   ✅ CLI        ✅ Accounts   ✅ Refresh    📋 Sparkle    (SLC 14)     │
│  ✅ README     ✅ Keychain   ✅ Notifs     ✅ Alerts     (SLC 13)                    │
│                              ✅ Export     ✅ Charts                                 │
│                                            ✅ Terminal                               │
│                                                                                      │
│  DEVELOPER EXPERIENCE                                                                │
│  ────────────────────                                                                │
│                                                                                      │
│  ❌ CI/CD      ❌ Auto Tests  ❌ PR Checks                                           │
│  (SLC 12)     (SLC 12)       (SLC 12)                                               │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

Legend: ✅ Complete | 📋 Planned | ⚠️ Friction Point | ❌ Gap/Regression
```

### Gap Analysis Results

| Category | Status | Details |
|----------|--------|---------|
| Core Features | ✅ COMPLETE | View usage, refresh, notifications, settings |
| Enhanced Features | ✅ COMPLETE | Icon styles, historical charts, power-aware refresh |
| Power User Features | ✅ COMPLETE | Multi-account, settings export, terminal integration |
| Accessibility | ✅ COMPLETE | VoiceOver, keyboard nav, Dynamic Type, color-blind safe |
| Internationalization | ✅ COMPLETE | 3 languages with 105+ strings |
| **CI/CD Infrastructure** | ❌ REGRESSION | `.github/workflows/ci.yml` deleted - 853 tests unprotected |
| Updates | ⚠️ FRICTION | GitHub Releases only (manual download required) |
| Sparkle Auto-Updates | 📋 BLOCKED | Requires Apple Developer ID ($99/year) |
| Widgets | 📋 BLOCKED | Requires Apple Developer ID ($99/year) |

### Critical Finding: CI/CD Regression

The `.github/workflows/` directory no longer exists (file was committed but locally deleted):

```bash
$ ls -la .github/workflows/
ls: .github/workflows/: No such file or directory

$ git show HEAD:.github/workflows/ci.yml
# File exists in git history - unstaged deletion
```

**Impact:**
- 853 tests provide NO protection without CI
- Any PR can break the codebase without validation
- Open-source contributors cannot verify their changes
- Sparkle's release workflow depends on GitHub Actions

---

## Recommended SLC Release: SLC 12 - CI/CD Infrastructure

**Audience:** Professional developers using Claude Code AND open-source contributors.

**Value proposition:** Restore automated quality gates that protect all 853 tests, enable confident contributions, and establish the foundation for automated releases. This is **prerequisite infrastructure** for SLC 13 (Sparkle).

**Why CI/CD BEFORE Sparkle?**
1. **No external dependencies** - Can ship immediately, no $99/year requirement
2. **Protects existing work** - 853 tests are worthless without automation
3. **Enables Sparkle** - Sparkle's release workflow requires GitHub Actions
4. **Enables contributions** - Open-source contributors need CI validation
5. **Zero risk** - Internal infrastructure, not user-facing

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| CI Pipeline | Standard | Run tests on every PR to prevent regressions |
| Quality Gates | Standard | SwiftFormat + SwiftLint enforce code quality |
| Release Automation | Basic | DMG builds on tags (unsigned) |
| Documentation | Basic | Badges + contributing guidelines |

**What's NOT in this slice:**
- Code signing → Deferred to SLC 13 (requires Apple Developer ID)
- Sparkle integration → Deferred to SLC 13
- Widgets → Deferred to SLC 14 (requires code signing)
- Delta updates → Nice-to-have for SLC 13

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Build System | `specs/toolchain.md` | Makefile targets, CI workflow templates |
| Package Structure | `specs/architecture.md` | 4-package layout for targeted testing |
| Update Patterns | `research/update-mechanisms.md` | Sparkle integration patterns for future |
| OSS Practices | `research/competitive-analysis.md` | CI/CD patterns from 40+ analyzed apps |
| Menu Bar Apps | `research/macos-menubar-apps.md` | GitHub Actions workflows from similar apps |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - CI/CD is foundational. It protects all existing work and enables Sparkle. -->

## Prerequisites: None

SLC 12 has **no external dependencies**. Proceed immediately.

---
<!-- CHECKPOINT: Confirm no blockers before proceeding. -->

## Phase 1: Restore CI Pipeline - CRITICAL

**Purpose:** Restore automated testing on every PR and push to main.

- [x] **Restore CI workflow with build, test, and lint jobs** [spec: toolchain.md] [file: .github/workflows/ci.yml]
  - Recreate `.github/workflows/` directory
  - Restore `.github/workflows/ci.yml` from git history or create fresh
  - Trigger on push to main and pull_request
  - Use `macos-14` runner (Apple Silicon, fast)
  - Job structure:
    - Step 1: Checkout + select Xcode 15.2
    - Step 2: Cache SPM dependencies (`actions/cache@v4`)
    - Step 3: Install tools (`brew install swiftformat swiftlint`)
    - Step 4: Check formatting (`swiftformat --lint`)
    - Step 5: Lint (`swiftlint lint --strict`)
    - Step 6: Build (`swift build --configuration release`)
    - Step 7: Test (`swift test` - all 853 tests)
  - Set 30-minute timeout
  - **Research:** `specs/toolchain.md#ci-cd` has complete workflow template
  - **See also:** `research/macos-menubar-apps.md` for patterns from Rectangle, Ice, Maccy
  - **Success criteria:** CI runs on all PRs, fails on test failures or lint errors

---
<!-- CHECKPOINT: Verify CI runs on a test PR before proceeding. -->

## Phase 2: Release Automation

**Purpose:** Automate DMG builds when tags are pushed.

- [ ] **Create release workflow for tag-based releases** [spec: toolchain.md] [file: .github/workflows/release.yml]
  - Create `.github/workflows/release.yml`
  - Trigger on `v*` tags only
  - Workflow steps:
    - Checkout + cache SPM
    - Run full test suite first (gate release on tests)
    - Build release app (`make release`)
    - Create DMG (`make dmg`)
    - Generate SHA256 checksum
    - Create GitHub Release with DMG attached using `softprops/action-gh-release@v2`
    - Include auto-generated release notes
  - **Research:** `specs/toolchain.md#release-process` documents DMG creation
  - **See also:** `research/update-mechanisms.md` - Sparkle apps use similar workflows
  - **Success criteria:** `git tag v2.0.1 && git push --tags` creates release with DMG

---
<!-- CHECKPOINT: Test by creating a v2.0.1-rc1 tag. -->

## Phase 3: Documentation & Quality

**Purpose:** Document CI status and contribution process.

- [ ] **Add CI badges and contribution documentation** [file: README.md, CONTRIBUTING.md]
  - Add badges to README.md:
    - CI status badge: `![CI](https://github.com/.../workflows/CI/badge.svg)`
    - Test count badge (853 tests)
    - macOS 14+ badge
    - Swift 5.9+ badge
  - Enhance CONTRIBUTING.md with:
    - Development setup instructions (reference `specs/toolchain.md`)
    - How to run tests locally (`make test`, `make check`)
    - PR checklist (tests pass, lint clean, format check)
    - Code style guidelines (SwiftFormat + SwiftLint configs)
    - Architecture overview (4-package structure)
  - Update README.md "Development" section to reference CONTRIBUTING.md
  - **Research:** `research/competitive-analysis.md` shows standard OSS badge patterns
  - **Success criteria:** Contributors understand requirements; badges render correctly

---
<!-- CHECKPOINT: Verify README renders correctly with badges. -->

## Phase 4: Release v2.0.1

**Purpose:** Ship CI/CD infrastructure as patch release.

- [ ] **Prepare and release v2.0.1** [file: Resources/Info.plist, CHANGELOG.md]
  - Update version in `Resources/Info.plist`:
    - `CFBundleShortVersionString` → `2.0.1`
    - `CFBundleVersion` → increment build number
  - Create CHANGELOG.md entry for v2.0.1:
    - "Restored CI/CD pipeline for automated testing"
    - "Added release automation for GitHub Releases"
    - "Added CONTRIBUTING.md with development guidelines"
    - "Added CI status badges to README"
  - Run full test suite locally: `make check` (all 853+ tests pass)
  - Commit changes: "Prepare v2.0.1 release"
  - Create release: `git tag v2.0.1 && git push && git push --tags`
  - Verify release workflow creates GitHub Release with DMG
  - **Success criteria:** v2.0.1 released with working CI, DMG attached

---
<!-- CHECKPOINT: SLC 12 COMPLETE. CI/CD OPERATIONAL. -->

## Acceptance Criteria Summary

### CI Pipeline
- [x] GitHub Actions workflow exists at `.github/workflows/ci.yml`
- [x] Triggers on push to main and pull_request
- [x] Runs `swift build` successfully
- [x] Runs `swift test` (853 tests pass)
- [x] Runs SwiftFormat lint check
- [x] Runs SwiftLint with `--strict`
- [x] SPM dependencies are cached
- [x] Failed tests block PR merge

### Release Automation
- [ ] GitHub Actions workflow exists at `.github/workflows/release.yml`
- [ ] Triggers on `v*` tags
- [ ] Builds release DMG
- [ ] Creates GitHub Release with DMG attached
- [ ] Includes SHA256 checksum

### Documentation
- [ ] README.md has CI status badge
- [ ] README.md has test count badge
- [ ] CONTRIBUTING.md exists with guidelines
- [ ] Development setup documented

---

## Future Work (Outside Current Scope)

### SLC 13: Sparkle Auto-Updates

**Requires:** Apple Developer Program enrollment ($99/year)
**Depends on:** SLC 12 (release workflow)

| Phase | Task | Complexity |
|-------|------|------------|
| 1 | Code signing + notarization | Medium |
| 2 | Sparkle framework integration | Medium |
| 3 | Appcast + EdDSA signing | Medium |
| 4 | Settings UI for updates | Low |
| 5 | Release v2.1.0 | Low |

**Research:**
- `specs/sparkle-updates.md` - Full Sparkle integration spec
- `research/update-mechanisms.md` - Patterns from 9 apps (Rectangle, Ice, Maccy, etc.)

### SLC 14: macOS Widgets

**Requires:** Code signing from SLC 13

| Feature | Complexity |
|---------|------------|
| Small widget (percentage) | Medium |
| Medium widget (2 windows) | Medium |
| Large widget (all + sparkline) | High |
| App Group data sharing | Low |

**Research:** `specs/features/widgets.md`

### SLC 15+: Future Enhancements

| Feature | Priority |
|---------|----------|
| Delta updates (Sparkle) | Low |
| Beta channel | Low |
| Additional languages (FR, DE, JA, ZH, KO) | Low |
| Multiple providers (OpenAI, Gemini) | Low |

### Technical Debt (Low Priority)

| Item | Priority |
|------|----------|
| Split ClaudeApp.swift (2,809 lines) | Medium |
| Network failure integration tests | Medium |
| Keychain error scenario tests | Medium |
| CLI multi-account commands | Low |

---

## Test Coverage

**Current (v2.0.0):** 853 tests (verified passing 2026-01-31)

| Package | Tests | Focus |
|---------|-------|-------|
| Domain | 168 | Models, protocols, errors |
| Services | 29 | API client, Keychain |
| Core | 397 | Business logic, managers |
| UI | 259 | Components, accessibility |

**SLC 12 Target:** 853 tests (no new features, infrastructure only)

---

## SLC History

| SLC | Name | Version | Tests | Status |
|-----|------|---------|-------|--------|
| 1 | Usage Monitor | 1.0.0 | 81 | ✅ |
| 2 | Notifications & Settings | 1.1.0 | 155 | ✅ |
| 3 | Predictive Insights | 1.2.0 | 320 | ✅ |
| 4 | Distribution Ready | 1.3.0 | 369 | ✅ |
| 5 | Internationalization | 1.4.0 | 402 | ✅ |
| 6 | Advanced Accessibility | 1.5.0 | 489 | ✅ |
| 7 | Community Ready | 1.6.0 | 552 | ✅ |
| 8 | Power-Aware Refresh | 1.7.0 | 620 | ✅ |
| 9 | Visualization | 1.8.0 | 726 | ✅ |
| 10 | Terminal Integration | 1.9.0 | 752 | ✅ |
| 11 | Multi-Account | 2.0.0 | 853 | ✅ |
| **12** | **CI/CD Infrastructure** | **2.0.1** | **853** | **📋 PLANNED** |
| 13 | Sparkle Auto-Updates | 2.1.0 | 880+ | 📋 Future |
| 14 | macOS Widgets | 2.2.0 | 920+ | 📋 Future |

---

## Jobs-to-be-Done Coverage

| Job | Status | How Satisfied |
|-----|--------|---------------|
| J1: Monitor Usage Passively | ✅ | Menu bar percentage |
| J2: Plan Work Sessions | ✅ | Detailed dropdown |
| J3: Avoid Interruptions | ✅ | Notifications with hysteresis |
| J4: Understand Patterns | ✅ | Per-model breakdown, charts |
| J4a: Know When Limit Hits | ✅ | Time-to-exhaustion |
| J4b: Understand Velocity | ✅ | Burn rate badge |
| J5: Stay Informed | ✅ | Auto-refresh, notifications |
| J6: Recover from Errors | ✅ | Clear messages, retry |
| J7: Customize | ✅ | Settings, icon styles |
| J8: Trust Lightweight | ✅ | Power-aware, <15MB |
| J9: Stay Up to Date | ⚡ | GitHub Releases → Sparkle (SLC 13) |

**SLC 12 serves DEVELOPER EXPERIENCE** - protects all existing JTBD implementations from regressions.

---

## Appendix: CI Workflow Template

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-14
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Show Swift version
        run: swift --version

      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: .build
          key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-

      - name: Install tools
        run: brew install swiftformat swiftlint

      - name: Check formatting
        run: swiftformat . --config .swiftformat --lint

      - name: Lint
        run: swiftlint lint --config .swiftlint.yml --strict

      - name: Build
        run: swift build --configuration release

      - name: Test
        run: swift test
```

---

## Appendix: Release Workflow Template

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-14
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: .build
          key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-

      - name: Test
        run: swift test

      - name: Build Release
        run: make release

      - name: Create DMG
        run: make dmg

      - name: Create Checksums
        run: |
          cd release
          shasum -a 256 ClaudeApp.dmg > checksums.txt
          cat checksums.txt

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            release/ClaudeApp.dmg
            release/checksums.txt
          generate_release_notes: true
```
