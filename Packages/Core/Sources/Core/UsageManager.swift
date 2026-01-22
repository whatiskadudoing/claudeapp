import Domain
import Foundation

// MARK: - UsageManager

/// Main state manager for usage data.
/// Handles fetching, caching, and exposing usage state to the UI layer.
@MainActor
@Observable
public final class UsageManager {
    // MARK: - Published State

    /// Current usage data (nil if not yet fetched or on error)
    public private(set) var usageData: UsageData?

    /// Whether a refresh is currently in progress
    public private(set) var isLoading: Bool = false

    /// Last error encountered during refresh (nil on success)
    public private(set) var lastError: AppError?

    /// Timestamp of last successful data fetch
    public private(set) var lastUpdated: Date?

    // MARK: - Dependencies

    private let usageRepository: UsageRepository

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

    // MARK: - Public Methods

    /// Fetches fresh usage data from the repository.
    /// Updates `usageData` on success, `lastError` on failure.
    /// Tracks consecutive failures for exponential backoff.
    public func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        lastError = nil

        do {
            usageData = try await usageRepository.fetchUsage()
            lastUpdated = Date()
            consecutiveFailures = 0 // Reset backoff on success
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
