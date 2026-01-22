import Foundation

// MARK: - SettingsRepository

/// Protocol for persisting and retrieving settings.
/// Abstracted to allow different storage backends (UserDefaults, file-based, etc.).
public protocol SettingsRepository: Sendable {
    /// Retrieves a value for the given settings key.
    /// Returns the key's default value if no value is stored.
    func get<T: Codable & Sendable>(_ key: SettingsKey<T>) -> T

    /// Stores a value for the given settings key.
    func set<T: Codable & Sendable>(_ key: SettingsKey<T>, value: T)
}
