import Domain
import SwiftUI

// MARK: - Burn Rate Badge

/// A small colored pill showing the current burn rate level in the dropdown header.
/// Shows consumption velocity at a glance: Low (green), Med (yellow), High (orange), V.High (red).
/// Only displayed when burn rate data is available (after 2+ samples collected).
///
/// ## Color-Blind Accessibility (WCAG 2.1 AA)
/// Each level includes a shape indicator in addition to color and text:
/// - Low: Circle (safe, stable)
/// - Medium: Triangle (caution)
/// - High: Diamond (warning)
/// - Very High: Exclamation (alert)
///
/// This ensures status is distinguishable without relying solely on color.
public struct BurnRateBadge: View {
    let level: BurnRateLevel

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Whether high contrast mode is enabled
    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }

    public init(level: BurnRateLevel) {
        self.level = level
    }

    public var body: some View {
        HStack(spacing: 3) {
            // Shape indicator for color-blind accessibility
            Image(systemName: shapeIndicator)
                .font(.system(size: 8, weight: .bold))

            Text(localizedLevelName)
                .font(Theme.Typography.badge)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.15))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(badgeColor.opacity(isHighContrast ? 0.6 : 0), lineWidth: isHighContrast ? 1.5 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// SF Symbol name for the shape indicator based on burn rate level.
    /// Each level uses a distinct shape for color-blind accessibility.
    private var shapeIndicator: String {
        switch level {
        case .low:
            // Circle: Safe, stable, no concern
            return "circle.fill"
        case .medium:
            // Triangle: Caution, moderate concern
            return "triangle.fill"
        case .high:
            // Diamond: Warning, elevated concern
            return "diamond.fill"
        case .veryHigh:
            // Exclamation: Alert, critical concern
            return "exclamationmark.circle.fill"
        }
    }

    /// Localized level name for display
    private var localizedLevelName: String {
        let key = "burnRate.\(level.localizationKey)"
        return Bundle.main.localizedString(forKey: key, value: level.rawValue, table: nil)
    }

    private var badgeColor: Color {
        switch level {
        case .low:
            Theme.Colors.success
        case .medium:
            Theme.Colors.warning
        case .high:
            Theme.Colors.orange
        case .veryHigh:
            Theme.Colors.primary
        }
    }

    /// Accessibility label describing the burn rate level for VoiceOver
    private var accessibilityLabel: String {
        let key = "accessibility.burnRate.\(level.localizationKey)"
        let defaultValue: String
        switch level {
        case .low:
            defaultValue = "Consumption rate: low, sustainable pace"
        case .medium:
            defaultValue = "Consumption rate: medium, moderate usage"
        case .high:
            defaultValue = "Consumption rate: high, heavy usage"
        case .veryHigh:
            defaultValue = "Consumption rate: very high, will exhaust quickly"
        }
        return Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
    }
}
