import Foundation

// MARK: - UsageSnapshot

/// A point-in-time snapshot of usage data for history tracking.
/// Used internally by BurnRateCalculator to calculate consumption velocity.
///
/// This struct is internal to the Core package and is not exported to the UI layer.
/// It captures the essential utilization values needed for burn rate calculation.
struct UsageSnapshot: Sendable, Equatable {
    /// 5-hour rolling session window utilization (0.0 to 100.0)
    let fiveHourUtilization: Double

    /// 7-day total usage utilization (0.0 to 100.0)
    let sevenDayUtilization: Double

    /// 7-day Opus-specific utilization (nil if not used)
    let opusUtilization: Double?

    /// 7-day Sonnet-specific utilization (nil if not used)
    let sonnetUtilization: Double?

    /// When this snapshot was taken
    let timestamp: Date

    /// Creates a new usage snapshot.
    /// - Parameters:
    ///   - fiveHourUtilization: 5-hour session utilization (0.0 to 100.0)
    ///   - sevenDayUtilization: 7-day total utilization (0.0 to 100.0)
    ///   - opusUtilization: Opus-specific utilization (nil if not used)
    ///   - sonnetUtilization: Sonnet-specific utilization (nil if not used)
    ///   - timestamp: When this snapshot was taken (defaults to now)
    init(
        fiveHourUtilization: Double,
        sevenDayUtilization: Double,
        opusUtilization: Double? = nil,
        sonnetUtilization: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.fiveHourUtilization = fiveHourUtilization
        self.sevenDayUtilization = sevenDayUtilization
        self.opusUtilization = opusUtilization
        self.sonnetUtilization = sonnetUtilization
        self.timestamp = timestamp
    }
}
