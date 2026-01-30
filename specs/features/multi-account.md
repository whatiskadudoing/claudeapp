# Feature: Multi-Account Support

## Overview

Support multiple Claude accounts/profiles, allowing users to monitor usage across different accounts (e.g., personal and work).

---

## Research References

> **Sources:**
> - [Claude Usage Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker) (684 stars) - Multi-profile menu bar display
> - [ClaudeBar](https://github.com/tddworks/ClaudeBar) (482 stars) - Multi-provider support pattern
> - [quotio](https://github.com/nguyenphutrong/quotio) (3,099 stars) - Unified multi-provider tracking
> - Research document: `research/competitive-analysis.md`

---

## User Story

**As a** developer with multiple Claude accounts
**I want to** monitor usage for all my accounts in one place
**So that** I can manage my usage across work and personal projects

---

## Use Cases

### Primary Use Cases

1. **Work + Personal accounts** - Developer has Claude Pro for personal use and work provides Max 20x
2. **Multiple projects** - Consultant works on different client projects with separate accounts
3. **Team monitoring** - Track shared team account alongside personal account

### User Flow

1. User opens Settings → Accounts
2. User clicks "Add Account"
3. User enters account name (e.g., "Work", "Personal")
4. App prompts for authentication (reads from different Keychain entry or manual token)
5. Account appears in list and dropdown

---

## Design

### Account Switcher in Dropdown

```
┌──────────────────────────────────────┐
│ ▾ Personal        [Med] ⚙️  🔄        │ ← Account switcher
├──────────────────────────────────────┤
│                                      │
│ Current Session (5h)           45%   │
│ ████████████░░░░░░░░░░░░░░░░░░░░░░  │
│ ...                                  │
└──────────────────────────────────────┘

        ↓ Click account name

┌──────────────────────────────────────┐
│ ▾ Personal ✓                         │
│   Work                               │
│   ─────────────                      │
│   + Add Account                      │
└──────────────────────────────────────┘
```

### Menu Bar Multi-Account Display

Option to show multiple accounts in menu bar:

```
┌─────────────────────────────┐
│ [✦] P:45% W:72%             │  ← Compact multi-account
└─────────────────────────────┘
```

Or separate icons:

```
┌───────────────────────────────┐
│ [✦] 45%  [✦] 72%              │  ← Dual icons
└───────────────────────────────┘
```

### Accounts Settings Section

```
┌──────────────────────────────────────┐
│ Accounts ────────────────────────    │
│ ┌──────────────────────────────────┐ │
│ │ ● Personal (Pro)           ✏️  🗑│ │
│ │   claude@personal.com             │ │
│ ├──────────────────────────────────┤ │
│ │ ○ Work (Max 20x)           ✏️  🗑│ │
│ │   claude@company.com              │ │
│ ├──────────────────────────────────┤ │
│ │       + Add Account               │ │
│ └──────────────────────────────────┘ │
│                                      │
│ Menu Bar Display ────────────────    │
│ ┌──────────────────────────────────┐ │
│ │ Show accounts     [All ▾]        │ │
│ │ Options: All / Active only /      │ │
│ │          Primary only             │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## Data Model

### Account

```swift
public struct Account: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var email: String?
    public var planType: PlanType?
    public var keychainIdentifier: String  // Keychain item name for credentials
    public var isActive: Bool
    public var isPrimary: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        planType: PlanType? = nil,
        keychainIdentifier: String,
        isActive: Bool = true,
        isPrimary: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.planType = planType
        self.keychainIdentifier = keychainIdentifier
        self.isActive = isActive
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}
```

### AccountManager

```swift
@MainActor
@Observable
public final class AccountManager {
    public private(set) var accounts: [Account] = []
    public private(set) var activeAccountId: UUID?

    /// Currently selected account for display
    public var activeAccount: Account? {
        accounts.first { $0.id == activeAccountId }
    }

    /// Primary account (default when app launches)
    public var primaryAccount: Account? {
        accounts.first { $0.isPrimary } ?? accounts.first
    }

    private let storage: AccountStorage

    public init(storage: AccountStorage = UserDefaultsAccountStorage()) {
        self.storage = storage
        loadAccounts()
    }

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

    public func removeAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }

        // If removed active account, switch to primary
        if activeAccountId == account.id {
            activeAccountId = primaryAccount?.id
        }

        // If removed primary, assign new primary
        if account.isPrimary, let first = accounts.first {
            var updated = first
            updated.isPrimary = true
            updateAccount(updated)
        }

        saveAccounts()
    }

    public func updateAccount(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        saveAccounts()
    }

    public func setActiveAccount(_ accountId: UUID) {
        activeAccountId = accountId
    }

    public func setPrimaryAccount(_ accountId: UUID) {
        for i in accounts.indices {
            accounts[i].isPrimary = accounts[i].id == accountId
        }
        saveAccounts()
    }

    private func loadAccounts() {
        accounts = storage.loadAccounts()
        activeAccountId = primaryAccount?.id
    }

    private func saveAccounts() {
        storage.saveAccounts(accounts)
    }
}
```

### Account Storage Protocol

```swift
public protocol AccountStorage: Sendable {
    func loadAccounts() -> [Account]
    func saveAccounts(_ accounts: [Account])
}

public final class UserDefaultsAccountStorage: AccountStorage {
    private let key = "savedAccounts"

    public init() {}

