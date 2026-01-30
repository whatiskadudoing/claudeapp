import Foundation

// MARK: - AccountStorage

/// Protocol for persisting and retrieving accounts.
/// Implemented by UserDefaultsAccountStorage in the Core package.
///
/// All methods are synchronous since account data is small and stored locally.
/// The protocol is designed to be simple with no async operations needed.
public protocol AccountStorage: Sendable {
    /// Loads all saved accounts from storage.
    /// - Returns: Array of accounts, empty if none exist
    func loadAccounts() -> [Account]

    /// Saves all accounts to storage, replacing any existing data.
    /// - Parameter accounts: The accounts to save
    func saveAccounts(_ accounts: [Account])
}
