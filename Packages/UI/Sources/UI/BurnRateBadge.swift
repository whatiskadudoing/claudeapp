import Domain
import SwiftUI

// MARK: - Burn Rate Badge

/// A small colored pill showing the current burn rate level in the dropdown header.
/// Shows consumption velocity at a glance: Low (green), Med (yellow), High (orange), V.High (red).
/// Only displayed when burn rate data is available (after 2+ samples collected).
public struct BurnRateBadge: View {
    let level: BurnRateLevel

    public init(level: BurnRateLevel) {
        self.level = level
    }

    public var body: some View {
        Text(localizedLevelName)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
            .accessibilityLabel(accessibilityLabel)
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
