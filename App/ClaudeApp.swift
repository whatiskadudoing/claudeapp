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
    /// For update notifications: opens the download URL in the browser.
    /// For other notifications: opens the dropdown by activating the app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        // Check if this is an update notification
        if identifier.hasPrefix("update-available-") {
            // Extract download URL from userInfo and open in browser
            let userInfo = response.notification.request.content.userInfo
            if let urlString = userInfo["downloadURL"] as? String,
               let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }

        // Always activate the app (shows the dropdown)
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

/// Main SwiftUI app for GUI mode.
/// Entry point is handled by main.swift to support CLI/GUI mode detection.
struct ClaudeAppMain: App {
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
                .environment(container.usageHistoryManager)
                .environment(container.settingsExportManager)
                .environment(container.accountManager)
        } label: {
            MenuBarLabel(detectedPlanType: container.detectedPlanType)
                .environment(container.usageManager)
                .environment(container.settingsManager)
                .environment(container.accountManager)
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

    /// Whether any usage window has reached 100% capacity
    private var isAtCapacity: Bool {
        usageManager.usageData?.isAtCapacity ?? false
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

                // Warning indicator when any limit is at 100%
                if isAtCapacity {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.warning)
                }
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

            // Add warning state for high usage (check isAtCapacity for any window at 100%)
            if data.isAtCapacity {
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
    @Environment(AccountManager.self) private var accountManager
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
                    // Main content with header
                    VStack(alignment: .leading, spacing: Theme.KOSMASpace.elementGap) {
                        // Header: Title + Account Switcher + Burn Rate Badge
                        HStack(spacing: 8) {
                            Text(L("usage.header.title").uppercased())
                                .font(Theme.Typography.sectionHeader)
                                .foregroundStyle(Theme.Colors.brand.opacity(0.9))
                                .tracking(1.2)

                            // Account switcher (shows when multiple accounts exist)
                            if accountManager.accounts.count > 1 {
                                AccountSwitcherMenu()
                            }

                            // Burn rate badge (only shown when data available)
                            if let burnRateLevel = usageManager.overallBurnRateLevel {
                                BurnRateBadge(level: burnRateLevel)
                            }

                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(headerAccessibilityLabel)

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

    /// Accessibility label for header including burn rate status
    private var headerAccessibilityLabel: String {
        var label = L("usage.header.title")
        if let burnRateLevel = usageManager.overallBurnRateLevel {
            let burnRateKey = "accessibility.burnRate.\(burnRateLevel.localizationKey)"
            let burnRateDescription = Bundle.main.localizedString(forKey: burnRateKey, value: nil, table: nil)
            label += ", " + burnRateDescription
        }
        return label
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
/// Shows progress bars with optional sparkline charts below each when enabled.
struct UsageContent: View {
    let data: UsageData
    var focusedElement: FocusState<FocusableElement?>.Binding

    @Environment(SettingsManager.self) private var settings
    @Environment(UsageHistoryManager.self) private var historyManager

    var body: some View {
        VStack(spacing: Theme.KOSMASpace.sectionGap) {
            // 5-hour session window
            VStack(spacing: 4) {
                UsageProgressBar(
                    value: data.fiveHour.utilization,
                    label: L("usage.progressBar.session"),
                    resetsAt: data.fiveHour.resetsAt,
                    timeToExhaustion: data.fiveHour.timeToExhaustion
                )
                .focusable()
                .focusEffectDisabled()
                .focused(focusedElement, equals: .progressBar(0))

                // Sparkline for session history
                if settings.showSparklines, historyManager.hasSessionChartData {
                    UsageSparkline(dataPoints: historyManager.sessionHistory)
                }
            }

            // 7-day weekly window (all models)
            VStack(spacing: 4) {
                UsageProgressBar(
                    value: data.sevenDay.utilization,
                    label: L("usage.progressBar.weekly"),
                    resetsAt: data.sevenDay.resetsAt,
                    timeToExhaustion: data.sevenDay.timeToExhaustion
                )
                .focusable()
                .focusEffectDisabled()
                .focused(focusedElement, equals: .progressBar(1))

                // Sparkline for weekly history
                if settings.showSparklines, historyManager.hasWeeklyChartData {
                    UsageSparkline(dataPoints: historyManager.weeklyHistory)
                }
            }

            // Opus-specific window (optional)
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

            // Sonnet-specific window (optional)
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

    @AppStorage("settings.section.accounts.expanded") private var accountsExpanded = false
    @AppStorage("settings.section.display.expanded") private var displayExpanded = true
    @AppStorage("settings.section.refresh.expanded") private var refreshExpanded = true
    @AppStorage("settings.section.notifications.expanded") private var notificationsExpanded = true
    @AppStorage("settings.section.general.expanded") private var generalExpanded = true
    @AppStorage("settings.section.data.expanded") private var dataExpanded = false
    @AppStorage("settings.section.about.expanded") private var aboutExpanded = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                CollapsibleSection(title: L("settings.accounts"), isExpanded: $accountsExpanded) {
                    AccountsSectionContent()
                }

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

                CollapsibleSection(title: L("settings.data"), isExpanded: $dataExpanded) {
                    DataSectionContent()
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

            SettingsToggle(
                title: L("settings.display.showSparklines"),
                isOn: $settings.showSparklines,
                subtitle: L("settings.display.showSparklines.subtitle")
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

// MARK: - Data Section

/// Data section for settings export, import, and reset.
struct DataSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L("settings.data"))
            DataSectionContent()
        }
    }
}

/// Data settings content for export, import, backup, and reset functionality.
/// Provides buttons for:
/// - Export: Save settings to JSON file
/// - Import: Load settings from JSON file
/// - Reset: Reset all settings to defaults
struct DataSectionContent: View {
    @Environment(SettingsExportManager.self) private var exportManager

    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showResetConfirmation = false
    @State private var showImportConfirmation = false
    @State private var importedSettings: ExportedSettings?
    @State private var importError: String?
    @State private var exportSuccess = false
    @State private var importSuccess = false
    @State private var resetSuccess = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Export button
            DataActionButton(
                title: L("settings.data.export"),
                subtitle: L("settings.data.export.subtitle"),
                icon: "square.and.arrow.up",
                showSuccess: exportSuccess
            ) {
                showExportSheet = true
            }

            // Import button
            DataActionButton(
                title: L("settings.data.import"),
                subtitle: L("settings.data.import.subtitle"),
                icon: "square.and.arrow.down",
                showSuccess: importSuccess
            ) {
                showImportPicker = true
            }

            // Reset button (destructive)
            DataActionButton(
                title: L("settings.data.reset"),
                subtitle: L("settings.data.reset.subtitle"),
                icon: "arrow.counterclockwise",
                isDestructive: true,
                showSuccess: resetSuccess
            ) {
                showResetConfirmation = true
            }

            // Error display
            if let error = importError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSettingsSheet(
                exportManager: exportManager,
                onExportSuccess: {
                    withAnimation(.kosma) { exportSuccess = true }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run { exportSuccess = false }
                    }
                }
            )
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            onCompletion: handleImportFile
        )
        .sheet(isPresented: $showImportConfirmation) {
            if let settings = importedSettings {
                ImportConfirmationSheet(
                    importedSettings: settings,
                    exportManager: exportManager,
                    onImportSuccess: {
                        importedSettings = nil
                        withAnimation(.kosma) { importSuccess = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            await MainActor.run { importSuccess = false }
                        }
                    },
                    onCancel: {
                        importedSettings = nil
                    }
                )
            }
        }
        .confirmationDialog(
            L("settings.data.reset.confirm.title"),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("settings.data.reset.confirm.button"), role: .destructive) {
                performReset()
            }
            Button(L("button.cancel"), role: .cancel) {}
        } message: {
            Text(L("settings.data.reset.confirm.message"))
        }
    }

    private func handleImportFile(_ result: Result<URL, Error>) {
        importError = nil

        switch result {
        case .success(let url):
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importError = L("settings.data.import.error.access")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let settings = try exportManager.importFromFile(url: url)

                // Validate settings
                let validation = settings.validate()
                if !validation.isValid {
                    importError = validation.messages.first ?? L("settings.data.import.error.invalid")
                    return
                }

                // Show confirmation dialog
                importedSettings = settings
                showImportConfirmation = true
            } catch {
                importError = L("settings.data.import.error.parse")
            }

        case .failure:
            importError = L("settings.data.import.error.read")
        }
    }

    private func performReset() {
        exportManager.resetToDefaults(clearHistory: false)
        withAnimation(.kosma) { resetSuccess = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { resetSuccess = false }
        }
    }
}

/// Button for data actions (export, import, reset) with KOSMA styling.
struct DataActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    var isDestructive: Bool = false
    var showSuccess: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: showSuccess ? "checkmark" : icon)
                    .font(.system(size: 11))
                    .foregroundStyle(showSuccess ? Theme.Colors.safe : (isDestructive ? Theme.Colors.critical : Theme.Colors.brand))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundStyle(isDestructive ? Theme.Colors.critical : Theme.Colors.textOnDark)
                        .tracking(1.2)

                    Text(subtitle)
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.Colors.textTertiaryOnDark)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isDestructive ? Theme.Colors.critical.opacity(0.08) : Theme.Colors.brand.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Sheet for export options.
struct ExportSettingsSheet: View {
    let exportManager: SettingsExportManager
    let onExportSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var includeUsageHistory = false
    @State private var exportError: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(L("settings.data.export.sheet.title").uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.brand)
                    .tracking(1.5)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Theme.Colors.brand.opacity(0.2))

            // Options
            VStack(alignment: .leading, spacing: 12) {
                SettingsToggle(
                    title: L("settings.data.export.includeHistory"),
                    isOn: $includeUsageHistory,
                    subtitle: L("settings.data.export.includeHistory.subtitle")
                )
            }

            if let error = exportError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                Button(L("button.cancel")) {
                    dismiss()
                }
                .buttonStyle(KOSMAGhostButtonStyle())

                Button(L("settings.data.export.button")) {
                    performExport()
                }
                .buttonStyle(KOSMAPrimaryButtonStyle())
            }
        }
        .padding(20)
        .frame(width: 280, height: 220)
        .background(Theme.Colors.background)
    }

    private func performExport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "ClaudeApp-Settings.json"
        panel.title = L("settings.data.export.panel.title")

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try exportManager.exportToFile(url: url, includeUsageHistory: includeUsageHistory)
                onExportSuccess()
                dismiss()
            } catch {
                exportError = L("settings.data.export.error")
            }
        }
    }
}

