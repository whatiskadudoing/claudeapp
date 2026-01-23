# Implementation Plan

## Recommended SLC Release: Internationalization (SLC 5)

**Audience:** Professional developers using Claude Code globally, including Portuguese (Brazil) and Spanish (Latin America) speakers who prefer native language interfaces.

**Value proposition:** Make ClaudeApp accessible to non-English speakers. A fully functional app that only speaks English excludes a significant portion of the global developer community. This slice adds internationalization infrastructure and Phase 1 languages (English, Portuguese, Spanish) to deliver a truly global product.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Internationalization Infrastructure | Basic | Required - Extract all strings to String Catalog |
| English (en) Localization | Complete | Base language with all strings defined |
| Portuguese (pt-BR) Localization | Complete | P0 priority - large developer community |
| Spanish (es-LATAM) Localization | Complete | P1 priority - large developer community |
| Locale-aware Formatting | Standard | Dates, numbers, percentages use system locale |

**What's NOT in this slice:**
- Phase 2 languages (French, German, Japanese, Chinese, Korean) → Future
- RTL language support (Arabic, Hebrew) → Future
- Advanced accessibility (Dynamic Type, color patterns) → SLC 6
- Local JSONL fallback → Future
- Custom app icon design → Future
- Plan badge auto-detection (requires API support) → Future

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| i18n Strategy | `specs/internationalization.md` | Complete localization spec with string keys |
| String Catalog Format | `specs/internationalization.md#string-management` | .xcstrings format and structure |
| SwiftUI Implementation | `specs/internationalization.md#swiftui-implementation` | LocalizedStringKey patterns |
| Translation Glossary | `specs/internationalization.md#glossary` | Technical term translations |
| Date/Time Formatting | `specs/internationalization.md#date--time-formatting` | Locale-aware formatters |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Users who prefer Portuguese or Spanish interfaces can now use ClaudeApp
     in their native language. All UI text, notifications, and error messages are localized.
     This opens the app to a significantly larger audience without changing functionality. -->

## Phase 0: Build Verification - CRITICAL

**Purpose:** Verify the app still compiles, tests pass, and runs correctly before making changes.

### Pre-Flight Checks

- [x] **Verify current build and test status** [file: Makefile]
  - Run `make clean && make build` - should succeed ✅
  - Run `swift test` - all 369 tests should pass ✅
  - Run `make release` - .app bundle should be created ✅
  - Run `open release/ClaudeApp.app` - app should launch and show usage ✅
  - **Success criteria:** All checks pass, no regressions from SLC 4

---
<!-- CHECKPOINT: Phase 0 must pass before continuing. Do not proceed if build is broken. -->

## Phase 1: Internationalization Infrastructure - CRITICAL

**Purpose:** Create the foundation for localization by extracting all hardcoded strings and setting up String Catalogs.

- [ ] **Create String Catalog and extract all UI strings** [spec: internationalization.md] [file: Resources/Localizable.xcstrings]
  - Create `Resources/Localizable.xcstrings` String Catalog file
  - Extract ALL hardcoded strings from:
    - `App/ClaudeApp.swift` - Menu bar labels, dropdown text, button labels
    - `Packages/UI/Sources/UI/*.swift` - Progress bar labels, badges, theme text
    - `Packages/Core/Sources/Core/*.swift` - Notification messages, error messages
  - Use key naming convention: `{feature}.{component}.{element}`
  - Key examples from spec:
    - `usage.header.title` = "Claude Usage"
    - `usage.session.label` = "Current Session (5h)"
    - `usage.reset.relative` = "Resets %@"
    - `settings.title` = "Settings"
    - `button.refresh` = "Refresh"
    - `error.notAuthenticated.title` = "Claude Code not found"
    - `notification.warning.title` = "Claude Usage Warning"
  - Estimate: ~50-80 unique strings
  - **Research:** `specs/internationalization.md` lines 36-125 for string keys
  - **Test:** Build succeeds, all strings display correctly, no regressions

