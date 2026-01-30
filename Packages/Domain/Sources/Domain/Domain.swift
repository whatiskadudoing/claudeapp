// Domain Package
// Core business models with zero internal dependencies
// This is the LEAF node in the dependency graph

// All public types are defined in separate files:
// - UsageWindow.swift: Usage window with utilization and reset time
// - UsageData.swift: Aggregated usage data across all windows
// - UsageDataPoint.swift: Historical usage data point for sparklines
// - Credentials.swift: OAuth credentials for API authentication
// - AppError.swift: Application error types
// - UsageRepository.swift: Protocol for fetching usage data
// - CredentialsRepository.swift: Protocol for accessing credentials
// - SettingsRepository.swift: Protocol for persisting settings
// - SettingsKey.swift: Type-safe settings key definitions
// - PlanType.swift: Subscription plan types
// - IconStyle.swift: Menu bar icon display styles
// - PercentageSource.swift: Usage percentage source options
// - BurnRate.swift: Usage consumption velocity model
// - ExportedSettings.swift: Settings export/import model
// - Account.swift: Multi-account user account model
// - AccountStorage.swift: Protocol for persisting accounts
// - MultiAccountDisplayMode.swift: Multi-account display mode options

public enum Domain {
    public static let version = "2.0.0"
}
