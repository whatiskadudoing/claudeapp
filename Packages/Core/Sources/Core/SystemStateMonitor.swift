import Cocoa
import CoreGraphics
import Foundation
import IOKit.ps

// MARK: - SystemState

/// System states that affect refresh behavior.
/// Used by AdaptiveRefreshManager to determine refresh intervals.
public enum SystemState: Sendable, Equatable {
    /// Screen on, user actively using the Mac
    case active
    /// Screen on, no user activity for idle threshold
    case idle
    /// Screen off/locked or system sleeping
    case sleeping
}

// MARK: - SystemStateMonitorProtocol

/// Protocol for system state monitoring to enable testing.
@MainActor
public protocol SystemStateMonitorProtocol: Sendable {
    var currentState: SystemState { get }
    var isOnBattery: Bool { get }
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - SystemStateMonitor

/// Monitors system state for power-aware refresh behavior.
/// Detects screen sleep/wake, system sleep/wake, user idle time, and battery state.
///
/// # Usage
/// ```swift
/// let monitor = SystemStateMonitor()
/// monitor.startMonitoring()
///
/// // Check current state
/// switch monitor.currentState {
/// case .active: // Normal refresh
/// case .idle: // Reduced refresh
/// case .sleeping: // Suspended refresh
/// }
///
/// // Check power source
/// if monitor.isOnBattery {
///     // Conserve battery
/// }
/// ```
@MainActor
@Observable
public final class SystemStateMonitor: SystemStateMonitorProtocol {
    // MARK: - State

    /// Current system state (active, idle, sleeping)
    public private(set) var currentState: SystemState = .active

    /// Whether Mac is running on battery power
    public private(set) var isOnBattery: Bool = false

    // MARK: - Configuration

    /// Time in seconds before transitioning to idle state (default: 5 minutes)
    public let idleThreshold: TimeInterval

    /// Interval for checking idle time (default: 60 seconds)
    public let idleCheckInterval: TimeInterval

    // MARK: - Private State

    private var idleTimer: Timer?
    private var isMonitoring: Bool = false

    // Notification observers - nonisolated for deinit access
    private var screenSleepObserver: NSObjectProtocol?
    private var screenWakeObserver: NSObjectProtocol?
    private var systemSleepObserver: NSObjectProtocol?
    private var systemWakeObserver: NSObjectProtocol?

    // MARK: - Initialization

    /// Creates a new SystemStateMonitor.
    /// - Parameters:
    ///   - idleThreshold: Time in seconds before transitioning to idle (default: 300 = 5 minutes)
    ///   - idleCheckInterval: How often to check idle time in seconds (default: 60)
    public init(
        idleThreshold: TimeInterval = 300,
        idleCheckInterval: TimeInterval = 60
    ) {
        self.idleThreshold = idleThreshold
        self.idleCheckInterval = idleCheckInterval
    }

    // MARK: - Public Methods

    /// Starts monitoring system state changes.
    /// Registers notification observers and starts idle detection timer.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        registerNotifications()
        startIdleDetection()
        checkPowerSource()
    }

    /// Stops monitoring system state changes.
    /// Removes notification observers and stops idle detection timer.
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        unregisterNotifications()
        stopIdleDetection()
    }

    // MARK: - Notification Registration

    private func registerNotifications() {
        let notificationCenter = NSWorkspace.shared.notificationCenter

        // Screen sleep notification
        screenSleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenSleep()
            }
        }

        // Screen wake notification
        screenWakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenWake()
            }
        }

        // System sleep notification
        systemSleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemSleep()
            }
        }

        // System wake notification
        systemWakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemWake()
            }
        }
    }

    private func unregisterNotifications() {
        let notificationCenter = NSWorkspace.shared.notificationCenter

        if let observer = screenSleepObserver {
            notificationCenter.removeObserver(observer)
            screenSleepObserver = nil
        }
        if let observer = screenWakeObserver {
            notificationCenter.removeObserver(observer)
            screenWakeObserver = nil
        }
        if let observer = systemSleepObserver {
            notificationCenter.removeObserver(observer)
            systemSleepObserver = nil
        }
        if let observer = systemWakeObserver {
            notificationCenter.removeObserver(observer)
            systemWakeObserver = nil
        }
    }

    // MARK: - Notification Handlers

    private func handleScreenSleep() {
        currentState = .sleeping
        stopIdleDetection()
    }

    private func handleScreenWake() {
        currentState = .active
        startIdleDetection()
        checkPowerSource()
    }

    private func handleSystemSleep() {
        currentState = .sleeping
        stopIdleDetection()
    }

    private func handleSystemWake() {
        currentState = .active
        startIdleDetection()
        checkPowerSource()
    }

    // MARK: - Idle Detection

    private func startIdleDetection() {
        stopIdleDetection()

        // Create and schedule timer on main run loop
        idleTimer = Timer.scheduledTimer(
            withTimeInterval: idleCheckInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleTime()
            }
        }
    }

    private func stopIdleDetection() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    private func checkIdleTime() {
        // Don't check idle if sleeping
        guard currentState != .sleeping else { return }

        let idleTime = getSystemIdleTime()

        if idleTime > idleThreshold, currentState == .active {
            currentState = .idle
        } else if idleTime <= idleThreshold, currentState == .idle {
            currentState = .active
        }
    }

    /// Returns the system idle time in seconds.
    /// Uses CGEventSource to check time since last user input event.
    private func getSystemIdleTime() -> TimeInterval {
        // Check multiple event types and use the minimum (most recent activity)
        let mouseIdleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )
        let keyboardIdleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )
        let mouseDownIdleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .leftMouseDown
        )
        let scrollIdleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .scrollWheel
        )

        // Return the minimum (most recent activity)
        return min(mouseIdleTime, keyboardIdleTime, mouseDownIdleTime, scrollIdleTime)
    }

    // MARK: - Power Source Detection

    /// Checks and updates the current power source state (battery vs AC).
    public func checkPowerSource() {
        isOnBattery = detectBatteryPower()
    }

    /// Detects if the Mac is running on battery power.
    /// Uses IOKit Power Sources API.
    private func detectBatteryPower() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return false
        }

        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // Check power source state key
            if let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String {
                // kIOPSBatteryPowerValue = "Battery Power"
                // kIOPSACPowerValue = "AC Power"
                if powerSourceState == kIOPSBatteryPowerValue as String {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Testing Support

    /// Forces a state change for testing purposes.
    /// Only use in tests - not for production code.
    public func setStateForTesting(_ state: SystemState) {
        currentState = state
    }

    /// Sets battery state for testing purposes.
    /// Only use in tests - not for production code.
    public func setBatteryStateForTesting(_ onBattery: Bool) {
        isOnBattery = onBattery
    }

    /// Manually triggers an idle check for testing purposes.
    public func triggerIdleCheckForTesting() {
        checkIdleTime()
    }
}

// MARK: - MockSystemStateMonitor

/// Mock implementation for testing.
@MainActor
public final class MockSystemStateMonitor: SystemStateMonitorProtocol {
    public var currentState: SystemState = .active
    public var isOnBattery: Bool = false

    public var startMonitoringCallCount = 0
    public var stopMonitoringCallCount = 0

    public init() {}

    public func startMonitoring() {
        startMonitoringCallCount += 1
    }

    public func stopMonitoring() {
        stopMonitoringCallCount += 1
    }

    /// Sets the state for testing
    public func setState(_ state: SystemState) {
        currentState = state
    }

    /// Sets the battery state for testing
    public func setBatteryState(_ onBattery: Bool) {
        isOnBattery = onBattery
    }
}
