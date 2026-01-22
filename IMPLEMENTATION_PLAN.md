# Implementation Plan

## Recommended SLC Release: Usage Monitor

**Audience:** Professional developers using Claude Code (Pro, Max 5x, Max 20x plans) who want to monitor their usage limits without interrupting their workflow.

**Value proposition:** Glanceable menu bar monitoring that shows your Claude usage at a glance—percentage in the menu bar, detailed breakdown in a click. Never be surprised by hitting limits again.

**Activities included:**

| Activity | Depth | Why Included |
|----------|-------|--------------|
| View Usage | Basic | Core job: see usage at a glance (< 1 second) |
| Refresh Usage | Basic | Keeps data current with auto-refresh |

**What's NOT in this slice:**
- Notifications (warning alerts, capacity full, reset complete) → SLC 2
- Settings panel (configurable thresholds, display options) → SLC 2
- Launch at Login → SLC 2
- Update checking → SLC 3
- Accessibility polish (VoiceOver, keyboard nav) → SLC 3
- Internationalization → Future

---

## Research References

Key research documents for this implementation:

| Topic | Document | Why Relevant |
|-------|----------|--------------|
| OAuth API | `research/apis/anthropic-oauth.md` | Endpoint, headers, response schema |
| Keychain | `research/approaches/keychain-access.md` | Read Claude Code credentials |
| Menu Bar | `research/approaches/menubar-extra.md` | Native MenuBarExtra implementation |
| Inspiration | `research/inspiration.md` | UI patterns from similar apps |

---
<!-- HUMAN VERIFICATION: Does this slice form a coherent, valuable product? -->
<!-- Answer: YES - Users can monitor all usage windows, see reset times, and plan their Claude Code sessions. This solves the primary JTBD completely. -->

## Phase 1: Project Foundation

Establish the project structure, build system, and domain models that all features depend on.

- [x] **Initialize Swift Package project with modular architecture** [spec: architecture.md]
  - Create Package.swift with 4-package structure (Domain, Services, Core, UI)
  - Set up App target that imports all packages
  - Configure macOS 14+ deployment target and Swift 5.9+
  - Add Info.plist with LSUIElement=YES (menu bar only)
  - Create Makefile with build, run, clean, test targets
  - **Research:** `specs/architecture.md` for package structure, `specs/toolchain.md` for Makefile
  - **Note:** SPM doesn't support Info.plist as a resource; for menu bar app LSUIElement behavior, the app relies on MenuBarExtra which works without explicit plist configuration

- [x] **Implement Domain models and protocols** [spec: architecture.md, api-documentation.md]
  - Create `UsageData` struct with four `UsageWindow` properties
  - Create `UsageWindow` struct (utilization: Double, resetsAt: Date?)
  - Create `Credentials` struct (accessToken: String, expiresAt: Date?)
  - Create `AppError` enum (notAuthenticated, networkError, apiError, keychainError)
  - Define `UsageRepository` protocol with `fetchUsage() async throws -> UsageData`
  - Define `CredentialsRepository` protocol with `getCredentials() async throws -> Credentials`
  - All types must be `Sendable`
  - **Research:** `research/apis/anthropic-oauth.md` for response schema and Swift types
  - **Note:** Added `rateLimited(retryAfter: Int)` case to AppError for 429 handling. All Domain types require `import Foundation` for `Date` type.

- [x] **Implement Keychain credentials repository** [spec: api-documentation.md]
  - Create `KeychainCredentialsRepository` actor implementing `CredentialsRepository`
  - Use `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`
  - Parse JSON response with `claudeAiOauth.accessToken` extraction
  - Handle missing keychain entry → throw `AppError.notAuthenticated`
  - Handle invalid JSON → throw `AppError.keychainError`
  - **Research:** `research/approaches/keychain-access.md` for implementation pattern
  - **Note:** Actor-based implementation ensures thread-safety. Internal JSON models (`KeychainCredentials`, `OAuthCredentials`) handle the nested JSON structure from Claude Code.

