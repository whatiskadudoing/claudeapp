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
                .environment(container.systemStateMonitor)
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
        Theme.Colors.forUsage(currentUsage)
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
/// KOSMA Business Card Design System inspired interface.
/// Features: Status indicator knobs, bracket notation, corner accent, card-based layout.
struct DropdownView: View {
    let updateChecker: UpdateChecker

    @Environment(UsageManager.self) private var usageManager
    @Environment(SettingsManager.self) private var settings
    @Environment(SystemStateMonitor.self) private var systemStateMonitor
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

    /// Dropdown width - slightly wider for KOSMA spacing
    private var dropdownWidth: CGFloat {
        isAccessibilitySize ? 350 : 300
    }

    /// Connection status for indicator
    private var isConnected: Bool {
        usageManager.usageData != nil && usageManager.lastError == nil
    }

    /// Sync status for indicator
    private var isSynced: Bool {
        !usageManager.isStale && usageManager.usageData != nil
    }

    var body: some View {
        HStack(spacing: 0) {
            // === MAIN CONTENT AREA ===
            VStack(alignment: .leading, spacing: 0) {
                if showingSettings {
                    // Settings header - KOSMA orange
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.kosma) { showingSettings = false }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.Colors.brand)
                        }
                        .buttonStyle(.plain)

                        Text(L("settings.title").uppercased())
                            .font(Theme.Typography.sectionHeader)
                            .foregroundStyle(Theme.Colors.brand.opacity(0.9))
                            .tracking(1.2)
                    }
                    .padding(.horizontal, Theme.KOSMASpace.cardPadding)
                    .padding(.vertical, 14)

                    Rectangle()
                        .fill(Color(red: 26/255, green: 26/255, blue: 26/255))  // #1A1A1A
                        .frame(height: 1)
                        .padding(.horizontal, 16)  // Inset divider

