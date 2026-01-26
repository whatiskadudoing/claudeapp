import AppKit
import Domain
import Services
import UserNotifications

// MARK: - AppContainer

/// Dependency injection container that wires up all app dependencies.
/// Creates and holds references to all managers and repositories.
/// Handles app lifecycle including auto-refresh and sleep/wake events.
@MainActor
@Observable
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

    /// Manager for system notifications
    public let notificationManager: NotificationManager

    /// Manager for notification permission state (observable for UI)
    public let notificationPermissionManager: NotificationPermissionManager

    /// Checker for triggering usage notifications
    public let notificationChecker: UsageNotificationChecker

    /// Checker for app updates via GitHub Releases
    public let updateChecker: UpdateChecker

    /// The detected subscription plan type from credentials
    public private(set) var detectedPlanType: PlanType = .pro

    // MARK: - Configuration

    /// Default auto-refresh interval (5 minutes)
    private static let defaultRefreshInterval: TimeInterval = 300

    // MARK: - Notification Observers

    nonisolated(unsafe) private var sleepObserver: NSObjectProtocol?
    nonisolated(unsafe) private var wakeObserver: NSObjectProtocol?

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

        // Create notification manager, permission manager, and checker
        let notifManager = NotificationManager()
        self.notificationManager = notifManager
        self.notificationPermissionManager = NotificationPermissionManager(notificationManager: notifManager)
        self.notificationChecker = UsageNotificationChecker(
            notificationManager: notifManager,
            settingsManager: settings
        )

        // Create update checker
        self.updateChecker = UpdateChecker()

        // Create usage manager
        self.usageManager = UsageManager(usageRepository: apiClient)

        // Connect notification checker to usage manager
        usageManager.setNotificationChecker(notificationChecker)

        // Configure settings callback to update refresh interval
        settings.onRefreshIntervalChanged = { [weak self] newInterval in
            self?.usageManager.restartAutoRefresh(interval: TimeInterval(newInterval * 60))
        }

        // Start auto-refresh using settings interval
        usageManager.startAutoRefresh(interval: settings.refreshIntervalSeconds)

        // Request notification permission if notifications are enabled
        if settings.notificationsEnabled {
            Task {
                _ = await notifManager.requestPermission()
            }
        }

        // Register sleep/wake observers
        registerSleepWakeObservers()

        // Check for updates 5 seconds after launch (if enabled in settings)
        if settings.checkForUpdates {
            Task {
                try? await Task.sleep(for: .seconds(5))
                await checkForUpdatesInBackground(notificationManager: notifManager, updateChecker: self.updateChecker)
            }
        }

        // Fetch plan type from credentials
        Task {
            await self.fetchPlanType()
        }
    }

    /// Fetches the plan type from stored credentials.
    private func fetchPlanType() async {
        do {
            let credentials = try await credentialsRepository.getCredentials()
            self.detectedPlanType = credentials.planType
        } catch {
            // Keep default (Pro) if credentials can't be read
            self.detectedPlanType = .pro
        }
    }

    /// Performs a background update check and sends notification if update found.
    /// - Parameters:
    ///   - notificationManager: Manager to send notification through
    ///   - updateChecker: Checker to perform the version check
    private func checkForUpdatesInBackground(
        notificationManager: NotificationManager,
        updateChecker: UpdateChecker
    ) async {
        guard let result = await updateChecker.checkInBackground() else {
            return // Rate limited or skipped
        }

        // Only notify if we should (haven't notified for this version yet)
        guard let updateInfo = await updateChecker.shouldNotify(for: result) else {
            return
        }

        await notificationManager.send(
            title: "Update Available",
            body: "ClaudeApp v\(updateInfo.version) is now available",
            identifier: "update-available-\(updateInfo.version)"
        )
    }

    /// Creates a new AppContainer with custom dependencies (for testing).
    /// Does NOT start auto-refresh or register observers - caller controls lifecycle.
    /// - Parameters:
    ///   - credentialsRepository: Custom credentials repository
    ///   - usageRepository: Custom usage repository
    ///   - settingsRepository: Custom settings repository (optional)
    ///   - launchAtLoginService: Custom launch at login service (optional)
    ///   - notificationService: Custom notification service (optional)
    ///   - startAutoRefresh: Whether to start auto-refresh (default false for tests)
    public init(
        credentialsRepository: CredentialsRepository,
        usageRepository: UsageRepository,
        settingsRepository: SettingsRepository? = nil,
        launchAtLoginService: LaunchAtLoginService? = nil,
        notificationService: NotificationService? = nil,
        startAutoRefresh: Bool = false
    ) {
        self.credentialsRepository = credentialsRepository
        self.usageRepository = usageRepository
        let settings = SettingsManager(repository: settingsRepository ?? UserDefaultsSettingsRepository())
        self.settingsManager = settings
        self.launchAtLoginManager = launchAtLoginService.map { LaunchAtLoginManager(service: $0) } ?? LaunchAtLoginManager()

        // Create notification manager, permission manager, and checker
        let notifManager = notificationService.map { NotificationManager(notificationCenter: $0) } ?? NotificationManager()
        self.notificationManager = notifManager
        self.notificationPermissionManager = NotificationPermissionManager(notificationManager: notifManager)
        self.notificationChecker = UsageNotificationChecker(
            notificationManager: notifManager,
            settingsManager: settings
        )

        // Create update checker (uses default settings for tests)
        self.updateChecker = UpdateChecker()

        self.usageManager = UsageManager(usageRepository: usageRepository)
        usageManager.setNotificationChecker(notificationChecker)

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
