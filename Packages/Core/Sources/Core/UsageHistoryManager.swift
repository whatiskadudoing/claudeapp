import Domain
import Foundation

// MARK: - UsageHistoryManager

/// Manages usage history for sparkline charts.
///
/// Tracks two separate histories:
/// - **Session history:** 5-minute granularity, max 60 points (5 hours of data)
/// - **Weekly history:** 1-hour granularity, max 168 points (7 days of data)
///
/// History is persisted to UserDefaults and restored on app launch.
@MainActor
@Observable
public final class UsageHistoryManager {
    // MARK: - Public State

    /// History for 5-hour session window (5-min granularity, max 60 points)
    /// Ordered chronologically (oldest first) for chart display.
    public private(set) var sessionHistory: [UsageDataPoint] = []

    /// History for 7-day windows (1-hour granularity, max 168 points)
    /// Ordered chronologically (oldest first) for chart display.
    public private(set) var weeklyHistory: [UsageDataPoint] = []

    // MARK: - Configuration

    /// Maximum session history points (5 hours at 5-min intervals)
    public static let maxSessionPoints = 60

    /// Maximum weekly history points (7 days at 1-hour intervals)
    public static let maxWeeklyPoints = 168

    /// Minimum interval between session recordings (5 minutes)
    public static let sessionRecordingInterval: TimeInterval = 300

    /// Minimum interval between weekly recordings (1 hour)
    public static let weeklyRecordingInterval: TimeInterval = 3600

    // MARK: - Persistence Keys

    private static let sessionHistoryKey = "sessionUsageHistory"
    private static let weeklyHistoryKey = "weeklyUsageHistory"

    // MARK: - Dependencies

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    /// Creates a new UsageHistoryManager.
    /// - Parameter userDefaults: UserDefaults instance for persistence (defaults to standard)
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    // MARK: - Recording

    /// Records a new usage snapshot.
    ///
    /// Data is only recorded if enough time has passed since the last recording:
    /// - Session: 5 minutes minimum between points
    /// - Weekly: 1 hour minimum between points
    ///
    /// - Parameters:
    ///   - sessionUtilization: Current 5-hour session utilization (0.0 to 100.0)
    ///   - weeklyUtilization: Current 7-day weekly utilization (0.0 to 100.0)
    public func record(sessionUtilization: Double, weeklyUtilization: Double) {
        let now = Date()

        // Record session history if interval has passed
        if shouldRecordSession(at: now) {
            let point = UsageDataPoint(utilization: sessionUtilization, timestamp: now)
            sessionHistory.append(point)

            // Trim if exceeds max
            if sessionHistory.count > Self.maxSessionPoints {
                sessionHistory.removeFirst()
            }
        }

        // Record weekly history if interval has passed
        if shouldRecordWeekly(at: now) {
            let point = UsageDataPoint(utilization: weeklyUtilization, timestamp: now)
            weeklyHistory.append(point)

            // Trim if exceeds max
            if weeklyHistory.count > Self.maxWeeklyPoints {
                weeklyHistory.removeFirst()
            }
        }

        // Persist changes
        save()
    }

    /// Determines if enough time has passed to record a new session data point.
    /// - Parameter date: The timestamp to check
    /// - Returns: True if recording should occur
    private func shouldRecordSession(at date: Date) -> Bool {
        guard let last = sessionHistory.last else { return true }
        return date.timeIntervalSince(last.timestamp) >= Self.sessionRecordingInterval
    }

    /// Determines if enough time has passed to record a new weekly data point.
    /// - Parameter date: The timestamp to check
    /// - Returns: True if recording should occur
    private func shouldRecordWeekly(at date: Date) -> Bool {
        guard let last = weeklyHistory.last else { return true }
        return date.timeIntervalSince(last.timestamp) >= Self.weeklyRecordingInterval
    }

    // MARK: - Clearing

    /// Clears session history.
    /// Call this when the 5-hour session window resets.
    public func clearSessionHistory() {
        sessionHistory.removeAll()
        save()
    }

    /// Clears weekly history.
    /// Typically called for testing or when user requests data reset.
    public func clearWeeklyHistory() {
        weeklyHistory.removeAll()
        save()
    }

    /// Clears all history (both session and weekly).
    public func clearAllHistory() {
        sessionHistory.removeAll()
        weeklyHistory.removeAll()
        save()
    }

    // MARK: - Persistence

    /// Saves history to UserDefaults.
    public func save() {
        let encoder = JSONEncoder()

        if let sessionData = try? encoder.encode(sessionHistory) {
            userDefaults.set(sessionData, forKey: Self.sessionHistoryKey)
        }

        if let weeklyData = try? encoder.encode(weeklyHistory) {
            userDefaults.set(weeklyData, forKey: Self.weeklyHistoryKey)
        }
    }

    /// Loads history from UserDefaults.
    public func load() {
        let decoder = JSONDecoder()

        if let sessionData = userDefaults.data(forKey: Self.sessionHistoryKey),
           let history = try? decoder.decode([UsageDataPoint].self, from: sessionData) {
            // Filter out points older than 5 hours (stale session data)
            let fiveHoursAgo = Date().addingTimeInterval(-5 * 3600)
            sessionHistory = history.filter { $0.timestamp > fiveHoursAgo }
        }

        if let weeklyData = userDefaults.data(forKey: Self.weeklyHistoryKey),
           let history = try? decoder.decode([UsageDataPoint].self, from: weeklyData) {
            // Filter out points older than 7 days (stale weekly data)
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            weeklyHistory = history.filter { $0.timestamp > sevenDaysAgo }
        }
    }

    // MARK: - Computed Properties

    /// Returns true if session history has enough points for a meaningful chart.
    /// At least 2 points are needed to draw a line.
    public var hasSessionChartData: Bool {
        sessionHistory.count >= 2
    }

    /// Returns true if weekly history has enough points for a meaningful chart.
    /// At least 2 points are needed to draw a line.
    public var hasWeeklyChartData: Bool {
        weeklyHistory.count >= 2
    }

    /// Returns the session history point count for display/testing.
    public var sessionPointCount: Int {
        sessionHistory.count
    }

    /// Returns the weekly history point count for display/testing.
    public var weeklyPointCount: Int {
        weeklyHistory.count
    }

    // MARK: - Import (Settings Restore)

    /// Imports session history points directly (for settings import).
    /// Bypasses the normal recording interval check.
    /// - Parameter points: The data points to import
    public func importSessionHistory(_ points: [UsageDataPoint]) {
        sessionHistory = Array(points.suffix(Self.maxSessionPoints))
    }

    /// Imports weekly history points directly (for settings import).
    /// Bypasses the normal recording interval check.
    /// - Parameter points: The data points to import
    public func importWeeklyHistory(_ points: [UsageDataPoint]) {
        weeklyHistory = Array(points.suffix(Self.maxWeeklyPoints))
    }
}
