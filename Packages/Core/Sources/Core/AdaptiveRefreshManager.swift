import Domain
import Foundation

// MARK: - AdaptiveRefreshManagerProtocol

/// Protocol for adaptive refresh management to enable testing.
@MainActor
public protocol AdaptiveRefreshManagerProtocol: Sendable {
    /// The effective refresh interval based on current system state.
    /// Returns `.infinity` when refresh should be suspended.
    var effectiveRefreshInterval: TimeInterval { get }

    /// Whether auto-refresh is currently running.
    var isAutoRefreshing: Bool { get }

    /// Starts automatic refresh with state-based interval calculation.
    func startAutoRefresh()

    /// Stops automatic refresh.
    func stopAutoRefresh()
}

// MARK: - AdaptiveRefreshManager

/// Manages automatic refresh behavior based on system state (sleep, idle, battery).
/// Replaces the simple auto-refresh in UsageManager with intelligent, state-aware scheduling.
///
/// # Refresh Intervals by State
/// - **Sleeping:** Suspended (no API calls)
/// - **Idle on battery:** Double the user's interval (max 30 min)
/// - **Idle on power:** Use user's interval
/// - **Active with critical usage (≥90%):** Min(user interval, 2 min)
/// - **Active normal:** Use user's interval
///
/// # Usage
/// ```swift
/// let manager = AdaptiveRefreshManager(
///     systemStateMonitor: systemMonitor,
///     usageManager: usageManager,
///     settingsManager: settingsManager
/// )
/// manager.startAutoRefresh()
/// ```
@MainActor
@Observable
public final class AdaptiveRefreshManager: AdaptiveRefreshManagerProtocol {
    // MARK: - Constants

    /// Maximum interval when idle (30 minutes)
    private static let maxIdleInterval: TimeInterval = 1800

    /// Interval for critical usage (2 minutes)
    private static let criticalInterval: TimeInterval = 120

    /// Usage threshold for critical monitoring (90%)
    private static let criticalUsageThreshold: Double = 90.0

    /// Polling interval when sleeping (60 seconds to check for state changes)
    private static let sleepPollingInterval: TimeInterval = 60

    /// Delay before refreshing after wake (allows network reconnection)
    private static let wakeRefreshDelay: TimeInterval = 5

    // MARK: - Dependencies

    private let systemStateMonitor: any SystemStateMonitorProtocol
    private let usageManager: UsageManager
    private let settingsManager: SettingsManager

    // MARK: - State

    private var refreshTask: Task<Void, Never>?

    /// Track the last state to detect transitions
    private var lastKnownState: SystemState = .active

    // MARK: - Computed Properties

    /// Calculates the effective refresh interval based on current system state.
    /// Returns `.infinity` when refresh should be suspended (sleeping state).
    public var effectiveRefreshInterval: TimeInterval {
        // If power-aware refresh is disabled, just use the user's interval
        guard settingsManager.enablePowerAwareRefresh else {
            return settingsManager.refreshIntervalSeconds
        }

        let baseInterval = settingsManager.refreshIntervalSeconds

        switch systemStateMonitor.currentState {
        case .sleeping:
            // Suspended - no refresh
            return .infinity

        case .idle:
            // When idle, optionally double the interval on battery
            if systemStateMonitor.isOnBattery && settingsManager.reduceRefreshOnBattery {
                // Double interval but cap at max
                return min(baseInterval * 2, Self.maxIdleInterval)
            }
            // Idle but on power - use normal interval
            return baseInterval

        case .active:
            // Check for critical usage (≥90%)
            if let utilization = usageManager.usageData?.highestUtilization,
               utilization >= Self.criticalUsageThreshold
            {
                // More frequent refresh when critical
                return min(baseInterval, Self.criticalInterval)
            }

            // Normal active state
            // If on battery and reduce is enabled, use double interval
            if systemStateMonitor.isOnBattery && settingsManager.reduceRefreshOnBattery {
                return min(baseInterval * 2, Self.maxIdleInterval)
            }

            return baseInterval
        }
    }

    /// Whether auto-refresh is currently running.
    public var isAutoRefreshing: Bool {
        refreshTask != nil
    }

    // MARK: - Initialization

    /// Creates a new AdaptiveRefreshManager.
    /// - Parameters:
    ///   - systemStateMonitor: Monitor for system state (sleep, idle, battery)
    ///   - usageManager: Manager for usage data (performs the actual refresh)
    ///   - settingsManager: Manager for user settings
    public init(
        systemStateMonitor: any SystemStateMonitorProtocol,
        usageManager: UsageManager,
        settingsManager: SettingsManager
    ) {
        self.systemStateMonitor = systemStateMonitor
        self.usageManager = usageManager
        self.settingsManager = settingsManager
    }

    // MARK: - Public Methods

    /// Starts automatic refresh with state-based interval calculation.
    /// Stops any existing refresh task before starting a new one.
    public func startAutoRefresh() {
        stopAutoRefresh()
        scheduleNextRefresh()
    }

    /// Stops automatic refresh if running.
    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Handles system wake event - triggers immediate refresh after delay.
    /// Call this when system wakes from sleep to get fresh data.
    public func handleWake() {
        Task {
            // Delay to allow network reconnection
            try? await Task.sleep(for: .seconds(Self.wakeRefreshDelay))
            await usageManager.refresh()
        }
    }

    // MARK: - Private Methods

    private func scheduleNextRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let interval = self.effectiveRefreshInterval

                // Check if sleeping (suspended)
                if !interval.isFinite {
                    // In sleep state - poll periodically to check for state changes
                    try? await Task.sleep(for: .seconds(Self.sleepPollingInterval))

                    // Check if we transitioned from sleeping to another state
                    if self.systemStateMonitor.currentState != .sleeping {
                        // State changed - trigger immediate refresh
                        await self.usageManager.refresh()
                    }
                    continue
                }

                // Perform refresh
                await self.usageManager.refresh()

                // Recalculate interval after refresh (usage may have changed to critical)
                let nextInterval = self.effectiveRefreshInterval

                // If next interval is infinity (sleeping), just continue loop
                guard nextInterval.isFinite else {
                    continue
                }

                // Sleep until next refresh
                try? await Task.sleep(for: .seconds(nextInterval))
            }
        }
    }
}

// MARK: - MockAdaptiveRefreshManager

/// Mock implementation for testing.
@MainActor
public final class MockAdaptiveRefreshManager: AdaptiveRefreshManagerProtocol {
    public var effectiveRefreshInterval: TimeInterval = 300
    public private(set) var isAutoRefreshing: Bool = false

    public var startAutoRefreshCallCount = 0
    public var stopAutoRefreshCallCount = 0

    public init() {}

    public func startAutoRefresh() {
        startAutoRefreshCallCount += 1
        isAutoRefreshing = true
    }

    public func stopAutoRefresh() {
        stopAutoRefreshCallCount += 1
        isAutoRefreshing = false
    }

    /// Sets the effective interval for testing
    public func setEffectiveInterval(_ interval: TimeInterval) {
        effectiveRefreshInterval = interval
    }
}
