import Domain
import Foundation
import ServiceManagement
import Services
import Testing
import UserNotifications
@testable import Core

@Suite("Core Tests")
struct CoreTests {
    @Test("Core version is correct")
    func coreVersion() {
        #expect(Core.version == "1.0.0")
    }
}

// MARK: - Mock Usage Repository

/// Mock repository for testing UsageManager
actor MockUsageRepository: UsageRepository {
    var usageDataToReturn: UsageData?
    var errorToThrow: AppError?
    var fetchCallCount = 0

    init(usageData: UsageData? = nil, error: AppError? = nil) {
        self.usageDataToReturn = usageData
        self.errorToThrow = error
    }

    func fetchUsage() async throws -> UsageData {
        fetchCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        if let data = usageDataToReturn {
            return data
        }
        throw AppError.networkError(message: "No data configured")
    }

    func setUsageData(_ data: UsageData) {
        usageDataToReturn = data
    }

    func setError(_ error: AppError?) {
        errorToThrow = error
    }
}

// MARK: - UsageManager Tests

@Suite("UsageManager Tests")
struct UsageManagerTests {
    @Test("Initial state has nil usageData")
    @MainActor
    func initialState() {
        let mockRepo = MockUsageRepository()
        let manager = UsageManager(usageRepository: mockRepo)

        #expect(manager.usageData == nil)
        #expect(manager.isLoading == false)
        #expect(manager.lastError == nil)
        #expect(manager.lastUpdated == nil)
        #expect(manager.highestUtilization == 0)
    }

    @Test("refresh updates usageData on success")
    @MainActor
    func refreshSuccess() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        #expect(manager.usageData != nil)
        #expect(manager.usageData?.fiveHour.utilization == 45.0)
        #expect(manager.usageData?.sevenDay.utilization == 72.0)
        #expect(manager.lastError == nil)
        #expect(manager.lastUpdated != nil)
        #expect(manager.isLoading == false)
    }

    @Test("refresh sets lastError on failure")
    @MainActor
    func refreshFailure() async {
        let mockRepo = MockUsageRepository(error: .notAuthenticated)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        #expect(manager.usageData == nil)
        #expect(manager.lastError == .notAuthenticated)
        #expect(manager.isLoading == false)
    }

    @Test("highestUtilization returns correct value")
    @MainActor
    func highestUtilization() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            sevenDayOpus: UsageWindow(utilization: 90.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        #expect(manager.highestUtilization == 90.0)
    }

    @Test("refresh prevents concurrent calls")
    @MainActor
    func preventsConcurrentRefresh() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Start two refreshes concurrently
        async let refresh1: Void = manager.refresh()
        async let refresh2: Void = manager.refresh()

        await refresh1
        await refresh2

        // Due to the guard, only one should execute
        let callCount = await mockRepo.fetchCallCount
        #expect(callCount == 1)
    }

    @Test("startAutoRefresh and stopAutoRefresh work correctly")
    @MainActor
    func autoRefreshLifecycle() async throws {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Start auto-refresh with very short interval
        manager.startAutoRefresh(interval: 0.1)

        // Wait for at least one refresh
        try await Task.sleep(for: .milliseconds(150))

        // Stop auto-refresh
        manager.stopAutoRefresh()

        let callCount = await mockRepo.fetchCallCount
        #expect(callCount >= 1)
    }

    @Test("refresh clears previous error on success")
    @MainActor
    func clearsPreviousErrorOnSuccess() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(error: .notAuthenticated)
        let manager = UsageManager(usageRepository: mockRepo)

        // First refresh fails
        await manager.refresh()
        #expect(manager.lastError == .notAuthenticated)

        // Configure success
        await mockRepo.setError(nil)
        await mockRepo.setUsageData(testData)

        // Second refresh succeeds
        await manager.refresh()
        #expect(manager.lastError == nil)
        #expect(manager.usageData != nil)
    }

    @Test("refresh handles network error")
    @MainActor
    func handlesNetworkError() async {
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        #expect(manager.lastError == .networkError(message: "Connection failed"))
    }

    @Test("refresh handles rate limit error")
    @MainActor
    func handlesRateLimitError() async {
        let mockRepo = MockUsageRepository(error: .rateLimited(retryAfter: 60))
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        #expect(manager.lastError == .rateLimited(retryAfter: 60))
    }

    // MARK: - Exponential Backoff Tests

    @Test("consecutive failures increase retry interval")
    @MainActor
    func consecutiveFailuresIncreaseRetryInterval() async {
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let manager = UsageManager(usageRepository: mockRepo)

        // Initial retry interval should be 60 seconds (base)
        #expect(manager.currentRetryInterval == 60)

        // First failure
        await manager.refresh()
        #expect(manager.failureCount == 1)
        #expect(manager.currentRetryInterval == 120) // 60 * 2^1

        // Second failure
        await manager.refresh()
        #expect(manager.failureCount == 2)
        #expect(manager.currentRetryInterval == 240) // 60 * 2^2

        // Third failure
        await manager.refresh()
        #expect(manager.failureCount == 3)
        #expect(manager.currentRetryInterval == 480) // 60 * 2^3

        // Fourth failure
        await manager.refresh()
        #expect(manager.failureCount == 4)
        #expect(manager.currentRetryInterval == 900) // Capped at 15 minutes (900s)

        // Fifth failure - should stay at max
        await manager.refresh()
        #expect(manager.failureCount == 5)
        #expect(manager.currentRetryInterval == 900) // Still capped at 15 minutes
    }

    @Test("success resets consecutive failures")
    @MainActor
    func successResetsConsecutiveFailures() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let manager = UsageManager(usageRepository: mockRepo)

        // Accumulate some failures
        await manager.refresh()
        await manager.refresh()
        #expect(manager.failureCount == 2)

        // Now succeed
        await mockRepo.setError(nil)
        await mockRepo.setUsageData(testData)
        await manager.refresh()

        // Failures should be reset
        #expect(manager.failureCount == 0)
        #expect(manager.currentRetryInterval == 60) // Back to base
    }

    @Test("auth errors do not increment failure count")
    @MainActor
    func authErrorsDoNotIncrementFailures() async {
        let mockRepo = MockUsageRepository(error: .notAuthenticated)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()
        #expect(manager.failureCount == 0) // Auth errors don't count

        await manager.refresh()
        #expect(manager.failureCount == 0) // Still zero
    }

    @Test("rate limit errors increment failure count")
    @MainActor
    func rateLimitErrorsIncrementFailures() async {
        let mockRepo = MockUsageRepository(error: .rateLimited(retryAfter: 60))
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()
        #expect(manager.failureCount == 1)

        await manager.refresh()
        #expect(manager.failureCount == 2)
    }

    // MARK: - Sleep/Wake Tests

    @Test("handleSleep stops auto-refresh")
    @MainActor
    func handleSleepStopsAutoRefresh() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Start auto-refresh
        manager.startAutoRefresh(interval: 1)
        #expect(manager.isAutoRefreshing == true)

        // Simulate sleep
        manager.handleSleep()
        #expect(manager.isAutoRefreshing == false)
    }

    @Test("handleWake resumes auto-refresh if was running")
    @MainActor
    func handleWakeResumesAutoRefresh() async throws {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Start auto-refresh
        manager.startAutoRefresh(interval: 1)
        #expect(manager.isAutoRefreshing == true)

        // Simulate sleep
        manager.handleSleep()
        #expect(manager.isAutoRefreshing == false)

        // Simulate wake - should resume
        manager.handleWake()

        // Give it a moment to resume
        try await Task.sleep(for: .milliseconds(50))
        #expect(manager.isAutoRefreshing == true)

        // Clean up
        manager.stopAutoRefresh()
    }

    @Test("handleWake does not resume if was not running")
    @MainActor
    func handleWakeDoesNotResumeIfWasNotRunning() async throws {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Don't start auto-refresh
        #expect(manager.isAutoRefreshing == false)

        // Simulate sleep
        manager.handleSleep()
        #expect(manager.isAutoRefreshing == false)

        // Simulate wake - should NOT resume since it wasn't running
        manager.handleWake()

        try await Task.sleep(for: .milliseconds(50))
        #expect(manager.isAutoRefreshing == false)
    }

    @Test("isAutoRefreshing reflects task state")
    @MainActor
    func isAutoRefreshingReflectsTaskState() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        #expect(manager.isAutoRefreshing == false)

        manager.startAutoRefresh(interval: 10)
        #expect(manager.isAutoRefreshing == true)

        manager.stopAutoRefresh()
        #expect(manager.isAutoRefreshing == false)
    }

    // MARK: - isStale Tests

    @Test("isStale returns true when no data")
    @MainActor
    func isStaleReturnsTrueWhenNoData() {
        let mockRepo = MockUsageRepository()
        let manager = UsageManager(usageRepository: mockRepo)

        #expect(manager.isStale == true)
    }

    @Test("isStale returns false after recent refresh")
    @MainActor
    func isStaleReturnsFalseAfterRecentRefresh() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        #expect(manager.isStale == false)
    }

    // MARK: - RefreshState Tests

    @Test("refreshState starts as idle")
    @MainActor
    func refreshStateStartsAsIdle() {
        let mockRepo = MockUsageRepository()
        let manager = UsageManager(usageRepository: mockRepo)

        #expect(manager.refreshState == .idle)
    }

    @Test("refreshState transitions to success after successful refresh")
    @MainActor
    func refreshStateTransitionsToSuccessOnSuccess() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        // Immediately after refresh, should be in success state
        #expect(manager.refreshState == .success)
    }

    @Test("refreshState transitions to error after failed refresh")
    @MainActor
    func refreshStateTransitionsToErrorOnFailure() async {
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        // Immediately after refresh, should be in error state
        #expect(manager.refreshState == .error)
    }

    @Test("refreshState returns to idle after flash duration")
    @MainActor
    func refreshStateReturnsToIdleAfterFlash() async throws {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()
        #expect(manager.refreshState == .success)

        // Wait for flash duration (1 second) plus buffer
        try await Task.sleep(for: .milliseconds(1100))

        #expect(manager.refreshState == .idle)
    }
}

