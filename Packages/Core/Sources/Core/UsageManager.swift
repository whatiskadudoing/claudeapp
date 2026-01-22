import Domain
import Foundation

// MARK: - RefreshState

/// Visual state of the refresh button for UI feedback.
public enum RefreshState: Sendable, Equatable {
    case idle
    case loading
    case success
    case error
}

// MARK: - UsageManager

/// Main state manager for usage data.
/// Handles fetching, caching, and exposing usage state to the UI layer.
@MainActor
@Observable
public final class UsageManager {
    // MARK: - Published State

    /// Current usage data (nil if not yet fetched or on error)
    public private(set) var usageData: UsageData?

    /// Previous usage data for notification comparison
    /// Stored after each successful refresh to detect threshold crossings
    public private(set) var previousUsageData: UsageData?

    /// Whether a refresh is currently in progress
    public private(set) var isLoading: Bool = false

    /// Last error encountered during refresh (nil on success)
    public private(set) var lastError: AppError?

    /// Timestamp of last successful data fetch
    public private(set) var lastUpdated: Date?

    /// Current visual state of the refresh button
    public private(set) var refreshState: RefreshState = .idle

    // MARK: - Dependencies

    private let usageRepository: UsageRepository
    private var notificationChecker: UsageNotificationChecker?

    // MARK: - Auto-Refresh State

    private var refreshTask: Task<Void, Never>?
    private var currentInterval: TimeInterval = 300 // 5 minutes default

    // MARK: - Backoff State

    /// Number of consecutive failures for exponential backoff calculation
    private var consecutiveFailures: Int = 0

    /// Base retry interval in seconds (1 minute)
    private static let baseRetryInterval: TimeInterval = 60

    /// Maximum retry interval in seconds (15 minutes)
    private static let maxRetryInterval: TimeInterval = 900

    // MARK: - Sleep/Wake State

    /// Whether auto-refresh was running before sleep
    private var wasRefreshing: Bool = false

    // MARK: - Initialization

    /// Creates a new UsageManager with the given repository.
    /// - Parameter usageRepository: Repository for fetching usage data
    public init(usageRepository: UsageRepository) {
        self.usageRepository = usageRepository
    }

    /// Sets the notification checker for triggering usage notifications.
    /// This should be called after initialization when the checker is available.
    /// - Parameter checker: The notification checker to use
    public func setNotificationChecker(_ checker: UsageNotificationChecker) {
        self.notificationChecker = checker
    }

    // MARK: - Computed Properties

    /// Returns the highest utilization across all usage windows.
    /// Returns 0 if no data is available.
    public var highestUtilization: Double {
        usageData?.highestUtilization ?? 0
    }

    /// Calculates the retry interval using exponential backoff.
    /// Starts at 1 minute and doubles with each failure, capped at 15 minutes.
    private var retryInterval: TimeInterval {
        let exponent = min(consecutiveFailures, 4) // Cap exponent to avoid overflow
        let interval = Self.baseRetryInterval * pow(2, Double(exponent))
        return min(interval, Self.maxRetryInterval)
    }

    /// Whether auto-refresh is currently active
    public var isAutoRefreshing: Bool {
        refreshTask != nil
    }

