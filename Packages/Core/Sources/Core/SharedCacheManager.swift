import Domain
import Foundation

// MARK: - Cache Freshness

/// Indicates the freshness state of cached usage data.
/// Used by CLI to determine appropriate exit codes and warnings.
public enum CacheFreshness: Sendable, Equatable {
    /// Cache is fresh (less than 5 minutes old)
    case fresh

    /// Cache is stale (5-15 minutes old) - still usable with warning
    case stale

    /// Cache is expired (more than 15 minutes old) - data may be unreliable
    case expired

    /// No cached data available
    case none
}

// MARK: - Cache TTL Constants

/// Module-level constants for cache freshness thresholds.
/// Defined outside the MainActor class for Sendable access.
public enum CacheTTL {
    /// Threshold for "fresh" data (5 minutes in seconds)
    public static let freshThreshold: TimeInterval = 300

    /// Threshold for "expired" data (15 minutes in seconds)
    public static let expiredThreshold: TimeInterval = 900
}

// MARK: - Cached Usage Data

/// Wrapper for cached usage data with timestamp and freshness calculation.
/// Codable for JSON persistence in shared UserDefaults.
public struct CachedUsageData: Sendable, Equatable, Codable {
    /// The cached usage data
    public let data: UsageData

    /// When the data was cached
    public let timestamp: Date

    public init(data: UsageData, timestamp: Date = Date()) {
        self.data = data
        self.timestamp = timestamp
    }

    /// Calculates the freshness of the cached data relative to now.
    /// - Parameter now: Current time (defaults to Date())
    /// - Returns: Freshness state based on age
    public func freshness(at now: Date = Date()) -> CacheFreshness {
        let age = now.timeIntervalSince(timestamp)

        if age < CacheTTL.freshThreshold {
            return .fresh
        } else if age < CacheTTL.expiredThreshold {
            return .stale
        } else {
            return .expired
        }
    }

    /// Age of the cached data in seconds
    public var ageInSeconds: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Shared Cache Manager

/// Manages shared usage data cache between GUI app and CLI.
///
/// Uses App Group UserDefaults for cross-process data sharing.
/// The GUI app writes to the cache on each refresh, and the CLI reads from it.
///
/// Cache freshness thresholds:
/// - **Fresh:** < 5 minutes (normal operation)
/// - **Stale:** 5-15 minutes (usable with warning)
/// - **Expired:** > 15 minutes (data may be unreliable)
///
/// Usage:
/// ```swift
/// // GUI app - write on refresh
/// let manager = SharedCacheManager()
/// manager.writeUsageCache(usageData)
///
/// // CLI - read cached data
/// if let cached = manager.readUsageCache() {
///     let freshness = cached.freshness()
///     print(cached.data)
/// }
/// ```
@MainActor
public final class SharedCacheManager {
    // MARK: - TTL Constants (aliases for backward compatibility)

    /// Threshold for "fresh" data (5 minutes in seconds)
    public static let freshThreshold: TimeInterval = CacheTTL.freshThreshold

    /// Threshold for "expired" data (15 minutes in seconds)
    public static let expiredThreshold: TimeInterval = CacheTTL.expiredThreshold

    /// The App Group identifier for shared UserDefaults
    public static let appGroupIdentifier = "group.com.kaduwaengertner.ClaudeApp"

    // MARK: - Storage Keys

    private static let usageDataKey = "cachedUsageData"

    // MARK: - Dependencies

    private let userDefaults: UserDefaults?

    // MARK: - Initialization

    /// Creates a SharedCacheManager using the App Group UserDefaults.
    /// - Parameter userDefaults: Optional UserDefaults for testing. If nil, uses App Group suite.
    public init(userDefaults: UserDefaults? = nil) {
        if let userDefaults {
            self.userDefaults = userDefaults
        } else {
            // Use App Group UserDefaults for real usage
            self.userDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        }
    }

    // MARK: - Write Operations

    /// Writes usage data to the shared cache.
    ///
    /// The data is JSON-encoded and stored in App Group UserDefaults
    /// along with a timestamp for freshness calculation.
    ///
    /// - Parameter data: The usage data to cache
    /// - Returns: True if write succeeded, false otherwise
    @discardableResult
    public func writeUsageCache(_ data: UsageData) -> Bool {
        guard let defaults = userDefaults else {
            return false
        }

        let cached = CachedUsageData(data: data, timestamp: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let encoded = try? encoder.encode(cached) else {
            return false
        }

        defaults.set(encoded, forKey: Self.usageDataKey)
        return true
    }

    // MARK: - Read Operations

    /// Reads cached usage data from the shared cache.
    ///
    /// Returns nil if:
    /// - App Group UserDefaults is not available
    /// - No cached data exists
    /// - Data cannot be decoded
    ///
    /// - Returns: CachedUsageData with data and timestamp, or nil
    public func readUsageCache() -> CachedUsageData? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: Self.usageDataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(CachedUsageData.self, from: data)
    }

    /// Returns the freshness state of the current cache.
    /// - Returns: CacheFreshness indicating how recent the cached data is
    public func cacheFreshness() -> CacheFreshness {
        guard let cached = readUsageCache() else {
            return .none
        }
        return cached.freshness()
    }

    /// Returns the age of the cached data in seconds.
    /// - Returns: Age in seconds, or nil if no cache exists
    public func cacheAge() -> TimeInterval? {
        guard let cached = readUsageCache() else {
            return nil
        }
        return cached.ageInSeconds
    }

    // MARK: - Cache Management

    /// Clears all cached usage data.
    /// Useful for testing or when user signs out.
    public func clearCache() {
        guard let defaults = userDefaults else { return }
        defaults.removeObject(forKey: Self.usageDataKey)
    }

    /// Checks if the App Group UserDefaults is available.
    /// - Returns: True if App Group access is configured, false otherwise
    public var isAppGroupAvailable: Bool {
        userDefaults != nil
    }
}
