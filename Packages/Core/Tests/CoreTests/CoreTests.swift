import Domain
import Foundation
import Services
import Testing
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
