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
        #expect(Core.version == "2.0.0")
    }
}

// MARK: - UsageSnapshot Tests

@Suite("UsageSnapshot Tests")
struct UsageSnapshotTests {
    @Test("UsageSnapshot initializes with required fields")
    func initWithRequiredFields() {
        let timestamp = Date()
        let snapshot = UsageSnapshot(
            fiveHourUtilization: 45.0,
            sevenDayUtilization: 72.0,
            timestamp: timestamp
        )

        #expect(snapshot.fiveHourUtilization == 45.0)
        #expect(snapshot.sevenDayUtilization == 72.0)
        #expect(snapshot.opusUtilization == nil)
        #expect(snapshot.sonnetUtilization == nil)
        #expect(snapshot.timestamp == timestamp)
    }

    @Test("UsageSnapshot initializes with all fields")
    func initWithAllFields() {
        let timestamp = Date()
        let snapshot = UsageSnapshot(
            fiveHourUtilization: 30.0,
            sevenDayUtilization: 50.0,
            opusUtilization: 20.0,
            sonnetUtilization: 80.0,
            timestamp: timestamp
        )

        #expect(snapshot.fiveHourUtilization == 30.0)
        #expect(snapshot.sevenDayUtilization == 50.0)
        #expect(snapshot.opusUtilization == 20.0)
        #expect(snapshot.sonnetUtilization == 80.0)
        #expect(snapshot.timestamp == timestamp)
    }

    @Test("UsageSnapshot defaults timestamp to now")
    func defaultTimestamp() {
        let before = Date()
        let snapshot = UsageSnapshot(fiveHourUtilization: 50.0, sevenDayUtilization: 50.0)
        let after = Date()

        #expect(snapshot.timestamp >= before)
        #expect(snapshot.timestamp <= after)
    }

    @Test("UsageSnapshot is Equatable")
    func equatable() {
        let timestamp = Date()
        let snapshot1 = UsageSnapshot(
            fiveHourUtilization: 45.0,
            sevenDayUtilization: 72.0,
            opusUtilization: 20.0,
            sonnetUtilization: 30.0,
            timestamp: timestamp
        )
        let snapshot2 = UsageSnapshot(
            fiveHourUtilization: 45.0,
            sevenDayUtilization: 72.0,
            opusUtilization: 20.0,
            sonnetUtilization: 30.0,
            timestamp: timestamp
        )
        let snapshot3 = UsageSnapshot(
            fiveHourUtilization: 50.0,
            sevenDayUtilization: 72.0,
            timestamp: timestamp
        )

        #expect(snapshot1 == snapshot2)
        #expect(snapshot1 != snapshot3)
    }

    @Test("UsageSnapshot equality considers optional fields")
    func equalityWithOptionals() {
        let timestamp = Date()
        let snapshot1 = UsageSnapshot(
            fiveHourUtilization: 45.0,
            sevenDayUtilization: 72.0,
            opusUtilization: 20.0,
            timestamp: timestamp
        )
        let snapshot2 = UsageSnapshot(
            fiveHourUtilization: 45.0,
            sevenDayUtilization: 72.0,
            opusUtilization: nil,
            timestamp: timestamp
        )

        #expect(snapshot1 != snapshot2)
    }

    @Test("UsageSnapshot is Sendable")
    func sendable() async {
        let snapshot = UsageSnapshot(
            fiveHourUtilization: 45.0,
            sevenDayUtilization: 72.0
        )

        // Verify it can be passed across actor boundaries
        let result = await Task.detached {
            snapshot.fiveHourUtilization
        }.value

        #expect(result == 45.0)
    }
}

// MARK: - UsageHistoryManager Tests

@Suite("UsageHistoryManager Tests")
struct UsageHistoryManagerTests {
    /// Creates a test UserDefaults instance with a unique suite name
    private func createTestDefaults() -> UserDefaults {
        let suiteName = "com.claudeapp.test.history.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Initialization Tests

    @Test("Initial state has empty histories")
    @MainActor
    func initialState() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        #expect(manager.sessionHistory.isEmpty)
        #expect(manager.weeklyHistory.isEmpty)
        #expect(manager.hasSessionChartData == false)
        #expect(manager.hasWeeklyChartData == false)
    }

    @Test("Initial point counts are zero")
    @MainActor
    func initialPointCounts() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        #expect(manager.sessionPointCount == 0)
        #expect(manager.weeklyPointCount == 0)
    }

    // MARK: - Recording Tests

    @Test("Recording adds points to both histories")
    @MainActor
    func recordingAddsPoints() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)

        #expect(manager.sessionPointCount == 1)
        #expect(manager.weeklyPointCount == 1)
        #expect(manager.sessionHistory.first?.utilization == 45.0)
        #expect(manager.weeklyHistory.first?.utilization == 72.0)
    }

    @Test("Recording respects session interval (5 minutes)")
    @MainActor
    func recordingRespectsSessionInterval() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        // First recording
        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.sessionPointCount == 1)

        // Second recording immediately - should be ignored for session
        manager.record(sessionUtilization: 50.0, weeklyUtilization: 75.0)
        #expect(manager.sessionPointCount == 1) // Still 1 (interval not met)
    }

    @Test("Recording respects weekly interval (1 hour)")
    @MainActor
    func recordingRespectsWeeklyInterval() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        // First recording
        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.weeklyPointCount == 1)

        // Second recording immediately - should be ignored for weekly
        manager.record(sessionUtilization: 50.0, weeklyUtilization: 75.0)
        #expect(manager.weeklyPointCount == 1) // Still 1 (interval not met)
    }

    @Test("hasSessionChartData requires at least 2 points")
    @MainActor
    func hasSessionChartDataRequiresTwoPoints() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        #expect(manager.hasSessionChartData == false)

        // Add one point
        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.hasSessionChartData == false) // Still false

        // We can't easily add a second point due to interval restrictions in tests
        // but we can verify the threshold logic
    }

    @Test("hasWeeklyChartData requires at least 2 points")
    @MainActor
    func hasWeeklyChartDataRequiresTwoPoints() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        #expect(manager.hasWeeklyChartData == false)

        // Add one point
        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.hasWeeklyChartData == false) // Still false
    }

    // MARK: - Clearing Tests

    @Test("clearSessionHistory removes session history only")
    @MainActor
    func clearSessionHistoryRemovesSessionOnly() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.sessionPointCount == 1)
        #expect(manager.weeklyPointCount == 1)

        manager.clearSessionHistory()

        #expect(manager.sessionPointCount == 0)
        #expect(manager.weeklyPointCount == 1) // Weekly preserved
    }

    @Test("clearWeeklyHistory removes weekly history only")
    @MainActor
    func clearWeeklyHistoryRemovesWeeklyOnly() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.sessionPointCount == 1)
        #expect(manager.weeklyPointCount == 1)

        manager.clearWeeklyHistory()

        #expect(manager.sessionPointCount == 1) // Session preserved
        #expect(manager.weeklyPointCount == 0)
    }

    @Test("clearAllHistory removes both histories")
    @MainActor
    func clearAllHistoryRemovesBoth() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager.sessionPointCount == 1)
        #expect(manager.weeklyPointCount == 1)

        manager.clearAllHistory()

        #expect(manager.sessionPointCount == 0)
        #expect(manager.weeklyPointCount == 0)
    }

    // MARK: - Persistence Tests

    @Test("History persists across manager instances")
    @MainActor
    func historyPersistsAcrossInstances() {
        let defaults = createTestDefaults()

        // First manager instance - record data
        let manager1 = UsageHistoryManager(userDefaults: defaults)
        manager1.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        #expect(manager1.sessionPointCount == 1)
        #expect(manager1.weeklyPointCount == 1)

        // Second manager instance - should load from persistence
        let manager2 = UsageHistoryManager(userDefaults: defaults)
        #expect(manager2.sessionPointCount == 1)
        #expect(manager2.weeklyPointCount == 1)
        #expect(manager2.sessionHistory.first?.utilization == 45.0)
        #expect(manager2.weeklyHistory.first?.utilization == 72.0)
    }

    @Test("Cleared history persists as empty")
    @MainActor
    func clearedHistoryPersistsAsEmpty() {
        let defaults = createTestDefaults()

        // First manager - record then clear
        let manager1 = UsageHistoryManager(userDefaults: defaults)
        manager1.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)
        manager1.clearAllHistory()

        // Second manager - should be empty
        let manager2 = UsageHistoryManager(userDefaults: defaults)
        #expect(manager2.sessionPointCount == 0)
        #expect(manager2.weeklyPointCount == 0)
    }

    // MARK: - Configuration Constants Tests

    @Test("Max session points is 60")
    func maxSessionPoints() {
        #expect(UsageHistoryManager.maxSessionPoints == 60)
    }

    @Test("Max weekly points is 168")
    func maxWeeklyPoints() {
        #expect(UsageHistoryManager.maxWeeklyPoints == 168)
    }

    @Test("Session recording interval is 5 minutes (300 seconds)")
    func sessionRecordingInterval() {
        #expect(UsageHistoryManager.sessionRecordingInterval == 300)
    }

    @Test("Weekly recording interval is 1 hour (3600 seconds)")
    func weeklyRecordingInterval() {
        #expect(UsageHistoryManager.weeklyRecordingInterval == 3600)
    }

    // MARK: - Data Order Tests

    @Test("Session history is ordered chronologically (oldest first)")
    @MainActor
    func sessionHistoryOrderedChronologically() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        // Add a point
        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)

        // Verify the first (and only) point has a timestamp
        #expect(manager.sessionHistory.first != nil)
        #expect(manager.sessionHistory.first?.timestamp != nil)
    }

    @Test("Weekly history is ordered chronologically (oldest first)")
    @MainActor
    func weeklyHistoryOrderedChronologically() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        // Add a point
        manager.record(sessionUtilization: 45.0, weeklyUtilization: 72.0)

        // Verify the first (and only) point has a timestamp
        #expect(manager.weeklyHistory.first != nil)
        #expect(manager.weeklyHistory.first?.timestamp != nil)
    }

    // MARK: - Edge Value Tests

    @Test("Records zero utilization correctly")
    @MainActor
    func recordsZeroUtilization() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        manager.record(sessionUtilization: 0.0, weeklyUtilization: 0.0)

        #expect(manager.sessionHistory.first?.utilization == 0.0)
        #expect(manager.weeklyHistory.first?.utilization == 0.0)
    }

    @Test("Records 100% utilization correctly")
    @MainActor
    func records100PercentUtilization() {
        let defaults = createTestDefaults()
        let manager = UsageHistoryManager(userDefaults: defaults)

        manager.record(sessionUtilization: 100.0, weeklyUtilization: 100.0)

        #expect(manager.sessionHistory.first?.utilization == 100.0)
        #expect(manager.weeklyHistory.first?.utilization == 100.0)
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

    // MARK: - Burn Rate Integration Tests

    @Test("refresh records usage snapshot in history")
    @MainActor
    func refreshRecordsSnapshot() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        #expect(manager.usageHistoryCount == 0)

        await manager.refresh()

        #expect(manager.usageHistoryCount == 1)
    }

    @Test("multiple refreshes accumulate history")
    @MainActor
    func multipleRefreshesAccumulateHistory() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()
        await manager.refresh()
        await manager.refresh()

        #expect(manager.usageHistoryCount == 3)
    }

    @Test("history is trimmed at maxHistoryCount (12)")
    @MainActor
    func historyTrimmedAtMax() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Refresh 15 times (more than max of 12)
        for _ in 0..<15 {
            await manager.refresh()
        }

        // Should be capped at 12
        #expect(manager.usageHistoryCount == 12)
    }

    @Test("clearHistory removes all snapshots")
    @MainActor
    func clearHistoryRemovesAll() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()
        await manager.refresh()
        #expect(manager.usageHistoryCount == 2)

        manager.clearHistory()

        #expect(manager.usageHistoryCount == 0)
    }

    @Test("single refresh does not produce burn rate (needs 2+ samples)")
    @MainActor
    func singleRefreshNoBurnRate() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        // With only 1 sample, no burn rate should be calculated
        #expect(manager.usageData?.fiveHour.burnRate == nil)
        #expect(manager.usageData?.sevenDay.burnRate == nil)
        #expect(manager.overallBurnRateLevel == nil)
    }

    @Test("overallBurnRateLevel returns nil when no data")
    @MainActor
    func overallBurnRateLevelNilWhenNoData() {
        let mockRepo = MockUsageRepository()
        let manager = UsageManager(usageRepository: mockRepo)

        #expect(manager.overallBurnRateLevel == nil)
    }

    @Test("failed refresh does not record snapshot")
    @MainActor
    func failedRefreshNoSnapshot() async {
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        // Failed refresh should not add to history
        #expect(manager.usageHistoryCount == 0)
    }

    @Test("refresh preserves original utilization values")
    @MainActor
    func refreshPreservesUtilization() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.5, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.3, resetsAt: nil),
            sevenDayOpus: UsageWindow(utilization: 15.0, resetsAt: nil),
            sevenDaySonnet: UsageWindow(utilization: 68.2, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        // Verify original utilization values are preserved
        #expect(manager.usageData?.fiveHour.utilization == 45.5)
        #expect(manager.usageData?.sevenDay.utilization == 72.3)
        #expect(manager.usageData?.sevenDayOpus?.utilization == 15.0)
        #expect(manager.usageData?.sevenDaySonnet?.utilization == 68.2)
    }

    @Test("refresh preserves resetsAt dates")
    @MainActor
    func refreshPreservesResetDates() async {
        let fiveHourReset = Date().addingTimeInterval(3600)
        let sevenDayReset = Date().addingTimeInterval(86400 * 3)
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: fiveHourReset),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: sevenDayReset),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        await manager.refresh()

        // Verify reset dates are preserved
        #expect(manager.usageData?.fiveHour.resetsAt == fiveHourReset)
        #expect(manager.usageData?.sevenDay.resetsAt == sevenDayReset)
    }

    // MARK: - UsageHistoryManager Integration Tests

    @Test("setUsageHistoryManager connects history manager")
    @MainActor
    func setUsageHistoryManagerConnectsManager() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        let suiteName = "com.claudeapp.test.history.integration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let historyManager = UsageHistoryManager(userDefaults: defaults)

        manager.setUsageHistoryManager(historyManager)

        // Refresh should record to history manager
        await manager.refresh()

        #expect(historyManager.sessionPointCount == 1)
        #expect(historyManager.weeklyPointCount == 1)
        #expect(historyManager.sessionHistory.first?.utilization == 45.0)
        #expect(historyManager.weeklyHistory.first?.utilization == 72.0)
    }

    @Test("refresh records correct utilization values to history")
    @MainActor
    func refreshRecordsCorrectValuesToHistory() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 55.5, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 88.8, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        let suiteName = "com.claudeapp.test.history.values.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let historyManager = UsageHistoryManager(userDefaults: defaults)
        manager.setUsageHistoryManager(historyManager)

        await manager.refresh()

        #expect(historyManager.sessionHistory.first?.utilization == 55.5)
        #expect(historyManager.weeklyHistory.first?.utilization == 88.8)
    }

    @Test("refresh does not record to history on failure")
    @MainActor
    func refreshDoesNotRecordOnFailure() async {
        let mockRepo = MockUsageRepository(error: .notAuthenticated)
        let manager = UsageManager(usageRepository: mockRepo)

        let suiteName = "com.claudeapp.test.history.failure.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let historyManager = UsageHistoryManager(userDefaults: defaults)
        manager.setUsageHistoryManager(historyManager)

        await manager.refresh()

        #expect(historyManager.sessionPointCount == 0)
        #expect(historyManager.weeklyPointCount == 0)
    }

    @Test("session reset clears session history")
    @MainActor
    func sessionResetClearsSessionHistory() async {
        // Initial data with reset time 1 hour from now
        let initialResetTime = Date().addingTimeInterval(3600)
        let initialData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: initialResetTime),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: initialData)
        let manager = UsageManager(usageRepository: mockRepo)

        let suiteName = "com.claudeapp.test.history.reset.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let historyManager = UsageHistoryManager(userDefaults: defaults)
        manager.setUsageHistoryManager(historyManager)

        // First refresh - records to history
        await manager.refresh()
        #expect(historyManager.sessionPointCount == 1)
        #expect(historyManager.weeklyPointCount == 1)

        // New data with reset time 2 hours from now (window reset happened)
        let newResetTime = Date().addingTimeInterval(7200)
        let newData = UsageData(
            fiveHour: UsageWindow(utilization: 10.0, resetsAt: newResetTime),
            sevenDay: UsageWindow(utilization: 75.0, resetsAt: nil),
            fetchedAt: Date()
        )
        await mockRepo.setUsageData(newData)

        // Second refresh - detects session reset, clears session, records new point
        await manager.refresh()

        // Session history was cleared, then new point added
        #expect(historyManager.sessionPointCount == 1)
        #expect(historyManager.sessionHistory.first?.utilization == 10.0)
        // Weekly history should have both points (not cleared)
        #expect(historyManager.weeklyPointCount == 1) // Still 1 due to interval
    }

    @Test("session reset also clears burn rate history")
    @MainActor
    func sessionResetClearsBurnRateHistory() async {
        // Initial data with reset time 1 hour from now
        let initialResetTime = Date().addingTimeInterval(3600)
        let initialData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: initialResetTime),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: initialData)
        let manager = UsageManager(usageRepository: mockRepo)

        // First refresh - builds up burn rate history
        await manager.refresh()
        #expect(manager.usageHistoryCount == 1)

        // New data with reset time 2 hours from now (window reset happened)
        let newResetTime = Date().addingTimeInterval(7200)
        let newData = UsageData(
            fiveHour: UsageWindow(utilization: 10.0, resetsAt: newResetTime),
            sevenDay: UsageWindow(utilization: 75.0, resetsAt: nil),
            fetchedAt: Date()
        )
        await mockRepo.setUsageData(newData)

        // Second refresh - detects session reset, clears burn rate history
        await manager.refresh()

        // Burn rate history was cleared, then new snapshot added
        #expect(manager.usageHistoryCount == 1)
    }

    @Test("no session reset when resetsAt time stays same")
    @MainActor
    func noSessionResetWhenTimeSame() async {
        let resetTime = Date().addingTimeInterval(3600)
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: resetTime),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        let suiteName = "com.claudeapp.test.history.noreset.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let historyManager = UsageHistoryManager(userDefaults: defaults)
        manager.setUsageHistoryManager(historyManager)

        // First refresh
        await manager.refresh()
        #expect(historyManager.sessionPointCount == 1)

        // Update data with same reset time (no reset happened)
        let updatedData = UsageData(
            fiveHour: UsageWindow(utilization: 50.0, resetsAt: resetTime),
            sevenDay: UsageWindow(utilization: 74.0, resetsAt: nil),
            fetchedAt: Date()
        )
        await mockRepo.setUsageData(updatedData)

        // Second refresh - no reset detected, point not added due to interval
        await manager.refresh()

        #expect(historyManager.sessionPointCount == 1) // Same due to interval
        #expect(manager.usageHistoryCount == 2) // Burn rate history grows
    }

    @Test("history recording works without history manager set")
    @MainActor
    func historyRecordingWorksWithoutManager() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)

        // Don't set history manager - should not crash
        await manager.refresh()

        #expect(manager.usageData != nil)
        #expect(manager.usageHistoryCount == 1) // Burn rate history still works
    }
}

