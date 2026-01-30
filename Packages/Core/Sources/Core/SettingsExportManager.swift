import Domain
import Foundation

// MARK: - SettingsExportManager

/// Manages settings export, import, backup, and reset functionality.
///
/// Features:
/// - Export settings to JSON file with optional usage history
/// - Import settings from JSON file with validation
/// - Create automatic backups before import
/// - Reset all settings to defaults
/// - Auto-load configuration from standard location
///
/// Security:
/// - Never exports credentials or authentication data
/// - Validates imported data before applying
@MainActor
public final class SettingsExportManager {
    // MARK: - Dependencies

    private let settingsManager: SettingsManager
    private let launchAtLoginManager: LaunchAtLoginManager
    private let usageHistoryManager: UsageHistoryManager?
    private let appVersionProvider: () -> String
    private let fileManager: FileManager

    // MARK: - Configuration

    /// Standard location for auto-loading configuration
    public static let autoLoadPath = "~/Library/Application Support/ClaudeApp/ClaudeAppConfig.json"

    /// Backup directory path
    public static let backupDirectoryPath = "~/Library/Application Support/ClaudeApp/Backups"

    // MARK: - Initialization

    /// Creates a new SettingsExportManager.
    /// - Parameters:
    ///   - settingsManager: The settings manager to export from / import to
    ///   - launchAtLoginManager: Manager for launch at login state
    ///   - usageHistoryManager: Optional history manager for chart data export
    ///   - appVersionProvider: Closure that returns the current app version
    ///   - fileManager: FileManager for file operations (defaults to .default)
    public init(
        settingsManager: SettingsManager,
        launchAtLoginManager: LaunchAtLoginManager,
        usageHistoryManager: UsageHistoryManager? = nil,
        appVersionProvider: @escaping () -> String = { Bundle.main.appVersion },
        fileManager: FileManager = .default
    ) {
        self.settingsManager = settingsManager
        self.launchAtLoginManager = launchAtLoginManager
        self.usageHistoryManager = usageHistoryManager
        self.appVersionProvider = appVersionProvider
        self.fileManager = fileManager
    }

    // MARK: - Export

    /// Exports current settings to an ExportedSettings structure.
    /// - Parameter includeUsageHistory: Whether to include usage history data
    /// - Returns: The exported settings
    public func export(includeUsageHistory: Bool = false) -> ExportedSettings {
        let displaySettings = ExportedSettings.DisplaySettings(
            iconStyle: settingsManager.iconStyle.rawValue,
            showPlanBadge: settingsManager.showPlanBadge,
            showPercentage: settingsManager.showPercentage,
            percentageSource: settingsManager.percentageSource.rawValue,
            showSparklines: settingsManager.showSparklines,
            planType: settingsManager.planType.rawValue
        )

        let refreshSettings = ExportedSettings.RefreshSettings(
            interval: settingsManager.refreshInterval,
            enablePowerAwareRefresh: settingsManager.enablePowerAwareRefresh,
            reduceRefreshOnBattery: settingsManager.reduceRefreshOnBattery
        )

        let notificationSettings = ExportedSettings.NotificationSettings(
            enabled: settingsManager.notificationsEnabled,
            warningThreshold: settingsManager.warningThreshold,
            warningEnabled: settingsManager.warningEnabled,
            capacityFullEnabled: settingsManager.capacityFullEnabled,
            resetCompleteEnabled: settingsManager.resetCompleteEnabled
        )

        let generalSettings = ExportedSettings.GeneralSettings(
            launchAtLogin: launchAtLoginManager.isEnabled,
            checkForUpdates: settingsManager.checkForUpdates
        )

        let settingsPayload = ExportedSettings.SettingsPayload(
            display: displaySettings,
            refresh: refreshSettings,
            notifications: notificationSettings,
            general: generalSettings
        )

        var usageHistory: ExportedSettings.UsageHistoryPayload?
        if includeUsageHistory, let historyManager = usageHistoryManager {
            usageHistory = ExportedSettings.UsageHistoryPayload(
                sessionHistory: historyManager.sessionHistory,
                weeklyHistory: historyManager.weeklyHistory
            )
        }

        return ExportedSettings(
            version: ExportedSettings.currentVersion,
            exportedAt: Date(),
            appVersion: appVersionProvider(),
            settings: settingsPayload,
            usageHistory: usageHistory
        )
    }

