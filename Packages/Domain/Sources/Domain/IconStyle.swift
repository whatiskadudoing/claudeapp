import Foundation

// MARK: - IconStyle

/// Defines how usage is displayed in the menu bar.
/// Users can choose from multiple display styles to match their preferences.
public enum IconStyle: String, Sendable, CaseIterable, Codable {
    /// Claude icon + percentage text (e.g., "86%")
    case percentage = "percentage"

    /// Claude icon + horizontal progress bar
    case progressBar = "progressBar"

    /// Battery-shaped indicator showing remaining capacity
    case battery = "battery"

    /// Claude icon + small colored status dot
    case compact = "compact"

    /// Claude icon only, tinted by status color
    case iconOnly = "iconOnly"

    /// Full display: icon + progress bar + percentage
    case full = "full"

    /// Localization key for this style. Use String(localized:) in UI layer.
    public var localizationKey: String {
        switch self {
        case .percentage: return "iconStyle.percentage"
        case .progressBar: return "iconStyle.progressBar"
        case .battery: return "iconStyle.battery"
        case .compact: return "iconStyle.compact"
        case .iconOnly: return "iconStyle.iconOnly"
        case .full: return "iconStyle.full"
        }
    }

    /// Localized display name. Requires Localizable.xcstrings in the main bundle.
    public var localizedName: String {
        // Fall back to display name if localization not available
        Bundle.main.localizedString(forKey: localizationKey, value: displayName, table: nil)
    }

    /// Default display name (used as fallback)
    public var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .progressBar: return "Progress Bar"
        case .battery: return "Battery"
        case .compact: return "Compact"
        case .iconOnly: return "Icon Only"
        case .full: return "Full (Icon + Bar + %)"
        }
    }
}