/// Sheet for import confirmation with settings preview.
struct ImportConfirmationSheet: View {
    let importedSettings: ExportedSettings
    let exportManager: SettingsExportManager
    let onImportSuccess: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var createBackup = true
    @State private var includeUsageHistory = false
    @State private var importError: String?

    private var summary: ExportedSettings.ImportSummary {
        importedSettings.validate().summary ?? ExportedSettings.ImportSummary(
            displaySettingsCount: 0,
            refreshSettingsCount: 0,
            notificationSettingsCount: 0,
            generalSettingsCount: 0,
            includesUsageHistory: false,
            sessionHistoryPoints: 0,
            weeklyHistoryPoints: 0
        )
    }

    /// Total number of settings being imported
    private var totalSettingsCount: Int {
        summary.displaySettingsCount + summary.refreshSettingsCount +
        summary.notificationSettingsCount + summary.generalSettingsCount
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(L("settings.data.import.sheet.title").uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.brand)
                    .tracking(1.5)

                Spacer()

                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Theme.Colors.brand.opacity(0.2))

            // Import summary
            VStack(alignment: .leading, spacing: 8) {
                Text(L("settings.data.import.summary").uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textSecondaryOnDark)
                    .tracking(1)

                VStack(alignment: .leading, spacing: 4) {
                    ImportSummaryRow(label: L("settings.data.import.summary.version"), value: importedSettings.appVersion)
                    ImportSummaryRow(label: L("settings.data.import.summary.exported"), value: formattedDate(importedSettings.exportedAt))
                    ImportSummaryRow(label: L("settings.data.import.summary.settings"), value: "\(totalSettingsCount)")
                    if summary.includesUsageHistory {
                        ImportSummaryRow(label: L("settings.data.import.summary.history"), value: L("settings.data.import.summary.history.included"))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.Colors.cardBlack)
                )
            }