    /// Whether the current data is considered stale (older than 1 minute).
    /// Returns true if no data exists or if data is older than 60 seconds.
    public var isStale: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 60
    }

    // MARK: - Public Methods

    /// Fetches fresh usage data from the repository.
    /// Updates `usageData` on success, `lastError` on failure.
    /// Tracks consecutive failures for exponential backoff.
    /// Manages `refreshState` for visual feedback (success/error flash).
    public func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        refreshState = .loading
        lastError = nil

        var succeeded = false

        do {
            let newData = try await usageRepository.fetchUsage()

            // Check notifications before updating state (needs previous data)
            if let checker = notificationChecker {
                await checker.check(current: newData, previous: usageData)
            }

            // Update previous data before current (for next comparison)
            previousUsageData = usageData
            usageData = newData
            lastUpdated = Date()
            consecutiveFailures = 0 // Reset backoff on success
            succeeded = true
        } catch let error as AppError {
            lastError = error
            // Only increment failures for retryable errors
            if shouldRetry(for: error) {
                consecutiveFailures += 1
            }
        } catch {
            lastError = .networkError(message: error.localizedDescription)
            consecutiveFailures += 1
        }

        isLoading = false

        // Show success/error flash briefly, then return to idle
        refreshState = succeeded ? .success : .error
        Task {
            try? await Task.sleep(for: .seconds(1))
            // Only reset to idle if we're still in the flash state
            if self.refreshState == .success || self.refreshState == .error {
                self.refreshState = .idle
            }
        }
    }

    /// Determines if an error should trigger retry with backoff.
    /// Auth errors should not retry automatically.
    private func shouldRetry(for error: AppError) -> Bool {
        switch error {
        case .notAuthenticated:
            return false // Don't retry auth errors
        case .rateLimited:
            return true // Retry after rate limit (uses retry-after)
        case .networkError, .apiError, .keychainError, .decodingError:
            return true
        }
    }

    /// Starts automatic refresh at the specified interval.
    /// Uses exponential backoff when errors occur.
    /// - Parameter interval: Time between refresh attempts in seconds (default 5 minutes)
    public func startAutoRefresh(interval: TimeInterval = 300) {
        stopAutoRefresh()
        currentInterval = interval

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()

                // Determine sleep duration based on success/failure
                let sleepInterval: TimeInterval
                if let self = self, self.lastError != nil {
                    // Use backoff interval on error (unless it's an auth error)
                    if let error = self.lastError, !self.shouldRetry(for: error) {
                        // Auth errors: don't auto-retry, wait for user action
                        sleepInterval = interval
                    } else if let error = self.lastError, case .rateLimited(let retryAfter) = error {
                        // Rate limited: use server-provided retry-after
                        sleepInterval = TimeInterval(retryAfter)
                    } else {
                        // Other errors: use exponential backoff
                        sleepInterval = self.retryInterval
                    }
                } else {
                    // Success: use normal interval
                    sleepInterval = interval
                }

                try? await Task.sleep(for: .seconds(sleepInterval))
            }
        }
    }

    /// Stops automatic refresh if running.
    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Restarts auto-refresh with a new interval.
    /// Use this when the user changes the refresh interval in settings.
    /// - Parameter interval: New time between refresh attempts in seconds
    public func restartAutoRefresh(interval: TimeInterval) {
        if refreshTask != nil {
            stopAutoRefresh()
            startAutoRefresh(interval: interval)
        } else {
            currentInterval = interval
        }
    }

    // MARK: - Sleep/Wake Handling

    /// Pauses auto-refresh when system goes to sleep.
    /// Call this from NSWorkspace.willSleepNotification observer.
    public func handleSleep() {
        wasRefreshing = refreshTask != nil
        stopAutoRefresh()
    }

    /// Resumes auto-refresh after system wakes.
    /// Waits briefly before refreshing to allow network reconnection.
    /// Call this from NSWorkspace.didWakeNotification observer.
    public func handleWake() {
        // Resume auto-refresh if it was running before sleep
        if wasRefreshing {
            startAutoRefresh(interval: currentInterval)
        }

        // Delay refresh to let network reconnect
        Task {
            try? await Task.sleep(for: .seconds(5))
            await refresh()
        }
    }

    // MARK: - Testing Support

    /// Returns the current retry interval for testing purposes.
    /// This is the interval that would be used after the current number of failures.
    public var currentRetryInterval: TimeInterval {
        retryInterval
    }

    /// Returns the current consecutive failure count for testing purposes.
    public var failureCount: Int {
        consecutiveFailures
    }
}
