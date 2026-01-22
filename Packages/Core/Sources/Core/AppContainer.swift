import Domain
import Services

// MARK: - AppContainer

/// Dependency injection container that wires up all app dependencies.
/// Creates and holds references to all managers and repositories.
@MainActor
public final class AppContainer {
    // MARK: - Repositories

    /// Repository for accessing Keychain credentials
    public let credentialsRepository: CredentialsRepository

    /// Repository for fetching usage data from API
    public let usageRepository: UsageRepository

    // MARK: - Managers

    /// Manager for usage data state
    public let usageManager: UsageManager

    // MARK: - Initialization

    /// Creates a new AppContainer with default production dependencies.
    public init() {
        // Create repositories
        let keychainRepo = KeychainCredentialsRepository()
        self.credentialsRepository = keychainRepo

        let apiClient = ClaudeAPIClient(credentialsRepository: keychainRepo)
        self.usageRepository = apiClient

        // Create managers
        self.usageManager = UsageManager(usageRepository: apiClient)
    }

    /// Creates a new AppContainer with custom dependencies (for testing).
    /// - Parameters:
    ///   - credentialsRepository: Custom credentials repository
    ///   - usageRepository: Custom usage repository
    public init(
        credentialsRepository: CredentialsRepository,
        usageRepository: UsageRepository
    ) {
        self.credentialsRepository = credentialsRepository
        self.usageRepository = usageRepository
        self.usageManager = UsageManager(usageRepository: usageRepository)
    }
}
