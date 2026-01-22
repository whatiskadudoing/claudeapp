import Foundation

// MARK: - BurnRateLevel

/// Represents the level of burn rate (consumption velocity) for usage.
/// Used for display purposes with color-coded badges.
public enum BurnRateLevel: String, Sendable, CaseIterable, Equatable, Codable {
    case low = "Low"
    case medium = "Med"
    case high = "High"
    case veryHigh = "V.High"

    /// Semantic color name for this burn rate level.
    /// - Returns: Color name string (green/yellow/orange/red)
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }
}

// MARK: - BurnRate

/// Represents the consumption velocity as percentage points per hour.
/// Used to calculate time-to-exhaustion and display burn rate indicators.
public struct BurnRate: Sendable, Equatable, Codable {
    /// Consumption rate in percentage points per hour.
    /// For example, 15.0 means 15% of capacity used per hour.
    public let percentPerHour: Double

    public init(percentPerHour: Double) {
        self.percentPerHour = percentPerHour
    }

    /// The burn rate level based on thresholds.
    /// - Low: < 10%/hr (sustainable pace)
    /// - Medium: 10-25%/hr (moderate consumption)
    /// - High: 25-50%/hr (heavy usage)
    /// - Very High: > 50%/hr (will exhaust quickly)
    public var level: BurnRateLevel {
        switch percentPerHour {
        case ..<10:
            return .low
        case 10..<25:
            return .medium
        case 25..<50:
            return .high
        default:
            return .veryHigh
        }
    }

    /// Formatted string for display, e.g., "15%/hr"
    public var displayString: String {
        String(format: "%.0f%%/hr", percentPerHour)
    }
}
