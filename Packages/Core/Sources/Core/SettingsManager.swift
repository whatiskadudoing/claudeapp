import Domain
import Foundation

// MARK: - UserDefaultsSettingsRepository

/// Concrete implementation of SettingsRepository using UserDefaults.
public final class UserDefaultsSettingsRepository: SettingsRepository, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func get<T: Codable & Sendable>(_ key: SettingsKey<T>) -> T {
        guard let data = defaults.data(forKey: key.key),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else {
            return key.defaultValue
        }
        return value
    }

    public func set<T: Codable & Sendable>(_ key: SettingsKey<T>, value: T) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key.key)
        }
    }
}

// MARK: - SettingsManager

/// Main state manager for app settings.
/// Uses @Observable for SwiftUI integration and persists changes to UserDefaults.
@MainActor
@Observable
public final class SettingsManager {
    // MARK: - Display Settings

    /// Which icon style to display in the menu bar
    public var iconStyle: IconStyle {
        didSet { save(.iconStyle, value: iconStyle) }
    }

    /// Whether to show the plan badge (Pro, Max 5x, Max 20x) in the menu bar
    public var showPlanBadge: Bool {
        didSet { save(.showPlanBadge, value: showPlanBadge) }
    }

    /// Whether to show the percentage in the menu bar
    public var showPercentage: Bool {
        didSet { save(.showPercentage, value: showPercentage) }
    }

    /// Which usage metric to display in the menu bar percentage
    public var percentageSource: PercentageSource {
        didSet { save(.percentageSource, value: percentageSource) }
    }

    /// The user's subscription plan type (Pro, Max 5x, Max 20x)
    public var planType: PlanType {
        didSet { save(.planType, value: planType) }
    }

    // MARK: - Refresh Settings

    /// Refresh interval in minutes (1-30)
    public var refreshInterval: Int {
        didSet {
            // Clamp to valid range
            let clamped = min(max(refreshInterval, 1), 30)
            if refreshInterval != clamped {
                refreshInterval = clamped
            }
            save(.refreshInterval, value: refreshInterval)
            onRefreshIntervalChanged?(refreshInterval)
        }
    }

    /// Whether to enable power-aware refresh (Smart Refresh)
    /// When enabled, refresh is suspended when screen is off and reduced when idle
    public var enablePowerAwareRefresh: Bool {
        didSet { save(.enablePowerAwareRefresh, value: enablePowerAwareRefresh) }
    }

    /// Whether to reduce refresh frequency when on battery power
    /// Only takes effect when enablePowerAwareRefresh is true
    public var reduceRefreshOnBattery: Bool {
        didSet { save(.reduceRefreshOnBattery, value: reduceRefreshOnBattery) }
    }

    /// Callback when refresh interval changes (for UsageManager to restart auto-refresh)
    public var onRefreshIntervalChanged: ((Int) -> Void)?

    // MARK: - Notification Settings

    /// Master toggle for all notifications
    public var notificationsEnabled: Bool {
        didSet { save(.notificationsEnabled, value: notificationsEnabled) }
    }

    /// Warning threshold percentage (50-99)
    public var warningThreshold: Int {
        didSet {
            // Clamp to valid range
            let clamped = min(max(warningThreshold, 50), 99)
            if warningThreshold != clamped {
                warningThreshold = clamped
            }
            save(.warningThreshold, value: warningThreshold)
        }
    }

    /// Whether usage warning notifications are enabled
    public var warningEnabled: Bool {
        didSet { save(.warningEnabled, value: warningEnabled) }
    }

    /// Whether capacity full (100%) notifications are enabled
    public var capacityFullEnabled: Bool {
        didSet { save(.capacityFullEnabled, value: capacityFullEnabled) }
    }

    /// Whether reset complete notifications are enabled
    public var resetCompleteEnabled: Bool {
        didSet { save(.resetCompleteEnabled, value: resetCompleteEnabled) }
    }

    // MARK: - General Settings

    /// Whether to launch the app at login
    public var launchAtLogin: Bool {
        didSet { save(.launchAtLogin, value: launchAtLogin) }
    }

    /// Whether to automatically check for updates
    public var checkForUpdates: Bool {
        didSet { save(.checkForUpdates, value: checkForUpdates) }
    }

    // MARK: - Dependencies

    private let repository: SettingsRepository

    // MARK: - Initialization

    /// Creates a new SettingsManager, loading values from the repository.
    /// - Parameter repository: The settings repository to use for persistence
    public init(repository: SettingsRepository = UserDefaultsSettingsRepository()) {
        self.repository = repository

        // Load all settings from repository
        iconStyle = repository.get(.iconStyle)
        showPlanBadge = repository.get(.showPlanBadge)
        showPercentage = repository.get(.showPercentage)
        percentageSource = repository.get(.percentageSource)
        planType = repository.get(.planType)
        refreshInterval = repository.get(.refreshInterval)
        enablePowerAwareRefresh = repository.get(.enablePowerAwareRefresh)
        reduceRefreshOnBattery = repository.get(.reduceRefreshOnBattery)
        notificationsEnabled = repository.get(.notificationsEnabled)
        warningThreshold = repository.get(.warningThreshold)
        warningEnabled = repository.get(.warningEnabled)
        capacityFullEnabled = repository.get(.capacityFullEnabled)
        resetCompleteEnabled = repository.get(.resetCompleteEnabled)
        launchAtLogin = repository.get(.launchAtLogin)
        checkForUpdates = repository.get(.checkForUpdates)
    }

    // MARK: - Computed Properties

    /// Refresh interval in seconds (for UsageManager)
    public var refreshIntervalSeconds: TimeInterval {
        TimeInterval(refreshInterval * 60)
    }

    // MARK: - Private Methods

    private func save<T: Codable & Sendable>(_ key: SettingsKey<T>, value: T) {
        repository.set(key, value: value)
    }
}
