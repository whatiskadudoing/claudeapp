import Foundation

// MARK: - UsageData

/// Aggregated usage data across all usage windows.
/// Fetched from the Claude API and displayed in the app.
public struct UsageData: Sendable, Equatable {
    /// 5-hour rolling session window
    public let fiveHour: UsageWindow

    /// 7-day total usage across all models
    public let sevenDay: UsageWindow

    /// 7-day Opus-specific quota (nil if not used)
    public let sevenDayOpus: UsageWindow?

    /// 7-day Sonnet-specific quota (nil if not used)
    public let sevenDaySonnet: UsageWindow?

    /// When this data was fetched
    public let fetchedAt: Date

    public init(
        fiveHour: UsageWindow,
        sevenDay: UsageWindow,
        sevenDayOpus: UsageWindow? = nil,
        sevenDaySonnet: UsageWindow? = nil,
        fetchedAt: Date = Date()
    ) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.sevenDayOpus = sevenDayOpus
        self.sevenDaySonnet = sevenDaySonnet
        self.fetchedAt = fetchedAt
    }

    /// Returns the highest utilization across all usage windows.
    /// This is displayed in the menu bar.
    public var highestUtilization: Double {
        [
            fiveHour.utilization,
            sevenDay.utilization,
            sevenDayOpus?.utilization ?? 0,
            sevenDaySonnet?.utilization ?? 0
        ].max() ?? 0
    }
}
