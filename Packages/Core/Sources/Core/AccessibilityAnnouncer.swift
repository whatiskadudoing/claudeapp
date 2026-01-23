import AppKit
import Foundation

// MARK: - AccessibilityAnnouncerProtocol

/// Protocol for accessibility announcements.
/// Allows mocking in tests.
public protocol AccessibilityAnnouncerProtocol: Sendable {
    /// Posts an announcement to VoiceOver users.
    /// - Parameter message: The message to announce
    func announce(_ message: String)
}

// MARK: - AccessibilityAnnouncer

/// Posts VoiceOver announcements for important state changes.
///
/// This class provides accessible feedback for screen reader users by
/// announcing state changes that might not be visually apparent:
/// - Refresh completion
/// - Errors during refresh
/// - Threshold warnings when usage crosses configured limits
///
/// Announcements are only posted when VoiceOver is active to avoid
/// unnecessary work when no assistive technology is in use.
public final class AccessibilityAnnouncer: AccessibilityAnnouncerProtocol, @unchecked Sendable {
    // MARK: - Singleton

    /// Shared instance for app-wide use
    public static let shared = AccessibilityAnnouncer()

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Posts an announcement to VoiceOver users.
    ///
    /// The announcement is only posted when VoiceOver is currently running.
    /// This check prevents unnecessary work when no assistive technology is active.
    ///
    /// - Parameter message: The message to announce (e.g., "Usage data updated")
    public func announce(_ message: String) {
        // Only announce when VoiceOver is active
        guard NSWorkspace.shared.isVoiceOverEnabled else { return }

        // Post the announcement to VoiceOver
        // Use the focused window as the element to announce from
        // If no focused window, announcement still works as a generic announcement
        NSAccessibility.post(
            element: NSApp.keyWindow ?? NSApp as Any,
            notification: .announcementRequested,
            userInfo: [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.high.rawValue
            ]
        )
    }
}

// MARK: - Announcement Messages

/// Predefined announcement messages for consistency.
public enum AccessibilityAnnouncementMessages {
    /// Announcement after successful refresh
    public static let refreshComplete = "Usage data updated"

    /// Announcement when refresh fails
    public static let refreshFailed = "Unable to refresh usage data"

    /// Announcement for warning threshold crossed
    /// - Parameter percentage: The current usage percentage
    /// - Returns: Formatted announcement string
    public static func warningThreshold(percentage: Int) -> String {
        "Warning: usage at \(percentage) percent"
    }

    /// Announcement for capacity full (100%)
    /// - Parameter windowName: The name of the usage window (e.g., "Current session")
    /// - Returns: Formatted announcement string
    public static func capacityFull(windowName: String) -> String {
        "\(windowName) limit reached"
    }

    /// Announcement for usage reset
    public static let resetComplete = "Usage limit has reset. Full capacity available."
}
