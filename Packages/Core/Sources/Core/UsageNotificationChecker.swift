import Domain
import Foundation

// MARK: - UsageNotificationChecker

/// Evaluates usage changes and triggers notifications when thresholds are crossed.
///
/// This class implements the notification trigger logic including:
/// - Usage Warning: fires when utilization crosses the warning threshold from below
/// - Capacity Full: fires when utilization hits 100%
/// - Reset Complete: fires when 7-day usage drops significantly (>50% to <10%)
/// - Hysteresis: prevents notification spam by requiring util to drop 5% below threshold
///   before the notification can fire again
///
/// Thread safety: This class reads settings synchronously and coordinates with the
/// NotificationManager actor for actual notification delivery.
@MainActor
public final class UsageNotificationChecker {
    // MARK: - Types

    /// Represents a named usage window for iteration
    private struct NamedWindow {
        let name: String
        let identifier: String
        let current: UsageWindow?
        let previous: UsageWindow?
    }

    // MARK: - Constants

    /// Hysteresis buffer percentage. Notification state resets when utilization
    /// drops this amount below the threshold.
    private static let hysteresisBuffer: Double = 5.0

    /// Reset detection threshold - previous utilization must be above this
    private static let resetDetectionHighThreshold: Double = 50.0

    /// Reset detection threshold - current utilization must be below this
    private static let resetDetectionLowThreshold: Double = 10.0

    // MARK: - Dependencies

    private let notificationManager: NotificationManager
    private let settingsManager: SettingsManager

    // MARK: - Initialization

    /// Creates a new UsageNotificationChecker.
    ///
    /// - Parameters:
    ///   - notificationManager: Manager for sending notifications
    ///   - settingsManager: Manager for reading notification settings
    public init(
        notificationManager: NotificationManager,
        settingsManager: SettingsManager
    ) {
        self.notificationManager = notificationManager
        self.settingsManager = settingsManager
    }

    // MARK: - Public Methods

    /// Checks current usage against previous usage and triggers notifications as needed.
    ///
    /// This method should be called after each successful usage data refresh.
    /// It evaluates all usage windows and triggers appropriate notifications
    /// while respecting user settings and hysteresis logic.
    ///
    /// - Parameters:
    ///   - current: The newly fetched usage data
    ///   - previous: The previous usage data (nil on first fetch)
    public func check(current: UsageData, previous: UsageData?) async {
        // Bail out if notifications are globally disabled
        guard settingsManager.notificationsEnabled else { return }

        // Build named windows for iteration
        let windows = buildNamedWindows(current: current, previous: previous)

        // Get settings
        let warningThreshold = Double(settingsManager.warningThreshold)
        let warningEnabled = settingsManager.warningEnabled
        let capacityFullEnabled = settingsManager.capacityFullEnabled
        let resetCompleteEnabled = settingsManager.resetCompleteEnabled

        // Check each window for warning and capacity full notifications
        for window in windows {
            guard let currentWindow = window.current else { continue }

            let currentUtil = currentWindow.utilization
            let previousUtil = window.previous?.utilization ?? 0

            // Check warning threshold crossing
            if warningEnabled {
                await checkWarningThreshold(
                    name: window.name,
                    identifier: window.identifier,
                    currentUtil: currentUtil,
                    previousUtil: previousUtil,
                    threshold: warningThreshold,
                    resetsAt: currentWindow.resetsAt
                )
            }

            // Check capacity full (100%)
            if capacityFullEnabled {
                await checkCapacityFull(
                    name: window.name,
                    identifier: window.identifier,
                    currentUtil: currentUtil,
                    previousUtil: previousUtil,
                    resetsAt: currentWindow.resetsAt
                )
            }
        }

        // Check for reset complete (7-day only)
        if resetCompleteEnabled {
            await checkResetComplete(
                currentSevenDay: current.sevenDay,
                previousSevenDay: previous?.sevenDay
            )
        }
    }

    // MARK: - Private Methods

