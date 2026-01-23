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

    /// Returns the highest burn rate across all usage windows.
    /// Used for the burn rate badge in the dropdown header.
    /// Returns nil if no windows have burn rate data.
    public var highestBurnRate: BurnRate? {
        [fiveHour.burnRate, sevenDay.burnRate, sevenDayOpus?.burnRate, sevenDaySonnet?.burnRate]
            .compactMap { $0 }
            .max { $0.percentPerHour < $1.percentPerHour }
    }

    /// Returns the utilization for the specified percentage source.
    /// Falls back to highest utilization if the requested source is unavailable.
    public func utilization(for source: PercentageSource) -> Double {
        switch source {
        case .highest:
            return highestUtilization
        case .session:
            return fiveHour.utilization
        case .weekly:
            return sevenDay.utilization
        case .opus:
            return sevenDayOpus?.utilization ?? highestUtilization
        case .sonnet:
            return sevenDaySonnet?.utilization ?? highestUtilization
        }
    }
}
