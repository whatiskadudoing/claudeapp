import Foundation

// MARK: - PlanType

/// The user's Claude subscription plan type.
/// Used for displaying the plan badge in the menu bar.
public enum PlanType: String, Codable, Sendable, CaseIterable {
    case pro = "pro"
    case max5x = "max5x"
    case max20x = "max20x"

    /// The display name shown in the menu bar badge
    public var badgeText: String {
        switch self {
        case .pro:
            return "Pro"
        case .max5x:
            return "5x"
        case .max20x:
            return "20x"
        }
    }

    /// The full display name shown in settings
    public var displayName: String {
        switch self {
        case .pro:
            return "Pro"
        case .max5x:
            return "Max (5x)"
        case .max20x:
            return "Max (20x)"
        }
    }
}