                    SettingsContent(updateChecker: updateChecker)
                        .accentColor(Theme.Colors.brand)
                        .tint(Theme.Colors.brand)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    // Main content (no header - cleaner KOSMA look)
                    VStack(alignment: .leading, spacing: Theme.KOSMASpace.elementGap) {
                        if hasErrorWithCachedData, let error = usageManager.lastError {
                            StaleDataBanner(error: error) {
                                Task { await usageManager.refresh() }
                            }
                        }

                        if let data = usageManager.usageData {
                            UsageContent(data: data, focusedElement: $focusedElement)
                        } else if usageManager.isLoading {
                            BrandedLoadingView()
                        } else if let error = usageManager.lastError {
                            BrandedErrorView(
                                title: errorTitle(for: error),
                                message: errorMessage(for: error)
                            ) {
                                Task { await usageManager.refresh() }
                            }
                        } else {
                            BrandedEmptyStateView {
                                Task { await usageManager.refresh() }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.KOSMASpace.cardPadding)
                    .padding(.top, 20)
                    .padding(.bottom, Theme.KOSMASpace.cardPadding)
                    .transition(.opacity.combined(with: .move(edge: .leading)))

                    Spacer(minLength: 0)

                    // Footer: timestamp + power state indicator
                    HStack(spacing: 8) {
                        if let lastUpdated = usageManager.lastUpdated {
                            KOSMABracketText(
                                updatedAgoText(for: lastUpdated),
                                bracketColor: Theme.Colors.accentRed,
                                textColor: Theme.Colors.textTertiary,
                                font: Theme.Typography.caption
                            )
                        }

                        // Power state indicator (only when smart refresh is enabled)
                        if settings.enablePowerAwareRefresh {
                            PowerStateIndicator(
                                isOnBattery: systemStateMonitor.isOnBattery,
                                isIdle: systemStateMonitor.currentState == .idle
                            )
                        }
                    }
                    .padding(.horizontal, Theme.KOSMASpace.cardPadding)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.kosma, value: showingSettings)

            // === KOSMA VERTICAL SIDEBAR ===
            if !showingSettings {
                Rectangle()
                    .fill(Theme.Colors.brand.opacity(0.3))
                    .frame(width: 1)

                VStack(spacing: 0) {
                    Spacer()

                    // Vertical "[CLAUDE]" text - KOSMA bracket style (ghosted/ambient)
                    HStack(spacing: 1) {
                        Text("[")
                            .foregroundStyle(Theme.Colors.accentRed.opacity(0.4))
                        Text("CLAUDE")
                            .foregroundStyle(Theme.Colors.textSecondaryOnDark.opacity(0.4))
                        Text("]")
                            .foregroundStyle(Theme.Colors.accentRed.opacity(0.4))
                    }
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()

                    Spacer()

                    // Bottom icons section
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Theme.Colors.brand.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 8)

                        // Refresh button
                        RefreshButton()
                            .focused($focusedElement, equals: .refresh)
                            .frame(width: 36, height: 32)

                        // Settings button
                        Button {
                            withAnimation(.kosma) { showingSettings = true }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.brand.opacity(0.7))
                                .frame(width: 36, height: 32)
                        }
                        .buttonStyle(.plain)
                        .focused($focusedElement, equals: .settings)
                        .keyboardShortcut(",", modifiers: .command)

                        // Quit button
                        Button {
                            NSApplication.shared.terminate(nil)
                        } label: {
                            Image(systemName: "power")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.Colors.accentRed)
                                .frame(width: 36, height: 32)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("q", modifiers: .command)

                        // KOSMA corner accent at very bottom
                        KOSMACornerAccent(size: 12, thickness: 2, color: Theme.Colors.brand)
                            .rotationEffect(.degrees(180))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                    }
                }
                .frame(width: 36)
                .background(Theme.Colors.cardBlack)
            }
        }
        .frame(width: dropdownWidth)
        .background(Theme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .accentColor(Theme.Colors.brand)
        .tint(Theme.Colors.brand)
        .task {
            if usageManager.usageData == nil || usageManager.isStale {
                await usageManager.refresh()
            }
        }
        .onAppear {
            focusedElement = .refresh
        }
    }

    /// Localized text for timestamp display
    private func updatedAgoText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Error title for branded error view
    private func errorTitle(for error: AppError) -> String {
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

    /// Error message for branded error view
    private func errorMessage(for error: AppError) -> String {
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

// MARK: - Settings Button

/// Button to open settings.
struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.tertiary)
        }
        .buttonStyle(HoverHighlightButtonStyle())
        .keyboardShortcut(",", modifiers: .command)
        .accessibilityLabel(L("accessibility.openSettings"))
    }
}

// MARK: - Power State Indicator

/// Shows the current power state when power-aware refresh is enabled.
/// Displays battery icon when on battery power, moon icon when idle.
/// Only visible when there's a non-default power state to show.
struct PowerStateIndicator: View {
    let isOnBattery: Bool
    let isIdle: Bool

    /// Whether any indicator should be shown
    private var shouldShow: Bool {
        isOnBattery || isIdle
    }

    /// Accessibility label describing current power state
    private var accessibilityLabel: String {
        var states: [String] = []
        if isOnBattery {
            states.append(L("accessibility.powerState.onBattery"))
        }
        if isIdle {
            states.append(L("accessibility.powerState.idle"))
        }
        return states.joined(separator: ", ")
    }

