import Foundation

// MARK: - UsageWindow

/// Represents a usage window with utilization percentage and optional reset time.
/// Used for both 5-hour session and 7-day usage limits.
public struct UsageWindow: Sendable, Equatable {
    /// Usage percentage (0.0 to 100.0)
    public let utilization: Double

    /// When this usage window resets (nil if unknown)
    public let resetsAt: Date?

    public init(utilization: Double, resetsAt: Date? = nil) {
        self.utilization = utilization
        self.resetsAt = resetsAt
    }
}
