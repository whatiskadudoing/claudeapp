import Foundation

// MARK: - PercentageSource

/// Defines which usage metric to display in the menu bar percentage.
public enum PercentageSource: String, Sendable, CaseIterable, Codable {
    case highest = "Highest %"
    case session = "Current Session"
    case weekly = "Weekly (All Models)"
    case opus = "Weekly (Opus)"
    case sonnet = "Weekly (Sonnet)"
}
