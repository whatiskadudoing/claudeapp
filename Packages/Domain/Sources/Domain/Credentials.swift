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

    public init(accessToken: String, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// Whether the access token has expired.
    /// Returns false if expiration date is unknown.
    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }
}
