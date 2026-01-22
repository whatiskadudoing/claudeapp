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

    // MARK: - Public Methods

    /// Fetches fresh usage data from the repository.
    /// Updates `usageData` on success, `lastError` on failure.
    public func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        lastError = nil

        do {
            usageData = try await usageRepository.fetchUsage()
            lastUpdated = Date()
        } catch let error as AppError {
            lastError = error
        } catch {
            lastError = .networkError(message: error.localizedDescription)
        }

        isLoading = false
    }

    /// Starts automatic refresh at the specified interval.
    /// - Parameter interval: Time between refresh attempts in seconds
    public func startAutoRefresh(interval: TimeInterval) {
        stopAutoRefresh()

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    /// Stops automatic refresh if running.
    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