- [ ] **Update SwiftUI views to use LocalizedStringKey** [spec: internationalization.md#swiftui-implementation] [file: App/ClaudeApp.swift, Packages/UI/Sources/UI/*.swift]
  - Replace hardcoded `Text("string")` with `Text("key.name")`
  - Create `LocalizedStringKey` extensions for type-safe access
  - Use `String(localized:)` for non-Text contexts (notifications, accessibility)
  - Handle string interpolation with positional placeholders (`%@`, `%d`)
  - Update accessibility labels to use localized strings
  - **Research:** `specs/internationalization.md` lines 129-168 for SwiftUI patterns
  - **Test:** VoiceOver announces localized strings correctly

- [ ] **Implement locale-aware date and number formatting** [spec: internationalization.md#date--time-formatting] [file: Packages/UI/Sources/UI/UsageProgressBar.swift, Packages/Core/Sources/Core/*.swift]
  - Replace custom date formatting with `Text(date, style: .relative)`
  - Use `DateComponentsFormatter` for time intervals
  - Ensure percentages use `.monospacedDigit()` (locale-independent)
  - Update time-to-exhaustion display to use localized formatters
  - Review `spokenTimeToExhaustion` for localization
  - **Research:** `specs/internationalization.md` lines 212-268 for formatters
  - **Test:** Run app with different system locales, verify dates display correctly

---
<!-- CHECKPOINT: Phase 1 delivers infrastructure. All strings should be in String Catalog with English values. -->

## Phase 2: Portuguese (pt-BR) Localization

**Purpose:** Add complete Portuguese (Brazil) translations for all user-facing strings.

- [ ] **Add Portuguese translations to String Catalog** [spec: internationalization.md#glossary] [file: Resources/Localizable.xcstrings]
  - Add `pt-BR` localizations for all strings
  - Follow glossary from spec:
    - Usage → Uso
    - Session → Sessão
    - Weekly → Semanal
    - Refresh → Atualizar
    - Settings → Configurações
    - Threshold → Limite
    - Plan → Plano
    - Capacity → Capacidade
  - Translate all ~50-80 strings
  - Handle pluralization rules for Portuguese
  - **Research:** `specs/internationalization.md` lines 336-347 for glossary
  - **Research:** `specs/internationalization.md` lines 176-206 for pluralization
  - **Test:** Launch with `-AppleLanguages "(pt-BR)"`, verify all text is Portuguese

- [ ] **Test Portuguese localization end-to-end** [file: Resources/Localizable.xcstrings]
  - Test menu bar label displays correctly
  - Test dropdown with all usage windows
  - Test settings panel (all sections)
  - Test notifications (warning, capacity full, reset)
  - Test error states (not authenticated, network error)
  - Test accessibility labels with VoiceOver
  - Verify no truncation issues (Portuguese strings ~10-20% longer)
  - **Research:** `specs/internationalization.md` lines 390-409 for string limits
  - **Test:** `make test` passes, manual testing with pt-BR locale

---
<!-- CHECKPOINT: Phase 2 delivers Portuguese. App should be fully usable in Portuguese. -->

## Phase 3: Spanish (es-LATAM) Localization

**Purpose:** Add complete Spanish (Latin America) translations for all user-facing strings.

- [ ] **Add Spanish translations to String Catalog** [spec: internationalization.md#glossary] [file: Resources/Localizable.xcstrings]
  - Add `es` localizations for all strings
  - Follow glossary from spec:
    - Usage → Uso
    - Session → Sesión
    - Weekly → Semanal
    - Refresh → Actualizar
    - Settings → Configuración
    - Threshold → Límite
    - Plan → Plan
    - Capacity → Capacidad
  - Translate all ~50-80 strings
  - Handle pluralization rules for Spanish
  - Use neutral Latin American Spanish (avoid Spain-specific terms)
  - **Research:** `specs/internationalization.md` lines 336-347 for glossary
  - **Test:** Launch with `-AppleLanguages "(es)"`, verify all text is Spanish

- [ ] **Test Spanish localization end-to-end** [file: Resources/Localizable.xcstrings]
  - Test all UI elements (same checklist as Portuguese)
  - Verify no truncation issues
  - Test VoiceOver in Spanish
  - **Test:** `make test` passes, manual testing with es locale

---
<!-- CHECKPOINT: Phase 3 delivers Spanish. App now supports 3 languages. -->

## Phase 4: Localization Tests & Documentation

**Purpose:** Add automated tests for localization and update documentation.

- [ ] **Add localization unit tests** [file: Packages/UI/Tests/UITests/UITests.swift, Packages/Core/Tests/CoreTests/CoreTests.swift]
  - Test that all localized keys exist in String Catalog
  - Test that all supported locales have translations
  - Test string interpolation with placeholders
  - Test date/time formatters produce valid output for all locales
  - Test pluralization rules
  - Test that no hardcoded English strings remain in code
  - **Research:** `specs/internationalization.md` lines 377-386 for UI test patterns
  - **Target:** 10-15 new tests for i18n

- [ ] **Update documentation for i18n** [file: README.md, specs/README.md, IMPLEMENTATION_PLAN.md]
  - Add "Supported Languages" section to README.md
  - Document how to run app in different locales
  - Document contribution guidelines for translations
  - Update IMPLEMENTATION_PLAN.md to mark SLC 5 complete
  - Update version to 1.4.0
  - **Test:** Documentation is accurate and helpful

---
<!-- CHECKPOINT: Phase 4 completes SLC 5. The app now supports English, Portuguese, and Spanish. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 6: Advanced Accessibility
- Dynamic Type support with adaptive layouts
- Reduced motion support for animations
- Color-blind safe patterns (diagonal stripes at >90%)
- High contrast mode support
- Yellow warning color fix (pattern-based solution for 2.1:1 contrast issue)
- **Research:** `specs/accessibility.md` lines 299-410

### SLC 7: Phase 2 Languages
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
- Plan badge auto-detection (requires Anthropic API support)
- Apple Developer ID signing and notarization
- Homebrew tap repository setup
- Historical usage graphs/trends visualization
- Widget support for Notification Center

### Technical Debt Identified
- Hysteresis values hardcoded (5%) - could be configurable
- Burn rate thresholds hardcoded (10/25/50% per hour)
- No integration tests with mock network layer
- Memory leak detection for long-running sessions

---

## Implementation Notes

### String Catalog Structure

The `.xcstrings` file should follow this structure:

```json
{
  "sourceLanguage": "en",
  "strings": {
    "usage.header.title": {
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Claude Usage" } },
        "pt-BR": { "stringUnit": { "state": "translated", "value": "Uso do Claude" } },
        "es": { "stringUnit": { "state": "translated", "value": "Uso de Claude" } }
      }
    }
  }
}
```

### Key Categories

Organize strings by feature:
- `usage.*` - Dropdown and progress bars (~20 strings)
- `settings.*` - Settings panel (~15 strings)
- `button.*` - Action buttons (~5 strings)
- `error.*` - Error states (~10 strings)
- `notification.*` - System notifications (~10 strings)
- `update.*` - Update checking (~5 strings)
- `accessibility.*` - VoiceOver labels (~15 strings)

### Testing Strategy

1. **Automated:** Unit tests verify all keys exist and have translations
2. **Manual:** Test with launch arguments:
   ```bash
   # In Xcode: Product > Scheme > Edit Scheme > Run > Arguments
   -AppleLanguages "(pt-BR)"
   -AppleLocale "pt_BR"
   ```
3. **Pseudo-localization:** Extend strings by 30% to test truncation

### Accessibility Considerations

- All accessibility labels must be localized
- VoiceOver announcements use `String(localized:)`
- Test VoiceOver in each supported language
- Ensure spoken numbers and dates are locale-appropriate

---

## Previous SLC Releases

### SLC 1: Usage Monitor - COMPLETE

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

### SLC 2: Notifications & Settings - COMPLETE

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

### SLC 3: Predictive Insights - COMPLETE

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

### SLC 4: Distribution Ready - COMPLETE

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

## Version History

| SLC | Name | Version | Tests | Status |
|-----|------|---------|-------|--------|
| 1 | Usage Monitor | 1.0.0 | 81 | COMPLETE |
| 2 | Notifications & Settings | 1.1.0 | 155 | COMPLETE |
| 3 | Predictive Insights | 1.2.0 | 320 | COMPLETE |
| 4 | Distribution Ready | 1.3.0 | 369 | COMPLETE |
| 5 | Internationalization | 1.4.0 | ~385 | **PLANNED** |
