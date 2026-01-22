# Implementation Plan

## Recommended SLC Release: Predictive Insights (SLC 3)

**Audience:** Professional developers using Claude Code (Pro, Max 5x, Max 20x plans) who want to anticipate when they'll hit limits and plan their work sessions accordingly.

**Value proposition:** Know not just where you are, but where you're going. See consumption velocity at a glance, get time-to-exhaustion predictions, and plan your Claude sessions with confidence. This transforms ClaudeApp from showing "what is" to predicting "what will be."

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| Burn Rate Tracking | Basic | Core value: understand consumption velocity (Job 4b) |
| Time-to-Exhaustion | Basic | Core value: predict when limit will be reached (Job 4a) |
| Update Checking | Basic | Quality of life: stay current with new versions (Job 9) |

**What's NOT in this slice:**
- Historical usage graphs/trends → Future
- Accessibility polish (VoiceOver, keyboard nav) → SLC 4
- Distribution tooling (signed DMG, Homebrew) → SLC 4
- Internationalization → Future
- Widget support → Future

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| Burn Rate Spec | `specs/features/view-usage.md` | NEW requirements section with thresholds and UI design |
| Architecture | `specs/architecture.md` | BurnRateCalculator patterns, UsageSnapshot model |
| GitHub Releases API | `research/apis/github-releases.md` | Complete API reference with Swift models |
| Inspiration | `research/inspiration.md` | ccusage-monitor shows 195-line minimal approach |
| Design System | `specs/design-system.md` | Color tokens for burn rate badges |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Users get predictive insights that enable proactive session planning.
     The burn rate indicator answers "am I burning through quota quickly?"
     Time-to-exhaustion answers "when will I hit my limit?"
     Combined with existing notifications, this creates a complete picture. -->

## Phase 1: Burn Rate Domain Models - CRITICAL

Build the foundational data structures for burn rate tracking.

- [x] **Implement BurnRate and BurnRateLevel domain models** [spec: features/view-usage.md] [file: Packages/Domain/Sources/Domain/]
  - Create `BurnRate` struct with `percentPerHour: Double` property
  - Create `level: BurnRateLevel` computed property based on thresholds
  - Create `displayString` computed property ("15%/hr" format)
  - Create `BurnRateLevel` enum with cases: low, medium, high, veryHigh
  - Add `color` property returning semantic color name (green/yellow/orange/red)
  - Ensure `Sendable`, `Equatable`, `Codable` conformance
  - **Research:** `specs/features/view-usage.md` lines 63-69 for thresholds
  - **Thresholds:** <10%/hr = Low, 10-25%/hr = Medium, 25-50%/hr = High, >50%/hr = Very High
  - ✅ Completed: 17 tests added covering all threshold boundaries and conformances

- [ ] **Extend UsageWindow with burn rate properties** [spec: features/view-usage.md] [file: Packages/Domain/Sources/Domain/UsageWindow.swift]
  - Add optional `burnRate: BurnRate?` property
  - Add optional `timeToExhaustion: TimeInterval?` property
  - Update initializer with new optional parameters (default nil)
  - Maintain backward compatibility with existing code
  - **Note:** These start nil and get enriched by BurnRateCalculator

- [ ] **Extend UsageData with highestBurnRate computed property** [spec: features/view-usage.md] [file: Packages/Domain/Sources/Domain/UsageData.swift]
  - Add `highestBurnRate: BurnRate?` computed property
  - Returns the highest burn rate across all windows (fiveHour, sevenDay, opus, sonnet)
  - Used for the header badge in dropdown
  - **Research:** `specs/architecture.md` lines 143-147 for implementation pattern

---
<!-- CHECKPOINT: Phase 1 adds domain models. Verify: BurnRate struct compiles, UsageWindow accepts optional burn rate, UsageData.highestBurnRate returns correct value. Run existing tests - they should still pass. -->

## Phase 2: Burn Rate Calculator - CRITICAL

Implement the calculation logic for burn rates and time-to-exhaustion.