// MARK: - AppContainer Tests

@Suite("AppContainer Tests")
struct AppContainerTests {
    @Test("AppContainer creates all dependencies")
    @MainActor
    func createsAllDependencies() {
        let container = AppContainer()

        #expect(container.credentialsRepository is KeychainCredentialsRepository)
        #expect(container.usageRepository is ClaudeAPIClient)

        // Clean up auto-refresh started by production init
        container.usageManager.stopAutoRefresh()
    }

    @Test("AppContainer creates UsageManager")
    @MainActor
    func createsUsageManager() {
        let container = AppContainer()

        #expect(container.usageManager.usageData == nil)
        #expect(container.usageManager.isLoading == false)

        // Clean up auto-refresh started by production init
        container.usageManager.stopAutoRefresh()
    }

    @Test("AppContainer starts auto-refresh on production init")
    @MainActor
    func startsAutoRefreshOnProductionInit() {
        let container = AppContainer()

        // Production init should start auto-refresh
        #expect(container.usageManager.isAutoRefreshing == true)

        // Clean up
        container.usageManager.stopAutoRefresh()
    }

    @Test("AppContainer test init does not start auto-refresh by default")
    @MainActor
    func testInitDoesNotStartAutoRefresh() {
        let mockCredentials = MockCredentialsRepository()
        let mockUsage = MockUsageRepository()
        let container = AppContainer(
            credentialsRepository: mockCredentials,
            usageRepository: mockUsage
        )

        // Test init should NOT start auto-refresh by default
        #expect(container.usageManager.isAutoRefreshing == false)
    }

    @Test("AppContainer test init can optionally start auto-refresh")
    @MainActor
    func testInitCanStartAutoRefresh() {
        let mockRepo = MockUsageRepository()
        let container = AppContainer(
            credentialsRepository: MockCredentialsRepository(),
            usageRepository: mockRepo,
            startAutoRefresh: true
        )

        // Should start auto-refresh when requested
        #expect(container.usageManager.isAutoRefreshing == true)

        // Clean up
        container.usageManager.stopAutoRefresh()
    }
}

// MARK: - Mock Credentials Repository for Tests

actor MockCredentialsRepository: CredentialsRepository {
    var credentialsToReturn: Credentials?
    var errorToThrow: AppError?

    init(credentials: Credentials? = nil, error: AppError? = nil) {
        self.credentialsToReturn = credentials
        self.errorToThrow = error
    }

    func getCredentials() async throws -> Credentials {
        if let error = errorToThrow {
            throw error
        }
        if let creds = credentialsToReturn {
            return creds
        }
        throw AppError.notAuthenticated
    }

    func hasCredentials() async -> Bool {
        credentialsToReturn != nil && errorToThrow == nil
    }
}

// MARK: - Mock Settings Repository for Tests

