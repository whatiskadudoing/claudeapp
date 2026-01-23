import Foundation
import UserNotifications

// MARK: - NotificationService Protocol

/// Protocol for notification system integration.
/// Allows mocking UNUserNotificationCenter in tests.
public protocol NotificationService: Sendable {
    /// Request notification permission from the user
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool

    /// Get current authorization status
    func authorizationStatus() async -> UNAuthorizationStatus

    /// Add a notification request
    func add(_ request: UNNotificationRequest) async throws

    /// Remove delivered notifications (sync, non-isolated)
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

// MARK: - UNUserNotificationCenter Conformance

extension UNUserNotificationCenter: NotificationService {
    public func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
}

// MARK: - Stub Service for Non-Bundle Contexts

/// A no-op notification service used when running outside an app bundle.
/// UNUserNotificationCenter.current() crashes without a valid bundle,
/// so this stub allows the app to run for development/testing.
private final class StubNotificationService: NotificationService {
    func requestAuthorization(options _: UNAuthorizationOptions) async throws -> Bool {
        false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        .notDetermined
    }

    func add(_: UNNotificationRequest) async throws {
        // No-op: notifications not available outside bundle
    }

    func removeDeliveredNotifications(withIdentifiers _: [String]) {
        // No-op
    }
}

// MARK: - Safe Notification Center Access

/// Safely get the notification center, returning nil if not in a bundle context.
/// This prevents crashes when running the bare executable from SPM.
private func safeNotificationCenter() -> NotificationService {
    // Check if we have a valid bundle with an identifier
    // UNUserNotificationCenter.current() crashes without this
    guard Bundle.main.bundleIdentifier != nil else {
        return StubNotificationService()
    }
    return UNUserNotificationCenter.current()
}

// MARK: - NotificationManager

/// Manager for handling system notifications.
///
/// This actor provides:
/// - Permission request handling (with tracking to avoid repeated prompts)
/// - Notification sending with duplicate prevention per identifier
/// - State management to support hysteresis logic
/// - Permission status checking
///
/// Thread safety is guaranteed by actor isolation.
public actor NotificationManager {
    // MARK: - Public Properties (accessed via methods)

    /// Whether permission has been requested during this session
    private var hasRequestedPermission = false

    /// Tracks which notification identifiers have been sent this cycle
    /// Used to prevent duplicate notifications until state is reset
    private var notificationState: [String: Bool] = [:]

    // MARK: - Private Properties

    private let notificationCenter: NotificationService

    // MARK: - Initialization

    /// Creates a new NotificationManager with the default UNUserNotificationCenter.
    /// Falls back to a stub service when running outside an app bundle (e.g., SPM debug builds).
    public init() {
        self.notificationCenter = safeNotificationCenter()
    }

    /// Creates a new NotificationManager with a custom service (for testing).
    /// - Parameter notificationCenter: The notification service to use
    public init(notificationCenter: NotificationService) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Permission Methods

    /// Requests notification permission from the user.
    ///
    /// This method tracks whether permission has been requested to avoid
    /// showing repeated system prompts. On subsequent calls within the
    /// same session, it returns the current permission status instead.
    ///
    /// - Returns: `true` if permission is granted, `false` otherwise
    public func requestPermission() async -> Bool {
        // If already requested this session, just check current status
        if hasRequestedPermission {
            return await checkPermissionStatus() == .authorized
        }

        hasRequestedPermission = true

        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Checks the current notification permission status.
    ///
    /// - Returns: The current authorization status
    public func checkPermissionStatus() async -> UNAuthorizationStatus {
        await notificationCenter.authorizationStatus()
    }

    // MARK: - Notification Methods

    /// Sends a notification immediately.
    ///
    /// This method includes duplicate prevention: if a notification with the
    /// same identifier has already been sent in the current cycle (before
    /// `resetState` is called), it will be skipped.
    ///
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: The notification body text
    ///   - identifier: Unique identifier for this notification
    public func send(title: String, body: String, identifier: String) async {
        // Check duplicate prevention
        guard notificationState[identifier] != true else {
            return
        }

        // Mark as sent for this cycle
        notificationState[identifier] = true

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Create immediate request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // nil trigger = immediate delivery
        )

        // Send notification (ignore errors - notification delivery is best-effort)
        try? await notificationCenter.add(request)
    }

    // MARK: - State Management

    /// Resets the notification state for a specific identifier.
    ///
    /// Call this when utilization drops below the hysteresis threshold
    /// to allow the notification to fire again when the threshold is
    /// crossed the next time.
    ///
    /// - Parameter identifier: The notification identifier to reset
    public func resetState(for identifier: String) {
        notificationState[identifier] = false
    }

    /// Resets all notification states.
    ///
    /// This clears all tracking, allowing all notifications to fire again.
    public func resetAllStates() {
        notificationState.removeAll()
    }

    /// Checks if a notification has been sent for a given identifier.
    ///
    /// - Parameter identifier: The notification identifier to check
    /// - Returns: `true` if a notification was sent for this identifier
    public func hasNotified(for identifier: String) -> Bool {
        notificationState[identifier] == true
    }

    /// Removes delivered notifications from the notification center.
    ///
    /// - Parameter identifiers: Array of notification identifiers to remove
    public func removeDelivered(identifiers: [String]) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
