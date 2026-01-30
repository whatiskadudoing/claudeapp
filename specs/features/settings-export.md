# Feature: Settings Export/Import

## Overview

Allow users to export and import settings as JSON files, enabling backup, migration, and sharing of configurations.

---

## Research References

> **Sources:**
> - [Rectangle](https://github.com/rxhanson/Rectangle) (28K stars) - JSON-based config export/import from Preferences
> - [SwiftBar](https://github.com/swiftbar/SwiftBar) (3.7K stars) - Folder-based configuration import
> - [SketchyBar](https://github.com/FelixKratz/SketchyBar) (11K stars) - Shell script configuration at `~/.config/`
> - [Mackup](https://github.com/lra/mackup) (15K stars) - Settings backup supporting multiple backends
> - Research document: `research/advanced-settings-patterns.md`

---

## User Story

**As a** ClaudeApp user
**I want to** export and import my settings
**So that** I can backup my configuration, migrate to a new machine, or share settings with teammates

---

## Export Format

### JSON Schema

```json
{
  "version": "1.0",
  "exportedAt": "2026-01-26T12:00:00Z",
  "appVersion": "1.6.0",
  "settings": {
    "display": {
      "iconStyle": "percentage",
      "showPlanBadge": false,
      "showPercentage": true,
      "percentageSource": "highest",
      "showSparklines": true
    },
    "refresh": {
      "interval": 5,
      "enablePowerAwareRefresh": true,
      "reduceRefreshOnBattery": true
    },
    "notifications": {
      "enabled": true,
      "warningThreshold": 90,
      "warningEnabled": true,
      "capacityFullEnabled": true,
      "resetCompleteEnabled": true
    },
    "general": {
      "launchAtLogin": false,
      "checkForUpdates": true
    }
  },
  "accounts": [
    {
      "name": "Personal",
      "isPrimary": true,
      "isActive": true
    }
  ]
}
```

### Export Options

| Option | Default | Description |
|--------|---------|-------------|
| Include accounts | Yes | Export account names (not credentials) |
| Include usage history | No | Export sparkline history data |

---

## Settings UI

### Export/Import Section

```
┌──────────────────────────────────────┐
│ Data ────────────────────────────    │
│ ┌──────────────────────────────────┐ │
│ │ [ Export Settings... ]           │ │
│ │                                  │ │
│ │ [ Import Settings... ]           │ │
│ │                                  │ │
│ │ [ Reset to Defaults ]            │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Export Dialog

```
┌─────────────────────────────────────────────────┐
│ Export Settings                                  │
│                                                  │
│  ☑ Include account names                        │
│  ☐ Include usage history (increases file size)  │
│                                                  │
│             [ Cancel ]  [ Export... ]            │
└─────────────────────────────────────────────────┘
```

### Import Confirmation

```
┌─────────────────────────────────────────────────┐
│ Import Settings                                  │
│                                                  │
│  This will replace your current settings with   │
│  the imported configuration.                    │
│                                                  │
│  Settings to import:                            │
│  • Display: Icon style, percentage source       │
│  • Refresh: 5 minute interval                   │
│  • Notifications: Warning at 90%                │
│  • 2 accounts                                   │
│                                                  │
│  ☑ Create backup before importing               │
│                                                  │
│             [ Cancel ]  [ Import ]               │
└─────────────────────────────────────────────────┘
```

---

## Implementation

### Settings Export Model

```swift
/// Represents exportable settings configuration
public struct ExportedSettings: Codable {
    public let version: String
    public let exportedAt: Date
    public let appVersion: String
    public let settings: SettingsPayload
    public let accounts: [ExportedAccount]?

    public struct SettingsPayload: Codable {
        public let display: DisplaySettings
        public let refresh: RefreshSettings
        public let notifications: NotificationSettings
        public let general: GeneralSettings
    }

    public struct DisplaySettings: Codable {
        public let iconStyle: String
        public let showPlanBadge: Bool
        public let showPercentage: Bool
        public let percentageSource: String
        public let showSparklines: Bool
    }

    public struct RefreshSettings: Codable {
        public let interval: Int
        public let enablePowerAwareRefresh: Bool
        public let reduceRefreshOnBattery: Bool
    }

    public struct NotificationSettings: Codable {
        public let enabled: Bool
        public let warningThreshold: Int
        public let warningEnabled: Bool
        public let capacityFullEnabled: Bool
        public let resetCompleteEnabled: Bool
    }

    public struct GeneralSettings: Codable {
        public let launchAtLogin: Bool
        public let checkForUpdates: Bool
    }

    public struct ExportedAccount: Codable {
        public let name: String
        public let isPrimary: Bool
        public let isActive: Bool
        // Note: Credentials are NEVER exported
    }
}
```

### Settings Export Manager

```swift
@MainActor
public final class SettingsExportManager {
    private let settingsRepository: SettingsRepository
    private let accountManager: AccountManager

    public init(
        settingsRepository: SettingsRepository,
        accountManager: AccountManager
    ) {
        self.settingsRepository = settingsRepository
        self.accountManager = accountManager
    }

    // MARK: - Export

    public func export(includeAccounts: Bool = true) -> ExportedSettings {
        ExportedSettings(
            version: "1.0",
            exportedAt: Date(),
            appVersion: Bundle.main.appVersion,
            settings: ExportedSettings.SettingsPayload(
                display: ExportedSettings.DisplaySettings(
                    iconStyle: settingsRepository.get(.iconStyle).rawValue,
                    showPlanBadge: settingsRepository.get(.showPlanBadge),
                    showPercentage: settingsRepository.get(.showPercentage),
                    percentageSource: settingsRepository.get(.percentageSource).rawValue,
                    showSparklines: settingsRepository.get(.showSparklines)
                ),
                refresh: ExportedSettings.RefreshSettings(
                    interval: settingsRepository.get(.refreshInterval),
                    enablePowerAwareRefresh: settingsRepository.get(.enablePowerAwareRefresh),
                    reduceRefreshOnBattery: settingsRepository.get(.reduceRefreshOnBattery)
                ),
                notifications: ExportedSettings.NotificationSettings(
                    enabled: settingsRepository.get(.notificationsEnabled),
                    warningThreshold: settingsRepository.get(.warningThreshold),
                    warningEnabled: settingsRepository.get(.warningEnabled),
                    capacityFullEnabled: settingsRepository.get(.capacityFullEnabled),
                    resetCompleteEnabled: settingsRepository.get(.resetCompleteEnabled)
                ),
                general: ExportedSettings.GeneralSettings(
                    launchAtLogin: LaunchAtLoginManager.shared.isEnabled,
                    checkForUpdates: settingsRepository.get(.checkForUpdates)
                )
            ),
            accounts: includeAccounts ? exportAccounts() : nil
        )
    }

    public func exportToFile(url: URL, includeAccounts: Bool = true) throws {
        let exported = export(includeAccounts: includeAccounts)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exported)
        try data.write(to: url)
    }

    private func exportAccounts() -> [ExportedSettings.ExportedAccount] {
        accountManager.accounts.map { account in
            ExportedSettings.ExportedAccount(
                name: account.name,
                isPrimary: account.isPrimary,
                isActive: account.isActive
            )
        }
    }

    // MARK: - Import

    public func importFromFile(url: URL) throws -> ExportedSettings {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportedSettings.self, from: data)
    }

    public func applySettings(_ exported: ExportedSettings) {
        // Display settings
        if let iconStyle = IconStyle(rawValue: exported.settings.display.iconStyle) {
            settingsRepository.set(.iconStyle, value: iconStyle)
        }
        settingsRepository.set(.showPlanBadge, value: exported.settings.display.showPlanBadge)
        settingsRepository.set(.showPercentage, value: exported.settings.display.showPercentage)
        if let percentageSource = PercentageSource(rawValue: exported.settings.display.percentageSource) {
            settingsRepository.set(.percentageSource, value: percentageSource)
        }
        settingsRepository.set(.showSparklines, value: exported.settings.display.showSparklines)

        // Refresh settings
        settingsRepository.set(.refreshInterval, value: exported.settings.refresh.interval)
        settingsRepository.set(.enablePowerAwareRefresh, value: exported.settings.refresh.enablePowerAwareRefresh)
        settingsRepository.set(.reduceRefreshOnBattery, value: exported.settings.refresh.reduceRefreshOnBattery)

        // Notification settings
        settingsRepository.set(.notificationsEnabled, value: exported.settings.notifications.enabled)
        settingsRepository.set(.warningThreshold, value: exported.settings.notifications.warningThreshold)
        settingsRepository.set(.warningEnabled, value: exported.settings.notifications.warningEnabled)
        settingsRepository.set(.capacityFullEnabled, value: exported.settings.notifications.capacityFullEnabled)
        settingsRepository.set(.resetCompleteEnabled, value: exported.settings.notifications.resetCompleteEnabled)

        // General settings
        LaunchAtLoginManager.shared.isEnabled = exported.settings.general.launchAtLogin
        settingsRepository.set(.checkForUpdates, value: exported.settings.general.checkForUpdates)
    }

    // MARK: - Backup

    public func createBackup() throws -> URL {
        let backupDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClaudeApp/Backups", isDirectory: true)

        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let backupURL = backupDir.appendingPathComponent("settings-backup-\(timestamp).json")

        try exportToFile(url: backupURL, includeAccounts: true)
        return backupURL
    }

    // MARK: - Reset

    public func resetToDefaults() {
        // Clear all user defaults for app
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        // Reset launch at login
        LaunchAtLoginManager.shared.isEnabled = false
    }
}
```

### SwiftUI Integration

```swift
struct DataSettingsSection: View {
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showResetConfirmation = false
    @State private var exportResult: Result<URL, Error>?

    var body: some View {
        Section("Data") {
            Button("Export Settings...") {
                showExportSheet = true
            }

            Button("Import Settings...") {
                showImportPicker = true
            }

            Button("Reset to Defaults", role: .destructive) {
                showResetConfirmation = true
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSettingsSheet()
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            onCompletion: handleImport
        )
        .confirmationDialog(
            "Reset to Defaults",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset All Settings", role: .destructive) {
                SettingsExportManager.shared.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all settings to their default values. This cannot be undone.")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        // Implementation
    }
}

struct ExportSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var includeAccounts = true
    @State private var includeHistory = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Include account names", isOn: $includeAccounts)
                Toggle("Include usage history", isOn: $includeHistory)
                    .help("Increases file size")
            }
            .padding()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Export...") {
                    exportSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func exportSettings() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "ClaudeApp-Settings.json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try SettingsExportManager.shared.exportToFile(
                    url: url,
                    includeAccounts: includeAccounts
                )
                dismiss()
            } catch {
                // Handle error
            }
        }
    }
}
```

---

## Auto-Loading Configuration

Like Rectangle, support auto-loading config from a known location:

```swift
extension SettingsExportManager {
    private static let autoLoadPath = "~/Library/Application Support/ClaudeApp/ClaudeAppConfig.json"