            // Options
            VStack(alignment: .leading, spacing: 10) {
                SettingsToggle(
                    title: L("settings.data.import.createBackup"),
                    isOn: $createBackup,
                    subtitle: L("settings.data.import.createBackup.subtitle")
                )

                if summary.includesUsageHistory {
                    SettingsToggle(
                        title: L("settings.data.import.includeHistory"),
                        isOn: $includeUsageHistory,
                        subtitle: L("settings.data.import.includeHistory.subtitle")
                    )
                }
            }

            if let error = importError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Warning text
            Text(L("settings.data.import.warning"))
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: 12) {
                Button(L("button.cancel")) {
                    onCancel()
                    dismiss()
                }
                .buttonStyle(KOSMAGhostButtonStyle())

                Button(L("settings.data.import.button")) {
                    performImport()
                }
                .buttonStyle(KOSMAPrimaryButtonStyle())
            }
        }
        .padding(20)
        .frame(width: 300, height: 380)
        .background(Theme.Colors.background)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func performImport() {
        do {
            // Create backup if requested
            if createBackup {
                _ = try exportManager.createBackup()
            }

            // Apply settings
            exportManager.applySettings(importedSettings, includeUsageHistory: includeUsageHistory)

            onImportSuccess()
            dismiss()
        } catch {
            importError = L("settings.data.import.error.apply")
        }
    }
}

