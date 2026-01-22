import AppKit
import Domain
import Services

// MARK: - AppContainer

/// Dependency injection container that wires up all app dependencies.
/// Creates and holds references to all managers and repositories.
/// Handles app lifecycle including auto-refresh and sleep/wake events.
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

    /// Manager for app settings
    public let settingsManager: SettingsManager

    /// Manager for launch at login functionality
    public let launchAtLoginManager: LaunchAtLoginManager

    // MARK: - Configuration

    /// Default auto-refresh interval (5 minutes)
    private static let defaultRefreshInterval: TimeInterval = 300

    // MARK: - Notification Observers

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    // MARK: - Initialization

    /// Creates a new AppContainer with default production dependencies.
    /// Starts auto-refresh and registers system event observers.
    public init() {
        // Create repositories
        let keychainRepo = KeychainCredentialsRepository()
        self.credentialsRepository = keychainRepo

        let apiClient = ClaudeAPIClient(credentialsRepository: keychainRepo)
        self.usageRepository = apiClient

        // Create settings manager first (other managers may depend on it)
        let settings = SettingsManager()
        self.settingsManager = settings

        // Create launch at login manager
        self.launchAtLoginManager = LaunchAtLoginManager()

        // Create usage manager
        self.usageManager = UsageManager(usageRepository: apiClient)

        // Configure settings callback to update refresh interval
        settings.onRefreshIntervalChanged = { [weak self] newInterval in
            self?.usageManager.restartAutoRefresh(interval: TimeInterval(newInterval * 60))
        }

        // Start auto-refresh using settings interval
        usageManager.startAutoRefresh(interval: settings.refreshIntervalSeconds)

        // Register sleep/wake observers
        registerSleepWakeObservers()
    }

    /// Creates a new AppContainer with custom dependencies (for testing).
    /// Does NOT start auto-refresh or register observers - caller controls lifecycle.
    /// - Parameters:
    ///   - credentialsRepository: Custom credentials repository
    ///   - usageRepository: Custom usage repository
    ///   - settingsRepository: Custom settings repository (optional)
    ///   - launchAtLoginService: Custom launch at login service (optional)
    ///   - startAutoRefresh: Whether to start auto-refresh (default false for tests)
    public init(
        credentialsRepository: CredentialsRepository,
        usageRepository: UsageRepository,
        settingsRepository: SettingsRepository? = nil,
        launchAtLoginService: LaunchAtLoginService? = nil,
        startAutoRefresh: Bool = false
    ) {
        self.credentialsRepository = credentialsRepository
        self.usageRepository = usageRepository
        self.settingsManager = SettingsManager(repository: settingsRepository ?? UserDefaultsSettingsRepository())
        self.launchAtLoginManager = launchAtLoginService.map { LaunchAtLoginManager(service: $0) } ?? LaunchAtLoginManager()
        self.usageManager = UsageManager(usageRepository: usageRepository)

        if startAutoRefresh {
            usageManager.startAutoRefresh(interval: Self.defaultRefreshInterval)
            registerSleepWakeObservers()
        }
    }

    deinit {
        // Clean up notification observers
        if let sleepObserver = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        if let wakeObserver = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    // MARK: - System Event Handling

    /// Registers observers for system sleep/wake notifications.
    private func registerSleepWakeObservers() {
        // Pause auto-refresh during sleep
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.usageManager.handleSleep()
            }
        }

        // Resume auto-refresh after wake
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.usageManager.handleWake()
            }
        }
    }
}
