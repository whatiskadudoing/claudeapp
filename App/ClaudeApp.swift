import Core
import Domain
import Foundation
import SwiftUI
import UI
import UserNotifications

// MARK: - Localization Helpers

/// Returns a localized string from the app's resource bundle.
/// This is needed because SPM resource bundles use Bundle.module, not Bundle.main.
func L(_ key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: key, table: nil)
}

/// Returns a localized string with format arguments from the app's resource bundle.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: key, table: nil)
    return String(format: format, arguments: args)
}

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

        // Set up notification delegate (only when running in a proper app bundle)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = notificationDelegate
        }
    }

    var body: some Scene {
        MenuBarExtra {
            DropdownView(updateChecker: container.updateChecker)
                .environment(container.usageManager)
                .environment(container.settingsManager)
                .environment(container.launchAtLoginManager)
                .environment(container.notificationPermissionManager)
        } label: {
            MenuBarLabel(detectedPlanType: container.detectedPlanType)
                .environment(container.usageManager)
                .environment(container.settingsManager)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Label

/// The label displayed in the macOS menu bar.
/// Shows Claude icon + usage visualization based on selected icon style.
/// Supports 6 icon styles: percentage, progressBar, battery, compact, iconOnly, full.
/// Respects display settings: iconStyle, showPercentage, percentageSource, showPlanBadge.
struct MenuBarLabel: View {
    let detectedPlanType: PlanType

    @Environment(UsageManager.self) private var usageManager
    @Environment(SettingsManager.self) private var settings

    /// Current usage percentage based on settings
    private var currentUsage: Double {
        guard let data = usageManager.usageData else { return 0 }
        return data.utilization(for: settings.percentageSource)
    }

    /// Color based on usage thresholds for icon tinting
    private var statusColor: Color {
        switch currentUsage {
        case 0..<50:
            Theme.Colors.success
        case 50..<90:
            Theme.Colors.warning
        default:
            Theme.Colors.primary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if usageManager.isLoading && usageManager.usageData == nil {
                // Loading state - show icon with spinner
                ClaudeIconImage(size: 10, color: Theme.Colors.brand)
                ProgressView()
                    .controlSize(.small)
            } else if usageManager.usageData != nil {
                // Render based on selected icon style
                iconStyleContent
            } else {
                // No data state - show icon only
                ClaudeIconImage(size: 10, color: Theme.Colors.brand)
                if settings.showPercentage {
                    Text(L("usage.noPercentage"))
                        .font(Theme.Typography.menuBar)
                        .fontWeight(.medium)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(L("accessibility.menuBar.hint"))
    }

    /// Content based on selected icon style
    @ViewBuilder
    private var iconStyleContent: some View {
        switch settings.iconStyle {
        case .percentage:
            // Icon + percentage text (default)
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            percentageText

        case .progressBar:
            // Icon + horizontal progress bar
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            ProgressBarIcon(value: currentUsage)

        case .battery:
            // Battery-shaped indicator showing remaining capacity
            BatteryIndicator(usagePercent: currentUsage)

        case .compact:
            // Icon + small colored status dot
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            StatusDot(usagePercent: currentUsage)

        case .iconOnly:
            // Icon only, tinted by status color
            ClaudeIconImage(size: 10, color: statusColor)

        case .full:
            // Full display: icon + bar + percentage
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            ProgressBarIcon(value: currentUsage)
            percentageText
        }
    }

    /// Percentage text view with optional plan badge
    private var percentageText: some View {
        Text(menuBarText)
            .font(Theme.Typography.menuBar)
            .fontWeight(.medium)
    }

    /// Constructs the menu bar text combining percentage and optional badge
    private var menuBarText: String {
        guard let data = usageManager.usageData else { return "—" }

        var text = ""

        if settings.showPercentage || settings.iconStyle == .percentage || settings.iconStyle == .full {
            let percentage = Int(data.utilization(for: settings.percentageSource))
            text = "\(percentage)%"
        }

        if settings.showPlanBadge {
            let badge = detectedPlanType.badgeText
            if text.isEmpty {
                text = badge
            } else {
                text += " \(badge)"
            }
        }

        return text.isEmpty ? "—" : text
    }

    /// Accessibility label combining all menu bar element information for VoiceOver
    private var accessibilityLabel: String {
        var label = "ClaudeApp"

        if usageManager.isLoading && usageManager.usageData == nil {
            label += L("accessibility.menuBar.loading")
        } else if let data = usageManager.usageData {
            let percentage = Int(data.utilization(for: settings.percentageSource))
            label += L("accessibility.menuBar.usage", percentage)

            // Add status level for non-visual indicator styles
            switch settings.iconStyle {
            case .battery, .compact, .iconOnly:
                // Add status description for styles without visible percentage
                if percentage < 50 {
                    label += L("accessibility.menuBar.statusSafe")
                } else if percentage < 90 {
                    label += L("accessibility.menuBar.statusWarning")
                } else {
                    label += L("accessibility.menuBar.statusCritical")
                }
            default:
                break
            }

            // Add warning state for high usage
            if percentage >= 100 {
                label += L("accessibility.menuBar.limitReached")
            } else if percentage >= 90 {
                label += L("accessibility.menuBar.approachingLimit")
            }
        } else {
            label += L("accessibility.menuBar.noData")
        }

        return label
    }
}

// MARK: - Plan Badge Label

/// A small label showing the user's plan type in the menu bar.
/// Note: Plan type detection is not yet implemented (would require API support).
/// For now, this displays a placeholder badge.
/// Uses simple text styling that works reliably in macOS menu bar context.
struct PlanBadgeLabel: View {
    var body: some View {
        Text(L("usage.planBadge.pro"))
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Theme.Colors.brand)
    }
}

// MARK: - Focusable Elements

/// Enum defining all focusable elements in the dropdown for keyboard navigation.
/// Used with @FocusState to manage Tab key navigation order.
enum FocusableElement: Hashable {
    case refresh
    case settings
    case progressBar(Int)
    case quit
}

// MARK: - Dropdown View

/// The dropdown content that appears when clicking the menu bar item.
/// Shows detailed usage information with progress bars, or settings when toggled.
/// Supports keyboard navigation via Tab key and keyboard shortcuts.
/// Adapts layout for accessibility text sizes.
struct DropdownView: View {
    let updateChecker: UpdateChecker

    @Environment(UsageManager.self) private var usageManager
    @Environment(\.sizeCategory) private var sizeCategory

    /// Whether to show settings instead of usage
    @State private var showingSettings = false

    /// Focus state for keyboard navigation
    @FocusState private var focusedElement: FocusableElement?

    /// Whether we have an error but also have cached data to show
    private var hasErrorWithCachedData: Bool {
        usageManager.lastError != nil && usageManager.usageData != nil
    }

    /// Whether data should be considered stale (error occurred or data is old)
    private var isDataStale: Bool {
        usageManager.lastError != nil || usageManager.isStale
    }

    /// Whether we're using accessibility sizes (AX1 and above)
    private var isAccessibilitySize: Bool {
        sizeCategory >= .accessibilityMedium
    }

    /// Dropdown width adapts to text size
    /// Default: 280pt, Accessibility sizes (AX1+): 340pt
    private var dropdownWidth: CGFloat {
        isAccessibilitySize ? 340 : 280
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if showingSettings {
                    Button {
                        showingSettings = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text(L("settings.title"))
                                .font(Theme.Typography.title)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                } else {
                    Text(L("usage.header.title"))
                        .font(Theme.Typography.title)
                }
                Spacer()
                if !showingSettings {
                    // Show burn rate badge when available
                    if let burnRateLevel = usageManager.usageData?.highestBurnRate?.level {
                        BurnRateBadge(level: burnRateLevel)
                    }
                    SettingsButton {
                        showingSettings = true
                    }
                    .focused($focusedElement, equals: .settings)
                    RefreshButton()
                        .focused($focusedElement, equals: .refresh)
                }
            }

            Divider()

            // Content - either settings or usage
            if showingSettings {
                SettingsContent(updateChecker: updateChecker)
            } else {
                // Usage content
                if let data = usageManager.usageData {
                    if hasErrorWithCachedData, let error = usageManager.lastError {
                        StaleDataBanner(error: error) {
                            Task { await usageManager.refresh() }
                        }
                    }
                    UsageContent(data: data, focusedElement: $focusedElement)
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
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(Theme.Typography.metadata)
                                .foregroundStyle(.orange)
                            Text(L("usage.staleData"))
                                .font(Theme.Typography.metadata)
                                .foregroundStyle(.secondary)
                        }
                    } else if let lastUpdated = usageManager.lastUpdated {
                        Text(updatedAgoText(for: lastUpdated))
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button(L("button.quit")) {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .font(Theme.Typography.label)
                    .keyboardShortcut("q", modifiers: .command)
                }
            }
        }
        .padding(16)
        .frame(width: dropdownWidth)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            // Refresh on dropdown open if data is stale or missing
            if usageManager.usageData == nil || usageManager.isStale {
                await usageManager.refresh()
            }
        }
        .onAppear {
            // Set initial focus to refresh button when dropdown opens
            focusedElement = .refresh
        }
    }

    /// Localized text for "Updated X ago" display.
    /// Combines localized format string with system-provided relative date.
    private func updatedAgoText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relativeTime = formatter.localizedString(for: date, relativeTo: Date())

        let key = "usage.updated %@"
        let format = Bundle.module.localizedString(forKey: key, value: "Updated %@ ago", table: nil)
        return String(format: format, relativeTime)
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
        .accessibilityLabel(L("accessibility.openSettings"))
    }
}

// MARK: - Refresh Button

/// Button for manual refresh with visual state feedback.
/// Shows different icons based on refresh state: idle, loading, success, error.
/// Respects "Reduce Motion" accessibility setting - shows static icon instead of spinning.
struct RefreshButton: View {
    @Environment(UsageManager.self) private var usageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            Task { await usageManager.refresh() }
        } label: {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .rotationEffect(.degrees(shouldAnimate ? 360 : 0))
                .animation(animationValue, value: usageManager.refreshState)
        }
        .buttonStyle(.plain)
        .disabled(usageManager.isLoading)
        .keyboardShortcut("r", modifiers: .command)
        .accessibilityLabel(refreshAccessibilityLabel)
    }

    /// Whether the spinning animation should be active.
    /// Disabled when Reduce Motion is enabled - shows static icon instead.
    private var shouldAnimate: Bool {
        usageManager.refreshState == .loading && !reduceMotion
    }

    /// Animation for the refresh button rotation.
    /// Returns nil when Reduce Motion is enabled (instant state changes).
    private var animationValue: Animation? {
        guard !reduceMotion else { return nil }
        return usageManager.refreshState == .loading
            ? .linear(duration: 1).repeatForever(autoreverses: false)
            : .default
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

    /// Accessibility label that describes current refresh state
    private var refreshAccessibilityLabel: String {
        switch usageManager.refreshState {
        case .idle:
            L("accessibility.refresh")
        case .loading:
            L("accessibility.refreshing")
        case .success:
            L("accessibility.refreshComplete")
        case .error:
            L("accessibility.refreshFailed")
        }
    }
}

