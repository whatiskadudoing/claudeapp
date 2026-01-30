import Domain
import Foundation

// MARK: - AccountManager

/// Manages multiple Claude accounts with CRUD operations and state tracking.
/// Uses @Observable for SwiftUI integration and persists changes to storage.
///
/// The AccountManager handles:
/// - Account CRUD operations (add, remove, update)
/// - Active account selection for usage display
/// - Primary account designation for default display
/// - Migration from single-account to multi-account setup
@MainActor
@Observable
public final class AccountManager {
    // MARK: - Observable State

    /// All registered accounts
    public private(set) var accounts: [Account] = []

    /// The ID of the currently active/selected account for display
    public private(set) var activeAccountId: UUID?

    // MARK: - Dependencies

    private let storage: AccountStorage

    // MARK: - Computed Properties

    /// Currently selected account for display.
    /// Returns the account matching activeAccountId, or nil if not found.
    public var activeAccount: Account? {
        guard let id = activeAccountId else { return nil }
        return accounts.first { $0.id == id }
    }

    /// Primary account (default when app launches).
    /// Falls back to first account if no explicit primary is set.
    public var primaryAccount: Account? {
        accounts.first { $0.isPrimary } ?? accounts.first
    }

    /// Whether migration has occurred (accounts exist)
    public var hasAccounts: Bool {
        !accounts.isEmpty
    }

    /// Number of active (enabled) accounts
    public var activeAccountCount: Int {
        accounts.filter(\.isActive).count
    }

    // MARK: - Initialization

    /// Creates a new AccountManager, loading existing accounts from storage.
    /// - Parameter storage: The storage implementation for persistence. Defaults to UserDefaultsAccountStorage.
    public init(storage: AccountStorage = UserDefaultsAccountStorage()) {
        self.storage = storage
        loadAccounts()
    }

    // MARK: - CRUD Operations

    /// Adds a new account.
    /// If this is the first account, it automatically becomes primary.
    /// The new account becomes the active account.
    /// - Parameter account: The account to add
    public func addAccount(_ account: Account) {
        var newAccount = account

        // If first account, make it primary
        if accounts.isEmpty {
            newAccount.isPrimary = true
        }

        accounts.append(newAccount)
        saveAccounts()

        // Activate new account
        activeAccountId = newAccount.id
    }

    /// Removes an account.
    /// If the removed account was active, switches to primary.
    /// If the removed account was primary, assigns a new primary.
    /// - Parameter account: The account to remove
    public func removeAccount(_ account: Account) {
        let wasActive = activeAccountId == account.id
        let wasPrimary = account.isPrimary

        accounts.removeAll { $0.id == account.id }

        // If removed active account, switch to primary
        if wasActive {
            activeAccountId = primaryAccount?.id
        }

        // If removed primary, assign new primary
        if wasPrimary, !accounts.isEmpty {
            if let firstIndex = accounts.indices.first {
                accounts[firstIndex].isPrimary = true
            }
        }

        saveAccounts()
    }

    /// Updates an existing account's data.
    /// If the account doesn't exist, this operation is a no-op.
    /// - Parameter account: The account with updated values
    public func updateAccount(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        saveAccounts()
    }

    /// Sets the active account for display.
    /// - Parameter accountId: The ID of the account to activate
    public func setActiveAccount(_ accountId: UUID) {
        guard accounts.contains(where: { $0.id == accountId }) else { return }
        activeAccountId = accountId
    }

    /// Sets a specific account as primary.
    /// Only one account can be primary at a time.
    /// - Parameter accountId: The ID of the account to make primary
    public func setPrimaryAccount(_ accountId: UUID) {
        for i in accounts.indices {
            accounts[i].isPrimary = accounts[i].id == accountId
        }
        saveAccounts()
    }

    // MARK: - Migration

    /// Performs migration from single-account to multi-account setup.
    /// Creates a "Default" account using Claude Code credentials if no accounts exist.
    /// This should be called once during app initialization.
    public func migrateIfNeeded() {
        // Check if migration needed (no accounts exist yet)
        guard accounts.isEmpty else { return }

        // Create default account from existing credentials
        let defaultAccount = Account(
            name: "Default",
            keychainIdentifier: "default", // Uses "Claude Code-credentials"
            isActive: true,
            isPrimary: true
        )

        accounts.append(defaultAccount)
        activeAccountId = defaultAccount.id
        saveAccounts()
    }

    // MARK: - Persistence

    private func loadAccounts() {
        accounts = storage.loadAccounts()
        // Set active account to primary on load
        activeAccountId = primaryAccount?.id
    }

    private func saveAccounts() {
        storage.saveAccounts(accounts)
    }

    // MARK: - Testing Support

    /// Clears all accounts. Primarily used for testing.
    public func clearAllAccounts() {
        accounts = []
        activeAccountId = nil
        saveAccounts()
    }

    /// Reloads accounts from storage. Primarily used for testing.
    public func reload() {
        loadAccounts()
    }
}