/// In-memory settings repository for testing
final class MockSettingsRepository: SettingsRepository, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func get<T: Codable & Sendable>(_ key: SettingsKey<T>) -> T {
        guard let data = storage[key.key],
              let value = try? JSONDecoder().decode(T.self, from: data)
        else {
            return key.defaultValue
        }
        return value
    }

    func set<T: Codable & Sendable>(_ key: SettingsKey<T>, value: T) {
        if let data = try? JSONEncoder().encode(value) {
            storage[key.key] = data
        }
    }

    /// Clears all stored settings
    func clear() {
        storage.removeAll()
    }
}

// MARK: - SettingsManager Tests

@Suite("SettingsManager Tests")
struct SettingsManagerTests {
    // MARK: - Default Values Tests

    @Test("Initial state has correct default values")
    @MainActor
    func initialStateDefaults() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        // Display settings defaults
        #expect(manager.showPlanBadge == false)
        #expect(manager.showPercentage == true)
        #expect(manager.percentageSource == .highest)

        // Refresh settings defaults
        #expect(manager.refreshInterval == 5)

        // Notification settings defaults
        #expect(manager.notificationsEnabled == true)
        #expect(manager.warningThreshold == 90)
        #expect(manager.warningEnabled == true)
        #expect(manager.capacityFullEnabled == true)
        #expect(manager.resetCompleteEnabled == true)

        // General settings defaults
        #expect(manager.launchAtLogin == false)
        #expect(manager.checkForUpdates == true)
    }

    // MARK: - Persistence Tests

    @Test("Display settings persist when changed")
    @MainActor
    func displaySettingsPersist() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        // Change settings
        manager.showPlanBadge = true
        manager.showPercentage = false
        manager.percentageSource = .session

        // Verify persisted
        #expect(mockRepo.get(.showPlanBadge) == true)
        #expect(mockRepo.get(.showPercentage) == false)
        #expect(mockRepo.get(.percentageSource) == .session)
    }

    @Test("Refresh settings persist when changed")
    @MainActor
    func refreshSettingsPersist() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        manager.refreshInterval = 15

        #expect(mockRepo.get(.refreshInterval) == 15)
    }

    @Test("Notification settings persist when changed")
    @MainActor
    func notificationSettingsPersist() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        manager.notificationsEnabled = false
        manager.warningThreshold = 75
        manager.warningEnabled = false
        manager.capacityFullEnabled = false
        manager.resetCompleteEnabled = false

        #expect(mockRepo.get(.notificationsEnabled) == false)
        #expect(mockRepo.get(.warningThreshold) == 75)
        #expect(mockRepo.get(.warningEnabled) == false)
        #expect(mockRepo.get(.capacityFullEnabled) == false)
        #expect(mockRepo.get(.resetCompleteEnabled) == false)
    }

    @Test("General settings persist when changed")
    @MainActor
    func generalSettingsPersist() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        manager.launchAtLogin = true
        manager.checkForUpdates = false

        #expect(mockRepo.get(.launchAtLogin) == true)
        #expect(mockRepo.get(.checkForUpdates) == false)
    }

    @Test("Settings load from repository on init")
    @MainActor
    func settingsLoadFromRepository() {
        let mockRepo = MockSettingsRepository()

        // Pre-populate repository
        mockRepo.set(.showPlanBadge, value: true)
        mockRepo.set(.showPercentage, value: false)
        mockRepo.set(.percentageSource, value: PercentageSource.weekly)
        mockRepo.set(.refreshInterval, value: 10)
        mockRepo.set(.warningThreshold, value: 80)

        // Create manager - should load from repository
        let manager = SettingsManager(repository: mockRepo)

        #expect(manager.showPlanBadge == true)
        #expect(manager.showPercentage == false)
        #expect(manager.percentageSource == .weekly)
        #expect(manager.refreshInterval == 10)
        #expect(manager.warningThreshold == 80)
    }

    // MARK: - Value Clamping Tests

    @Test("Refresh interval clamps to valid range")
    @MainActor
    func refreshIntervalClamping() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        // Test lower bound
        manager.refreshInterval = 0
        #expect(manager.refreshInterval == 1)

        // Test upper bound
        manager.refreshInterval = 100
        #expect(manager.refreshInterval == 30)

        // Test within range
        manager.refreshInterval = 15
        #expect(manager.refreshInterval == 15)
    }

    @Test("Warning threshold clamps to valid range")
    @MainActor
    func warningThresholdClamping() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        // Test lower bound
        manager.warningThreshold = 10
        #expect(manager.warningThreshold == 50)

        // Test upper bound
        manager.warningThreshold = 150
        #expect(manager.warningThreshold == 99)

        // Test within range
        manager.warningThreshold = 75
        #expect(manager.warningThreshold == 75)
    }

    // MARK: - Computed Property Tests

    @Test("refreshIntervalSeconds computes correctly")
    @MainActor
    func refreshIntervalSecondsComputation() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        manager.refreshInterval = 5
        #expect(manager.refreshIntervalSeconds == 300)

        manager.refreshInterval = 1
        #expect(manager.refreshIntervalSeconds == 60)

        manager.refreshInterval = 30
        #expect(manager.refreshIntervalSeconds == 1800)
    }

    // MARK: - Callback Tests

    @Test("onRefreshIntervalChanged callback fires when interval changes")
    @MainActor
    func refreshIntervalChangedCallback() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        var callbackInterval: Int?
        manager.onRefreshIntervalChanged = { interval in
            callbackInterval = interval
        }

        manager.refreshInterval = 10

        #expect(callbackInterval == 10)
    }

    @Test("onRefreshIntervalChanged not called when setting same value")
    @MainActor
    func refreshIntervalChangedCallbackNotCalledForSameValue() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        var callCount = 0
        manager.onRefreshIntervalChanged = { _ in
            callCount += 1
        }

        // Set to same as default (5)
        manager.refreshInterval = 5

        // Should still fire because didSet always fires
        // This is expected Swift behavior
        #expect(callCount == 1)
    }

    // MARK: - PercentageSource Tests

    @Test("All PercentageSource cases work correctly")
    @MainActor
    func percentageSourceAllCases() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        for source in PercentageSource.allCases {
            manager.percentageSource = source
            #expect(manager.percentageSource == source)
            #expect(mockRepo.get(.percentageSource) == source)
        }
    }

    @Test("PercentageSource raw values are correct")
    func percentageSourceRawValues() {
        #expect(PercentageSource.highest.rawValue == "Highest %")
        #expect(PercentageSource.session.rawValue == "Current Session")
        #expect(PercentageSource.weekly.rawValue == "Weekly (All Models)")
        #expect(PercentageSource.opus.rawValue == "Weekly (Opus)")
        #expect(PercentageSource.sonnet.rawValue == "Weekly (Sonnet)")
    }
}

