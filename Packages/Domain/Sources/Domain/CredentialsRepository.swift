// MARK: - CredentialsRepository

/// Protocol for accessing OAuth credentials.
/// Implemented by KeychainCredentialsRepository in the Services package.
public protocol CredentialsRepository: Sendable {
    /// Retrieves the current OAuth credentials.
    /// - Returns: The stored credentials
    /// - Throws: `AppError.notAuthenticated` if no credentials exist
    func getCredentials() async throws -> Credentials

    /// Checks if valid credentials exist.
    /// - Returns: True if credentials are available
    func hasCredentials() async -> Bool
}
