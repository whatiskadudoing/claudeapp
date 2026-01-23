import Core
import Domain
import SwiftUI
import UI
import UserNotifications

// MARK: - Notification Delegate

/// Handles notification interactions (clicks, actions).
/// Configured at app launch to handle notification responses.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// Called when user interacts with a notification (clicks it).
    /// Opens the dropdown by activating the app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Activate the app - this will show the menu bar dropdown
        NSApp.activate(ignoringOtherApps: true)
        completionHandler()
    }

    /// Called when notification should be presented while app is in foreground.
    /// Shows the notification banner even when app is active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

@main
struct ClaudeApp: App {
    @State private var container: AppContainer
    private let notificationDelegate = NotificationDelegate()

    init() {
        _container = State(initialValue: AppContainer())

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        MenuBarExtra {
            DropdownView()
                .environment(container.usageManager)
                .environment(container.settingsManager)
                .environment(container.launchAtLoginManager)
        } label: {
            MenuBarLabel()
                .environment(container.usageManager)
                .environment(container.settingsManager)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Window("Settings", id: "settings") {
            SettingsView(updateChecker: container.updateChecker)
                .environment(container.settingsManager)
                .environment(container.launchAtLoginManager)
                .environment(container.notificationPermissionManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Menu Bar Label

/// The label displayed in the macOS menu bar.
/// Shows Claude icon + percentage or loading/error state.
/// Respects display settings: showPercentage, percentageSource, showPlanBadge.
struct MenuBarLabel: View {
    @Environment(UsageManager.self) private var usageManager
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkle")
                .font(.system(size: 14))

            if usageManager.isLoading && usageManager.usageData == nil {
                ProgressView()
                    .controlSize(.small)
            } else if let data = usageManager.usageData {
                if settings.showPercentage {
                    Text("\(Int(data.utilization(for: settings.percentageSource)))%")
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                }

                if settings.showPlanBadge {
                    PlanBadgeLabel()
                }
            } else {
                if settings.showPercentage {
                    Text("--")
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
    }
}

// MARK: - Plan Badge Label

/// A small label showing the user's plan type in the menu bar.
/// Note: Plan type detection is not yet implemented (would require API support).
/// For now, this displays a placeholder badge.
struct PlanBadgeLabel: View {
    var body: some View {
        Text("Pro")
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Theme.Colors.primary.opacity(0.2))
            .foregroundStyle(Theme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Dropdown View

/// The dropdown content that appears when clicking the menu bar item.
/// Shows detailed usage information with progress bars.
struct DropdownView: View {
    @Environment(UsageManager.self) private var usageManager
    @Environment(\.openWindow) private var openWindow

    /// Whether we have an error but also have cached data to show
    private var hasErrorWithCachedData: Bool {
        usageManager.lastError != nil && usageManager.usageData != nil
    }

    /// Whether data should be considered stale (error occurred or data is old)
    private var isDataStale: Bool {
        usageManager.lastError != nil || usageManager.isStale
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Claude Usage")
                    .font(.headline)
                Spacer()
                // Show burn rate badge when available
                if let burnRateLevel = usageManager.usageData?.highestBurnRate?.level {
                    BurnRateBadge(level: burnRateLevel)
                }
                SettingsButton {
                    openWindow(id: "settings")
                }
                RefreshButton()
            }

            Divider()

            // Content
            if let data = usageManager.usageData {
                // Show error banner if we have cached data but encountered an error
                if hasErrorWithCachedData, let error = usageManager.lastError {
                    StaleDataBanner(error: error) {
                        Task { await usageManager.refresh() }
                    }
                }
                UsageContent(data: data)
            } else if usageManager.isLoading {
                LoadingView()
            } else if let error = usageManager.lastError {
                ErrorView(error: error) {
                    Task { await usageManager.refresh() }
                }
            } else {
                EmptyStateView {
                    Task { await usageManager.refresh() }
                }
            }

            Divider()

            // Footer
            HStack {
                if hasErrorWithCachedData {
                    // Show stale warning when we have error with cached data
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Data may be stale")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if let lastUpdated = usageManager.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .keyboardShortcut("r", modifiers: .command)
        .task {
            // Refresh on dropdown open if data is stale or missing
            if usageManager.usageData == nil || usageManager.isStale {
                await usageManager.refresh()
            }
        }
    }
}

// MARK: - Settings Button

/// Button to open the settings window.
struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(",", modifiers: .command)
    }
}

// MARK: - Refresh Button

/// Button for manual refresh with visual state feedback.
/// Shows different icons based on refresh state: idle, loading, success, error.
struct RefreshButton: View {
    @Environment(UsageManager.self) private var usageManager

    var body: some View {
        Button {
            Task { await usageManager.refresh() }
        } label: {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .rotationEffect(.degrees(usageManager.refreshState == .loading ? 360 : 0))
                .animation(
                    usageManager.refreshState == .loading
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                    value: usageManager.refreshState
                )
        }
        .buttonStyle(.plain)
        .disabled(usageManager.isLoading)
        .keyboardShortcut("r", modifiers: .command)
    }

    private var iconName: String {
        switch usageManager.refreshState {
        case .idle:
            "arrow.clockwise"
        case .loading:
            "arrow.clockwise"
        case .success:
            "checkmark.circle"
        case .error:
            "exclamationmark.circle"
        }
    }

    private var iconColor: Color {
        switch usageManager.refreshState {
        case .idle, .loading:
            .primary
        case .success:
            .green
        case .error:
            .red
        }
    }
}

// MARK: - Usage Content

/// Displays the usage progress bars when data is available.
/// Passes time-to-exhaustion data from UsageWindow to each progress bar.
struct UsageContent: View {
    let data: UsageData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            UsageProgressBar(
                value: data.fiveHour.utilization,
                label: "Current Session (5h)",
                resetsAt: data.fiveHour.resetsAt,
                timeToExhaustion: data.fiveHour.timeToExhaustion
            )

            UsageProgressBar(
                value: data.sevenDay.utilization,
                label: "Weekly (All Models)",
                resetsAt: data.sevenDay.resetsAt,
                timeToExhaustion: data.sevenDay.timeToExhaustion
            )

            if let opus = data.sevenDayOpus {
                UsageProgressBar(
                    value: opus.utilization,
                    label: "Weekly (Opus)",
                    resetsAt: opus.resetsAt,
                    timeToExhaustion: opus.timeToExhaustion
                )
            }

            if let sonnet = data.sevenDaySonnet {
                UsageProgressBar(
                    value: sonnet.utilization,
                    label: "Weekly (Sonnet)",
                    resetsAt: sonnet.resetsAt,
                    timeToExhaustion: sonnet.timeToExhaustion
                )
            }
        }
    }
}

// MARK: - Stale Data Banner

/// Banner displayed when we have cached data but encountered an error on refresh.
/// Shows a warning with the error reason and a retry button.
struct StaleDataBanner: View {
    let error: AppError
    let retryAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Unable to refresh")
                    .font(.caption)
                    .fontWeight(.medium)
                Text(errorReason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Retry", action: retryAction)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.bottom, 4)
    }

    private var errorReason: String {
        switch error {
        case .networkError:
            "Connection issue"
        case .rateLimited(let retryAfter):
            "Rate limited (\(retryAfter)s)"
        case .apiError(let statusCode, _):
            "Server error (\(statusCode))"
        case .notAuthenticated:
            "Authentication required"
        case .keychainError:
            "Keychain error"
        case .decodingError:
            "Data format error"
        }
    }
}

// MARK: - Loading View

/// Displayed while fetching initial data.
struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading usage data...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Error View

/// Displayed when an error occurs.
struct ErrorView: View {
    let error: AppError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: errorIcon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(errorTitle)
                .font(.caption)
                .fontWeight(.medium)

            Text(errorMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retryAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var errorIcon: String {
        switch error {
        case .notAuthenticated:
            "person.crop.circle.badge.questionmark"
        default:
            "exclamationmark.triangle"
        }
    }

    private var errorTitle: String {
        switch error {
        case .notAuthenticated:
            "Claude Code not found"
        case .networkError:
            "Connection Error"
        case .rateLimited:
            "Rate Limited"
        default:
            "Unable to load data"
        }
    }

    private var errorMessage: String {
        switch error {
        case .notAuthenticated:
            "Run `claude login` in terminal to connect"
        case .networkError(let message):
            message
        case .rateLimited(let retryAfter):
            "Please wait \(retryAfter) seconds"
        case .apiError(let statusCode, _):
            "Server error (\(statusCode))"
        case .keychainError(let message):
            message
        case .decodingError(let message):
            message
        }
    }
}

// MARK: - Empty State View

/// Displayed when no data is available and not loading.
struct EmptyStateView: View {
    let refreshAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No usage data")
                .font(.caption)
                .fontWeight(.medium)

            Button("Refresh", action: refreshAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings View

/// The main settings window showing all app configuration options.
/// Organized into sections: Display, Refresh, Notifications, General, About.
struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(LaunchAtLoginManager.self) private var launchAtLogin
    @Environment(\.dismiss) private var dismiss

    let updateChecker: UpdateChecker

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    DisplaySection()
                    RefreshSection()
                    NotificationsSection()
                    GeneralSection()
                    AboutSection(updateChecker: updateChecker)
                }
                .padding(16)
            }
        }
        .frame(width: 320, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Display Section

/// Settings for menu bar display options.
struct DisplaySection: View {
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Display")

            SettingsToggle(
                title: "Show Plan Badge",
                isOn: $settings.showPlanBadge,
                subtitle: "Display Pro, Max 5x, or Max 20x"
            )

            SettingsToggle(
                title: "Show Percentage",
                isOn: $settings.showPercentage
            )

            if settings.showPercentage {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Percentage Source")
                        .font(.body)

                    Picker("", selection: $settings.percentageSource) {
                        ForEach(PercentageSource.allCases, id: \.self) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
    }
}

// MARK: - Refresh Section

/// Settings for data refresh interval.
struct RefreshSection: View {
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Refresh")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Refresh Interval")
                    Spacer()
                    Text("\(settings.refreshInterval) min")
                        .foregroundStyle(.secondary)
                        .font(.body.monospacedDigit())
                }

                Slider(
                    value: Binding(
                        get: { Double(settings.refreshInterval) },
                        set: { settings.refreshInterval = Int($0) }
                    ),
                    in: 1...30,
                    step: 1
                )
                .controlSize(.small)

                HStack {
                    Text("1 min")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("30 min")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Notifications Section

/// Settings for notification preferences.
/// Handles permission status display and denied state UI.
struct NotificationsSection: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(NotificationPermissionManager.self) private var permissionManager

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notifications")

            // Enable toggle with permission request
            Toggle(isOn: Binding(
                get: { settings.notificationsEnabled },
                set: { newValue in
                    settings.notificationsEnabled = newValue
                    if newValue {
                        // Request permission when enabling notifications
                        Task {
                            await permissionManager.requestPermission()
                        }
                    }
                }
            )) {
                Text("Enable Notifications")
                    .font(.body)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            if settings.notificationsEnabled {
                // Permission denied warning banner
                if permissionManager.isPermissionDenied {
                    PermissionDeniedBanner()
                }

                // Only show settings when permission allows
                if permissionManager.canSendNotifications {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Warning Threshold")
                            Spacer()
                            Text("\(settings.warningThreshold)%")
                                .foregroundStyle(.secondary)
                                .font(.body.monospacedDigit())
                        }

                        Slider(
                            value: Binding(
                                get: { Double(settings.warningThreshold) },
                                set: { settings.warningThreshold = Int($0) }
                            ),
                            in: 50...99,
                            step: 1
                        )
                        .controlSize(.small)

                        HStack {
                            Text("50%")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text("99%")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Divider()

                    SettingsToggle(
                        title: "Usage Warnings",
                        isOn: $settings.warningEnabled,
                        subtitle: "When usage crosses threshold"
                    )

                    SettingsToggle(
                        title: "Capacity Full",
                        isOn: $settings.capacityFullEnabled,
                        subtitle: "When usage reaches 100%"
                    )

                    SettingsToggle(
                        title: "Reset Complete",
                        isOn: $settings.resetCompleteEnabled,
                        subtitle: "When limits reset"
                    )
                }
            }
        }
        .onAppear {
            // Re-check permission status when settings view opens
            Task {
                await permissionManager.refreshPermissionStatus()
            }
        }
    }
}

// MARK: - Permission Denied Banner

/// Banner shown when notification permission is denied.
/// Provides a button to open System Settings.
struct PermissionDeniedBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Notifications Disabled")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Text("Enable in System Settings > Notifications > ClaudeApp")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                openNotificationSettings()
            } label: {
                Text("Open System Settings")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func openNotificationSettings() {
        // Open System Settings to Notifications pane
        // The URL scheme opens the Notifications section
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - General Section

/// General app settings like launch at login.
struct GeneralSection: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(LaunchAtLoginManager.self) private var launchAtLogin

    var body: some View {
        @Bindable var launchAtLogin = launchAtLogin
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "General")

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: $launchAtLogin.isEnabled) {
                    Text("Launch at Login")
                        .font(.body)
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                if launchAtLogin.requiresUserApproval {
                    Button {
                        openLoginItemsSettings()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Requires approval in System Settings")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }

                if let error = launchAtLogin.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            SettingsToggle(
                title: "Check for Updates",
                isOn: $settings.checkForUpdates,
                subtitle: "Automatically check on launch"
            )
        }
    }

    private func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - About Section

/// About section showing app info, version checking, and links.
struct AboutSection: View {
    let updateChecker: UpdateChecker

    @State private var checkResult: CheckResult?
    @State private var isChecking = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About")

            VStack(spacing: 12) {
                // App icon
                Image(systemName: "sparkle")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primary)

                Text("ClaudeApp")
                    .font(.headline)

                Text("v\(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Update check UI
                updateStatusView

                // Links
                HStack(spacing: 8) {
                    if let githubURL = URL(string: "https://github.com/anthropics/claude-code") {
                        Link("GitHub", destination: githubURL)
                    }
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("Monitor your Claude usage")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    /// View showing update check status (button, checking spinner, or result)
    @ViewBuilder
    private var updateStatusView: some View {
        switch (isChecking, checkResult) {
        case (true, _):
            // Loading state
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case (false, nil):
            // Default state: show button
            Button("Check for Updates") {
                checkForUpdates()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case (false, .upToDate):
            // Up to date state
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("You're up to date")
            }
            .font(.caption)

        case (false, .updateAvailable(let info)):
            // Update available state
            VStack(spacing: 8) {
                Text("Version \(info.version) available")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Download") {
                    NSWorkspace.shared.open(info.downloadURL)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

        case (false, .rateLimited):
            // Rate limited state (try again later)
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.secondary)
                Text("Try again later")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

        case (false, .error):
            // Error state
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Unable to check")
                }
                .font(.caption)

                // Show brief error, allow retry
                Button("Retry") {
                    checkForUpdates()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
    }

    /// Initiates an update check
    private func checkForUpdates() {
        isChecking = true
        checkResult = nil

        Task {
            let result = await updateChecker.check()

            await MainActor.run {
                isChecking = false
                checkResult = result
            }

            // Auto-dismiss "up to date" message after 3 seconds
            if case .upToDate = result {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    // Only reset if still showing upToDate
                    if case .upToDate = checkResult {
                        checkResult = nil
                    }
                }
            }

            // Auto-dismiss rate limited and error after 5 seconds
            if case .rateLimited = result {
                try? await Task.sleep(for: .seconds(5))
                await MainActor.run {
                    if case .rateLimited = checkResult {
                        checkResult = nil
                    }
                }
            }
        }
    }
}