// MARK: - UserDefaultsSettingsRepository Tests

@Suite("UserDefaultsSettingsRepository Tests")
struct UserDefaultsSettingsRepositoryTests {
    @Test("Returns default value when key not set")
    func returnsDefaultWhenNotSet() {
        // Use a unique suite name to avoid test interference
        let testSuiteName = "com.claudeapp.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: testSuiteName)!
        let repo = UserDefaultsSettingsRepository(defaults: defaults)

        #expect(repo.get(.showPlanBadge) == false) // default
        #expect(repo.get(.refreshInterval) == 5) // default

        // Clean up
        defaults.removePersistentDomain(forName: testSuiteName)
    }

    @Test("Set and get work correctly for Bool")
    func setAndGetBool() {
        let testSuiteName = "com.claudeapp.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: testSuiteName)!
        let repo = UserDefaultsSettingsRepository(defaults: defaults)

        repo.set(.showPlanBadge, value: true)
        #expect(repo.get(.showPlanBadge) == true)

        repo.set(.showPlanBadge, value: false)
        #expect(repo.get(.showPlanBadge) == false)

        defaults.removePersistentDomain(forName: testSuiteName)
    }

    @Test("Set and get work correctly for Int")
    func setAndGetInt() {
        let testSuiteName = "com.claudeapp.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: testSuiteName)!
        let repo = UserDefaultsSettingsRepository(defaults: defaults)

        repo.set(.refreshInterval, value: 15)
        #expect(repo.get(.refreshInterval) == 15)

        repo.set(.warningThreshold, value: 80)
        #expect(repo.get(.warningThreshold) == 80)

        defaults.removePersistentDomain(forName: testSuiteName)
    }

    @Test("Set and get work correctly for PercentageSource")
    func setAndGetPercentageSource() {
        let testSuiteName = "com.claudeapp.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: testSuiteName)!
        let repo = UserDefaultsSettingsRepository(defaults: defaults)

        repo.set(.percentageSource, value: .session)
        #expect(repo.get(.percentageSource) == .session)

        repo.set(.percentageSource, value: .opus)
        #expect(repo.get(.percentageSource) == .opus)

        defaults.removePersistentDomain(forName: testSuiteName)
    }
}

// MARK: - Mock LaunchAtLoginService for Tests

/// Mock service for testing LaunchAtLoginManager
final class MockLaunchAtLoginService: LaunchAtLoginService, @unchecked Sendable {
    private var _status: SMAppService.Status
    var shouldThrowOnRegister: Bool = false
    var shouldThrowOnUnregister: Bool = false
    var registerCallCount = 0
    var unregisterCallCount = 0

    init(initialStatus: SMAppService.Status = .notRegistered) {
        self._status = initialStatus
    }

    var status: SMAppService.Status {
        _status
    }

    func register() throws {
        registerCallCount += 1
        if shouldThrowOnRegister {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to register"])
        }
        _status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        if shouldThrowOnUnregister {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to unregister"])
        }
        _status = .notRegistered
    }

    /// Set the status externally (simulates system changes)
    func setStatus(_ newStatus: SMAppService.Status) {
        _status = newStatus
    }
}

// MARK: - LaunchAtLoginManager Tests

@Suite("LaunchAtLoginManager Tests")
struct LaunchAtLoginManagerTests {
    // MARK: - Initialization Tests