// MARK: - Usage Content

/// Displays the usage progress bars when data is available.
/// Passes time-to-exhaustion data from UsageWindow to each progress bar.
/// Supports keyboard focus navigation through progress bars.
struct UsageContent: View {
    let data: UsageData
    var focusedElement: FocusState<FocusableElement?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            UsageProgressBar(
                value: data.fiveHour.utilization,
                label: L("usage.progressBar.session"),
                resetsAt: data.fiveHour.resetsAt,
                timeToExhaustion: data.fiveHour.timeToExhaustion
            )
            .focusable()
            .focusEffectDisabled()
            .focused(focusedElement, equals: .progressBar(0))

            UsageProgressBar(
                value: data.sevenDay.utilization,
                label: L("usage.progressBar.weekly"),
                resetsAt: data.sevenDay.resetsAt,
                timeToExhaustion: data.sevenDay.timeToExhaustion
            )
            .focusable()
            .focusEffectDisabled()
            .focused(focusedElement, equals: .progressBar(1))

            if let opus = data.sevenDayOpus {
                UsageProgressBar(
                    value: opus.utilization,
                    label: L("usage.progressBar.opus"),
                    resetsAt: opus.resetsAt,
                    timeToExhaustion: opus.timeToExhaustion
                )
                .focusable()
                .focusEffectDisabled()
                .focused(focusedElement, equals: .progressBar(2))
            }