    public func loadAccounts() -> [Account] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let accounts = try? JSONDecoder().decode([Account].self, from: data) else {
            return []
        }
        return accounts
    }

    public func saveAccounts(_ accounts: [Account]) {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
```

---

## Credentials Management

### Keychain Storage Strategy

Each account has its own Keychain entry:

```swift
// Default account (backward compatible)
"Claude Code-credentials"

// Additional accounts use custom identifiers
"ClaudeApp-account-{uuid}"
```

### Multi-Account Credentials Repository

```swift
public actor MultiAccountCredentialsRepository {
    private let baseRepository: KeychainCredentialsRepository

    public init() {
        self.baseRepository = KeychainCredentialsRepository()
    }

    /// Get credentials for a specific account
    public func getCredentials(for account: Account) async throws -> Credentials {
        if account.keychainIdentifier == "default" {
            // Use default Claude Code credentials
            return try await baseRepository.getCredentials()
        } else {
            // Use account-specific credentials
            return try await readFromKeychain(identifier: account.keychainIdentifier)
        }
    }

    /// Store credentials for a specific account
    public func storeCredentials(_ credentials: Credentials, for account: Account) async throws {
        try await writeToKeychain(credentials, identifier: account.keychainIdentifier)
    }

    private func readFromKeychain(identifier: String) async throws -> Credentials {
        // Similar to existing KeychainCredentialsRepository but with custom service name
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", identifier, "-w"]
        // ... rest of implementation
    }

    private func writeToKeychain(_ credentials: Credentials, identifier: String) async throws {
        // Write credentials to Keychain with account-specific identifier
    }
}
```

---

## UsageManager Updates

### Per-Account Usage Tracking

```swift
@MainActor
@Observable
public final class UsageManager {
    public private(set) var usageByAccount: [UUID: UsageData] = [:]

    private let accountManager: AccountManager
    private let credentialsRepository: MultiAccountCredentialsRepository
    private var refreshTasks: [UUID: Task<Void, Never>] = [:]

    public init(
        accountManager: AccountManager,
        credentialsRepository: MultiAccountCredentialsRepository
    ) {
        self.accountManager = accountManager
        self.credentialsRepository = credentialsRepository
    }

    /// Refresh usage for active account
    public func refreshActiveAccount() async {
        guard let account = accountManager.activeAccount else { return }
        await refreshAccount(account)
    }

    /// Refresh usage for all accounts
    public func refreshAllAccounts() async {
        await withTaskGroup(of: Void.self) { group in
            for account in accountManager.accounts where account.isActive {
                group.addTask {
                    await self.refreshAccount(account)
                }
            }
        }
    }

    private func refreshAccount(_ account: Account) async {
        do {
            let credentials = try await credentialsRepository.getCredentials(for: account)
            let apiClient = ClaudeAPIClient(credentials: credentials)
            let data = try await apiClient.fetchUsage()
            usageByAccount[account.id] = data
        } catch {
            // Handle error
        }
    }

    /// Usage data for active account
    public var currentUsageData: UsageData? {
        guard let id = accountManager.activeAccountId else { return nil }
        return usageByAccount[id]
    }

    /// Highest utilization across all active accounts
    public var highestUtilizationAcrossAccounts: Double {
        accountManager.accounts
            .filter { $0.isActive }
            .compactMap { usageByAccount[$0.id]?.highestUtilization }
            .max() ?? 0
    }
}
```

---

## Settings Integration

### Display Options

```swift
public enum MultiAccountDisplayMode: String, CaseIterable, Codable {
    case all = "All Accounts"
    case activeOnly = "Active Only"
    case primaryOnly = "Primary Only"
}

extension SettingsKey {
    static let multiAccountDisplayMode = SettingsKey<MultiAccountDisplayMode>(
        key: "multiAccountDisplayMode",
        defaultValue: .primaryOnly
    )

    static let showAccountLabels = SettingsKey<Bool>(
        key: "showAccountLabels",
        defaultValue: false
    )
}
```

---

## Migration

### From Single Account

When upgrading from single-account version:

1. Create default account named "Default"
2. Point it to existing "Claude Code-credentials" Keychain entry
3. Mark as primary
4. Preserve all existing settings

```swift
func migrateToMultiAccount() {
    let accountManager = AccountManager()

    // Check if migration needed
    if accountManager.accounts.isEmpty {
        // Create default account from existing credentials
        let defaultAccount = Account(
            name: "Default",
            keychainIdentifier: "default",  // Uses "Claude Code-credentials"
            isPrimary: true
        )
        accountManager.addAccount(defaultAccount)
    }
}
```

---

## Acceptance Criteria

### Must Have

- [x] Add/remove accounts from settings
- [x] Switch between accounts in dropdown
- [x] Each account fetches usage independently
- [x] Primary account displayed by default
- [x] Backward compatible with single-account setup

### Should Have

- [x] Account names editable
- [x] Show plan type per account
- [ ] Refresh all accounts option
- [x] Account status indicator (connected/error)

### Nice to Have

- [ ] Multi-account menu bar display
- [ ] Aggregate view across all accounts
- [ ] Account-specific notification settings
- [ ] Import accounts from multiple Keychain entries

---

## Future Considerations

### Multiple Providers

Architecture supports extending to other AI providers:

```swift
public enum Provider: String, CaseIterable, Codable {
    case claude = "Claude"
    case openai = "OpenAI"
    case gemini = "Gemini"
}

public struct Account {
    // ...
    public var provider: Provider = .claude
}
```

This follows patterns from [quotio](https://github.com/nguyenphutrong/quotio) which supports Claude, Gemini, OpenAI, Qwen, and Antigravity.

---

## Related Specifications

- [settings.md](./settings.md) - Settings integration
- [architecture.md](../architecture.md) - Dependency injection patterns
- [api-documentation.md](../api-documentation.md) - API authentication
