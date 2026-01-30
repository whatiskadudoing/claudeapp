import Domain
import Foundation
import Services

// MARK: - MultiAccountCredentialsRepository

/// Repository for retrieving credentials for multiple accounts.
/// Delegates to KeychainCredentialsRepository with account-specific service names.
///
/// Each account has its own Keychain entry:
/// - "default" identifier → Uses "Claude Code-credentials" (backward compatible)
/// - Other identifiers → Uses "ClaudeApp-account-{identifier}"
public actor MultiAccountCredentialsRepository {
    // MARK: - Properties

    /// Cache of KeychainCredentialsRepository instances keyed by service name.
    /// This avoids creating new instances for each credential fetch.
    private var repositoryCache: [String: KeychainCredentialsRepository] = [:]

    // MARK: - Initialization

    public init() {}

    // MARK: - Credential Retrieval

    /// Get credentials for a specific account.
    /// - Parameter account: The account to fetch credentials for
    /// - Returns: The credentials stored for this account
    /// - Throws: `AppError.notAuthenticated` if no credentials exist,
    ///           `AppError.keychainError` if credentials cannot be read
    public func getCredentials(for account: Account) async throws -> Credentials {
        let repository = getOrCreateRepository(for: account.keychainServiceName)
        return try await repository.getCredentials()
    }

    /// Check if credentials exist for a specific account.
    /// - Parameter account: The account to check credentials for
    /// - Returns: `true` if credentials are available and readable
    public func hasCredentials(for account: Account) async -> Bool {
        let repository = getOrCreateRepository(for: account.keychainServiceName)
        return await repository.hasCredentials()
    }

    /// Get credentials using a specific keychain service name.
    /// This is useful for validating credentials before creating an account.
    /// - Parameter serviceName: The Keychain service name
    /// - Returns: The credentials stored under this service name
    /// - Throws: `AppError.notAuthenticated` if no credentials exist
    public func getCredentials(forServiceName serviceName: String) async throws -> Credentials {
        let repository = getOrCreateRepository(for: serviceName)
        return try await repository.getCredentials()
    }

    /// Check if credentials exist for a specific service name.
    /// - Parameter serviceName: The Keychain service name to check
    /// - Returns: `true` if credentials are available
    public func hasCredentials(forServiceName serviceName: String) async -> Bool {
        let repository = getOrCreateRepository(for: serviceName)
        return await repository.hasCredentials()
    }

    // MARK: - Private Methods

    private func getOrCreateRepository(for serviceName: String) -> KeychainCredentialsRepository {
        if let cached = repositoryCache[serviceName] {
            return cached
        }

        let repository = KeychainCredentialsRepository(serviceName: serviceName)
        repositoryCache[serviceName] = repository
        return repository
    }

    // MARK: - Testing Support

    /// Clears the repository cache. Primarily used for testing.
    public func clearCache() {
        repositoryCache.removeAll()
    }
}

// MARK: - CredentialsRepository Conformance (Single Account Compatibility)

/// Extension to make MultiAccountCredentialsRepository compatible with existing single-account code.
/// Uses the default "Claude Code-credentials" service name.
extension MultiAccountCredentialsRepository: CredentialsRepository {
    /// Retrieves credentials using the default Claude Code service name.
    /// This maintains backward compatibility with single-account code.
    public func getCredentials() async throws -> Credentials {
        try await getCredentials(forServiceName: "Claude Code-credentials")
    }

    /// Checks if credentials exist using the default Claude Code service name.
    public func hasCredentials() async -> Bool {
        await hasCredentials(forServiceName: "Claude Code-credentials")
    }
}
