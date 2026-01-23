import Foundation

// MARK: - PercentageSource

/// Defines which usage metric to display in the menu bar percentage.
public enum PercentageSource: String, Sendable, CaseIterable, Codable {
    case highest = "Highest %"
    case session = "Current Session"
    case weekly = "Weekly (All Models)"
    case opus = "Weekly (Opus)"
    case sonnet = "Weekly (Sonnet)"

    /// Localization key for this source. Use String(localized:) in UI layer.
    public var localizationKey: String {
        switch self {
        case .highest: return "percentageSource.highest"
        case .session: return "percentageSource.session"
        case .weekly: return "percentageSource.weekly"
        case .opus: return "percentageSource.opus"
        case .sonnet: return "percentageSource.sonnet"
        }
    }

    /// Localized display name. Requires Localizable.xcstrings in the main bundle.
    public var localizedName: String {
        // Fall back to rawValue if localization not available
        Bundle.main.localizedString(forKey: localizationKey, value: rawValue, table: nil)
    }
}
