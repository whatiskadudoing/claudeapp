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