/// Row in import summary showing label and value.
struct ImportSummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiaryOnDark)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.Colors.textOnDark)
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

// MARK: - Account Switcher Menu

/// Dropdown menu for switching between accounts.
/// Shows the active account name with a chevron, and a menu of all accounts when clicked.
struct AccountSwitcherMenu: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(UsageManager.self) private var usageManager

    /// Whether to show the add account sheet
    @State private var showingAddAccount = false

    var body: some View {
        if accountManager.accounts.count > 1 {
            // Multi-account: show switcher dropdown
            Menu {
                ForEach(accountManager.accounts) { account in
                    Button {
                        accountManager.setActiveAccount(account.id)
                        Task { await usageManager.refresh() }
                    } label: {
                        HStack {
                            if account.isPrimary {
                                Image(systemName: "star.fill")
                            }
                            Text(account.name)
                            if account.id == accountManager.activeAccountId {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    showingAddAccount = true
                } label: {
                    Label(L("accounts.add"), systemImage: "plus")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(accountManager.activeAccount?.name ?? L("accounts.default"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondaryOnDark)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .sheet(isPresented: $showingAddAccount) {
                AddAccountSheet()
            }
        } else {
            // Single account: just show name (no dropdown needed)
            if let account = accountManager.activeAccount {
                Text(account.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondaryOnDark)
            }
        }
    }
}

// MARK: - Add Account Sheet

/// Sheet for adding a new account.
struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AccountManager.self) private var accountManager

    @State private var accountName = ""
    @State private var keychainIdentifier = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(L("accounts.add.title").uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.brand)
                    .tracking(1.5)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Theme.Colors.brand.opacity(0.2))

            VStack(alignment: .leading, spacing: 16) {
                // Account name input
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("accounts.name").uppercased())
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textOnDark)
                        .tracking(1.2)

                    TextField(L("accounts.name.placeholder"), text: $accountName)
                        .textFieldStyle(.roundedBorder)
                }

                // Keychain identifier (for advanced users)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("accounts.keychainId").uppercased())
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textOnDark)
                        .tracking(1.2)

                    TextField(L("accounts.keychainId.placeholder"), text: $keychainIdentifier)
                        .textFieldStyle(.roundedBorder)

                    Text(L("accounts.keychainId.hint"))
                        .font(.system(size: 9, weight: .light))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }

                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 10))
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                Button(L("button.cancel")) {
                    dismiss()
                }
                .buttonStyle(KOSMAGhostButtonStyle())

                Button(L("accounts.add.button")) {
                    addAccount()
                }
                .buttonStyle(KOSMAPrimaryButtonStyle())
                .disabled(accountName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320, height: 320)
        .background(Theme.Colors.background)
    }

    private func addAccount() {
        let trimmedName = accountName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = L("accounts.error.emptyName")
            return
        }

        // Check for duplicate names
        if accountManager.accounts.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            errorMessage = L("accounts.error.duplicateName")
            return
        }

        let identifier = keychainIdentifier.trimmingCharacters(in: .whitespaces)
        let account = Account(
            name: trimmedName,
            keychainIdentifier: identifier.isEmpty ? UUID().uuidString : identifier
        )

        accountManager.addAccount(account)
        dismiss()
    }
}

// MARK: - Account Row

/// A single account row in the accounts settings list.
struct AccountRow: View {
    let account: Account
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetPrimary: () -> Void

    @Environment(AccountManager.self) private var accountManager
    @Environment(UsageManager.self) private var usageManager

    /// Whether this account has an error
    private var hasError: Bool {
        usageManager.errorByAccount[account.id] != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            // Primary indicator
            Button {
                onSetPrimary()
            } label: {
                Image(systemName: account.isPrimary ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(account.isPrimary ? Theme.Colors.brand : Theme.Colors.textTertiaryOnDark)
            }
            .buttonStyle(.plain)
            .help(account.isPrimary ? L("accounts.primary.current") : L("accounts.primary.set"))

            // Account info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(account.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textOnDark)

                    if let planType = account.planType {
                        Text("(\(planType.displayName))")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.textSecondaryOnDark)
                    }

                    // Status indicator
                    if hasError {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.Colors.warning)
                    } else if account.id == accountManager.activeAccountId {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.Colors.safe)
                    }
                }

                if account.usesDefaultCredentials {
                    Text(L("accounts.credentials.default"))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.brand.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(L("accounts.edit"))

                // Don't allow deleting the only account
                if accountManager.accounts.count > 1 {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.critical.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help(L("accounts.delete"))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(account.id == accountManager.activeAccountId
                    ? Theme.Colors.brand.opacity(0.08)
                    : Color.clear)
        )
    }
}