    var body: some View {
        if shouldShow {
            HStack(spacing: 4) {
                if isOnBattery {
                    Image(systemName: "battery.50")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                if isIdle {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
        }
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
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
                .rotationEffect(.degrees(shouldAnimate ? 360 : 0))
                .animation(animationValue, value: usageManager.refreshState)
        }
        .buttonStyle(HoverHighlightButtonStyle())
        .disabled(usageManager.isLoading)
        .keyboardShortcut("r", modifiers: .command)
        .accessibilityLabel(refreshAccessibilityLabel)
    }

    private var shouldAnimate: Bool {
        usageManager.refreshState == .loading && !reduceMotion
    }

    private var animationValue: Animation? {
        guard !reduceMotion else { return nil }
        return usageManager.refreshState == .loading
            ? .linear(duration: 1).repeatForever(autoreverses: false)
            : .quick
    }

    private var iconName: String {
        switch usageManager.refreshState {
        case .idle, .loading: "arrow.clockwise"
        case .success: "checkmark"
        case .error: "exclamationmark"
        }
    }

    private var iconColor: Color {
        switch usageManager.refreshState {
        case .idle, .loading: Theme.Colors.tertiary
        case .success: Theme.Colors.safe
        case .error: Theme.Colors.critical
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

/// KOSMA-style usage display with generous spacing
struct UsageContent: View {
    let data: UsageData
    var focusedElement: FocusState<FocusableElement?>.Binding

    var body: some View {
        VStack(spacing: Theme.KOSMASpace.sectionGap) {
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

/// KOSMA-style banner with bracket notation for stale data warning
struct StaleDataBanner: View {
    let error: AppError
    let retryAction: () -> Void

    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            HStack(spacing: 2) {
                Text("[")
                    .foregroundStyle(Theme.Colors.accentRed.opacity(0.7))
                Text(L("error.unableToRefresh"))
                    .foregroundStyle(Theme.Colors.warning)
                Text("]")
                    .foregroundStyle(Theme.Colors.accentRed.opacity(0.7))
            }
            .font(Theme.Typography.bracketSmall)

            Spacer()

            Button("Retry", action: retryAction)
                .buttonStyle(KOSMAGhostButtonStyle())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.Colors.warning.opacity(0.08))
        )
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

/// Settings content with clean, minimal sections.
struct SettingsContent: View {
    let updateChecker: UpdateChecker

    @AppStorage("settings.section.display.expanded") private var displayExpanded = true
    @AppStorage("settings.section.refresh.expanded") private var refreshExpanded = true
    @AppStorage("settings.section.notifications.expanded") private var notificationsExpanded = true
    @AppStorage("settings.section.general.expanded") private var generalExpanded = true
    @AppStorage("settings.section.about.expanded") private var aboutExpanded = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                CollapsibleSection(title: L("settings.display"), isExpanded: $displayExpanded) {
                    DisplaySectionContent()
                }

                CollapsibleSection(title: L("settings.refresh"), isExpanded: $refreshExpanded) {
                    RefreshSectionContent()
                }

                CollapsibleSection(title: L("settings.notifications"), isExpanded: $notificationsExpanded) {
                    NotificationsSectionContent()
                }

                CollapsibleSection(title: L("settings.general"), isExpanded: $generalExpanded) {
                    GeneralSectionContent()
                }

                CollapsibleSection(title: L("settings.about"), isExpanded: $aboutExpanded) {
                    CompactAboutSection(updateChecker: updateChecker)
                }
            }
            .padding(Theme.Space.md)
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

/// Settings for menu bar display options (with header).
struct DisplaySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("settings.display"))
            DisplaySectionContent()
        }
    }
}

/// Display settings content (without header, for use in collapsible sections).
struct DisplaySectionContent: View {
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
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
        Theme.Colors.forUsage(percentage)
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

/// Settings for data refresh interval (with header).
struct RefreshSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("settings.refresh"))
            RefreshSectionContent()
        }
    }
}

/// Refresh settings content (without header, for use in collapsible sections).
struct RefreshSectionContent: View {
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
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

            SettingsToggle(
                title: L("settings.refresh.smartRefresh"),
                isOn: $settings.enablePowerAwareRefresh,
                subtitle: L("settings.refresh.smartRefresh.subtitle")
            )

