import Foundation

// MARK: - Credentials

/// OAuth credentials for authenticating with the Claude API.
/// Retrieved from the macOS Keychain where Claude Code stores them.
public struct Credentials: Sendable {
    /// OAuth access token for API requests
    public let accessToken: String

    /// OAuth refresh token for obtaining new access tokens
    public let refreshToken: String?

    /// When the access token expires (nil if unknown)
    public let expiresAt: Date?

    /// The subscription type (e.g., "pro", "max")
    public let subscriptionType: String?

    /// The rate limit tier (e.g., "default_claude_pro", "default_claude_max_20x")
    public let rateLimitTier: String?

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil,
        subscriptionType: String? = nil,
        rateLimitTier: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.subscriptionType = subscriptionType
        self.rateLimitTier = rateLimitTier
    }

    /// Whether the access token has expired.
    /// Returns false if expiration date is unknown.
    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    /// Detected plan type based on subscription and rate limit tier
    public var planType: PlanType {
        // Check rateLimitTier first (more specific)
        if let tier = rateLimitTier?.lowercased() {
            if tier.contains("20x") {
                return .max20x
            } else if tier.contains("5x") {
                return .max5x
            } else if tier.contains("max") {
                // Generic max without multiplier - default to 5x
                return .max5x
            }
        }

        // Fall back to subscriptionType
        if let sub = subscriptionType?.lowercased() {
            if sub == "max" {
                // If max but no specific tier, check rateLimitTier again or default
                return .max5x
            }
        }

        // Default to Pro
        return .pro
    }
}
