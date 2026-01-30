import Foundation

// MARK: - ExportedSettings

/// Represents a complete settings export for backup, restore, and migration.
///
/// The structure follows a versioned schema that allows for future compatibility:
/// - `version`: Schema version (currently "1.0")
/// - `exportedAt`: ISO 8601 timestamp when the export was created
/// - `appVersion`: The app version that created the export
/// - `settings`: All user-configurable settings grouped by category
/// - `usageHistory`: Optional usage history data for sparkline charts
public struct ExportedSettings: Codable, Sendable, Equatable {
    /// Schema version for compatibility checking
    public let version: String

    /// When the settings were exported
    public let exportedAt: Date

    /// App version that created this export
    public let appVersion: String

    /// All settings organized by category
    public let settings: SettingsPayload

    /// Optional usage history data (increases file size)
    public let usageHistory: UsageHistoryPayload?

    /// Current schema version
    public static let currentVersion = "1.0"

    public init(
        version: String = ExportedSettings.currentVersion,
        exportedAt: Date,
        appVersion: String,
        settings: SettingsPayload,
        usageHistory: UsageHistoryPayload? = nil
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.settings = settings
        self.usageHistory = usageHistory
    }
}

// MARK: - SettingsPayload

public extension ExportedSettings {
    /// Container for all settings grouped by category.
    struct SettingsPayload: Codable, Sendable, Equatable {
        public let display: DisplaySettings
        public let refresh: RefreshSettings
        public let notifications: NotificationSettings
        public let general: GeneralSettings

        public init(
            display: DisplaySettings,
            refresh: RefreshSettings,
            notifications: NotificationSettings,
            general: GeneralSettings
        ) {
            self.display = display
            self.refresh = refresh
            self.notifications = notifications
            self.general = general
        }
    }
}

// MARK: - DisplaySettings

public extension ExportedSettings {
    /// Display-related settings.
    struct DisplaySettings: Codable, Sendable, Equatable {
        /// Menu bar icon style (e.g., "percentage", "progressBar", "battery")
        public let iconStyle: String

        /// Whether to show the plan badge (Pro, Max 5x, Max 20x)
        public let showPlanBadge: Bool

        /// Whether to show percentage in the menu bar
        public let showPercentage: Bool

        /// Which usage metric to display (e.g., "highest", "session", "weekly")
        public let percentageSource: String

        /// Whether to show sparkline charts below progress bars
        public let showSparklines: Bool

        /// User's subscription plan type (e.g., "pro", "max5x", "max20x")
        public let planType: String

        public init(
            iconStyle: String,
            showPlanBadge: Bool,
            showPercentage: Bool,
            percentageSource: String,
            showSparklines: Bool,
            planType: String
        ) {
            self.iconStyle = iconStyle
            self.showPlanBadge = showPlanBadge
            self.showPercentage = showPercentage
            self.percentageSource = percentageSource
            self.showSparklines = showSparklines
            self.planType = planType
        }
    }
}

// MARK: - RefreshSettings

public extension ExportedSettings {
    /// Refresh-related settings.
    struct RefreshSettings: Codable, Sendable, Equatable {
        /// Refresh interval in minutes (1-30)
        public let interval: Int

        /// Whether power-aware (smart) refresh is enabled
        public let enablePowerAwareRefresh: Bool

        /// Whether to reduce refresh frequency on battery
        public let reduceRefreshOnBattery: Bool

        public init(
            interval: Int,
            enablePowerAwareRefresh: Bool,
            reduceRefreshOnBattery: Bool
        ) {
            self.interval = interval
            self.enablePowerAwareRefresh = enablePowerAwareRefresh
            self.reduceRefreshOnBattery = reduceRefreshOnBattery
        }
    }
}

// MARK: - NotificationSettings

public extension ExportedSettings {
    /// Notification-related settings.
    struct NotificationSettings: Codable, Sendable, Equatable {
        /// Master toggle for notifications
        public let enabled: Bool

        /// Warning threshold percentage (50-99)
        public let warningThreshold: Int

        /// Whether usage warning notifications are enabled
        public let warningEnabled: Bool

        /// Whether capacity full (100%) notifications are enabled
        public let capacityFullEnabled: Bool

        /// Whether reset complete notifications are enabled
        public let resetCompleteEnabled: Bool

        public init(
            enabled: Bool,
            warningThreshold: Int,
            warningEnabled: Bool,
            capacityFullEnabled: Bool,
            resetCompleteEnabled: Bool
        ) {
            self.enabled = enabled
            self.warningThreshold = warningThreshold
            self.warningEnabled = warningEnabled
            self.capacityFullEnabled = capacityFullEnabled
            self.resetCompleteEnabled = resetCompleteEnabled
        }
    }
}

// MARK: - GeneralSettings

public extension ExportedSettings {
    /// General app settings.
    struct GeneralSettings: Codable, Sendable, Equatable {
        /// Whether to launch the app at login
        public let launchAtLogin: Bool