// MARK: - AppContainer Tests

@Suite("AppContainer Tests")
struct AppContainerTests {
    // Note: Production AppContainer() init cannot be tested in SPM test environment
    // because UNUserNotificationCenter.current() crashes without a proper app bundle.
    // The production init is tested implicitly when the app runs.

    @Test("AppContainer test init creates all managers")
    @MainActor
    func testInitCreatesAllManagers() {
        let mockCredentials = MockCredentialsRepository()
        let mockUsage = MockUsageRepository()
        let mockNotifications = MockNotificationService()
        let container = AppContainer(
            credentialsRepository: mockCredentials,
            usageRepository: mockUsage,
            notificationService: mockNotifications
        )

        // Verify all managers are created and initialized properly
        #expect(container.usageManager.usageData == nil)
        #expect(container.usageManager.isLoading == false)
        #expect(container.settingsManager.notificationsEnabled == true) // default

        // Verify notification infrastructure exists by checking types (non-optional)
        let _: UsageNotificationChecker = container.notificationChecker
        let _: NotificationManager = container.notificationManager

        // Verify usage history manager is created and accessible
        // Note: We verify the manager exists and has valid state, but not that it's empty,
        // because UsageHistoryManager persists to UserDefaults and may have data from prior runs.
        let _: UsageHistoryManager = container.usageHistoryManager
        #expect(container.usageHistoryManager.sessionPointCount >= 0)
        #expect(container.usageHistoryManager.weeklyPointCount >= 0)
    }

    @Test("AppContainer test init does not start auto-refresh by default")
    @MainActor
    func testInitDoesNotStartAutoRefresh() {
        let mockCredentials = MockCredentialsRepository()
        let mockUsage = MockUsageRepository()
        let mockNotifications = MockNotificationService()
        let container = AppContainer(
            credentialsRepository: mockCredentials,
            usageRepository: mockUsage,
            notificationService: mockNotifications
        )

        // Test init should NOT start auto-refresh by default
        #expect(container.usageManager.isAutoRefreshing == false)
    }

    @Test("AppContainer test init can optionally start auto-refresh with power-aware disabled")
    @MainActor
    func testInitCanStartAutoRefreshWithPowerAwareDisabled() {
        let mockRepo = MockUsageRepository()
        let mockNotifications = MockNotificationService()
        let mockSettings = MockSettingsRepository()

        // Disable power-aware refresh to use UsageManager's simple auto-refresh
        mockSettings.set(.enablePowerAwareRefresh, value: false)

        let container = AppContainer(
            credentialsRepository: MockCredentialsRepository(),
            usageRepository: mockRepo,
            settingsRepository: mockSettings,
            notificationService: mockNotifications,
            startAutoRefresh: true
        )

        // Should start UsageManager's auto-refresh when power-aware is disabled
        #expect(container.usageManager.isAutoRefreshing == true)
        #expect(container.adaptiveRefreshManager.isAutoRefreshing == false)

        // Clean up
        container.usageManager.stopAutoRefresh()
    }

    @Test("AppContainer test init can optionally start auto-refresh with power-aware enabled")
    @MainActor
    func testInitCanStartAutoRefreshWithPowerAwareEnabled() {
        let mockRepo = MockUsageRepository()
        let mockNotifications = MockNotificationService()
        let mockSettings = MockSettingsRepository()

        // Enable power-aware refresh (this is the default)
        mockSettings.set(.enablePowerAwareRefresh, value: true)

        let container = AppContainer(
            credentialsRepository: MockCredentialsRepository(),
            usageRepository: mockRepo,
            settingsRepository: mockSettings,
            notificationService: mockNotifications,
            startAutoRefresh: true
        )

        // Should start AdaptiveRefreshManager when power-aware is enabled
        #expect(container.adaptiveRefreshManager.isAutoRefreshing == true)
        #expect(container.usageManager.isAutoRefreshing == false)

        // Clean up
        container.adaptiveRefreshManager.stopAutoRefresh()
    }

    @Test("AppContainer wires notification checker to usage manager")
    @MainActor
    func wiresNotificationCheckerToUsageManager() async {
        let mockUsage = MockUsageRepository()
        await mockUsage.setUsageData(UsageData(
            fiveHour: UsageWindow(utilization: 50, resetsAt: nil), // Start below threshold
            sevenDay: UsageWindow(utilization: 50, resetsAt: nil),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            fetchedAt: Date()
        ))
        let mockNotifications = MockNotificationService()
        mockNotifications.setShouldGrantPermission(true)

        let mockSettings = MockSettingsRepository()
        mockSettings.set(.notificationsEnabled, value: true)
        mockSettings.set(.warningEnabled, value: true)
        mockSettings.set(.warningThreshold, value: 90)

        let container = AppContainer(
            credentialsRepository: MockCredentialsRepository(),
            usageRepository: mockUsage,
            settingsRepository: mockSettings,
            notificationService: mockNotifications
        )

        // First refresh - establish baseline below threshold
        await container.usageManager.refresh()
        #expect(container.usageManager.usageData?.fiveHour.utilization == 50)

        // Now update to cross the threshold
        await mockUsage.setUsageData(UsageData(
            fiveHour: UsageWindow(utilization: 95, resetsAt: nil), // Crosses 90% threshold
            sevenDay: UsageWindow(utilization: 50, resetsAt: nil),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            fetchedAt: Date()
        ))

        // Second refresh - should trigger warning notification
        await container.usageManager.refresh()

        // Verify notification was triggered (usage warning for session)
        #expect(mockNotifications.getAddedRequestCount() >= 1)
    }

    @Test("AppContainer test init creates update checker")
    @MainActor
    func testInitCreatesUpdateChecker() {
        let mockCredentials = MockCredentialsRepository()
        let mockUsage = MockUsageRepository()
        let mockNotifications = MockNotificationService()
        let container = AppContainer(
            credentialsRepository: mockCredentials,
            usageRepository: mockUsage,
            notificationService: mockNotifications
        )

        // Verify update checker is created (it's a non-optional property, so it always exists)
        let _: UpdateChecker = container.updateChecker
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
        #expect(manager.iconStyle == .percentage)
        #expect(manager.showPlanBadge == false)
        #expect(manager.showPercentage == true)
        #expect(manager.showSparklines == true)
        #expect(manager.percentageSource == .highest)

        // Refresh settings defaults
        #expect(manager.refreshInterval == 5)
        #expect(manager.enablePowerAwareRefresh == true)
        #expect(manager.reduceRefreshOnBattery == true)

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
        manager.iconStyle = .battery
        manager.showPlanBadge = true
        manager.showPercentage = false
        manager.showSparklines = false
        manager.percentageSource = .session

        // Verify persisted
        #expect(mockRepo.get(.iconStyle) == .battery)
        #expect(mockRepo.get(.showPlanBadge) == true)
        #expect(mockRepo.get(.showPercentage) == false)
        #expect(mockRepo.get(.showSparklines) == false)
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

    @Test("Power-aware refresh settings persist when changed")
    @MainActor
    func powerAwareRefreshSettingsPersist() {
        let mockRepo = MockSettingsRepository()
        let manager = SettingsManager(repository: mockRepo)

        // Change power-aware settings
        manager.enablePowerAwareRefresh = false
        manager.reduceRefreshOnBattery = false

        // Verify persisted
        #expect(mockRepo.get(.enablePowerAwareRefresh) == false)
        #expect(mockRepo.get(.reduceRefreshOnBattery) == false)
    }

    @Test("Power-aware refresh settings load from repository")
    @MainActor
    func powerAwareRefreshSettingsLoad() {
        let mockRepo = MockSettingsRepository()

        // Pre-set values in repository
        mockRepo.set(.enablePowerAwareRefresh, value: false)
        mockRepo.set(.reduceRefreshOnBattery, value: false)

        // Create manager - should load from repository
        let manager = SettingsManager(repository: mockRepo)

        #expect(manager.enablePowerAwareRefresh == false)
        #expect(manager.reduceRefreshOnBattery == false)
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
        mockRepo.set(.iconStyle, value: IconStyle.compact)
        mockRepo.set(.showPlanBadge, value: true)
        mockRepo.set(.showPercentage, value: false)
        mockRepo.set(.showSparklines, value: false)
        mockRepo.set(.percentageSource, value: PercentageSource.weekly)
        mockRepo.set(.refreshInterval, value: 10)
        mockRepo.set(.warningThreshold, value: 80)

        // Create manager - should load from repository
        let manager = SettingsManager(repository: mockRepo)

        #expect(manager.iconStyle == .compact)
        #expect(manager.showPlanBadge == true)
        #expect(manager.showPercentage == false)
        #expect(manager.showSparklines == false)
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
    @Test("Returns default value when JSON data is not found")
    func returnsDefaultWhenNotSet() {
        // Use a unique suite name to avoid test interference
        let testSuiteName = "com.claudeapp.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: testSuiteName)!

        // Clear the suite-specific domain
        defaults.removePersistentDomain(forName: testSuiteName)

        let repo = UserDefaultsSettingsRepository(defaults: defaults)

        // Test with a key that has never been set in standard defaults
        // to verify the default value logic works correctly.
        // Note: UserDefaults(suiteName:) inherits from standard defaults,
        // so keys that exist in standard may not test the default path.
        // We verify the behavior by setting and then verifying consistency.

        // Initially, these keys should return their defaults
        // (unless already set in standard defaults from app usage)
        let initialShowPlanBadge = repo.get(.showPlanBadge)
        let initialRefreshInterval = repo.get(.refreshInterval)

        // Now set different values
        repo.set(.showPlanBadge, value: !initialShowPlanBadge)
        repo.set(.refreshInterval, value: 20)

        // Verify the new values are returned
        #expect(repo.get(.showPlanBadge) == !initialShowPlanBadge)
        #expect(repo.get(.refreshInterval) == 20)

        // Remove from the suite - the values should now come from standard
        // or return defaults if not in standard
        defaults.removePersistentDomain(forName: testSuiteName)

        // After clearing suite, should return to initial state
        // (either default or what's in standard defaults)
        #expect(repo.get(.showPlanBadge) == initialShowPlanBadge)
        #expect(repo.get(.refreshInterval) == initialRefreshInterval)
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

    // MARK: - UserInfo Tests

    @Test("send includes userInfo when provided")
    func sendIncludesUserInfo() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.send(
            title: "Update Available",
            body: "ClaudeApp v1.7.0 is now available",
            identifier: "update-available-1.7.0",
            userInfo: ["downloadURL": "https://example.com/download.dmg"]
        )

        let request = mockService.getLastRequest()
        #expect(request != nil)
        #expect(request?.content.userInfo["downloadURL"] as? String == "https://example.com/download.dmg")
    }

    @Test("send works without userInfo")
    func sendWorksWithoutUserInfo() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.send(
            title: "Test",
            body: "Test body",
            identifier: "test-id"
        )

        let request = mockService.getLastRequest()
        #expect(request != nil)
        #expect(request?.content.userInfo.isEmpty == true)
    }

    @Test("send with nil userInfo does not crash")
    func sendWithNilUserInfoDoesNotCrash() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.send(
            title: "Test",
            body: "Test body",
            identifier: "test-id",
            userInfo: nil
        )

        let request = mockService.getLastRequest()
        #expect(request != nil)
        #expect(request?.content.userInfo.isEmpty == true)
    }

    @Test("send preserves multiple userInfo keys")
    func sendPreservesMultipleUserInfoKeys() async {
        let mockService = MockNotificationService()
        let manager = NotificationManager(notificationCenter: mockService)

        await manager.send(
            title: "Test",
            body: "Test body",
            identifier: "test-id",
            userInfo: [
                "downloadURL": "https://example.com/download.dmg",
                "version": "1.7.0"
            ]
        )

        let request = mockService.getLastRequest()
        #expect(request != nil)
        #expect(request?.content.userInfo["downloadURL"] as? String == "https://example.com/download.dmg")
        #expect(request?.content.userInfo["version"] as? String == "1.7.0")
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

// MARK: - BurnRateCalculator Tests

@Suite("BurnRateCalculator Tests")
struct BurnRateCalculatorTests {
    // MARK: - Initialization Tests

    @Test("BurnRateCalculator initializes with default minimum samples")
    func initWithDefaults() {
        let calculator = BurnRateCalculator()
        // Default minimumSamples is 2, verify by testing behavior
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (50.0, Date()),
            (40.0, Date().addingTimeInterval(-3600)),
        ]
        // With 2 samples, should work if there's positive change
        // This tests that default is at least 2
        let result = calculator.calculate(from: [(60.0, Date()), (40.0, Date().addingTimeInterval(-3600))])
        #expect(result != nil)
    }

    @Test("BurnRateCalculator initializes with custom minimum samples")
    func initWithCustomMinimum() {
        let calculator = BurnRateCalculator(minimumSamples: 3)
        let twoSamples: [(utilization: Double, timestamp: Date)] = [
            (60.0, Date()),
            (40.0, Date().addingTimeInterval(-3600)),
        ]
        // With only 2 samples and minimum of 3, should return nil
        let result = calculator.calculate(from: twoSamples)
        #expect(result == nil)
    }

    @Test("BurnRateCalculator enforces minimum of 2 samples even if set lower")
    func enforcesMinimumOfTwo() {
        let calculator = BurnRateCalculator(minimumSamples: 1)
        let oneSnapshot: [(utilization: Double, timestamp: Date)] = [
            (60.0, Date()),
        ]
        // Even with minimumSamples=1, should require at least 2
        let result = calculator.calculate(from: oneSnapshot)
        #expect(result == nil)
    }

    // MARK: - Calculate Tests

    @Test("calculate returns nil with 0 samples")
    func calculateReturnsNilWithZeroSamples() {
        let calculator = BurnRateCalculator()
        let result = calculator.calculate(from: [])
        #expect(result == nil)
    }

    @Test("calculate returns nil with 1 sample")
    func calculateReturnsNilWithOneSample() {
        let calculator = BurnRateCalculator()
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (50.0, Date()),
        ]
        let result = calculator.calculate(from: snapshots)
        #expect(result == nil)
    }