            if let sonnet = data.sevenDaySonnet {
                UsageProgressBar(
                    value: sonnet.utilization,
                    label: L("usage.progressBar.sonnet"),
                    resetsAt: sonnet.resetsAt,
                    timeToExhaustion: sonnet.timeToExhaustion
                )
                .focusable()
                .focusEffectDisabled()
                .focused(focusedElement, equals: .progressBar(3))
            }
        }
    }
}

// MARK: - Stale Data Banner

/// Banner displayed when we have cached data but encountered an error on refresh.
/// Shows a warning with the error reason and a retry button.
/// Supports high contrast mode with visible border when "Increase Contrast" is enabled.
struct StaleDataBanner: View {
    let error: AppError
    let retryAction: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Whether high contrast mode is enabled
    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Theme.Typography.label)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L("error.unableToRefresh"))
                    .font(Theme.Typography.label)
                    .fontWeight(.medium)
                Text(errorReason)
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(L("button.retry"), action: retryAction)
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .accessibilityLabel(L("accessibility.retryRefresh"))
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.orange.opacity(isHighContrast ? 0.5 : 0), lineWidth: isHighContrast ? 1.5 : 0)
        )
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("accessibility.unableToRefresh", errorReason))
    }

    private var errorReason: String {
        switch error {
        case .networkError:
            L("error.connectionIssue")
        case .rateLimited(let retryAfter):
            L("error.rateLimited.reason", retryAfter)
        case .apiError(let statusCode, _):
            L("error.serverError", statusCode)
        case .notAuthenticated:
            L("error.authRequired")
        case .keychainError:
            L("error.keychainError")
        case .decodingError:
            L("error.dataFormatError")
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
                Text(L("usage.loading"))
                    .font(Theme.Typography.label)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("accessibility.loading"))
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
                .font(Theme.Typography.iconLarge)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(errorTitle)
                .font(Theme.Typography.label)
                .fontWeight(.medium)

            Text(errorMessage)
                .font(Theme.Typography.metadata)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(L("button.tryAgain"), action: retryAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
                .accessibilityLabel(L("accessibility.retryLoad"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("accessibility.error", errorTitle, errorMessage))
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
            L("error.notAuthenticated.title")
        case .networkError:
            L("error.connectionError")
        case .rateLimited:
            L("error.rateLimited")
        default:
            L("error.unableToLoad")
        }
    }

    private var errorMessage: String {
        switch error {
        case .notAuthenticated:
            L("error.notAuthenticated.message")
        case .networkError(let message):
            message
        case .rateLimited(let retryAfter):
            L("error.rateLimited.wait", retryAfter)
        case .apiError(let statusCode, _):
            L("error.serverError", statusCode)
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
                .font(Theme.Typography.iconLarge)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(L("usage.noData"))
                .font(Theme.Typography.label)
                .fontWeight(.medium)

            Button(L("button.refresh"), action: refreshAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
                .accessibilityLabel(L("accessibility.refresh"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("accessibility.noUsageData"))
    }
}

// MARK: - Settings Content (Inline)

/// Settings content for inline display in the dropdown.
/// Shows all settings sections in a scrollable view.
struct SettingsContent: View {
    let updateChecker: UpdateChecker

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DisplaySection()

                Divider()

                RefreshSection()

                Divider()

                NotificationsSection()

                Divider()

                GeneralSection()

                Divider()

                AboutSection(updateChecker: updateChecker)

                Divider()

                // Quit button
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text(L("button.quit"))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .frame(maxHeight: 400)
    }
}

// MARK: - Settings View (Legacy Window)

/// The main settings window showing all app configuration options.
/// Organized into sections: Display, Refresh, Notifications, General, About.
/// Adapts size for accessibility text sizes.
struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(LaunchAtLoginManager.self) private var launchAtLogin
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory

    let updateChecker: UpdateChecker

    /// Whether we're using accessibility sizes (AX1 and above)
    private var isAccessibilitySize: Bool {
        sizeCategory >= .accessibilityMedium
    }

    /// Settings window width adapts to text size
    private var windowWidth: CGFloat {
        isAccessibilitySize ? 400 : 320
    }

    /// Settings window height adapts to text size
    private var windowHeight: CGFloat {
        isAccessibilitySize ? 600 : 500
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L("settings.title"))
                    .font(Theme.Typography.title)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(Theme.Typography.iconMedium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("accessibility.closeSettings"))
                .frame(minWidth: 44, minHeight: 44)
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
        .frame(width: windowWidth, height: windowHeight)
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
            SectionHeader(title: L("settings.display"))

            // Icon Style picker with live preview
            VStack(alignment: .leading, spacing: 8) {
                SettingsPickerRow(
                    title: L("settings.display.iconStyle"),
                    selection: $settings.iconStyle
                ) {
                    ForEach(IconStyle.allCases, id: \.self) { style in
                        Text(L(style.localizationKey)).tag(style)
                    }
                }

                // Live preview of the selected icon style
                IconStylePreview(iconStyle: settings.iconStyle, percentage: 72)
                    .padding(.leading, 4)
            }

            SettingsToggle(
                title: L("settings.display.showPlanBadge"),
                isOn: $settings.showPlanBadge,
                subtitle: L("settings.display.showPlanBadge.subtitle")
            )

            SettingsToggle(
                title: L("settings.display.showPercentage"),
                isOn: $settings.showPercentage
            )

            if settings.showPercentage {
                SettingsPickerRow(
                    title: L("settings.display.percentageSource"),
                    selection: $settings.percentageSource
                ) {
                    ForEach(PercentageSource.allCases, id: \.self) { source in
                        Text(source.localizedName).tag(source)
                    }
                }
            }
        }
    }
}

