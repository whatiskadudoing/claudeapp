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
        Text(level.rawValue)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
            .accessibilityLabel(accessibilityLabel)
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
        switch level {
        case .low:
            "Consumption rate: low, sustainable pace"
        case .medium:
            "Consumption rate: medium, moderate usage"
        case .high:
            "Consumption rate: high, heavy usage"
        case .veryHigh:
            "Consumption rate: very high, will exhaust quickly"
        }
    }
}