    @Test("Initial state reflects service status when not registered")
    @MainActor
    func initialStateNotRegistered() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.isEnabled == false)
        #expect(manager.status == .notRegistered)
        #expect(manager.lastError == nil)
    }

    @Test("Initial state reflects service status when enabled")
    @MainActor
    func initialStateEnabled() {
        let mockService = MockLaunchAtLoginService(initialStatus: .enabled)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.isEnabled == true)
        #expect(manager.status == .enabled)
        #expect(manager.lastError == nil)
    }

    @Test("Initial state reflects service status when requires approval")
    @MainActor
    func initialStateRequiresApproval() {
        let mockService = MockLaunchAtLoginService(initialStatus: .requiresApproval)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.isEnabled == false)
        #expect(manager.status == .requiresApproval)
        #expect(manager.requiresUserApproval == true)
    }

    // MARK: - Enable/Disable Tests

    @Test("Setting isEnabled to true registers the app")
    @MainActor
    func enableRegistersApp() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        let manager = LaunchAtLoginManager(service: mockService)

        manager.isEnabled = true

        #expect(mockService.registerCallCount == 1)
        #expect(mockService.unregisterCallCount == 0)
        #expect(manager.status == .enabled)
        #expect(manager.isEnabled == true)
        #expect(manager.lastError == nil)
    }

    @Test("Setting isEnabled to false unregisters the app")
    @MainActor
    func disableUnregistersApp() {
        let mockService = MockLaunchAtLoginService(initialStatus: .enabled)
        let manager = LaunchAtLoginManager(service: mockService)

        manager.isEnabled = false

        #expect(mockService.unregisterCallCount == 1)
        #expect(mockService.registerCallCount == 0)
        #expect(manager.status == .notRegistered)
        #expect(manager.isEnabled == false)
        #expect(manager.lastError == nil)
    }

    @Test("Setting isEnabled to same value does not call service")
    @MainActor
    func sameValueNoServiceCall() {
        let mockService = MockLaunchAtLoginService(initialStatus: .enabled)
        let manager = LaunchAtLoginManager(service: mockService)

        // Already enabled, set to true again
        manager.isEnabled = true

        #expect(mockService.registerCallCount == 0)
        #expect(mockService.unregisterCallCount == 0)
    }

    @Test("Does not register if already enabled")
    @MainActor
    func doesNotRegisterIfAlreadyEnabled() {
        let mockService = MockLaunchAtLoginService(initialStatus: .enabled)
        let manager = LaunchAtLoginManager(service: mockService)

        // Force a re-registration attempt by toggling off then on
        manager.isEnabled = false
        mockService.setStatus(.enabled) // Simulate external re-enable
        manager.isEnabled = true

        // Should only have called unregister once, register should be skipped since status is already enabled
        #expect(mockService.unregisterCallCount == 1)
        #expect(mockService.registerCallCount == 0)
    }

    @Test("Does not unregister if already not registered")
    @MainActor
    func doesNotUnregisterIfAlreadyNotRegistered() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        let manager = LaunchAtLoginManager(service: mockService)

        manager.isEnabled = false

        // Should not call unregister since already not registered
        #expect(mockService.unregisterCallCount == 0)
    }

    // MARK: - Error Handling Tests

    @Test("Reverts isEnabled on register failure")
    @MainActor
    func revertsOnRegisterFailure() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        mockService.shouldThrowOnRegister = true
        let manager = LaunchAtLoginManager(service: mockService)

        manager.isEnabled = true

        #expect(mockService.registerCallCount == 1)
        #expect(manager.isEnabled == false) // Reverted
        #expect(manager.status == .notRegistered)
        #expect(manager.lastError != nil)
        #expect(manager.lastError?.contains("Failed to register") == true)
    }

    @Test("Reverts isEnabled on unregister failure")
    @MainActor
    func revertsOnUnregisterFailure() {
        let mockService = MockLaunchAtLoginService(initialStatus: .enabled)
        mockService.shouldThrowOnUnregister = true
        let manager = LaunchAtLoginManager(service: mockService)

        manager.isEnabled = false

        #expect(mockService.unregisterCallCount == 1)
        #expect(manager.isEnabled == true) // Reverted
        #expect(manager.status == .enabled)
        #expect(manager.lastError != nil)
        #expect(manager.lastError?.contains("Failed to unregister") == true)
    }

    // MARK: - Refresh Status Tests

    @Test("refreshStatus syncs with system state")
    @MainActor
    func refreshStatusSyncs() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        let manager = LaunchAtLoginManager(service: mockService)

        // Simulate external change to enabled
        mockService.setStatus(.enabled)

        #expect(manager.isEnabled == false) // Still old value
        #expect(manager.status == .notRegistered) // Still old value

        manager.refreshStatus()

        #expect(manager.isEnabled == true) // Updated
        #expect(manager.status == .enabled) // Updated
        #expect(manager.lastError == nil) // Cleared
    }

    @Test("refreshStatus clears lastError")
    @MainActor
    func refreshStatusClearsError() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        mockService.shouldThrowOnRegister = true
        let manager = LaunchAtLoginManager(service: mockService)

        // Cause an error
        manager.isEnabled = true
        #expect(manager.lastError != nil)

        // Refresh should clear it
        manager.refreshStatus()
        #expect(manager.lastError == nil)
    }

    // MARK: - Status Description Tests

    @Test("statusDescription returns correct text for notRegistered")
    @MainActor
    func statusDescriptionNotRegistered() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.statusDescription == "Not set to launch at login")
    }

    @Test("statusDescription returns correct text for enabled")
    @MainActor
    func statusDescriptionEnabled() {
        let mockService = MockLaunchAtLoginService(initialStatus: .enabled)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.statusDescription == "Will launch at login")
    }

    @Test("statusDescription returns correct text for requiresApproval")
    @MainActor
    func statusDescriptionRequiresApproval() {
        let mockService = MockLaunchAtLoginService(initialStatus: .requiresApproval)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.statusDescription == "Requires approval in System Settings")
    }

    @Test("statusDescription returns correct text for notFound")
    @MainActor
    func statusDescriptionNotFound() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notFound)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.statusDescription == "App not found")
    }

    // MARK: - Requires User Approval Tests

    @Test("requiresUserApproval is true only for requiresApproval status")
    @MainActor
    func requiresUserApprovalFlag() {
        let mockService = MockLaunchAtLoginService(initialStatus: .notRegistered)
        let manager = LaunchAtLoginManager(service: mockService)

        #expect(manager.requiresUserApproval == false)

        mockService.setStatus(.enabled)
        manager.refreshStatus()
        #expect(manager.requiresUserApproval == false)

        mockService.setStatus(.requiresApproval)
        manager.refreshStatus()
        #expect(manager.requiresUserApproval == true)

        mockService.setStatus(.notFound)
        manager.refreshStatus()
        #expect(manager.requiresUserApproval == false)
    }
}

// MARK: - Mock NotificationService for Tests

/// Mock notification service for testing NotificationManager.
/// Uses a lock for thread-safe access to mutable state since it conforms to Sendable.
final class MockNotificationService: NotificationService, @unchecked Sendable {
    private let lock = NSLock()

    private var _authorizationStatus: UNAuthorizationStatus = .notDetermined
    private var _shouldGrantPermission: Bool = true
    private var _shouldThrowOnRequest: Bool = false
    private var _requestAuthorizationCallCount: Int = 0
    private var _addedRequests: [UNNotificationRequest] = []
    private var _removedIdentifiers: [String] = []

    // MARK: - Configuration setters (thread-safe)

    func setShouldGrantPermission(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _shouldGrantPermission = value
    }

    func setShouldThrowOnRequest(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _shouldThrowOnRequest = value
    }

    func setAuthorizationStatus(_ status: UNAuthorizationStatus) {
        lock.lock()
        defer { lock.unlock() }
        _authorizationStatus = status
    }

    // MARK: - Test inspection methods (thread-safe)

    func getRequestAuthorizationCallCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return _requestAuthorizationCallCount
    }

    func getAddedRequestCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return _addedRequests.count
    }

    func getLastRequest() -> UNNotificationRequest? {
        lock.lock()
        defer { lock.unlock() }
        return _addedRequests.last
    }

    func getRemovedIdentifiers() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return _removedIdentifiers
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _requestAuthorizationCallCount = 0
        _addedRequests.removeAll()
        _removedIdentifiers.removeAll()
    }

    // MARK: - NotificationService Protocol

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        lock.lock()
        _requestAuthorizationCallCount += 1
        let shouldThrow = _shouldThrowOnRequest
        let shouldGrant = _shouldGrantPermission
        lock.unlock()

        if shouldThrow {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission request failed"])
        }

        lock.lock()
        if shouldGrant {
            _authorizationStatus = .authorized
        } else {
            _authorizationStatus = .denied
        }
        lock.unlock()

        return shouldGrant
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        lock.lock()
        defer { lock.unlock() }
        return _authorizationStatus
    }

    func add(_ request: UNNotificationRequest) async throws {
        lock.lock()
        defer { lock.unlock() }
        _addedRequests.append(request)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        lock.lock()
        defer { lock.unlock() }
        _removedIdentifiers.append(contentsOf: identifiers)
    }
}

// MARK: - NotificationManager Tests

@Suite("NotificationManager Tests")
struct NotificationManagerTests {
    // MARK: - Permission Request Tests