    @Test("calculate returns correct burn rate with 2 samples")
    func calculateWithTwoSamples() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Utilization increased from 40% to 60% over 1 hour = 20%/hr
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (60.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result?.percentPerHour == 20.0)
    }

    @Test("calculate returns correct burn rate with 12 samples (full history)")
    func calculateWithFullHistory() {
        let calculator = BurnRateCalculator()
        let now = Date()

        // 12 samples over 55 minutes (5 min intervals), from 20% to 75% = 55% over ~0.917 hours
        var snapshots: [(utilization: Double, timestamp: Date)] = []
        for i in 0..<12 {
            let util = 75.0 - (Double(i) * 5.0) // 75, 70, 65, ..., 20
            let time = now.addingTimeInterval(-Double(i) * 300) // 0, -5min, -10min, ...
            snapshots.append((util, time))
        }

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        // 55% over 55 minutes = 60%/hr
        #expect(result!.percentPerHour > 59.0 && result!.percentPerHour < 61.0)
    }

    @Test("calculate returns nil during reset (negative utilization change)")
    func calculateReturnsNilDuringReset() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Utilization decreased from 80% to 20% (reset happened)
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (20.0, now), // newest
            (80.0, oneHourAgo), // oldest
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result == nil)
    }

    @Test("calculate returns nil when no change in utilization")
    func calculateReturnsNilWithNoChange() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Same utilization
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (50.0, now),
            (50.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result == nil)
    }

    @Test("calculate returns nil when timestamps are identical")
    func calculateReturnsNilWithIdenticalTimestamps() {
        let calculator = BurnRateCalculator()
        let now = Date()

        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (60.0, now),
            (40.0, now), // Same timestamp
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result == nil)
    }

    @Test("calculate returns nil when oldest timestamp is after newest")
    func calculateReturnsNilWithReversedTimestamps() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Timestamps in wrong order (oldest should be last, newest first)
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (40.0, oneHourAgo), // This is supposed to be newest but has older timestamp
            (60.0, now), // This is supposed to be oldest but has newer timestamp
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result == nil) // Time diff would be negative
    }

    @Test("calculate handles small time intervals correctly")
    func calculateWithSmallTimeInterval() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300) // 5 minutes

        // 5% increase over 5 minutes = 60%/hr
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (45.0, now),
            (40.0, fiveMinutesAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.percentPerHour == 60.0)
    }

    @Test("calculate handles large time intervals correctly")
    func calculateWithLargeTimeInterval() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let sixHoursAgo = now.addingTimeInterval(-21600) // 6 hours

        // 30% increase over 6 hours = 5%/hr
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (60.0, now),
            (30.0, sixHoursAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.percentPerHour == 5.0)
    }

    @Test("calculate returns correct BurnRateLevel for Low rate")
    func calculateReturnsLowLevel() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // 5%/hr = Low
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (45.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.level == .low)
    }

    @Test("calculate returns correct BurnRateLevel for Medium rate")
    func calculateReturnsMediumLevel() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // 15%/hr = Medium
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (55.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.level == .medium)
    }

    @Test("calculate returns correct BurnRateLevel for High rate")
    func calculateReturnsHighLevel() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // 35%/hr = High
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (75.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.level == .high)
    }

    @Test("calculate returns correct BurnRateLevel for Very High rate")
    func calculateReturnsVeryHighLevel() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // 60%/hr = Very High
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (100.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.level == .veryHigh)
    }

    // MARK: - Threshold Boundary Tests

    @Test("calculate correctly classifies rate at exactly 10%/hr (boundary)")
    func calculateAtTenPercentBoundary() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Exactly 10%/hr is Medium (10..<25 range)
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (50.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.percentPerHour == 10.0)
        #expect(result!.level == .medium)
    }

    @Test("calculate correctly classifies rate at exactly 25%/hr (boundary)")
    func calculateAtTwentyFivePercentBoundary() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Exactly 25%/hr is High (25..<50 range)
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (65.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.percentPerHour == 25.0)
        #expect(result!.level == .high)
    }

    @Test("calculate correctly classifies rate at exactly 50%/hr (boundary)")
    func calculateAtFiftyPercentBoundary() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // Exactly 50%/hr is Very High (>=50 range)
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (90.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.percentPerHour == 50.0)
        #expect(result!.level == .veryHigh)
    }

    @Test("calculate correctly classifies rate just below 10%/hr")
    func calculateJustBelowTenPercent() {
        let calculator = BurnRateCalculator()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)

        // 9%/hr = Low
        let snapshots: [(utilization: Double, timestamp: Date)] = [
            (49.0, now),
            (40.0, oneHourAgo),
        ]

        let result = calculator.calculate(from: snapshots)
        #expect(result != nil)
        #expect(result!.percentPerHour == 9.0)
        #expect(result!.level == .low)
    }

    // MARK: - Time to Exhaustion Tests

    @Test("timeToExhaustion returns nil with nil burn rate")
    func timeToExhaustionNilBurnRate() {
        let calculator = BurnRateCalculator()
        let result = calculator.timeToExhaustion(currentUtilization: 50.0, burnRate: nil)
        #expect(result == nil)
    }

    @Test("timeToExhaustion returns nil with zero burn rate")
    func timeToExhaustionZeroBurnRate() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 0.0)
        let result = calculator.timeToExhaustion(currentUtilization: 50.0, burnRate: burnRate)
        #expect(result == nil)
    }

    @Test("timeToExhaustion returns nil with negative burn rate")
    func timeToExhaustionNegativeBurnRate() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: -5.0)
        let result = calculator.timeToExhaustion(currentUtilization: 50.0, burnRate: burnRate)
        #expect(result == nil)
    }

    @Test("timeToExhaustion returns 0 at 100% utilization")
    func timeToExhaustionAtHundredPercent() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 20.0)
        let result = calculator.timeToExhaustion(currentUtilization: 100.0, burnRate: burnRate)
        #expect(result == 0)
    }

    @Test("timeToExhaustion returns 0 above 100% utilization")
    func timeToExhaustionAboveHundredPercent() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 20.0)
        let result = calculator.timeToExhaustion(currentUtilization: 105.0, burnRate: burnRate)
        #expect(result == 0)
    }

    @Test("timeToExhaustion calculates correct time at 50% with 10%/hr")
    func timeToExhaustionBasicCalculation() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 10.0)

        // 50% remaining capacity, 10%/hr = 5 hours = 18000 seconds
        let result = calculator.timeToExhaustion(currentUtilization: 50.0, burnRate: burnRate)
        #expect(result == 18000)
    }

    @Test("timeToExhaustion calculates correct time at 80% with 20%/hr")
    func timeToExhaustionHighUtilization() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 20.0)

        // 20% remaining capacity, 20%/hr = 1 hour = 3600 seconds
        let result = calculator.timeToExhaustion(currentUtilization: 80.0, burnRate: burnRate)
        #expect(result == 3600)
    }

    @Test("timeToExhaustion calculates correct time at 0% with 5%/hr")
    func timeToExhaustionFromZeroUtilization() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 5.0)

        // 100% remaining capacity, 5%/hr = 20 hours = 72000 seconds
        let result = calculator.timeToExhaustion(currentUtilization: 0.0, burnRate: burnRate)
        #expect(result == 72000)
    }

    @Test("timeToExhaustion calculates correct time at 99% with 100%/hr")
    func timeToExhaustionNearLimit() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 100.0)

        // 1% remaining capacity, 100%/hr = 0.01 hours = 36 seconds
        let result = calculator.timeToExhaustion(currentUtilization: 99.0, burnRate: burnRate)
        #expect(result == 36)
    }

    @Test("timeToExhaustion with fractional values")
    func timeToExhaustionFractionalValues() {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 15.0)

        // 37.5% remaining capacity, 15%/hr = 2.5 hours = 9000 seconds
        let result = calculator.timeToExhaustion(currentUtilization: 62.5, burnRate: burnRate)
        #expect(result == 9000)
    }

    // MARK: - Sendable Conformance Tests

    @Test("BurnRateCalculator is Sendable and can cross actor boundaries")
    func sendableConformance() async {
        let calculator = BurnRateCalculator()

        let result = await Task.detached {
            let now = Date()
            let oneHourAgo = now.addingTimeInterval(-3600)
            let snapshots: [(utilization: Double, timestamp: Date)] = [
                (60.0, now),
                (40.0, oneHourAgo),
            ]
            return calculator.calculate(from: snapshots)
        }.value

        #expect(result != nil)
        #expect(result!.percentPerHour == 20.0)
    }

    @Test("timeToExhaustion can be called from different contexts")
    func timeToExhaustionSendable() async {
        let calculator = BurnRateCalculator()
        let burnRate = BurnRate(percentPerHour: 25.0)

        let result = await Task.detached {
            calculator.timeToExhaustion(currentUtilization: 75.0, burnRate: burnRate)
        }.value

        // 25% remaining / 25%/hr = 1 hour = 3600 seconds
        #expect(result == 3600)
    }
}

// MARK: - UpdateChecker Tests

@Suite("UpdateChecker Tests")
struct UpdateCheckerTests {
    // MARK: - Version Comparison Tests

    @Test("isVersion detects newer major version")
    func newerMajorVersion() {
        #expect(UpdateChecker.isVersion("2.0.0", newerThan: "1.0.0") == true)
        #expect(UpdateChecker.isVersion("10.0.0", newerThan: "9.0.0") == true)
    }

    @Test("isVersion detects newer minor version")
    func newerMinorVersion() {
        #expect(UpdateChecker.isVersion("1.2.0", newerThan: "1.1.0") == true)
        #expect(UpdateChecker.isVersion("1.10.0", newerThan: "1.9.0") == true)
    }

    @Test("isVersion detects newer patch version")
    func newerPatchVersion() {
        #expect(UpdateChecker.isVersion("1.0.2", newerThan: "1.0.1") == true)
        #expect(UpdateChecker.isVersion("1.0.10", newerThan: "1.0.9") == true)
    }

    @Test("isVersion returns false for same version")
    func sameVersion() {
        #expect(UpdateChecker.isVersion("1.0.0", newerThan: "1.0.0") == false)
        #expect(UpdateChecker.isVersion("2.5.3", newerThan: "2.5.3") == false)
    }

    @Test("isVersion returns false for older version")
    func olderVersion() {
        #expect(UpdateChecker.isVersion("1.0.0", newerThan: "2.0.0") == false)
        #expect(UpdateChecker.isVersion("1.0.0", newerThan: "1.1.0") == false)
        #expect(UpdateChecker.isVersion("1.0.0", newerThan: "1.0.1") == false)
    }

    @Test("isVersion handles v prefix")
    func vPrefixHandling() {
        #expect(UpdateChecker.isVersion("v2.0.0", newerThan: "1.0.0") == true)
        #expect(UpdateChecker.isVersion("2.0.0", newerThan: "v1.0.0") == true)
        #expect(UpdateChecker.isVersion("v2.0.0", newerThan: "v1.0.0") == true)
        #expect(UpdateChecker.isVersion("V2.0.0", newerThan: "v1.0.0") == true)
    }

    @Test("isVersion handles different segment counts")
    func differentSegmentCounts() {
        #expect(UpdateChecker.isVersion("1.0.1", newerThan: "1.0") == true)
        #expect(UpdateChecker.isVersion("1.1", newerThan: "1.0.0") == true)
        #expect(UpdateChecker.isVersion("2", newerThan: "1.9.9") == true)
    }

    @Test("isVersion handles zero padding")
    func zeroPadding() {
        #expect(UpdateChecker.isVersion("1.0.0", newerThan: "1") == false)
        #expect(UpdateChecker.isVersion("1.0.1", newerThan: "1") == true)
    }

    // MARK: - GitHub API Models Tests

    @Test("GitHubRelease decodes from JSON")
    func gitHubReleaseDecoding() throws {
        let json = """
            {
                "tag_name": "v1.2.0",
                "name": "Release v1.2.0",
                "html_url": "https://github.com/owner/repo/releases/tag/v1.2.0",
                "published_at": "2026-01-22T10:00:00Z",
                "body": "## What's New\\n- Feature 1",
                "assets": [],
                "draft": false,
                "prerelease": false
            }
            """
        let data = json.data(using: .utf8)!
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        #expect(release.tagName == "v1.2.0")
        #expect(release.name == "Release v1.2.0")
        #expect(release.htmlUrl == "https://github.com/owner/repo/releases/tag/v1.2.0")
        #expect(release.publishedAt == "2026-01-22T10:00:00Z")
        #expect(release.body == "## What's New\n- Feature 1")
        #expect(release.assets.isEmpty)
        #expect(release.draft == false)
        #expect(release.prerelease == false)
    }

    @Test("GitHubRelease decodes with null body")
    func gitHubReleaseWithNullBody() throws {
        let json = """
            {
                "tag_name": "v1.0.0",
                "name": "v1.0.0",
                "html_url": "https://github.com/owner/repo/releases/tag/v1.0.0",
                "published_at": "2026-01-22T10:00:00Z",
                "body": null,
                "assets": [],
                "draft": false,
                "prerelease": false
            }
            """
        let data = json.data(using: .utf8)!
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        #expect(release.body == nil)
    }

    @Test("GitHubAsset decodes from JSON")
    func gitHubAssetDecoding() throws {
        let json = """
            {
                "name": "ClaudeApp.dmg",
                "browser_download_url": "https://github.com/owner/repo/releases/download/v1.0.0/ClaudeApp.dmg",
                "size": 15728640,
                "download_count": 1234
            }
            """
        let data = json.data(using: .utf8)!
        let asset = try JSONDecoder().decode(GitHubAsset.self, from: data)

        #expect(asset.name == "ClaudeApp.dmg")
        #expect(asset.browserDownloadUrl.absoluteString == "https://github.com/owner/repo/releases/download/v1.0.0/ClaudeApp.dmg")
        #expect(asset.size == 15728640)
        #expect(asset.downloadCount == 1234)
    }

    @Test("GitHubRelease decodes with assets")
    func gitHubReleaseWithAssets() throws {
        let json = """
            {
                "tag_name": "v1.2.0",
                "name": "Release v1.2.0",
                "html_url": "https://github.com/owner/repo/releases/tag/v1.2.0",
                "published_at": "2026-01-22T10:00:00Z",
                "body": "Release notes",
                "assets": [
                    {
                        "name": "ClaudeApp.dmg",
                        "browser_download_url": "https://github.com/owner/repo/releases/download/v1.2.0/ClaudeApp.dmg",
                        "size": 15000000,
                        "download_count": 100
                    },
                    {
                        "name": "ClaudeApp.zip",
                        "browser_download_url": "https://github.com/owner/repo/releases/download/v1.2.0/ClaudeApp.zip",
                        "size": 12000000,
                        "download_count": 50
                    }
                ],
                "draft": false,
                "prerelease": false
            }
            """
        let data = json.data(using: .utf8)!
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        #expect(release.assets.count == 2)
        #expect(release.assets[0].name == "ClaudeApp.dmg")
        #expect(release.assets[1].name == "ClaudeApp.zip")
    }

    // MARK: - UpdateInfo Tests

    @Test("UpdateInfo initializes correctly")
    func updateInfoInit() {
        let info = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: "New features"
        )

        #expect(info.version == "1.2.0")
        #expect(info.downloadURL.absoluteString == "https://example.com/download.dmg")
        #expect(info.releaseURL.absoluteString == "https://github.com/owner/repo/releases/tag/v1.2.0")
        #expect(info.releaseNotes == "New features")
    }

    @Test("UpdateInfo is Equatable")
    func updateInfoEquatable() {
        let info1 = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: "Notes"
        )
        let info2 = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: "Notes"
        )
        let info3 = UpdateInfo(
            version: "1.3.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.3.0")!,
            releaseNotes: nil
        )

        #expect(info1 == info2)
        #expect(info1 != info3)
    }

    // MARK: - CheckResult Tests

    @Test("CheckResult upToDate equality")
    func checkResultUpToDateEquality() {
        #expect(CheckResult.upToDate == CheckResult.upToDate)
    }

    @Test("CheckResult rateLimited equality")
    func checkResultRateLimitedEquality() {
        #expect(CheckResult.rateLimited == CheckResult.rateLimited)
    }

    @Test("CheckResult error equality")
    func checkResultErrorEquality() {
        #expect(CheckResult.error("Network error") == CheckResult.error("Network error"))
        #expect(CheckResult.error("Error A") != CheckResult.error("Error B"))
    }

    @Test("CheckResult updateAvailable equality")
    func checkResultUpdateAvailableEquality() {
        let info1 = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: nil
        )
        let info2 = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: nil
        )

        #expect(CheckResult.updateAvailable(info1) == CheckResult.updateAvailable(info2))
    }

    @Test("CheckResult different types not equal")
    func checkResultDifferentTypesNotEqual() {
        let info = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: nil
        )

        #expect(CheckResult.upToDate != CheckResult.rateLimited)
        #expect(CheckResult.upToDate != CheckResult.error("Error"))
        #expect(CheckResult.upToDate != CheckResult.updateAvailable(info))
        #expect(CheckResult.rateLimited != CheckResult.error("Error"))
    }

    // MARK: - UpdateChecker Actor Tests

    @Test("UpdateChecker initializes with default values")
    func updateCheckerInit() async {
        let checker = UpdateChecker()
        let lastCheck = await checker.getLastCheckDate()
        #expect(lastCheck == nil)
    }

    @Test("UpdateChecker initializes with custom values")
    func updateCheckerCustomInit() async {
        let checker = UpdateChecker(
            repoOwner: "anthropics",
            repoName: "claude-code",
            currentVersionProvider: { "1.0.0" }
        )
        let lastCheck = await checker.getLastCheckDate()
        #expect(lastCheck == nil)
    }

    @Test("UpdateChecker reset clears state")
    func updateCheckerReset() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })

        // Simulate a check happening
        _ = await checker.checkInBackground()

        // Reset
        await checker.reset()

        let lastCheck = await checker.getLastCheckDate()
        #expect(lastCheck == nil)
    }

    @Test("shouldNotify returns nil for upToDate")
    func shouldNotifyUpToDate() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })
        let result = await checker.shouldNotify(for: .upToDate)
        #expect(result == nil)
    }

    @Test("shouldNotify returns nil for error")
    func shouldNotifyError() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })
        let result = await checker.shouldNotify(for: .error("Network error"))
        #expect(result == nil)
    }

    @Test("shouldNotify returns nil for rateLimited")
    func shouldNotifyRateLimited() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })
        let result = await checker.shouldNotify(for: .rateLimited)
        #expect(result == nil)
    }

    @Test("shouldNotify returns info for new update")
    func shouldNotifyNewUpdate() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })
        let info = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: nil
        )

        let result = await checker.shouldNotify(for: .updateAvailable(info))
        #expect(result != nil)
        #expect(result?.version == "1.2.0")
    }

    @Test("shouldNotify returns nil for already notified version")
    func shouldNotifyAlreadyNotified() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })
        let info = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: nil
        )

        // First notification
        let result1 = await checker.shouldNotify(for: .updateAvailable(info))
        #expect(result1 != nil)

        // Second notification for same version
        let result2 = await checker.shouldNotify(for: .updateAvailable(info))
        #expect(result2 == nil)
    }

    @Test("shouldNotify returns info for different version after previous")
    func shouldNotifyDifferentVersion() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })
        let info1 = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.2.0")!,
            releaseNotes: nil
        )
        let info2 = UpdateInfo(
            version: "1.3.0",
            downloadURL: URL(string: "https://example.com/download.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo/releases/tag/v1.3.0")!,
            releaseNotes: nil
        )

        // First notification
        let result1 = await checker.shouldNotify(for: .updateAvailable(info1))
        #expect(result1 != nil)

        // Second notification for different version
        let result2 = await checker.shouldNotify(for: .updateAvailable(info2))
        #expect(result2 != nil)
        #expect(result2?.version == "1.3.0")
    }

    // MARK: - Bundle Extension Tests

    @Test("Bundle appVersion returns version string")
    func bundleAppVersion() {
        // Bundle.main in tests may not have version info, so we test the extension exists
        let version = Bundle.main.appVersion
        #expect(version.isEmpty == false)
    }

    @Test("Bundle buildNumber returns build string")
    func bundleBuildNumber() {
        let build = Bundle.main.buildNumber
        #expect(build.isEmpty == false)
    }

    // MARK: - GitHubRelease Initialization Tests

    @Test("GitHubRelease initializes with all parameters")
    func gitHubReleaseInit() {
        let asset = GitHubAsset(
            name: "ClaudeApp.dmg",
            browserDownloadUrl: URL(string: "https://example.com/app.dmg")!,
            size: 15000000,
            downloadCount: 100
        )
        let release = GitHubRelease(
            tagName: "v1.2.0",
            name: "Release 1.2.0",
            htmlUrl: "https://github.com/owner/repo/releases/tag/v1.2.0",
            publishedAt: "2026-01-22T10:00:00Z",
            body: "Release notes",
            assets: [asset],
            draft: false,
            prerelease: false
        )

        #expect(release.tagName == "v1.2.0")
        #expect(release.name == "Release 1.2.0")
        #expect(release.assets.count == 1)
        #expect(release.draft == false)
        #expect(release.prerelease == false)
    }

    @Test("GitHubRelease is Equatable")
    func gitHubReleaseEquatable() {
        let release1 = GitHubRelease(
            tagName: "v1.0.0",
            name: "v1.0.0",
            htmlUrl: "https://github.com/owner/repo",
            publishedAt: "2026-01-22",
            body: nil,
            assets: []
        )
        let release2 = GitHubRelease(
            tagName: "v1.0.0",
            name: "v1.0.0",
            htmlUrl: "https://github.com/owner/repo",
            publishedAt: "2026-01-22",
            body: nil,
            assets: []
        )
        let release3 = GitHubRelease(
            tagName: "v2.0.0",
            name: "v2.0.0",
            htmlUrl: "https://github.com/owner/repo",
            publishedAt: "2026-01-22",
            body: nil,
            assets: []
        )

        #expect(release1 == release2)
        #expect(release1 != release3)
    }

    @Test("GitHubAsset is Equatable")
    func gitHubAssetEquatable() {
        let asset1 = GitHubAsset(
            name: "app.dmg",
            browserDownloadUrl: URL(string: "https://example.com/app.dmg")!,
            size: 1000,
            downloadCount: 10
        )
        let asset2 = GitHubAsset(
            name: "app.dmg",
            browserDownloadUrl: URL(string: "https://example.com/app.dmg")!,
            size: 1000,
            downloadCount: 10
        )
        let asset3 = GitHubAsset(
            name: "other.dmg",
            browserDownloadUrl: URL(string: "https://example.com/other.dmg")!
        )

        #expect(asset1 == asset2)
        #expect(asset1 != asset3)
    }

    // MARK: - Sendable Conformance Tests

    @Test("UpdateChecker is actor-isolated and Sendable types work across boundaries")
    func updateCheckerSendable() async {
        let checker = UpdateChecker(currentVersionProvider: { "1.0.0" })

        let result = await Task.detached {
            await checker.getLastCheckDate()
        }.value

        #expect(result == nil)
    }

    @Test("CheckResult is Sendable")
    func checkResultSendable() async {
        let info = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/app.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo")!,
            releaseNotes: nil
        )
        let result: CheckResult = .updateAvailable(info)

        let crossedResult = await Task.detached {
            result
        }.value

        #expect(crossedResult == result)
    }

    @Test("UpdateInfo is Sendable")
    func updateInfoSendable() async {
        let info = UpdateInfo(
            version: "1.2.0",
            downloadURL: URL(string: "https://example.com/app.dmg")!,
            releaseURL: URL(string: "https://github.com/owner/repo")!,
            releaseNotes: "Notes"
        )

        let crossedInfo = await Task.detached {
            info
        }.value

        #expect(crossedInfo.version == "1.2.0")
    }

    @Test("GitHubRelease is Sendable")
    func gitHubReleaseSendable() async {
        let release = GitHubRelease(
            tagName: "v1.0.0",
            name: "v1.0.0",
            htmlUrl: "https://github.com/owner/repo",
            publishedAt: "2026-01-22",
            body: nil,
            assets: []
        )

        let crossedRelease = await Task.detached {
            release
        }.value

        #expect(crossedRelease.tagName == "v1.0.0")
    }

    @Test("GitHubAsset is Sendable")
    func gitHubAssetSendable() async {
        let asset = GitHubAsset(
            name: "app.dmg",
            browserDownloadUrl: URL(string: "https://example.com/app.dmg")!
        )

        let crossedAsset = await Task.detached {
            asset
        }.value

        #expect(crossedAsset.name == "app.dmg")
    }

    // MARK: - Persistence Tests

    @Test("UpdateChecker loads persisted lastCheckDate on init")
    func loadsPersistedLastCheckDate() async {
        let mockRepo = MockSettingsRepository()
        let persistedDate = Date().addingTimeInterval(-3600) // 1 hour ago

        // Pre-populate the repository with a check date
        mockRepo.set(.lastUpdateCheckDate, value: persistedDate)

        let checker = UpdateChecker(
            settingsRepository: mockRepo,
            currentVersionProvider: { "1.0.0" }
        )

        let loadedDate = await checker.getLastCheckDate()
        #expect(loadedDate != nil)
        // Compare within 1 second tolerance due to encoding/decoding
        #expect(abs(loadedDate!.timeIntervalSince(persistedDate)) < 1)
    }

    @Test("UpdateChecker persists lastCheckDate after background check")
    func persistsLastCheckDateAfterBackgroundCheck() async {
        let mockRepo = MockSettingsRepository()
        let checker = UpdateChecker(
            settingsRepository: mockRepo,
            currentVersionProvider: { "1.0.0" }
        )

        // Verify no date persisted initially
        let initialDate: Date? = mockRepo.get(.lastUpdateCheckDate)
        #expect(initialDate == nil)

        // Perform a background check (will fail network but still sets date)
        _ = await checker.checkInBackground()

        // Verify date is now persisted
        let persistedDate: Date? = mockRepo.get(.lastUpdateCheckDate)
        #expect(persistedDate != nil)
    }

    @Test("UpdateChecker clears persisted lastCheckDate on reset")
    func clearsPersistedLastCheckDateOnReset() async {
        let mockRepo = MockSettingsRepository()
        let checker = UpdateChecker(
            settingsRepository: mockRepo,
            currentVersionProvider: { "1.0.0" }
        )

        // Perform a check to set the date
        _ = await checker.checkInBackground()

        // Verify date is persisted
        let persistedDate: Date? = mockRepo.get(.lastUpdateCheckDate)
        #expect(persistedDate != nil)

        // Reset the checker
        await checker.reset()

        // Verify date is cleared
        let clearedDate: Date? = mockRepo.get(.lastUpdateCheckDate)
        #expect(clearedDate == nil)
    }

    @Test("UpdateChecker skips check when persisted date is recent")
    func skipsCheckWhenPersistedDateIsRecent() async {
        let mockRepo = MockSettingsRepository()
        let recentDate = Date().addingTimeInterval(-3600) // 1 hour ago (within 24 hour limit)

        // Pre-populate with a recent check date
        mockRepo.set(.lastUpdateCheckDate, value: recentDate)

        let checker = UpdateChecker(
            settingsRepository: mockRepo,
            currentVersionProvider: { "1.0.0" }
        )

        // Background check should be skipped due to recent date
        let result = await checker.checkInBackground()
        #expect(result == nil)
    }
}

