import Foundation
import UserNotifications

// MARK: - NotificationPermissionStatus

/// Simplified permission status for UI display.
public enum NotificationPermissionStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case provisional

    /// Whether notifications can be sent with this status
    public var canSendNotifications: Bool {
        switch self {
        case .authorized, .provisional:
            return true
        case .notDetermined, .denied:
            return false
        }
    }

    /// Create from UNAuthorizationStatus
    init(from status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .provisional:
            self = .provisional
        @unknown default:
            self = .denied
        }
    }
}

// MARK: - NotificationPermissionManager

/// Observable manager for notification permission state.
///
/// This class provides:
/// - Observable permission status for SwiftUI binding
/// - Methods to request and refresh permission status
/// - Integration with NotificationManager actor
///
/// Must be created and used on MainActor for UI binding.
@MainActor
@Observable
public final class NotificationPermissionManager {
    // MARK: - Public Properties

    /// Current notification permission status
    public private(set) var permissionStatus: NotificationPermissionStatus = .notDetermined

    /// Whether permission has been requested (to avoid showing multiple prompts)
    public private(set) var hasRequestedPermission: Bool = false

    /// Error message from last failed operation, if any
    public private(set) var lastError: String?

    // MARK: - Computed Properties

    /// Whether notifications are currently disabled by the user
    public var isPermissionDenied: Bool {
        permissionStatus == .denied
    }

    /// Whether we can send notifications with current permission
    public var canSendNotifications: Bool {
        permissionStatus.canSendNotifications
    }

    /// User-friendly description of the current permission status
    public var statusDescription: String {
        switch permissionStatus {
        case .notDetermined:
            return "Not requested"
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        case .provisional:
            return "Provisional"
        }
    }

    // MARK: - Private Properties

    private let notificationManager: NotificationManager

    // MARK: - Initialization

    /// Creates a new NotificationPermissionManager.
    /// - Parameter notificationManager: The notification manager to use for permission requests
    public init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager

        // Check initial permission status
        Task {
            await refreshPermissionStatus()
        }
    }

    // MARK: - Public Methods

    /// Requests notification permission from the user.
    ///
    /// This will show the system permission dialog if not already requested.
    /// Updates `permissionStatus` with the result.
    ///
    /// - Returns: `true` if permission was granted, `false` otherwise
    @discardableResult
    public func requestPermission() async -> Bool {
        lastError = nil
        hasRequestedPermission = true

        let granted = await notificationManager.requestPermission()

        // Refresh status to get accurate state
        await refreshPermissionStatus()

        return granted
    }

    /// Refreshes the permission status from the system.
    ///
    /// Call this when the app becomes active or settings window opens
    /// to sync with any changes made in System Settings.
    public func refreshPermissionStatus() async {
        let status = await notificationManager.checkPermissionStatus()
        permissionStatus = NotificationPermissionStatus(from: status)
    }
}