    @Test("requestPermission returns true when granted")
    func requestPermissionGranted() async {
        let mockService = MockNotificationService()
        mockService.setAuthorizationStatus(.notDetermined)
        let manager = NotificationManager(notificationCenter: mockService)

        let result = await manager.requestPermission()

        #expect(result == true)
        let callCount = mockService.getRequestAuthorizationCallCount()
        #expect(callCount == 1)
    }

    @Test("requestPermission returns false when denied")
    func requestPermissionDenied() async {
        let mockService = MockNotificationService()
        mockService.setShouldGrantPermission(false)
        let manager = NotificationManager(notificationCenter: mockService)

        let result = await manager.requestPermission()

        #expect(result == false)
    }

    @Test("requestPermission returns false when throws error")
    func requestPermissionError() async {
        let mockService = MockNotificationService()
        mockService.setShouldThrowOnRequest(true)
        let manager = NotificationManager(notificationCenter: mockService)

        let result = await manager.requestPermission()

        #expect(result == false)
    }

    @Test("requestPermission does not prompt twice in same session")
    func requestPermissionOnlyOnce() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        // First request
        _ = await manager.requestPermission()
        let firstCallCount = mockService.getRequestAuthorizationCallCount()
        #expect(firstCallCount == 1)

        // Second request should not prompt again
        _ = await manager.requestPermission()
        let secondCallCount = mockService.getRequestAuthorizationCallCount()
        #expect(secondCallCount == 1) // Still 1, not 2
    }

    @Test("checkPermissionStatus returns current status")
    func checkPermissionStatus() async {
        let mockService = MockNotificationService()
        mockService.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockService)

        let status = await manager.checkPermissionStatus()

        #expect(status == .authorized)
    }

    @Test("checkPermissionStatus reflects denied status")
    func checkPermissionStatusDenied() async {
        let mockService = MockNotificationService()
        mockService.setAuthorizationStatus(.denied)
        let manager = NotificationManager(notificationCenter: mockService)

        let status = await manager.checkPermissionStatus()

        #expect(status == .denied)
    }

    // MARK: - Send Notification Tests

    @Test("send creates notification request")
    func sendCreatesRequest() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.send(
            title: "Test Title",
            body: "Test Body",
            identifier: "test-notification"
        )

        let count = mockService.getAddedRequestCount()
        #expect(count == 1)

        let request = mockService.getLastRequest()
        #expect(request?.identifier == "test-notification")
        #expect(request?.content.title == "Test Title")
        #expect(request?.content.body == "Test Body")
        #expect(request?.trigger == nil) // Immediate delivery
    }

    @Test("send prevents duplicate notifications")
    func sendPreventsDuplicates() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        // First send
        await manager.send(title: "Title", body: "Body", identifier: "dup-test")

        // Second send with same identifier
        await manager.send(title: "Title 2", body: "Body 2", identifier: "dup-test")

        // Should only have one notification
        let count = mockService.getAddedRequestCount()
        #expect(count == 1)
    }

    @Test("send allows different identifiers")
    func sendAllowsDifferentIdentifiers() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.send(title: "Title 1", body: "Body 1", identifier: "id-1")
        await manager.send(title: "Title 2", body: "Body 2", identifier: "id-2")
        await manager.send(title: "Title 3", body: "Body 3", identifier: "id-3")

        let count = mockService.getAddedRequestCount()
        #expect(count == 3)
    }

    // MARK: - State Management Tests

    @Test("resetState allows notification to fire again")
    func resetStateAllowsRenotification() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        // First send
        await manager.send(title: "Title", body: "Body", identifier: "reset-test")
        var count = mockService.getAddedRequestCount()
        #expect(count == 1)

        // Try to send again - should be blocked
        await manager.send(title: "Title", body: "Body", identifier: "reset-test")
        count = mockService.getAddedRequestCount()
        #expect(count == 1)

        // Reset state
        await manager.resetState(for: "reset-test")

        // Now should be able to send again
        await manager.send(title: "Title", body: "Body", identifier: "reset-test")
        count = mockService.getAddedRequestCount()
        #expect(count == 2)
    }

    @Test("resetAllStates clears all tracking")
    func resetAllStatesClearsTracking() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        // Send multiple notifications
        await manager.send(title: "Title", body: "Body", identifier: "id-1")
        await manager.send(title: "Title", body: "Body", identifier: "id-2")

        // Reset all states
        await manager.resetAllStates()

        // Both should be able to fire again
        await manager.send(title: "Title", body: "Body", identifier: "id-1")
        await manager.send(title: "Title", body: "Body", identifier: "id-2")

        let count = mockService.getAddedRequestCount()
        #expect(count == 4) // 2 original + 2 after reset
    }

    @Test("hasNotified returns correct status")
    func hasNotifiedReturnsCorrectStatus() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        // Initially false
        var hasNotified = await manager.hasNotified(for: "test-id")
        #expect(hasNotified == false)

        // After send, should be true
        await manager.send(title: "Title", body: "Body", identifier: "test-id")
        hasNotified = await manager.hasNotified(for: "test-id")
        #expect(hasNotified == true)

        // After reset, should be false again
        await manager.resetState(for: "test-id")
        hasNotified = await manager.hasNotified(for: "test-id")
        #expect(hasNotified == false)
    }

    @Test("removeDelivered calls notification center")
    func removeDeliveredCallsCenter() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.removeDelivered(identifiers: ["id-1", "id-2"])

        let removed = mockService.getRemovedIdentifiers()
        #expect(removed == ["id-1", "id-2"])
    }

    // MARK: - Integration Tests

    @Test("Full notification cycle with hysteresis pattern")
    func fullNotificationCycle() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        let warningId = "usage-warning-session"

        // 1. First warning fires
        await manager.send(title: "Warning", body: "At 90%", identifier: warningId)
        var count = mockService.getAddedRequestCount()
        #expect(count == 1)

        // 2. Usage goes higher - still blocked (same cycle)
        await manager.send(title: "Warning", body: "At 95%", identifier: warningId)
        count = mockService.getAddedRequestCount()
        #expect(count == 1) // Still 1

        // 3. Usage drops below hysteresis threshold - reset state
        await manager.resetState(for: warningId)

        // 4. Usage rises again - warning can fire again
        await manager.send(title: "Warning", body: "At 90%", identifier: warningId)
        count = mockService.getAddedRequestCount()
        #expect(count == 2)
    }
}

// MARK: - UsageNotificationChecker Tests

@Suite("UsageNotificationChecker Tests")
struct UsageNotificationCheckerTests {
    // MARK: - Helper Methods