    /// Builds an array of named windows for iteration.
    private func buildNamedWindows(current: UsageData, previous: UsageData?) -> [NamedWindow] {
        [
            NamedWindow(
                name: "Current session",
                identifier: "session",
                current: current.fiveHour,
                previous: previous?.fiveHour
            ),
            NamedWindow(
                name: "Weekly (all models)",
                identifier: "weekly",
                current: current.sevenDay,
                previous: previous?.sevenDay
            ),
            NamedWindow(
                name: "Weekly (Opus)",
                identifier: "opus",
                current: current.sevenDayOpus,
                previous: previous?.sevenDayOpus
            ),
            NamedWindow(
                name: "Weekly (Sonnet)",
                identifier: "sonnet",
                current: current.sevenDaySonnet,
                previous: previous?.sevenDaySonnet
            )
        ]
    }

    /// Checks if the warning threshold was crossed and sends notification if needed.
    private func checkWarningThreshold(
        name: String,
        identifier: String,
        currentUtil: Double,
        previousUtil: Double,
        threshold: Double,
        resetsAt: Date?
    ) async {
        let notificationId = "usage-warning-\(identifier)"

        // Hysteresis: reset notification state if utilization drops below (threshold - buffer)
        let hysteresisThreshold = threshold - Self.hysteresisBuffer
        if currentUtil < hysteresisThreshold {
            await notificationManager.resetState(for: notificationId)
        }

        // Check if crossed threshold from below
        if currentUtil >= threshold && previousUtil < threshold {
            let body = buildNotificationBody(
                windowName: name,
                utilization: currentUtil,
                resetsAt: resetsAt
            )

            await notificationManager.send(
                title: "Claude Usage Warning",
                body: body,
                identifier: notificationId
            )
        }
    }

    /// Checks if utilization hit 100% and sends notification if needed.
    private func checkCapacityFull(
        name: String,
        identifier: String,
        currentUtil: Double,
        previousUtil: Double,
        resetsAt: Date?
    ) async {
        let notificationId = "capacity-full-\(identifier)"

        // Hysteresis: reset notification state if utilization drops below 95%
        let hysteresisThreshold = 100.0 - Self.hysteresisBuffer
        if currentUtil < hysteresisThreshold {
            await notificationManager.resetState(for: notificationId)
        }

        // Check if crossed 100% from below
        if currentUtil >= 100 && previousUtil < 100 {
            let body = buildCapacityFullBody(windowName: name, resetsAt: resetsAt)

            await notificationManager.send(
                title: "Claude Capacity Full",
                body: body,
                identifier: notificationId
            )
        }
    }

    /// Checks if 7-day usage reset occurred and sends notification if needed.
    private func checkResetComplete(
        currentSevenDay: UsageWindow,
        previousSevenDay: UsageWindow?
    ) async {
        let notificationId = "reset-complete"

        // Need previous data to detect reset
        guard let previousSevenDay else { return }

        // Reset detection: previous was high (>50%), current is low (<10%)
        let wasHigh = previousSevenDay.utilization > Self.resetDetectionHighThreshold
        let isLow = currentSevenDay.utilization < Self.resetDetectionLowThreshold

        if wasHigh && isLow {
            await notificationManager.send(
                title: "Usage Reset Complete",
                body: "Your weekly limit has reset. Full capacity available.",
                identifier: notificationId
            )
        }

        // Reset state when utilization rises above the low threshold
        // This ensures the notification can fire again on the next reset
        if currentSevenDay.utilization >= Self.resetDetectionLowThreshold {
            await notificationManager.resetState(for: notificationId)
        }
    }

    /// Builds the notification body for usage warnings.
    private func buildNotificationBody(
        windowName: String,
        utilization: Double,
        resetsAt: Date?
    ) -> String {
        var body = "\(windowName) at \(Int(utilization))%"
        if let resetsAt {
            body += ". \(formatResetTime(resetsAt))"
        }
        return body
    }

    /// Builds the notification body for capacity full alerts.
    private func buildCapacityFullBody(
        windowName: String,
        resetsAt: Date?
    ) -> String {
        var body = "\(windowName) limit reached"
        if let resetsAt {
            body += ". \(formatResetTime(resetsAt))"
        }
        return body
    }

    /// Formats the reset time for notification display.
    private func formatResetTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Resets \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