            if settings.enablePowerAwareRefresh {
                SettingsToggle(
                    title: L("settings.refresh.reduceOnBattery"),
                    isOn: $settings.reduceRefreshOnBattery,
                    subtitle: L("settings.refresh.reduceOnBattery.subtitle")
                )
            }
        }
    }
}

// MARK: - Notifications Section

/// Settings for notification preferences (with header).
struct NotificationsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("settings.notifications"))
            NotificationsSectionContent()
        }
    }
}

/// Notifications settings content (without header, for use in collapsible sections).
/// Handles permission status display and denied state UI.
struct NotificationsSectionContent: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(NotificationPermissionManager.self) private var permissionManager

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("settings.notifications.enable").uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textOnDark)
                    .tracking(0.5)
                Spacer(minLength: 16)
                Toggle("", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { newValue in
                        settings.notificationsEnabled = newValue
                        HapticFeedback.success()
                        if newValue {
                            Task {
                                await permissionManager.requestPermission()
                            }
                        }
                    }
                ))
                .toggleStyle(KOSMAToggleStyle())
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

/// General app settings like launch at login (with header).
struct GeneralSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("settings.general"))
            GeneralSectionContent()
        }
    }
}

/// General settings content (without header, for use in collapsible sections).
struct GeneralSectionContent: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(LaunchAtLoginManager.self) private var launchAtLogin

    var body: some View {
        @Bindable var launchAtLogin = launchAtLogin
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L("settings.general.launchAtLogin").uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textOnDark)
                        .tracking(0.5)
                    Spacer(minLength: 16)
                    Toggle("", isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { newValue in
                            launchAtLogin.isEnabled = newValue
                            HapticFeedback.success()
                        }
                    ))
                    .toggleStyle(KOSMAToggleStyle())
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

/// About section showing app info, version checking, and links (full version with header).
struct AboutSection: View {
    let updateChecker: UpdateChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: L("settings.about"))
            AboutSectionContent(updateChecker: updateChecker)
        }
    }
}

/// Full about section content (for legacy SettingsView).
struct AboutSectionContent: View {
    let updateChecker: UpdateChecker

    @State private var checkResult: CheckResult?
    @State private var isChecking = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.6.0"
    }

    var body: some View {
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

/// Compact about section for collapsible display.
/// Horizontal layout: Icon (36px) | Name+Version | Update button
/// Links in single row below.
struct CompactAboutSection: View {
    let updateChecker: UpdateChecker

    @State private var checkResult: CheckResult?
    @State private var isChecking = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.6.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Horizontal layout: Icon | Name+Version | Update button
            HStack(spacing: 12) {
                ClaudeIcon(size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("settings.about.appName"))
                        .font(.system(size: 13, weight: .medium))
                    Text(L("settings.about.version %@", appVersion))
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                compactUpdateStatusView
            }

            // Links in single row
            HStack(spacing: 8) {
                if let githubURL = URL(string: "https://github.com/anthropics/claude-code") {
                    Link(L("settings.about.github"), destination: githubURL)
                }
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(L("settings.about.description"))
            }
            .font(Theme.Typography.metadata)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var compactUpdateStatusView: some View {
        switch (isChecking, checkResult) {
        case (true, _):
            ProgressView()
                .controlSize(.small)

        case (false, nil):
            Button(L("button.checkForUpdates")) {
                checkForUpdates()
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

        case (false, .upToDate):
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 14))

        case (false, .updateAvailable(let info)):
            Button(L("button.download")) {
                NSWorkspace.shared.open(info.downloadURL)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.brand)
            .controlSize(.mini)

        case (false, .rateLimited), (false, .error):
            Button {
                checkForUpdates()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
    }

    private func checkForUpdates() {
        isChecking = true
        checkResult = nil

        Task {
            let result = await updateChecker.check()

            await MainActor.run {
                isChecking = false
                checkResult = result
            }

            // Auto-dismiss states after delay
            if case .upToDate = result {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    if case .upToDate = checkResult {
                        checkResult = nil
                    }
                }
            }

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
