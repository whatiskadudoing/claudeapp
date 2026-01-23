# Implementation Plan

## Recommended SLC Release: Advanced Accessibility (SLC 6)

**Audience:** Professional developers using Claude Code, including those with visual impairments, color vision deficiency, or preferences for reduced motion and larger text.

**Value proposition:** Make ClaudeApp truly accessible to all developers. While SLC 4 added basic VoiceOver support and keyboard navigation, users with color blindness cannot distinguish warning states, Dynamic Type users see truncated text, and motion-sensitive users experience discomfort. This slice delivers WCAG 2.1 AA compliance across all accessibility dimensions.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Dynamic Type Support | Standard | Large text users need readable UI |
| Color-Blind Safe Patterns | Standard | Color alone isn't sufficient for status |
| Reduced Motion Support | Basic | Respect system preferences |
| High Contrast Mode | Basic | Low vision users need stronger contrast |
| Yellow Warning Color Fix | Standard | Current 2.1:1 ratio fails WCAG AA |

**What's NOT in this slice:**
- Phase 2 languages (French, German, Japanese, Chinese, Korean) → SLC 7
- RTL language support (Arabic, Hebrew) → Future
- Local JSONL fallback → Future
- Custom app icon design → Future
- Plan badge auto-detection (requires API support) → Future
- Homebrew tap setup → Future
- Documentation site (docs/) → Future

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Accessibility Requirements | `specs/accessibility.md` | Complete accessibility spec with WCAG requirements |
| Dynamic Type | `specs/accessibility.md#dynamic-type` | Size categories and adaptive layouts |
| Color Patterns | `specs/accessibility.md#color-blind` | Pattern overlays for color-blind users |
| Motion Preferences | `specs/accessibility.md#reduced-motion` | System preference detection |
| Design System | `specs/design-system.md` | Current colors and spacing tokens |
| View Usage Spec | `specs/features/view-usage.md` | UI components to update |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Users who rely on accessibility features will have a fully
     usable experience. This is not just about compliance - it's about ensuring
     every developer can monitor their Claude usage effectively. -->

## Phase 0: Build Verification - CRITICAL

**Purpose:** Verify the app compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - should succeed ✓
  - Run `swift test` - all 402 tests should pass ✓
  - Run `make release` - .app bundle should be created ✓
  - Run `open release/ClaudeApp.app` - app should launch and show usage ✓
  - **Success criteria:** All checks pass, no regressions from SLC 5
  - **Bug Found & Fixed:** Localization strings showed as keys (e.g., "usage.header.title") instead of values in release bundle. Root cause: SPM doesn't compile `.xcstrings` to runtime format; code was using `Bundle.main` instead of `Bundle.module`. Fix: Added `L()` helper function using `Bundle.module`, updated all localized strings, added `compile-strings.py` to convert `.xcstrings` → `.strings` in bundle script.

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. Do not proceed if build is broken. -->

## Phase 1: Dynamic Type Support - CRITICAL

**Purpose:** Enable the app to scale text appropriately for users who need larger (or smaller) text sizes.

