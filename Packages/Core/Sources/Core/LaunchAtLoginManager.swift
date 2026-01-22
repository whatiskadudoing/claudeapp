import Foundation
import ServiceManagement

// MARK: - LaunchAtLoginService Protocol

/// Protocol for launch at login system integration.
/// Allows mocking SMAppService in tests.
public protocol LaunchAtLoginService: Sendable {
    /// The current registration status
    var status: SMAppService.Status { get }

    /// Register the app to launch at login
    func register() throws

    /// Unregister the app from launching at login
    func unregister() throws
}

// MARK: - SMAppService Conformance

extension SMAppService: LaunchAtLoginService {}

// MARK: - LaunchAtLoginManager

/// Manager for controlling launch at login functionality using SMAppService.
/// Uses @Observable for SwiftUI integration.
///
/// This manager:
/// - Reads the current status from SMAppService on init
/// - Registers/unregisters when `isEnabled` changes
/// - Handles errors by reverting the toggle state
/// - Provides status information for UI feedback
@MainActor
@Observable
public final class LaunchAtLoginManager {
    // MARK: - Public Properties

    /// Whether the app is set to launch at login.
    /// Setting this will attempt to register/unregister with the system.
    /// On failure, the value reverts to the actual system state.
    public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue, !isUpdating else { return }
            updateRegistration()
        }
    }

    /// The current status from SMAppService.
    /// Use this to show appropriate UI feedback.
    public private(set) var status: SMAppService.Status

    /// Error message from the last failed operation, if any.
    public private(set) var lastError: String?

    // MARK: - Private Properties

    private let service: LaunchAtLoginService

    /// Flag to prevent re-entry when reverting isEnabled on error
    private var isUpdating = false

    // MARK: - Initialization

    /// Creates a new LaunchAtLoginManager with the default SMAppService.
    public convenience init() {
        self.init(service: SMAppService.mainApp)
    }

    /// Creates a new LaunchAtLoginManager with a custom service (for testing).
    /// - Parameter service: The service to use for registration
    public init(service: LaunchAtLoginService) {
        self.service = service
        self.status = service.status
        self.isEnabled = service.status == .enabled
        self.lastError = nil
    }

    // MARK: - Public Methods

    /// Refreshes the status from the system.
    /// Call this when the app becomes active to sync with external changes.
    public func refreshStatus() {
        status = service.status
        let systemEnabled = status == .enabled
        if isEnabled != systemEnabled {
            isEnabled = systemEnabled
        }
        lastError = nil
    }

    /// Returns a user-friendly description of the current status.
    public var statusDescription: String {
        switch status {
        case .notRegistered:
            return "Not set to launch at login"
        case .enabled:
            return "Will launch at login"
        case .requiresApproval:
            return "Requires approval in System Settings"
        case .notFound:
            return "App not found"
        @unknown default:
            return "Unknown status"
        }
    }

    /// Whether the status requires user action in System Settings.
    public var requiresUserApproval: Bool {
        status == .requiresApproval
    }

    // MARK: - Private Methods

    private func updateRegistration() {
        isUpdating = true
        defer { isUpdating = false }

        lastError = nil

        do {
            if isEnabled {
                // Only register if not already enabled
                if service.status != .enabled {
                    try service.register()
                }
            } else {
                // Only unregister if currently enabled
                if service.status == .enabled {
                    try service.unregister()
                }
            }
            // Update status after successful operation
            status = service.status
        } catch {
            // Revert to actual system state on failure
            lastError = error.localizedDescription
            status = service.status
            isEnabled = service.status == .enabled
        }
    }
}