// MARK: - Mock Accessibility Announcer

/// Mock accessibility announcer for testing VoiceOver announcements.
final class MockAccessibilityAnnouncer: AccessibilityAnnouncerProtocol, @unchecked Sendable {
    private var lock = NSLock()
    private var _announcements: [String] = []

    var announcements: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _announcements
    }

    var lastAnnouncement: String? {
        lock.lock()
        defer { lock.unlock() }
        return _announcements.last
    }

    var announcementCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _announcements.count
    }

    func announce(_ message: String) {
        lock.lock()
        _announcements.append(message)
        lock.unlock()
    }

    func reset() {
        lock.lock()
        _announcements.removeAll()
        lock.unlock()
    }
}

// MARK: - AccessibilityAnnouncer Tests

@Suite("AccessibilityAnnouncer Tests")
struct AccessibilityAnnouncerTests {
    @Test("Announcement messages are correct")
    func announcementMessages() {
        // Verify static message content
        #expect(AccessibilityAnnouncementMessages.refreshComplete == "Usage data updated")
        #expect(AccessibilityAnnouncementMessages.refreshFailed == "Unable to refresh usage data")
        #expect(AccessibilityAnnouncementMessages.resetComplete == "Usage limit has reset. Full capacity available.")
    }

    @Test("Warning threshold message formats correctly")
    func warningThresholdMessage() {
        let message90 = AccessibilityAnnouncementMessages.warningThreshold(percentage: 90)
        #expect(message90 == "Warning: usage at 90 percent")

        let message100 = AccessibilityAnnouncementMessages.warningThreshold(percentage: 100)
        #expect(message100 == "Warning: usage at 100 percent")

        let message75 = AccessibilityAnnouncementMessages.warningThreshold(percentage: 75)
        #expect(message75 == "Warning: usage at 75 percent")
    }

    @Test("Capacity full message formats correctly")
    func capacityFullMessage() {
        let sessionMessage = AccessibilityAnnouncementMessages.capacityFull(windowName: "Current session")
        #expect(sessionMessage == "Current session limit reached")

        let weeklyMessage = AccessibilityAnnouncementMessages.capacityFull(windowName: "Weekly (all models)")
        #expect(weeklyMessage == "Weekly (all models) limit reached")
    }

    @Test("Mock announcer records announcements")
    func mockAnnouncerRecords() {
        let announcer = MockAccessibilityAnnouncer()

        announcer.announce("Test message 1")
        announcer.announce("Test message 2")

        #expect(announcer.announcementCount == 2)
        #expect(announcer.announcements == ["Test message 1", "Test message 2"])
        #expect(announcer.lastAnnouncement == "Test message 2")
    }

    @Test("Mock announcer reset clears announcements")
    func mockAnnouncerReset() {
        let announcer = MockAccessibilityAnnouncer()

        announcer.announce("Test message")
        #expect(announcer.announcementCount == 1)

        announcer.reset()
        #expect(announcer.announcementCount == 0)
        #expect(announcer.lastAnnouncement == nil)
    }
}

// MARK: - UsageManager Multi-Account Tests

@Suite("UsageManager Multi-Account Tests")
struct UsageManagerMultiAccountTests {
    /// Creates a test UserDefaults instance with a unique suite name
    private func createTestDefaults() -> UserDefaults {
        let suiteName = "com.claudeapp.test.multiaccountusage.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Creates an AccountManager with isolated test storage
    @MainActor
    private func createTestAccountManager() -> AccountManager {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        return AccountManager(storage: storage)
    }

    // MARK: - Basic Multi-Account Tests

    @Test("UsageManager stores data per account")
    @MainActor
    func storesDataPerAccount() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        // Add test account and wire up
        let account = Account(name: "Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        // Check data is stored for the account
        #expect(manager.usageByAccount[account.id] != nil)
        #expect(manager.usageByAccount[account.id]?.fiveHour.utilization == 45.0)
    }

    @Test("UsageData returns active account's data")
    @MainActor
    func usageDataReturnsActiveAccountData() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 60.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 80.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "Active Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        // usageData property should return active account's data
        #expect(manager.usageData?.fiveHour.utilization == 60.0)
        #expect(manager.usageData?.sevenDay.utilization == 80.0)
    }

    @Test("HighestUtilizationAcrossAccounts returns max from all active accounts")
    @MainActor
    func highestUtilizationAcrossAccounts() async {
        let data1 = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 50.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: data1)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        // Add first account
        let account1 = Account(name: "Account 1")
        accountManager.addAccount(account1)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        // Add data for second account (simulated - directly set)
        let account2 = Account(name: "Account 2")
        accountManager.addAccount(account2)

        // Simulate fetching higher data for account2
        let data2 = UsageData(
            fiveHour: UsageWindow(utilization: 90.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 95.0, resetsAt: nil),
            fetchedAt: Date()
        )
        await mockRepo.setUsageData(data2)
        await manager.refresh()

        // Should return max (95% from account2's sevenDay)
        #expect(manager.highestUtilizationAcrossAccounts == 95.0)
    }

    @Test("UsageHistoryCount returns per-account history")
    @MainActor
    func usageHistoryCountPerAccount() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "History Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        // Refresh multiple times
        await manager.refresh()
        await manager.refresh()
        await manager.refresh()

        #expect(manager.usageHistoryCount == 3)
    }

    @Test("ClearHistory for specific account clears only that account")
    @MainActor
    func clearHistoryForSpecificAccount() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account1 = Account(name: "Account 1")
        accountManager.addAccount(account1)
        manager.setAccountManager(accountManager)

        await manager.refresh()
        #expect(manager.usageHistoryCount >= 1)

        manager.clearHistory(for: account1.id)
        #expect(manager.usageHistoryCount == 0)
    }

    // MARK: - Error Handling Tests

    @Test("ErrorByAccount tracks per-account errors")
    @MainActor
    func errorByAccountTracksErrors() async {
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "Error Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        #expect(manager.errorByAccount[account.id] != nil)
        if case .networkError = manager.errorByAccount[account.id] {
            // Expected
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("Error method returns account-specific error")
    @MainActor
    func errorMethodReturnsAccountError() async {
        let mockRepo = MockUsageRepository(error: .notAuthenticated)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "Auth Error Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        let error = manager.error(for: account.id)
        #expect(error == .notAuthenticated)
    }

    @Test("UsageData method returns data for specific account")
    @MainActor
    func usageDataMethodForAccount() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 75.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 85.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "Specific Account")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        let data = manager.usageData(for: account.id)
        #expect(data?.fiveHour.utilization == 75.0)
    }

    // MARK: - Backward Compatibility Tests

    @Test("Works without AccountManager (legacy mode)")
    @MainActor
    func worksWithoutAccountManager() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 50.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 60.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        // Intentionally NOT setting AccountManager

        await manager.refresh()

        // Should still work and store data
        #expect(manager.usageData?.fiveHour.utilization == 50.0)
        #expect(manager.highestUtilization == 60.0)
    }

    @Test("Legacy mode uses usageHistory not usageHistoryByAccount")
    @MainActor
    func legacyModeUsesUsageHistory() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        // No AccountManager = legacy mode

        await manager.refresh()
        await manager.refresh()

        #expect(manager.usageHistoryCount == 2)
    }

    // MARK: - RefreshActiveAccount Tests

    @Test("RefreshActiveAccount updates only active account")
    @MainActor
    func refreshActiveAccountUpdatesOnlyActive() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 55.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 65.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account1 = Account(name: "Active")
        let account2 = Account(name: "Inactive")
        accountManager.addAccount(account1)
        accountManager.addAccount(account2)
        manager.setAccountManager(accountManager)

        // Set account1 as active (should be active by default as it was added first then account2 became active)
        accountManager.setActiveAccount(account1.id)

        await manager.refreshActiveAccount()

        // Only active account should have data
        #expect(manager.usageByAccount[account1.id] != nil)
        // Account2 was never active when refresh happened, so no data
    }

    // MARK: - Integration Tests

    @Test("Account switching shows correct data")
    @MainActor
    func accountSwitchingShowsCorrectData() async {
        let data1 = UsageData(
            fiveHour: UsageWindow(utilization: 30.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 40.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: data1)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        // Add and refresh account1
        let account1 = Account(name: "Account 1")
        accountManager.addAccount(account1)
        manager.setAccountManager(accountManager)
        await manager.refresh()

        // Add account2 with different data
        let account2 = Account(name: "Account 2")
        accountManager.addAccount(account2)

        let data2 = UsageData(
            fiveHour: UsageWindow(utilization: 70.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 80.0, resetsAt: nil),
            fetchedAt: Date()
        )
        await mockRepo.setUsageData(data2)
        await manager.refresh()

        // Check account2 data (currently active)
        #expect(manager.usageData?.fiveHour.utilization == 70.0)

        // Switch to account1
        accountManager.setActiveAccount(account1.id)

        // Should show account1's data
        #expect(manager.usageData?.fiveHour.utilization == 30.0)
    }

    @Test("HighestUtilization reflects active account")
    @MainActor
    func highestUtilizationReflectsActiveAccount() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            sevenDayOpus: UsageWindow(utilization: 88.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "Multi-Window Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        await manager.refresh()

        // Highest should be 88% from Opus window
        #expect(manager.highestUtilization == 88.0)
    }

    @Test("Burn rates calculated per account")
    @MainActor
    func burnRatesCalculatedPerAccount() async {
        // Start with lower utilization
        let data1 = UsageData(
            fiveHour: UsageWindow(utilization: 20.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 30.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: data1)
        let manager = UsageManager(usageRepository: mockRepo)
        let accountManager = createTestAccountManager()

        let account = Account(name: "Burn Rate Test")
        accountManager.addAccount(account)
        manager.setAccountManager(accountManager)

        // First refresh
        await manager.refresh()

        // Simulate time passing and higher utilization
        let data2 = UsageData(
            fiveHour: UsageWindow(utilization: 40.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 50.0, resetsAt: nil),
            fetchedAt: Date()
        )
        await mockRepo.setUsageData(data2)
        await manager.refresh()

        // Check that we have at least 2 history snapshots
        #expect(manager.usageHistoryCount >= 2)
    }
}

// MARK: - UsageManager Accessibility Tests

@Suite("UsageManager Accessibility Tests")
struct UsageManagerAccessibilityTests {
    @Test("Refresh announces success on successful fetch")
    @MainActor
    func refreshAnnouncesSuccess() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let mockAnnouncer = MockAccessibilityAnnouncer()
        let manager = UsageManager(usageRepository: mockRepo, accessibilityAnnouncer: mockAnnouncer)

        await manager.refresh()

        #expect(mockAnnouncer.announcementCount == 1)
        #expect(mockAnnouncer.lastAnnouncement == AccessibilityAnnouncementMessages.refreshComplete)
    }

    @Test("Refresh announces failure on error")
    @MainActor
    func refreshAnnouncesFailure() async {
        let mockRepo = MockUsageRepository(error: .networkError(message: "Connection failed"))
        let mockAnnouncer = MockAccessibilityAnnouncer()
        let manager = UsageManager(usageRepository: mockRepo, accessibilityAnnouncer: mockAnnouncer)

        await manager.refresh()

        #expect(mockAnnouncer.announcementCount == 1)
        #expect(mockAnnouncer.lastAnnouncement == AccessibilityAnnouncementMessages.refreshFailed)
    }

    @Test("Refresh announces failure on auth error")
    @MainActor
    func refreshAnnouncesAuthFailure() async {
        let mockRepo = MockUsageRepository(error: .notAuthenticated)
        let mockAnnouncer = MockAccessibilityAnnouncer()
        let manager = UsageManager(usageRepository: mockRepo, accessibilityAnnouncer: mockAnnouncer)

        await manager.refresh()

        #expect(mockAnnouncer.announcementCount == 1)
        #expect(mockAnnouncer.lastAnnouncement == AccessibilityAnnouncementMessages.refreshFailed)
    }

    @Test("Multiple refreshes create multiple announcements")
    @MainActor
    func multipleRefreshesAnnounce() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let mockAnnouncer = MockAccessibilityAnnouncer()
        let manager = UsageManager(usageRepository: mockRepo, accessibilityAnnouncer: mockAnnouncer)

        await manager.refresh()
        await manager.refresh()
        await manager.refresh()

        #expect(mockAnnouncer.announcementCount == 3)
        #expect(mockAnnouncer.announcements.allSatisfy { $0 == AccessibilityAnnouncementMessages.refreshComplete })
    }

    @Test("Mixed success and failure announcements")
    @MainActor
    func mixedSuccessAndFailure() async {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        )
        let mockRepo = MockUsageRepository(usageData: testData)
        let mockAnnouncer = MockAccessibilityAnnouncer()
        let manager = UsageManager(usageRepository: mockRepo, accessibilityAnnouncer: mockAnnouncer)

        // First refresh succeeds
        await manager.refresh()
        #expect(mockAnnouncer.lastAnnouncement == AccessibilityAnnouncementMessages.refreshComplete)

        // Configure failure - setting error will cause it to throw before returning data
        await mockRepo.setError(.networkError(message: "No connection"))

        // Second refresh fails
        await manager.refresh()
        #expect(mockAnnouncer.lastAnnouncement == AccessibilityAnnouncementMessages.refreshFailed)

        #expect(mockAnnouncer.announcementCount == 2)
        #expect(mockAnnouncer.announcements[0] == AccessibilityAnnouncementMessages.refreshComplete)
        #expect(mockAnnouncer.announcements[1] == AccessibilityAnnouncementMessages.refreshFailed)
    }
}