    /// Exports settings to a file.
    /// - Parameters:
    ///   - url: The file URL to write to
    ///   - includeUsageHistory: Whether to include usage history data
    /// - Throws: Error if file writing fails
    public func exportToFile(url: URL, includeUsageHistory: Bool = false) throws {
        let exported = export(includeUsageHistory: includeUsageHistory)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exported)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Import

    /// Imports settings from a file.
    /// - Parameter url: The file URL to read from
    /// - Returns: The parsed ExportedSettings
    /// - Throws: Error if file reading or parsing fails
    public func importFromFile(url: URL) throws -> ExportedSettings {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportedSettings.self, from: data)
    }

    /// Imports settings from JSON data.
    /// - Parameter data: The JSON data to parse
    /// - Returns: The parsed ExportedSettings
    /// - Throws: Error if parsing fails
    public func importFromData(_ data: Data) throws -> ExportedSettings {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportedSettings.self, from: data)
    }

    /// Applies imported settings to the app.
    /// - Parameters:
    ///   - exported: The settings to apply
    ///   - includeUsageHistory: Whether to import usage history (if present)
    public func applySettings(_ exported: ExportedSettings, includeUsageHistory: Bool = false) {
        // Apply display settings
        if let iconStyle = IconStyle(rawValue: exported.settings.display.iconStyle) {
            settingsManager.iconStyle = iconStyle
        }
        settingsManager.showPlanBadge = exported.settings.display.showPlanBadge
        settingsManager.showPercentage = exported.settings.display.showPercentage
        if let percentageSource = PercentageSource(rawValue: exported.settings.display.percentageSource) {
            settingsManager.percentageSource = percentageSource
        }
        settingsManager.showSparklines = exported.settings.display.showSparklines
        if let planType = PlanType(rawValue: exported.settings.display.planType) {
            settingsManager.planType = planType
        }

        // Apply refresh settings
        settingsManager.refreshInterval = exported.settings.refresh.interval
        settingsManager.enablePowerAwareRefresh = exported.settings.refresh.enablePowerAwareRefresh
        settingsManager.reduceRefreshOnBattery = exported.settings.refresh.reduceRefreshOnBattery

        // Apply notification settings
        settingsManager.notificationsEnabled = exported.settings.notifications.enabled
        settingsManager.warningThreshold = exported.settings.notifications.warningThreshold
        settingsManager.warningEnabled = exported.settings.notifications.warningEnabled
        settingsManager.capacityFullEnabled = exported.settings.notifications.capacityFullEnabled
        settingsManager.resetCompleteEnabled = exported.settings.notifications.resetCompleteEnabled

        // Apply general settings
        launchAtLoginManager.isEnabled = exported.settings.general.launchAtLogin
        settingsManager.checkForUpdates = exported.settings.general.checkForUpdates

        // Apply usage history if requested and present
        if includeUsageHistory, let history = exported.usageHistory, let historyManager = usageHistoryManager {
            historyManager.clearAllHistory()
            historyManager.importSessionHistory(history.sessionHistory)
            historyManager.importWeeklyHistory(history.weeklyHistory)
            historyManager.save()
        }
    }

    // MARK: - Backup

    /// Creates a backup of current settings.
    /// - Returns: The URL of the created backup file
    /// - Throws: Error if backup creation fails
    public func createBackup() throws -> URL {
        let backupPath = NSString(string: Self.backupDirectoryPath).expandingTildeInPath
        let backupDir = URL(fileURLWithPath: backupPath, isDirectory: true)

        // Create backup directory if needed
        try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)

        // Generate timestamped filename
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-") // Colons not allowed in filenames on macOS

        let backupURL = backupDir.appendingPathComponent("settings-backup-\(timestamp).json")

        // Export with usage history for complete backup
        try exportToFile(url: backupURL, includeUsageHistory: true)

        return backupURL
    }

    /// Lists existing backup files.
    /// - Returns: Array of backup file URLs, sorted by date (newest first)
    public func listBackups() -> [URL] {
        let backupPath = NSString(string: Self.backupDirectoryPath).expandingTildeInPath
        let backupDir = URL(fileURLWithPath: backupPath, isDirectory: true)

        guard let contents = try? fileManager.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        // Filter for JSON files and sort by creation date (newest first)
        return contents
            .filter { $0.pathExtension == "json" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return date1 > date2
            }
    }

    /// Deletes a backup file.
    /// - Parameter url: The backup file URL to delete
    /// - Throws: Error if deletion fails
    public func deleteBackup(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    // MARK: - Reset

    /// Resets all settings to defaults.
    /// - Parameter clearHistory: Whether to also clear usage history
    public func resetToDefaults(clearHistory: Bool = false) {
        // Reset display settings
        settingsManager.iconStyle = SettingsKey<IconStyle>.iconStyle.defaultValue
        settingsManager.showPlanBadge = SettingsKey<Bool>.showPlanBadge.defaultValue
        settingsManager.showPercentage = SettingsKey<Bool>.showPercentage.defaultValue
        settingsManager.percentageSource = SettingsKey<PercentageSource>.percentageSource.defaultValue
        settingsManager.showSparklines = SettingsKey<Bool>.showSparklines.defaultValue
        settingsManager.planType = SettingsKey<PlanType>.planType.defaultValue

        // Reset refresh settings
        settingsManager.refreshInterval = SettingsKey<Int>.refreshInterval.defaultValue
        settingsManager.enablePowerAwareRefresh = SettingsKey<Bool>.enablePowerAwareRefresh.defaultValue
        settingsManager.reduceRefreshOnBattery = SettingsKey<Bool>.reduceRefreshOnBattery.defaultValue

        // Reset notification settings
        settingsManager.notificationsEnabled = SettingsKey<Bool>.notificationsEnabled.defaultValue
        settingsManager.warningThreshold = SettingsKey<Int>.warningThreshold.defaultValue
        settingsManager.warningEnabled = SettingsKey<Bool>.warningEnabled.defaultValue
        settingsManager.capacityFullEnabled = SettingsKey<Bool>.capacityFullEnabled.defaultValue
        settingsManager.resetCompleteEnabled = SettingsKey<Bool>.resetCompleteEnabled.defaultValue

        // Reset general settings
        launchAtLoginManager.isEnabled = SettingsKey<Bool>.launchAtLogin.defaultValue
        settingsManager.checkForUpdates = SettingsKey<Bool>.checkForUpdates.defaultValue

        // Clear history if requested
        if clearHistory {
            usageHistoryManager?.clearAllHistory()
        }
    }

    // MARK: - Auto-Load

    /// Checks for and loads auto-configuration from standard location.
    /// - Returns: True if configuration was found and applied
    @discardableResult
    public func checkAutoLoadConfig() -> Bool {
        let path = NSString(string: Self.autoLoadPath).expandingTildeInPath
        let url = URL(fileURLWithPath: path)

        guard fileManager.fileExists(atPath: path) else {
            return false
        }

        do {
            let settings = try importFromFile(url: url)
            applySettings(settings, includeUsageHistory: false)
            return true
        } catch {
            // Silently fail - auto-load is optional
            return false
        }
    }

    /// Saves current settings to the auto-load location.
    /// - Throws: Error if saving fails
    public func saveToAutoLoadLocation() throws {
        let path = NSString(string: Self.autoLoadPath).expandingTildeInPath
        let url = URL(fileURLWithPath: path)

        // Create parent directory if needed
        let parentDir = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)

        try exportToFile(url: url, includeUsageHistory: false)
    }
}
