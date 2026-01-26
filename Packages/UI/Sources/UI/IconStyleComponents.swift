import SwiftUI

// MARK: - Icon Style Components for Menu Bar Display
// These components are used by MenuBarView to render different icon styles.
// Each component is designed to be compact and efficient for menu bar rendering.
// See: specs/features/icon-styles.md

// MARK: - Progress Bar Icon

/// A compact horizontal progress bar for menu bar display.
/// Shows usage percentage with color-coded fill based on thresholds.
/// Dimensions: 40x8 pixels for menu bar fit.
public struct ProgressBarIcon: View {
    /// Usage percentage (0-100)
    public let value: Double

    /// Initialize with usage value.
    /// - Parameter value: Usage percentage (0-100). Values above 100 are clamped.
    public init(value: Double) {
        self.value = value
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))

            // Filled progress
            RoundedRectangle(cornerRadius: 2)
                .fill(progressColor)
                .frame(width: 40 * min(max(value / 100, 0), 1))
        }
        .frame(width: 40, height: 8)
        .accessibilityHidden(true) // Parent view provides accessibility
    }

    /// Color based on usage thresholds.
    /// - 0-49%: Green (safe)
    /// - 50-89%: Yellow (warning)
    /// - 90-100%: Red/Primary (critical)
    private var progressColor: Color {
        switch value {
        case 0..<50:
            Theme.Colors.success
        case 50..<90:
            Theme.Colors.warning
        default:
            Theme.Colors.primary
        }
    }
}

// MARK: - Battery Indicator

/// A battery-shaped indicator showing remaining capacity.
/// Displays the inverse of usage (remaining capacity) for intuitive understanding.
/// This is a familiar metaphor: like a phone battery showing what's left.
public struct BatteryIndicator: View {
    /// Remaining capacity (0.0 to 1.0, inverse of usage)
    public let fillLevel: Double

    /// Color for the fill (based on remaining capacity)
    public let color: Color

    /// Initialize with fill level and color.
    /// - Parameters:
    ///   - fillLevel: Remaining capacity from 0.0 (empty) to 1.0 (full)
    ///   - color: Color for the battery fill
    public init(fillLevel: Double, color: Color) {
        self.fillLevel = fillLevel
        self.color = color
    }

    /// Convenience initializer from usage percentage.
    /// Automatically calculates fill level (inverse) and color.
    /// - Parameter usagePercent: Usage percentage (0-100)
    public init(usagePercent: Double) {
        let remaining = max(0, min(100, 100 - usagePercent))
        self.fillLevel = remaining / 100

        // Color based on remaining capacity
        // >50% remaining: green
        // 20-50% remaining: yellow
        // <20% remaining: red
        switch remaining {
        case 50...:
            self.color = Theme.Colors.success
        case 20..<50:
            self.color = Theme.Colors.warning
        default:
            self.color = Theme.Colors.primary
        }
    }

    public var body: some View {
        HStack(spacing: 1) {
            // Battery body
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.secondary, lineWidth: 1)

                // Battery fill
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .padding(2)
                    .frame(width: max(4, 20 * min(max(fillLevel, 0), 1)))
            }
            .frame(width: 20, height: 10)

            // Battery cap (positive terminal)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary)
                .frame(width: 2, height: 5)
        }
        .accessibilityHidden(true) // Parent view provides accessibility
    }
}

// MARK: - Status Dot

/// A small colored status dot for compact menu bar display.
/// Used in the "compact" icon style to show status with minimal space.
/// Dimensions: 6x6 pixels.
public struct StatusDot: View {
    /// The color of the status dot
    public let color: Color

    /// Initialize with explicit color.
    /// - Parameter color: The dot color
    public init(color: Color) {
        self.color = color
    }