    /// Check for and load auto-config on app launch
    func checkAutoLoadConfig() {
        let path = NSString(string: Self.autoLoadPath).expandingTildeInPath
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else { return }

        do {
            let settings = try importFromFile(url: url)
            applySettings(settings)
            print("Auto-loaded settings from \(path)")
        } catch {
            print("Failed to auto-load settings: \(error)")
        }
    }
}
```

---

## URL Scheme Support

Support importing via URL scheme (like SwiftBar):

```swift
// URL: claudeapp://import?url=https://example.com/settings.json

extension ClaudeApp {
    func handleURL(_ url: URL) {
        guard url.scheme == "claudeapp" else { return }

        switch url.host {
        case "import":
            if let settingsURL = url.queryParameters["url"],
               let url = URL(string: settingsURL) {
                importSettingsFromURL(url)
            }
        default:
            break
        }
    }
}
```

---

## Security Considerations

### What is NEVER Exported

- OAuth access tokens
- Refresh tokens
- Keychain credentials
- Any authentication data

### File Permissions

- Exported files are user-readable only (0600)
- Backup directory protected by macOS sandboxing

---

## Acceptance Criteria

### Must Have

- [x] Export settings to JSON file
- [x] Import settings from JSON file
- [x] Reset to defaults option
- [x] Confirmation dialog before import/reset
- [x] Create backup before import (optional)

### Should Have

- [x] Include/exclude accounts option
- [x] Pretty-printed JSON output
- [x] Version compatibility check on import
- [x] Show summary of settings to import

### Nice to Have

- [ ] Auto-load config from standard location
- [ ] URL scheme for importing
- [ ] iCloud sync via App Group
- [ ] Diff view showing changes before import

---

## Related Specifications

- [settings.md](./settings.md) - Settings integration
- [multi-account.md](./multi-account.md) - Account export/import
- [architecture.md](../architecture.md) - Storage patterns