        /// Whether to automatically check for updates
        public let checkForUpdates: Bool

        public init(
            launchAtLogin: Bool,
            checkForUpdates: Bool
        ) {
            self.launchAtLogin = launchAtLogin
            self.checkForUpdates = checkForUpdates
        }
    }
}

// MARK: - UsageHistoryPayload

public extension ExportedSettings {
    /// Optional usage history data for sparkline charts.
    struct UsageHistoryPayload: Codable, Sendable, Equatable {
        /// History for 5-hour session window
        public let sessionHistory: [UsageDataPoint]

        /// History for 7-day weekly window
        public let weeklyHistory: [UsageDataPoint]

        public init(
            sessionHistory: [UsageDataPoint],
            weeklyHistory: [UsageDataPoint]
        ) {
            self.sessionHistory = sessionHistory
            self.weeklyHistory = weeklyHistory
        }
    }
}

// MARK: - Import Validation

public extension ExportedSettings {
    /// Result of validating an imported settings file.
    struct ValidationResult: Sendable, Equatable {
        /// Whether the import is valid and can be applied
        public let isValid: Bool

        /// Human-readable validation messages
        public let messages: [String]

        /// Summary of settings to be imported
        public let summary: ImportSummary?

        public init(isValid: Bool, messages: [String], summary: ImportSummary?) {
            self.isValid = isValid
            self.messages = messages
            self.summary = summary
        }
    }

    /// Summary of what will be imported.
    struct ImportSummary: Sendable, Equatable {
        /// Number of display settings to import
        public let displaySettingsCount: Int

        /// Number of refresh settings to import
        public let refreshSettingsCount: Int

        /// Number of notification settings to import
        public let notificationSettingsCount: Int

        /// Number of general settings to import
        public let generalSettingsCount: Int

        /// Whether usage history is included
        public let includesUsageHistory: Bool

        /// Session history point count (if included)
        public let sessionHistoryPoints: Int

        /// Weekly history point count (if included)
        public let weeklyHistoryPoints: Int

        public init(
            displaySettingsCount: Int,
            refreshSettingsCount: Int,
            notificationSettingsCount: Int,
            generalSettingsCount: Int,
            includesUsageHistory: Bool,
            sessionHistoryPoints: Int,
            weeklyHistoryPoints: Int
        ) {
            self.displaySettingsCount = displaySettingsCount
            self.refreshSettingsCount = refreshSettingsCount
            self.notificationSettingsCount = notificationSettingsCount
            self.generalSettingsCount = generalSettingsCount
            self.includesUsageHistory = includesUsageHistory
            self.sessionHistoryPoints = sessionHistoryPoints
            self.weeklyHistoryPoints = weeklyHistoryPoints
        }
    }

    /// Validates the exported settings for import compatibility.
    /// - Returns: Validation result with messages and summary
    func validate() -> ValidationResult {
        var messages: [String] = []
        let isValid = true

        // Check version compatibility
        if version != Self.currentVersion {
            messages.append("Warning: Settings version \(version) differs from current version \(Self.currentVersion)")
        }

        // Validate display settings
        if IconStyle(rawValue: settings.display.iconStyle) == nil {
            messages.append("Warning: Unknown icon style '\(settings.display.iconStyle)', will use default")
        }
        if PercentageSource(rawValue: settings.display.percentageSource) == nil {
            messages.append("Warning: Unknown percentage source '\(settings.display.percentageSource)', will use default")
        }
        if PlanType(rawValue: settings.display.planType) == nil {
            messages.append("Warning: Unknown plan type '\(settings.display.planType)', will use default")
        }

        // Validate refresh settings
        if settings.refresh.interval < 1 || settings.refresh.interval > 30 {
            messages.append("Warning: Refresh interval \(settings.refresh.interval) out of range (1-30), will be clamped")
        }

        // Validate notification settings
        if settings.notifications.warningThreshold < 50 || settings.notifications.warningThreshold > 99 {
            messages.append("Warning: Warning threshold \(settings.notifications.warningThreshold) out of range (50-99), will be clamped")
        }

        // Build summary
        let summary = ImportSummary(
            displaySettingsCount: 6, // iconStyle, showPlanBadge, showPercentage, percentageSource, showSparklines, planType
            refreshSettingsCount: 3, // interval, enablePowerAwareRefresh, reduceRefreshOnBattery
            notificationSettingsCount: 5, // enabled, warningThreshold, warningEnabled, capacityFullEnabled, resetCompleteEnabled
            generalSettingsCount: 2, // launchAtLogin, checkForUpdates
            includesUsageHistory: usageHistory != nil,
            sessionHistoryPoints: usageHistory?.sessionHistory.count ?? 0,
            weeklyHistoryPoints: usageHistory?.weeklyHistory.count ?? 0
        )

        if messages.isEmpty {
            messages.append("All settings valid")
        }

        return ValidationResult(isValid: isValid, messages: messages, summary: summary)
    }
}