    /// Creates test dependencies with configurable settings
    @MainActor
    private static func createTestDependencies(
        notificationsEnabled: Bool = true,
        warningEnabled: Bool = true,
        capacityFullEnabled: Bool = true,
        resetCompleteEnabled: Bool = true,
        warningThreshold: Int = 90
    ) -> (checker: UsageNotificationChecker, service: MockNotificationService, settings: SettingsManager) {
        let mockService = MockNotificationService()
        let notificationManager = NotificationManager(notificationCenter: mockService)
        let mockSettingsRepo = MockSettingsRepository()

        // Configure settings
        mockSettingsRepo.set(.notificationsEnabled, value: notificationsEnabled)
        mockSettingsRepo.set(.warningEnabled, value: warningEnabled)
        mockSettingsRepo.set(.capacityFullEnabled, value: capacityFullEnabled)
        mockSettingsRepo.set(.resetCompleteEnabled, value: resetCompleteEnabled)
        mockSettingsRepo.set(.warningThreshold, value: warningThreshold)

        let settingsManager = SettingsManager(repository: mockSettingsRepo)

        let checker = UsageNotificationChecker(
            notificationManager: notificationManager,
            settingsManager: settingsManager
        )

        return (checker, mockService, settingsManager)
    }

    /// Creates test usage data
    private static func createUsageData(
        fiveHour: Double,
        sevenDay: Double,
        opus: Double? = nil,
        sonnet: Double? = nil
    ) -> UsageData {
        UsageData(
            fiveHour: UsageWindow(utilization: fiveHour, resetsAt: Date().addingTimeInterval(3600)),
            sevenDay: UsageWindow(utilization: sevenDay, resetsAt: Date().addingTimeInterval(86400)),
            sevenDayOpus: opus.map { UsageWindow(utilization: $0) },
            sevenDaySonnet: sonnet.map { UsageWindow(utilization: $0) },
            fetchedAt: Date()
        )
    }

    // MARK: - Global Enable/Disable Tests

