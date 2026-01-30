import Foundation

// MARK: - Account

/// Represents a Claude account with credentials and metadata.
/// Used for multi-account support, allowing users to monitor usage
/// across different accounts (e.g., personal and work).
public struct Account: Identifiable, Sendable, Codable, Equatable {
    /// Unique identifier for this account
    public let id: UUID

    /// User-friendly name for the account (e.g., "Personal", "Work")
    public var name: String

    /// Optional email address associated with the account
    public var email: String?

    /// The subscription plan type for this account (e.g., Pro, Max 5x)
    public var planType: PlanType?

    /// Keychain identifier for retrieving credentials.
    /// "default" uses the standard "Claude Code-credentials" entry.
    /// Other values use "ClaudeApp-account-{keychainIdentifier}" format.
    public let keychainIdentifier: String

    /// Whether this account is enabled for monitoring.
    /// Disabled accounts are not refreshed but remain in the account list.
    public var isActive: Bool

    /// Whether this is the primary account.
    /// The primary account is shown by default when the app launches.
    public var isPrimary: Bool

    /// When this account was added to the app
    public let createdAt: Date

    /// Creates a new account.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: User-friendly name for the account
    ///   - email: Optional email address
    ///   - planType: Optional subscription plan type
    ///   - keychainIdentifier: Keychain identifier ("default" for Claude Code credentials)
    ///   - isActive: Whether the account is enabled (defaults to true)
    ///   - isPrimary: Whether this is the primary account (defaults to false)
    ///   - createdAt: When the account was created (defaults to now)
    public init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        planType: PlanType? = nil,
        keychainIdentifier: String = "default",
        isActive: Bool = true,
        isPrimary: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.planType = planType
        self.keychainIdentifier = keychainIdentifier
        self.isActive = isActive
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// Whether this account uses the default Claude Code credentials.
    /// Default accounts read from the "Claude Code-credentials" Keychain entry
    /// created by the Claude Code CLI.
    public var usesDefaultCredentials: Bool {
        keychainIdentifier == "default"
    }

    /// The actual Keychain service name used to retrieve credentials.
    /// For "default", returns "Claude Code-credentials".
    /// For other identifiers, returns "ClaudeApp-account-{identifier}".
    public var keychainServiceName: String {
        if usesDefaultCredentials {
            return "Claude Code-credentials"
        } else {
            return "ClaudeApp-account-\(keychainIdentifier)"
        }
    }

    /// Display name with plan badge if available.
    /// Example: "Personal (Pro)" or "Work (Max 5x)"
    public var displayNameWithPlan: String {
        if let planType {
            return "\(name) (\(planType.displayName))"
        }
        return name
    }
}