// MARK: - Icon Style Preview

/// Shows a live preview of the selected icon style with mock data.
/// Displayed in the Display settings section to help users visualize their choice.
struct IconStylePreview: View {
    let iconStyle: IconStyle
    let percentage: Double

    /// Color based on usage thresholds
    private var statusColor: Color {
        switch percentage {
        case 0..<50:
            Theme.Colors.success
        case 50..<90:
            Theme.Colors.warning
        default:
            Theme.Colors.primary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(L("settings.display.preview"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            // Preview container with menu bar-like background
            HStack(spacing: 4) {
                previewContent
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("settings.display.preview.accessibility", L(iconStyle.localizationKey)))
    }

    @ViewBuilder
    private var previewContent: some View {
        switch iconStyle {
        case .percentage:
            // Icon + percentage text (default)
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            Text("\(Int(percentage))%")
                .font(Theme.Typography.menuBar)
                .fontWeight(.medium)

        case .progressBar:
            // Icon + horizontal progress bar
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            ProgressBarIcon(value: percentage)

        case .battery:
            // Battery-shaped indicator showing remaining capacity
            BatteryIndicator(usagePercent: percentage)

        case .compact:
            // Icon + small colored status dot
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            StatusDot(usagePercent: percentage)

        case .iconOnly:
            // Icon only, tinted by status color
            ClaudeIconImage(size: 10, color: statusColor)

        case .full:
            // Full display: icon + bar + percentage
            ClaudeIconImage(size: 10, color: Theme.Colors.brand)
            ProgressBarIcon(value: percentage)
            Text("\(Int(percentage))%")
                .font(Theme.Typography.menuBar)
                .fontWeight(.medium)
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
            SectionHeader(title: L("settings.refresh"))

            SettingsSliderRow(
                title: L("settings.refresh.interval"),
                value: Binding(
                    get: { Double(settings.refreshInterval) },
                    set: { settings.refreshInterval = Int($0) }
                ),
                in: 1...30,
                step: 1,
                minLabel: L("settings.refresh.interval.min"),
                maxLabel: L("settings.refresh.interval.max")
            ) { value in
                L("settings.refresh.interval.value %lld", Int(value))
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
            SectionHeader(title: L("settings.notifications"))

            HStack {
                Text(L("settings.notifications.enable"))
                    .font(.system(size: 13))
                Spacer(minLength: 16)
                Toggle("", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { newValue in
                        settings.notificationsEnabled = newValue
                        if newValue {
                            Task {
                                await permissionManager.requestPermission()
                            }
                        }
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
            }

            if settings.notificationsEnabled {
                if permissionManager.isPermissionDenied {
                    PermissionDeniedBanner()
                }

                if permissionManager.canSendNotifications {
                    SettingsSliderRow(
                        title: L("settings.notifications.warningThreshold"),
                        value: Binding(
                            get: { Double(settings.warningThreshold) },
                            set: { settings.warningThreshold = Int($0) }
                        ),
                        in: 50...99,
                        step: 1,
                        minLabel: "50%",
                        maxLabel: "99%"
                    ) { value in
                        "\(Int(value))%"
                    }

                    SettingsToggle(
                        title: L("settings.notifications.usageWarnings"),
                        isOn: $settings.warningEnabled,
                        subtitle: L("settings.notifications.usageWarnings.subtitle")
                    )

                    SettingsToggle(
                        title: L("settings.notifications.capacityFull"),
                        isOn: $settings.capacityFullEnabled,
                        subtitle: L("settings.notifications.capacityFull.subtitle")
                    )

                    SettingsToggle(
                        title: L("settings.notifications.resetComplete"),
                        isOn: $settings.resetCompleteEnabled,
                        subtitle: L("settings.notifications.resetComplete.subtitle")
                    )
                }
            }
        }
        .onAppear {
            Task {
                await permissionManager.refreshPermissionStatus()
            }
        }
    }
}

// MARK: - Permission Denied Banner

/// Banner shown when notification permission is denied.
/// Provides a button to open System Settings.
/// Supports high contrast mode with visible border when "Increase Contrast" is enabled.
struct PermissionDeniedBanner: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Whether high contrast mode is enabled
    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(Theme.Typography.label)
                Text(L("settings.notifications.disabled.title"))
                    .font(Theme.Typography.label)
                    .fontWeight(.medium)
            }

            Text(L("settings.notifications.disabled.instructions"))
                .font(Theme.Typography.label)
                .foregroundStyle(.secondary)

            Button {
                openNotificationSettings()
            } label: {
                Text(L("button.openSystemSettings"))
                    .font(Theme.Typography.label)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.orange.opacity(isHighContrast ? 0.5 : 0), lineWidth: isHighContrast ? 1.5 : 0)
        )
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
            SectionHeader(title: L("settings.general"))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L("settings.general.launchAtLogin"))
                        .font(.system(size: 13))
                    Spacer(minLength: 16)
                    Toggle("", isOn: $launchAtLogin.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                }

                if launchAtLogin.requiresUserApproval {
                    Button {
                        openLoginItemsSettings()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(L("settings.general.requiresApproval"))
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }

                if let error = launchAtLogin.lastError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
            }

            SettingsToggle(
                title: L("settings.general.checkForUpdates"),
                isOn: $settings.checkForUpdates,
                subtitle: L("settings.general.checkForUpdates.subtitle")
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
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.2.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: L("settings.about"))

            VStack(spacing: 16) {
                // App icon
                ClaudeIcon(size: 48)

                Text(L("settings.about.appName"))
                    .font(Theme.Typography.title)

                Text(L("settings.about.version %@", appVersion))
                    .font(Theme.Typography.label)
                    .foregroundStyle(.secondary)

                // Update check UI
                updateStatusView

                // Links
                HStack(spacing: 8) {
                    if let githubURL = URL(string: "https://github.com/anthropics/claude-code") {
                        Link(L("settings.about.github"), destination: githubURL)
                    }
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(L("settings.about.description"))
                }
                .font(Theme.Typography.label)
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
                Text(L("update.checking"))
                    .font(Theme.Typography.label)
                    .foregroundStyle(.secondary)
            }

        case (false, nil):
            // Default state: show button
            Button(L("button.checkForUpdates")) {
                checkForUpdates()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case (false, .upToDate):
            // Up to date state
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(L("update.upToDate"))
            }
            .font(Theme.Typography.label)

        case (false, .updateAvailable(let info)):
            // Update available state
            VStack(spacing: 8) {
                Text(L("update.versionAvailable", info.version))
                    .font(Theme.Typography.label)
                    .foregroundStyle(.secondary)

                Button(L("button.download")) {
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
                Text(L("update.tryAgainLater"))
            }
            .font(Theme.Typography.label)
            .foregroundStyle(.secondary)

        case (false, .error):
            // Error state
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(L("update.unableToCheck"))
                }
                .font(Theme.Typography.label)

                // Show brief error, allow retry
                Button(L("button.retry")) {
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