- [ ] **Implement adaptive text scaling throughout UI** [spec: accessibility.md#dynamic-type] [file: App/ClaudeApp.swift, Packages/UI/Sources/UI/*.swift]
  - Replace fixed font sizes with `.font(.body)`, `.font(.headline)`, `.font(.caption)` semantic styles
  - Use `@ScaledMetric` for custom sizes that must scale (icons, spacing tied to text)
  - Test with all size categories: xSmall through AX5 (Accessibility sizes)
  - Ensure text doesn't truncate at largest sizes - use `lineLimit(nil)` or scroll where appropriate
  - Key areas to update:
    - Menu bar label (percentage display)
    - Dropdown header (title, burn rate badge)
    - Usage progress bars (percentage, label, reset time, time-to-exhaustion)
    - Settings sections (all labels and descriptions)
    - Error states and buttons
  - **Research:** `specs/accessibility.md` lines 341-410 for size category table
  - **Test:** Build succeeds, all tests pass, UI readable at AX5

- [ ] **Add layout adaptations for extreme text sizes** [spec: accessibility.md#dynamic-type] [file: App/ClaudeApp.swift]
  - Increase dropdown width at accessibility sizes (280px → 340px for AX1+)
  - Stack horizontal layouts vertically when text would overflow
  - Ensure minimum touch targets (44pt) maintained
  - Test with "Larger Accessibility Sizes" enabled in System Settings
  - **Research:** `specs/accessibility.md` lines 395-410 for layout rules
  - **Test:** All content visible and tappable at extreme sizes

---
<!-- CHECKPOINT: Phase 1 delivers Dynamic Type. App should be usable at all text sizes. -->

## Phase 2: Color-Blind Safe Patterns

**Purpose:** Ensure status information is conveyed through patterns and shapes, not just color.

- [ ] **Add pattern overlays to progress bars at critical thresholds** [spec: accessibility.md#color-blind] [file: Packages/UI/Sources/UI/UsageProgressBar.swift]
  - At >90% utilization: Add diagonal stripe pattern overlay to progress bar fill
  - At 100% utilization: Add solid pattern or pulsing animation (respecting reduced motion)
  - Pattern should be visible but not obscure the percentage text
  - Implementation approach: Use `Canvas` or `Shape` with `.stroke(style:)` for stripes
  - Colors remain for sighted users; patterns add redundant information
  - **Research:** `specs/accessibility.md` lines 263-298 for pattern requirements
  - **Test:** Status distinguishable in grayscale/color-blind simulation

- [ ] **Add shape indicators to burn rate badge** [spec: accessibility.md#color-blind] [file: Packages/UI/Sources/UI/BurnRateBadge.swift]
  - Low: Circle or no shape (green, safe)
  - Medium: Triangle or caution shape (yellow)
  - High: Diamond or warning shape (orange)
  - Very High: Exclamation or alert shape (red)
  - Shapes should be small, subtle, and complement the text label
  - **Research:** `specs/design-system.md` for burn rate color definitions
  - **Test:** Burn rate level distinguishable without color

---
<!-- CHECKPOINT: Phase 2 delivers color-blind support. Status clear without color alone. -->

## Phase 3: Reduced Motion & High Contrast

**Purpose:** Respect system accessibility preferences for motion and contrast.

- [ ] **Implement reduced motion support** [spec: accessibility.md#reduced-motion] [file: Packages/UI/Sources/UI/*.swift, App/ClaudeApp.swift]
  - Detect `UIAccessibility.isReduceMotionEnabled` (use `@Environment(\.accessibilityReduceMotion)`)
  - When enabled:
    - Replace progress bar animations with instant transitions
    - Remove refresh button spinning animation
    - Remove any pulsing or repeating animations
    - Keep essential state changes visible (use opacity or instant color change)
  - Test by enabling "Reduce motion" in System Settings > Accessibility > Display
  - **Research:** `specs/accessibility.md` lines 248-262 for motion requirements
  - **Test:** No animations when Reduce Motion enabled, all states still visible

- [ ] **Fix yellow warning color contrast** [spec: accessibility.md] [file: Packages/UI/Sources/UI/Theme.swift, UsageProgressBar.swift]
  - Current yellow (#EAB308) on background (#F4F3EE) is 2.1:1 (fails WCAG AA 3:1 for UI)
  - Solution options:
    1. Darken yellow to #B8860B (goldenrod) - achieves 3.5:1
    2. Add dark border/outline to yellow elements
    3. Use pattern overlay (from Phase 2) to provide additional contrast
  - Ensure the fix works in both light and dark modes
  - Update `Theme.warning` color if changed
  - **Research:** `specs/accessibility.md` contrast requirements, `specs/design-system.md` color definitions
  - **Test:** Contrast ratio ≥3:1 for all UI components, verified with color contrast tool

- [ ] **Add high contrast mode support** [spec: accessibility.md#high-contrast] [file: Packages/UI/Sources/UI/Theme.swift]
  - Detect `UIAccessibility.isDarkerSystemColorsEnabled` / `@Environment(\.accessibilityDifferentiateWithoutColor)`
  - When enabled:
    - Increase border widths (1px → 2px)
    - Ensure all text meets 7:1 contrast (WCAG AAA)
    - Add borders to progress bar containers
    - Increase focus indicator visibility
  - **Research:** `specs/accessibility.md` lines 165-180 for high contrast requirements
  - **Test:** UI clearly visible with "Increase Contrast" enabled

---
<!-- CHECKPOINT: Phase 3 delivers motion and contrast improvements. -->

## Phase 4: Accessibility Tests & Documentation

**Purpose:** Add automated tests for accessibility features and update documentation.

- [ ] **Add accessibility unit tests** [file: Packages/UI/Tests/UITests/UITests.swift, Packages/Core/Tests/CoreTests/CoreTests.swift]
  - Test Dynamic Type scaling with `@ScaledMetric`
  - Test reduced motion behavior (animation disabled)
  - Test pattern presence at >90% utilization
  - Test shape indicators on burn rate badges
  - Test color contrast values programmatically
  - Verify accessibility labels still work with new features
  - Target: 20+ new accessibility tests
  - **Test:** All new tests pass, total test count ~420+

- [ ] **Update accessibility documentation** [file: specs/accessibility.md, README.md]
  - Mark completed items in accessibility.md checklist
  - Add "Accessibility Features" section to README.md
  - Document testing procedures for accessibility
  - List supported accessibility features:
    - VoiceOver (SLC 4)
    - Keyboard Navigation (SLC 4)
    - Dynamic Type (SLC 6)
    - Reduced Motion (SLC 6)
    - Color-Blind Patterns (SLC 6)
    - High Contrast (SLC 6)
  - **Test:** Documentation accurate and helpful

---
<!-- CHECKPOINT: Phase 4 completes SLC 6. The app is now fully WCAG 2.1 AA compliant. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 7: Phase 2 Languages
- French (fr-FR/CA)
- German (de-DE)
- Japanese (ja-JP)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)
- Korean (ko-KR)
- RTL preparation for future Arabic/Hebrew
- **Research:** `specs/internationalization.md` Phase 2 section

### SLC 8: Distribution & Documentation
- Homebrew tap repository setup
- Documentation site (docs/ folder):
  - docs/installation.md
  - docs/usage.md
  - docs/troubleshooting.md
  - docs/faq.md
  - docs/privacy.md
- CHANGELOG.md
- CODE_OF_CONDUCT.md
- SECURITY.md
- **Research:** `specs/user-documentation.md`

### Future Releases
- Local JSONL fallback when API unavailable
- Custom Claude brand app icon (replace SF Symbol)
- Plan badge auto-detection (requires Anthropic API support)
- Apple Developer ID signing and notarization
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
- GitHub repo URL placeholders in UpdateChecker (repoOwner: "yourname", repoName: "claudeapp")

---

## Implementation Notes

### Dynamic Type Implementation

Use SwiftUI's built-in Dynamic Type support:

```swift
// Before (fixed size)
Text("86%").font(.system(size: 24, weight: .bold))

// After (scales with Dynamic Type)
Text("86%").font(.title.bold())

// For custom sizes that must scale
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 16
```

### Pattern Overlay for Progress Bars

```swift
struct DiagonalStripes: Shape {
    let lineWidth: CGFloat = 2
    let spacing: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = Int((rect.width + rect.height) / spacing)
        for i in 0..<count {
            let x = CGFloat(i) * spacing - rect.height
            path.move(to: CGPoint(x: x, y: rect.height))
            path.addLine(to: CGPoint(x: x + rect.height, y: 0))
        }
        return path
    }
}

// Usage in progress bar at >90%
if utilization > 0.9 {
    DiagonalStripes()
        .stroke(Color.white.opacity(0.3), lineWidth: 2)
        .clipShape(progressShape)
}
```

### Reduced Motion Detection

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .easeOut(duration: 0.3)
}
```

### Color Contrast Fix Options

| Option | Color | Contrast | Pros | Cons |
|--------|-------|----------|------|------|
| Darken yellow | #B8860B | 3.5:1 | Simple change | Slightly different look |
| Add border | Current + border | 4.5:1+ | Preserves brand color | More visual complexity |
| Pattern only | Current + stripes | N/A | Brand color + accessibility | Relies on Phase 2 |

Recommendation: Darken yellow (#B8860B) for simplicity and universal benefit.

### Testing Strategy

1. **Automated:** Unit tests for scaling, patterns, motion preferences
2. **Manual Testing:**
   - Enable Larger Accessibility Sizes in System Settings
   - Enable Reduce Motion in System Settings
   - Enable Increase Contrast in System Settings
   - Use Color Filter (Grayscale) to simulate color blindness
   - Test with VoiceOver at each size
3. **Tools:**
   - Accessibility Inspector (Xcode)
   - Color contrast analyzer
   - Sim Daltonism (color blindness simulator)

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

**Known Issue:** Yellow warning color (#EAB308) on background (#F4F3EE) has 2.1:1 contrast ratio, below WCAG AA 3:1 for UI. Deferred to SLC 6 (Advanced Accessibility) for pattern-based solution.

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

## Version History

| SLC | Name | Version | Tests | Status |
|-----|------|---------|-------|--------|
| 1 | Usage Monitor | 1.0.0 | 81 | COMPLETE |
| 2 | Notifications & Settings | 1.1.0 | 155 | COMPLETE |
| 3 | Predictive Insights | 1.2.0 | 320 | COMPLETE |
| 4 | Distribution Ready | 1.3.0 | 369 | COMPLETE |
| 5 | Internationalization | 1.4.0 | 402 | COMPLETE |
| 6 | Advanced Accessibility | 1.5.0 | ~420 | **NEXT** |
