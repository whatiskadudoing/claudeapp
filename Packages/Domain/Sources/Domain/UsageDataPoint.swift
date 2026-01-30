import Foundation

// MARK: - UsageDataPoint

/// Represents a single usage data point for historical tracking.
/// Used by UsageHistoryManager to store usage history for sparkline charts.
///
/// Each data point captures the utilization at a specific moment in time,
/// enabling visualization of usage trends over time.
public struct UsageDataPoint: Sendable, Equatable, Codable, Identifiable {
    /// The utilization percentage at this point in time (0.0 to 100.0)
    public let utilization: Double

    /// When this data point was recorded
    public let timestamp: Date

    /// Unique identifier for SwiftUI list/chart identification
    public var id: Date { timestamp }

    /// Creates a new usage data point.
    /// - Parameters:
    ///   - utilization: The utilization percentage (0.0 to 100.0)
    ///   - timestamp: When this data point was recorded (defaults to now)
    public init(utilization: Double, timestamp: Date = Date()) {
        self.utilization = utilization
        self.timestamp = timestamp
    }
}

// MARK: - Comparable

extension UsageDataPoint: Comparable {
    /// Compares data points by timestamp for chronological sorting.
    public static func < (lhs: UsageDataPoint, rhs: UsageDataPoint) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
