import Foundation

// MARK: - MultiAccountDisplayMode

/// Defines which accounts to display in the menu bar for multi-account setups.
/// Users can choose to show all accounts, only the active account, or only the primary account.
public enum MultiAccountDisplayMode: String, Sendable, CaseIterable, Codable {
    /// Show all enabled accounts in the menu bar
    case all = "all"

    /// Show only the currently active/selected account
    case activeOnly = "activeOnly"

    /// Show only the primary account
    case primaryOnly = "primaryOnly"

    /// Localization key for this display mode. Use String(localized:) in UI layer.
    public var localizationKey: String {
        switch self {
        case .all: return "multiAccountDisplayMode.all"
        case .activeOnly: return "multiAccountDisplayMode.activeOnly"
        case .primaryOnly: return "multiAccountDisplayMode.primaryOnly"
        }
    }

    /// Localized display name. Requires Localizable.xcstrings in the main bundle.
    public var localizedName: String {
        Bundle.main.localizedString(forKey: localizationKey, value: displayName, table: nil)
    }

    /// Default display name (used as fallback)
    public var displayName: String {
        switch self {
        case .all: return "All Accounts"
        case .activeOnly: return "Active Only"
        case .primaryOnly: return "Primary Only"
        }
    }
}