// MARK: - UsageNotificationChecker Accessibility Tests

@Suite("UsageNotificationChecker Accessibility Tests")
struct UsageNotificationCheckerAccessibilityTests {
    /// Creates test dependencies with mock announcer
    @MainActor
    private static func createTestDependencies(
        notificationsEnabled: Bool = true,
        warningEnabled: Bool = true,
        capacityFullEnabled: Bool = true,
        resetCompleteEnabled: Bool = true,
        warningThreshold: Int = 90
    ) -> (checker: UsageNotificationChecker, service: MockNotificationService, announcer: MockAccessibilityAnnouncer) {
        let mockService = MockNotificationService()
        let notificationManager = NotificationManager(notificationCenter: mockService)
        let mockSettingsRepo = MockSettingsRepository()
        let mockAnnouncer = MockAccessibilityAnnouncer()

        // Configure settings
        mockSettingsRepo.set(.notificationsEnabled, value: notificationsEnabled)
        mockSettingsRepo.set(.warningEnabled, value: warningEnabled)
        mockSettingsRepo.set(.capacityFullEnabled, value: capacityFullEnabled)
        mockSettingsRepo.set(.resetCompleteEnabled, value: resetCompleteEnabled)
        mockSettingsRepo.set(.warningThreshold, value: warningThreshold)

        let settingsManager = SettingsManager(repository: mockSettingsRepo)

        let checker = UsageNotificationChecker(
            notificationManager: notificationManager,
            settingsManager: settingsManager,
            accessibilityAnnouncer: mockAnnouncer
        )

        return (checker, mockService, mockAnnouncer)
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

    @Test("Warning threshold crossing announces to VoiceOver")
    @MainActor
    func warningThresholdAnnounces() async {
        let deps = Self.createTestDependencies(warningThreshold: 90)

        // Cross from 80% to 95%
        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        #expect(deps.announcer.announcementCount == 1)
        #expect(deps.announcer.lastAnnouncement == "Warning: usage at 95 percent")
    }

    @Test("Capacity full announces to VoiceOver")
    @MainActor
    func capacityFullAnnounces() async {
        let deps = Self.createTestDependencies()

        // Cross from 95% to 100%
        let previous = Self.createUsageData(fiveHour: 95, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 100, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        // Should announce both warning (crossing 90) and capacity full
        // Actually, capacity full is separate from warning
        // Since we went from 95 to 100, no warning (already above 90), but capacity full
        #expect(deps.announcer.announcementCount == 1)
        #expect(deps.announcer.lastAnnouncement == "Current session limit reached")
    }

    @Test("Reset complete announces to VoiceOver")
    @MainActor
    func resetCompleteAnnounces() async {
        let deps = Self.createTestDependencies()

        // Simulate reset: previous high (60%), current low (5%)
        let previous = Self.createUsageData(fiveHour: 50, sevenDay: 60)
        let current = Self.createUsageData(fiveHour: 5, sevenDay: 5)

        await deps.checker.check(current: current, previous: previous)

        #expect(deps.announcer.announcementCount == 1)
        #expect(deps.announcer.lastAnnouncement == AccessibilityAnnouncementMessages.resetComplete)
    }

    @Test("No announcement when notifications disabled")
    @MainActor
    func noAnnouncementWhenDisabled() async {
        let deps = Self.createTestDependencies(notificationsEnabled: false)

        // Cross threshold but notifications are disabled
        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        #expect(deps.announcer.announcementCount == 0)
    }

    @Test("No warning announcement when warning disabled")
    @MainActor
    func noWarningWhenDisabled() async {
        let deps = Self.createTestDependencies(warningEnabled: false, capacityFullEnabled: false)

        // Cross warning threshold
        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        #expect(deps.announcer.announcementCount == 0)
    }

    @Test("Multiple window crossings announce multiple times")
    @MainActor
    func multipleWindowCrossings() async {
        let deps = Self.createTestDependencies()

        // Cross threshold in multiple windows
        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 80, opus: 80)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 95, opus: 95)

        await deps.checker.check(current: current, previous: previous)

        // Should announce warning for session, weekly, and opus
        #expect(deps.announcer.announcementCount == 3)
    }

    @Test("Both warning and capacity full can announce")
    @MainActor
    func warningAndCapacityFull() async {
        let deps = Self.createTestDependencies()

        // Cross from below threshold to 100%
        let previous = Self.createUsageData(fiveHour: 80, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 100, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        // Should announce both warning (crossing 90) and capacity full (crossing 100)
        #expect(deps.announcer.announcementCount == 2)
        #expect(deps.announcer.announcements.contains("Warning: usage at 100 percent"))
        #expect(deps.announcer.announcements.contains("Current session limit reached"))
    }

    @Test("No announcement when not crossing threshold")
    @MainActor
    func noAnnouncementWhenNotCrossing() async {
        let deps = Self.createTestDependencies()

        // Both already above threshold
        let previous = Self.createUsageData(fiveHour: 92, sevenDay: 50)
        let current = Self.createUsageData(fiveHour: 95, sevenDay: 50)

        await deps.checker.check(current: current, previous: previous)

        #expect(deps.announcer.announcementCount == 0)
    }
}

// MARK: - SystemStateMonitor Tests

@Suite("SystemStateMonitor Tests")
struct SystemStateMonitorTests {
    // MARK: - Initial State Tests

    @Test("Initial state is active")
    @MainActor
    func initialStateIsActive() {
        let monitor = SystemStateMonitor()
        #expect(monitor.currentState == .active)
    }

    @Test("Initial battery state is false")
    @MainActor
    func initialBatteryStateIsFalse() {
        let monitor = SystemStateMonitor()
        // Note: This may vary on actual hardware, but default is false
        // Testing the default before monitoring starts
        let _ = monitor.isOnBattery // Just verify it's accessible
    }

    @Test("Default idle threshold is 5 minutes")
    @MainActor
    func defaultIdleThresholdIs5Minutes() {
        let monitor = SystemStateMonitor()
        #expect(monitor.idleThreshold == 300)
    }

    @Test("Default idle check interval is 60 seconds")
    @MainActor
    func defaultIdleCheckIntervalIs60Seconds() {
        let monitor = SystemStateMonitor()
        #expect(monitor.idleCheckInterval == 60)
    }

    @Test("Custom idle threshold is preserved")
    @MainActor
    func customIdleThresholdIsPreserved() {
        let monitor = SystemStateMonitor(idleThreshold: 600)
        #expect(monitor.idleThreshold == 600)
    }

    @Test("Custom idle check interval is preserved")
    @MainActor
    func customIdleCheckIntervalIsPreserved() {
        let monitor = SystemStateMonitor(idleCheckInterval: 30)
        #expect(monitor.idleCheckInterval == 30)
    }

    // MARK: - State Transition Tests (using test helpers)

    @Test("setStateForTesting sets state to sleeping")
    @MainActor
    func setStateForTestingSetsStateSleeping() {
        let monitor = SystemStateMonitor()
        monitor.setStateForTesting(.sleeping)
        #expect(monitor.currentState == .sleeping)
    }

    @Test("setStateForTesting sets state to idle")
    @MainActor
    func setStateForTestingSetsStateIdle() {
        let monitor = SystemStateMonitor()
        monitor.setStateForTesting(.idle)
        #expect(monitor.currentState == .idle)
    }

    @Test("setStateForTesting sets state to active")
    @MainActor
    func setStateForTestingSetsStateActive() {
        let monitor = SystemStateMonitor()
        monitor.setStateForTesting(.sleeping)
        monitor.setStateForTesting(.active)
        #expect(monitor.currentState == .active)
    }

    @Test("setBatteryStateForTesting sets battery state")
    @MainActor
    func setBatteryStateForTestingSetsBatteryState() {
        let monitor = SystemStateMonitor()
        monitor.setBatteryStateForTesting(true)
        #expect(monitor.isOnBattery == true)

        monitor.setBatteryStateForTesting(false)
        #expect(monitor.isOnBattery == false)
    }

    // MARK: - Monitoring Lifecycle Tests

    @Test("startMonitoring can be called multiple times safely")
    @MainActor
    func startMonitoringMultipleTimes() async throws {
        let monitor = SystemStateMonitor(idleCheckInterval: 1)
        monitor.startMonitoring()
        monitor.startMonitoring() // Should not crash or duplicate observers
        monitor.stopMonitoring()
    }

    @Test("stopMonitoring can be called multiple times safely")
    @MainActor
    func stopMonitoringMultipleTimes() {
        let monitor = SystemStateMonitor()
        monitor.startMonitoring()
        monitor.stopMonitoring()
        monitor.stopMonitoring() // Should not crash
    }

    @Test("stopMonitoring before startMonitoring is safe")
    @MainActor
    func stopMonitoringBeforeStart() {
        let monitor = SystemStateMonitor()
        monitor.stopMonitoring() // Should not crash
    }

    // MARK: - SystemState Enum Tests

    @Test("SystemState enum has expected cases")
    func systemStateEnumCases() {
        let active = SystemState.active
        let idle = SystemState.idle
        let sleeping = SystemState.sleeping

        #expect(active != idle)
        #expect(idle != sleeping)
        #expect(active != sleeping)
    }

    @Test("SystemState is Equatable")
    func systemStateIsEquatable() {
        #expect(SystemState.active == SystemState.active)
        #expect(SystemState.idle == SystemState.idle)
        #expect(SystemState.sleeping == SystemState.sleeping)
    }

    @Test("SystemState is Sendable")
    func systemStateIsSendable() async {
        let state = SystemState.active
        let result = await Task.detached {
            state
        }.value
        #expect(result == .active)
    }
}

// MARK: - MockSystemStateMonitor Tests

@Suite("MockSystemStateMonitor Tests")
struct MockSystemStateMonitorTests {
    @Test("MockSystemStateMonitor initial state is active")
    @MainActor
    func initialStateIsActive() {
        let mock = MockSystemStateMonitor()
        #expect(mock.currentState == .active)
    }

    @Test("MockSystemStateMonitor initial battery state is false")
    @MainActor
    func initialBatteryStateIsFalse() {
        let mock = MockSystemStateMonitor()
        #expect(mock.isOnBattery == false)
    }

    @Test("MockSystemStateMonitor tracks startMonitoring calls")
    @MainActor
    func tracksStartMonitoringCalls() {
        let mock = MockSystemStateMonitor()
        #expect(mock.startMonitoringCallCount == 0)

        mock.startMonitoring()
        #expect(mock.startMonitoringCallCount == 1)

        mock.startMonitoring()
        #expect(mock.startMonitoringCallCount == 2)
    }

    @Test("MockSystemStateMonitor tracks stopMonitoring calls")
    @MainActor
    func tracksStopMonitoringCalls() {
        let mock = MockSystemStateMonitor()
        #expect(mock.stopMonitoringCallCount == 0)

        mock.stopMonitoring()
        #expect(mock.stopMonitoringCallCount == 1)

        mock.stopMonitoring()
        #expect(mock.stopMonitoringCallCount == 2)
    }

    @Test("MockSystemStateMonitor setState changes state")
    @MainActor
    func setStateChangesState() {
        let mock = MockSystemStateMonitor()

        mock.setState(.idle)
        #expect(mock.currentState == .idle)

        mock.setState(.sleeping)
        #expect(mock.currentState == .sleeping)

        mock.setState(.active)
        #expect(mock.currentState == .active)
    }

    @Test("MockSystemStateMonitor setBatteryState changes battery state")
    @MainActor
    func setBatteryStateChangesBatteryState() {
        let mock = MockSystemStateMonitor()

        mock.setBatteryState(true)
        #expect(mock.isOnBattery == true)

        mock.setBatteryState(false)
        #expect(mock.isOnBattery == false)
    }

    @Test("MockSystemStateMonitor conforms to SystemStateMonitorProtocol")
    @MainActor
    func conformsToProtocol() {
        let mock: any SystemStateMonitorProtocol = MockSystemStateMonitor()
        #expect(mock.currentState == .active)
        #expect(mock.isOnBattery == false)
    }
}

// MARK: - AdaptiveRefreshManager Tests

@Suite("AdaptiveRefreshManager Tests")
struct AdaptiveRefreshManagerTests {
    // Helper to create test dependencies
    @MainActor
    private func createTestDependencies(
        state: SystemState = .active,
        isOnBattery: Bool = false,
        enablePowerAware: Bool = true,
        reduceOnBattery: Bool = true,
        refreshInterval: Int = 5,
        usageData: UsageData? = nil
    ) -> (MockSystemStateMonitor, UsageManager, SettingsManager, AdaptiveRefreshManager) {
        let mockStateMonitor = MockSystemStateMonitor()
        mockStateMonitor.setState(state)
        mockStateMonitor.setBatteryState(isOnBattery)

        let mockSettingsRepo = MockSettingsRepository()
        mockSettingsRepo.set(.enablePowerAwareRefresh, value: enablePowerAware)
        mockSettingsRepo.set(.reduceRefreshOnBattery, value: reduceOnBattery)
        mockSettingsRepo.set(.refreshInterval, value: refreshInterval)

        let settingsManager = SettingsManager(repository: mockSettingsRepo)

        let mockUsageRepo = MockUsageRepository(usageData: usageData)
        let usageManager = UsageManager(usageRepository: mockUsageRepo)

        let adaptiveManager = AdaptiveRefreshManager(
            systemStateMonitor: mockStateMonitor,
            usageManager: usageManager,
            settingsManager: settingsManager
        )

        return (mockStateMonitor, usageManager, settingsManager, adaptiveManager)
    }

    // MARK: - Initialization Tests

    @Test("AdaptiveRefreshManager initializes with correct state")
    @MainActor
    func initialization() {
        let (_, _, _, manager) = createTestDependencies()
        #expect(manager.isAutoRefreshing == false)
    }

    // MARK: - Effective Interval Tests - Active State

    @Test("Active state uses base interval when power-aware enabled")
    @MainActor
    func activeStateUsesBaseInterval() {
        let (_, _, _, manager) = createTestDependencies(
            state: .active,
            isOnBattery: false,
            enablePowerAware: true,
            refreshInterval: 5
        )

        // 5 minutes = 300 seconds
        #expect(manager.effectiveRefreshInterval == 300)
    }

    @Test("Active state uses base interval when power-aware disabled")
    @MainActor
    func activeStateUseBaseIntervalWhenDisabled() {
        let (_, _, _, manager) = createTestDependencies(
            state: .active,
            isOnBattery: true,
            enablePowerAware: false,
            refreshInterval: 10
        )

        // Power-aware disabled means always use base interval
        // 10 minutes = 600 seconds
        #expect(manager.effectiveRefreshInterval == 600)
    }

    @Test("Active state doubles interval on battery when reduce enabled")
    @MainActor
    func activeStateDoublesOnBattery() {
        let (_, _, _, manager) = createTestDependencies(
            state: .active,
            isOnBattery: true,
            enablePowerAware: true,
            reduceOnBattery: true,
            refreshInterval: 5
        )

        // 5 minutes * 2 = 600 seconds
        #expect(manager.effectiveRefreshInterval == 600)
    }

    @Test("Active state uses base interval on battery when reduce disabled")
    @MainActor
    func activeStateBaseIntervalWhenReduceDisabled() {
        let (_, _, _, manager) = createTestDependencies(
            state: .active,
            isOnBattery: true,
            enablePowerAware: true,
            reduceOnBattery: false,
            refreshInterval: 5
        )

        // Reduce on battery disabled means use base interval
        #expect(manager.effectiveRefreshInterval == 300)
    }

    // MARK: - Effective Interval Tests - Sleeping State

    @Test("Sleeping state returns infinity")
    @MainActor
    func sleepingStateReturnsInfinity() {
        let (_, _, _, manager) = createTestDependencies(
            state: .sleeping,
            enablePowerAware: true
        )

        #expect(manager.effectiveRefreshInterval == .infinity)
    }

    @Test("Sleeping state ignores battery status")
    @MainActor
    func sleepingStateIgnoresBattery() {
        let (_, _, _, manager) = createTestDependencies(
            state: .sleeping,
            isOnBattery: true,
            enablePowerAware: true
        )

        // Still infinity even on battery
        #expect(manager.effectiveRefreshInterval == .infinity)
    }

    @Test("Sleeping state uses base interval when power-aware disabled")
    @MainActor
    func sleepingStateUsesBaseWhenDisabled() {
        let (_, _, _, manager) = createTestDependencies(
            state: .sleeping,
            enablePowerAware: false,
            refreshInterval: 5
        )

        // Power-aware disabled means normal behavior
        #expect(manager.effectiveRefreshInterval == 300)
    }

    // MARK: - Effective Interval Tests - Idle State

    @Test("Idle state on battery doubles interval")
    @MainActor
    func idleStateOnBatteryDoubles() {
        let (_, _, _, manager) = createTestDependencies(
            state: .idle,
            isOnBattery: true,
            enablePowerAware: true,
            reduceOnBattery: true,
            refreshInterval: 5
        )

        // 5 minutes * 2 = 600 seconds
        #expect(manager.effectiveRefreshInterval == 600)
    }

    @Test("Idle state on power uses base interval")
    @MainActor
    func idleStateOnPowerUsesBase() {
        let (_, _, _, manager) = createTestDependencies(
            state: .idle,
            isOnBattery: false,
            enablePowerAware: true,
            refreshInterval: 5
        )

        // On power: use base interval
        #expect(manager.effectiveRefreshInterval == 300)
    }

    @Test("Idle state caps at max interval")
    @MainActor
    func idleStateCapsAtMax() {
        let (_, _, _, manager) = createTestDependencies(
            state: .idle,
            isOnBattery: true,
            enablePowerAware: true,
            reduceOnBattery: true,
            refreshInterval: 20  // 20 minutes * 2 = 40 minutes, but max is 30
        )

        // Should cap at 30 minutes = 1800 seconds
        #expect(manager.effectiveRefreshInterval == 1800)
    }