- [x] **Implement Claude API client** [spec: api-documentation.md]
  - Create `ClaudeAPIClient` actor implementing `UsageRepository`
  - Endpoint: `GET https://api.anthropic.com/api/oauth/usage`
  - Required headers: Authorization Bearer, anthropic-beta: oauth-2025-04-20
  - Parse ISO8601 dates with fractional seconds (custom decoder)
  - Map API response to domain `UsageData`
  - Handle 401 → `AppError.notAuthenticated`, 429 → `AppError.rateLimited` with retry-after
  - **Research:** `research/apis/anthropic-oauth.md` for complete API reference
  - **Note:** Actor-based implementation with dependency injection for testability. Internal `APIUsageResponse` and `APIUsageWindow` models handle snake_case API response. Added 13 new tests for API client and response parsing (total 53 tests passing).

---
<!-- CHECKPOINT: Phase 1 delivers the data layer. Verify credentials read and API calls work before UI. -->

## Phase 2: Menu Bar UI

Build the visible product: menu bar icon with percentage and dropdown with detailed usage.

- [x] **Create menu bar app entry point with MenuBarExtra** [spec: features/view-usage.md]
  - Set up `@main` App struct with MenuBarExtra scene
  - Use `.menuBarExtraStyle(.window)` for custom SwiftUI content
  - Create `AppContainer` for dependency injection (credentials repo → API client → usage manager)
  - Pass `UsageManager` via SwiftUI Environment
  - **Research:** `research/approaches/menubar-extra.md` for MenuBarExtra setup
  - **Note:** Implemented in App/ClaudeApp.swift with AppContainer in Core package. Uses SwiftUI Environment to pass UsageManager to views.

- [x] **Implement UsageManager with @Observable state** [spec: architecture.md]
  - Create `@MainActor @Observable class UsageManager`
  - State: `usageData: UsageData?`, `isLoading: Bool`, `lastError: AppError?`, `lastUpdated: Date?`
  - Computed: `highestUtilization` (max across all windows)
  - Method: `refresh() async` - fetches from repository, updates state
  - Method: `startAutoRefresh(interval: TimeInterval)` - background Task loop
  - Method: `stopAutoRefresh()` - cancels refresh Task
  - **Research:** `specs/architecture.md` for state management patterns
  - **Note:** Implemented in Packages/Core/Sources/Core/UsageManager.swift with 11 new tests covering state management, concurrent refresh prevention, error handling, and auto-refresh lifecycle.

- [x] **Build menu bar label view** [spec: features/view-usage.md, design-system.md]
  - Display Claude icon (16x16 template image) + percentage text
  - Percentage: SF Mono 12pt medium, monospacedDigit()
  - States: normal (icon + %), loading (icon + spinner), error (icon + "--")
  - 4px spacing between icon and text
  - **Research:** `specs/design-system.md` for typography and spacing
  - **Note:** Implemented MenuBarLabel view in App/ClaudeApp.swift. Uses SF symbol "sparkle" as placeholder icon until brand icon is added. Shows loading spinner when no data, percentage when available, "--" on error.

- [x] **Build dropdown view with usage bars** [spec: features/view-usage.md, design-system.md]
  - Fixed 280px width, 12px corner radius, 16px padding
  - Solid opaque background: `Color(nsColor: .windowBackgroundColor)`
  - Header: title "Claude Usage", refresh button (circular arrow)
  - Four progress bars: 5-hour session, 7-day all, 7-day Opus, 7-day Sonnet
  - Each bar: label, percentage (monospaced), 6px height bar, reset time
  - Footer: "Last updated" timestamp, quit button
  - Color thresholds: green (0-49%), yellow (50-89%), red (90-100%)
  - **Research:** `specs/design-system.md` for colors and component patterns
  - **Note:** Implemented DropdownView, UsageContent, UsageProgressBar, LoadingView, ErrorView, EmptyStateView components. Progress bars use green/yellow/red colors based on utilization thresholds. Error states show specific messages for notAuthenticated, networkError, rateLimited, etc.

---
<!-- CHECKPOINT: Phase 2 delivers the complete visible product. Test manually: menu bar shows %, click opens dropdown with all 4 usage windows. -->

## Phase 3: Refresh & Polish

Add auto-refresh, manual refresh interactions, and loading/error states.