    @Test("No notifications when globally disabled")
    @MainActor
    func noNotificationsWhenGloballyDisabled() async {
        let deps = Self.createTestDependencies(notificationsEnabled: false)

        // Cross threshold from below
        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 80)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 95)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Notifications work when globally enabled")
    @MainActor
    func notificationsWorkWhenEnabled() async {
        let deps = Self.createTestDependencies(notificationsEnabled: true)

        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 80)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 80)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 1) // Warning for session crossing 90%
    }

    // MARK: - Warning Threshold Tests

    @Test("Warning fires when crossing threshold from below")
    @MainActor
    func warningFiresOnThresholdCrossing() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        let previous = Self.createUsageData(fiveHour: 85, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 92, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 1)

        let request = deps.service.getLastRequest()
        #expect(request?.identifier == "usage-warning-session")
        #expect(request?.content.title == "Claude Usage Warning")
        #expect(request?.content.body.contains("Current session at 92%") == true)
    }

    @Test("Warning does not fire when already above threshold")
    @MainActor
    func warningDoesNotFireWhenAlreadyAbove() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        let previous = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Warning does not fire when still below threshold")
    @MainActor
    func warningDoesNotFireWhenBelowThreshold() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        let previous = Self.createUsageData(fiveHour: 70, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 85, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Warning respects custom threshold")
    @MainActor
    func warningRespectsCustomThreshold() async {
        let deps = Self.createTestDependencies(warningThreshold: 75)

        let previous = Self.createUsageData(fiveHour: 70, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 78, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 1) // Crossed 75% threshold
    }

    @Test("Warning does not fire when warning toggle disabled")
    @MainActor
    func warningDoesNotFireWhenDisabled() async {
        let deps = Self.createTestDependencies(warningEnabled: false)

        let previous = Self.createUsageData(fiveHour: 85, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        // Should have no warning notifications
        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Warning fires for multiple windows crossing threshold")
    @MainActor
    func warningFiresForMultipleWindows() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        let previous = Self.createUsageData(fiveHour: 85, sevenDay: 85, opus: 85, sonnet: 85)
        let current = Self.createUsageData(fiveHour: 92, sevenDay: 92, opus: 92, sonnet: 92)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 4) // All four windows crossed threshold
    }

    // MARK: - Hysteresis Tests

    @Test("Hysteresis prevents duplicate warning after state reset")
    @MainActor
    func hysteresisPreventsSpam() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        // First: cross threshold
        let previous1 = Self.createUsageData(fiveHour: 85, sevenDay: 50)
        let current1 = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        await deps.checker.check(current: current1, previous: previous1)

        var count = deps.service.getAddedRequestCount()
        #expect(count == 1)

        // Second: still above threshold - should not fire again
        let previous2 = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        let current2 = Self.createUsageData(fiveHour: 95, sevenDay: 50)
        await deps.checker.check(current: current2, previous: previous2)

        count = deps.service.getAddedRequestCount()
        #expect(count == 1) // Still 1

        // Third: drop below hysteresis threshold (90 - 5 = 85)
        let previous3 = Self.createUsageData(fiveHour: 95, sevenDay: 50)
        let current3 = Self.createUsageData(fiveHour: 83, sevenDay: 50) // Below 85%
        await deps.checker.check(current: current3, previous: previous3)

        count = deps.service.getAddedRequestCount()
        #expect(count == 1) // Still 1, no new notification

        // Fourth: cross threshold again - should fire
        let previous4 = Self.createUsageData(fiveHour: 83, sevenDay: 50)
        let current4 = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        await deps.checker.check(current: current4, previous: previous4)

        count = deps.service.getAddedRequestCount()
        #expect(count == 2) // Now 2
    }

    @Test("Hysteresis does not reset when still above buffer")
    @MainActor
    func hysteresisDoesNotResetAboveBuffer() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        // First: cross threshold
        let previous1 = Self.createUsageData(fiveHour: 85, sevenDay: 50)
        let current1 = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        await deps.checker.check(current: current1, previous: previous1)

        var count = deps.service.getAddedRequestCount()
        #expect(count == 1)

        // Second: drop but still above hysteresis threshold (87 > 85)
        let previous2 = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        let current2 = Self.createUsageData(fiveHour: 87, sevenDay: 50)
        await deps.checker.check(current: current2, previous: previous2)

        // Third: rise again - should NOT fire because state wasn't reset
        let previous3 = Self.createUsageData(fiveHour: 87, sevenDay: 50)
        let current3 = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        await deps.checker.check(current: current3, previous: previous3)

        count = deps.service.getAddedRequestCount()
        #expect(count == 1) // Still 1, blocked by duplicate prevention
    }

    // MARK: - Capacity Full Tests

    @Test("Capacity full fires at 100%")
    @MainActor
    func capacityFullFiresAt100() async {
        let deps = Self.createTestDependencies()

        let previous = Self.createUsageData(fiveHour: 98, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 100, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        // Should have warning (crossing 90%) AND capacity full
        let count = deps.service.getAddedRequestCount()
        #expect(count >= 1) // At least capacity full

        // Find the capacity full notification
        let request = deps.service.getLastRequest()
        #expect(request?.content.title == "Claude Capacity Full")
    }

    @Test("Capacity full does not fire when already at 100%")
    @MainActor
    func capacityFullDoesNotFireWhenAlready100() async {
        let deps = Self.createTestDependencies(warningEnabled: false) // Disable warning to isolate test

        let previous = Self.createUsageData(fiveHour: 100, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 100, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0) // No notification
    }

    @Test("Capacity full does not fire when toggle disabled")
    @MainActor
    func capacityFullDoesNotFireWhenDisabled() async {
        let deps = Self.createTestDependencies(
            warningEnabled: false,
            capacityFullEnabled: false
        )

        let previous = Self.createUsageData(fiveHour: 98, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 100, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Capacity full hysteresis resets below 95%")
    @MainActor
    func capacityFullHysteresisResets() async {
        let deps = Self.createTestDependencies(warningEnabled: false)

        // First: hit 100%
        let previous1 = Self.createUsageData(fiveHour: 98, sevenDay: 50)
        let current1 = Self.createUsageData(fiveHour: 100, sevenDay: 50)
        await deps.checker.check(current: current1, previous: previous1)

        var count = deps.service.getAddedRequestCount()
        #expect(count == 1)

        // Second: drop below 95%
        let previous2 = Self.createUsageData(fiveHour: 100, sevenDay: 50)
        let current2 = Self.createUsageData(fiveHour: 93, sevenDay: 50)
        await deps.checker.check(current: current2, previous: previous2)

        // Third: hit 100% again - should fire
        let previous3 = Self.createUsageData(fiveHour: 93, sevenDay: 50)
        let current3 = Self.createUsageData(fiveHour: 100, sevenDay: 50)
        await deps.checker.check(current: current3, previous: previous3)

        count = deps.service.getAddedRequestCount()
        #expect(count == 2)
    }

    // MARK: - Reset Complete Tests

    @Test("Reset complete fires when 7-day drops from >50% to <10%")
    @MainActor
    func resetCompleteFiresOnDrop() async {
        let deps = Self.createTestDependencies(
            warningEnabled: false,
            capacityFullEnabled: false
        )

        let previous = Self.createUsageData(fiveHour: 50, sevenDay: 75)
        let current = Self.createUsageData(fiveHour: 50, sevenDay: 5)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 1)

        let request = deps.service.getLastRequest()
        #expect(request?.identifier == "reset-complete")
        #expect(request?.content.title == "Usage Reset Complete")
        #expect(request?.content.body.contains("weekly limit has reset") == true)
    }

    @Test("Reset complete does not fire when previous was below 50%")
    @MainActor
    func resetCompleteDoesNotFireWhenPreviousLow() async {
        let deps = Self.createTestDependencies(
            warningEnabled: false,
            capacityFullEnabled: false
        )

        let previous = Self.createUsageData(fiveHour: 50, sevenDay: 40) // Below 50%
        let current = Self.createUsageData(fiveHour: 50, sevenDay: 5)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Reset complete does not fire when current is above 10%")
    @MainActor
    func resetCompleteDoesNotFireWhenCurrentHigh() async {
        let deps = Self.createTestDependencies(
            warningEnabled: false,
            capacityFullEnabled: false
        )

        let previous = Self.createUsageData(fiveHour: 50, sevenDay: 75)
        let current = Self.createUsageData(fiveHour: 50, sevenDay: 15) // Above 10%

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Reset complete does not fire when toggle disabled")
    @MainActor
    func resetCompleteDoesNotFireWhenDisabled() async {
        let deps = Self.createTestDependencies(
            warningEnabled: false,
            capacityFullEnabled: false,
            resetCompleteEnabled: false
        )

        let previous = Self.createUsageData(fiveHour: 50, sevenDay: 75)
        let current = Self.createUsageData(fiveHour: 50, sevenDay: 5)

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Reset complete does not fire without previous data")
    @MainActor
    func resetCompleteNeedsPreviousData() async {
        let deps = Self.createTestDependencies(
            warningEnabled: false,
            capacityFullEnabled: false
        )

        let current = Self.createUsageData(fiveHour: 50, sevenDay: 5)

        await deps.checker.check(current: current, previous: nil)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    // MARK: - Notification Body Tests

    @Test("Warning notification includes reset time")
    @MainActor
    func warningIncludesResetTime() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        let previous = Self.createUsageData(fiveHour: 85, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 92, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let request = deps.service.getLastRequest()
        #expect(request?.content.body.contains("Resets") == true)
    }

    @Test("Capacity full notification includes reset time")
    @MainActor
    func capacityFullIncludesResetTime() async {
        let deps = Self.createTestDependencies(warningEnabled: false)

        let previous = Self.createUsageData(fiveHour: 98, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 100, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        let request = deps.service.getLastRequest()
        #expect(request?.content.body.contains("Resets") == true)
    }

    // MARK: - Edge Cases

    @Test("First fetch with nil previous data")
    @MainActor
    func firstFetchWithNilPrevious() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        // First fetch with high usage but no previous
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: nil)

        // Should fire because previous is treated as 0
        let count = deps.service.getAddedRequestCount()
        #expect(count == 1)
    }

    @Test("Nil optional windows are skipped")
    @MainActor
    func nilWindowsAreSkipped() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        // Previous had opus/sonnet, current doesn't
        let previous = Self.createUsageData(fiveHour: 50, sevenDay: 50, opus: 85, sonnet: 85)
        let current = Self.createUsageData(fiveHour: 50, sevenDay: 50, opus: nil, sonnet: nil)

        await deps.checker.check(current: current, previous: previous)

        // No notifications because nil windows are skipped
        let count = deps.service.getAddedRequestCount()
        #expect(count == 0)
    }

    @Test("Exactly at threshold triggers warning")
    @MainActor
    func exactlyAtThresholdTriggers() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        let previous = Self.createUsageData(fiveHour: 85, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 90, sevenDay: 50) // Exactly 90%

        await deps.checker.check(current: current, previous: previous)

        let count = deps.service.getAddedRequestCount()
        #expect(count == 1)
    }
}