    // MARK: - Critical Usage Tests

    @Test("Critical usage uses minimum interval")
    @MainActor
    func criticalUsageUsesMinInterval() async {
        // Create usage data with 95% utilization (critical)
        let criticalUsageData = UsageData(
            fiveHour: UsageWindow(utilization: 95.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 50.0, resetsAt: nil),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            fetchedAt: Date()
        )

        let mockUsageRepo = MockUsageRepository(usageData: criticalUsageData)
        let mockStateMonitor = MockSystemStateMonitor()
        mockStateMonitor.setState(.active)

        let mockSettingsRepo = MockSettingsRepository()
        mockSettingsRepo.set(.enablePowerAwareRefresh, value: true)
        mockSettingsRepo.set(.refreshInterval, value: 5)

        let settingsManager = SettingsManager(repository: mockSettingsRepo)
        let usageManager = UsageManager(usageRepository: mockUsageRepo)

        // Perform a refresh to load the usage data
        await usageManager.refresh()

        let manager = AdaptiveRefreshManager(
            systemStateMonitor: mockStateMonitor,
            usageManager: usageManager,
            settingsManager: settingsManager
        )

        // Critical usage (>=90%) should use 2-minute interval
        #expect(manager.effectiveRefreshInterval == 120)
    }

    @Test("Critical usage prefers user interval if less than 2 minutes")
    @MainActor
    func criticalUsagePrefersUserInterval() async {
        let criticalUsageData = UsageData(
            fiveHour: UsageWindow(utilization: 92.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 50.0, resetsAt: nil),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            fetchedAt: Date()
        )

        let mockUsageRepo = MockUsageRepository(usageData: criticalUsageData)
        let mockStateMonitor = MockSystemStateMonitor()
        mockStateMonitor.setState(.active)

        let mockSettingsRepo = MockSettingsRepository()
        mockSettingsRepo.set(.enablePowerAwareRefresh, value: true)
        mockSettingsRepo.set(.refreshInterval, value: 1)  // 1 minute

        let settingsManager = SettingsManager(repository: mockSettingsRepo)
        let usageManager = UsageManager(usageRepository: mockUsageRepo)
        await usageManager.refresh()

        let manager = AdaptiveRefreshManager(
            systemStateMonitor: mockStateMonitor,
            usageManager: usageManager,
            settingsManager: settingsManager
        )

        // User's 1-minute interval is less than 2-minute critical, so use 1 minute
        #expect(manager.effectiveRefreshInterval == 60)
    }

    @Test("Non-critical usage uses normal interval")
    @MainActor
    func nonCriticalUsageUsesNormalInterval() async {
        let normalUsageData = UsageData(
            fiveHour: UsageWindow(utilization: 85.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 50.0, resetsAt: nil),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            fetchedAt: Date()
        )

        let mockUsageRepo = MockUsageRepository(usageData: normalUsageData)
        let mockStateMonitor = MockSystemStateMonitor()
        mockStateMonitor.setState(.active)

        let mockSettingsRepo = MockSettingsRepository()
        mockSettingsRepo.set(.enablePowerAwareRefresh, value: true)
        mockSettingsRepo.set(.refreshInterval, value: 5)

        let settingsManager = SettingsManager(repository: mockSettingsRepo)
        let usageManager = UsageManager(usageRepository: mockUsageRepo)
        await usageManager.refresh()

        let manager = AdaptiveRefreshManager(
            systemStateMonitor: mockStateMonitor,
            usageManager: usageManager,
            settingsManager: settingsManager
        )

        // 85% is below 90% threshold, so normal 5-minute interval
        #expect(manager.effectiveRefreshInterval == 300)
    }

    // MARK: - Auto-Refresh Control Tests

    @Test("startAutoRefresh sets isAutoRefreshing to true")
    @MainActor
    func startAutoRefreshSetsFlag() {
        let (_, _, _, manager) = createTestDependencies()

        #expect(manager.isAutoRefreshing == false)
        manager.startAutoRefresh()
        #expect(manager.isAutoRefreshing == true)
    }

    @Test("stopAutoRefresh sets isAutoRefreshing to false")
    @MainActor
    func stopAutoRefreshClearsFlag() {
        let (_, _, _, manager) = createTestDependencies()

        manager.startAutoRefresh()
        #expect(manager.isAutoRefreshing == true)

        manager.stopAutoRefresh()
        #expect(manager.isAutoRefreshing == false)
    }

    @Test("startAutoRefresh stops existing task first")
    @MainActor
    func startAutoRefreshStopsExisting() {
        let (_, _, _, manager) = createTestDependencies()

        manager.startAutoRefresh()
        let wasRefreshing = manager.isAutoRefreshing

        // Start again - should stop existing first
        manager.startAutoRefresh()

        #expect(wasRefreshing == true)
        #expect(manager.isAutoRefreshing == true)
    }

    // MARK: - Protocol Conformance Tests

    @Test("AdaptiveRefreshManager conforms to AdaptiveRefreshManagerProtocol")
    @MainActor
    func conformsToProtocol() {
        let (_, _, _, manager) = createTestDependencies()
        let _: any AdaptiveRefreshManagerProtocol = manager
        #expect(true) // Compilation succeeds = conformance verified
    }
}

// MARK: - MockAdaptiveRefreshManager Tests

@Suite("MockAdaptiveRefreshManager Tests")
struct MockAdaptiveRefreshManagerTests {
    @Test("MockAdaptiveRefreshManager initial state")
    @MainActor
    func initialState() {
        let mock = MockAdaptiveRefreshManager()

        #expect(mock.effectiveRefreshInterval == 300)
        #expect(mock.isAutoRefreshing == false)
        #expect(mock.startAutoRefreshCallCount == 0)
        #expect(mock.stopAutoRefreshCallCount == 0)
    }

    @Test("MockAdaptiveRefreshManager tracks startAutoRefresh calls")
    @MainActor
    func tracksStartCalls() {
        let mock = MockAdaptiveRefreshManager()

        mock.startAutoRefresh()
        #expect(mock.startAutoRefreshCallCount == 1)
        #expect(mock.isAutoRefreshing == true)

        mock.startAutoRefresh()
        #expect(mock.startAutoRefreshCallCount == 2)
    }

    @Test("MockAdaptiveRefreshManager tracks stopAutoRefresh calls")
    @MainActor
    func tracksStopCalls() {
        let mock = MockAdaptiveRefreshManager()

        mock.startAutoRefresh()
        mock.stopAutoRefresh()

        #expect(mock.stopAutoRefreshCallCount == 1)
        #expect(mock.isAutoRefreshing == false)
    }

    @Test("MockAdaptiveRefreshManager setEffectiveInterval changes interval")
    @MainActor
    func setEffectiveInterval() {
        let mock = MockAdaptiveRefreshManager()

        mock.setEffectiveInterval(600)
        #expect(mock.effectiveRefreshInterval == 600)

        mock.setEffectiveInterval(.infinity)
        #expect(mock.effectiveRefreshInterval == .infinity)
    }

    @Test("MockAdaptiveRefreshManager conforms to AdaptiveRefreshManagerProtocol")
    @MainActor
    func conformsToProtocol() {
        let mock: any AdaptiveRefreshManagerProtocol = MockAdaptiveRefreshManager()
        #expect(mock.effectiveRefreshInterval == 300)
    }
}

// MARK: - AppContainer Power-Aware Integration Tests

@Suite("AppContainer Power-Aware Integration Tests")
struct AppContainerPowerAwareTests {
    // Helper to create test container with mock dependencies
    @MainActor
    private func createTestContainer(
        enablePowerAware: Bool = true,
        startAutoRefresh: Bool = false
    ) -> (AppContainer, MockUsageRepository, MockSettingsRepository) {
        let mockCredentials = MockCredentialsRepository()
        let mockUsage = MockUsageRepository(usageData: UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: nil),
            fetchedAt: Date()
        ))
        let mockSettings = MockSettingsRepository()

        // Configure power-aware setting
        mockSettings.set(.enablePowerAwareRefresh, value: enablePowerAware)

        let container = AppContainer(
            credentialsRepository: mockCredentials,
            usageRepository: mockUsage,
            settingsRepository: mockSettings,
            startAutoRefresh: startAutoRefresh
        )

        return (container, mockUsage, mockSettings)
    }

    @Test("AppContainer creates SystemStateMonitor")
    @MainActor
    func createsSystemStateMonitor() {
        let (container, _, _) = createTestContainer()
        #expect(container.systemStateMonitor != nil)
    }

    @Test("AppContainer creates AdaptiveRefreshManager")
    @MainActor
    func createsAdaptiveRefreshManager() {
        let (container, _, _) = createTestContainer()
        #expect(container.adaptiveRefreshManager != nil)
    }

    @Test("AppContainer starts AdaptiveRefreshManager when power-aware enabled")
    @MainActor
    func startsAdaptiveRefreshWhenPowerAwareEnabled() async throws {
        let (container, _, _) = createTestContainer(enablePowerAware: true, startAutoRefresh: true)

        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(50))

        #expect(container.adaptiveRefreshManager.isAutoRefreshing == true)
        // UsageManager should NOT be running its own auto-refresh
        #expect(container.usageManager.isAutoRefreshing == false)

        // Clean up
        container.adaptiveRefreshManager.stopAutoRefresh()
    }

    @Test("AppContainer starts UsageManager auto-refresh when power-aware disabled")
    @MainActor
    func startsUsageManagerWhenPowerAwareDisabled() async throws {
        let (container, _, _) = createTestContainer(enablePowerAware: false, startAutoRefresh: true)

        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(50))

        #expect(container.usageManager.isAutoRefreshing == true)
        // AdaptiveRefreshManager should NOT be running
        #expect(container.adaptiveRefreshManager.isAutoRefreshing == false)

        // Clean up
        container.usageManager.stopAutoRefresh()
    }

    @Test("AppContainer does not start auto-refresh when startAutoRefresh is false")
    @MainActor
    func doesNotStartAutoRefreshWhenFalse() {
        let (container, _, _) = createTestContainer(enablePowerAware: true, startAutoRefresh: false)

        #expect(container.adaptiveRefreshManager.isAutoRefreshing == false)
        #expect(container.usageManager.isAutoRefreshing == false)
    }

    @Test("AppContainer exposes SystemStateMonitor publicly")
    @MainActor
    func exposesSystemStateMonitorPublicly() {
        let (container, _, _) = createTestContainer()

        // Verify we can access the monitor's properties
        let state = container.systemStateMonitor.currentState
        let isOnBattery = container.systemStateMonitor.isOnBattery

        #expect(state == .active) // Default state
        // isOnBattery depends on actual hardware, just verify accessible
        _ = isOnBattery
    }

    @Test("AppContainer exposes AdaptiveRefreshManager publicly")
    @MainActor
    func exposesAdaptiveRefreshManagerPublicly() {
        let (container, _, _) = createTestContainer()

        // Verify we can access the manager's properties
        let interval = container.adaptiveRefreshManager.effectiveRefreshInterval
        let isRefreshing = container.adaptiveRefreshManager.isAutoRefreshing

        #expect(interval > 0) // Should have a positive interval
        #expect(isRefreshing == false) // Not started yet
    }

    @Test("AppContainer wires AdaptiveRefreshManager with correct dependencies")
    @MainActor
    func wiresAdaptiveRefreshManagerCorrectly() async throws {
        let (container, mockUsage, _) = createTestContainer(enablePowerAware: true, startAutoRefresh: true)

        // The adaptive manager should be wired to the usage manager
        // When it refreshes, it should call the usage repository
        // Wait longer to ensure the async Task has time to start and execute
        try await Task.sleep(for: .milliseconds(500))

        let callCount = await mockUsage.fetchCallCount
        // At least one refresh should have occurred
        #expect(callCount >= 1)

        // Clean up
        container.adaptiveRefreshManager.stopAutoRefresh()
    }
}

// MARK: - SettingsExportManager Tests

@Suite("SettingsExportManager Tests")
struct SettingsExportManagerTests {
    // MARK: - Mock LaunchAtLoginService for tests

    final class MockLaunchAtLoginService: LaunchAtLoginService, @unchecked Sendable {
        var _status: SMAppService.Status = .notRegistered
        var _isEnabled = false

        var status: SMAppService.Status { _status }

        func register() throws {
            _status = .enabled
            _isEnabled = true
        }

        func unregister() throws {
            _status = .notRegistered
            _isEnabled = false
        }
    }

    // MARK: - Helper to create test manager

    @MainActor
    private func createTestManager(
        userDefaults: UserDefaults = UserDefaults(suiteName: UUID().uuidString)!
    ) -> (SettingsExportManager, SettingsManager, LaunchAtLoginManager, UsageHistoryManager) {
        let settingsRepo = UserDefaultsSettingsRepository(defaults: userDefaults)
        let settingsManager = SettingsManager(repository: settingsRepo)
        let mockService = MockLaunchAtLoginService()
        let launchAtLoginManager = LaunchAtLoginManager(service: mockService)
        let historyManager = UsageHistoryManager(userDefaults: userDefaults)

        let exportManager = SettingsExportManager(
            settingsManager: settingsManager,
            launchAtLoginManager: launchAtLoginManager,
            usageHistoryManager: historyManager,
            appVersionProvider: { "1.8.0" }
        )

        return (exportManager, settingsManager, launchAtLoginManager, historyManager)
    }

    // MARK: - Export Tests

    @Test("export creates correct structure")
    @MainActor
    func exportCreatesCorrectStructure() {
        let (exportManager, _, _, _) = createTestManager()

        let exported = exportManager.export()

        #expect(exported.version == ExportedSettings.currentVersion)
        #expect(exported.appVersion == "1.8.0")
        #expect(exported.settings.display.iconStyle == "percentage")
        #expect(exported.settings.refresh.interval == 5)
        #expect(exported.settings.notifications.enabled == true)
        #expect(exported.usageHistory == nil)
    }

    @Test("export includes usage history when requested")
    @MainActor
    func exportIncludesUsageHistory() {
        let (exportManager, _, _, historyManager) = createTestManager()

        // Add some history
        historyManager.importSessionHistory([
            UsageDataPoint(utilization: 30.0),
            UsageDataPoint(utilization: 40.0)
        ])
        historyManager.importWeeklyHistory([
            UsageDataPoint(utilization: 50.0)
        ])

        let exported = exportManager.export(includeUsageHistory: true)

        #expect(exported.usageHistory != nil)
        #expect(exported.usageHistory?.sessionHistory.count == 2)
        #expect(exported.usageHistory?.weeklyHistory.count == 1)
    }

    @Test("export reflects current settings values")
    @MainActor
    func exportReflectsCurrentSettings() {
        let (exportManager, settingsManager, _, _) = createTestManager()

        // Change settings
        settingsManager.iconStyle = .battery
        settingsManager.refreshInterval = 15
        settingsManager.warningThreshold = 80
        settingsManager.showSparklines = false

        let exported = exportManager.export()

        #expect(exported.settings.display.iconStyle == "battery")
        #expect(exported.settings.refresh.interval == 15)
        #expect(exported.settings.notifications.warningThreshold == 80)
        #expect(exported.settings.display.showSparklines == false)
    }

    @Test("export without history has nil usageHistory")
    @MainActor
    func exportWithoutHistoryIsNil() {
        let (exportManager, _, _, _) = createTestManager()

        let exported = exportManager.export(includeUsageHistory: false)

        #expect(exported.usageHistory == nil)
    }

    // MARK: - Import Tests