// MARK: - Accounts Section Content

/// Accounts settings content for the Settings panel.
/// Shows list of accounts with add/edit/remove functionality.
struct AccountsSectionContent: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(UsageManager.self) private var usageManager
    @Environment(SettingsManager.self) private var settings

    @State private var showingAddAccount = false
    @State private var showingDeleteConfirmation = false
    @State private var accountToDelete: Account?
    @State private var showingEditAccount = false
    @State private var accountToEdit: Account?
    @State private var editedName = ""

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 12) {
            // Account list
            VStack(spacing: 4) {
                ForEach(accountManager.accounts) { account in
                    AccountRow(
                        account: account,
                        onEdit: {
                            accountToEdit = account
                            editedName = account.name
                            showingEditAccount = true
                        },
                        onDelete: {
                            accountToDelete = account
                            showingDeleteConfirmation = true
                        },
                        onSetPrimary: {
                            accountManager.setPrimaryAccount(account.id)
                        }
                    )
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Colors.cardBlack)
            )

            // Add account button
            Button {
                showingAddAccount = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text(L("accounts.add"))
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .tracking(1.0)
                }
                .foregroundStyle(Theme.Colors.brand)
            }
            .buttonStyle(.plain)

            Divider()
                .background(Theme.Colors.brand.opacity(0.1))

            // Display mode picker (for when multiple accounts exist)
            if accountManager.accounts.count > 1 {
                SettingsPickerRow(
                    title: L("accounts.displayMode"),
                    selection: $settings.multiAccountDisplayMode
                ) {
                    ForEach(MultiAccountDisplayMode.allCases, id: \.self) { mode in
                        Text(L(mode.localizationKey)).tag(mode)
                    }
                }

                SettingsToggle(
                    title: L("accounts.showLabels"),
                    isOn: $settings.showAccountLabels,
                    subtitle: L("accounts.showLabels.subtitle")
                )
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet()
        }
        .sheet(isPresented: $showingEditAccount) {
            if let account = accountToEdit {
                EditAccountSheet(
                    account: account,
                    editedName: $editedName,
                    onSave: {
                        var updated = account
                        updated.name = editedName.trimmingCharacters(in: .whitespaces)
                        accountManager.updateAccount(updated)
                        showingEditAccount = false
                        accountToEdit = nil
                    },
                    onCancel: {
                        showingEditAccount = false
                        accountToEdit = nil
                    }
                )
            }
        }
        .confirmationDialog(
            L("accounts.delete.confirm.title"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("accounts.delete.confirm.button"), role: .destructive) {
                if let account = accountToDelete {
                    accountManager.removeAccount(account)
                }
                accountToDelete = nil
            }
            Button(L("button.cancel"), role: .cancel) {
                accountToDelete = nil
            }
        } message: {
            if let account = accountToDelete {
                Text(L("accounts.delete.confirm.message", account.name))
            }
        }
    }
}

// MARK: - Edit Account Sheet

/// Sheet for editing an existing account.
struct EditAccountSheet: View {
    let account: Account
    @Binding var editedName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(AccountManager.self) private var accountManager

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(L("accounts.edit.title").uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Colors.brand)
                    .tracking(1.5)

                Spacer()

                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiaryOnDark)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Theme.Colors.brand.opacity(0.2))

            VStack(alignment: .leading, spacing: 16) {
                // Account name input
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("accounts.name").uppercased())
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textOnDark)
                        .tracking(1.2)

                    TextField(L("accounts.name.placeholder"), text: $editedName)
                        .textFieldStyle(.roundedBorder)
                }

                // Keychain info (read-only)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("accounts.keychainId").uppercased())
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textOnDark)
                        .tracking(1.2)

                    Text(account.usesDefaultCredentials ? "Claude Code-credentials" : account.keychainIdentifier)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondaryOnDark)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.Colors.cardBlack)
                        )
                }

                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 10))
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                Button(L("button.cancel")) {
                    onCancel()
                }
                .buttonStyle(KOSMAGhostButtonStyle())

                Button(L("button.save")) {
                    saveChanges()
                }
                .buttonStyle(KOSMAPrimaryButtonStyle())
                .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320, height: 280)
        .background(Theme.Colors.background)
    }

    private func saveChanges() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = L("accounts.error.emptyName")
            return
        }

        // Check for duplicate names (excluding current account)
        if accountManager.accounts.contains(where: {
            $0.id != account.id && $0.name.lowercased() == trimmedName.lowercased()
        }) {
            errorMessage = L("accounts.error.duplicateName")
            return
        }

        onSave()
    }
}
