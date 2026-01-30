import Foundation

// MARK: - SettingsKey

/// Type-safe key for accessing settings with a default value.
/// Used by SettingsManager for compile-time safe settings access.
public struct SettingsKey<Value: Codable>: Sendable where Value: Sendable {
    /// The string key used for UserDefaults storage
    public let key: String

    /// The default value returned when no value is stored
    public let defaultValue: Value

    public init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

// MARK: - Predefined Settings Keys

public extension SettingsKey where Value == Bool {
    // Display Settings
    static let showPlanBadge = SettingsKey<Bool>(key: "showPlanBadge", defaultValue: false)
    static let showPercentage = SettingsKey<Bool>(key: "showPercentage", defaultValue: true)
    static let showSparklines = SettingsKey<Bool>(key: "showSparklines", defaultValue: true)

    // Notification Settings
    static let notificationsEnabled = SettingsKey<Bool>(key: "notificationsEnabled", defaultValue: true)
    static let warningEnabled = SettingsKey<Bool>(key: "warningEnabled", defaultValue: true)
    static let capacityFullEnabled = SettingsKey<Bool>(key: "capacityFullEnabled", defaultValue: true)
    static let resetCompleteEnabled = SettingsKey<Bool>(key: "resetCompleteEnabled", defaultValue: true)

    // Refresh Settings
    static let enablePowerAwareRefresh = SettingsKey<Bool>(key: "enablePowerAwareRefresh", defaultValue: true)
    static let reduceRefreshOnBattery = SettingsKey<Bool>(key: "reduceRefreshOnBattery", defaultValue: true)

    // General Settings
    static let launchAtLogin = SettingsKey<Bool>(key: "launchAtLogin", defaultValue: false)
    static let checkForUpdates = SettingsKey<Bool>(key: "checkForUpdates", defaultValue: true)
}

public extension SettingsKey where Value == Int {
    // Refresh Settings (minutes)
    static let refreshInterval = SettingsKey<Int>(key: "refreshInterval", defaultValue: 5)

    // Notification Settings (percentage)
    static let warningThreshold = SettingsKey<Int>(key: "warningThreshold", defaultValue: 90)
}

public extension SettingsKey where Value == PercentageSource {
    // Display Settings
    static let percentageSource = SettingsKey<PercentageSource>(
        key: "percentageSource",
        defaultValue: .highest
    )
}

public extension SettingsKey where Value == PlanType {
    // Display Settings
    static let planType = SettingsKey<PlanType>(
        key: "planType",
        defaultValue: .pro
    )
}

public extension SettingsKey where Value == IconStyle {
    // Display Settings
    static let iconStyle = SettingsKey<IconStyle>(
        key: "iconStyle",
        defaultValue: .percentage
    )
}

public extension SettingsKey where Value == Date? {
    // Update Checker Settings
    static let lastUpdateCheckDate = SettingsKey<Date?>(
        key: "lastUpdateCheckDate",
        defaultValue: nil
    )
}