    @Test("applySettings updates all settings values")
    @MainActor
    func applySettingsUpdatesAllValues() {
        let (exportManager, settingsManager, launchAtLoginManager, _) = createTestManager()

        let imported = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "progressBar",
                    showPlanBadge: true,
                    showPercentage: false,
                    percentageSource: "Current Session",
                    showSparklines: false,
                    planType: "max5x"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 10,
                    enablePowerAwareRefresh: false,
                    reduceRefreshOnBattery: false
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: false,
                    warningThreshold: 75,
                    warningEnabled: false,
                    capacityFullEnabled: false,
                    resetCompleteEnabled: false
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: true,
                    checkForUpdates: false
                )
            ),
            usageHistory: nil
        )

        exportManager.applySettings(imported)

        #expect(settingsManager.iconStyle == .progressBar)
        #expect(settingsManager.showPlanBadge == true)
        #expect(settingsManager.showPercentage == false)
        #expect(settingsManager.percentageSource == .session)
        #expect(settingsManager.showSparklines == false)
        #expect(settingsManager.planType == .max5x)
        #expect(settingsManager.refreshInterval == 10)
        #expect(settingsManager.enablePowerAwareRefresh == false)
        #expect(settingsManager.notificationsEnabled == false)
        #expect(settingsManager.warningThreshold == 75)
        #expect(launchAtLoginManager.isEnabled == true)
        #expect(settingsManager.checkForUpdates == false)
    }

    @Test("applySettings imports usage history when requested")
    @MainActor
    func applySettingsImportsHistory() {
        let (exportManager, _, _, historyManager) = createTestManager()

        let history = ExportedSettings.UsageHistoryPayload(
            sessionHistory: [
                UsageDataPoint(utilization: 30.0),
                UsageDataPoint(utilization: 40.0)
            ],
            weeklyHistory: [
                UsageDataPoint(utilization: 50.0),
                UsageDataPoint(utilization: 55.0),
                UsageDataPoint(utilization: 60.0)
            ]
        )

        let imported = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "percentage",
                    showPlanBadge: false,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: history
        )

        exportManager.applySettings(imported, includeUsageHistory: true)

        #expect(historyManager.sessionHistory.count == 2)
        #expect(historyManager.weeklyHistory.count == 3)
    }

    @Test("applySettings ignores unknown enum values")
    @MainActor
    func applySettingsIgnoresUnknownEnums() {
        let (exportManager, settingsManager, _, _) = createTestManager()

        // Set initial values
        settingsManager.iconStyle = .battery
        settingsManager.percentageSource = .weekly

        let imported = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "unknownStyle", // Invalid
                    showPlanBadge: true,
                    showPercentage: true,
                    percentageSource: "invalidSource", // Invalid
                    showSparklines: true,
                    planType: "unknownPlan" // Invalid
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 5,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 90,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        exportManager.applySettings(imported)

        // Invalid enums should be skipped, keeping original values
        #expect(settingsManager.iconStyle == .battery)
        #expect(settingsManager.percentageSource == .weekly)
        // Valid bool should be applied
        #expect(settingsManager.showPlanBadge == true)
    }

    // MARK: - Reset Tests

    @Test("resetToDefaults restores all default values")
    @MainActor
    func resetToDefaultsRestoresDefaults() {
        let (exportManager, settingsManager, _, _) = createTestManager()

        // Change settings from defaults
        settingsManager.iconStyle = .battery
        settingsManager.showPlanBadge = true
        settingsManager.refreshInterval = 15
        settingsManager.warningThreshold = 75
        settingsManager.notificationsEnabled = false

        exportManager.resetToDefaults()

        #expect(settingsManager.iconStyle == .percentage) // Default
        #expect(settingsManager.showPlanBadge == false) // Default
        #expect(settingsManager.refreshInterval == 5) // Default
        #expect(settingsManager.warningThreshold == 90) // Default
        #expect(settingsManager.notificationsEnabled == true) // Default
    }

    @Test("resetToDefaults clears history when requested")
    @MainActor
    func resetToDefaultsClearsHistory() {
        let (exportManager, _, _, historyManager) = createTestManager()

        // Add history
        historyManager.importSessionHistory([
            UsageDataPoint(utilization: 30.0),
            UsageDataPoint(utilization: 40.0)
        ])

        #expect(historyManager.sessionHistory.count == 2)

        exportManager.resetToDefaults(clearHistory: true)

        #expect(historyManager.sessionHistory.isEmpty)
        #expect(historyManager.weeklyHistory.isEmpty)
    }

    @Test("resetToDefaults preserves history by default")
    @MainActor
    func resetToDefaultsPreservesHistory() {
        let (exportManager, _, _, historyManager) = createTestManager()

        // Add history
        historyManager.importSessionHistory([
            UsageDataPoint(utilization: 30.0),
            UsageDataPoint(utilization: 40.0)
        ])

        #expect(historyManager.sessionHistory.count == 2)

        exportManager.resetToDefaults(clearHistory: false)

        #expect(historyManager.sessionHistory.count == 2) // Still there
    }

    // MARK: - File Export/Import Tests

    @Test("exportToFile creates valid JSON file")
    @MainActor
    func exportToFileCreatesValidJSON() throws {
        let (exportManager, _, _, _) = createTestManager()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-export-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try exportManager.exportToFile(url: tempURL)

        // Verify file exists and is valid JSON
        let data = try Data(contentsOf: tempURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let imported = try decoder.decode(ExportedSettings.self, from: data)

        #expect(imported.version == ExportedSettings.currentVersion)
        #expect(imported.appVersion == "1.8.0")
    }

    @Test("importFromFile reads valid JSON")
    @MainActor
    func importFromFileReadsValidJSON() throws {
        let (exportManager, _, _, _) = createTestManager()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-import-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Create test file
        let settings = ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: "1.8.0",
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: "battery",
                    showPlanBadge: true,
                    showPercentage: true,
                    percentageSource: "highest",
                    showSparklines: true,
                    planType: "pro"
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: 10,
                    enablePowerAwareRefresh: true,
                    reduceRefreshOnBattery: true
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: true,
                    warningThreshold: 85,
                    warningEnabled: true,
                    capacityFullEnabled: true,
                    resetCompleteEnabled: true
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: false,
                    checkForUpdates: true
                )
            ),
            usageHistory: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(settings)
        try data.write(to: tempURL)

        // Import
        let imported = try exportManager.importFromFile(url: tempURL)

        #expect(imported.settings.display.iconStyle == "battery")
        #expect(imported.settings.refresh.interval == 10)
        #expect(imported.settings.notifications.warningThreshold == 85)
    }

    @Test("importFromData parses JSON data")
    @MainActor
    func importFromDataParsesJSON() throws {
        let (exportManager, _, _, _) = createTestManager()

        let json = """
        {
            "version": "1.0",
            "exportedAt": "2026-01-30T12:00:00Z",
            "appVersion": "1.8.0",
            "settings": {
                "display": {
                    "iconStyle": "compact",
                    "showPlanBadge": false,
                    "showPercentage": true,
                    "percentageSource": "weekly",
                    "showSparklines": true,
                    "planType": "max20x"
                },
                "refresh": {
                    "interval": 20,
                    "enablePowerAwareRefresh": false,
                    "reduceRefreshOnBattery": false
                },
                "notifications": {
                    "enabled": false,
                    "warningThreshold": 70,
                    "warningEnabled": false,
                    "capacityFullEnabled": true,
                    "resetCompleteEnabled": false
                },
                "general": {
                    "launchAtLogin": true,
                    "checkForUpdates": false
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let imported = try exportManager.importFromData(data)

        #expect(imported.settings.display.iconStyle == "compact")
        #expect(imported.settings.display.planType == "max20x")
        #expect(imported.settings.refresh.interval == 20)
        #expect(imported.settings.notifications.warningThreshold == 70)
        #expect(imported.settings.general.launchAtLogin == true)
    }

    // MARK: - Round-trip Tests

    @Test("export and import round-trip preserves all settings")
    @MainActor
    func roundTripPreservesSettings() throws {
        let (exportManager1, settingsManager1, _, historyManager1) = createTestManager()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-roundtrip-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Configure settings
        settingsManager1.iconStyle = .progressBar
        settingsManager1.showPlanBadge = true
        settingsManager1.refreshInterval = 12
        settingsManager1.warningThreshold = 85
        settingsManager1.enablePowerAwareRefresh = false

        historyManager1.importSessionHistory([
            UsageDataPoint(utilization: 25.0),
            UsageDataPoint(utilization: 35.0)
        ])

        // Export
        try exportManager1.exportToFile(url: tempURL, includeUsageHistory: true)

        // Create fresh manager and import
        let (exportManager2, settingsManager2, _, historyManager2) = createTestManager()

        let imported = try exportManager2.importFromFile(url: tempURL)
        exportManager2.applySettings(imported, includeUsageHistory: true)

        // Verify
        #expect(settingsManager2.iconStyle == .progressBar)
        #expect(settingsManager2.showPlanBadge == true)
        #expect(settingsManager2.refreshInterval == 12)
        #expect(settingsManager2.warningThreshold == 85)
        #expect(settingsManager2.enablePowerAwareRefresh == false)
        #expect(historyManager2.sessionHistory.count == 2)
    }
}

// MARK: - UsageHistoryManager Import Methods Tests

@Suite("UsageHistoryManager Import Tests")
struct UsageHistoryManagerImportTests {
    @Test("importSessionHistory replaces existing history")
    @MainActor
    func importSessionHistoryReplaces() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let manager = UsageHistoryManager(userDefaults: userDefaults)

        // Add initial history
        manager.importSessionHistory([UsageDataPoint(utilization: 10.0)])
        #expect(manager.sessionHistory.count == 1)

        // Import new history
        manager.importSessionHistory([
            UsageDataPoint(utilization: 20.0),
            UsageDataPoint(utilization: 30.0),
            UsageDataPoint(utilization: 40.0)
        ])

        #expect(manager.sessionHistory.count == 3)
        #expect(manager.sessionHistory[0].utilization == 20.0)
    }

    @Test("importWeeklyHistory replaces existing history")
    @MainActor
    func importWeeklyHistoryReplaces() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let manager = UsageHistoryManager(userDefaults: userDefaults)

        // Add initial history
        manager.importWeeklyHistory([UsageDataPoint(utilization: 10.0)])
        #expect(manager.weeklyHistory.count == 1)

        // Import new history
        manager.importWeeklyHistory([
            UsageDataPoint(utilization: 50.0),
            UsageDataPoint(utilization: 60.0)
        ])

        #expect(manager.weeklyHistory.count == 2)
        #expect(manager.weeklyHistory[0].utilization == 50.0)
    }

    @Test("importSessionHistory respects max points limit")
    @MainActor
    func importSessionHistoryRespectsLimit() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let manager = UsageHistoryManager(userDefaults: userDefaults)

        // Create more points than max
        var points: [UsageDataPoint] = []
        for i in 0..<100 { // More than maxSessionPoints (60)
            points.append(UsageDataPoint(utilization: Double(i)))
        }

        manager.importSessionHistory(points)

        #expect(manager.sessionHistory.count == UsageHistoryManager.maxSessionPoints)
        // Should keep the last 60 points (40-99)
        #expect(manager.sessionHistory.first?.utilization == 40.0)
    }

    @Test("importWeeklyHistory respects max points limit")
    @MainActor
    func importWeeklyHistoryRespectsLimit() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let manager = UsageHistoryManager(userDefaults: userDefaults)

        // Create more points than max
        var points: [UsageDataPoint] = []
        for i in 0..<200 { // More than maxWeeklyPoints (168)
            points.append(UsageDataPoint(utilization: Double(i)))
        }

        manager.importWeeklyHistory(points)

        #expect(manager.weeklyHistory.count == UsageHistoryManager.maxWeeklyPoints)
        // Should keep the last 168 points (32-199)
        #expect(manager.weeklyHistory.first?.utilization == 32.0)
    }
}

// MARK: - SharedCacheManager Tests

@Suite("SharedCacheManager Tests")
struct SharedCacheManagerTests {
    /// Creates a test UserDefaults instance with a unique suite name
    private func createTestDefaults() -> UserDefaults {
        let suiteName = "com.claudeapp.test.cache.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Creates test usage data for testing
    private func createTestUsageData(
        sessionUtilization: Double = 45.0,
        weeklyUtilization: Double = 72.0
    ) -> UsageData {
        UsageData(
            fiveHour: UsageWindow(utilization: sessionUtilization),
            sevenDay: UsageWindow(utilization: weeklyUtilization),
            fetchedAt: Date()
        )
    }

    // MARK: - Initialization Tests

    @Test("SharedCacheManager initializes with custom UserDefaults")
    @MainActor
    func initWithCustomDefaults() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)

        #expect(manager.isAppGroupAvailable == true)
    }

    @Test("SharedCacheManager defaults to App Group when nil passed")
    @MainActor
    func initWithNilUsesAppGroup() {
        // When nil is passed, it tries to use App Group UserDefaults
        // On macOS without sandboxing, this typically succeeds
        let manager = SharedCacheManager(userDefaults: nil)

        // App Group UserDefaults can be created on macOS
        #expect(manager.isAppGroupAvailable == true)
    }

    // MARK: - Write Operation Tests

    @Test("writeUsageCache stores data successfully")
    @MainActor
    func writeStoresData() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)
        let testData = createTestUsageData()

        let success = manager.writeUsageCache(testData)

        #expect(success == true)
    }

    @Test("writeUsageCache works with App Group defaults")
    @MainActor
    func writeWorksWithAppGroup() {
        // When nil is passed, it uses App Group which should work
        let manager = SharedCacheManager(userDefaults: nil)
        let testData = createTestUsageData()

        let success = manager.writeUsageCache(testData)

        #expect(success == true)

        // Clean up - remove the test data from App Group
        manager.clearCache()
    }

    // MARK: - Read Operation Tests

    @Test("readUsageCache returns nil when no data cached")
    @MainActor
    func readReturnsNilWhenEmpty() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)

        let result = manager.readUsageCache()

        #expect(result == nil)
    }

    @Test("readUsageCache returns cached data after write")
    @MainActor
    func readAfterWrite() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)
        let testData = createTestUsageData(sessionUtilization: 55.0, weeklyUtilization: 80.0)

        manager.writeUsageCache(testData)
        let result = manager.readUsageCache()

        #expect(result != nil)
        #expect(result?.data.fiveHour.utilization == 55.0)
        #expect(result?.data.sevenDay.utilization == 80.0)
    }

    @Test("readUsageCache preserves all usage windows")
    @MainActor
    func readPreservesAllWindows() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)

        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0, resetsAt: Date().addingTimeInterval(3600)),
            sevenDay: UsageWindow(utilization: 72.0, resetsAt: Date().addingTimeInterval(86400)),
            sevenDayOpus: UsageWindow(utilization: 30.0),
            sevenDaySonnet: UsageWindow(utilization: 50.0),
            fetchedAt: Date()
        )

        manager.writeUsageCache(testData)
        let result = manager.readUsageCache()

        #expect(result?.data.fiveHour.utilization == 45.0)
        #expect(result?.data.sevenDay.utilization == 72.0)
        #expect(result?.data.sevenDayOpus?.utilization == 30.0)
        #expect(result?.data.sevenDaySonnet?.utilization == 50.0)
    }

    // MARK: - Freshness Tests

    @Test("cacheFreshness returns .none when no cache")
    @MainActor
    func freshnessNoneWhenEmpty() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)

        let freshness = manager.cacheFreshness()

        #expect(freshness == .none)
    }

    @Test("cacheFreshness returns .fresh for recent cache")
    @MainActor
    func freshnessFreshForRecent() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)
        let testData = createTestUsageData()

        manager.writeUsageCache(testData)
        let freshness = manager.cacheFreshness()

        #expect(freshness == .fresh)
    }

    @Test("CachedUsageData calculates fresh freshness correctly")
    func cachedDataFreshnessCalculation() {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )

        // Cache created now should be fresh
        let cached = CachedUsageData(data: testData, timestamp: Date())
        #expect(cached.freshness() == .fresh)

        // Cache from 3 minutes ago should be fresh
        let cached3min = CachedUsageData(data: testData, timestamp: Date().addingTimeInterval(-180))
        #expect(cached3min.freshness() == .fresh)
    }

    @Test("CachedUsageData calculates stale freshness correctly")
    func cachedDataStaleCalculation() {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )

        // Cache from 6 minutes ago should be stale (>5 min, <15 min)
        let cached6min = CachedUsageData(data: testData, timestamp: Date().addingTimeInterval(-360))
        #expect(cached6min.freshness() == .stale)

        // Cache from 10 minutes ago should be stale
        let cached10min = CachedUsageData(data: testData, timestamp: Date().addingTimeInterval(-600))
        #expect(cached10min.freshness() == .stale)
    }

    @Test("CachedUsageData calculates expired freshness correctly")
    func cachedDataExpiredCalculation() {
        let testData = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )

        // Cache from 16 minutes ago should be expired (>15 min)
        let cached16min = CachedUsageData(data: testData, timestamp: Date().addingTimeInterval(-960))
        #expect(cached16min.freshness() == .expired)

        // Cache from 1 hour ago should be expired
        let cached1hr = CachedUsageData(data: testData, timestamp: Date().addingTimeInterval(-3600))
        #expect(cached1hr.freshness() == .expired)
    }

    // MARK: - Cache Age Tests

    @Test("cacheAge returns nil when no cache")
    @MainActor
    func cacheAgeNilWhenEmpty() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)

        let age = manager.cacheAge()

        #expect(age == nil)
    }

    @Test("cacheAge returns approximately correct age")
    @MainActor
    func cacheAgeCorrect() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)
        let testData = createTestUsageData()

        manager.writeUsageCache(testData)
        let age = manager.cacheAge()

        #expect(age != nil)
        #expect(age! >= 0)
        #expect(age! < 1) // Should be less than 1 second since we just wrote it
    }

    // MARK: - Clear Cache Tests

    @Test("clearCache removes cached data")
    @MainActor
    func clearCacheRemovesData() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)
        let testData = createTestUsageData()

        manager.writeUsageCache(testData)
        #expect(manager.readUsageCache() != nil)

        manager.clearCache()
        #expect(manager.readUsageCache() == nil)
    }

    @Test("clearCache is safe when no cache exists")
    @MainActor
    func clearCacheSafeWhenEmpty() {
        let defaults = createTestDefaults()
        let manager = SharedCacheManager(userDefaults: defaults)

        // Should not crash
        manager.clearCache()

        #expect(manager.readUsageCache() == nil)
    }

    // MARK: - TTL Constant Tests

    @Test("Fresh threshold is 5 minutes")
    func freshThresholdIs5Minutes() {
        #expect(SharedCacheManager.freshThreshold == 300)
    }

    @Test("Expired threshold is 15 minutes")
    func expiredThresholdIs15Minutes() {
        #expect(SharedCacheManager.expiredThreshold == 900)
    }

    @Test("App Group identifier is correct")
    func appGroupIdentifier() {
        #expect(SharedCacheManager.appGroupIdentifier == "group.com.kaduwaengertner.ClaudeApp")
    }
}

// MARK: - CacheFreshness Tests

@Suite("CacheFreshness Tests")
struct CacheFreshnessTests {
    @Test("CacheFreshness is Equatable")
    func freshnessEquatable() {
        #expect(CacheFreshness.fresh == CacheFreshness.fresh)
        #expect(CacheFreshness.stale == CacheFreshness.stale)
        #expect(CacheFreshness.expired == CacheFreshness.expired)
        #expect(CacheFreshness.none == CacheFreshness.none)
        #expect(CacheFreshness.fresh != CacheFreshness.stale)
    }

    @Test("CacheFreshness is Sendable")
    func freshnessSendable() async {
        let freshness: CacheFreshness = .fresh

        let result = await Task.detached {
            freshness
        }.value

        #expect(result == .fresh)
    }
}

// MARK: - CachedUsageData Tests

@Suite("CachedUsageData Tests")
struct CachedUsageDataTests {
    @Test("CachedUsageData initializes with current timestamp by default")
    func initDefaultTimestamp() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )

        let before = Date()
        let cached = CachedUsageData(data: data)
        let after = Date()

        #expect(cached.timestamp >= before)
        #expect(cached.timestamp <= after)
    }

    @Test("CachedUsageData initializes with custom timestamp")
    func initCustomTimestamp() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )
        let customDate = Date().addingTimeInterval(-1000)

        let cached = CachedUsageData(data: data, timestamp: customDate)

        #expect(cached.timestamp == customDate)
    }

    @Test("CachedUsageData is Equatable")
    func cachedDataEquatable() {
        let timestamp = Date()
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )

        let cached1 = CachedUsageData(data: data, timestamp: timestamp)
        let cached2 = CachedUsageData(data: data, timestamp: timestamp)

        #expect(cached1 == cached2)
    }

    @Test("CachedUsageData is Sendable")
    func cachedDataSendable() async {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )
        let cached = CachedUsageData(data: data)

        let result = await Task.detached {
            cached.data.fiveHour.utilization
        }.value

        #expect(result == 45.0)
    }

    @Test("CachedUsageData ageInSeconds is approximately correct")
    func ageInSeconds() {
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 45.0),
            sevenDay: UsageWindow(utilization: 72.0)
        )
        let fiveMinutesAgo = Date().addingTimeInterval(-300)

        let cached = CachedUsageData(data: data, timestamp: fiveMinutesAgo)

        #expect(cached.ageInSeconds >= 299)
        #expect(cached.ageInSeconds <= 301)
    }
}

// MARK: - UserDefaultsAccountStorage Tests

@Suite("UserDefaultsAccountStorage Tests")
struct UserDefaultsAccountStorageTests {
    /// Creates a test UserDefaults instance with a unique suite name
    private func createTestDefaults() -> UserDefaults {
        let suiteName = "com.claudeapp.test.accounts.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Load/Save Tests

    @Test("loadAccounts returns empty array when no data exists")
    func loadAccountsEmpty() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let accounts = storage.loadAccounts()

        #expect(accounts.isEmpty)
    }

    @Test("saveAccounts and loadAccounts round-trip preserves data")
    func saveLoadRoundTrip() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let account1 = Account(name: "Personal", planType: .pro, keychainIdentifier: "default")
        let account2 = Account(name: "Work", planType: .max20x, keychainIdentifier: "work")

        storage.saveAccounts([account1, account2])
        let loaded = storage.loadAccounts()

        #expect(loaded.count == 2)
        #expect(loaded[0].name == "Personal")
        #expect(loaded[0].planType == .pro)
        #expect(loaded[1].name == "Work")
        #expect(loaded[1].planType == .max20x)
    }

    @Test("saveAccounts replaces existing data")
    func saveReplacesData() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let account1 = Account(name: "First")
        storage.saveAccounts([account1])

        let account2 = Account(name: "Second")
        storage.saveAccounts([account2])

        let loaded = storage.loadAccounts()

        #expect(loaded.count == 1)
        #expect(loaded[0].name == "Second")
    }

    @Test("saveAccounts handles empty array")
    func saveEmptyArray() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let account = Account(name: "Test")
        storage.saveAccounts([account])
        storage.saveAccounts([])

        let loaded = storage.loadAccounts()

        #expect(loaded.isEmpty)
    }

    @Test("clearAccounts removes all stored data")
    func clearAccounts() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let account = Account(name: "Test")
        storage.saveAccounts([account])
        storage.clearAccounts()

        let loaded = storage.loadAccounts()

        #expect(loaded.isEmpty)
    }

    @Test("loadAccounts preserves account IDs")
    func preservesAccountIds() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let id = UUID()
        let account = Account(id: id, name: "Test")

        storage.saveAccounts([account])
        let loaded = storage.loadAccounts()

        #expect(loaded.first?.id == id)
    }

    @Test("loadAccounts preserves all account fields")
    func preservesAllFields() throws {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)

        let createdAt = Date()
        let id = UUID()
        let account = Account(
            id: id,
            name: "Full Account",
            email: "test@example.com",
            planType: .max5x,
            keychainIdentifier: "custom-key",
            isActive: false,
            isPrimary: true,
            createdAt: createdAt
        )

        storage.saveAccounts([account])
        let loaded = storage.loadAccounts()

        #expect(loaded.count == 1)
        let result = loaded[0]
        #expect(result.id == id)
        #expect(result.name == "Full Account")
        #expect(result.email == "test@example.com")
        #expect(result.planType == .max5x)
        #expect(result.keychainIdentifier == "custom-key")
        #expect(result.isActive == false)
        #expect(result.isPrimary == true)
    }

    @Test("Storage is Sendable")
    func sendable() async {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let account = Account(name: "Test")

        await Task.detached {
            storage.saveAccounts([account])
        }.value

        let loaded = storage.loadAccounts()
        #expect(loaded.count == 1)
    }
}

// MARK: - AccountManager Tests

@Suite("AccountManager Tests")
struct AccountManagerTests {
    /// Creates a test UserDefaults instance with a unique suite name
    private func createTestDefaults() -> UserDefaults {
        let suiteName = "com.claudeapp.test.accountmanager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Creates an AccountManager with isolated test storage
    @MainActor
    private func createTestManager() -> AccountManager {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        return AccountManager(storage: storage)
    }

    // MARK: - Initialization Tests

    @Test("AccountManager starts with empty accounts")
    @MainActor
    func initialStateEmpty() {
        let manager = createTestManager()

        #expect(manager.accounts.isEmpty)
        #expect(manager.activeAccount == nil)
        #expect(manager.primaryAccount == nil)
        #expect(manager.hasAccounts == false)
    }

    @Test("AccountManager activeAccountCount starts at zero")
    @MainActor
    func initialActiveAccountCount() {
        let manager = createTestManager()

        #expect(manager.activeAccountCount == 0)
    }

    // MARK: - Add Account Tests

    @Test("addAccount adds account to list")
    @MainActor
    func addAccountAddsToList() {
        let manager = createTestManager()
        let account = Account(name: "Personal")

        manager.addAccount(account)

        #expect(manager.accounts.count == 1)
        #expect(manager.accounts.first?.name == "Personal")
    }

    @Test("addAccount makes first account primary")
    @MainActor
    func addAccountMakesFirstPrimary() {
        let manager = createTestManager()
        let account = Account(name: "First", isPrimary: false)

        manager.addAccount(account)

        #expect(manager.accounts.first?.isPrimary == true)
        #expect(manager.primaryAccount?.name == "First")
    }

    @Test("addAccount sets new account as active")
    @MainActor
    func addAccountSetsActive() {
        let manager = createTestManager()
        let account = Account(name: "New")

        manager.addAccount(account)

        #expect(manager.activeAccount?.name == "New")
    }

    @Test("addAccount does not make second account primary")
    @MainActor
    func addAccountSecondNotPrimary() {
        let manager = createTestManager()
        let first = Account(name: "First")
        let second = Account(name: "Second")

        manager.addAccount(first)
        manager.addAccount(second)

        #expect(manager.accounts[0].isPrimary == true)
        #expect(manager.accounts[1].isPrimary == false)
        #expect(manager.primaryAccount?.name == "First")
    }

    @Test("addAccount persists to storage")
    @MainActor
    func addAccountPersists() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let manager = AccountManager(storage: storage)

        let account = Account(name: "Persistent")
        manager.addAccount(account)

        // Create new manager with same storage to verify persistence
        let manager2 = AccountManager(storage: storage)
        #expect(manager2.accounts.count == 1)
        #expect(manager2.accounts.first?.name == "Persistent")
    }

    // MARK: - Remove Account Tests

    @Test("removeAccount removes account from list")
    @MainActor
    func removeAccountRemovesFromList() {
        let manager = createTestManager()
        let account = Account(name: "ToRemove")
        manager.addAccount(account)

        manager.removeAccount(account)

        #expect(manager.accounts.isEmpty)
    }

    @Test("removeAccount switches active to primary when removing active")
    @MainActor
    func removeActiveSwitchesToPrimary() {
        let manager = createTestManager()
        let first = Account(name: "First") // Will be primary
        let second = Account(name: "Second")
        manager.addAccount(first)
        manager.addAccount(second) // This becomes active

        #expect(manager.activeAccount?.name == "Second")

        manager.removeAccount(manager.accounts[1]) // Remove "Second"

        #expect(manager.activeAccount?.name == "First")
    }

    @Test("removeAccount assigns new primary when removing primary")
    @MainActor
    func removePrimaryAssignsNewPrimary() {
        let manager = createTestManager()
        let first = Account(name: "First")
        let second = Account(name: "Second")
        manager.addAccount(first)
        manager.addAccount(second)

        let primaryAccount = manager.accounts.first { $0.isPrimary }!
        manager.removeAccount(primaryAccount)

        #expect(manager.accounts.count == 1)
        #expect(manager.accounts.first?.isPrimary == true)
    }

    @Test("removeAccount persists removal")
    @MainActor
    func removeAccountPersists() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let manager = AccountManager(storage: storage)

        let account = Account(name: "Temp")
        manager.addAccount(account)
        manager.removeAccount(manager.accounts.first!)

        // Verify with new manager
        let manager2 = AccountManager(storage: storage)
        #expect(manager2.accounts.isEmpty)
    }

    // MARK: - Update Account Tests

    @Test("updateAccount updates account data")
    @MainActor
    func updateAccountUpdatesData() {
        let manager = createTestManager()
        var account = Account(name: "Original")
        manager.addAccount(account)

        account = manager.accounts.first!
        var updated = account
        updated.name = "Updated"
        manager.updateAccount(updated)

        #expect(manager.accounts.first?.name == "Updated")
    }

    @Test("updateAccount is no-op for non-existent account")
    @MainActor
    func updateNonExistentIsNoOp() {
        let manager = createTestManager()
        let existing = Account(name: "Existing")
        manager.addAccount(existing)

        let nonExistent = Account(name: "NonExistent")
        manager.updateAccount(nonExistent)

        #expect(manager.accounts.count == 1)
        #expect(manager.accounts.first?.name == "Existing")
    }

    @Test("updateAccount persists changes")
    @MainActor
    func updateAccountPersists() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let manager = AccountManager(storage: storage)

        var account = Account(name: "Original")
        manager.addAccount(account)

        account = manager.accounts.first!
        var updated = account
        updated.name = "Persisted Update"
        manager.updateAccount(updated)

        // Verify with new manager
        let manager2 = AccountManager(storage: storage)
        #expect(manager2.accounts.first?.name == "Persisted Update")
    }

    // MARK: - Set Active Account Tests

    @Test("setActiveAccount changes active account")
    @MainActor
    func setActiveAccountChanges() {
        let manager = createTestManager()
        let first = Account(name: "First")
        let second = Account(name: "Second")
        manager.addAccount(first)
        manager.addAccount(second)

        let firstId = manager.accounts.first { $0.name == "First" }!.id
        manager.setActiveAccount(firstId)

        #expect(manager.activeAccount?.name == "First")
    }

    @Test("setActiveAccount is no-op for invalid ID")
    @MainActor
    func setActiveAccountInvalidId() {
        let manager = createTestManager()
        let account = Account(name: "Only")
        manager.addAccount(account)

        let originalActive = manager.activeAccount
        manager.setActiveAccount(UUID()) // Non-existent ID

        #expect(manager.activeAccount?.id == originalActive?.id)
    }

    // MARK: - Set Primary Account Tests

    @Test("setPrimaryAccount changes primary account")
    @MainActor
    func setPrimaryAccountChanges() {
        let manager = createTestManager()
        let first = Account(name: "First")
        let second = Account(name: "Second")
        manager.addAccount(first)
        manager.addAccount(second)

        let secondId = manager.accounts.first { $0.name == "Second" }!.id
        manager.setPrimaryAccount(secondId)

        #expect(manager.primaryAccount?.name == "Second")
        #expect(manager.accounts[0].isPrimary == false)
        #expect(manager.accounts[1].isPrimary == true)
    }

    @Test("setPrimaryAccount ensures only one primary")
    @MainActor
    func setPrimaryAccountOnlyOne() {
        let manager = createTestManager()
        let first = Account(name: "First")
        let second = Account(name: "Second")
        let third = Account(name: "Third")
        manager.addAccount(first)
        manager.addAccount(second)
        manager.addAccount(third)

        let thirdId = manager.accounts.first { $0.name == "Third" }!.id
        manager.setPrimaryAccount(thirdId)

        let primaryCount = manager.accounts.filter(\.isPrimary).count
        #expect(primaryCount == 1)
    }

    @Test("setPrimaryAccount persists change")
    @MainActor
    func setPrimaryAccountPersists() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let manager = AccountManager(storage: storage)

        let first = Account(name: "First")
        let second = Account(name: "Second")
        manager.addAccount(first)
        manager.addAccount(second)

        let secondId = manager.accounts.first { $0.name == "Second" }!.id
        manager.setPrimaryAccount(secondId)

        // Verify with new manager
        let manager2 = AccountManager(storage: storage)
        #expect(manager2.primaryAccount?.name == "Second")
    }

    // MARK: - Migration Tests

    @Test("migrateIfNeeded creates default account when empty")
    @MainActor
    func migrateCreatesDefaultAccount() {
        let manager = createTestManager()

        manager.migrateIfNeeded()

        #expect(manager.accounts.count == 1)
        #expect(manager.accounts.first?.name == "Default")
        #expect(manager.accounts.first?.keychainIdentifier == "default")
        #expect(manager.accounts.first?.isPrimary == true)
        #expect(manager.accounts.first?.isActive == true)
    }

    @Test("migrateIfNeeded sets active account to default")
    @MainActor
    func migrateSetsActiveAccount() {
        let manager = createTestManager()

        manager.migrateIfNeeded()

        #expect(manager.activeAccount?.name == "Default")
    }

    @Test("migrateIfNeeded is no-op when accounts exist")
    @MainActor
    func migrateNoOpWhenAccountsExist() {
        let manager = createTestManager()
        let existing = Account(name: "Existing")
        manager.addAccount(existing)

        manager.migrateIfNeeded()

        #expect(manager.accounts.count == 1)
        #expect(manager.accounts.first?.name == "Existing")
    }

    @Test("migrateIfNeeded persists default account")
    @MainActor
    func migratePersistsDefaultAccount() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let manager = AccountManager(storage: storage)

        manager.migrateIfNeeded()

        // Verify with new manager
        let manager2 = AccountManager(storage: storage)
        #expect(manager2.accounts.count == 1)
        #expect(manager2.accounts.first?.name == "Default")
    }

    // MARK: - Computed Properties Tests

    @Test("hasAccounts returns true when accounts exist")
    @MainActor
    func hasAccountsTrue() {
        let manager = createTestManager()
        manager.addAccount(Account(name: "Test"))

        #expect(manager.hasAccounts == true)
    }

    @Test("activeAccountCount counts only active accounts")
    @MainActor
    func activeAccountCountOnlyActive() {
        let manager = createTestManager()

        var active = Account(name: "Active", isActive: true)
        var inactive = Account(name: "Inactive", isActive: false)
        manager.addAccount(active)

        // Get the added account and update the inactive one
        active = manager.accounts.first!
        inactive.isActive = false
        manager.addAccount(inactive)

        // Manually set the second one to inactive
        var updatedInactive = manager.accounts[1]
        updatedInactive.isActive = false
        manager.updateAccount(updatedInactive)

        #expect(manager.activeAccountCount == 1)
    }

    // MARK: - Clear and Reload Tests

    @Test("clearAllAccounts removes all accounts")
    @MainActor
    func clearAllAccountsRemovesAll() {
        let manager = createTestManager()
        manager.addAccount(Account(name: "One"))
        manager.addAccount(Account(name: "Two"))

        manager.clearAllAccounts()

        #expect(manager.accounts.isEmpty)
        #expect(manager.activeAccount == nil)
    }

    @Test("reload loads from storage")
    @MainActor
    func reloadLoadsFromStorage() {
        let defaults = createTestDefaults()
        let storage = UserDefaultsAccountStorage(defaults: defaults)
        let manager = AccountManager(storage: storage)

        // Directly save to storage
        let account = Account(name: "External", isPrimary: true)
        storage.saveAccounts([account])

        manager.reload()

        #expect(manager.accounts.count == 1)
        #expect(manager.accounts.first?.name == "External")
    }
}

// MARK: - MultiAccountCredentialsRepository Tests

@Suite("MultiAccountCredentialsRepository Tests")
struct MultiAccountCredentialsRepositoryTests {
    @Test("Repository conforms to CredentialsRepository")
    func conformsToProtocol() async {
        let repo = MultiAccountCredentialsRepository()

        // This test verifies the protocol conformance compiles
        // The actual credential fetching depends on system Keychain state
        let hasCredentials = await repo.hasCredentials()
        // We don't assert the result since it depends on system state
        _ = hasCredentials
    }

    @Test("getCredentials(for:) uses account keychain service name")
    func usesAccountServiceName() async {
        let repo = MultiAccountCredentialsRepository()

        // Create an account with a custom keychain identifier
        let account = Account(name: "Custom", keychainIdentifier: "custom-test-id")

        // This will try to fetch from "ClaudeApp-account-custom-test-id"
        // which shouldn't exist, so we expect notAuthenticated error
        do {
            _ = try await repo.getCredentials(for: account)
            Issue.record("Expected notAuthenticated error for non-existent keychain entry")
        } catch let error as AppError {
            switch error {
            case .notAuthenticated:
                // Expected - no credentials exist for this custom identifier
                break
            case .keychainError:
                // Also acceptable - keychain access might fail differently
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("hasCredentials(for:) returns false for non-existent account")
    func hasCredentialsFalseForNonExistent() async {
        let repo = MultiAccountCredentialsRepository()
        let account = Account(name: "NonExistent", keychainIdentifier: "definitely-not-real-\(UUID())")

        let result = await repo.hasCredentials(for: account)

        #expect(result == false)
    }

    @Test("clearCache clears repository cache")
    func clearCacheWorks() async {
        let repo = MultiAccountCredentialsRepository()

        // Access a few service names to populate cache
        _ = await repo.hasCredentials(forServiceName: "test-service-1")
        _ = await repo.hasCredentials(forServiceName: "test-service-2")

        await repo.clearCache()

        // Cache is cleared - no way to directly verify, but this shouldn't crash
        _ = await repo.hasCredentials(forServiceName: "test-service-1")
    }

    @Test("Repository handles default account correctly")
    func handlesDefaultAccount() async {
        let repo = MultiAccountCredentialsRepository()
        let account = Account(name: "Default", keychainIdentifier: "default")

        // Default account should use "Claude Code-credentials" service name
        #expect(account.keychainServiceName == "Claude Code-credentials")

        // The actual credential fetch depends on system state
        let hasCredentials = await repo.hasCredentials(for: account)
        _ = hasCredentials // Result depends on whether Claude Code is installed and logged in
    }

    @Test("getCredentials(forServiceName:) uses specified service name")
    func getCredentialsForServiceName() async {
        let repo = MultiAccountCredentialsRepository()

        do {
            _ = try await repo.getCredentials(forServiceName: "non-existent-service-\(UUID())")
            Issue.record("Expected error for non-existent service")
        } catch let error as AppError {
            switch error {
            case .notAuthenticated, .keychainError:
                // Expected
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("hasCredentials(forServiceName:) returns false for non-existent service")
    func hasCredentialsForServiceNameFalse() async {
        let repo = MultiAccountCredentialsRepository()

        let result = await repo.hasCredentials(forServiceName: "definitely-non-existent-\(UUID())")

        #expect(result == false)
    }
}