- [x] **Implement auto-refresh lifecycle** [spec: features/refresh-usage.md]
  - Start auto-refresh on app launch (5-minute interval)
  - Pause during system sleep (NSWorkspace notifications)
  - Resume 5 seconds after wake
  - Cancel on app termination
  - Exponential backoff on errors: 1m → 2m → 4m → max 15m
  - Reset backoff on successful refresh
  - **Research:** `specs/features/refresh-usage.md` for lifecycle and backoff strategy
  - **Note:** Implemented in UsageManager with exponential backoff (consecutiveFailures counter, retryInterval computed property). AppContainer now starts auto-refresh on production init and registers NSWorkspace sleep/wake observers. Auth errors (notAuthenticated) don't trigger retry, rate-limited errors use server-provided retry-after. Added 11 new tests for backoff and sleep/wake handling (total 75 tests passing).

- [x] **Implement manual refresh with button states** [spec: features/refresh-usage.md]
  - Refresh button in dropdown header (Cmd+R keyboard shortcut)
  - Button states: idle (arrow), loading (spinner), success (checkmark 1s), error (warning icon)
  - Debounce: prevent concurrent refresh requests
  - Auto-refresh on dropdown open if data stale (> 1 minute old)
  - **Research:** `specs/features/refresh-usage.md` for interaction patterns
  - **Note:** Added RefreshState enum in Core package with idle/loading/success/error states. RefreshButton component shows state-based icons with color feedback (green for success, red for error). Added isStale computed property (>60s threshold). Auto-refresh triggers on dropdown open when stale. Cmd+R keyboard shortcut added to both dropdown and button. 6 new tests for isStale and refreshState (total 81 tests passing).

- [ ] **Implement error and loading states** [spec: features/view-usage.md]
  - Loading: show skeleton/spinner in dropdown while fetching
  - Not authenticated: message with "Run `claude login` in terminal" guidance
  - Network error: show cached data with "stale" indicator, retry button
  - Display `lastUpdated` timestamp in footer
  - **Research:** `specs/features/view-usage.md` for state designs

---
<!-- CHECKPOINT: Phase 3 completes the SLC. The app now monitors usage continuously, handles errors gracefully, and provides a polished experience. -->

## Future Work (Outside Current Scope)

The following items were identified during analysis but are deferred to maintain SLC focus:

### SLC 2: Notifications & Settings
- Usage warning notifications at configurable threshold (default 90%)
- Capacity full notifications (100%)
- Reset complete notifications
- Settings panel with all configuration options
- Launch at Login toggle
- Configurable refresh interval (1-30 minutes)
- Display preferences (show plan badge, percentage source)
- **Research:** `research/approaches/system-notifications.md`, `research/approaches/launch-at-login.md`

### SLC 3: Distribution & Polish
- Update checking via GitHub Releases API
- Accessibility (VoiceOver, keyboard navigation)
- Homebrew Cask formula
- DMG creation script
- CI/CD with GitHub Actions
- **Research:** `research/apis/github-releases.md`, `specs/accessibility.md`, `specs/toolchain.md`

### Future Releases
- Internationalization (multiple languages)
- Local JSONL fallback when API unavailable
- Historical usage trends
- Widget support
- **Research:** `specs/internationalization.md`, `specs/api-documentation.md` (fallback section)

---

## Implementation Notes

### Performance Targets (from specs/performance.md)
- Memory: < 15 MB idle, < 25 MB active
- CPU: < 0.1% idle, < 2% during refresh
- Startup: < 500ms to menu bar visible
- Energy: "Low" impact in Activity Monitor

### Design Tokens (from specs/design-system.md)
- Primary color: #C15F3C (Crail)
- Success: #22C55E (green)
- Warning: #EAB308 (yellow)
- Danger: #C15F3C (red)
- Spacing: xs=4, sm=8, md=12, lg=16, xl=24
- Corner radius: sm=4, md=8, lg=12

### API Requirements (from research/apis/anthropic-oauth.md)
- Endpoint: `GET https://api.anthropic.com/api/oauth/usage`
- Header: `anthropic-beta: oauth-2025-04-20` (required)
- ISO 8601 dates with fractional seconds
- Handle null `seven_day_opus` and `seven_day_sonnet`