- [ ] **Create UsageSnapshot model for history tracking** [spec: architecture.md] [file: Packages/Core/Sources/Core/]
  - Create `UsageSnapshot` struct with: fiveHourUtilization, sevenDayUtilization, opusUtilization?, sonnetUtilization?, timestamp
  - Make it `Sendable` for actor use
  - This is internal to Core package (not exported to Domain)
  - **Note:** Will be stored in an array in UsageManager

- [ ] **Implement BurnRateCalculator** [spec: architecture.md] [file: Packages/Core/Sources/Core/BurnRateCalculator.swift]
  - Create `BurnRateCalculator` struct (Sendable for thread safety)
  - Method: `calculate(from snapshots: [(utilization: Double, timestamp: Date)]) -> BurnRate?`
  - Requires minimum 2 samples to calculate
  - Use oldest and newest snapshots: `(newest.util - oldest.util) / timeDiffHours`
  - Only return positive burn rates (consumption, not reset)
  - Return nil if insufficient data or during reset period
  - Method: `timeToExhaustion(currentUtilization: Double, burnRate: BurnRate?) -> TimeInterval?`
  - Formula: `(100 - currentUtilization) / burnRate.percentPerHour * 3600`
  - Return 0 if already at 100%, nil if no burn rate
  - **Research:** `specs/architecture.md` lines 564-602 for full implementation pattern

- [ ] **Integrate burn rate calculation into UsageManager** [spec: architecture.md] [file: Packages/Core/Sources/Core/UsageManager.swift]
  - Add `usageHistory: [UsageSnapshot]` private property
  - Add `maxHistoryCount = 12` constant (1 hour at 5-min intervals)
  - Add `burnRateCalculator = BurnRateCalculator()` property
  - In `refresh()`: after fetching data, call `recordSnapshot()` then `enrichWithBurnRates()`
  - `recordSnapshot()`: Insert new snapshot, trim if > maxHistoryCount
  - `enrichWithBurnRates()`: Calculate burn rates for each window, create enriched UsageData
  - Add `overallBurnRateLevel: BurnRateLevel?` computed property for header badge
  - **Note:** History resets on app restart (acceptable for v1)

- [ ] **Add comprehensive tests for BurnRateCalculator** [file: Packages/Core/Tests/CoreTests/]
  - Test calculate() with 2 samples (minimum)
  - Test calculate() with 12 samples (full history)
  - Test calculate() returns nil with 1 sample
  - Test calculate() returns nil during reset (negative rate)
  - Test timeToExhaustion() at various utilizations
  - Test timeToExhaustion() returns 0 at 100%
  - Test timeToExhaustion() returns nil without burn rate
  - Test BurnRateLevel thresholds (edge cases at 10, 25, 50)
  - Target: 100% coverage for calculator logic

---
<!-- CHECKPOINT: Phase 2 delivers calculation logic. Verify: BurnRateCalculator returns correct rates, UsageManager enriches data, history accumulates across refreshes. -->

## Phase 3: Burn Rate UI

Add visual indicators for burn rate and time-to-exhaustion.

- [ ] **Create BurnRateBadge component** [spec: features/view-usage.md] [file: App/ClaudeApp.swift]
  - Create `BurnRateBadge` view showing burn rate level as colored pill
  - Input: `burnRateLevel: BurnRateLevel?`
  - Show nothing if nil (insufficient data)
  - Colors: Low=green, Medium=yellow, High=orange, Very High=red
  - Font: caption, padding: horizontal 6pt
  - Position: In dropdown header between title and buttons
  - **Research:** `specs/design-system.md` for color tokens, `specs/features/view-usage.md` lines 188-198

- [ ] **Add time-to-exhaustion display to UsageProgressBar** [spec: features/view-usage.md] [file: App/ClaudeApp.swift]
  - Extend UsageProgressBar to accept optional `timeToExhaustion: TimeInterval?`
  - Display format: "~2h until limit" or "~45min until limit"
  - Only show when: utilization > 20% AND timeToExhaustion is not nil
  - Position: Below reset time, same tertiary styling
  - Show "—" when insufficient data but utilization > 50%
  - **Research:** `specs/features/view-usage.md` lines 129-146 for layout

