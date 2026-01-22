import Domain
import Foundation

// MARK: - BurnRateCalculator

/// Calculates burn rate from usage history snapshots.
/// Burn rate represents consumption velocity as percentage points per hour.
///
/// The calculator requires a minimum of 2 samples to produce a reliable calculation.
/// It uses the oldest and newest snapshots to compute the rate of change over time.
public struct BurnRateCalculator: Sendable {
    /// Minimum number of samples needed for reliable burn rate calculation.
    private let minimumSamples: Int

    /// Creates a new burn rate calculator.
    /// - Parameter minimumSamples: Minimum samples required for calculation (default: 2)
    public init(minimumSamples: Int = 2) {
        self.minimumSamples = max(2, minimumSamples)
    }

    /// Calculate burn rate from a series of usage snapshots.
    ///
    /// The calculation uses the oldest and newest snapshots to determine
    /// the rate of change in utilization over time.
    ///
    /// - Parameter snapshots: Array of (utilization, timestamp) tuples, newest first.
    ///   Utilization values should be in the range 0-100 (percentage).
    /// - Returns: BurnRate if calculable, nil otherwise.
    ///
    /// Returns nil when:
    /// - Fewer than 2 samples provided
    /// - Time difference is zero or negative
    /// - Utilization decreased (indicates a reset, not consumption)
    public func calculate(from snapshots: [(utilization: Double, timestamp: Date)]) -> BurnRate? {
        guard snapshots.count >= minimumSamples else { return nil }

        // Use oldest and newest snapshots for calculation
        let newest = snapshots[0]
        let oldest = snapshots[snapshots.count - 1]

        let timeDiffHours = newest.timestamp.timeIntervalSince(oldest.timestamp) / 3600
        guard timeDiffHours > 0 else { return nil }

        let utilizationDiff = newest.utilization - oldest.utilization
        // Only calculate positive burn rates (consumption, not reset)
        guard utilizationDiff > 0 else { return nil }

        let percentPerHour = utilizationDiff / timeDiffHours
        return BurnRate(percentPerHour: percentPerHour)
    }

    /// Calculate time to exhaustion (100% utilization).
    ///
    /// Given the current utilization and burn rate, predicts how long until
    /// the usage limit is reached.
    ///
    /// - Parameters:
    ///   - currentUtilization: Current utilization percentage (0-100)
    ///   - burnRate: Current burn rate (consumption velocity)
    /// - Returns: TimeInterval in seconds until exhaustion, nil if not applicable.
    ///
    /// Returns 0 if already at or above 100%.
    /// Returns nil if burn rate is nil or zero/negative.
    public func timeToExhaustion(currentUtilization: Double, burnRate: BurnRate?) -> TimeInterval? {
        guard let burnRate = burnRate, burnRate.percentPerHour > 0 else { return nil }
        guard currentUtilization < 100 else { return 0 }

        let remainingCapacity = 100 - currentUtilization
        let hoursUntilExhaustion = remainingCapacity / burnRate.percentPerHour
        return hoursUntilExhaustion * 3600 // Convert to seconds
    }
}
