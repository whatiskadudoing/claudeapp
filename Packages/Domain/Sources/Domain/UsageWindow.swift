import Foundation

// MARK: - UsageWindow

/// Represents a usage window with utilization percentage and optional reset time.
/// Used for both 5-hour session and 7-day usage limits.
///
/// The `burnRate` and `timeToExhaustion` properties are optional and get enriched
/// by the `BurnRateCalculator` in the Core package after accumulating usage history.
public struct UsageWindow: Sendable, Equatable, Codable {
    /// Usage percentage (0.0 to 100.0)
    public let utilization: Double

    /// When this usage window resets (nil if unknown)
    public let resetsAt: Date?

    /// Calculated burn rate (consumption velocity) for this window.
    /// Nil when insufficient history is available for calculation.
    public let burnRate: BurnRate?

    /// Estimated time in seconds until this window reaches 100% utilization.
    /// Nil when burn rate is unavailable or utilization is already at 100%.
    public let timeToExhaustion: TimeInterval?

    /// Creates a new usage window.
    /// - Parameters:
    ///   - utilization: Usage percentage (0.0 to 100.0)
    ///   - resetsAt: When this window resets (nil if unknown)
    ///   - burnRate: Calculated burn rate (nil until enriched by calculator)
    ///   - timeToExhaustion: Estimated seconds until limit reached (nil until enriched)
    public init(
        utilization: Double,
        resetsAt: Date? = nil,
        burnRate: BurnRate? = nil,
        timeToExhaustion: TimeInterval? = nil
    ) {
        self.utilization = utilization
        self.resetsAt = resetsAt
        self.burnRate = burnRate
        self.timeToExhaustion = timeToExhaustion
    }
}