- [ ] **Integrate burn rate into dropdown header** [spec: features/view-usage.md] [file: App/ClaudeApp.swift]
  - Add BurnRateBadge to DropdownView header
  - Get level from `usageManager.overallBurnRateLevel`
  - Position between "Claude Usage" title and settings button
  - Only show when burn rate data is available
  - **Layout:** `HStack { Title, Spacer, BurnRateBadge, SettingsButton, RefreshButton }`

- [ ] **Update UsageProgressBar instances with time-to-exhaustion** [file: App/ClaudeApp.swift]
  - Pass `timeToExhaustion` from each UsageWindow to UsageProgressBar
  - Update for: fiveHour, sevenDay, sevenDayOpus, sevenDaySonnet
  - Only show if window has calculable time-to-exhaustion
  - **Note:** First few refreshes won't have data - graceful degradation

---
<!-- CHECKPOINT: Phase 3 delivers burn rate UI. Test: run app, wait for 2-3 refresh cycles, verify badge appears, verify time-to-exhaustion shows for active windows. -->

## Phase 4: Update Checking

Implement version checking via GitHub Releases API.

- [ ] **Create UpdateChecker actor** [spec: features/updates.md] [file: Packages/Core/Sources/Core/UpdateChecker.swift]
  - Create `actor UpdateChecker` for thread-safe version checking
  - Properties: `repoOwner`, `repoName`, `lastCheckDate`, `lastNotifiedVersion`
  - Method: `check() async -> CheckResult` (upToDate, updateAvailable(info), error)
  - Method: `checkInBackground() async` - only if >24 hours since last check
  - Internal: `isVersion(_:newerThan:) -> Bool` for semantic version comparison
  - **Research:** `research/apis/github-releases.md` lines 74-176 for full implementation

- [ ] **Create GitHub API models** [spec: features/updates.md] [file: Packages/Core/Sources/Core/]
  - Create `GitHubRelease` struct: tagName, name, htmlUrl, publishedAt, body, assets
  - Create `GitHubAsset` struct: name, browserDownloadUrl
  - Use CodingKeys for snake_case to camelCase mapping
  - Create `UpdateInfo` struct: version, downloadURL, releaseURL, releaseNotes
  - Create `CheckResult` enum: upToDate, updateAvailable(UpdateInfo), error(Error)
  - **Research:** `research/apis/github-releases.md` lines 179-206 for models

- [ ] **Integrate update checking into app lifecycle** [file: App/ClaudeApp.swift, Packages/Core/Sources/Core/AppContainer.swift]
  - Add `updateChecker: UpdateChecker` to AppContainer
  - Check for updates 5 seconds after app launch (non-blocking)
  - Only check if `settings.checkForUpdates` is true
  - Show notification if update found (use NotificationManager)
  - Track lastNotifiedVersion to avoid spam
  - **Note:** Respect 24-hour rate limit for auto-checks

- [ ] **Implement update UI in Settings About section** [file: App/ClaudeApp.swift]
  - Enable the currently-disabled "Check for Updates" button
  - Add state: `checkResult: UpdateChecker.CheckResult?`, `isChecking: Bool`
  - Show loading spinner while checking
  - Show "Up to date" with checkmark (green) - auto-dismiss after 3 seconds
  - Show "Version X.Y.Z available" with "Download" button
  - Download button opens browser to release/download URL
  - Show error state briefly if check fails
  - **Research:** `specs/features/updates.md` lines 229-304 for UI implementation

---
<!-- CHECKPOINT: Phase 4 delivers update checking. Test: click "Check for Updates", verify correct state display, verify download button opens correct URL. -->

## Phase 5: Polish & Code Organization

Clean up and prepare for release.

- [ ] **Refactor UI components into UI package** [file: Packages/UI/Sources/UI/]
  - Move from App/ClaudeApp.swift to UI package:
    - `UsageProgressBar` component
    - `BurnRateBadge` component
    - `SettingsToggle` component
    - `SectionHeader` component
    - Theme/color constants
  - Update imports in App/ClaudeApp.swift
  - Reduces monolithic file from ~1000 lines to ~300 lines
  - **Note:** Keep views that depend on specific Environment objects in App