    /// Convenience initializer from usage percentage.
    /// Automatically determines color based on thresholds.
    /// - Parameter usagePercent: Usage percentage (0-100)
    public init(usagePercent: Double) {
        // Color based on usage thresholds
        // 0-49%: green (safe)
        // 50-89%: yellow (warning)
        // 90-100%: red (critical)
        switch usagePercent {
        case 0..<50:
            self.color = Theme.Colors.success
        case 50..<90:
            self.color = Theme.Colors.warning
        default:
            self.color = Theme.Colors.primary
        }
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .accessibilityHidden(true) // Parent view provides accessibility
    }
}

// MARK: - Color Helpers

/// Helper function to get status color from usage percentage.
/// Used across icon style components for consistent color theming.
/// - Parameter usage: Usage percentage (0-100)
/// - Returns: Color based on threshold (green/yellow/red)
public func statusColor(for usage: Double) -> Color {
    switch usage {
    case 0..<50:
        Theme.Colors.success
    case 50..<90:
        Theme.Colors.warning
    default:
        Theme.Colors.primary
    }
}

/// Helper function to get remaining capacity color.
/// Used for battery-style indicators where high remaining = good.
/// - Parameter remaining: Remaining capacity percentage (0-100)
/// - Returns: Color based on threshold (green/yellow/red)
public func remainingColor(for remaining: Double) -> Color {
    switch remaining {
    case 50...:
        Theme.Colors.success
    case 20..<50:
        Theme.Colors.warning
    default:
        Theme.Colors.primary
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Progress Bar Icon") {
    VStack(spacing: 20) {
        HStack(spacing: 10) {
            Text("0%")
            ProgressBarIcon(value: 0)
        }
        HStack(spacing: 10) {
            Text("25%")
            ProgressBarIcon(value: 25)
        }
        HStack(spacing: 10) {
            Text("50%")
            ProgressBarIcon(value: 50)
        }
        HStack(spacing: 10) {
            Text("75%")
            ProgressBarIcon(value: 75)
        }
        HStack(spacing: 10) {
            Text("90%")
            ProgressBarIcon(value: 90)
        }
        HStack(spacing: 10) {
            Text("100%")
            ProgressBarIcon(value: 100)
        }
    }
    .padding()
}

#Preview("Battery Indicator") {
    VStack(spacing: 20) {
        HStack(spacing: 10) {
            Text("0% used (full)")
            BatteryIndicator(usagePercent: 0)
        }
        HStack(spacing: 10) {
            Text("25% used")
            BatteryIndicator(usagePercent: 25)
        }
        HStack(spacing: 10) {
            Text("50% used")
            BatteryIndicator(usagePercent: 50)
        }
        HStack(spacing: 10) {
            Text("75% used")
            BatteryIndicator(usagePercent: 75)
        }
        HStack(spacing: 10) {
            Text("90% used")
            BatteryIndicator(usagePercent: 90)
        }
        HStack(spacing: 10) {
            Text("100% used (empty)")
            BatteryIndicator(usagePercent: 100)
        }
    }
    .padding()
}

#Preview("Status Dot") {
    VStack(spacing: 20) {
        HStack(spacing: 10) {
            Text("Safe (25%)")
            StatusDot(usagePercent: 25)
        }
        HStack(spacing: 10) {
            Text("Warning (60%)")
            StatusDot(usagePercent: 60)
        }
        HStack(spacing: 10) {
            Text("Critical (95%)")
            StatusDot(usagePercent: 95)
        }
    }
    .padding()
}

#Preview("All Components at 75% Usage") {
    VStack(spacing: 20) {
        Text("All at 75% usage")
            .font(.headline)

        HStack(spacing: 20) {
            VStack {
                Text("Progress Bar")
                    .font(.caption)
                ProgressBarIcon(value: 75)
            }

            VStack {
                Text("Battery")
                    .font(.caption)
                BatteryIndicator(usagePercent: 75)
            }

            VStack {
                Text("Status Dot")
                    .font(.caption)
                StatusDot(usagePercent: 75)
            }
        }
    }
    .padding()
}
#endif
