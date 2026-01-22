// MARK: - UsageRepository

/// Protocol for fetching usage data from a data source.
/// Implemented by ClaudeAPIClient in the Services package.
public protocol UsageRepository: Sendable {
    /// Fetches the current usage data.
    /// - Returns: The current usage data across all windows
    /// - Throws: `AppError` if the fetch fails
    func fetchUsage() async throws -> UsageData
}