- [ ] **Add UI tests for burn rate display** [file: Tests/UITests/]
  - Snapshot test: BurnRateBadge at each level (Low/Medium/High/Very High)
  - Snapshot test: UsageProgressBar with and without time-to-exhaustion
  - Verify colors match design system
  - **Note:** Use Swift snapshot testing library if available, or manual verification

- [ ] **Update documentation and version** [file: various]
  - Update README with burn rate feature description
  - Update version to 1.2.0 (or appropriate SLC 3 version)
  - Update IMPLEMENTATION_PLAN.md to mark SLC 3 complete
  - Add changelog entry for new features

---
<!-- CHECKPOINT: Phase 5 completes SLC 3. The app now predicts usage exhaustion, shows consumption velocity, and checks for updates. Code is better organized. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 4: Distribution & Accessibility
- Full accessibility audit (VoiceOver labels, keyboard navigation, focus states)
- Homebrew Cask formula for easy installation
- Signed DMG creation with Apple Developer ID
- CI/CD pipeline with GitHub Actions for automated releases
- **Research:** `specs/accessibility.md`, `specs/toolchain.md`

### Future Releases
- Historical usage graphs/trends visualization
- Burn rate trends over time (is my velocity increasing?)
- Plan type auto-detection from API (remove hardcoded "Pro")
- Quiet hours setting (pause notifications during focus time)
- Different sounds per notification type
- Internationalization (multiple languages)
- Widget support for Notification Center
- Local JSONL fallback when API unavailable
- Export/import settings
- **Research:** `specs/internationalization.md`, `specs/features/refresh-usage.md`

### Technical Debt Identified
- Custom Claude brand icon (replace SF symbol "sparkle" placeholder)
- Integration tests with mock network layer
- API retry with exponential backoff for rate limits
- Keychain error recovery mechanism

---

## Implementation Notes

### Burn Rate Thresholds (from specs/features/view-usage.md)
| Level | Rate (%/hr) | Color | User Meaning |
|-------|-------------|-------|--------------|
| Low | < 10 | Green (#22C55E) | Sustainable pace |
| Medium | 10-25 | Yellow (#EAB308) | Moderate consumption |
| High | 25-50 | Orange (#F97316) | Heavy usage |
| Very High | > 50 | Red (#C15F3C) | Will exhaust quickly |

### Time-to-Exhaustion Display Rules
- Only show when utilization > 20% (avoid noise at low usage)
- Only show when burn rate is calculable (need 2+ samples)
- Format: "~Xh until limit" or "~Xmin until limit"
- Use ~ prefix to indicate estimate nature
- Show "—" when data insufficient but utilization warrants display

### Usage History Strategy
- Keep last 12 samples (1 hour at 5-min intervals)
- In-memory only (resets on app restart) - acceptable for v1
- Future: persist to UserDefaults for cross-session history

### GitHub API Rate Limits
- Unauthenticated: 60 requests/hour (plenty for once-per-24h checks)
- No auth token needed for public repo releases
- Cache lastCheckDate to enforce 24-hour minimum

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

---

### SLC 2: Notifications & Settings ✅ COMPLETE

All tasks completed with 155 passing tests.

**Phase 1: Settings Infrastructure** ✅
- [x] Implement SettingsManager with @Observable state and UserDefaults persistence
- [x] Implement LaunchAtLoginManager using SMAppService
- [x] Build Settings window with all sections
- [x] Connect settings to existing UI (menu bar display + refresh interval)

**Phase 2: Notification System** ✅
- [x] Implement NotificationManager actor with permission handling
- [x] Implement notification trigger logic with hysteresis
- [x] Integrate notifications into UsageManager refresh cycle
- [x] Add notification permission UI and denied state handling

**Phase 3: Polish & Testing** ✅
- [x] Add comprehensive tests for Settings and Notifications (155 tests)
- [x] Implement settings button and window lifecycle
