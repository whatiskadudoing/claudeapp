// Domain Package
// Core business models with zero internal dependencies
// This is the LEAF node in the dependency graph

// All public types are defined in separate files:
// - UsageWindow.swift: Usage window with utilization and reset time
// - UsageData.swift: Aggregated usage data across all windows
// - Credentials.swift: OAuth credentials for API authentication
// - AppError.swift: Application error types
// - UsageRepository.swift: Protocol for fetching usage data
// - CredentialsRepository.swift: Protocol for accessing credentials

public enum Domain {
    public static let version = "1.2.0"
}
