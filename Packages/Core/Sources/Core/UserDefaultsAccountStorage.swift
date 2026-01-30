import Domain
import Foundation

// MARK: - UserDefaultsAccountStorage

/// Concrete implementation of AccountStorage using UserDefaults.
/// Stores accounts as JSON-encoded data in UserDefaults.
public final class UserDefaultsAccountStorage: AccountStorage, @unchecked Sendable {
    // MARK: - Constants

    /// The UserDefaults key for storing accounts
    private static let accountsKey = "savedAccounts"

    // MARK: - Properties

    private let defaults: UserDefaults

    // MARK: - Initialization

    /// Creates a new UserDefaultsAccountStorage.
    /// - Parameter defaults: The UserDefaults instance to use for persistence. Defaults to standard.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - AccountStorage Protocol

    /// Loads all saved accounts from UserDefaults.
    /// - Returns: Array of accounts, empty if none exist or decoding fails
    public func loadAccounts() -> [Account] {
        guard let data = defaults.data(forKey: Self.accountsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Account].self, from: data)
        } catch {
            // Return empty array if decoding fails (e.g., corrupted data or schema change)
            return []
        }
    }

    /// Saves all accounts to UserDefaults, replacing any existing data.
    /// - Parameter accounts: The accounts to save
    public func saveAccounts(_ accounts: [Account]) {
        guard let data = try? JSONEncoder().encode(accounts) else {
            return
        }
        defaults.set(data, forKey: Self.accountsKey)
    }

    // MARK: - Additional Methods

    /// Clears all stored accounts. Primarily used for testing.
    public func clearAccounts() {
        defaults.removeObject(forKey: Self.accountsKey)
    }
}
